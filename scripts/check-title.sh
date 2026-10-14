#!/usr/bin/env bash
# Validates a Conventional Commit title; shared by the PR-title workflow and the commit-msg hook.
#   feat|fix|perf|refactor  -> `type(scope)[!|#]: subject [STORY-123]`, scope from commit-scopes.txt
#   docs|chore|ci|test|build|revert -> `type(scope)[!|#]: subject`, scope and story optional
#   `!` = breaking change (major), `#` = skip the automatic deploy (version from the type)
# Usage: check-title.sh <title | commit-msg-file> [scopes-file] [pr-commit-subjects-file]
#   file argument (hook mode): story reference not required, since the PR title is what lands on main
#   PR_BODY env var (PR mode): functional PRs must link an issue, e.g. `Closes #123` or `Refs poopals/other-repo#4`
#   commit subjects file (PR mode): the title must list every scope used by the PR's functional commits
set -u

input="$1"
hook_mode=false
if [ -f "$input" ]; then
  hook_mode=true
  title="$(head -n1 "$input")"
else
  title="$input"
fi
scopes_file="${2:-$(git rev-parse --show-toplevel 2>/dev/null)/.github/commit-scopes.txt}"
commits_file="${3:-}"

case "$title" in
  Merge\ * | Revert\ * | fixup!\ * | squash!\ *) exit 0 ;;
esac

fail() {
  echo "Invalid title: $title" >&2
  echo "$1" >&2
  echo "Expected: feat|fix|perf|refactor(scope)[!|#]: subject [STORY-123]  or  docs|chore|ci|test|build|revert[(scope)][!|#]: subject" >&2
  exit 1
}

pattern='^(feat|fix|perf|refactor|docs|chore|ci|test|build|revert)(\(([^)]+)\))?([!#]?): (.+)$'
[[ "$title" =~ $pattern ]] || fail "Title must follow Conventional Commits."
type="${BASH_REMATCH[1]}"
scope_list="${BASH_REMATCH[3]}"
subject="${BASH_REMATCH[5]}"

case "$type" in
  feat | fix | perf | refactor)
    [ -n "$scope_list" ] || fail "'$type' needs a scope (functional area)."
    if [ -f "$scopes_file" ]; then
      allowed="$(grep -Ev '^\s*(#|$)' "$scopes_file")"
      IFS=, read -ra used <<<"$scope_list"
      for scope in "${used[@]}"; do
        scope="${scope// /}"
        grep -Fxq "$scope" <<<"$allowed" ||
          fail "Unknown scope '$scope'. Allowed: $(tr '\n' ' ' <<<"$allowed")"
      done
    fi
    if [ "$hook_mode" = false ] && ! [[ "$subject" =~ \[[A-Z]+(-[A-Z]+)*-[0-9]+\]$ ]]; then
      fail "'$type' needs a story reference at the end, e.g. [POO-BACK-59]."
    fi
    issue_ref='(close[sd]?|fix(e[sd])?|resolve[sd]?|refs?):?[[:space:]]+([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)?#[0-9]+'
    if [ "${PR_BODY+set}" = set ] && ! perl -0777 -pe 's/<!--.*?-->//gs' <<<"$PR_BODY" | grep -Eiq "$issue_ref"; then
      fail "'$type' PRs must link their GitHub issue in the description, e.g. 'Closes #123' (or 'Refs #123')."
    fi
    ;;
esac

if [ -n "$commits_file" ] && [ -f "$commits_file" ]; then
  title_scopes=",${scope_list// /},"
  missing=""
  functional='^(feat|fix|perf|refactor)\(([^)]+)\)[!#]?:'
  while IFS= read -r commit; do
    if [[ "$commit" =~ $functional ]]; then
      IFS=, read -ra commit_scopes <<<"${BASH_REMATCH[2]}"
      for scope in "${commit_scopes[@]}"; do
        scope="${scope// /}"
        [[ "$title_scopes" == *",$scope,"* || "$missing" == *" $scope "* ]] || missing="$missing $scope "
      done
    fi
  done <"$commits_file"
  [ -z "$missing" ] || fail "Title scopes must cover every scope in the PR's commits; missing:$missing"
fi
