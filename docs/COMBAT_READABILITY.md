# Combat loading and compact character information

Implemented in the requested order: attack preparation (6), compact run information (4/5), floor transition (3), health plates (2), line weight (1).

## Behavior

- Loading prepares party animation textures/materials and basic/ultimate effect atlases. Every encounter also prepares its actual allies/enemies, including secret enemies and recruits, in an offscreen viewport before permitting an action. Prepared resources remain cached. No attack is executed and no combat resource is spent by this preparation.
- The character sheet uses icon/value tiles for AP, AD, DEF, RES, HP, ESQ, QTD, MAN, CRIT and TAXA, plus INI. CRIT is the multiplier; TAXA is critical chance. The sheet portrait faces left independently of combat orientation.
- Basic/passive/special cards show calculated values, with physical damage red, magical blue, and real damage identified separately. Hover opens a description and calculation; mouse click or finger tap pins it. Close dismisses the description. Hover panels ignore mouse input; closing immediately detaches the panel so it cannot swallow the next input event.
- Basic/ultimate damage components are shared with live combat. Previews are target-independent and rounded, before defenses/criticals. Conditional target multipliers, extra hits and conditional equipment effects are explicitly excluded. Utility skills display their actual effect instead of fictitious damage.
- All nonzero run bonus totals are shown, distinguishing percentages, critical/evasion percentage points, and flat gains. Equipment, blessings and active conditions remain separate.
- Both arena projection shaders blend mapping slopes around the ground horizon, preserving the authored source art.
- Vertical formation depths are 0.40/0.66/0.92; two units use top/bottom. Viewport-based character height reserves the health plate plus an 8px gap per vertical slot. Size remains independent of enemy/party composition. Plates share their owner's depth rather than rendering above all bodies.
- Gallery portraits receive screen-sized ink reinforcement, stronger for Scarlet. Scarlet's combat animation shader also reinforces her existing contours. HD source images are preserved.

## Validation and limits

Tests use Godot 4.5.1 (the available executable). The project remains configured for 4.7. Rendered checks use OpenGL Compatibility with software rendering (Mesa llvmpipe), not a physical phone/GPU.

- `combat_readability.gd`: warmup completion/action gating/cache, reserved slot space, complete bonus display, eleven stat tiles, left-facing portrait, read-only previews, real finger+emulated-mouse input and persistent mouse hover at PC/mobile dimensions (1280×720, 540×960, 360×640).
- `rules_095.gd`: 53 checks.
- `wishes_silk_097.gd`: 655 checks. The fixture waits for preparation before casting.
- `arena_equipment_layout.gd`: PC/mobile geometry, health plates, equipment and rendering. The body/plate check now explicitly requires reserved vertical space.
- `visual_consistency.gd`: stable character scale across encounter compositions and retained information sections, with expectations updated for eleven compact stat tiles.
- `seasonal_ui_100.gd`: 2,220 checks across 130 full fourteen-unit scene fixtures.
- `seasonal_routes_100.gd`: route and terrain validation with updated formation depths.

The previous baseline investigation found unrelated failures in `ultimate_overhaul.gd` (assumes every authored attack has twelve frames) and `equipment_overhaul.gd` (assumes an older item count and that the consumable `travelers_page` is equipable). Those suites also fail on the unchanged parent commit.

No Android APK was exported. Frame-time improvements on the first attack and final appearance still need confirmation in the target Godot 4.7 build on physical PC/Android devices.
