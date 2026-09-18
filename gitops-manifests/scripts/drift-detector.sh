#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "========================================="
echo "   ENTERPRISE GITOPS DRIFT DETECTOR      "
echo "========================================="

python3 "${REPO_ROOT}/scripts/drift-detector.py" "$@"
