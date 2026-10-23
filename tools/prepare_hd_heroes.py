"""Rebuild native-resolution hero meshes. Pillow/Scipy inspect alpha only; Godot builds assets."""
from pathlib import Path
import json,shutil,subprocess,os
import numpy as np
from scipy import ndimage as nd
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
ART=ROOT.parent/'recovered-art'/'GameDev'
mapping={('alice','idle'):'Atlas de sprites da Alice.png',('alice','attack'):'Alice lança cartas em ataque.png',('rapunzel','idle'):'Rapunzel em quatro poses.png',('rapunzel','attack'):'Rapunzel: chicote de cabelo em ação.png'}
work=ROOT.parent/'rogue-tools'/'hd-masks';work.mkdir(exist_ok=True)
sheets=[]
for (hero,kind),name in mapping.items():
 target=ROOT/'assets'/hero/(kind+'_hd.png')
 if (ART/name).is_file(): shutil.copyfile(ART/name,target)
 alpha=np.asarray(Image.open(target).getchannel('A'));h,w=alpha.shape
 if kind=='idle': centers=[(.25,.25),(.75,.25),(.25,.75),(.75,.75)]
 elif hero=='alice':centers=[((i+.5)/5,.30) for i in range(5)]+[(x,.75) for x in [.12,.50,.71,.91]]
 else:centers=[((i+.5)/4,y) for y in [.30,.78] for i in range(4)]
 labels,_=nd.label(nd.binary_erosion(alpha>128,iterations=7));sizes=np.bincount(labels.ravel());seeds=np.zeros(alpha.shape,np.uint8)
 candidates=[]
 for label in np.where(sizes>5000)[0]:
  if label==0:continue
  cy,cx=nd.center_of_mass(labels==label);candidates.append((label,cx/w,cy/h))
 for index,(cx,cy) in enumerate(centers,1):
  label=min(candidates,key=lambda it:(it[1]-cx)**2+(it[2]-cy)**2)[0]
  core=labels==label
  # The two bottom Rapunzel hair silhouettes touch; torso seeds separate them.
  if hero=='rapunzel' and kind=='attack' and index in [5,6]:
   yy,xx=np.ogrid[:h,:w];core &= ((xx-(.13 if index==5 else .39)*w)**2+((yy-.78*h)*1.2)**2)<(w*.075)**2
  seeds[core]=index
 _,nearest=nd.distance_transform_edt(seeds==0,return_indices=True);ownership=seeds[tuple(nearest)];ownership[alpha<8]=0
 frames=[]
 for index in range(1,len(centers)+1):
  pieces,_=nd.label(ownership==index,np.ones((3,3)));counts=np.bincount(pieces.ravel());body=int(np.argmax(counts[1:])+1);distance=nd.distance_transform_edt(pieces!=body)
  for piece in range(1,len(counts)):
   if piece!=body and (counts[piece]<64 or distance[pieces==piece].min()>18):ownership[pieces==piece]=0
  yy,xx=np.where(ownership==index);frames.append({'bounds':[int(xx.min()),int(yy.min()),int(xx.max()-xx.min()+1),int(yy.max()-yy.min()+1)]})
 mask=work/(hero+'-'+kind+'.bin');mask.write_bytes(ownership.tobytes());sheets.append({'hero':hero,'kind':kind,'source':'res://assets/'+hero+'/'+kind+'_hd.png','mask':str(mask),'frames':frames})
(ROOT/'assets'/'portraits').mkdir(exist_ok=True)
if (ART/'Retratos de Alice e Rapunzel.png').is_file(): shutil.copyfile(ART/'Retratos de Alice e Rapunzel.png',ROOT/'assets'/'portraits'/'heroes_hd.png')
metadata=work/'manifest.json';metadata.write_text(json.dumps(sheets))
subprocess.run([os.environ['GODOT'],'--headless','--path',str(ROOT),'--editor','--import'],check=True,stdout=open(work/'import.log','w'),stderr=subprocess.STDOUT)
subprocess.run([os.environ['GODOT'],'--headless','--path',str(ROOT),'--script','res://tools/prepare_hd_heroes.gd','--',str(metadata)],check=True)
