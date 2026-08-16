# Incident method: IMPACT

Use the same loop for every failure. Commands are evidence, not the method itself.

## I - Identify impact

- What customer action is failing?
- Is impact total, partial, regional, tenant-specific, or limited to a new revision?
- What still works?
- When did the symptom begin?

## M - Map the request path

Trace one request instead of inspecting everything randomly:

```text
client -> gateway/load balancer -> Service -> EndpointSlice -> pod
       -> process -> dependency -> response
```

For deployment failures, trace:

```text
Git commit -> CI artifact -> image digest -> GitOps declaration
           -> ReplicaSet -> pod -> readiness -> Service endpoint
```

## P - Pin recent changes

Inspect Git, Argo CD history, Deployment revisions, ConfigMaps, image references and events. Time correlation is evidence, not proof of causation.

## A - Assemble competing hypotheses

Write at least two plausible causes. For each, state the next observation that would support or reject it. Do not restart resources merely to see whether the symptom disappears.

## C - Contain and correct

Prefer the lowest-risk reversible mitigation: pause promotion, restore a known-good declaration, revert configuration, or remove broken endpoints. Preserve evidence before destructive cleanup.

## T - Test recovery and prevent recurrence

Validate infrastructure health and the customer transaction. A green rollout is not enough. Record root cause, contributing factors, missing detection, and a concrete prevention change.

## Fifteen-minute drill

| Time | Expected behavior |
|---|---|
| 0-3 min | Establish impact and a known-good comparison |
| 3-6 min | Trace the request or deployment path |
| 6-9 min | Form and test competing hypotheses |
| 9-12 min | Apply a reversible mitigation |
| 12-15 min | Run customer-level validation and start the timeline |
