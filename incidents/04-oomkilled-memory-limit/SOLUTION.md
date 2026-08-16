# Solution: the kernel enforced the container memory limit

The new process deliberately commits roughly 192 MiB while the container limit is 128 MiB. The cgroup cannot satisfy that usage, so the kernel kills the process and Kubernetes records `lastState.terminated.reason=OOMKilled` with exit code 137.

Useful proof:

```bash
kubectl -n incident-lab get pod -l app.kubernetes.io/name=incident-api \
  -o jsonpath='{range .items[*]}{.metadata.name}{" limit="}{.spec.containers[0].resources.limits.memory}{" reason="}{.status.containerStatuses[0].lastState.terminated.reason}{"\n"}{end}'
kubectl -n incident-lab describe pod <pod>
```

Prevention: establish working-set baselines, load-test with realistic concurrency, alert before saturation, and change application behavior or sizing from evidence rather than simply removing limits.
