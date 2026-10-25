#!/bin/bash
# PreToolUse(Bash) gate: before `git commit`, lint staged Python and run the project's tests.
# Exit 2 blocks the commit and feeds stderr back to Claude; exit 0 lets it through.
# Projects with real git pre-commit hooks are still checked by git itself on top of this.

input=$(cat)
command=$(jq -r '.tool_input.command // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")

# Only act on commands that run `git commit` (also catches `cd x && git commit`).
grep -Eq '(^|[^[:alnum:]_-])git[[:space:]]+(.*[[:space:]])?commit([[:space:]]|$)' <<<"$command" || exit 0

cd "${cwd:-.}" 2>/dev/null || exit 0
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0

fail() {
  echo "pre-commit gate: $1 — fix before committing." >&2
  tail -40 <<<"$2" >&2
  exit 2
}

# Lint staged Python files.
if command -v ruff >/dev/null 2>&1 && git diff --cached --name-only --diff-filter=ACM -z -- '*.py' | grep -qz .; then
  out=$(git diff --cached --name-only --diff-filter=ACM -z -- '*.py' | xargs -0 ruff check 2>&1) \
    || fail "ruff check failed" "$out"
fi

# Run the project's tests.
if [ -f package.json ] && jq -e '.scripts.test and (.scripts.test | contains("no test specified") | not)' package.json >/dev/null 2>&1; then
  out=$(npm test --silent 2>&1) || fail "npm test failed" "$out"
elif [ -f pytest.ini ] || [ -f conftest.py ] || [ -d tests ] || grep -qs '\[tool\.pytest' pyproject.toml; then
  # Prefer the project's own environment (uv), then a global pytest.
  if [ -f pyproject.toml ] && command -v uv >/dev/null 2>&1 && uv run --quiet python -c 'import pytest' >/dev/null 2>&1; then
    out=$(uv run --quiet python -m pytest -x -q 2>&1) || fail "pytest failed" "$out"
  elif command -v pytest >/dev/null 2>&1; then
    out=$(pytest -x -q 2>&1) || fail "pytest failed" "$out"
  elif python3 -c 'import pytest' >/dev/null 2>&1; then
    out=$(python3 -m pytest -x -q 2>&1) || fail "pytest failed" "$out"
  fi
fi

exit 0
