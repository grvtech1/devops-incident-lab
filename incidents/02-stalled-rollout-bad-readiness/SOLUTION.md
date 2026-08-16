# Solution: readiness probe targets the wrong path

The container is alive, so the liveness probe succeeds. The readiness probe receives `404`, so Kubernetes never adds the new pod to Service endpoints. With `maxUnavailable: 0`, old replicas stay available and the rollout stalls instead of replacing healthy capacity.

Prevention: test probe paths against the built image, use rollout timeouts in CI, and distinguish process health from traffic readiness.
