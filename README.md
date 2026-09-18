# GitOps Progressive Delivery with Argo CD + Argo Rollouts

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.28%2B-blue.svg)](https://kubernetes.io/)
[![Argo CD](https://img.shields.io/badge/Argo_CD-v2.10-orange.svg)](https://argo-cd.readthedocs.io/)
[![Argo Rollouts](https://img.shields.io/badge/Argo_Rollouts-v1.6-red.svg)](https://argoproj.github.io/argo-rollouts/)
[![Prometheus](https://img.shields.io/badge/Prometheus-Metric_Gates-informational.svg)](https://prometheus.io/)

Declarative, automated GitOps delivery platform leveraging **Argo CD (App-of-Apps pattern)** and **Argo Rollouts** for progressive blue/green deployment strategies protected by automated Prometheus metric gates and drift reconciliation.

---

## Architecture Overview

```
[ Git Repository: main ] ---> [ Argo CD Root Application (App-of-Apps) ]
                                            |
                         Reconciles Desired Cluster State
                                            v
               +------------------------------------------------+
               | Argo Rollout Controller                        |
               |                                                |
               | 1. Deploys candidate version to Preview Pods   |
               | 2. Executes Prometheus AnalysisTemplate gates: |
               |    - HTTP Success Rate >= 99%                  |
               |    - P95 Response Latency <= 200ms             |
               +------------------------------------------------+
                    |                                    |
            Analysis PASSED                      Analysis FAILED
                    |                                    |
                    v                                    v
     [ Traffic Switch to Active ]              [ Automated Rollback ]
     (Zero Downtime Blue/Green)                (Active pods remain untouched)
```

---

## Key Capabilities

1. **Argo CD App-of-Apps & ApplicationSets**:
   - Centralized declarative management in [`argocd/01-root-app-of-apps.yaml`](argocd/01-root-app-of-apps.yaml) syncing child workloads and infrastructure.
   - Dynamic multi-environment generator in [`argocd/02-applicationset-environments.yaml`](argocd/02-applicationset-environments.yaml) deploying staging and production clusters with branch-specific revisions.

2. **Progressive Delivery with Argo Rollouts**:
   - **Blue/Green Strategy**: Implemented in [`argo-rollouts/01-blue-green-rollout.yaml`](argo-rollouts/01-blue-green-rollout.yaml) utilizing active (`payment-processor-active`) and preview (`payment-processor-preview`) Kubernetes services with automated cutover delays.
   - **Canary Strategy**: Step-based traffic ramping (20% -> 40% -> 60% -> 80% -> 100%) in [`argo-rollouts/02-canary-rollout.yaml`](argo-rollouts/02-canary-rollout.yaml).

3. **Automated Prometheus Metric Gates**:
   - `AnalysisTemplate` definitions in [`argo-rollouts/03-analysis-templates.yaml`](argo-rollouts/03-analysis-templates.yaml) querying real-time Prometheus metrics during rollouts:
     - `http-success-rate`: Queries `http_requests_total`, enforcing `result[0] >= 0.99`.
     - `http-p95-latency`: Queries histogram quantiles, enforcing `p95 <= 200ms`.
   - Any degradation exceeding failure limits automatically aborts promotion and scales down preview pods, preventing broken releases from touching end users.

4. **Drift Detection & Readiness Probe Remediation**:
   - Standalone drift auditor in [`scripts/drift-detector.py`](scripts/drift-detector.py) analyzing live Kubernetes cluster objects against Git source of truth.
   - Diagnoses out-of-sync workloads, probe mismatches (e.g., mismatched port or path in readiness probes), and automatically reports drift status.

---

## Directory Structure

```text
├── README.md
├── argo-rollouts/
│   ├── 01-blue-green-rollout.yaml           # Blue/Green Rollout with pre-promotion gates
│   ├── 02-canary-rollout.yaml               # Step-based Canary Rollout specification
│   ├── 03-analysis-templates.yaml           # Prometheus metric analysis templates
│   └── 04-services.yaml                     # Active, preview, and canary Kubernetes Services
├── argocd/
│   ├── 01-root-app-of-apps.yaml             # Argo CD root App-of-Apps pattern
│   └── 02-applicationset-environments.yaml  # Multi-environment ApplicationSet
├── gitops-manifests/                        # Supplementary GitOps configurations
└── scripts/
    ├── drift-detector.py                    # Standalone GitOps drift detection CLI
    ├── drift-detector.sh                    # Shell wrapper for CI/CD runners
    └── rollout-status.sh                    # Live terminal rollout watcher
```

---

## Usage & Verification

### 1. Deploy Progressive Rollout
```bash
kubectl apply -f argo-rollouts/04-services.yaml
kubectl apply -f argo-rollouts/03-analysis-templates.yaml
kubectl apply -f argo-rollouts/01-blue-green-rollout.yaml
```

### 2. Monitor Live Rollout Progression
```bash
./scripts/rollout-status.sh payment-processor prod
```

### 3. Run Drift Detection Gate
```bash
python3 scripts/drift-detector.py --namespace argocd
```
