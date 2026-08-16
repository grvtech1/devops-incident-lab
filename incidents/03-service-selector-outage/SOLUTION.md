# Solution: Service selector does not match pod labels

The pods are healthy, but `Service.spec.selector` requests `app.kubernetes.io/name=wrong-api`. The EndpointSlice controller therefore publishes no addresses. Restarting pods cannot fix a declarative selector mismatch.

Prevention: render and validate manifests in CI, add an endpoint-presence deployment check, and let Argo CD detect/reconcile drift.
