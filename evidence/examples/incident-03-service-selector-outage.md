# Incident 03: Service outage from selector drift

## Summary

- Environment: Local three-node kind cluster, namespace `incident-lab`
- Severity: SEV-2 (complete Service-path outage in the lab)
- Duration: Approximately six minutes
- Trigger: Service selector no longer matched application pod labels
- Resolution: Correct only the Service selector; no pod restart

## Customer impact

All requests through the `incident-api` Service failed. Both application pods remained healthy and directly reachable on the pod network, but Service discovery exposed no backends.

## Evidence and diagnosis

```text
Deployment:       READY=2/2, UP-TO-DATE=2, AVAILABLE=2
Pods:             1/1 Running, zero restarts
Service selector: app.kubernetes.io/name=wrong-api
Pod label:        app.kubernetes.io/name=incident-api
EndpointSlice:    zero endpoint addresses
Customer path:    connection refused at ClusterIP
```

The client resolved the Service name to `10.96.239.163`, rejecting a DNS hypothesis. The empty EndpointSlice rejected application and probe hypotheses and localized the fault to Service discovery. Comparing `spec.selector` with Pod-template labels confirmed selector drift.

Kubernetes emitted no warning event because `wrong-api` is syntactically valid. The controller correctly selected zero pods; it could not infer operator intent.

## Mitigation and recovery

The Service selector was restored to `app.kubernetes.io/name=incident-api`, matching `k8s/base/service.yaml`. EndpointSlice controller repopulated existing pod IPs `10.244.1.3` and `10.244.2.4`.

No pods were deleted or restarted. Their ages stayed near three hours and restart counts remained zero, proving the fault and repair were isolated to the Service layer.

## Validation

- Deployment remained 2/2 throughout.
- EndpointSlice addresses became `ready=true`, `serving=true`, `terminating=false`.
- In-cluster Service DNS/ClusterIP readiness returned HTTP 200.
- Port-forwarded readiness returned HTTP 200.
- Order creation returned HTTP 202.
- Prometheus-format request and order metrics were present.

## Prevention actions

| Action | Control type | Verification |
|---|---|---|
| Validate rendered Service selectors against workload Pod-template labels | Prevent | Mismatched fixture fails CI |
| Alert on zero ready endpoints plus failed synthetic requests | Detect | Incident 03 produces and resolves alerts |
| Use GitOps reconciliation and Kubernetes API audit history | Respond | Imperative selector drift is attributed and reverted |

## Interview explanation

Customers could not reach the API even though the Deployment was 2/2 and both pods were healthy. The in-cluster request resolved the Service name to its ClusterIP but received connection refused, and EndpointSlice contained no addresses. I compared the Service selector with pod labels and found `wrong-api` versus `incident-api`. Because the selector was syntactically valid, Kubernetes produced no warning event. I corrected only the selector; EndpointSlice controller repopulated both existing pod IPs, with no restart or Deployment change. I validated internal Service readiness, order creation and metrics. The prevention plan is selector-to-template validation, zero-endpoint synthetic alerting and GitOps reconciliation.
