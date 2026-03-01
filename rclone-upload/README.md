# Rclone Upload

Uploads files to S3-compatible storage using rclone (via Docker). Supports multiple providers with automatic endpoint detection and optional CDN cache purge for DigitalOcean Spaces CDN and AWS CloudFront. A summary is written to the GitHub Actions job summary.

## Supported Providers

| Provider | Endpoint auto-detected | Notes |
|----------|----------------------|-------|
| DigitalOcean | Yes | `{region}.digitaloceanspaces.com` |
| AWS | Yes | `s3.{region}.amazonaws.com` |
| Wasabi | Yes | `s3.{region}.wasabisys.com` |
| Cloudflare | Yes | `{region}.r2.cloudflarestorage.com` |
| MinIO | No | Requires explicit `endpoint` |
| Custom | No | Requires explicit `endpoint` |

## Inputs

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `source` | Yes | | Local source directory to upload (relative to `$GITHUB_WORKSPACE`). |
| `bucket` | Yes | | Target bucket and optional folder (e.g. `my-bucket/frontend`). |
| `access_key` | Yes | | S3 access key ID. |
| `secret_key` | Yes | | S3 secret access key. |
| `provider` | No | `DigitalOcean` | Storage provider: `DigitalOcean`, `AWS`, `Wasabi`, `Cloudflare`, `MinIO`, `Custom`. |
| `region` | No | `nyc3` | Region for the storage provider (e.g. `nyc3`, `us-east-1`, `eu-central-1`). |
| `endpoint` | No | `""` | Custom S3 endpoint URL. If empty, auto-detected from provider and region. |
| `acl` | No | `private` | Access control for uploaded files (e.g. `private`, `public-read`). |
| `rclone_command` | No | `copy` | Rclone operation: `copy`, `sync`, or `move`. |
| `rclone_flags` | No | `""` | Extra rclone flags (e.g. `--transfers 8 --checkers 16`). |
| `cdn_provider` | No | `none` | CDN provider to purge after upload: `none`, `digitalocean`, `cloudfront`. |
| `cdn_id` | No | `""` | CDN endpoint or distribution ID for cache purge. |
| `cdn_token` | No | `""` | Token for CDN purge. Required for DigitalOcean; not needed for CloudFront if using OIDC. |

## Outputs

| Name | Description |
|------|-------------|
| `files_transferred` | Number of files transferred (from rclone output). |

## Basic Example

Upload a build directory to DigitalOcean Spaces:

```yaml
- name: Upload to Spaces
  uses: moreirodamian/github-actions/rclone-upload@v1
  with:
    source: dist
    bucket: my-bucket/frontend
    access_key: ${{ secrets.SPACES_ACCESS_KEY }}
    secret_key: ${{ secrets.SPACES_SECRET_KEY }}
```

## Advanced Example

Sync files to AWS S3 with public-read ACL, custom transfer settings, and CloudFront cache invalidation:

```yaml
- name: Upload and purge CDN
  uses: moreirodamian/github-actions/rclone-upload@v1
  with:
    source: build/output
    bucket: my-production-bucket/assets
    access_key: ${{ secrets.AWS_ACCESS_KEY_ID }}
    secret_key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    provider: AWS
    region: us-east-1
    acl: public-read
    rclone_command: sync
    rclone_flags: "--transfers 16 --checkers 32 --fast-list"
    cdn_provider: cloudfront
    cdn_id: ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID }}
```

Upload to a MinIO instance with an explicit endpoint:

```yaml
- name: Upload to MinIO
  uses: moreirodamian/github-actions/rclone-upload@v1
  with:
    source: artifacts
    bucket: ci-artifacts/${{ github.run_id }}
    access_key: ${{ secrets.MINIO_ACCESS_KEY }}
    secret_key: ${{ secrets.MINIO_SECRET_KEY }}
    provider: MinIO
    endpoint: minio.internal.example.com
    rclone_command: copy
```
