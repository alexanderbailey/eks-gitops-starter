# Build plan & progress

This is the working plan for `eks-gitops-starter`. It doubles as a resume point:
anyone (or any assistant session) can read this cold and continue.

## Goal

A greenfield, publishable **skeleton** for running one or more apps on AWS EKS with
GitOps. Single monorepo. Opinionated but escapable — the paid/SaaS pieces (Tailscale,
HCP Terraform) are optional feature flags so it runs locally on kind with no AWS account.

## Decisions (settled)

| Decision | Choice | Why |
|----------|--------|-----|
| Structure | **Monorepo** | One clone, atomic changes, kills per-repo deploy-key sprawl; Argo CD apps point at `path:` within the repo. |
| Build style | **Greenfield** | Written fresh; nothing copied. Modern-by-default and no de-identification risk. |
| IaC | **HCL, OpenTofu-first, Terraform-compatible** | Same `.tf` runs under `tofu` or `terraform`; no engine-specific features. Not Pulumi (HCL has the ecosystem reach a skeleton needs). |
| Access model | **Single-owner** | Right default for a starter. Multi-team = CODEOWNERS + AppProjects, documented in `docs/scaling-to-teams.md`. |
| Secrets IAM | **EKS Pod Identity** (not IRSA) | Simpler; no per-cluster OIDC provider. |
| Tailscale / HCP | **Optional**, off by default | Toggled in `.env` → `setup.sh`. Defaults: S3+DynamoDB backend, plain/ingress-nginx. |
| Demo apps | **3**: `backend-podinfo`, `frontend-nginx`, `db-service` | Cover stateless API, public-facing UI, and stateful-with-secrets (ESO + Postgres/RDS). Public images, wired into a real topology. |

## Modern stack

- OpenTofu 1.8+ / Terraform 1.9+ (code targets `>= 1.6`), AWS provider v6-compatible (`< 7.0`).
- `terraform-aws-modules/eks` v20 with **access entries** (no aws-auth configmap) + Pod Identity agent addon.
- `terraform-aws-modules/eks-pod-identity` for ESO / ALB / external-dns IAM + associations.
- `alekc/kubectl` provider for the app-of-apps manifest (no plan-time CRD dependency).
- RDS with `manage_master_user_password` → Secrets Manager → **External Secrets** → app namespace.
- Argo CD (helm) + app-of-apps. AppProjects on. ApplicationSet noted as the scale path.
- Ingress: ALB (AWS) / ingress-nginx (local), swapped per overlay. cert-manager for TLS.
- Testing: native `terraform test` (mock providers) + `kubeconform` + kind smoke test.

## Repo layout (target)

```
infra/                    # Terraform/OpenTofu  [DONE]
  modules/{vpc,eks,addons,rds,cluster}
  shared/{ecr,route53}
  environments/{dev,staging,prod}
bootstrap/                # app-of-apps + cluster_setup (ESO store, issuers, AppProjects)  [DONE]
  base/  overlays/{dev,staging,prod}/  base/cluster_setup/components/tailscale/
platform-addons/          # cert-manager config, ingress (nginx local / ALB aws)  [DONE]
apps/                     # [DONE]
  backend-podinfo/{base,overlays/…}
  frontend-nginx/{base,overlays/…}
  db-service/{base,overlays/…}
scripts/kind-up.sh kind-wait.sh   # [DONE]
```

## Phases & status

- [x] **P0 — Scaffold.** README, LICENSE (MIT), Taskfile, `.env.example` + `setup.sh`,
  `.pre-commit-config.yaml`, CI workflows (infra/gitops/e2e), `docs/`.
- [x] **P1 — Infra.** All modules + shared + 3 environments. Backend toggle (S3 default /
  HCP alt) via `setup.sh`. Pod Identity. RDS behind `enable_rds`.
  **Verified:** `fmt -check` clean; `validate` passes on every module+env; **11 `terraform
  test` cases pass** (ecr 2, rds 3, route53 3, addons 3) with mocked providers; `setup.sh`
  generates gitignored backend+tfvars with no secret leak.
- [x] **P2 — Bootstrap.** `bootstrap/base/` = `cluster_setup` (AppProjects `platform`
  + `apps` **on**, AWS SM `ClusterSecretStore` via Pod Identity) + `applications/` (4
  child Applications: `platform-addons`, `backend-podinfo`, `frontend-nginx`,
  `db-service`, baked at `overlays/dev`). `overlays/{dev,staging,prod}`: dev = base;
  staging/prod JSON-patch each Application's `source.path` to their env. Optional
  Tailscale operator as a Kustomize component under
  `cluster_setup/components/tailscale` (ESO-synced OAuth; off by default). repoURL uses
  the `your-org` placeholder (same convention as `.env.example`/`setup.sh`).
  **Verified:** `kustomize build` clean on all 3 overlays (7 resources each, correct
  per-env paths) + tailscale component composes; **`kubeconform -strict` 7/7 valid,
  0 skipped** per overlay (CRDs resolved via the datreeio catalog).
- [x] **P3 — Platform addons.** `platform-addons/base` = self-signed `ClusterIssuer`
  (dev/local). Overlays: `dev` adds ingress-nginx (nested Helm Application, `nginx`
  IngressClass, `ClusterIP` svc — internal); `staging`/`prod` add a `letsencrypt`
  `ClusterIssuer` (same name both envs; staging→ACME staging, prod→ACME prod; HTTP01
  solver via `alb`, internet-facing challenge Ingress). ALB IngressClass comes from the
  Terraform-installed LB controller; DNS01/Route53 noted as the extension needing a
  cert-manager Pod Identity role. **Verified:** `kustomize build` + `kubeconform -strict`
  clean on all 3 overlays (dev 2, staging 2, prod 2 resources; 0 skipped). P2 tweak:
  `platform-addons` parent Application now targets the `argocd` namespace.
- [x] **P4 — Demo apps.** `backend-podinfo` (podinfo, internal ClusterIP; replicas
  1/2/3 via kustomize `replicas`), `frontend-nginx` (nginx-unprivileged serving a page
  that proxies `/api/`→backend; Ingress patched per env: `nginx`/internal on dev,
  `alb`+host+`letsencrypt` TLS on staging/prod), `db-service` (postgres:16-alpine client
  reading `db-credentials`+`db-config` via `envFrom`; **dev** = ephemeral in-cluster
  Postgres + static Secret, **staging/prod** = `ExternalSecret` from the RDS-managed
  master secret in Secrets Manager + endpoint ConfigMap, with `REPLACE-with-…`
  placeholders for the two Terraform outputs). Apps ship **no** `Namespace` object (the
  `apps` AppProject forbids cluster-scoped resources); ns comes from `CreateNamespace=true`
  and the kustomize `namespace:` stamp. **Verified:** all 9 app overlays `kustomize build`
  + `kubeconform -strict` clean, 0 Namespace leaks; **full CI-parity sweep green across
  all 15 overlays** (bootstrap 3, platform-addons 3, apps 9).
- [x] **P5 — Local e2e + docs.** `local` overlays added (bootstrap/platform-addons/apps).
  `scripts/kind-up.sh`: creates kind (NodePort 30080→localhost:8080), installs **Argo CD**
  (the seam Terraform owns on AWS), serves the **working tree** — uncommitted changes
  included, via a temp-index snapshot commit — from a throwaway **in-cluster git-daemon**,
  then applies the app-of-apps at `bootstrap/overlays/local`. AWS seams swapped locally:
  ALB→ingress-nginx (NodePort + `publish-status-address=localhost` so Ingresses go
  Healthy), RDS→in-cluster Postgres, ESO/cert-manager/external-dns **skipped** (db-service
  uses its dev static `Secret`; docs table updated to match — LocalStack noted for the ESO
  path). `bootstrap/overlays/local` drops the `ClusterSecretStore` and repoints every child
  App at the in-cluster repo. `kind-wait.sh` blocks until ≥6 Apps are Synced+Healthy (dumps
  diagnostics on timeout). `e2e.yml` installs kind (`helm/kind-action install_only`) + dumps
  state on failure. **Verified (static):** `bash -n` on both scripts; **full CI-parity sweep
  green across all 20 overlays**. Live kind smoke test runs in CI (kind/kubectl not on this
  box — see notes).

## How to verify what exists

```bash
terraform fmt -recursive -check infra/          # or tofu
# validate every module/env:
for d in $(find infra -name '*.tf' -not -path '*/.terraform/*' -exec dirname {} \; | sort -u); do
  terraform -chdir="$d" init -backend=false >/dev/null && terraform -chdir="$d" validate; done
# unit tests:
for d in $(find infra -type d -name tests -exec dirname {} \;); do
  terraform -chdir="$d" init -backend=false >/dev/null && terraform -chdir="$d" test; done
```

## Notes / gotchas

- Only `terraform` is installed in the current dev box (no `tofu`, `kustomize`, `kind`).
  So P2–P4 Kustomize validation and P5 kind run happen in CI until those tools are local.
- Chart/module versions are pinned in `infra/modules/addons/variables.tf` and each
  `versions.tf` — bump deliberately; exact numbers may need a refresh over time.
- Provider config for helm/kubernetes/kubectl lives in each environment root
  (`providers.tf`) and reads the cluster module's outputs via `aws eks get-token`.
