# Bump Version

Bumps a semantic version in a JSON, YAML, or TOML file. Supports major/minor/patch increments, Release Candidate (RC) tag cycles, platform annotations, public changelogs, and dry-run mode.

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `version_file` | Path to the version file (JSON, YAML, or TOML). | Yes | `config.json` |
| `version_key` | Key path to the version field using jq/yq syntax (e.g. `.version`, `.tool.poetry.version`). | No | `.version` |
| `version_type` | Which part to bump: `major`, `minor`, or `patch`. | Yes | `patch` |
| `platforms` | Platform marker written into the git tag annotation (`mobile`, `web`, or `all`). | No | `all` |
| `is_final_release` | If `false`, creates an RC tag (`vX.Y.Z-rc.N`) instead of a final tag. Accepts `true`/`false`/`yes`/`no`/`1`/`0`. | No | `true` |
| `bot_pat` | Optional Personal Access Token for pushing. When set, the checkout uses this token instead of `GITHUB_TOKEN` (useful for bypassing branch protection or triggering downstream workflows). | No | `""` |
| `public_changelog` | Optional public changelog text. When provided, saved to `public_changelog/vX.Y.Z.txt` and committed alongside the version bump. | No | `""` |
| `git_user_name` | Git user name for commits and tags. | No | `github-actions` |
| `git_user_email` | Git user email for commits and tags. | No | `github-actions@github.com` |
| `dry_run` | If `true`, calculates the new version and tag name without committing, tagging, or pushing. | No | `false` |

## Outputs

| Name | Description | Example |
|------|-------------|---------|
| `new_version` | The new version string (without `v` prefix). | `1.2.3` |
| `previous_version` | The version before bumping. | `1.2.2` |
| `tag_name` | The git tag created (or that would be created in dry-run). | `v1.2.3` or `v1.2.3-rc.1` |
| `is_rc` | Whether an RC tag was created (`true`/`false`). | `false` |
| `bump_performed` | Whether the version number was actually incremented (`true`/`false`). When continuing an existing RC cycle, the version stays the same and only the RC suffix increments. | `true` |

## How It Works

1. Reads the current version from the specified file and key path.
2. Determines whether to bump the version number:
   - **Final releases** always bump.
   - **RC releases** bump only when no existing RC tags exist for the current version; otherwise, only the RC suffix (`-rc.N`) increments.
3. Writes the new version back to the file (JSON/YAML/TOML).
4. Optionally writes a public changelog file to `public_changelog/vX.Y.Z.txt`.
5. Commits all changes with the message `[Release Process] [skip ci] Prepare release X.Y.Z`.
6. Creates an annotated git tag with the platform annotation and pushes both the commit and the tag.
7. Writes a job summary table to `$GITHUB_STEP_SUMMARY`.

## Usage

### Basic Example

Bump the patch version in `config.json` and create a final release tag:

```yaml
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Bump version
        uses: moreirodamian/github-actions/version-bump@v1
        with:
          version_file: config.json
          version_type: patch
```

### Advanced Example

Create a Release Candidate for a minor version bump in a TOML file, using a bot PAT and a public changelog:

```yaml
jobs:
  release-candidate:
    runs-on: ubuntu-latest
    steps:
      - name: Bump version (RC)
        id: bump
        uses: moreirodamian/github-actions/version-bump@v1
        with:
          version_file: pyproject.toml
          version_key: .tool.poetry.version
          version_type: minor
          platforms: mobile
          is_final_release: false
          bot_pat: ${{ secrets.BOT_PAT }}
          public_changelog: |
            - Added new onboarding flow
            - Fixed crash on login screen
          git_user_name: release-bot
          git_user_email: release-bot@example.com

      - name: Print result
        run: |
          echo "Version: ${{ steps.bump.outputs.new_version }}"
          echo "Tag: ${{ steps.bump.outputs.tag_name }}"
          echo "Is RC: ${{ steps.bump.outputs.is_rc }}"
          echo "Bump performed: ${{ steps.bump.outputs.bump_performed }}"
```

### Dry-Run Example

Preview the version bump without making any changes:

```yaml
jobs:
  preview:
    runs-on: ubuntu-latest
    steps:
      - name: Dry run
        id: dry
        uses: moreirodamian/github-actions/version-bump@v1
        with:
          version_file: package.json
          version_type: major
          dry_run: true

      - name: Show preview
        run: |
          echo "Would bump ${{ steps.dry.outputs.previous_version }} -> ${{ steps.dry.outputs.new_version }}"
          echo "Would create tag: ${{ steps.dry.outputs.tag_name }}"
```
