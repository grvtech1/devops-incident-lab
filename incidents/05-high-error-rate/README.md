# High application error rate after configuration rollout
Primary signal: HTTP 5xx ratio and Prometheus alert increase while pods remain Ready

## Mission

The platform is green at the pod layer, but customer requests fail. Demonstrate why availability cannot be inferred from pod readiness, quantify the error ratio, and roll back the bad configuration.

## Observation workflow

Install the observability stack before starting this incident. Keep the Prometheus port-forward from the main README running, then capture the baseline and inject the failure:

```bash
./scripts/collect-evidence.sh baseline-05
./scripts/lab.sh start 05
kubectl -n incident-lab get pods
./scripts/lab.sh check 05
```

Generate traffic for at least 90 seconds so the alert's one-minute hold period can complete:

```bash
for i in {1..18}; do
  REQUESTS=25 ./scripts/load-test.sh || true
  sleep 5
done
```

Inspect the `DevOps Incident Lab` Grafana dashboard and query the alert state in Prometheus:

```promql
ALERTS{alertname="IncidentLabHighErrorRate"}
```

Do not open `SOLUTION.md` until you can explain why `up == 1` and Ready pods do not disprove customer impact. Capture firing and recovered evidence around your mitigation.
