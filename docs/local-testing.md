# Local testing

You can exercise almost everything in this repo **without an AWS account and without a
bill**. There are three layers of test, cheapest first.

## 1. Static validation (seconds, no cluster)

```bash
task lint
```

This runs:

- `tofu fmt -check` (or `terraform`) across `infra/`.
- `tofu validate` on every module and environment with `-backend=false` — no cloud access.
- `kustomize build` on every overlay, piped through `kubeconform` for schema validation.

`kubeconform -ignore-missing-schemas` is used so CRDs (Argo CD, ESO, cert-manager) don't
fail the run; core resources are still strictly validated.

## 2. Terraform unit tests (seconds, no cloud)

```bash
task infra:test
```

Native `terraform test` (works under OpenTofu too) with **mocked providers**, so no AWS
credentials or network are needed. These assert module *logic* — that inputs produce the
expected resource shapes, counts, and conditional wiring (e.g. ALB resources only exist
when `enable_alb = true`).

## 3. End-to-end on kind (minutes, no AWS)

```bash
task kind-up
```

This stands up a local [kind](https://kind.sigs.k8s.io/) cluster and reproduces the
GitOps plane:

1. Installs Argo CD (the one in-cluster component Terraform installs on AWS).
2. Serves this checkout — **including uncommitted changes** — from a throwaway
   in-cluster git server, so Argo reconciles exactly what you're editing and no
   GitHub access is needed.
3. Applies the `bootstrap` app-of-apps (the `local` overlay) pointed at that mirror.
4. Argo CD reconciles ingress-nginx and the demo apps until they're healthy.

`scripts/kind-wait.sh` then blocks until every Argo CD Application is Synced +
Healthy (and is what the CI smoke test asserts).

### What gets substituted locally

The AWS-only seams are swapped for local equivalents, chosen by the `local` overlay:

| AWS | Local (kind) |
|-----|--------------|
| ALB via Load Balancer Controller | ingress-nginx (NodePort → `localhost:8080`) |
| External DNS → Route53 | (skipped) |
| cert-manager real issuer | (skipped — local apps are plain HTTP) |
| ESO → AWS Secrets Manager | (skipped — `db-service` uses a local `Secret`) |
| Pod Identity IAM roles | (not needed — no AWS calls) |
| RDS | in-cluster ephemeral Postgres |

The application manifests themselves are **identical** to what runs on AWS — only the
store/ingress/database backends differ per overlay. That's the point: the thing you test
locally is the thing you ship. The ESO → Secrets Manager wiring still lives in the
`staging`/`prod` overlays (schema-validated by `kubeconform`); to exercise it for real
without AWS, point ESO at a LocalStack Secrets Manager endpoint as below.

## What you cannot test locally

`LocalStack` cannot stand up EKS on its free tier, so a full `terraform apply` of the
cluster is **not** part of the local flow — it's covered by static validation + unit
tests instead. If you want to exercise the ESO → Secrets Manager path specifically, you
can point ESO at a LocalStack Secrets Manager endpoint; that's an optional extra, not the
default.

## CI

Every push runs layers 1 and 2, and a kind-based smoke test runs layer 3. See
[`.github/workflows/`](../.github/workflows/).
