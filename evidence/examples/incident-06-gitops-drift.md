# Incident 06: Imperative replica drift reconciled by Argo CD

## Summary

- Environment: Local three-node kind cluster, Argo CD managing namespace `incident-lab`
- Severity: SEV-4 (control-plane drift; no failed customer request)
- Duration: Less than ten seconds
- Trigger: Imperative scale from two replicas to five
- Resolution: Argo CD automated self-heal restored the Git-declared replica count

## Customer impact

No request failed. Three unintended replicas were briefly created, increasing resource consumption and demonstrating that an undocumented emergency scale could not persist while self-heal remained enabled.

## Evidence and diagnosis

```text
Git desired replicas:          2
Imperative live replicas:      5
Argo transition:               Synced/Healthy
                               -> OutOfSync/Progressing
                               -> Synced/Progressing
                               -> Synced/Healthy
Final live replicas:           2
Manual recovery executed:      no
Argo automated.selfHeal:       true
```

The Deployment watch recorded `READY=2/5`, then `UP-TO-DATE=5`, proving Kubernetes accepted the manual scale. The Argo Application independently became `OutOfSync/Progressing`. The desired count then returned to two and the extra pods terminated before the Application settled at `Synced/Healthy`.

No Git commit changed the replica count and no recovery command was run. The ordered live-state and Application transitions therefore attribute recovery to Argo CD reconciliation rather than to a human correction.

## Desired, live and reconciled state

Git was the declared source of truth, Kubernetes held the temporary live state, and Argo continuously compared the two. `kubectl scale` was a valid Kubernetes API operation, but it changed only live state. With automated sync and `selfHeal: true`, Argo treated five replicas as drift and reapplied the two-replica declaration from `main`.

Self-heal is a guardrail, not a substitute for incident judgment. During a genuine capacity emergency, an undocumented manual scale could be reverted while traffic is still elevated. The break-glass procedure must account for the reconciler before changing live resources.

## Validation

- The checker observed replicas at five across four polling intervals.
- The Deployment watch captured scale-up and scale-down transitions.
- The Argo watch captured `OutOfSync` and subsequent convergence.
- Final Deployment state was `READY=2/2`, `UP-TO-DATE=2`, `AVAILABLE=2`.
- Final Application state was `Synced/Healthy`.
- Baseline and post-reconciliation evidence were captured separately.

## Prevention and operating controls

| Action | Control type | Verification |
|---|---|---|
| Change normal capacity through reviewed Git commits | Prevent | Replica changes map to an approved commit and Argo sync operation |
| Define an approved break-glass procedure for urgent live changes | Respond | Exercise records owner, reason, expiry and reconciliation handling |
| Alert on prolonged `OutOfSync` and sync failures | Detect | Test drift and an invalid desired state separately |
| Audit Kubernetes API writes and Argo operations | Detect | Attribute both the drift injection and correction |
| Reconcile the emergency state back into Git | Prevent | No undocumented live-only state remains after the incident |

## Interview explanation

The application was declared at two replicas in Git, but an imperative production-style command scaled the live Deployment to five. Kubernetes accepted the change and began creating three pods. Argo CD detected that live state no longer matched `main`; the Application moved from `Synced/Healthy` to `OutOfSync/Progressing`. With automated self-heal enabled, Argo reapplied the two-replica declaration, terminated the extra pods and returned to `Synced/Healthy` in under ten seconds. I captured both watches before injection, so recovery was attributable to the reconciler rather than a manual command. The operational lesson is that emergency changes require a controlled GitOps break-glass process because self-heal can undo a legitimate mitigation.
