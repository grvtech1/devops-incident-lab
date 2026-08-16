# CrashLoop from invalid runtime configuration
Primary signal: New ReplicaSet repeatedly restarts; rollout does not complete

## Mission

A configuration promotion introduced an invalid upstream URL. Establish impact, identify the failing revision, recover without deleting healthy old replicas, and explain why the rollout strategy limited customer impact.

## Rules

1. Start with `./scripts/lab.sh start 01`.
2. Do not open `SOLUTION.md` until you have a root-cause hypothesis.
3. Capture deployment status, pods, events, current/previous logs and ReplicaSets.
4. Recover with `./scripts/lab.sh recover 01` only after writing the hypothesis.
