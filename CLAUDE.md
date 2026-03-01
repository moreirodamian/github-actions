# CLAUDE.md - github-actions

## Project

Public repository of reusable GitHub Actions for CI/CD pipelines.
Owner: Damian Moreiro (personal project, not company-specific).

## Structure

```
github-actions/
├── argocd-deploy/       # Deploy apps via ArgoCD CLI
├── docker-build/        # Build & push Docker images (buildx, multi-registry)
├── version-bump/        # Bump semver in JSON/YAML/TOML files
├── generate-release/    # Generate changelog and create GitHub Release
├── rclone-upload/       # Upload files to S3-compatible storage via rclone
├── promote-rc/          # Promote RC tag to final release
└── .github/workflows/   # CI (lint) + Release (floating tags)
```

## Conventions

- Each action is a composite action (`using: composite`)
- Every action has: `action.yml`, `README.md`
- No client-specific data (URLs, org names, project prefixes) — everything is input-driven
- Shell scripts use `set -euo pipefail`, pass ShellCheck
- All `action.yml` files must be valid YAML
- Versioning: semantic tags (`v1.0.0`), floating major tags (`v1`)

## Commands

```bash
# Validate all action.yml files
for f in */action.yml; do python3 -c "import yaml; yaml.safe_load(open('$f'))"; done

# ShellCheck
shellcheck generate-release/generate-changelog.sh

# Check for client-specific strings (should return nothing)
grep -ri "kodear\|4piot\|treasuregame\|linear.app\|atlassian.net" --include="*.yml" --include="*.sh" --include="*.md" .
```
