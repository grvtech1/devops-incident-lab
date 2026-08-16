# Solution: a kind node is also a container

Pausing the kind worker freezes its kubelet and containerd processes. The control plane eventually marks the node `NotReady`. Existing workloads on that node become unavailable; Kubernetes can create replacements on healthy nodes after the node-monitor and eviction timeouts permit it.

Two replicas, topology spreading and a PodDisruptionBudget improve resilience, but a PDB governs voluntary disruption and does not prevent infrastructure failure. Recovery requires restoring the node and confirming both node health and application capacity.

Inspect containerd directly for learning:

```bash
docker exec incident-lab-worker crictl ps
docker exec incident-lab-worker crictl images
docker exec incident-lab-worker systemctl status containerd --no-pager
```
