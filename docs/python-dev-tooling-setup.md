# Python Dev Tooling Setup for Claude Code

A repeatable setup guide to wire up linting, formatting, type checking, testing, and live docs into Claude Code for any Python project.

---

## Tools Overview

| Tool | Purpose | Wired via |
|------|---------|-----------|
| **Pyright** | Type checking + go-to-definition, find-references, diagnostics | Claude Code Plugin |
| **Ruff** | Linting + formatting (replaces flake8, black, isort) | MCP server |
| **Pytest** | Test runner | MCP server |
| **Context7** | Live, version-specific library documentation | MCP server |

---

## One-Time Setup (User Scope)

Run once — applies to all projects on this machine.

### 1. Pyright LSP Plugin

```bash
claude plugin install pyright-lsp
```

Gives Claude IDE-level intelligence: type errors, go-to-definition, find-references, hover types.

### 2. Ruff MCP (lint + format)

```bash
claude mcp add ruff -- uvx mcp-server-analyzer
```

### 3. Pytest MCP (test runner)

```bash
claude mcp add pytest -- uvx mcp-pytest-runner
```

### 4. Context7 MCP (live docs)

```bash
claude mcp add context7 -- npx -y @upstash/context7-mcp@latest
```

> **Restart Claude Code** after installing plugins for them to take effect.

---

## Per-Project Setup

Add to the project's `.mcp.json` (project-scoped) if you want the servers scoped to the repo instead of globally:

```json
{
  "mcpServers": {
    "ruff": {
      "command": "uvx",
      "args": ["mcp-server-analyzer"]
    },
    "pytest": {
      "command": "uvx",
      "args": ["mcp-pytest-runner"]
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  }
}
```

---

## Verify Everything is Connected

```bash
claude mcp list
```

Expected output:
```
ruff:   uvx mcp-server-analyzer  ✓ Connected
pytest: uvx mcp-pytest-runner    ✓ Connected
context7: ...                    ✓ Connected
```

Check plugins:
```bash
claude plugin list
```

Expected:
```
pyright-lsp  ✔ enabled
```

---

## What Each Tool Provides to Claude

### Pyright (Plugin)
- Live type diagnostics after every edit
- `goToDefinition`, `findReferences`, `hover`, `documentSymbol`, `getDiagnostics`
- No mypy needed — Pyright is faster and stricter

### Ruff (MCP)
- `ruff_check` — lint Python files
- `ruff_format` — format code
- `ruff_fix` — auto-fix violations
- Configured via `pyproject.toml` or `ruff.toml`

### Pytest (MCP)
- Run tests directly from Claude
- Integrates with project's existing `pytest.ini` / `pyproject.toml`

### Context7 (MCP)
- Fetches real-time, version-specific docs for any library
- Use with `@context7` mentions or Claude will use it automatically

---

## Recommended `pyproject.toml` snippet

```toml
[tool.ruff]
line-length = 88
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "I", "UP"]  # pycodestyle, pyflakes, isort, pyupgrade

[tool.mypy]
strict = true
# Note: type checking is handled by Pyright LSP in Claude Code
# mypy config kept here for CI pipelines

[tool.pytest.ini_options]
testpaths = ["tests"]
```

---

## Notes

- **mypy**: No standalone MCP available. Pyright covers type checking interactively. Keep mypy for CI if needed (`uv run mypy src/`).
- **uvx**: Runs Python MCP servers in isolated environments — no venv management needed.
- **Scope**: Plugins are user-scoped (all projects). MCP servers can be user or project-scoped.
