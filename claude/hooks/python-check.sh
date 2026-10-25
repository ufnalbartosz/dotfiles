#!/bin/bash
# PostToolUse(Write|Edit) hook for .py files: ruff format, ruff check (+ Google docstring
# rules), mypy --strict. Auto-fixes what it can; exit 2 feeds the rest back to Claude.
# Missing-docstring rules (D100-D107) are ignored: this enforces docstring *format*, not presence.

input=$(cat)
file=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' <<<"$input")
[[ "$file" == *.py && -f "$file" ]] || exit 0

cd "$(dirname "$file")" || exit 0
problems=""

ruff format --quiet "$file" >/dev/null 2>&1

out=$(ruff check --fix --quiet --output-format concise \
  --extend-select D --extend-ignore D100,D101,D102,D103,D104,D105,D106,D107 \
  --config 'lint.pydocstyle.convention = "google"' "$file" 2>&1) \
  || problems+="ruff:"$'\n'"$out"$'\n'

# Prefer the project's own env (uv) so imports resolve; fall back to a throwaway mypy.
if uv run --quiet mypy --version >/dev/null 2>&1; then
  out=$(uv run --quiet mypy --strict --no-error-summary "$file" 2>&1)
else
  out=$(uvx --quiet mypy --strict --no-error-summary --ignore-missing-imports "$file" 2>&1)
fi
[ $? -eq 0 ] || problems+="mypy --strict:"$'\n'"$out"$'\n'

if [ -n "$problems" ]; then
  echo "Python check failed for $file — fix these:" >&2
  head -40 <<<"$problems" >&2
  exit 2
fi
exit 0
