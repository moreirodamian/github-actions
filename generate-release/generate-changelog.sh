#!/usr/bin/env bash
set -euo pipefail

# Usage: generate-changelog.sh <previous_tag> <current_tag> [platforms]
#
# Environment variables:
#   ISSUE_TRACKER_BASE_URL - Base URL for issue links (e.g. https://jira.example.com/browse/)
#                            If empty, ticket references are shown without links.
#   TICKET_PREFIXES        - Space-separated list of project prefixes to match (e.g. "PROJ OPS").
#                            If empty, matches any alphanumeric prefix pattern.
#   COMMIT_FORMAT          - Commit categorization format:
#                            "labels"       (default) - [feature], [bug], [task], [infra], etc.
#                            "conventional" - feat:, fix:, docs:, refactor:, ci:, chore:, etc.
#                            "none"         - no categorization, flat list

# PREV_TAG may be empty on the very first release (no previous tag exists yet).
# Only CURR_TAG is strictly required.
PREV_TAG="${1-}"
CURR_TAG="${2:?Usage: generate-changelog.sh <prev_tag> <current_tag> [platforms]}"
PLATFORMS="${3:-}"

ISSUE_TRACKER_BASE_URL="${ISSUE_TRACKER_BASE_URL:-}"
TICKET_PREFIXES="${TICKET_PREFIXES:-}"
COMMIT_FORMAT="${COMMIT_FORMAT:-labels}"

# Ensure base URL ends with a single slash if non-empty
if [[ -n "${ISSUE_TRACKER_BASE_URL}" ]]; then
  ISSUE_TRACKER_BASE_URL="${ISSUE_TRACKER_BASE_URL%/}/"
fi
export ISSUE_TRACKER_BASE_URL

# ── Platform label ──────────────────────────────────────────────────
platforms_label=""
if [[ -n "${PLATFORMS}" && "${PLATFORMS}" != "all" ]]; then
  case "${PLATFORMS}" in
    web)    platforms_label=" (Web Only)" ;;
    mobile) platforms_label=" (Mobile Only)" ;;
    *)      platforms_label=" (${PLATFORMS})" ;;
  esac
fi

# ── RC detection ────────────────────────────────────────────────────
is_rc="false"
if [[ "${CURR_TAG}" == *-rc.* ]]; then
  is_rc="true"
fi

# ── Collect commits ─────────────────────────────────────────────────
# On the first release there is no previous tag, so walk the full history
# reachable from CURR_TAG instead of a PREV_TAG..CURR_TAG range.
if [[ -n "${PREV_TAG}" ]]; then
  commit_range="${PREV_TAG}..${CURR_TAG}"
else
  commit_range="${CURR_TAG}"
fi
changes="$(git log --oneline --no-merges "${commit_range}" \
  | grep -v '\[Release Process\]' \
  | grep -v '\[skip ci\]' \
  || true)"

total_commits="$(echo "${changes}" | grep -c '.' || echo 0)"

# ── Ticket linking ──────────────────────────────────────────────────
linkify_tickets() {
  local msg="$1"

  if [[ -n "${ISSUE_TRACKER_BASE_URL}" ]]; then
    msg="$(
      printf '%s' "${msg}" \
      | perl -0777 -pe '
          my $base = $ENV{ISSUE_TRACKER_BASE_URL} || "";
          $base =~ s{/?$}{/} if length $base;
          s/\[([A-Za-z][A-Za-z0-9]+)-([0-9]+)\]/
            do {
              my $proj = uc($1);
              my $num  = $2;
              "[".$proj."-".$num."](".$base.$proj."-".$num.")"
            }
          /ge;
        '
    )"
  else
    msg="$(
      printf '%s' "${msg}" \
      | perl -0777 -pe 's/\[([A-Za-z][A-Za-z0-9]+)-([0-9]+)\]/"[".uc($1)."-".$2."]"/ge;'
    )"
  fi
  echo "${msg}"
}

# ── Process a single commit line ────────────────────────────────────
process_line() {
  local line="$1"
  # Extract short hash and message
  local hash msg
  hash="$(echo "${line}" | awk '{print $1}')"
  msg="$(echo "${line}" | cut -d' ' -f2-)"

  # Link tickets
  msg="$(linkify_tickets "${msg}")"

  # Remove category labels (both formats) for cleaner output
  msg="$(echo "${msg}" | sed -E 's/\[(feature|improvement|bug|bugfix|hotfix|task|infra|infrastructure|devops)\]//Ig')"
  msg="$(echo "${msg}" | sed -E 's/^(feat|fix|docs|refactor|ci|chore|perf|test|style|build|revert)(\(.+\))?:\s*//')"

  # Trim and squeeze
  msg="$(echo "${msg}" | sed 's/^[ \t]*//;s/[ \t]*$//' | tr -s ' ')"

  echo "\`${hash}\` ${msg}"
}

# ── Categorize commits ──────────────────────────────────────────────
feat_lines="" fix_lines="" task_lines="" infra_lines="" docs_lines="" refactor_lines="" other_lines=""

if [[ -n "${changes}" ]]; then
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    processed="$(process_line "${line}")"

    case "${COMMIT_FORMAT}" in
      conventional)
        if echo "${line}" | grep -qEi '^[a-f0-9]+ feat(\(.+\))?:'; then
          feat_lines+="${processed}"$'\n'
        elif echo "${line}" | grep -qEi '^[a-f0-9]+ fix(\(.+\))?:'; then
          fix_lines+="${processed}"$'\n'
        elif echo "${line}" | grep -qEi '^[a-f0-9]+ docs(\(.+\))?:'; then
          docs_lines+="${processed}"$'\n'
        elif echo "${line}" | grep -qEi '^[a-f0-9]+ (refactor|perf|style)(\(.+\))?:'; then
          refactor_lines+="${processed}"$'\n'
        elif echo "${line}" | grep -qEi '^[a-f0-9]+ (ci|chore|build)(\(.+\))?:'; then
          infra_lines+="${processed}"$'\n'
        else
          other_lines+="${processed}"$'\n'
        fi
        ;;
      labels)
        if echo "${line}" | grep -qEi '\[(feature|improvement)\]'; then
          feat_lines+="${processed}"$'\n'
        elif echo "${line}" | grep -qEi '\[(bug|bugfix|hotfix)\]'; then
          fix_lines+="${processed}"$'\n'
        elif echo "${line}" | grep -qEi '\[task\]'; then
          task_lines+="${processed}"$'\n'
        elif echo "${line}" | grep -qEi '\[(infra|infrastructure|devops)\]'; then
          infra_lines+="${processed}"$'\n'
        else
          other_lines+="${processed}"$'\n'
        fi
        ;;
      none)
        other_lines+="${processed}"$'\n'
        ;;
    esac
  done <<< "${changes}"
fi

# ── Collect unique tickets ──────────────────────────────────────────
ALL_TICKETS=""
if [[ -n "${TICKET_PREFIXES}" ]]; then
  PREFIXES_RE="$(echo "${TICKET_PREFIXES}" | tr ' ' '|')"
  ALL_TICKETS="$(echo "${changes}" | perl -ne "
    while (/\\[((${PREFIXES_RE})-[0-9]+)\\]/gi) {
      my \$k = uc(\$1);
      \$h{\$k}=1;
    }
    END { print join(\" \", sort keys %h); }
  " || true)"
else
  ALL_TICKETS="$(echo "${changes}" | perl -ne '
    while (/\[([A-Za-z][A-Za-z0-9]+-[0-9]+)\]/g) {
      my $k = uc($1);
      $h{$k}=1;
    }
    END { print join(" ", sort keys %h); }
  ' || true)"
fi

# ── Helpers ─────────────────────────────────────────────────────────
format_section() {
  local content="$1"
  content="$(echo "${content}" | sed '/^[[:space:]]*$/d')"
  if [[ -n "${content}" ]]; then
    echo "${content}" | while IFS= read -r line; do echo "- ${line}"; done
  else
    echo "*No changes*"
  fi
}

count_lines() {
  local content="$1"
  content="$(echo "${content}" | sed '/^[[:space:]]*$/d')"
  if [[ -n "${content}" ]]; then
    echo "${content}" | wc -l | tr -d '[:space:]'
  else
    echo "0"
  fi
}

# ── Build release title ─────────────────────────────────────────────
release_title="${CURR_TAG}"
if [[ "${is_rc}" == "true" ]]; then
  release_title="${release_title} (Release Candidate)"
fi
release_title="${release_title}${platforms_label}"

# ── Generate release notes ──────────────────────────────────────────
release_notes_file="$(mktemp)"

{
  # Header
  echo "# ${release_title}"
  echo ""
  echo "> **Date:** $(date '+%B %d, %Y') | **Commits:** ${total_commits} | **Platforms:** ${PLATFORMS:-all}"
  echo ""

  # Platform line for machine parsing (used by platform-aware tag search)
  echo "platforms: ${PLATFORMS:-all}"
  echo ""
  echo "---"
  echo ""

  case "${COMMIT_FORMAT}" in
    conventional)
      # Conventional commits sections
      if [[ -n "$(echo "${feat_lines}" | sed '/^[[:space:]]*$/d')" ]]; then
        echo "### New Features  ($(count_lines "${feat_lines}"))"
        echo ""
        format_section "${feat_lines}"
        echo ""
      fi
      if [[ -n "$(echo "${fix_lines}" | sed '/^[[:space:]]*$/d')" ]]; then
        echo "### Bug Fixes  ($(count_lines "${fix_lines}"))"
        echo ""
        format_section "${fix_lines}"
        echo ""
      fi
      if [[ -n "$(echo "${docs_lines}" | sed '/^[[:space:]]*$/d')" ]]; then
        echo "### Documentation  ($(count_lines "${docs_lines}"))"
        echo ""
        format_section "${docs_lines}"
        echo ""
      fi
      if [[ -n "$(echo "${refactor_lines}" | sed '/^[[:space:]]*$/d')" ]]; then
        echo "### Refactoring & Performance  ($(count_lines "${refactor_lines}"))"
        echo ""
        format_section "${refactor_lines}"
        echo ""
      fi
      if [[ -n "$(echo "${infra_lines}" | sed '/^[[:space:]]*$/d')" ]]; then
        echo "### CI/CD & Maintenance  ($(count_lines "${infra_lines}"))"
        echo ""
        format_section "${infra_lines}"
        echo ""
      fi
      if [[ -n "$(echo "${other_lines}" | sed '/^[[:space:]]*$/d')" ]]; then
        echo "### Other Changes  ($(count_lines "${other_lines}"))"
        echo ""
        format_section "${other_lines}"
        echo ""
      fi
      ;;
    labels)
      # Label-based sections
      if [[ -n "$(echo "${feat_lines}" | sed '/^[[:space:]]*$/d')" ]]; then
        echo "### New Features  ($(count_lines "${feat_lines}"))"
        echo ""
        format_section "${feat_lines}"
        echo ""
      fi
      if [[ -n "$(echo "${fix_lines}" | sed '/^[[:space:]]*$/d')" ]]; then
        echo "### Bug Fixes  ($(count_lines "${fix_lines}"))"
        echo ""
        format_section "${fix_lines}"
        echo ""
      fi
      if [[ -n "$(echo "${task_lines}" | sed '/^[[:space:]]*$/d')" ]]; then
        echo "### Tasks  ($(count_lines "${task_lines}"))"
        echo ""
        format_section "${task_lines}"
        echo ""
      fi
      if [[ -n "$(echo "${infra_lines}" | sed '/^[[:space:]]*$/d')" ]]; then
        echo "### Infrastructure  ($(count_lines "${infra_lines}"))"
        echo ""
        format_section "${infra_lines}"
        echo ""
      fi
      if [[ -n "$(echo "${other_lines}" | sed '/^[[:space:]]*$/d')" ]]; then
        echo "### Other Changes  ($(count_lines "${other_lines}"))"
        echo ""
        format_section "${other_lines}"
        echo ""
      fi
      ;;
    none)
      echo "### Changes  (${total_commits})"
      echo ""
      format_section "${other_lines}"
      echo ""
      ;;
  esac

  # Tickets section
  if [[ -n "${ALL_TICKETS//[[:space:]]/}" ]]; then
    echo "---"
    echo ""
    echo "<details>"
    echo "<summary><strong>Tickets Referenced</strong></summary>"
    echo ""
    while IFS= read -r key; do
      [[ -z "${key}" ]] && continue
      if [[ -n "${ISSUE_TRACKER_BASE_URL}" ]]; then
        echo "- [${key}](${ISSUE_TRACKER_BASE_URL}${key})"
      else
        echo "- ${key}"
      fi
    done <<< "$(echo "${ALL_TICKETS}" | tr ' ' '\n')"
    echo ""
    echo "</details>"
    echo ""
  fi

  # Compare link
  echo "---"
  echo ""
  REPO_SLUG="${GITHUB_REPOSITORY:-owner/repo}"
  if [[ -n "${PREV_TAG}" ]]; then
    echo "**Full diff:** [\`${PREV_TAG}...${CURR_TAG}\`](https://github.com/${REPO_SLUG}/compare/${PREV_TAG}...${CURR_TAG})"
  else
    echo "**Full diff:** [\`${CURR_TAG}\`](https://github.com/${REPO_SLUG}/commits/${CURR_TAG})"
  fi

} > "${release_notes_file}"

cat "${release_notes_file}"

# Output for GitHub Actions
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "changelog<<CHANGELOG_EOF"
    cat "${release_notes_file}"
    echo "CHANGELOG_EOF"
  } >> "${GITHUB_OUTPUT}"
fi
