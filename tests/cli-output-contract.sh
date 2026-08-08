#!/usr/bin/env bash
set -euo pipefail

KUJO_BIN="${KUJO_BIN:-kujo}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

shipcheck() {
	"$KUJO_BIN" run "$ROOT/shipcheck.kujo" "$@"
}

shipcheck_output() {
	shipcheck "$@" 2>&1 | sed '/^Compiler optimization:/d'
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
ShipCheck v1.0.0

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
assert_output "help output" "$expected_help" "$(shipcheck_output help)"

expected_version="$(cat <<'EOF'
ShipCheck v1.0.0
A Kujo ecosystem dogfood showcase tool.
Release-readiness scanner for local repositories.
EOF
)"
assert_output "version output" "$expected_version" "$(shipcheck_output version)"

json_output="$(shipcheck_output scan --dir "$ROOT" --format json)"
JSON_OUTPUT="$json_output" ROOT="$ROOT" python3 - <<'PY'
import json
import os
from pathlib import Path

data = json.loads(os.environ["JSON_OUTPUT"])
schema = json.loads((Path(os.environ["ROOT"]) / "schemas" / "shipcheck-report.schema.json").read_text())
assert schema["$id"].endswith("shipcheck-report-0.1.json")
assert set(schema["required"]).issubset(data)
assert set(schema["properties"]["summary"]["required"]).issubset(data["summary"])
assert all(set(schema["properties"]["checks"]["items"]["required"]).issubset(check) for check in data["checks"])
assert data["tool"] == "shipcheck"
assert data["version"] == "1.0.0"
assert data["summary"]["total_checks"] == 16
assert len(data["checks"]) == 16
assert data["summary"]["gate_passed"] in (0, 1)
PY

gate_json_output="$(shipcheck_output gate --dir "$ROOT" --format json)"
JSON_OUTPUT="$gate_json_output" ROOT="$ROOT" python3 - <<'PY'
import json
import os
from pathlib import Path

data = json.loads(os.environ["JSON_OUTPUT"])
schema = json.loads((Path(os.environ["ROOT"]) / "schemas" / "shipcheck-report.schema.json").read_text())
assert set(schema["required"]).issubset(data)
assert data["tool"] == "shipcheck"
assert data["summary"]["gate_passed"] == 1
PY

set +e
bad_format_output="$(shipcheck_output scan --format yaml)"
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
shipcheck_output gate --dir "$tmpdir" >"$tmpdir/gate.out"
gate_status=$?
set -e

if [[ "$gate_status" -ne 1 ]]; then
	printf '%s\n' "FAILED: gate should exit 1 for a non-repo fixture" >&2
	exit 1
fi

grep -q "Gate FAILED: Not all required checks passed." "$tmpdir/gate.out"

set +e
failed_gate_json="$(shipcheck_output gate --dir "$tmpdir" --format json)"
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

hostile_json="$(shipcheck_output scan --dir "$hostile_dir" --format json)"
if [[ -e "$tmpdir/shipcheck-pwned" ]]; then
	printf '%s\n' "FAILED: scan executed shell metacharacters from --dir" >&2
	exit 1
fi

JSON_OUTPUT="$hostile_json" HOSTILE_DIR="$hostile_dir" ROOT="$ROOT" python3 - <<'PY'
import json
import os
from pathlib import Path

data = json.loads(os.environ["JSON_OUTPUT"])
schema = json.loads((Path(os.environ["ROOT"]) / "schemas" / "shipcheck-report.schema.json").read_text())
assert set(schema["required"]).issubset(data)
assert data["dir"] == os.environ["HOSTILE_DIR"]
assert any(check["name"] == "git-repo" and check["passed"] == 1 for check in data["checks"])
PY

shipcheck_output release-note --dir "$hostile_dir" >"$tmpdir/release-note.out"
if [[ -e "$tmpdir/shipcheck-pwned" ]]; then
	printf '%s\n' "FAILED: release-note executed shell metacharacters from --dir" >&2
	exit 1
fi

grep -q "# Release Notes" "$tmpdir/release-note.out"

# Representative fixture matrix: a conventional Node project and a complete
# Kujo project must both pass the blocking gate without relying on this repo.
node_dir="$tmpdir/node-project"
mkdir -p "$node_dir/tests"
git -C "$node_dir" init -q
printf '# Node Fixture\n\n## Install\n\n## Usage\n' >"$node_dir/README.md"
printf '{"name":"node-fixture","version":"0.0.1","scripts":{"lint":"echo lint","format":"echo format"}}\n' >"$node_dir/package.json"
printf '# Changelog\n' >"$node_dir/CHANGELOG.md"
printf 'test fixture\n' >"$node_dir/tests/example.test.js"
node_json="$(shipcheck_output gate --dir "$node_dir" --format json)"
JSON_OUTPUT="$node_json" ROOT="$ROOT" python3 - <<'PY'
import json
import os
from pathlib import Path

data = json.loads(os.environ["JSON_OUTPUT"])
schema = json.loads((Path(os.environ["ROOT"]) / "schemas" / "shipcheck-report.schema.json").read_text())
assert set(schema["required"]).issubset(data)
assert data["project_type"] == "node"
assert data["summary"]["gate_passed"] == 1
PY

kujo_dir="$tmpdir/kujo-project"
mkdir -p "$kujo_dir/tests" "$kujo_dir/examples" "$kujo_dir/docs"
git -C "$kujo_dir" init -q
printf '# Kujo Fixture\n\n## Quick Start\n\n## Usage\n' >"$kujo_dir/README.md"
printf '# Changelog\n' >"$kujo_dir/CHANGELOG.md"
printf 'fixture\n' >"$kujo_dir/tests/smoke.kujo"
printf 'example\n' >"$kujo_dir/examples/basic.kujo"
printf 'docs\n' >"$kujo_dir/docs/usage.md"
printf '[package]\nname = "kujo-fixture"\nversion = "0.0.1"\ndescription = "fixture"\nlicense = "MIT"\n[kujo]\nentry = "main.kujo"\n' >"$kujo_dir/kennel.toml"
printf 'func main() {}\n' >"$kujo_dir/main.kujo"
kujo_json="$(shipcheck_output gate --dir "$kujo_dir" --format json)"
JSON_OUTPUT="$kujo_json" ROOT="$ROOT" python3 - <<'PY'
import json
import os
from pathlib import Path

data = json.loads(os.environ["JSON_OUTPUT"])
schema = json.loads((Path(os.environ["ROOT"]) / "schemas" / "shipcheck-report.schema.json").read_text())
assert set(schema["required"]).issubset(data)
assert data["project_type"] == "kujo"
assert data["summary"]["gate_passed"] == 1
PY
