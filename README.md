# poopals/.github

Shared defaults for every PooPals repo. This repo is public so GitHub applies the PR template org-wide, so it must never hold secrets.

| File | Used for |
|---|---|
| `.github/pull_request_template.md` | Default PR template for repos that have none of their own |
| `.github/workflows/pr-title.yml` | Reusable workflow that checks the PR title and description |
| `scripts/check-title.sh` | The rules; used by the workflow and, copied as `commit-msg`, by the local hook |
| `scripts/next-version.sh` | Computes the next release version from the last tag and the commits since |

## PR rules

The squashed PR title becomes the commit on `main`, so it carries the rules:

| Type | Scope | Story key | Issue in description |
|---|---|---|---|
| `feat` `fix` `perf` `refactor` | required, from the repo's `.github/commit-scopes.txt` | required: `[POO-BACK-59]` | required: `Closes #N` / `Fixes #N` / `Resolves #N` / `Refs #N` |
| `docs` `chore` `ci` `test` `build` `revert` | optional, not checked | not needed | not needed |

- Example: `feat(chat): add mentions [POO-BACK-59]`. Add `!` for a breaking change: `feat(api)!: ...`.
- When the PR's commits use several scopes, the title must list every one: `fix(toilet,shitting): ... [POO-BACK-59]`.
- HTML comments in the description are ignored, so the template's hints don't count as an issue link.

## Adopting it in a repo

1. Add `.github/commit-scopes.txt`: one allowed scope per line, `#` comments. Without it, any scope is accepted.
2. Add `.github/workflows/pr-title.yml`:

   ```yaml
   name: PR title
   on:
     pull_request:
       types: [opened, edited, synchronize, reopened]
   jobs:
     pr-title:
       uses: poopals/.github/.github/workflows/pr-title.yml@main
   ```

   `edited` makes the check re-run when the title or description changes.
3. Optional local hook: copy `scripts/check-title.sh` to the repo's hooks directory as `commit-msg` and activate it
   (`git config core.hooksPath <dir>`). It checks type and scope on every commit but does not require the story key
   or issue, because those are enforced on the PR title.
4. In GitHub settings: squash-merge only with the PR title as the commit message, and require the `PR title` check.

## Release versions

`scripts/next-version.sh [ref]` prints `RELEASE`, `VERSION` and `BREAKING_CHANGE` (evaluate with `eval "$(...)"`).
It takes the latest `vX.Y.Z` tag reachable from `ref` and bumps it from the commit subjects since:
`!` or a `BREAKING CHANGE:` footer is a major, `feat` a minor, anything else a patch. Docs-only ranges
and empty ranges give `RELEASE=false`. Tags must be fetched (`git fetch --tags`).
