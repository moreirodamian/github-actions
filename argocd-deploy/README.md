# ArgoCD Deploy

Installs the ArgoCD CLI (with caching and multi-arch support) and deploys one or more ArgoCD applications. It sets Helm values, syncs each app, and waits until the app reports healthy. A summary table is written to the GitHub Actions job summary.

## Inputs

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `argocd_url` | Yes | | ArgoCD server URL (host:port or FQDN). |
| `argocd_token` | Yes | | ArgoCD auth token. |
| `argocd_apps` | Yes | | Comma-separated list of ArgoCD application names to deploy. |
| `version` | Yes | | Image tag / version to set (e.g. `1.2.3-abc123`). |
| `revision` | No | `${{ github.sha }}` | Git revision for the ArgoCD app source. Defaults to the current workflow SHA. |
| `image_tag_key` | No | `app.image.tag` | Helm values key path for the image tag. Used when `helm_values` is empty. |
| `helm_values` | No | `""` | Comma-separated Helm values to set (e.g. `key1=value1,key2=value2`). Overrides `image_tag_key`. |
| `timeout_seconds` | No | `1200` | Timeout in seconds for sync and wait operations. |
| `grpc_web` | No | `true` | Use the `--grpc-web` flag (`true`/`false`). |
| `argocd_cli_version` | No | `v2.13.3` | ArgoCD CLI version tag (from GitHub releases). |
| `extra_headers` | No | `""` | Comma-separated extra HTTP headers sent with every argocd request (`Name:value,Name2:value2`). Useful when the ArgoCD API sits behind a WAF/CDN that needs a bypass header. |
| `retry_count` | No | `0` | Number of retries for the sync operation. `0` means no retry. Uses exponential backoff. |
| `debug` | No | `false` | If `true`, prints base64-encoded commands for local debugging. |

### Behind a WAF/CDN

If the ArgoCD API is proxied by Cloudflare (or similar) with a managed challenge,
the CLI gets a `403`. Send the bypass header your WAF rule expects:

```yaml
- uses: moreirodamian/github-actions/argocd-deploy@v1
  with:
    argocd_url: argo.example.com
    argocd_token: ${{ secrets.ARGOCD_TOKEN }}
    argocd_apps: my-app
    version: 1.2.3
    extra_headers: "X-CI-Bypass:${{ secrets.ARGOCD_CI_BYPASS }}"
```

## Outputs

| Name | Description |
|------|-------------|
| `deployed_apps` | Comma-separated list of successfully deployed app names. |

## Basic Example

Deploy a single application after building and pushing a Docker image:

```yaml
- name: Deploy to ArgoCD
  uses: moreirodamian/github-actions/argocd-deploy@v1
  with:
    argocd_url: argocd.example.com
    argocd_token: ${{ secrets.ARGOCD_TOKEN }}
    argocd_apps: my-app
    version: ${{ github.sha }}
```

## Advanced Example

Deploy multiple applications with custom Helm values, retry logic, and a specific CLI version:

```yaml
- name: Deploy to ArgoCD
  uses: moreirodamian/github-actions/argocd-deploy@v1
  with:
    argocd_url: argocd.example.com
    argocd_token: ${{ secrets.ARGOCD_TOKEN }}
    argocd_apps: api-backend, worker-backend
    version: 2.1.0-${{ github.run_number }}
    revision: ${{ github.ref_name }}
    helm_values: "app.image.tag=2.1.0-${{ github.run_number }},app.replicas=3"
    timeout_seconds: 600
    grpc_web: true
    argocd_cli_version: v2.13.3
    retry_count: 3
    debug: false
```
