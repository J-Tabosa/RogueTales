# maria

Source sheets generated with the integrated ImageGen tool using the character reference supplied by the user. The original `actions.png` and `walk.png` remain unchanged. `actions_atlas.png` and `walk_atlas.png` are Godot-prepared runtime atlases: source silhouettes are isolated from neighboring poses, packed with transparent padding and normalized to a shared foot anchor. No new poses are synthesized in that preparation.

Edit `frames.tres` and `scenes/heroes/maria.tscn` in Godot. Four animations match Scarlet: idle 4 at 2 FPS, blink 4 at 12 FPS, walk 16 at 12 FPS, attack 10 at 10 FPS. The attack animation also carries the unique ULT, with a distinct combat effect at impact.

To regenerate runtime atlases after changing source art, install Pillow, NumPy and SciPy, set `GODOT` to Godot 4.7, then run `python tools/prepare_roster.py`.
