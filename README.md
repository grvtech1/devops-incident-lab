# DevOps Incident Lab

A deliberately breakable Kubernetes workload for learning production diagnosis, mitigation, recovery, GitOps, and evidence-based incident communication.

The sample API is intentionally small. The engineering work is the platform around it: container security, Kubernetes rollout behavior, metrics, alerts, GitOps reconciliation, failure injection, recovery validation, and post-incident documentation.

## What you will prove

- Build and run an OCI image from a hardened Dockerfile.
- Operate a three-node kind cluster whose nodes use containerd internally.
- Diagnose failures through Deployments, ReplicaSets, pods, events, probes, Services, EndpointSlices, logs, metrics, and node state.
- Separate GitHub Actions CI from Argo CD deployment reconciliation.
- Detect both platform failures and customer-visible application failures.
- Produce incident evidence that can be explained in an interview.

## Architecture

```text
GitHub push
   |
   +-- GitHub Actions: test -> build -> scan -> SBOM -> GHCR
   |                                      |
   |                                      +-- GitOps promotion PR
   |
   +-- Argo CD watches approved manifests
                         |
                         v
                 Kubernetes / containerd
                         |
              +----------+----------+
              |                     |
         incident-api          Service endpoint
              |
     Prometheus -> Grafana
              |
         Alertmanager
```

## Prerequisites

Run the lab from WSL2. The fast path requires:

- Docker with a reachable daemon
- kind
- kubectl
- curl
- Bash

Helm is required only for the observability stack. Argo CD is installed through its versioned manifest.

## Start the lab

```bash
cd /mnt/c/Users/Gaurav/Documents/Codex/devops-incident-lab
make preflight
make bootstrap
make smoke
./scripts/lab.sh list
```

The bootstrap operation creates `kind-incident-lab`, builds `devops-incident-lab:local`, loads it into the kind nodes, deploys two replicas, and waits for rollout. The smoke test checks the Service DNS/ClusterIP path from inside the cluster, then validates readiness, order creation, and metrics through a temporary local port-forward. Application replicas use a hard topology-spread constraint across eligible worker hostnames so the node-failure exercise starts with one replica per worker. The constraint explicitly honors node taints, excluding the unschedulable control-plane hostname from skew calculations.

The local deploy script restarts an existing Deployment after loading a rebuilt `:local` image because an unchanged pod template does not trigger a rollout. This is a kind-lab convenience only. Production delivery should publish an immutable version tag or digest and update the declarative workload reference so the exact artifact is attributable and rollbackable.

## Practice one incident

```bash
./scripts/lab.sh start 03
./scripts/lab.sh status

# Investigate without reading the solution.
kubectl -n incident-lab get pods --show-labels
kubectl -n incident-lab get svc,endpointslice
kubectl -n incident-lab get events --sort-by=.metadata.creationTimestamp

./scripts/collect-evidence.sh 03
./scripts/lab.sh check 03
./scripts/lab.sh recover 03
make smoke
./scripts/lab.sh solution 03
```

The injector refuses to run unless the current context is `kind-incident-lab`. This prevents accidental execution against another cluster.

## Incident catalog

| ID | Failure | Primary lesson |
|---|---|---|
| 01 | Invalid runtime configuration | CrashLoop, ReplicaSets, rollout containment |
| 02 | Incorrect readiness probe | Ready versus live; stalled safe rollout |
| 03 | Service selector drift | Service-to-EndpointSlice traffic path |
| 04 | OOMKilled container | cgroups, limits, exit 137, evidence-based sizing |
| 05 | High HTTP error rate | Business SLI versus green pod status |
| 06 | Imperative GitOps drift | Desired state, reconciliation, break-glass tradeoff |
| 07 | Worker-node failure | Node health, containerd, rescheduling, resilience |

## Install observability

```bash
export GRAFANA_ADMIN_PASSWORD='use-a-local-non-reused-password'
bash scripts/install-observability.sh

kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-alertmanager 9093:9093
```

The chart version is pinned in the installer. Upgrade it deliberately after reading upstream notes and validating the rendered manifests. The installer waits up to 20 minutes for first-time image pulls; set `OBSERVABILITY_HELM_TIMEOUT` to override that limit when needed.

The workflow examples use versioned action releases for readability. Before reusing them with valuable organization secrets, pin every action to a reviewed full commit SHA and automate controlled updates.

## Enable GitOps

Push this repository to GitHub, make the repository accessible to Argo CD, and run:

```bash
export REPO_URL='https://github.com/YOUR_USER/devops-incident-lab.git'
export GITOPS_PATH='k8s/overlays/dev'
bash scripts/install-argocd.sh
```

The Argo CD Application has pruning and self-healing enabled. Do not point the lab Application at an unrelated cluster.

The installer refuses any context except `kind-incident-lab`, waits up to 15 minutes for first-time image pulls, and exits only after the Application reaches `Synced` and `Healthy`. Set `ARGOCD_WAIT_TIMEOUT` when the control-plane wait needs a different limit.

## Seven-day confidence path

1. Deploy and explain every Kubernetes object without incidents.
2. Complete incidents 01 and 02 using only CLI evidence.
3. Complete incidents 03 and 04, then explain traffic and memory paths aloud.
4. Install observability and complete incident 05 from dashboard to rollback.
5. Push to GitHub, run CI, install Argo CD, and complete incident 06.
6. Complete node failure incident 07 and inspect containerd with `crictl` inside a kind node.
7. Redo three randomly selected incidents without solutions and record interview answers.

## Evidence standard

Every completed incident needs:

- UTC start, detection, mitigation, recovery, and validation timestamps
- customer-visible impact statement
- commands and outputs that changed the hypothesis
- root cause and contributing controls
- recovery command and smoke-test result
- prevention action with an owner or implementation commit
- a two-minute interview explanation

Use [evidence/TEMPLATE.md](evidence/TEMPLATE.md). Generated evidence under `evidence/runs/` is ignored so you can remove secrets and select only safe artifacts before publishing.

Published example: [Incident 01 - CrashLoop from invalid runtime configuration](evidence/examples/incident-01-crashloop-invalid-config.md).

Published example: [Incident 02 - Stalled rollout from a bad readiness probe](evidence/examples/incident-02-stalled-rollout-readiness.md).

Published example: [Incident 03 - Service outage from selector drift](evidence/examples/incident-03-service-selector-outage.md).

Published example: [Incident 04 - OOMKilled from an unsafe memory allocation](evidence/examples/incident-04-oomkilled-memory-limit.md).

## Production boundary

This is an original portfolio lab, not a copy of BillFree and not evidence of historical company tenure. After you personally run the scenarios, you can accurately claim that you built and operated this lab. Company-production claims require separate company evidence and authorization.

## Upstream references

- [kind documentation](https://kind.sigs.k8s.io/)
- [Argo CD getting started](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Trivy documentation](https://trivy.dev/)
- [GitHub container publishing](https://docs.github.com/en/actions/tutorials/publish-packages/publish-docker-images)
