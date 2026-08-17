# CI and GitOps delivery evidence

## Delivery record

| Field | Evidence |
|---|---|
| Source commit | [`452b67e10530d66f72eb989fbc24136ce98dae19`](https://github.com/grvtech1/devops-incident-lab/commit/452b67e10530d66f72eb989fbc24136ce98dae19) |
| CI validation | [GitHub Actions run 32018624126](https://github.com/grvtech1/devops-incident-lab/actions/runs/32018624126) |
| Publish and promotion | [GitHub Actions run 32018624116](https://github.com/grvtech1/devops-incident-lab/actions/runs/32018624116) |
| Immutable image | `ghcr.io/grvtech1/devops-incident-lab:sha-452b67e10530d66f72eb989fbc24136ce98dae19` |
| Published digest | `sha256:f98dd285f2f508f5da14c079df363de93b4a03f1538803e79c707a2c678dbaf8` |
| SBOM artifact | `sbom-452b67e10530d66f72eb989fbc24136ce98dae19` |
| Promotion review | [Pull request #1](https://github.com/grvtech1/devops-incident-lab/pull/1) |

## Controls proven

1. Application tests passed before an image was built.
2. The runtime image ran as UID `10001` and contained no npm, npx, Corepack or Yarn executables.
3. Trivy found no actionable `HIGH` or `CRITICAL` vulnerabilities in the candidate image under the configured `ignore-unfixed` policy.
4. A CycloneDX SBOM was generated and retained as a workflow artifact.
5. Registry authentication and publication occurred only after the candidate passed the scan.
6. The published image used a source-SHA tag and produced an immutable registry digest.
7. Automation proposed the digest change in a pull request instead of editing the deployment declaration directly on `main`.
8. Independent CI validated application code, Bash syntax, Kustomize output, Helm values, Terraform and Ansible configuration.

## Promotion boundary

Pull request #1 updates `k8s/overlays/production/kustomization.yaml` from placeholders to the published GHCR image name and digest. Review and merge are deliberate approval gates.

The kind cluster's Argo CD Application watches `k8s/overlays/dev`. Incident 06 separately proves automated reconciliation and self-healing in that local environment. This delivery record does not claim that the production overlay was deployed to BillFree, AWS or any other production cluster.

## Interview explanation

I separated validation, publication and deployment intent. CI tested the service and delivery configuration, verified a minimal non-root container, and blocked the candidate on high or critical vulnerability findings. The publish workflow then generated a CycloneDX SBOM, authenticated to GHCR only after the scan, pushed a source-SHA image and captured its digest. A second job proposed that digest through a GitOps pull request, preserving review and an auditable desired-state change. In the local cluster, Argo CD reconciliation and self-healing were validated independently against the development overlay.
