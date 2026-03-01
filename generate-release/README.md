# Generate Changelog & Create Release

Generates a categorized changelog from git history between two tags and creates a GitHub Release. Supports multiple commit formats, platform-aware tag filtering, configurable issue tracker linking, and automatic Release Candidate detection.

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `draft_release` | Publish the release as a draft (`true`/`false`). | No | `false` |
| `platforms` | Platform scope: `auto` (detect from tag annotation), `mobile`, `web`, or `all`. | No | `auto` |
| `issue_tracker_url` | Base URL for issue links (e.g. `https://jira.example.com/browse/`). Empty = no links. | No | `""` |
| `ticket_prefixes` | Space-separated project prefixes to match (e.g. `PROJ OPS`). Empty = match all. | No | `""` |
| `commit_format` | Commit categorization format (see below). | No | `labels` |

### Commit Formats

| Format | Description | Commit Example |
|--------|-------------|----------------|
| `labels` | Categorizes by bracket labels in commit messages | `[feature] Add dark mode`, `[bugfix] Fix login` |
| `conventional` | Categorizes by Conventional Commits prefixes | `feat: add dark mode`, `fix: resolve login issue` |
| `none` | No categorization, flat list of all changes | Any format |

**`labels` categories:** `[feature]`/`[improvement]`, `[bug]`/`[bugfix]`/`[hotfix]`, `[task]`, `[infra]`/`[infrastructure]`/`[devops]`

**`conventional` categories:** `feat:`, `fix:`, `docs:`, `refactor:`/`perf:`/`style:`, `ci:`/`chore:`/`build:`

## Outputs

| Name | Description | Example |
|------|-------------|---------|
| `changelog` | The generated changelog in markdown format. | *(see below)* |
| `current_tag` | The current (release) tag. | `v1.2.3` |
| `previous_tag` | The previous tag used for the changelog diff. | `v1.2.2` |
| `is_rc` | Whether this is a Release Candidate (`true`/`false`). | `false` |

## How It Works

1. Detects the current tag via `git describe --tags --abbrev=0`
2. Determines if the tag is an RC (`*-rc.*`) — sets pre-release flag
3. Resolves platform from input or tag annotation
4. Finds the previous tag via GitHub Releases API (platform-compatible) or chronological fallback
5. Collects commits between tags (excluding merges, `[Release Process]`, `[skip ci]`)
6. Categorizes commits based on the selected `commit_format`
7. Extracts unique ticket references and optionally links them
8. Creates a GitHub Release with the changelog as body

## Changelog Output

The generated changelog includes:
- Header with tag, date, commit count, and platform
- Categorized sections (only non-empty sections are shown)
- Commit count per section
- Collapsible "Tickets Referenced" section
- Link to the full diff on GitHub

## Usage

### Basic — Labels Format (default)

```yaml
on:
  push:
    tags: ["v*"]

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: moreirodamian/github-actions/generate-release@v1
```

### Conventional Commits

```yaml
- uses: moreirodamian/github-actions/generate-release@v1
  with:
    commit_format: conventional
```

### Advanced — With Issue Tracker

```yaml
- id: release
  uses: moreirodamian/github-actions/generate-release@v1
  with:
    draft_release: true
    platforms: auto
    commit_format: labels
    issue_tracker_url: https://issues.example.com/browse/
    ticket_prefixes: PROJ OPS INFRA

- run: |
    echo "Tag: ${{ steps.release.outputs.current_tag }}"
    echo "Previous: ${{ steps.release.outputs.previous_tag }}"
    echo "Is RC: ${{ steps.release.outputs.is_rc }}"
```
