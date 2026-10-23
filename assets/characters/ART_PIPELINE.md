# Active character art

The game scenes use these native-resolution JPEG sheets and `frames.tres` resources. Each JPEG has a same-size `_alpha.png` lossless mask. JPEG alone cannot encode transparency: the actor shader samples the matching mask, and effects/static portraits compose the pair once into a shared texture. No opaque rectangles are rendered behind characters or spells.

Each of the ten revised heroes has 34 animation frames: idle 4, idle variation 4, walk 16 and attack 10. The native alpha contours generate separate padded meshes, so hair, hats and weapons can cross a source grid boundary without being cut by a rectangular crop. All new meshes use a shared foot anchor with generous outer bounds. Human heights match; Puss is half height and Little Match Girl is three-quarter height.

The active arena images are `assets/biomes/arena_*.jpg`. Their projection reserves the lower 64% of the battlefield for a deeper ground plane, with fixed mirrored formation slots, at most three units in each class row. Health and mana use themed numeric panels.

Replaced artwork and editable source images are archived in `old/`. That directory is ignored by Godot's importer and excluded from exports. Existing UI, enemies, Scarlet and Snow White remain active assets and are not obsolete backups.

To rebuild, install Pillow, NumPy and SciPy, then run `GODOT=/path/to/godot python tools/build_art.py`. The Python step only inspects source alpha to calculate ownership metadata; Godot performs JPEG/alpha conversion and builds the meshes. Image-generation references and the exact source-to-output mapping are recorded in `sources.json` and `old/source/PROMPTS.json`.
