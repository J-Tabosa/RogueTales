"""Prepare ImageGen source sheets for Godot without modifying their original PNGs.
Requires Pillow, numpy and scipy. Run with GODOT pointing to Godot 4.7.
Alpha segmentation is import metadata: disconnected neighboring poses must not leak
into rectangular atlas regions. Godot performs the final texture packing/resizing.
"""
from pathlib import Path
import json, os, subprocess, tempfile
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1]
IDS = ['joao', 'maria', 'alice', 'puss', 'matches', 'peter', 'aladin']
with tempfile.TemporaryDirectory(prefix='roguetales-atlas-') as work:
    work = Path(work)
    sheets = []
    for hero in IDS:
        for kind, cols in [('actions', 5), ('walk', 4)]:
            source = ROOT / 'assets' / hero / (kind + '.png')
            alpha = np.asarray(Image.open(source))[:, :, 3]
            height, width = alpha.shape
            cw, ch = width / cols, height / 4
            slots = [(r, c) for r in range(4) for c in range(cols) if not(kind == 'actions' and r < 2 and c == 4)]
            # Eroded cores separate even touching swords, smoke and carpet tassels.
            cores, count = ndimage.label(ndimage.binary_erosion(alpha > 24, iterations=8))
            boxes = ndimage.find_objects(cores)
            sizes = np.bincount(cores.ravel())
            candidates = {}
            for component, box in enumerate(boxes, 1):
                if box is None or sizes[component] < 2000:
                    continue
                cy, cx = ndimage.center_of_mass(cores[box] == component)
                cy += box[0].start
                cx += box[1].start
                slot = min(slots, key=lambda rc: ((cx-(rc[1]+.5)*cw)/cw)**2 + ((cy-(rc[0]+.5)*ch)/ch)**2)
                if slot not in candidates or sizes[component] > sizes[candidates[slot]]:
                    candidates[slot] = component
            assert len(candidates) == len(slots), (hero,kind, 'Missing body core',set(slots)-set(candidates))
            seeds = np.zeros(alpha.shape, np.uint8)
            for number, slot in enumerate(slots, 1):
                seeds[cores == candidates[slot]] = number
            # Nearest body cores retain source pixels across grid boundaries while
            # isolating each figure, including its detached cards and spell fragments.
            _, nearest = ndimage.distance_transform_edt(seeds == 0, return_indices=True)
            ownership = seeds[tuple(nearest)]
            ownership[alpha == 0] = 0
            # Reject detached fragments borrowed from a neighboring pose. Small
            # details close to the main silhouette (eyes, fingers, sparks) survive.
            for number in range(1, len(slots) + 1):
                pieces, piece_count = ndimage.label(ownership == number, np.ones((3,3)))
                piece_sizes = np.bincount(pieces.ravel())
                body = int(np.argmax(piece_sizes[1:]) + 1)
                distance = ndimage.distance_transform_edt(pieces != body)
                for piece in range(1, piece_count + 1):
                    if piece != body and (piece_sizes[piece] < 60 or distance[pieces == piece].min() > 12):
                        ownership[pieces == piece] = 0
            mask_path = work / (hero + '-' + kind + '.bin')
            mask_path.write_bytes(ownership.tobytes())
            frames = []
            for number, (row,col) in enumerate(slots,1):
                yy, xx = np.where((ownership == number) & (alpha > 12))
                frames.append({'row':row,'col':col,'bounds':[int(xx.min()),int(yy.min()),int(xx.max()-xx.min()+1),int(yy.max()-yy.min()+1)]})
            sheets.append({'hero':hero,'kind':kind,'columns':cols,'source':str(source),'mask':str(mask_path),'frames':frames})
    metadata = work / 'sheets.json'
    metadata.write_text(json.dumps(sheets))
    subprocess.run([os.environ.get('GODOT','godot'),'--headless','--path',str(ROOT),'--script','res://tools/pack_roster.gd','--',str(metadata)], check=True)

# Keep the editable AtlasTexture regions tight after packing. This is text-only
# resource generation; Pillow only inspects the prepared alpha bounds.
import re
for hero in IDS:
    resource = ROOT / 'assets' / hero / 'frames.tres'
    text = resource.read_text()
    masks = {kind:Image.open(ROOT/'assets'/hero/(kind+'_atlas.png')).getchannel('A') for kind in ['actions','walk']}
    for animation, count in [('idle',4),('idle_blink',4),('walk',16),('attack',10)]:
        for index in range(count):
            if animation == 'idle': row, column = 0,index
            elif animation == 'idle_blink': row,column = 1,index
            elif animation == 'walk': row,column = divmod(index,4)
            else: row,column = 2+index//5,index%5
            x,y = column*360,row*320
            left,top,right,bottom = masks['walk' if animation=='walk' else 'actions'].crop((x,y,x+360,y+320)).getbbox()
            width,height = right-left,bottom-top
            pattern = r'(\[sub_resource type="AtlasTexture" id="'+animation+'_'+str(index)+r'"\][\s\S]*?)region = Rect2\([^\n]+\)\nmargin = Rect2\([^\n]+\)'
            text,replacements = re.subn(pattern,lambda match:match[1]+f'region = Rect2({x+left}, {y+top}, {width}, {height})\nmargin = Rect2({180+left}, {290+top}, {720-width}, {640-height})',text)
            assert replacements == 1
    resource.write_text(text)
