#!/usr/bin/env python3
"""Compare a Git baseline with this checkout on identical metadata fixtures.

Usage: KUJO_BIN=/path/to/kujo python3 tests/benchmark.py BASE_REF OUTPUT_JSON
Timings are evidence, not a CI budget. Report equivalence is mandatory.
"""
import json
import os
from pathlib import Path
import statistics
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
KUJO = os.environ.get('KUJO_BIN', 'kujo')


def main():
    baseline, output = sys.argv[1:]
    receipt = {'baseline': baseline, 'runtime': subprocess.check_output([KUJO, '--version'], text=True).strip(),
               'samples_per_command': 7, 'fixtures': {}}
    with tempfile.TemporaryDirectory(prefix='shipcheck-benchmark-') as directory:
        temp = Path(directory)
        old = temp / 'baseline'
        for name in ('shipcheck.kujo', 'src/checks.kujo', 'src/scan.kujo', 'src/report.kujo'):
            path = old / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(subprocess.check_output(['git', 'show', f'{baseline}:{name}'], cwd=ROOT))
        for count in (0, 200):
            target = temp / f'library-{count}'
            target.mkdir()
            subprocess.run(['git', '-C', str(target), 'init', '-q'], check=True)
            for name, content in {'README.md': '# Library\nInstall and usage', 'VERSION': '1.0.0',
                                  'CHANGELOG.md': '# Changelog', 'tests/test.txt': 'test'}.items():
                path = target / name
                path.parent.mkdir(exist_ok=True)
                path.write_text(content)
            for i in range(count):
                (target / f'library_{i:03}.kujo').write_text('# library source without a CLI\n' * 140)
            fixture = {'root_source_files': count, 'source_bytes': count * 4200, 'commands': {}}
            for command in ('scan', 'release-note'):
                samples = {'before': [], 'after': []}
                outputs = {}
                for i in range(8):
                    # Alternate order to reduce systematic filesystem/cache bias.
                    for label in (('before', 'after') if i % 2 == 0 else ('after', 'before')):
                        entry = (old if label == 'before' else ROOT) / 'shipcheck.kujo'
                        args = [KUJO, 'run', str(entry), command, '--dir', str(target)]
                        if command == 'scan':
                            args += ['--format', 'json']
                        start = time.perf_counter()
                        p = subprocess.run(args, cwd=entry.parent, capture_output=True, timeout=30)
                        elapsed = time.perf_counter() - start
                        assert p.returncode == 0, p.stdout + p.stderr
                        outputs[label] = p.stdout
                        if i:
                            samples[label].append(elapsed)
                assert outputs['before'] == outputs['after'], (command, 'output changed')
                fixture['commands'][command] = {
                    label: {'seconds': values, 'median_seconds': statistics.median(values),
                            'stdout_bytes': len(outputs[label])} for label, values in samples.items()}
                fixture['commands'][command]['output_identical'] = True
            receipt['fixtures'][f'library-{count}'] = fixture
    Path(output).write_text(json.dumps(receipt, indent=2) + '\n')
    print(f'Benchmark passed: identical reports for 2 fixtures; evidence: {output}')


if __name__ == '__main__':
    main()
