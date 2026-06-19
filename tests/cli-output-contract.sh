#!/usr/bin/env bash
set -euo pipefail

KUJO_BIN="${KUJO_BIN:-kujo}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

shipcheck() {
	"$KUJO_BIN" run "$ROOT/shipcheck.kujo" "$@"
}

assert_output() {
	local name="$1"
	local expected="$2"
	local actual="$3"

	if [[ "$actual" != "$expected" ]]; then
		diff -u <(printf "%s\n" "$expected") <(printf "%s\n" "$actual")
		printf '%s\n' "FAILED: $name" >&2
		exit 1
	fi
}

expected_help="$(cat <<'EOF'
ShipCheck v0.1.0

A local developer tool that inspects a repository and produces
a release-readiness report.

Usage:
  kujo run shipcheck.kujo scan [--dir <path>] [--format markdown|json]
  kujo run shipcheck.kujo checklist [--dir <path>]
  kujo run shipcheck.kujo gate [--dir <path>] [--format markdown|json]
  kujo run shipcheck.kujo release-note [--dir <path>]
  kujo run shipcheck.kujo version
  kujo run shipcheck.kujo help

Commands:
  scan          Scan a repo and produce a release-readiness report
  checklist     Generate a release checklist
  gate          Run release gate checks (exits non-zero on failure)
  release-note  Draft release notes from recent commits
  version       Print version information
  help          Print this help message

Options:
  --dir         Target directory (default: current directory)
  --format      Output format: markdown (default) or json

Examples:
  kujo run shipcheck.kujo scan
  kujo run shipcheck.kujo scan --dir ../my-project --format json
  kujo run shipcheck.kujo checklist
  kujo run shipcheck.kujo gate
EOF
)"
assert_output "help output" "$expected_help" "$(shipcheck help)"

expected_version="$(cat <<'EOF'
ShipCheck v0.1.0
A Kujo ecosystem dogfood showcase tool.
Release-readiness scanner for local repositories.
EOF
)"
assert_output "version output" "$expected_version" "$(shipcheck version)"

json_output="$(shipcheck scan --dir "$ROOT" --format json)"
JSON_OUTPUT="$json_output" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["JSON_OUTPUT"])
assert data["tool"] == "shipcheck"
assert data["version"] == "0.1.0"
assert data["summary"]["total_checks"] == 16
assert len(data["checks"]) == 16
assert data["summary"]["gate_passed"] in (0, 1)
PY

gate_json_output="$(shipcheck gate --dir "$ROOT" --format json)"
JSON_OUTPUT="$gate_json_output" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["JSON_OUTPUT"])
assert data["tool"] == "shipcheck"
assert data["summary"]["gate_passed"] == 1
PY

set +e
bad_format_output="$(shipcheck scan --format yaml 2>&1)"
bad_format_status=$?
set -e

if [[ "$bad_format_status" -ne 2 ]]; then
	printf '%s\n' "FAILED: unsupported format should exit 2" >&2
	exit 1
fi

grep -q "Unsupported format: yaml" <<<"$bad_format_output"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

set +e
shipcheck gate --dir "$tmpdir" >"$tmpdir/gate.out"
gate_status=$?
set -e

if [[ "$gate_status" -ne 1 ]]; then
	printf '%s\n' "FAILED: gate should exit 1 for a non-repo fixture" >&2
	exit 1
fi

grep -q "Gate FAILED: Not all required checks passed." "$tmpdir/gate.out"

set +e
failed_gate_json="$(shipcheck gate --dir "$tmpdir" --format json)"
failed_gate_status=$?
set -e

if [[ "$failed_gate_status" -ne 1 ]]; then
	printf '%s\n' "FAILED: json gate should exit 1 for a non-repo fixture" >&2
	exit 1
fi

JSON_OUTPUT="$failed_gate_json" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["JSON_OUTPUT"])
assert data["summary"]["gate_passed"] == 0
assert data["summary"]["failed_errors"] > 0
PY

hostile_dir="$tmpdir/repo with spaces; touch $tmpdir/shipcheck-pwned"
mkdir -p "$hostile_dir"
git -C "$hostile_dir" init -q
printf '# Hostile Fixture\n' >"$hostile_dir/README.md"
printf '0.0.1\n' >"$hostile_dir/VERSION"
printf '# Changelog\n' >"$hostile_dir/CHANGELOG.md"
mkdir -p "$hostile_dir/tests"

hostile_json="$(shipcheck scan --dir "$hostile_dir" --format json)"
if [[ -e "$tmpdir/shipcheck-pwned" ]]; then
	printf '%s\n' "FAILED: scan executed shell metacharacters from --dir" >&2
	exit 1
fi

JSON_OUTPUT="$hostile_json" HOSTILE_DIR="$hostile_dir" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["JSON_OUTPUT"])
assert data["dir"] == os.environ["HOSTILE_DIR"]
assert any(check["name"] == "git-repo" and check["passed"] == 1 for check in data["checks"])
PY

shipcheck release-note --dir "$hostile_dir" >"$tmpdir/release-note.out"
if [[ -e "$tmpdir/shipcheck-pwned" ]]; then
	printf '%s\n' "FAILED: release-note executed shell metacharacters from --dir" >&2
	exit 1
fi

grep -q "# Release Notes" "$tmpdir/release-note.out"
