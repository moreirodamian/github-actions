# Reusable GitHub Actions

A collection of **production-ready, reusable GitHub Actions** for CI/CD pipelines.

## Available Actions

| Action | Description |
|--------|-------------|
| [ArgoCD Deploy](actions/argocd-deploy.md) | Deploy applications via ArgoCD CLI with multi-app support, retry, and caching |
| [Docker Build & Push](actions/docker-build.md) | Build & push Docker images with buildx, multi-registry, multi-platform, and GHA cache |
| [Version Bump](actions/version-bump.md) | Bump semantic versions in JSON, YAML, or TOML files with RC support |
| [Generate Release](actions/generate-release.md) | Generate changelogs from git history and create GitHub Releases |
| [Rclone Upload](actions/rclone-upload.md) | Upload files to S3-compatible storage with multi-provider support and CDN purge |
| [Promote RC](actions/promote-rc.md) | Promote a Release Candidate tag to a final release |

## Features

- **No vendor lock-in** — all client-specific data is input-driven
- **Job Summaries** — every action writes a summary table to `$GITHUB_STEP_SUMMARY`
- **Multi-arch** — ArgoCD CLI downloads the correct binary for the runner architecture
- **Buildx native** — Docker builds use buildx with GHA cache for fast rebuilds
- **Multi-provider** — rclone supports DigitalOcean, AWS, Wasabi, Cloudflare, and MinIO
- **RC workflow** — full Release Candidate lifecycle: bump RC, promote to final

## Quick Start

Pin to a major version to receive patches automatically:

```yaml
uses: moreirodamian/github-actions/<action>@v1
```

See the [Getting Started](getting-started.md) guide for a full pipeline example.

## License

[MIT](https://github.com/moreirodamian/github-actions/blob/main/LICENSE)
