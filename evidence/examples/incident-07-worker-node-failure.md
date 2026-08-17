# Incident 07: Worker-node loss with service continuity

## Summary

- Environment: Local three-node kind cluster using containerd
- Severity: SEV-3 (50% application capacity lost; customer path remained available)
- Detection: Node `Ready=Unknown`, one Ready EndpointSlice target and Deployment availability 1/2
- Replacement time: 260 seconds after observation began
- Trigger: Paused the `incident-lab-worker` container, freezing kubelet and containerd
- Resolution: Kubernetes evicted the unreachable pod, scheduled replacement capacity, then the node was unpaused and workload placement rebalanced

## Customer impact

The service retained one healthy backend on `incident-lab-worker2`. Readiness, order creation and metrics remained successful while application capacity was reduced from two Ready endpoints to one. No failed customer transaction was observed during the corrected exercise.

## Evidence and diagnosis

```text
Baseline nodes:                 3/3 Ready
Baseline application replicas: 2/2, one per worker
Failed node condition:         Ready=Unknown
Failed node reason:            NodeStatusUnknown
Controller message:            Kubelet stopped posting node status
Ready endpoints during loss:   1
Available replicas during loss:1
Replacement capacity restored: 260 seconds
Replacement destination:       incident-lab-worker2
Smoke test during degradation: passed
Smoke test after replacement:  passed
```

Before injection, `crictl ps` proved that the API container and platform workloads ran through containerd inside the kind worker, and `systemctl is-active containerd` returned `active`. Pausing the outer Docker container froze both containerd and kubelet. The control plane stopped receiving heartbeats and changed pressure and Ready conditions to `Unknown` with `NodeStatusUnknown`.

EndpointSlice state, rather than the stale pod phase alone, identified the serving backend. The unreachable pod could still appear `Running` because the control plane could not ask its kubelet for current state. Deployment availability and Ready endpoints correctly dropped to one.

## Eviction and replacement

Ready endpoint and available-replica counts remained at one for 250 seconds. TaintManager then marked the unreachable pod for deletion, the ReplicaSet created a replacement, and the scheduler placed it on `incident-lab-worker2`. At 260 seconds, both Ready endpoint and available-replica counts returned to two.

The PodDisruptionBudget did not prevent node-loss eviction because PDBs constrain voluntary eviction, not involuntary infrastructure failure. It was still useful during post-recovery rebalancing, where the policy eviction API removed only one healthy pod at a time.

## Recovery and rebalancing

Unpausing the kind node restored kubelet heartbeats and the node returned Ready. Kubernetes did not automatically move either healthy replacement from worker2 back to the recovered worker; the scheduler places pending pods but is not a continuous rebalancer. A PDB-respecting eviction of one replacement forced the Deployment to create a new pod, and the hard topology-spread rule placed it on the recovered worker.

## Design correction discovered during the exercise

The first attempt was invalid because both replicas were co-located under a soft `ScheduleAnyway` spread rule, producing total service loss and a hanging kubelet-dependent smoke command. The run was treated as a failed resilience test, not presented as success.

The platform was corrected before rerun:

- `whenUnsatisfiable: DoNotSchedule` enforces spreading while both workers are eligible.
- `nodeTaintsPolicy: Honor` excludes the tainted control-plane hostname from skew calculations and avoids rollout deadlock.
- Incident injection refuses unsafe initial placement.
- Smoke and evidence commands have external timeouts.
- Smoke selects a Ready EndpointSlice backend instead of trusting stale pod readiness.
- The recovery path rebalances placement through the Eviction API.

## Prevention and operating controls

| Action | Control type | Verification |
|---|---|---|
| Enforce replicas across eligible hostname domains | Prevent | Injection refuses any baseline other than one pod per worker |
| Alert on node readiness and reduced Ready endpoints | Detect | Corrected incident shows `Ready=Unknown` and endpoint count 2 to 1 |
| Run synthetic business checks during capacity loss | Detect | Order creation remains HTTP 202 with one endpoint |
| Keep node-loss commands bounded and trap recovery | Respond | Interrupting the exercise unpauses the node |
| Rebalance after node recovery using PDB-aware eviction | Respond | Final state returns to one Ready pod per worker |
| Test realistic zone failure in a managed cluster | Prevent | Workload survives loss of a failure domain, not only a kind container |

## Interview explanation

I simulated worker loss by pausing a kind node, which froze its kubelet and containerd. The node transitioned to `Ready=Unknown`, and application capacity dropped from two Ready endpoints to one, but synthetic order creation continued through the surviving worker. The unreachable pod still appeared Running initially, so I relied on node conditions, EndpointSlice readiness and Deployment availability rather than pod phase alone. After the default toleration window, TaintManager evicted the pod and the ReplicaSet restored capacity on the healthy worker in 260 seconds. I unpaused the node, verified heartbeats and then used a PDB-respecting eviction to rebalance one replica onto it. The exercise also caught and corrected an initial co-location flaw instead of falsely claiming high availability.
