"""Build editable Godot atlases/scenes. Source PNGs are never modified."""
import json, shutil
from pathlib import Path
from PIL import Image


def gutter(counts, expected, radius):
    """Choose a low-alpha separator, rather than cutting through an adjacent pose."""
    candidates = range(max(1, int(expected - radius)), min(len(counts) - 1, int(expected + radius)))
    return min(candidates, key=lambda at: (counts[at], abs(at - expected)))


root = Path(__file__).resolve().parents[1]
manifest = json.loads((root/'assets/enemies/PROMPTS.json').read_text())
for chapter, item in enumerate(manifest['assets'], 1):
    path = root/'assets/enemies'/f"{item['key']}.png"
    if not path.exists():
        shutil.copy2(item['source'], path)
    image = Image.open(path).convert('RGBA')
    width, height = image.size
    alpha = image.getchannel('A')
    occupied = [[value > 32 for value in alpha.crop((0, y, width, y + 1)).getdata()] for y in range(height)]
    rows = [sum(row) for row in occupied]
    row_cuts = [0] + [gutter(rows, height * k / 4, 55) for k in range(1, 4)] + [height]
    # AI sheets do not have exact equal-cell spacing. Isolate rows at transparent
    # gutters and pad with AtlasTexture.margin; never resample source artwork.
    canvas = 400
    lines = ['[gd_resource type="SpriteFrames" load_steps=18 format=3]', '',
             f'[ext_resource type="Texture2D" path="res://assets/enemies/{path.name}" id="1"]', '']
    for row in range(4):
        top, bottom = row_cuts[row:row + 2]
        columns = [sum(occupied[y][x] for y in range(top, bottom)) for x in range(width)]
        col_cuts = [0] + [gutter(columns, width * k / 4, 24) for k in range(1, 4)] + [width]
        for column in range(4):
            left, right = col_cuts[column:column + 2]
            cw, ch = right - left, bottom - top
            lines += [f'[sub_resource type="AtlasTexture" id="Frame_{row}_{column}"]',
                      'atlas = ExtResource("1")',
                      f'region = Rect2({left}, {top}, {cw}, {ch})',
                      f'margin = Rect2({(canvas-cw)/2:g}, {canvas-ch}, {canvas-cw}, {canvas-ch})',
                      'filter_clip = true', '']
    lines += ['[resource]', 'animations = [']
    for row, name in enumerate(['idle','attack','boss_idle','boss_attack']):
        lines += ['{', '"frames": [']
        for column in range(4):
            duration = [4.0, 1.0, 0.35, 1.5][column] if row%2 == 0 else 1.0
            lines += ['{ "duration": %g, "texture": SubResource("Frame_%d_%d") }%s' % (duration,row,column,',' if column<3 else '')]
        lines += ['],', f'"loop": {"true" if row%2==0 else "false"},', f'"name": &"{name}",', f'"speed": {4 if row%2==0 else 8}.0', '}'+(',' if row<3 else '')]
    lines += [']','']
    (root/'assets/enemies'/f'chapter_{chapter:02d}_frames.tres').write_text('\n'.join(lines))
    (root/'scenes/enemies'/f'chapter_{chapter:02d}.tscn').write_text(f'''[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/enemy.gd" id="1"]
[ext_resource type="SpriteFrames" path="res://assets/enemies/chapter_{chapter:02d}_frames.tres" id="2"]

[node name="Chapter{chapter:02d}Enemy" type="AnimatedSprite2D"]
texture_filter = 4
script = ExtResource("1")
sprite_frames = ExtResource("2")
animation = &"idle"
centered = false
''')
    print(path.name, width, height)
