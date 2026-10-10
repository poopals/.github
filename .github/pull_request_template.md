## Summary

<!-- What changes and why. The PR title becomes the commit on main:
     feat|fix|perf|refactor(scope)!: subject [STORY-123]   e.g. `feat(chat): add mentions [POO-BACK-59]`
     docs|chore|ci|test|build(...): subject               (no scope or story needed) -->

Closes #<!-- required for feat/fix/perf/refactor: `Closes #123`, or `Refs #123` if the story needs more PRs -->

## Type of change

- [ ] feat — new functionality (minor release)
- [ ] fix — bug fix (patch release)
- [ ] refactor / perf / test / build / ci / chore
- [ ] docs only
- [ ] **Breaking change** — title uses `!` (e.g. `feat(api)!: ...`); backend: skips the automatic CD bump and needs a manual deploy

## Checklist

- [ ] PR title follows Conventional Commits; functional changes carry the story reference
- [ ] Tests added or updated
- [ ] Formatting applied (Spotless / project formatter)
- [ ] Linked PR in the related repo (API spec, CD, Flutter) if the contract or deployment changes
- [ ] Docs / README updated if behaviour changed
