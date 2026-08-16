# Stalled rollout from a bad readiness probe
Primary signal: Updated pod runs but never becomes Ready

## Mission

A manifest change points the readiness probe at a nonexistent path. Determine why liveness passes while the rollout remains incomplete, and explain why restarting pods is not the fix.
