#!/usr/bin/env bash
set -euo pipefail

echo "========================================="
echo "   ENTERPRISE GITOPS DRIFT DETECTOR      "
echo "========================================="

python3 /home/dev/Documents/enterprise-platform-lab/python/enterprise_platform_tools/cli.py gitops
