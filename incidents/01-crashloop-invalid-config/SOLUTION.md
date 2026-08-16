# Solution: invalid runtime configuration

The new pods fail application startup because `BACKEND_URL=not-a-valid-url`. The structured log contains `startup_validation_failed`, and the new ReplicaSet accumulates restarts. `maxUnavailable: 0` allows the old healthy ReplicaSet to continue serving while the rollout is stalled.

Useful proof:

```bash
kubectl -n incident-lab rollout status deploy/incident-api --timeout=15s
kubectl -n incident-lab get rs,pods
kubectl -n incident-lab logs -l app.kubernetes.io/name=incident-api --prefix --tail=100
kubectl -n incident-lab describe deploy incident-api
```

Prevention: validate required configuration in CI, use environment-specific schema checks, require a smoke gate after rollout, and alert on unavailable updated replicas.
