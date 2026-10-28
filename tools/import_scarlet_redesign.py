#!/usr/bin/env python3
"""Inspect the supplied chroma sheets; Godot builds the textures and mesh resources.
Usage: GODOT=/path/to/godot python3 tools/import_scarlet_redesign.py
Requires numpy, scipy and Pillow. Original paintings remain unchanged.
"""
from pathlib import Path
import hashlib, json, os, subprocess, tempfile
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools/art_sources/scarlet_20261028"
GODOT = os.environ.get("GODOT", "godot")

def inspect_sheet(kind, rows, work):
    path = SOURCE / (kind + ".png")
    pixels = np.asarray(Image.open(path).convert("RGBA"))
    r, g, b = pixels[:, :, :3].astype(float).transpose(2, 0, 1)
    foreground = ~((g > r * 1.25 + 10) & (g > b * 1.25 + 10) & (g > 90))
    labels, _ = ndi.label(foreground, np.ones((3, 3)))
    sizes = np.bincount(labels.ravel())
    # Whole connected bodies, rather than fixed grid cuts: the supplied heads,
    # capes and floating bombs sometimes extend across nominal cell boundaries.
    bodies = sorted(range(1, len(sizes)), key=lambda k: sizes[k], reverse=True)[:rows * 4]
    regions = {}
    for k, region in enumerate(ndi.find_objects(labels), 1):
        if region is not None:
            ys, xs = region
            regions[k] = [xs.start, ys.start, xs.stop, ys.stop]
    bodies.sort(key=lambda k: (regions[k][1] + regions[k][3]) / 2)
    order = []
    for at in range(0, len(bodies), 4):
        order.extend(sorted(bodies[at:at + 4], key=lambda k: (regions[k][0] + regions[k][2]) / 2))
    centers = [((regions[k][0] + regions[k][2]) / 2, (regions[k][1] + regions[k][3]) / 2) for k in order]
    lookup = np.zeros(len(sizes), dtype=np.uint8)
    for at, k in enumerate(order, 1):
        lookup[k] = at
    h, w = foreground.shape
    for k, bounds in regions.items():
        if lookup[k] or sizes[k] < 6:
            continue
        x, y = (bounds[0] + bounds[2]) / 2, (bounds[1] + bounds[3]) / 2
        at = min(range(len(centers)), key=lambda i: ((x - centers[i][0]) / (w / 4)) ** 2 + ((y - centers[i][1]) / (h / rows)) ** 2)
        lookup[k] = at + 1
    ownership = lookup[labels]
    scale = 280.0 / (regions[order[0]][3] - regions[order[0]][1])
    frames = []
    for at, k in enumerate(order, 1):
        yy, xx = np.where(ownership == at)
        x0, y0, x1, y1 = int(xx.min()), int(yy.min()), int(xx.max()) + 1, int(yy.max()) + 1
        body = regions[k]
        # Both boots define the horizontal pivot; a detached floor basket never
        # moves the character's ground anchor or changes its anatomical scale.
        band = max(10, round((regions[order[0]][3] - regions[order[0]][1]) * .07))
        fy, fx = np.where(labels[max(body[1], body[3] - band):body[3]] == k)
        foot_x = (float(fx.min()) + float(fx.max()) + 1) / 2
        frames.append({"bounds": [x0, y0, x1 - x0, y1 - y0], "foot": [foot_x, body[3]]})
    mask = work / (kind + ".bin")
    mask.write_bytes(ownership.tobytes())
    return {"kind": kind, "source": str(path), "mask": str(mask), "rows": rows, "scale": scale, "frames": frames}

def main():
    with tempfile.TemporaryDirectory(prefix="scarlet-import-") as temporary:
        work = Path(temporary)
        sheets = [inspect_sheet(kind, rows, work) for kind, rows in [("idle", 2), ("attack", 3), ("ultimate", 4)]]
        manifest = work / "manifest.json"
        manifest.write_text(json.dumps(sheets))
        command = [GODOT, "--headless", "--path", str(ROOT)]
        metadata = work / "scarlet-layout.json"
        subprocess.run(command + ["--script", "res://tools/import_scarlet_redesign.gd", "--", str(manifest), str(metadata)], check=True)
        layout_path = ROOT / "assets/characters/FRAME_LAYOUT.json"
        layout = json.loads(layout_path.read_text())
        layout["heroes"]["scarlet"] = json.loads(metadata.read_text())
        layout_path.write_text(json.dumps(layout, indent=2) + "\n")
        subprocess.run(command + ["--editor", "--import", "--quit"], check=True)
        subprocess.run(command + ["--script", "res://tools/apply_animation_layout.gd", "--", "scarlet"], check=True)
    hashes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in SOURCE.glob("*.png")}
    (SOURCE / "SHA256.json").write_text(json.dumps(hashes, indent=2) + "\n")

if __name__ == "__main__":
    main()
