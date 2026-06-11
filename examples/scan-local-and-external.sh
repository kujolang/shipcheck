#!/usr/bin/env bash
set -euo pipefail

kujo run shipcheck.kujo -- scan --dir .
kujo run shipcheck.kujo -- scan --dir ../kujo-spec --format json
