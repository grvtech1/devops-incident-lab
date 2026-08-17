# Worker node failure with service continuity
Primary signal: Node becomes NotReady and pods are rescheduled

## Mission

Pause one kind worker node, observe node and pod behavior, determine whether the service remains available, then recover the node and explain the role of replicas, spreading and disruption controls.

## Safety and observation workflow

Do not leave the worker paused unattended. Install a shell trap before injection so interruption still unpauses it:

```bash
trap 'docker unpause incident-lab-worker >/dev/null 2>&1 || true' EXIT INT TERM
./scripts/lab.sh start 07
./scripts/lab.sh check 07
make smoke
./scripts/collect-evidence.sh 07-node-notready
```

The injector refuses to run unless exactly two application pods exist with exactly one on the selected worker. While the node is paused, record Ready EndpointSlice targets and Deployment availability every ten seconds. The default node-loss toleration means replacement may take about five minutes; one endpoint must continue serving throughout.

After replacement capacity returns, capture evidence and recover immediately:

```bash
./scripts/collect-evidence.sh 07-rescheduled
./scripts/lab.sh recover 07
trap - EXIT INT TERM
make smoke
```

Recovery uses the policy eviction API when both replacement pods remain on the surviving worker. This honors the PodDisruptionBudget while forcing one replacement onto the recovered worker; Kubernetes does not automatically rebalance already-running pods.
