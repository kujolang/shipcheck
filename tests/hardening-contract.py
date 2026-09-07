#!/usr/bin/env python3
"""Offline behavior regressions; KUJO_BIN selects the runtime. No pip packages."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
KUJO = os.environ.get('KUJO_BIN', 'kujo')


class HardeningContract(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='shipcheck-hardening-')
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)

    def write(self, name, text):
        path = self.repo / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)

    def run_cli(self, command='scan', *args, status=0):
        p = subprocess.run([KUJO, 'run', str(ROOT / 'shipcheck.kujo'), command,
                            '--dir', str(self.repo), *args], capture_output=True, text=True, timeout=30)
        self.assertEqual(p.returncode, status, p.stdout + p.stderr)
        return p.stdout

    def scan(self):
        data = json.loads(self.run_cli('scan', '--format', 'json'))
        checks = data['checks']
        self.assertEqual(len(checks), 16)
        self.assertEqual(len({c['name'] for c in checks}), 16)
        for c in checks:
            self.assertEqual(type(c['passed']), int)
            self.assertIn(c['passed'], (0, 1))
            self.assertIn(c['severity'], ('info', 'warning', 'error'))
            for field in ('name', 'message', 'detail'):
                self.assertIsInstance(c[field], str)
        summary = data['summary']
        self.assertEqual(summary['passed'], sum(c['passed'] for c in checks))
        for level, field in [('error', 'failed_errors'), ('warning', 'warnings')]:
            self.assertEqual(summary[field], sum(not c['passed'] and c['severity'] == level for c in checks))
        self.assertEqual(summary['total_checks'], len(checks))
        self.assertEqual(summary['gate_passed'], int(summary['failed_errors'] == 0))
        return {c['name']: c for c in checks}

    def test_toml_syntax(self):
        self.write('kennel.toml', '[package] # legal comment\nname="a=b"\nversion="1.0.0"\ndescription="escaped \\\"quote\\\""\nlicense="MIT"\n[kujo]\nentry="main.kujo"\n')
        c = self.scan()
        self.assertEqual(c['kennel-manifest']['passed'], 1)
        self.assertEqual(c['version-metadata']['passed'], 1)

    def test_invalid_toml_cannot_pass(self):
        self.write('kennel.toml', '[package]\nversion="1.0.0"\nversion="2.0.0"\n')
        self.assertEqual(self.scan()['version-metadata']['passed'], 0)

    def test_manifest_field_types(self):
        self.write('kennel.toml', '[package]\nname=[]\nversion=false\ndescription={}\nlicense=3\n')
        c = self.scan()
        self.assertEqual(c['version-metadata']['passed'], 0)
        self.assertEqual(c['kennel-manifest']['passed'], 0)

    def test_command_and_entry_false_positives(self):
        self.write('kennel.toml', '[package]\nname="lint-fmt-entry"\n# entry = "main.kujo"\n')
        self.write('package.json', '{"description":"lint format", "dependencies":{"lint":"1"}}')
        self.write('Makefile', '# lint: format:\nmessage = lint format\nlint := variable\nformat := variable\n')
        c = self.scan()
        for name in ('lint-command', 'format-command', 'entry-point'):
            self.assertEqual(c[name]['passed'], 0, name)

    def test_real_commands(self):
        for filename, content in [
            ('kennel.toml', '[scripts]\n"lint:ci"="kujo lint main.kujo"\nfmt="kujo format main.kujo"\n'),
            ('package.json', '{"scripts":{"lint:ci":"eslint .", "format":"prettier ."}}'),
            ('Makefile', '.PHONY: lint fmt\nlint fmt:\n\t@echo ok\n')]:
            with self.subTest(filename=filename):
                self.write(filename, content)
                c = self.scan()
                self.assertEqual(c['lint-command']['passed'], 1)
                self.assertEqual(c['format-command']['passed'], 1)
                (self.repo / filename).unlink()

    def test_empty_scripts(self):
        self.write('package.json', '{"scripts":{"lint":"", "format":false}}')
        self.write('kennel.toml', '[scripts]\nlint=" "\nformat=[]\n')
        c = self.scan()
        self.assertEqual(c['lint-command']['passed'], 0)
        self.assertEqual(c['format-command']['passed'], 0)

    def test_regular_files_required(self):
        for name in ('README.md', 'LICENSE', 'CHANGELOG.md', 'kennel.toml', 'test_fake.kujo'):
            (self.repo / name).mkdir()
        c = self.scan()
        for name in ('readme', 'license', 'changelog', 'kennel-manifest', 'tests-exist'):
            self.assertEqual(c[name]['passed'], 0, name)

    def test_fifo_is_not_read(self):
        os.mkfifo(self.repo / 'README.md')
        os.mkfifo(self.repo / 'VERSION')
        self.assertEqual(self.scan()['readme']['passed'], 0)

    def test_stable_root_selection_and_concurrent_scans(self):
        from concurrent.futures import ThreadPoolExecutor
        self.write('test_z.kujo', 'func main() {}')
        self.write('test_a.kujo', 'func main() {}')
        with ThreadPoolExecutor(max_workers=3) as pool:
            outputs = list(pool.map(lambda _: self.run_cli('scan', '--format', 'json'), range(3)))
        self.assertEqual(len(set(outputs)), 1)
        c = {c['name']: c for c in json.loads(outputs[0])['checks']}
        self.assertEqual(c['tests-exist']['detail'], 'Matched: test_a.kujo')
        self.assertIn('test_a.kujo', c['entry-point']['message'])

    def test_target_must_be_directory(self):
        self.write('file', 'contents')
        self.repo = self.repo / 'file'
        self.assertIn('Not a directory:', self.run_cli(status=1))

    def test_empty_split_directory(self):
        self.assertIn('Missing value for --dir', self.run_cli('scan', '--dir', '', status=2))

    def test_equals_directory(self):
        target = self.repo / '=fixture'
        target.mkdir()
        p = subprocess.run([KUJO, 'run', str(ROOT / 'shipcheck.kujo'), 'scan',
                            '--dir==fixture', '--format=json'], cwd=self.repo, capture_output=True, text=True, timeout=30)
        self.assertEqual(p.returncode, 0, p.stdout+p.stderr)
        self.assertEqual(json.loads(p.stdout)['dir'], '=fixture')

    def test_release_note_manifest_versions(self):
        for name, content in [('package.json', '{"version":"2.3.4"}'),
                              ('Cargo.toml', '[package]\nversion="2.3.4"\n')]:
            with self.subTest(name=name):
                self.write(name, content)
                self.assertIn('# Release Notes — v2.3.4', self.run_cli('release-note'))
                (self.repo/name).unlink()

    def test_release_note_ignores_unrelated_readme(self):
        # A README directory previously crashed the unnecessary full scan.
        (self.repo/'README.md').mkdir()
        self.write('VERSION', '1.2.3')
        self.assertIn('# Release Notes — v1.2.3', self.run_cli('release-note'))

    def test_terminal_controls_preserve_json(self):
        self.repo = self.repo / 'path\x1b[31m\x85'
        self.repo.mkdir()
        self.write('VERSION', '1.0.0\x1b[2J')
        data = json.loads(self.run_cli('scan', '--format', 'json'))
        self.assertEqual(data['dir'], str(self.repo))
        for command in ('scan', 'checklist', 'release-note'):
            output = self.run_cli(command)
            self.assertNotIn('\x1b', output)
            self.assertNotIn('\x85', output)
            self.assertIn('\\u001b', output)

    def test_shell_quote_and_color(self):
        self.repo = self.repo / "repo's ; $(touch PWNED)"
        self.repo.mkdir()
        subprocess.run(['git', '-C', str(self.repo), 'init', '-q'], check=True)
        subprocess.run(['git', '-C', str(self.repo), '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                        'commit', '--allow-empty', '-qm', 'fixture commit'], check=True)
        subprocess.run(['git', '-C', str(self.repo), 'config', 'color.ui', 'always'], check=True)
        self.assertEqual(self.scan()['git-repo']['passed'], 1)
        output = self.run_cli('release-note')
        self.assertIn('fixture commit', output)
        self.assertNotIn('\x1b', output)
        self.assertFalse((ROOT/'PWNED').exists())


if __name__ == '__main__':
    unittest.main()
