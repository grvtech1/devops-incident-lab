# Incident 05: High order error rate with healthy pods

## Summary

- Environment: Local three-node kind cluster, namespace `incident-lab`
- Severity: SEV-2 (majority of order creation requests failed)
- Duration: Approximately seven minutes
- Trigger: Runtime configuration set `FAILURE_RATE=0.75`
- Resolution: Remove the bad override and roll out the corrected pod template

## Customer impact

Both replicas remained Ready and scrapeable, but order creation was unreliable. The immediate test failed 63 of 80 requests (79%). Sustained traffic failed 326 of 450 requests (72.4%); across both tests, 389 of 530 order attempts failed (73.4%).

## Detection and diagnosis

```text
Deployment availability:       2/2 Ready
Prometheus target health:      up == 1 for both pods
Sustained order error rate:    72.4%
Initial Prometheus ratio:      53.2%
Alert state:                   IncidentLabHighErrorRate firing
Alert severity:                critical
Runtime override:              FAILURE_RATE=0.75
Pod restarts:                  0
```

Kubernetes readiness proved that each process could answer its readiness endpoint. It did not exercise `POST /api/orders`. Prometheus and the synthetic transaction exposed the customer-visible failure while pod-level signals remained green.

The initial 53.2% Prometheus ratio was lower than the 72.4% load-test result because the rule divided order failures by all HTTP traffic, including successful liveness, readiness and metrics requests. The rule and dashboard were corrected to scope both numerator and denominator to `method="POST",route="/api/orders"`.

The Deployment pod template contained `FAILURE_RATE=0.75`, directly matching the observed failure distribution. Rollout history showed revision numbers but no change causes, demonstrating an attribution gap. Logs contained request IDs and routes but only `request_started`; they could not show response outcome or latency. Completion logs with status code and duration were added as a prevention action.

## Mitigation and recovery

The `FAILURE_RATE` override was removed from the Deployment. Kubernetes performed a rolling replacement while retaining availability. This was narrower and more reversible than restarting the cluster, changing probes or scaling replicas, none of which addressed the request-path behavior.

## Validation

- Recovery test accepted 30 of 30 order requests with zero failures.
- In-cluster Service readiness returned HTTP 200.
- A subsequent order request returned HTTP 202.
- Both smoke tests passed and exposed application metrics.
- `ALERTS{alertname="IncidentLabHighErrorRate"}` returned an empty vector after the evaluation window.
- Recovered evidence was captured separately from the firing state.

## Prevention actions

| Action | Control type | Verification |
|---|---|---|
| Scope the availability SLI to `POST /api/orders` | Detect | Synthetic failure rate and Prometheus ratio track the same transaction |
| Log request completion with request ID, status and duration | Detect | A failed order is traceable from start to HTTP 500 completion |
| Run a post-deployment synthetic order transaction | Prevent | Promotion fails when the process is Ready but order creation fails |
| Manage runtime configuration through reviewed GitOps changes | Prevent | Every pod-template revision maps to an attributable commit and rollback |
| Alert on multi-window SLO burn rate in production | Detect | Fast and slow burn tests fire without relying on pod health |

## Interview explanation

The Deployment was 2/2 Ready and Prometheus reported `up=1` for both replicas, but a synthetic order test failed 63 of 80 requests. Sustained traffic confirmed roughly 72% customer-facing failures and triggered a critical error-rate alert. I separated process health from the business SLI, inspected the pod-template configuration and found `FAILURE_RATE=0.75`. I removed only that override and observed a controlled rollout. Recovery accepted 30 of 30 orders, smoke tests passed and the alert resolved. I also corrected the PromQL because health probes diluted the original denominator, and added response status and latency to completion logs.
