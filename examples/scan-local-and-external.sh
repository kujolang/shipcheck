#!/usr/bin/env bash
set -euo pipefail

external_dir="${1:-../kujo-spec}"

kujo run shipcheck.kujo scan --dir .

if [[ -d "$external_dir" ]]; then
	kujo run shipcheck.kujo scan --dir "$external_dir" --format json
else
	printf 'Skipping external scan; directory not found: %s\n' "$external_dir" >&2
fi
