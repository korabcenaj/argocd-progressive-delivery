#!/usr/bin/env bash
set -euo pipefail

ROLLOUT_NAME="${1:-payment-processor}"
NAMESPACE="${2:-prod}"

echo "Checking Argo Rollout status for '${ROLLOUT_NAME}' in namespace '${NAMESPACE}'..."
kubectl argo rollouts get rollout "${ROLLOUT_NAME}" -n "${NAMESPACE}" --watch
