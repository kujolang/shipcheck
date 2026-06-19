#!/usr/bin/env bash
set -euo pipefail

KUJO_BIN="${KUJO_BIN:-kujo}"
external_dir="${1:-../kujo-spec}"

"$KUJO_BIN" run shipcheck.kujo scan --dir .

if [[ -d "$external_dir" ]]; then
	"$KUJO_BIN" run shipcheck.kujo scan --dir "$external_dir" --format json
else
	printf 'Skipping external scan; directory not found: %s\n' "$external_dir" >&2
fi
