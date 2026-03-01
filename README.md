# Reusable GitHub Actions

A collection of production-ready, reusable GitHub Actions for CI/CD pipelines.

## Actions

| Action | Description |
|--------|-------------|
| [argocd-deploy](./argocd-deploy/) | Deploy applications via ArgoCD CLI with multi-app support, retry, and caching |
| [docker-build](./docker-build/) | Build & push Docker images with buildx, multi-registry, multi-platform, and GHA cache |
| [version-bump](./version-bump/) | Bump semantic versions in JSON, YAML, or TOML files with RC support |
| [generate-release](./generate-release/) | Generate changelogs from git history and create GitHub Releases |
| [rclone-upload](./rclone-upload/) | Upload files to S3-compatible storage with multi-provider support and CDN purge |
| [promote-rc](./promote-rc/) | Promote a Release Candidate tag to a final release |

## Quick Start

Pin to a major version to receive patches automatically:

```yaml
uses: moreirodamian/github-actions/argocd-deploy@v1
```

### Full Pipeline Example

```yaml
name: Release

on:
  workflow_dispatch:
    inputs:
      version_type:
        type: choice
        options: [patch, minor, major]

jobs:
  bump:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.bump.outputs.new_version }}
      tag: ${{ steps.bump.outputs.tag_name }}
    steps:
      - uses: moreirodamian/github-actions/version-bump@v1
        id: bump
        with:
          version_file: package.json
          version_type: ${{ inputs.version_type }}

  build:
    needs: bump
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: moreirodamian/github-actions/docker-build@v1
        with:
          repository: ghcr.io/${{ github.repository }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
          tag: ${{ needs.bump.outputs.version }}

  deploy:
    needs: [bump, build]
    runs-on: ubuntu-latest
    steps:
      - uses: moreirodamian/github-actions/argocd-deploy@v1
        with:
          argocd_url: ${{ secrets.ARGOCD_URL }}
          argocd_token: ${{ secrets.ARGOCD_TOKEN }}
          argocd_apps: my-app
          version: ${{ needs.bump.outputs.version }}

  release:
    needs: [bump, deploy]
    runs-on: ubuntu-latest
    steps:
      - uses: moreirodamian/github-actions/generate-release@v1
        with:
          issue_tracker_url: https://jira.example.com/browse/
```

## Features

- **No vendor lock-in** — all client-specific data is input-driven
- **Job Summaries** — every action writes a summary table to `$GITHUB_STEP_SUMMARY`
- **Multi-arch** — ArgoCD CLI downloads the correct binary for the runner architecture
- **Buildx native** — Docker builds use buildx with GHA cache for fast rebuilds
- **Multi-provider** — rclone supports DigitalOcean, AWS, Wasabi, Cloudflare, and MinIO
- **RC workflow** — full Release Candidate lifecycle: bump RC, promote to final

## License

[MIT](./LICENSE)

