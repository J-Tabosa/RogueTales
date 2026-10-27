#!/usr/bin/env python3
"""Canonical 0.9.6 regression runner. Historical superseded combat tests are excluded."""
import argparse, concurrent.futures, json, pathlib, subprocess, tempfile
SUITES = [
    'rules_095', 'boons_095', 'integration_095', 'corrections_096',
    'hd_portraits_093', 'auras_094', 'presentation_092', 'mobile_combat_fixes',
    'art_integration', 'encounter_difficulty', 'equipment_ui',
    'arena_equipment_layout', 'combat_presentation', 'mobile_ui_polish',
    'adventure_ui', 'recruitment', 'equipment_progression', 'endless_events',
    'expedition_ui', 'visual_consistency', 'worlds_polish',
]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default='godot')
    parser.add_argument('--logs', type=pathlib.Path)
    parser.add_argument('--jobs', type=int, default=4)
    parser.add_argument('--timeout', type=int, default=45)
    args = parser.parse_args()
    root = pathlib.Path(__file__).resolve().parents[1]
    logs = args.logs or pathlib.Path(tempfile.mkdtemp(prefix='roguetales-checks-'))
    logs.mkdir(parents=True, exist_ok=True)
    def check(suite):
        try:
            result = subprocess.run([args.godot, '--headless', '--path', str(root),
                '--script', f'res://tests/{suite}.gd'], capture_output=True,
                text=True, timeout=args.timeout)
            output = result.stdout + result.stderr
            code = result.returncode
        except subprocess.TimeoutExpired as exc:
            output = (exc.stdout or b'').decode(errors='replace') + (exc.stderr or b'').decode(errors='replace')
            code = 124
        (logs / f'{suite}.log').write_text(output, encoding='utf-8')
        ok = code == 0 and 'SCRIPT ERROR' not in output and 'ERROR:' not in output
        print(f'{"PASS" if ok else "FAIL"} {suite}', flush=True)
        return {'suite': suite, 'passed': ok, 'code': code}
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, min(4, args.jobs))) as pool:
        results = list(pool.map(check, SUITES))
    (logs / 'results.json').write_text(json.dumps(results, indent=2), encoding='utf-8')
    passed = sum(item['passed'] for item in results)
    print(f'{passed}/{len(results)} suites passed. Logs: {logs}', flush=True)
    return 0 if passed == len(results) else 1

if __name__ == '__main__':
    raise SystemExit(main())
