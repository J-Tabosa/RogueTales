# Active character art

Each hero has one folder under `assets/characters/<id>/`.

- The eleven revised heroes use `frames.tres`, `idle.webp`, `attack.webp`, `ultimate.webp`, `portrait.webp` and `fx.webp`. The WebP paintings retain their original bytes, dimensions and lossless transparency.
- `FRAME_LAYOUT.json` holds the shared 768 × 768 logical canvas, ground anchors and per-pose mesh geometry. `ART_PROMPTS.json` records the source art references.
- Puss still uses his active native JPEG sheets, lossless `_alpha.png` masks and `frames.tres`; he has no replacement WebP animation set.
- `effects.jpg` and `effects_alpha.png` are the six-frame basic spell/legacy burst effects still used by `scripts/character_effects.gd`. They are separate from the twelve-frame `fx.webp` Ultimate effects and must remain.
- HD UI portraits in `assets/portraits_hd/` take precedence over `portrait.webp`. Puss uses his current `display.jpg` plus alpha mask.

Replaced JPEG animation sheets, portraits and meshes have been removed rather than archived in the exported asset tree. Runtime scenes, UI art, Ultimate effects, tests and rebuild tools use the same character folders.

To rebuild the current WebP meshes without changing the paintings:

```sh
godot --headless --path . --script res://tools/apply_animation_layout.gd
```

To reimport Scarlet's approved original paintings:

```sh
GODOT=/path/to/godot python tools/import_scarlet_redesign.py
```

`sources.json` now lists only the active JPEG effects, Puss, arenas and secret art. `tools/build_art.py` rebuilds those dependencies; it no longer recreates replaced hero sheets. Older preparation scripts describe previous source pipelines and are not the current WebP importer.

Validate character resources after moving assets:

```sh
godot --headless --path . --script res://tests/character_asset_paths.gd
godot --headless --path . --script res://tests/art_integration.gd
```
