# Resume and interview use

## Claim only after execution

After deploying the lab, completing the incidents and retaining evidence, you may state:

> Built and operated a multi-node Kubernetes incident lab using Docker, containerd, GitHub Actions, Argo CD, Prometheus, Grafana and Alertmanager, with repeatable failure injection, recovery validation and incident documentation.

> Diagnosed CrashLoopBackOff, stalled rollouts, Service selector drift, OOMKilled containers, business-level HTTP failures, GitOps drift and worker-node loss using Kubernetes events, logs, metrics, EndpointSlices and rollout history.

> Implemented CI validation, scan-gated immutable GHCR publishing, CycloneDX SBOM generation, pull-request-based image promotion, and Argo CD automated reconciliation and self-healing in a Kubernetes lab.

The third statement is supported by the public [delivery record](../evidence/examples/ci-gitops-delivery.md) and [GitOps incident evidence](../evidence/examples/incident-06-gitops-drift.md). A workflow file alone proves design intent, not execution.

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

The useful sentence is not "I used kubectl." The useful sentence is "Healthy pods and an empty EndpointSlice localized the failure to Service label selection, so I corrected the selector without restarting application capacity."

## Honest positioning for a 2-3 year role

Your strongest positioning is "experienced production support leader transitioning into DevOps with hands-on platform evidence," not "three years of DevOps employment." Connect real support work to incident ownership, stakeholder communication, escalation, change control, Linux/AWS troubleshooting, and post-incident follow-up. Keep this lab under Projects, and keep employer bullets limited to work you actually performed and can verify.

Evidence can establish depth, but elapsed tenure is a separate fact. In an interview, state the distinction before the interviewer has to discover it.
