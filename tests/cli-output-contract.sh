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
PY

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
