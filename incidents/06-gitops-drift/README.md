# GitOps drift from an imperative production change
Primary signal: Live replica count differs from Git and Argo CD reports OutOfSync

## Mission

An operator scales the application manually. Determine the declared state, observe Argo CD's reconciliation, and explain when self-heal is helpful versus dangerous.

## Requirement

Install Argo CD and register this repository before starting the scenario.

## Observation workflow

Start watchers before injecting drift because self-healing may finish within seconds:

```bash
./scripts/collect-evidence.sh baseline-06

kubectl -n incident-lab get deployment incident-api -w \
  >/tmp/incident-06-deployment-watch.log 2>&1 &
DEPLOY_WATCH_PID=$!

kubectl -n argocd get application incident-lab -w \
  >/tmp/incident-06-argocd-watch.log 2>&1 &
ARGO_WATCH_PID=$!

./scripts/lab.sh start 06
./scripts/lab.sh check 06

sleep 5
kill "$DEPLOY_WATCH_PID" "$ARGO_WATCH_PID" 2>/dev/null || true
wait "$DEPLOY_WATCH_PID" "$ARGO_WATCH_PID" 2>/dev/null || true
cat /tmp/incident-06-deployment-watch.log
cat /tmp/incident-06-argocd-watch.log
```

The evidence must show all three facts: live replicas changed to five, the Application became `OutOfSync`, and Argo returned the Deployment to Git's two replicas. Do not run `recover 06` when self-heal already completed; doing so destroys attribution of the recovery action.
