#!/usr/bin/env python3
"""Recover whole poses from uploaded sheets, then calibrate anatomy independently of FX.
Usage: python3 tools/repair_animation_layout.py /path/to/CaractersATK
Requires Pillow, numpy, scipy and scikit-image.
"""
from pathlib import Path
import sys,json
import numpy as np
from PIL import Image
from scipy import ndimage as ndi
from skimage.segmentation import watershed
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/characters'
FILES={'scarlet':'Chapeuzinho','ariel':'Sereia','aladin':'Aladin','joao':'Joao','maria':'Maria','peter':'PeterPan','mulan':'Mulan','snow_white':'BrancadeNeve','rapunzel':'Rapunzel','alice':'Alice','matches':'fosforo'}
SCALE={'scarlet':(1,1),'ariel':(.97,1),'aladin':(.94,1),'joao':(1,1),'maria':(.96,1),'peter':(.82,1),'mulan':(.94,.83),'snow_white':(.94,.78),'rapunzel':(1,1),'alice':(.94,1),'matches':(.98,1)}
def recover(path,cols,rows):
 im=Image.open(path).convert('RGBA');a=np.array(im);mask=a[:,:,3]>10;h,w=mask.shape;markers=np.zeros(mask.shape,np.int32)
 centers=[]
 for n in range(cols*rows-(1 if cols==3 else 0)):
  cx=(n%cols+.50)*w/cols;cy=(n//cols+.58)*h/rows
  y0,y1=int(n//cols*h/rows),int((n//cols+1)*h/rows);x0,x1=int(n%cols*w/cols),int((n%cols+1)*w/cols)
  yy,xx=np.where(mask[y0:y1,x0:x1]);assert len(xx),(path,n)
  d=((xx+x0-cx)/(w/cols))**2+((yy+y0-cy)/(h/rows))**2;j=np.argmin(d);x,y=int(xx[j]+x0),int(yy[j]+y0)
  markers[y,x]=n+1;centers.append((cx,cy))
 labels=watershed(-ndi.distance_transform_edt(mask),markers,mask=mask)
 cc,count=ndi.label(mask & (labels==0))
 for k,sl in enumerate(ndi.find_objects(cc),1):
  if sl is None:continue
  ys,xs=np.where(cc[sl]==k);size=len(xs)
  if size<15:continue
  cx=xs.mean()+sl[1].start;cy=ys.mean()+sl[0].start
  nearest=min(range(len(centers)),key=lambda n:((cx-centers[n][0])/(w/cols))**2+((cy-centers[n][1])/(h/rows))**2)
  region=labels[sl];region[cc[sl]==k]=nearest+1
 result=[]
 for n in range(cols*rows-(1 if cols==3 else 0)):
  part=labels==n+1;ys,xs=np.where(part);box=(xs.min(),ys.min(),xs.max()+1,ys.max()+1)
  crop=a[box[1]:box[3],box[0]:box[2]].copy();crop[:,:,3]*=part[box[1]:box[3],box[0]:box[2]]
  result.append((Image.fromarray(crop),box))
 if cols==3:result.append(result[-1])
 return result

def clean_tile(tile):
 a=np.array(tile);mask=a[:,:,3]>10;cc,n=ndi.label(mask);sizes=np.bincount(cc.ravel());largest=sizes[1:].argmax()+1
 ys,xs=np.where(cc==largest);main=(xs.min(),ys.min(),xs.max()+1,ys.max()+1);removed=[]
 for k,sl in enumerate(ndi.find_objects(cc),1):
  if sl is None or k==largest:continue
  y,x=sl;area=sizes[k];ww=x.stop-x.start;hh=y.stop-y.start
  # Neighbor-row slivers and isolated edge fragments are not part of this pose.
  if area<15 or (hh<12 and y.stop<main[1]+20) or (y.stop<main[1]-18 and (x.start<24 or x.stop>488)):
   a[:,:,3][cc==k]=0;removed.append([x.start,y.start,ww,hh])
 return Image.fromarray(a),removed

def main(source):
 prompts=json.loads((OUT/'ART_PROMPTS.json').read_text());layout={'logical_size':768,'anchor':[384,608],'source_cell':512,'heroes':{}}
 for hero,file in FILES.items():
  poses=recover(Path(source)/(file+'ATK.png'),3 if hero=='alice' else 4,4 if hero=='alice' else 3)
  first=poses[0][1];scale=280/(first[3]-first[1]);anchor=(first[0]+first[2])*.5;sheet=Image.new('RGBA',(2048,1536))
  for n,(crop,box) in enumerate(poses):
   # Preserve one scale and one ground line for the entire attack, including raised weapons.
   crop=crop.resize((max(1,round(crop.width*scale)),max(1,round(crop.height*scale))),Image.Resampling.LANCZOS)
   cols=3 if hero=="alice" else 4
   original_width=Image.open(Path(source)/(file+"ATK.png")).width
   x=round(256+(box[0]-(min(n,10) if hero=="alice" else n)%cols*original_width/cols-anchor)*scale);y=480-crop.height
   sheet.alpha_composite(crop,(n%4*512+x,n//4*512+y))
  sheet.save(OUT/hero/'attack.webp',lossless=True,method=4)
  hero_meta={}
  for anim,count in [('idle',8),('attack',12),('ultimate',12)]:
   path=OUT/hero/(anim+'.webp');atlas=Image.open(path).convert('RGBA');meta=[]
   for n in range(count):
    tile=atlas.crop((n%4*512,n//4*512,n%4*512+512,n//4*512+512));tile,removed=clean_tile(tile)
    # Four old dash poses contain severed neighboring limbs; the arena supplies
    # actual dash movement and six thrust effects over complete replacement poses.
    if hero=='joao' and anim=='ultimate' and n in [1,2,10,11]:
     fallback='attack' if n<3 else 'idle';at=n if n<3 else 0
     src=Image.open(OUT/hero/(fallback+'.webp'));tile=src.crop((at%4*512,at//4*512,at%4*512+512,at//4*512+512))
    atlas.paste(tile,(n%4*512,n//4*512));box=tile.getbbox();assert box,(hero,anim,n)
    factor=1 if anim=='idle' else SCALE[hero][0 if anim=='attack' else 1]
    foot=462 if hero=='snow_white' and anim=='ultimate' and n>=8 else 480
    bounds=[384+(box[0]-256)*factor,608+(box[1]-foot)*factor,(box[2]-box[0])*factor,(box[3]-box[1])*factor]
    meta.append({'region':[n%4*512+box[0],n//4*512+box[1],box[2]-box[0],box[3]-box[1]],'local_bounds':bounds,'anchor':[256,foot],'scale':factor,'removed':removed})
   temp=path.with_suffix('.tmp.webp');atlas.save(temp,lossless=True,method=4);temp.replace(path);hero_meta[anim]=meta
  hero_meta['pose_order']=prompts[hero]['pose_order'];layout['heroes'][hero]=hero_meta
  print('CALIBRATED',hero,flush=True)
 (OUT/'FRAME_LAYOUT.json').write_text(json.dumps(layout,indent=2)+'\n')
if __name__=='__main__':main(sys.argv[1])
