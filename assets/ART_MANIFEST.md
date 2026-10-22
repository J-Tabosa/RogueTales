# Generated game artwork

Created with the built-in ImageGen tool from user-provided character references. Runtime packing is implemented in `tools/prepare_roster.py` and `tools/pack_roster.gd`.

| Character | Source sheets | Runtime atlases | Prompts |
| --- | --- | --- | --- |
| joao | `joao/actions.png`, `joao/walk.png` | `joao/actions_atlas.png`, `joao/walk_atlas.png` | [joao/PROMPTS.json](joao/PROMPTS.json) |
| maria | `maria/actions.png`, `maria/walk.png` | `maria/actions_atlas.png`, `maria/walk_atlas.png` | [maria/PROMPTS.json](maria/PROMPTS.json) |
| alice | `alice/actions.png`, `alice/walk.png` | `alice/actions_atlas.png`, `alice/walk_atlas.png` | [alice/PROMPTS.json](alice/PROMPTS.json) |
| puss | `puss/actions.png`, `puss/walk.png` | `puss/actions_atlas.png`, `puss/walk_atlas.png` | [puss/PROMPTS.json](puss/PROMPTS.json) |
| matches | `matches/actions.png`, `matches/walk.png` | `matches/actions_atlas.png`, `matches/walk_atlas.png` | [matches/PROMPTS.json](matches/PROMPTS.json) |
| peter | `peter/actions.png`, `peter/walk.png` | `peter/actions_atlas.png`, `peter/walk_atlas.png` | [peter/PROMPTS.json](peter/PROMPTS.json) |
| aladin | `aladin/actions.png`, `aladin/walk.png` | `aladin/actions_atlas.png`, `aladin/walk_atlas.png` | [aladin/PROMPTS.json](aladin/PROMPTS.json) |

New lateral arena: [`ui/storybook_battle.png`](ui/storybook_battle.png). Full production prompt: [`ui/storybook_battle_prompt.json`](ui/storybook_battle_prompt.json).

Each character has idle 4, blink 4, walk 16 and attack 10 frames. Ultimates share attack animation timing and apply a unique effect once at impact. All paths above are relative to `assets/`.
