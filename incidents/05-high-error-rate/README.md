# High application error rate after configuration rollout
Primary signal: HTTP 5xx ratio and Prometheus alert increase while pods remain Ready

## Mission

The platform is green at the pod layer, but customer requests fail. Demonstrate why availability cannot be inferred from pod readiness, quantify the error ratio, and roll back the bad configuration.
