# Runbook: IncidentLabHighErrorRate

## Trigger

More than 20% of observed HTTP requests return 5xx for one minute.

## Triage

1. Confirm the alert expression and request volume; low-volume ratios can mislead.
2. Compare `/health/ready` with the `/api/orders` business transaction.
3. Check the latest rollout, image, configuration and Argo CD sync history.
4. Split error rate by pod and revision before restarting anything.

## Mitigation

Restore the last known-good configuration or Git declaration. Do not silence the alert until the business smoke test passes.

## Validation

```bash
REQUESTS=100 bash scripts/load-test.sh
bash scripts/smoke-test.sh
```

The load test intentionally returns nonzero when it observes failures.
