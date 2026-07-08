# Scaling to multiple teams

This skeleton assumes a **single owner** — one person or one team who can write anywhere
in the repo. That is the right default for a starter. When you grow to multiple teams
sharing this monorepo, add controls at two layers. Neither requires restructuring.

## 1. Git: CODEOWNERS + branch protection (gate the merge)

Git permissions are repo-level, so the practical model is *review-gated ownership*, not
per-directory write walls. Add a `CODEOWNERS` file:

```
# .github/CODEOWNERS
/infra/                       @org/platform-team
/bootstrap/                   @org/platform-team
/apps/backend-podinfo/        @org/api-team
/apps/frontend-nginx/         @org/web-team
/apps/db-service/             @org/data-team
```

Then require code-owner approval in branch protection / rulesets on `main`. Now a PR that
touches an app can be owned by that app's team, while anything under `infra/` or
`bootstrap/` needs the platform team.

If you need a genuine *hard* wall (e.g. "this team physically cannot change prod IAM"),
the standard move is to split just those crown-jewel paths into a separate, locked-down
repo and keep everything else here.

## 2. Argo CD: AppProjects (bound the blast radius)

CODEOWNERS gates what gets *merged*; **AppProjects** bound what an Application can
*deploy*, independently of Git. Each project restricts source repos/paths, destination
clusters and namespaces, and allowed resource kinds. So even a mis-merged manifest can't
deploy outside its lane.

This repo ships AppProjects **on** (in [`bootstrap`](../bootstrap)) even for the
single-owner case, because they're cheap insurance against a misconfigured Application.
To add per-team isolation, give each team its own project scoped to its namespaces:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: api-team
  namespace: argocd
spec:
  sourceRepos:
    - https://github.com/your-org/eks-gitops-starter.git
  destinations:
    - server: https://kubernetes.default.svc
      namespace: backend-*
  # deny cluster-scoped resources by omitting clusterResourceWhitelist
```

## The combined model

| Control | Enforced at | Stops |
|---------|-------------|-------|
| CODEOWNERS + branch protection | merge time (Git) | unreviewed changes to a path |
| AppProject | deploy time (Argo CD) | an Application escaping its namespaces/kinds |
| Argo CD RBAC | UI/API | who can sync/rollback which project |

Together they recover most of what separate repos would give you, without the repo sprawl.
