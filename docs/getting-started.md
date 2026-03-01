# Getting Started

## Installation

All actions live in a single repository. Reference them with the full path and pin to a major version:

```yaml
uses: moreirodamian/github-actions/<action-name>@v1
```

Pinning to `@v1` ensures you receive patch and minor updates automatically while avoiding breaking changes.

## Full Pipeline Example

This example shows a complete release pipeline that bumps the version, builds a Docker image, deploys via ArgoCD, and creates a GitHub Release:

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

## Release Candidate Workflow

For projects that need a staging step before final releases:

### 1. Create an RC

```yaml
- uses: moreirodamian/github-actions/version-bump@v1
  with:
    version_file: package.json
    version_type: minor
    is_final_release: false  # Creates vX.Y.Z-rc.1
```

### 2. Test and iterate

Push more RC tags (`-rc.2`, `-rc.3`, ...) by running the same workflow again without changing `version_type`.

### 3. Promote to final

```yaml
- uses: moreirodamian/github-actions/promote-rc@v1
  # Promotes the latest RC to a final vX.Y.Z tag
```

### 4. Generate the release

The release workflow triggers on the new `vX.Y.Z` tag and generates the changelog automatically.

## Individual Action Docs

Each action has its own detailed documentation with inputs, outputs, and examples:

- [ArgoCD Deploy](actions/argocd-deploy.md) — Deploy via ArgoCD CLI
- [Docker Build & Push](actions/docker-build.md) — Build & push Docker images
- [Version Bump](actions/version-bump.md) — Bump semver in JSON/YAML/TOML
- [Generate Release](actions/generate-release.md) — Changelog and GitHub Release
- [Rclone Upload](actions/rclone-upload.md) — Upload to S3-compatible storage
- [Promote RC](actions/promote-rc.md) — Promote RC to final release
