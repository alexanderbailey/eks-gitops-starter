# Environments

Each environment (`dev`, `staging`, `prod`) is an independent Terraform/OpenTofu
root that stands up one isolated cluster by calling the shared
[`../modules/cluster`](../modules/cluster) module. They differ only in their
`*.auto.tfvars` (see the table in [`../../docs/architecture.md`](../../docs/architecture.md)).

## State backend

No backend is committed, so a fresh checkout uses **local state** (fine for
`validate`/`plan` demos). `./setup.sh` writes a gitignored `backend_override.tf` into
each environment based on your `.env`:

| `.env` setting | Backend used |
|----------------|--------------|
| `USE_HCP_BACKEND=true` (+ `HCP_ORG`) | HCP Terraform, workspace `<env>_infra` |
| `TF_STATE_BUCKET=...` (default) | S3 + DynamoDB lock table |
| neither set | local state |

Re-run `./setup.sh` any time you change `.env`.

## Applying

```bash
task infra:apply ENV=dev      # or ENV=staging / ENV=prod
```

Order for a clean bootstrap: `infra/shared` first (ECR, DNS), then each environment.
After apply, point `kubectl` at the cluster with the printed
`aws eks update-kubeconfig --name <cluster_name>` command — though day-to-day you
shouldn't need to, since Argo CD reconciles everything from Git.
