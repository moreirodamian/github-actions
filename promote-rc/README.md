# Promote RC to Final Release

Promotes a Release Candidate tag (`vX.Y.Z-rc.N`) to a final release tag (`vX.Y.Z`). The action resolves the RC tag, extracts the platform annotation from its git tag message (or release body), and creates an annotated final tag pointing at the same commit.

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `rc_tag` | Specific RC tag to promote (e.g. `v1.2.3-rc.2`). If empty, the latest RC tag is used automatically. | No | `""` |
| `git_user_name` | Git user name for the annotated tag. | No | `github-actions` |
| `git_user_email` | Git user email for the annotated tag. | No | `github-actions@github.com` |

## Outputs

| Name | Description | Example |
|------|-------------|---------|
| `final_version` | The finalized version tag. | `v1.2.3` |
| `rc_tag` | The RC tag that was promoted. | `v1.2.3-rc.2` |
| `platforms` | Platform annotation carried over from the RC tag (`mobile`, `web`, or `all`). | `all` |
| `already_exists` | Whether the final tag already existed before this run (`true`/`false`). | `false` |

## How It Works

1. Resolves the RC tag -- either the one you provide via `rc_tag` or the most recent `v*-rc.*` tag by creation date.
2. Extracts the platform annotation from the RC tag's git annotation message. Falls back to the GitHub Release body if the annotation is empty.
3. Defaults the platform to `all` if no valid value (`mobile`, `web`, `all`) is found.
4. If the final tag already exists, the action emits a warning and skips creation.
5. Otherwise, creates an annotated tag (`vX.Y.Z`) at the same commit as the RC and pushes it.
6. Writes a job summary table to `$GITHUB_STEP_SUMMARY`.

## Usage

### Basic Example

Promote the latest RC tag to a final release:

```yaml
jobs:
  promote:
    runs-on: ubuntu-latest
    steps:
      - name: Promote RC
        uses: moreirodamian/github-actions/promote-rc@v1
```

### Advanced Example

Promote a specific RC tag with a custom git identity, then use the outputs in a downstream step:

```yaml
jobs:
  promote:
    runs-on: ubuntu-latest
    steps:
      - name: Promote RC
        id: promote
        uses: moreirodamian/github-actions/promote-rc@v1
        with:
          rc_tag: v2.1.0-rc.3
          git_user_name: release-bot
          git_user_email: release-bot@example.com

      - name: Notify
        if: steps.promote.outputs.already_exists == 'false'
        run: |
          echo "Promoted ${{ steps.promote.outputs.rc_tag }} -> ${{ steps.promote.outputs.final_version }}"
          echo "Platforms: ${{ steps.promote.outputs.platforms }}"
```
