# Resume and interview use

## Claim only after execution

After deploying the lab, completing the incidents and retaining evidence, you may state:

> Built and operated a multi-node Kubernetes incident lab using Docker, containerd, GitHub Actions, Argo CD, Prometheus, Grafana and Alertmanager, with repeatable failure injection, recovery validation and incident documentation.

> Diagnosed CrashLoopBackOff, stalled rollouts, Service selector drift, OOMKilled containers, business-level HTTP failures, GitOps drift and worker-node loss using Kubernetes events, logs, metrics, EndpointSlices and rollout history.

> Implemented CI image scanning, SBOM generation, immutable GHCR publishing and pull-request-based GitOps promotion with Argo CD self-healing.

## Do not claim

- Do not call this BillFree production.
- Do not convert one week of lab work into two or three years of employment.
- Do not claim an incident was customer-facing when it was simulated.
- Do not list a tool until you can explain its failure mode and tradeoff.

## Interview structure

```text
Impact -> evidence -> competing hypotheses -> root cause
       -> reversible mitigation -> validation -> prevention
```

The useful sentence is not “I used kubectl.” The useful sentence is “Healthy pods and an empty EndpointSlice localized the failure to Service label selection, so I corrected the selector without restarting application capacity.”
