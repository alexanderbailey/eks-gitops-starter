# Tailscale operator (optional component)

Private, keyless access to in-cluster services over a tailnet — no public
ingress required. **Off by default.** A Kustomize
[component](https://kubectl.docs.kubernetes.io/guides/config_management/components/),
so it contributes nothing until an overlay opts in.

## Enable

Set `ENABLE_TAILSCALE=true` in `.env` and re-run `./setup.sh`, which appends the
component to the target overlay. To wire it by hand instead, add to
`bootstrap/overlays/<env>/kustomization.yaml`:

```yaml
components:
  - ../../base/cluster_setup/components/tailscale
```

## How it fits together

1. Create a Tailscale OAuth client (scopes: Devices Write) and store it in AWS
   Secrets Manager under `TAILSCALE_OAUTH_SECRET` (default key `tailscale/oauth`)
   as JSON with `client_id` and `client_secret`.
2. `oauth-externalsecret.yaml` — External Secrets syncs that into the
   `operator-oauth` Secret in the `tailscale` namespace, via the same
   `aws-secrets-manager` ClusterSecretStore every app uses.
3. `operator.yaml` — the Tailscale operator (Helm chart, delivered as an Argo CD
   Application) consumes that Secret and joins the cluster to your tailnet.

Expose a Service by annotating it (`tailscale.com/expose: "true"`) or with a
Tailscale-class `Ingress`; see the
[operator docs](https://tailscale.com/kb/1236/kubernetes-operator).
