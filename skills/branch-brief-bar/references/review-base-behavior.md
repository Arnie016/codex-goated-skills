# Review Base Behavior

Use this note when the user wants to understand, trust, or override Branch Brief Bar's compare-base heuristic.

## Default order

1. An explicit `--base-ref` always wins.
2. If the upstream already points at a different review branch such as `origin/main`, use that upstream.
3. If the upstream is only the same feature branch on the remote, prefer a review branch in this order:
   - `origin/HEAD`
   - `origin/main`
   - `main`
   - `origin/master`
   - `master`
   - `origin/trunk`
   - `trunk`
4. If no review branch resolves but the same-name upstream exists, fall back to that upstream.
5. If there is no upstream, fall back to `HEAD~1` when available.

## Why this exists

- A same-name upstream usually answers "what have I pushed?" rather than "what should a reviewer compare this against?"
- Review handoffs are more useful when they point at the branch likely to become the PR base.
- The helper prints the chosen compare base and the reason so the user can spot when the default is wrong and pin another ref.

## When to override

- The repo targets a release or hotfix branch instead of the default branch.
- The review should compare against a stack base or integration branch.
- The local clone is missing the remote default-branch ref and the fallback lands on the wrong baseline.
