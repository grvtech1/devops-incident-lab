# Incident 04: OOMKilled from an unsafe memory allocation

## Summary

- Environment: Local three-node kind cluster, namespace `incident-lab`
- Severity: SEV-3 (new revision blocked; no customer-visible impact)
- Duration: Approximately three minutes
- Trigger: Startup allocation exceeded the container cgroup limit
- Resolution: Remove the unsafe allocation; do not raise the limit without sizing evidence

## Customer impact

No customer request failed. The candidate revision repeatedly exceeded its memory limit, while the two previous replicas remained Ready and continued serving.

## Evidence and diagnosis

```text
Healthy idle memory.current:  17,199,104 bytes (16 MiB)
Memory request:               48 MiB
Memory limit/memory.max:      128 MiB / 134,217,728 bytes
Injected startup allocation:  192 MiB
Last termination reason:      OOMKilled
Exit code:                    137
Candidate restarts observed:  3
```

Previous logs showed the server listening and becoming Ready, then stopped without an application exception. The candidate's cgroup limit was lower than the explicit allocation even before Node.js runtime overhead, so the kernel killed the process.

Exit 137 alone is not sufficient proof of OOM because it represents a SIGKILL-like termination. Kubernetes `lastState.terminated.reason=OOMKilled` is the decisive signal.

## Requests, limits and runtime memory

The 48 MiB request influenced scheduling; it did not cap the process. The 128 MiB limit was enforced through cgroup v2 `memory.max`. The pod had Burstable QoS because request and limit differed, but this event was a container-limit OOM rather than node-pressure eviction.

A single 16 MiB idle sample is not a sizing recommendation. Production sizing needs time-series working set, RSS, Node.js heap and external Buffer memory, p95/p99 and peak behavior under representative load.

## Mitigation and recovery

`ALLOCATE_ON_START_MB` was removed and the rollout observed to completion. The limit was deliberately not increased. Kubernetes reused healthy ReplicaSet `784d9b466c` and removed failed ReplicaSet `879566c9f` without restarting serving pods.

## Validation

- Deployment reached `READY=2/2`, `UP-TO-DATE=2`, `AVAILABLE=2`.
- Serving pod ages remained above three hours with zero restarts.
- Both endpoints became `ready=true`, `serving=true`, `terminating=false`.
- In-cluster readiness returned HTTP 200.
- Order creation returned HTTP 202.
- Prometheus-format request and order metrics were present.

## Prevention actions

| Action | Control type | Verification |
|---|---|---|
| Profile memory under representative load before resource changes | Prevent | Record working-set p95/p99, peak RSS and safety headroom |
| Alert on OOM events and repeated restart growth | Detect | Incident 04 triggers and resolves the alert |
| Maintain evidence-first OOM rollback and sizing runbook | Respond | Recover a blind rerun without increasing the limit |

## Interview explanation

During a rollout, the candidate entered CrashLoopBackOff while old replicas remained available. I inspected the previous container state rather than treating probe failures as the cause: Kubernetes reported `OOMKilled`, exit 137. The workload requested 48 MiB, had a 128 MiB limit and attempted a 192 MiB startup allocation. A healthy pod measured about 16 MiB current usage with a 128 MiB cgroup maximum. Previous logs stopped without an exception, consistent with kernel SIGKILL. I removed the unsafe allocation instead of raising the limit blindly, and Kubernetes reused the healthy ReplicaSet. Both endpoints were Ready, order creation returned 202 and metrics were present.
