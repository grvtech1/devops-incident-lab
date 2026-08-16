# OOMKilled pod from an unsafe memory limit
Primary signal: Container terminates with reason OOMKilled

## Mission

A new revision allocates more memory than its cgroup limit. Prove the difference between an application exception and a kernel-enforced container termination, then recover without raising the limit blindly.
