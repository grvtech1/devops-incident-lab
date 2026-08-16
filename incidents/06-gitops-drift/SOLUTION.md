# Solution: live state drifted from Git

The imperative scale operation changes the Kubernetes object but not the Git declaration. An Argo CD Application with automated sync and `selfHeal: true` detects the difference and restores two replicas.

Self-heal prevents undocumented drift, but it can also undo legitimate emergency changes. Production procedure should either commit the emergency change, temporarily disable auto-sync through an approved process, or document a tightly controlled break-glass path.
