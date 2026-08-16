# Incident 02: Stalled rollout from a bad readiness probe

## Summary

- Environment: Local three-node kind cluster, namespace `incident-lab`
- Severity: SEV-3 (deployment blocked; no customer-visible impact)
- Duration: Approximately six minutes
- Trigger: Deployment readiness probe changed to a nonexistent path
- Resolution: Restore the probe contract and let Kubernetes reuse the known-good ReplicaSet

## Customer impact

No customer action failed. The candidate pod ran but never became Ready. The two previous replicas remained Ready and continued serving while the rollout was blocked.

## Evidence and diagnosis

| Signal | Observation | Meaning |
|---|---|---|
| Pod phase | `Running`, zero restarts | Process did not crash |
| Deployment | `READY=2/2`, `UP-TO-DATE=1` | Old capacity was healthy, rollout was incomplete |
| Candidate endpoint | `ready=false`, `serving=false` | Service correctly withheld traffic |
| Liveness endpoint | HTTP 200 | Container should not be restarted |
| Correct readiness endpoint | HTTP 200 | Application was capable of serving |
| Configured probe endpoint | HTTP 404 | Manifest-to-application contract was wrong |
| Rollout status | Timed out | Failure was persistent, not startup delay |

The Deployment specified `/health/ready-wrong`, while the application implemented `/health/ready`. Restarting the candidate would not help because every replacement pod would inherit the same Pod template.

## Recovery behavior

The readiness path was restored to `/health/ready`. That made the desired Pod template identical to previous ReplicaSet `784d9b466c`, so Kubernetes reused its two healthy replicas and scaled bad ReplicaSet `776fd5d747` to zero. During termination, EndpointSlice showed the failed candidate as `ready=false`, `serving=false`, `terminating=true`.

## Validation

- Deployment reached `READY=2/2`, `UP-TO-DATE=2`, `AVAILABLE=2`.
- Two endpoints were `ready=true`, `serving=true`, `terminating=false`.
- In-cluster Service DNS/ClusterIP readiness returned HTTP 200.
- Port-forwarded readiness returned HTTP 200.
- Order creation returned HTTP 202.
- Prometheus-format request and order metrics were present.

## Prevention actions

| Action | Control type | Verification |
|---|---|---|
| Start the built image in CI and test every configured probe path | Prevent | Invalid probe fixture fails before manifest promotion |
| Alert on stalled Deployment progress and unavailable updated replicas | Detect | Incident 02 triggers and resolves the alert |
| Document probe diagnosis and manifest rollback | Respond | Blind rerun is recovered without restarting individual pods |

## Interview explanation

During a rollout, the candidate pod was Running with zero restarts but remained `0/1 Ready`; the Deployment showed only one updated replica and could not progress. EndpointSlice marked the candidate `ready=false`, and events showed readiness HTTP 404. I proved the process was healthy because liveness and the actual readiness endpoint returned 200, then found the Deployment probe pointed to `/health/ready-wrong`. I restored the correct path instead of restarting pods, because replacements would inherit the same bad template. Kubernetes reused the previous healthy ReplicaSet, removed the candidate, and the in-cluster Service check, order request and metrics validation passed.
