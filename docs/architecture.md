# Architecture

This repo separates concerns into two planes:

- **Terraform / OpenTofu** owns *cloud primitives* — the VPC, the EKS cluster, IAM,
  ECR, Route53 — and installs the one in-cluster component that everything else hangs
  off: **Argo CD**.
- **GitOps (Argo CD + Kustomize)** owns *everything inside the cluster*, reconciled
  directly from this repository. That includes Argo CD's own applications.

The handoff is a single object: Terraform creates an Argo CD **app-of-apps**
`Application` that points at [`bootstrap/overlays/<env>`](../bootstrap). From that point
on, the cluster converges on Git without further `terraform apply`s.

```
                    ┌──────────────────────────────────────────┐
   terraform apply  │  infra/environments/<env>                │
   ────────────────▶│    ├─ module.vpc      (network)          │
                    │    ├─ module.eks      (cluster + nodes)  │
                    │    └─ module.addons                      │
                    │         ├─ External Secrets + IAM (Pod   │
                    │         │   Identity → Secrets Manager)  │
                    │         ├─ cert-manager                  │
                    │         └─ Argo CD  ──────────────┐      │
                    └───────────────────────────────────┼──────┘
                                                         │ app-of-apps
                                                         ▼
                    ┌──────────────────────────────────────────┐
                    │  bootstrap/overlays/<env>  (Git)          │
                    │    ├─ AppProjects                         │
                    │    ├─ ClusterSecretStore (AWS SM)         │
                    │    ├─ ClusterIssuer (cert-manager)        │
                    │    └─ child Applications ─────────┐       │
                    └───────────────────────────────────┼───────┘
                                                         ▼
              platform-addons/    apps/backend-podinfo    apps/frontend-nginx    apps/db-service
```

## Why these choices

- **EKS Pod Identity, not IRSA.** Pod Identity associations replace the older OIDC/IRSA
  dance. There's no per-cluster OIDC provider to wire up and trust policies are simpler.
  External Secrets gets its AWS access this way (see [`infra/modules/addons`](../infra/modules/addons)).
- **External Secrets Operator (ESO)** syncs secrets from AWS Secrets Manager into
  Kubernetes `Secret`s. Apps consume plain `Secret`s and never see AWS. Locally, the
  same `ExternalSecret` manifests target a fake in-cluster store so nothing AWS is needed.
- **cert-manager** issues TLS. `staging`/`prod` use a real (e.g. Let's Encrypt / ACM)
  issuer; `dev` and local use a self-signed `ClusterIssuer`.
- **Ingress is swappable.** On AWS, the AWS Load Balancer Controller provisions ALBs
  from `Ingress` objects and External DNS writes the Route53 records. Locally, the same
  apps are fronted by ingress-nginx. Overlays pick the class.
- **Argo CD runs in-cluster and manages itself.** For multi-cluster setups, the common
  pattern is to run one Argo CD in a stable non-prod cluster and register the others; the
  `bootstrap` overlays are structured to make that a later step, not a rewrite.

## Environments

`dev`, `staging`, `prod` are fully isolated: separate VPCs, separate state, separate
Argo CD applications. They differ only in their `*.tfvars` and their Kustomize overlays:

| | dev | staging | prod |
|---|---|---|---|
| Database | ephemeral in-cluster Postgres | RDS | RDS (deletion-protected) |
| Ingress | ingress-nginx | ALB | ALB |
| Public access | no | limited | yes |
| Node scaling | small, fixed | moderate | larger, autoscaled |

## Optional / paid pieces (off by default)

- **Tailscale** — private access to in-cluster services without public ingress. Enabled
  with `ENABLE_TAILSCALE=true`; adds the Tailscale operator via a Kustomize component.
- **HCP Terraform** — remote state + runs. Enabled with `USE_HCP_BACKEND=true`;
  otherwise state lives in S3 + DynamoDB.

Both are documented in [`.env.example`](../.env.example) and toggled by `setup.sh`.
