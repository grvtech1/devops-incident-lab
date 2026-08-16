# Incident 01: CrashLoop from invalid runtime configuration

## Summary

- Environment: Local three-node kind cluster, namespace `incident-lab`
- Severity: SEV-3 (deployment blocked; no customer-visible impact)
- Duration: Approximately seven minutes
- Trigger: Invalid `BACKEND_URL` promoted through a ConfigMap
- Resolution: Restore the Git-declared value and restart the rollout

## Customer impact

No customer action failed. The new revision never became Ready, but the two old replicas remained available and continued accepting orders with HTTP 202. The impact was operational: the rollout was blocked and could not safely replace the previous revision.

## Detection and diagnosis

The Deployment showed `UP-TO-DATE=1` while the new ReplicaSet remained `READY=0`. Its candidate pod entered `CrashLoopBackOff` with exit code 1.

Competing hypotheses were tested in this order:

| Hypothesis | Evidence | Decision |
|---|---|---|
| Image unavailable | Scheduler reported the image was already present; the container started repeatedly | Rejected |
| Resource exhaustion | Last state was `Error`, exit 1; no `OOMKilled` or exit 137 | Rejected |
| Probe misconfiguration | Startup probe saw connection refused | Symptom, because the process exited before binding port 8080 |
| Invalid runtime configuration | Current and previous logs reported `BACKEND_URL is invalid: not-a-valid-url` | Confirmed |

The live ConfigMap differed from `k8s/base/configmap.yaml`, establishing configuration drift. The application validates `BACKEND_URL` during startup and exits 1 when URL parsing fails.

## Why customers remained protected

The Deployment uses `maxUnavailable: 0` and `maxSurge: 1`. Kubernetes created one candidate pod without removing either healthy old replica. The failed candidate was not Ready, so normal Service routing continued to use ready endpoints from the previous ReplicaSet.

## Mitigation and recovery

The `BACKEND_URL` value was restored to `http://dependency.incident-lab.svc.cluster.local:8080`. The Deployment was restarted and observed with `kubectl rollout status`.

Deleting healthy pods was deliberately avoided. Preserving the old ReplicaSet maintained service while Kubernetes evaluated corrected candidates.

## Validation

- Deployment reached `READY=2/2`, `UP-TO-DATE=2`, `AVAILABLE=2`.
- Two new pods ran with zero restarts across separate workers.
- EndpointSlice conditions showed both addresses as `ready=true`, `serving=true`, `terminating=false`.
- In-cluster Service DNS/ClusterIP readiness returned HTTP 200.
- Order creation returned HTTP 202 after recovery.
- Prometheus-format request and order counters were emitted.

The order counter restarted at `ord-00001` because this lab intentionally uses process-local memory. A production order service would use durable storage and globally safe identifiers.

## Prevention actions

| Action | Control type | Verification |
|---|---|---|
| Validate URL syntax and allowed hosts before ConfigMap promotion | Prevent | CI rejects an invalid fixture and accepts the rendered dev manifest |
| Alert on stalled Deployment progress and CrashLooping containers | Detect | Repeat Incident 01 with observability installed and capture firing/resolution times |
| Maintain an evidence-first configuration rollback runbook | Respond | Recover from a blind rerun within five minutes without reading the solution |

## Interview explanation

During a configuration rollout, the new Kubernetes ReplicaSet stalled while the existing replicas remained available. The candidate pod entered CrashLoopBackOff with exit code 1. Scheduling and image events were healthy, and the startup-probe failure was only a symptom: current and previous logs showed startup validation rejecting an invalid `BACKEND_URL` supplied by the ConfigMap. I confirmed orders still returned HTTP 202 through the old replicas, captured the broken state, restored the Git-declared URL, and restarted the rollout instead of deleting healthy pods. The corrected ReplicaSet reached two Ready replicas across both workers, and readiness, order and metrics checks passed. The prevention plan is semantic configuration validation in CI, rollout-stall alerting and a tested rollback runbook.
