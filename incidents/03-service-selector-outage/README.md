# Service outage from selector drift
Primary signal: Healthy pods exist, but the Service has no endpoints

## Mission

Customers receive connection failures even though every application pod is healthy. Trace traffic from Service to EndpointSlice to pod labels before changing the Deployment.
