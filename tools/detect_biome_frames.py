"""Detect authored sprite regions; image pixels are packed only by Godot.
Usage: python tools/detect_biome_frames.py source-map.json output-map.json
Requires Pillow, NumPy and SciPy for alpha-component analysis.
"""
import json
import sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy.ndimage import label, find_objects, distance_transform_edt

inputs = json.loads(Path(sys.argv[1]).read_text())
output = {}
for key, source_path in inputs.items():
    if not key.startswith('enemies_'):
        output[key] = source_path
        continue
    rgba = np.asarray(Image.open(source_path).convert('RGBA'))
    alpha = rgba[:, :, 3]
    height, width = alpha.shape
    ownership = np.zeros_like(alpha, dtype=np.uint8)
    for col in range(4):
        x0, x1 = col * width // 4, (col + 1) * width // 4
        strong = alpha[:, x0:x1] > 100
        labels, count = label(strong)
        areas = np.bincount(labels.ravel())
        regions = find_objects(labels)
        major = sorted(range(1, count + 1), key=lambda at: int(areas[at]), reverse=True)[:6]
        major.sort(key=lambda at: (regions[at-1][0].start + regions[at-1][0].stop) / 2)
        assert len(major) == 6 and all(areas[at] > 2500 for at in major), key
        identities = np.zeros(count + 1, dtype=np.uint8)
        for row, at in enumerate(major):
            identities[at] = row * 4 + col + 1
        for at in range(1, count + 1):
            if identities[at] or areas[at] < 3:
                continue
            region = regions[at-1]
            cy = (region[0].start + region[0].stop) / 2
            closest = min(major, key=lambda main: abs(cy - (regions[main-1][0].start + regions[main-1][0].stop) / 2))
            body = regions[closest-1]
            dx = max(0, body[1].start - region[1].stop, region[1].start - body[1].stop)
            dy = max(0, body[0].start - region[0].stop, region[0].start - body[0].stop)
            if col in (0, 3) and max(dx, dy) > 16:
                continue
            identities[at] = identities[closest]
        ids = identities[labels]
        distance, nearest = distance_transform_edt(ids == 0, return_indices=True)
        ids = ids[nearest[0], nearest[1]]
        ids = np.where((alpha[:, x0:x1] >= 8) & (distance <= 16), ids, 0)
        ownership[:, x0:x1] = ids
    frames = []
    for row in range(6):
        for col in range(4):
            index = row * 4 + col + 1
            yy, xx = np.nonzero(ownership == index)
            frames.append({'row': row, 'col': col, 'bounds': [int(xx.min()), int(yy.min()), int(xx.max()-xx.min()+1), int(yy.max()-yy.min()+1)]})
    mask_path = Path(sys.argv[2]).resolve().parent / (key + '-ownership.bin')
    mask_path.write_bytes(ownership.tobytes())
    output[key] = {'source': source_path, 'mask': str(mask_path), 'frames': frames}
Path(sys.argv[2]).write_text(json.dumps(output))
