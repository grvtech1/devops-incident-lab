# Solution: readiness is not a business SLI

The deployment is healthy from Kubernetes' perspective because the process and readiness endpoint work. `FAILURE_RATE=0.75` affects only order creation, so customer-visible availability collapses while pod status stays green.

The useful signal is the ratio of 5xx responses on the critical route, not pod count alone. Use the supplied Prometheus rule and load test to quantify impact.

Prevention: define endpoint-level SLIs, canary or smoke-test critical transactions after deployment, alert on burn rate, and promote configuration through the same review controls as code.
