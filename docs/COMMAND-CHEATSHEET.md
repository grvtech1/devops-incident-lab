# Kubernetes incident command cheat sheet

## Establish state

```bash
kubectl config current-context
kubectl -n incident-lab get deploy,rs,pod,svc,endpointslice -o wide
kubectl -n incident-lab get events --sort-by=.metadata.creationTimestamp
kubectl -n incident-lab rollout status deploy/incident-api --timeout=20s
kubectl -n incident-lab rollout history deploy/incident-api
```

## Explain a pod failure

```bash
kubectl -n incident-lab describe pod <pod>
kubectl -n incident-lab logs <pod> -c api --tail=100
kubectl -n incident-lab logs <pod> -c api --previous --tail=100
kubectl -n incident-lab get pod <pod> -o jsonpath='{.status.containerStatuses[0]}'
```

## Trace traffic

```bash
kubectl -n incident-lab get svc incident-api -o yaml
kubectl -n incident-lab get endpointslice -l kubernetes.io/service-name=incident-api -o yaml
kubectl -n incident-lab get pods --show-labels
kubectl -n incident-lab port-forward svc/incident-api 18080:8080
curl -i http://127.0.0.1:18080/health/ready
```

## Inspect a kind node and containerd

```bash
docker exec incident-lab-worker crictl ps
docker exec incident-lab-worker crictl images
docker exec incident-lab-worker journalctl -u kubelet --since '10 minutes ago'
docker exec incident-lab-worker systemctl status containerd --no-pager
```

## Verify recovery

```bash
kubectl -n incident-lab rollout status deploy/incident-api --timeout=120s
bash scripts/smoke-test.sh
kubectl -n incident-lab get events --sort-by=.metadata.creationTimestamp | tail -n 20
```
