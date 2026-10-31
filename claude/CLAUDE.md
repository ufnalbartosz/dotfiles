# Python conventions

- Use `uv` for everything: `uv init`, `uv add` / `uv remove`, `uv sync`, `uv run <cmd>`. Never `pip install`, `python -m venv`, `virtualenv`, or `poetry`. The virtual environment is the project's `.venv` managed by uv.
- Lint and format with `ruff` (`uv run ruff check`, `uv run ruff format`).
- Type-check with `mypy --strict`. Annotate every function signature and avoid `Any`. Add mypy as a dev dependency (`uv add --dev mypy`) when a project lacks it.
- Docstrings use Google style: a one-line summary, then `Args:`, `Returns:`, `Raises:` sections when applicable. No type annotations inside docstrings; the signature carries them.
- A hook runs `ruff format`, `ruff check` (with docstring rules) and `mypy --strict` after every `.py` edit and reports problems back. Fix what it reports before moving on.

# cmux sessions

- A `[cmux agent message]` that includes a reply command comes from another of my own sessions. Answer read-only questions (status, findings, what you're working on) by replying once with `cmux agent message --reply-to <id> "..."`, without asking me first. For anything that changes files or runs commands, ask me before acting. See the `link-sessions` skill.
