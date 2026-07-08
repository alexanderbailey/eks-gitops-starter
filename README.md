# eks-gitops-starter

A production-shaped, **greenfield** skeleton for running one or more applications on
**AWS EKS** with **GitOps**. It is a single monorepo that takes you from an empty AWS
account to a cluster running three demo apps, managed declaratively by Argo CD.

It is deliberately opinionated but escapable: the paid/SaaS pieces (Tailscale, HCP
Terraform) are **optional feature flags**, so you can clone it and run the whole GitOps
layer locally on [kind](https://kind.sigs.k8s.io/) with no AWS account and no bill.

> This is a reference/starter, not a product. Fork it, rename it, and delete what you
> don't need.

---

## What's in the box

| Layer | Path | What it does |
|-------|------|--------------|
| **Infrastructure** | [`infra/`](infra/) | Terraform / OpenTofu: VPC, EKS, IAM (Pod Identity), ECR, Route53, and the in-cluster platform (Argo CD, External Secrets, cert-manager). |
| **Bootstrap** | [`bootstrap/`](bootstrap/) | The Argo CD *app-of-apps* + day-0 cluster config (secret store, projects, issuers). The single thing Terraform points Argo CD at. |
| **Platform addons** | [`platform-addons/`](platform-addons/) | Cluster-wide services delivered via GitOps (ingress, cert-manager config). |
| **Applications** | [`apps/`](apps/) | Three demo apps (see below), each Kustomize `base` + per-env `overlays`. |

The demo apps are chosen to exercise three different shapes of workload:

1. **`backend-podinfo`** — a stateless HTTP API ([podinfo](https://github.com/stefanprodan/podinfo)) with health, metrics and an HPA.
2. **`frontend-nginx`** — a public-facing static site that calls the backend, exercising Ingress + TLS + DNS.
3. **`db-service`** — a service that reads its database credentials from **External Secrets** and talks to Postgres (ephemeral in `dev`, RDS in `staging`/`prod`).

## Design at a glance

```
Terraform ──creates──▶ EKS + IAM + ArgoCD ──points at──▶ bootstrap/ (app-of-apps)
                                                              │
                                    ┌─────────────────────────┼─────────────────────────┐
                                    ▼                         ▼                         ▼
                             platform-addons/           apps/backend-podinfo      apps/db-service
                                                        apps/frontend-nginx         (+ ESO secrets)
```

Terraform owns the cloud primitives and installs Argo CD. Everything else — including
Argo CD's own applications — is GitOps, reconciled from this repo. See
[`docs/architecture.md`](docs/architecture.md) for the full walkthrough.

## Quick start

### 1. Configure

```bash
cp .env.example .env
# edit .env — everything optional defaults to OFF, so the local path needs nothing
./setup.sh
```

### 2. Try it locally (no AWS)

```bash
task kind-up     # kind cluster + Argo CD + the app-of-apps, all reconciled locally
```

### 3. Deploy to AWS

```bash
task infra:plan ENV=dev
task infra:apply ENV=dev
```

See [`docs/local-testing.md`](docs/local-testing.md) for the local story and
[`docs/architecture.md`](docs/architecture.md) for the AWS story.

## Terraform or OpenTofu?

The `.tf` code is plain HCL targeting **OpenTofu 1.8+ / Terraform 1.9+** and uses no
engine-specific features — the same files run under either CLI. The `Taskfile` defaults
to `tofu` and falls back to `terraform`; override with `TF=terraform`. If your team
prefers infrastructure in a general-purpose language, Pulumi is a fine alternative, but
this skeleton stays in HCL for ecosystem reach.

## Scaling to multiple teams

This skeleton assumes a single owner. To share it across teams, add `CODEOWNERS`
path rules and turn on Argo CD **AppProjects** to bound each app's blast radius — both
covered in [`docs/scaling-to-teams.md`](docs/scaling-to-teams.md).

## License

MIT — see [LICENSE](LICENSE).
