# Docker Build & Push

Builds and pushes Docker images using `docker buildx`. Supports multi-registry login (GHCR, Docker Hub, ECR, ACR), multi-platform builds, multi-target Dockerfiles, GitHub Actions build cache, and optional SLSA provenance and SBOM generation. A summary with all pushed tags is written to the GitHub Actions job summary.

## Inputs

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `repository` | Yes | | Full image repository (e.g. `ghcr.io/org/app`, `docker.io/org/app`, `123456.dkr.ecr.us-east-1.amazonaws.com/app`). |
| `username` | Yes | | Registry username. |
| `password` | Yes | | Registry password or token. |
| `tag` | No | `""` | Tag to apply (e.g. `1.4.2`). If empty, `latest` is used. |
| `dockerfile_path` | No | `Dockerfile` | Path to the Dockerfile. |
| `build_context` | No | `.` | Docker build context directory. |
| `target` | No | `""` | Docker build target(s). Comma-separated for multi-target (e.g. `cli,fpm`). |
| `custom_arguments` | No | `""` | Extra docker build arguments (e.g. `--build-arg FOO=bar`). |
| `platforms` | No | `linux/amd64` | Comma-separated target platforms (e.g. `linux/amd64,linux/arm64`). |
| `push_latest` | No | `false` | Also push a `latest` tag (`true`/`false`). |
| `provenance` | No | `false` | Enable SLSA provenance attestation (`true`/`false`). |
| `sbom` | No | `false` | Enable SBOM generation (`true`/`false`). |
| `cache_enabled` | No | `true` | Enable GitHub Actions build cache (`true`/`false`). |

## Outputs

| Name | Description |
|------|-------------|
| `image` | Repository image name. |
| `tags` | Comma-separated list of all pushed `image:tag` combinations. |
| `digest` | Image digest (`sha256`) of the last pushed image. |

## Basic Example

Build and push a single image to GitHub Container Registry:

```yaml
- name: Build and push Docker image
  uses: moreirodamian/github-actions/docker-build@v1
  with:
    repository: ghcr.io/my-org/my-app
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
    tag: ${{ github.sha }}
```

## Advanced Example

Multi-platform, multi-target build with provenance, SBOM, custom build args, and a latest tag:

```yaml
- name: Build and push Docker image
  id: docker
  uses: moreirodamian/github-actions/docker-build@v1
  with:
    repository: 123456789.dkr.ecr.us-east-1.amazonaws.com/my-app
    username: AWS
    password: ${{ steps.ecr-login.outputs.password }}
    tag: 2.1.0
    dockerfile_path: docker/Dockerfile
    build_context: .
    target: cli,fpm
    custom_arguments: "--build-arg APP_ENV=production --build-arg COMMIT_SHA=${{ github.sha }}"
    platforms: linux/amd64,linux/arm64
    push_latest: true
    provenance: true
    sbom: true
    cache_enabled: true

- name: Print pushed tags
  run: echo "Pushed tags: ${{ steps.docker.outputs.tags }}"
```

With multi-target set to `cli,fpm` and tag `2.1.0`, this produces the following tags:
- `my-app:cli-2.1.0`, `my-app:cli-latest`
- `my-app:fpm-2.1.0`, `my-app:fpm-latest`
