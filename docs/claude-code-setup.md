# Claude Code Setup

Documents the Claude Code user-level config in this repo (`claude/settings.json`, `claude/plugins.txt`) and how it all fits together.

---

## Quick start (fresh machine)

```sh
git clone <repo-url> ~/dotfiles
cd ~/dotfiles && bash scripts/setup.sh
```

`scripts/setup.sh` calls `scripts/claude-setup.sh`, which:
1. Seeds `~/.claude/settings.json` from `claude/settings.json` (skipped if the file already exists)
2. Installs all 9 plugins via `claude plugin install`

---

## Plugins

Installed from `claude/plugins.txt` via `claude plugin install <id>@<marketplace>`.

| Plugin | Marketplace | Purpose |
|--------|-------------|---------|
| `typescript-lsp` | `claude-plugins-official` | TypeScript language intelligence in Claude Code |
| `playwright` | `claude-plugins-official` | Browser automation / testing skill |
| `context7` | `claude-plugins-official` | Up-to-date library docs via Context7 |
| `github` | `claude-plugins-official` | GitHub MCP tools (PRs, issues, code search) |
| `commit-commands` | `claude-plugins-official` | `/commit`, `/commit-push-pr` slash commands |
| `feature-dev` | `claude-plugins-official` | Guided feature development workflow |
| `pyright-lsp` | `claude-plugins-official` | Python type checking via Pyright |
| `claude-api` | `anthropic-agent-skills` | mcp-builder skill + Anthropic SDK helpers |
| `claude-code-setup` | `claude-plugins-official` | Automation recommender for Claude Code setup |

### Anthropic Skills marketplace (`claude-api` plugin)

The `claude-api` plugin comes from a non-default marketplace. The `extraKnownMarketplaces` entry in `settings.json` is what registers it:

```json
"extraKnownMarketplaces": {
  "anthropic-agent-skills": {
    "source": {
      "source": "github",
      "repo": "anthropics/skills"
    }
  }
}
```

Without this entry, `claude plugin install claude-api@anthropic-agent-skills` will fail on a fresh machine. The `settings.json` template includes it, so seeding the file first and then running the install script is the correct order (which `scripts/claude-setup.sh` does).

The `claude-api` plugin provides:
- **mcp-builder** (`/mcp-builder`) — scaffold and build MCP servers
- **Anthropic SDK helpers** — Claude API patterns, streaming, tool use
- **Claude API development scaffolding** — project templates for API apps

---

## MCP servers (Claude Code)

Configured in `settings.json` under `mcpServers`. Two servers are included in the template:

| Server | Package | Notes |
|--------|---------|-------|
| `ruff` | `mcp-server-analyzer` (via uvx) | Python linting/formatting |
| `pytest` | `mcp-pytest-runner` (via uvx) | Run pytest from Claude Code |

### GitHub integration

GitHub access is provided by the `github@claude-plugins-official` plugin, which handles PRs, issues, and code search without requiring token management.

### Optional: snyk MCP server

Not included in the template (requires `snyk` CLI installed). To add it manually to `~/.claude/settings.json`:

```json
"snyk": {
  "command": "snyk",
  "args": ["mcp", "-t", "stdio"]
}
```

### Machine-specific settings

These settings are intentionally excluded from the template and must be set per-machine in `~/.claude/settings.json`:

- `model` — e.g. `"opus|m"` (depends on available models/subscription)
- `effortLevel` — e.g. `"high"`

### LSP plugins vs cclsp MCPs

Claude Code has a **native plugin system** for language servers:
- `pyright-lsp@claude-plugins-official` — Python type checking
- `typescript-lsp@claude-plugins-official` — TypeScript intelligence

These replace the `cclsp-python` and `cclsp-typescript` MCP servers. **Do not add cclsp MCPs to Claude Code's `settings.json`** — the native plugins are the right approach here.

The cclsp MCPs belong in **Cursor's `~/.cursor/mcp.json`** instead (see below).

### Adding a project-scoped language server

For a specific project workspace, add `mcp-language-server` to the project's `.claude/settings.json` (not the user-level one):

```json
"mcpServers": {
  "mcp-language-server": {
    "command": "npx",
    "args": [
      "-y",
      "mcp-language-server",
      "--workspace",
      "/absolute/path/to/your/project",
      "--lsp",
      "typescript-language-server",
      "--",
      "--stdio"
    ]
  }
}
```

This is intentionally **not** in the user-level template because the `--workspace` path is machine- and project-specific.

---

## Cursor MCP config (`~/.cursor/mcp.json`)

Cursor's agent mode reads MCP servers from `~/.cursor/mcp.json`. This is **separate** from Claude Code's config.

`scripts/setup.sh` seeds this file from `cursor/mcp.json` (copy-once, not a symlink — GitLens overwrites the file on updates and a symlink would cause churn).

### What's in the Cursor MCP template

| Server | Purpose |
|--------|---------|
| `github` | Same GitHub MCP as Claude Code — add token after setup |
| `context7` | Up-to-date library docs in Cursor agent mode |
| `cclsp-python` | Python LSP via cclsp (Pyright) |
| `cclsp-typescript` | TypeScript LSP via cclsp |

**Why cclsp here but not in Claude Code?** Cursor has no native plugin system. MCP is the only way to get Python/TypeScript language intelligence in Cursor's agent mode. Claude Code has native `pyright-lsp` and `typescript-lsp` plugins that do this better, so cclsp MCPs belong here, not there.

### GitKraken entry

GitLens automatically writes a `GitKraken` entry into `~/.cursor/mcp.json` when installed. It has a machine-specific binary path (`~/Library/Application Support/Cursor/User/globalStorage/eamodio.gitlens/gk`). This entry is **excluded from the dotfiles template** — GitLens will re-add it on first launch.
