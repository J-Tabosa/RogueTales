"""Inspect source alpha and rebuild native JPEG+alpha sheets and padded Godot meshes.
Run: GODOT=/path/to/godot python tools/build_art.py
No source image is cropped, resized or repainted by this script.
"""
from pathlib import Path
import json,os,subprocess,sys
import numpy as np
from scipy import ndimage as nd
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
work=ROOT.parent/'art-build';work.mkdir(exist_ok=True)
manifest=json.loads((ROOT/'assets/characters/sources.json').read_text())
if len(sys.argv)>1: manifest=[entry for entry in manifest if entry.get("hero")==sys.argv[1]]
sheets=[]
for entry in manifest:
 if entry.get('kind') in ('effects','arena'): sheets.append(entry);continue
 source=ROOT/entry['source']
 alpha=np.array(Image.open(source).convert('RGBA'))[:,:,3]
 h,w=alpha.shape;cols,rows=entry['grid'];count=entry['count']
 cw,ch=w/cols,h/rows
 yy,xx=np.ogrid[:h,:w]
 cores=nd.binary_erosion(alpha>40,iterations=3)
 seeds=np.zeros((h,w),np.uint8)
 for at in range(count):
  cx=(at%cols+.5)*cw;cy=(at//cols+.45)*ch
  zone=((xx-cx)/(.31*cw))**2+((yy-cy)/(.34*ch))**2<1
  labels,n=nd.label(cores & zone)
  sizes=np.bincount(labels.ravel());sizes[0]=0
  assert sizes.max()>20,(entry['hero'],entry['kind'],at,'body core missing')
  seeds[labels==sizes.argmax()]=at+1
 _,nearest=nd.distance_transform_edt(seeds==0,return_indices=True)
 ownership=seeds[tuple(nearest)];ownership[alpha<8]=0
 # A pose may never borrow feet or hair from another row. Locate the actual
 # transparent gutter rather than assuming generated rows have exact heights.
 projection=(alpha>40).sum(axis=1)
 boundaries=[0]
 for row in range(1,rows):
  nominal=int(row*ch);radius=max(2,int(ch*.13))
  lo=max(boundaries[-1]+1,nominal-radius);hi=min(h,nominal+radius)
  smooth=nd.uniform_filter1d(projection.astype(float),size=3)
  boundary=lo+int(np.argmin(smooth[lo:hi]))
  boundaries.append(boundary)
 boundaries.append(h)
 for at in range(count):
  row=at//cols
  ownership[:boundaries[row]][ownership[:boundaries[row]]==at+1]=0
  ownership[boundaries[row+1]:][ownership[boundaries[row+1]:]==at+1]=0
 frames=[]
 for at in range(1,count+1):
  pieces,n=nd.label(ownership==at,np.ones((3,3)))
  sizes=np.bincount(pieces.ravel());sizes[0]=0
  body=int(sizes.argmax());distance=nd.distance_transform_edt(pieces!=body)
  for part in range(1,n+1):
   if part!=body and (sizes[part]<25 or distance[pieces==part].min()>18):ownership[pieces==part]=0
  ys,xs=np.where(ownership==at)
  frames.append({'bounds':[int(xs.min()),int(ys.min()),int(xs.max()-xs.min()+1),int(ys.max()-ys.min()+1)]})
 mask=work/(entry['hero']+'-'+entry['kind']+'.bin');mask.write_bytes(ownership.tobytes())
 entry.update(mask=str(mask),frames=frames)
 sheets.append(entry)
meta=work/'sheets.json';meta.write_text(json.dumps(sheets))
godot=os.environ.get('GODOT','godot')
subprocess.run([godot,'--headless','--path',str(ROOT),'--script','res://tools/import_art.gd','--',str(meta),'convert'],check=True)
subprocess.run([godot,'--headless','--path',str(ROOT),'--editor','--import'],check=True,stdout=(work/'import.log').open('w'),stderr=subprocess.STDOUT)
subprocess.run([godot,'--headless','--path',str(ROOT),'--script','res://tools/import_art.gd','--',str(meta),'frames'],check=True)
