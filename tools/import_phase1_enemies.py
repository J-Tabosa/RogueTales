#!/usr/bin/env python3
"""Reproducible, lossless import of the approved Fase 1 archive (originals untouched).

Requires Pillow, numpy and scipy. Run with --source pointing at the extracted
Fase 1 folder. No generative editing: only keying, slicing and registration.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1]
SPECS = {
    'winter_moose': ('Inverno', 'AlceATK', None, 'alpha', 4, 2),
    'winter_hunter': ('Inverno', 'CacadorATK', None, 'white', 4, 2),
    'winter_owl': ('Inverno', 'CorujaBrancaATK', 'CorujaBrancaIDLE', 'green', 4, 2),
    'winter_wolf': ('Inverno', 'LoboBrancoATK', None, 'green', 4, 2),
    'autumn_hare': ('Outono', 'LebreATK', None, 'alpha', 4, 2),
    'autumn_lumberjack': ('Outono', 'LenhadorATK', None, 'white', 4, 2),
    'autumn_wolf': ('Outono', 'LoboPretoATK', None, 'green', 4, 2),
    'autumn_fox': ('Outono', 'RaposaATK', None, 'alpha', 4, 2),
    'spring_hunter': ('Primavera', 'CaçadorATK', None, 'alpha', 4, 2),
    'spring_boar': ('Primavera', 'JavaliATK(parte1)', None, 'alpha', 4, 2),
    'spring_wolf': ('Primavera', 'LoboCinzaATK', None, 'alpha', 4, 2),
    'spring_bear': ('Primavera', 'UrsoATK', None, 'alpha', 4, 2),
    'summer_falcon': ('Verão', 'FalcaoATK', 'FalcaoIDLE', 'green', 6, 1),
    'summer_raccoon': ('Verão', 'guaxininATK', 'GuaxininIDLE', 'green', 4, 2),
    'summer_wolf': ('Verão', 'LoboMarromATK', None, 'green', 4, 2),
    'summer_snake': ('Verão', 'SerpenteATK', None, 'alpha', 4, 2),
}
FLYING = {'winter_owl', 'summer_falcon'}
IMPACTS = {'winter_owl': [6], 'summer_falcon': [4], 'spring_bear': [4, 5, 6],
           'spring_boar': [9], 'summer_raccoon': [5, 6],
           'summer_snake': [6], 'autumn_lumberjack': [6]}


def save_png(path, image):
    """Publish a complete PNG atomically, never an in-progress image stream."""
    buffer = io.BytesIO()
    image.save(buffer,format='PNG',optimize=True)
    data=buffer.getvalue()
    temporary=path.with_suffix('.png.tmp')
    assert temporary.write_bytes(data)==len(data)
    with Image.open(temporary) as check:check.verify()
    temporary.replace(path)


def key_image(path, mode):
    im = Image.open(path).convert('RGBA')
    original = np.asarray(im)
    if mode == 'alpha':
        assert original[:, :, 3].min() == 0, f'Missing supplied alpha: {path}'
        return im  # The supplied RGBA pixels are deliberately left untouched.
    rgb = original[:, :, :3].astype(np.float32)
    if mode == 'green':
        excess = rgb[:, :, 1] - np.maximum(rgb[:, :, 0], rgb[:, :, 2])
        # Yellow/white FX and light fur are not green-dominant and survive.
        alpha = 1.0 - np.clip((excess - 10.0) / 85.0, 0, 1)
        background = np.median(np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]]), axis=0)
        edge = (alpha > 0) & (alpha < 1)
        rgb[edge] = (rgb[edge] - background * (1 - alpha[edge, None])) / np.maximum(.04, alpha[edge, None])
        fringe = ndimage.binary_dilation(alpha < 1, iterations=2) & (alpha > 0)
        rgb[:, :, 1][fringe] = np.minimum(rgb[:, :, 1][fringe], np.maximum(rgb[:, :, 0][fringe], rgb[:, :, 2][fringe]))
    else:
        # Flood only the near-white region connected to the outer canvas.
        pale = (rgb.min(axis=2) > 216) & (rgb.max(axis=2) - rgb.min(axis=2) < 32)
        seeds = np.zeros(pale.shape, bool)
        seeds[0] = pale[0]; seeds[-1] = pale[-1]
        seeds[:, 0] = pale[:, 0]; seeds[:, -1] = pale[:, -1]
        outside = ndimage.binary_propagation(seeds, mask=pale)
        edge = ndimage.binary_dilation(outside, iterations=2)
        distance = 255.0 - rgb.min(axis=2)
        alpha = np.ones(pale.shape, np.float32)
        alpha[edge] = np.clip(distance[edge] / 42.0, 0, 1)
        alpha[outside & (distance < 8)] = 0
        partial = (alpha > 0) & (alpha < 1)
        rgb[partial] = (rgb[partial] - 255 * (1 - alpha[partial, None])) / np.maximum(.04, alpha[partial, None])
    rgba = np.dstack([np.clip(rgb, 0, 255), np.rint(alpha * 255)]).astype(np.uint8)
    rgba[rgba[:, :, 3] == 0, :3] = 0
    return Image.fromarray(rgba)


def dividers(mask, count, axis):
    """Choose genuinely empty/minimal projection cuts near the nominal grid."""
    extent = mask.shape[axis]
    projection = mask.sum(axis=1-axis).astype(float)
    smoothed = ndimage.uniform_filter1d(projection, size=5)
    cuts = [0]
    for n in range(1, count):
        ideal = extent * n / count
        radius = extent / count * .17
        candidates = np.arange(max(cuts[-1]+1, int(ideal-radius)), min(extent, int(ideal+radius))+1)
        cost = smoothed[candidates] * 1000 + abs(candidates-ideal)
        cuts.append(int(candidates[np.argmin(cost)]))
    return cuts + [extent]


def slice_sheet(image, cols, rows):
    alpha = np.asarray(image)[:, :, 3]
    ys = dividers(alpha > 12, rows, 0)
    frames, boxes = [], []
    for row in range(rows):
        # Some authored silhouettes overlap in their X projection: there is no
        # vertical cut that can preserve both. Segment whole connected bodies,
        # then attach disconnected FX by their nearest body pixel instead.
        rgba = np.asarray(image)[ys[row]:ys[row+1]].copy()
        labels, count = ndimage.label(rgba[:, :, 3] > 8)
        sizes = np.bincount(labels.ravel()); sizes[0] = 0
        mains = np.argsort(sizes)[-cols:]
        assert all(sizes[k] > 1000 for k in mains), (cols, sizes[mains])
        mains = sorted(mains, key=lambda k: np.where(labels == k)[1].mean())
        core = np.isin(labels, mains)
        distances, nearest = ndimage.distance_transform_edt(~core, return_indices=True)
        nearest_label = labels[tuple(nearest)]
        owner = np.zeros(count+1, dtype=np.int16)
        for col, label in enumerate(mains):owner[label] = col+1
        for label in range(1,count+1):
            if label in mains:continue
            mask = labels == label
            closest = nearest_label[mask][np.argmin(distances[mask])]
            owner[label] = owner[closest]
        assigned = owner[labels]
        faint = (labels == 0) & (rgba[:, :, 3] > 0)
        assigned[faint] = owner[nearest_label[faint]]
        for col in range(cols):
            pixels = rgba.copy()
            pixels[assigned != col+1] = 0
            frame = Image.fromarray(pixels)
            used = frame.getchannel('A').getbbox()
            assert used
            # Include every disconnected FX pixel, with a transparent margin.
            frames.append(frame.crop((max(0,used[0]-3),max(0,used[1]-3),min(frame.width,used[2]+3),min(frame.height,used[3]+3))))
            boxes.append([used[0],ys[row]+used[1],used[2],ys[row]+used[3]])
        assert np.array_equal(assigned > 0, rgba[:, :, 3] > 0), 'Every alpha pixel belongs to exactly one frame'
    return frames, boxes


def body_mask(frame):
    a = np.asarray(frame)
    rgb = a[:, :, :3].astype(float)
    # Remove bright cream/white/yellow FX only for measuring the ground anchor.
    solid = (a[:, :, 3] > 160) & (rgb.mean(axis=2) < 190)
    labels, n = ndimage.label(solid)
    sizes = np.bincount(labels.ravel()); sizes[0] = 0
    if n:
        solid = labels == sizes.argmax()
        solid = ndimage.binary_fill_holes(solid)
    return solid


def normalize(frames, flying, scale=1.0, anchors=None):
    result = []
    for i, source in enumerate(frames):
        frame = source
        if scale != 1:
            frame = frame.resize((round(frame.width*scale),round(frame.height*scale)), Image.Resampling.LANCZOS)
        mask = body_mask(frame)
        yy, xx = np.where(mask)
        if anchors:
            anchor = np.array(anchors[i], dtype=float) * scale
        elif flying:
            # Metadata can override these authored flight pivots after QA.
            anchor = np.array([np.median(xx), np.median(yy)])
        else:
            foot = np.quantile(yy, .997)
            anchor = np.array([np.median(xx), foot])
        canvas = Image.new('RGBA', (768,768))
        target = np.array([384,384 if flying else 640])
        pos = np.rint(target-anchor).astype(int)
        assert min(pos) >= 3 and pos[0]+frame.width <= 765 and pos[1]+frame.height <= 765, (i,source.size,pos)
        canvas.alpha_composite(frame,tuple(pos))
        result.append(canvas)
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source',type=Path,required=True)
    parser.add_argument('--qa',type=Path,required=True)
    args = parser.parse_args()
    args.qa.mkdir(parents=True,exist_ok=True)
    dest = ROOT/'assets/enemies/phase1'
    manifest = {}
    sources = {}
    for ident, (season, atk, idle, mode, cols, rows) in SPECS.items():
        folder = args.source/f'Floresta {season}'
        atk_path = folder/(atk+'.png')
        sheet = key_image(atk_path,mode)
        raw, boxes = slice_sheet(sheet,cols,rows)
        if ident == 'spring_boar':
            part2 = folder/'JavaliATK(parte2).png'
            continuation, extra = slice_sheet(key_image(part2,'alpha'),4,1)
            raw += continuation; boxes += extra
            sources[str(part2.relative_to(args.source))] = hashlib.sha256(part2.read_bytes()).hexdigest()
        # Keep the native attack-frame resolution. Only idle is rescaled.
        attack = normalize(raw, ident in FLYING)
        idle_frames = []
        if idle:
            idle_path = folder/(idle+'.png')
            idle_raw, idle_boxes = slice_sheet(key_image(idle_path,'green'),1 if ident=='summer_raccoon' else 4,1)
            # Reference head/body size ratios, checked on the source sheets.
            ratio = {'winter_owl': .56, 'summer_falcon': .63, 'summer_raccoon': .40}[ident]
            idle_frames = normalize(idle_raw,ident in FLYING,ratio)
            sources[str(idle_path.relative_to(args.source))] = hashlib.sha256(idle_path.read_bytes()).hexdigest()
        paths = {}
        for action, images in [('attack',attack),('idle',idle_frames)]:
            paths[action] = []
            for i, frame in enumerate(images):
                path = dest/ident/action/f'{i+1:02}.png'
                path.parent.mkdir(parents=True,exist_ok=True)
                save_png(path,frame)
                paths[action].append('res://'+str(path.relative_to(ROOT)))
        manifest[ident] = {'attack':paths['attack'],'idle':paths['idle'] or [paths['attack'][0]],
                           'anchor':[384,384 if ident in FLYING else 640], 'canvas':[768,768],
                           'flying':ident in FLYING,'fps':10.0,'impacts':IMPACTS.get(ident,[5]),
                           'source_boxes':boxes,'segmentation':'connected-components', 'reference_height':raw[0].height}
        sources[str(atk_path.relative_to(args.source))] = hashlib.sha256(atk_path.read_bytes()).hexdigest()
        preview = Image.new('RGB',(1024,512),(27,31,40))
        for i,frame in enumerate(attack):
            thumb=frame.resize((256,256),Image.Resampling.LANCZOS)
            # Extra boar frames use a separate continuation image below.
            if i<8:preview.paste(thumb,((i%4)*256,(i//4)*256),thumb)
        preview.save(args.qa/(ident+'.png'))
    (dest/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    (ROOT/'docs/phase1_source_sha256.json').write_text(json.dumps(sources,ensure_ascii=False,indent=2)+'\n')
    print(f'Imported {len(manifest)} monsters, {sum(len(m["attack"])+len(m["idle"]) for m in manifest.values())} animation references')


if __name__=='__main__':main()
