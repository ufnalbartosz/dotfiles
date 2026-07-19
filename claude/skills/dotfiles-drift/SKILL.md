---
name: dotfiles-drift
description: Use when live machine config (Claude Code settings, plugins, Cursor mcp.json) may have diverged from the dotfiles repo templates — after changing settings live, when the user asks to sync/reconcile dotfiles, or periodically as a checkup.
---

# Dotfiles Drift

Reconcile live machine config with the dotfiles repo so the repo stays the source of truth. The mechanical diff is scripted; your job is deciding the sync direction and committing.

## Workflow

1. Run `python3 <this skill's directory>/check-drift.py` (test overrides: `$DOTFILES`, `$CLAUDE_DIR`, `$CURSOR_HOME`, `$SKIP_GIT_CHECK`).
2. Exit 0 → report "in sync" and stop.
3. For each drift item, pick a direction:
   - **Live-only preference** (new setting, changed value the user chose) → edit the repo template to match, commit.
   - **Template-only entry missing live** → apply it to the live file (back up first: copy to `~/.claude/backups/` or `.bak`).
   - **Permanent machine-only value** (plan-pinned model, extras-only tools, editor-injected servers) → add to `IGNORE_PATHS` / `CURSOR_IGNORE_PATHS` in check-drift.py, commit that.
4. Group related fixes into conventional commits (`feat:`/`fix:`/`chore:`). One logical change per commit. Don't push unless asked.
5. Re-run the checker; finish only when it exits 0.

## Gotchas

- **Never commit secrets.** The checker redacts `env` values in mcp.json; keep template tokens as `<your-token-here>` placeholders.
- `claude-setup.sh` seeds `~/.claude/settings.json` only when missing — updating the template does NOT update this machine; apply live edits too.
- `~/.cursor/mcp.json` is copy-once and **GitLens overwrites it**, silently dropping template servers. Restoring them live means re-adding the real token from the user (ask, don't invent).
- Cursor `settings.json`/`keybindings.json` are symlinked so live edits show up as uncommitted repo changes — the repo-clean check catches those.
- If the user disagrees with a direction, that's signal: encode the decision in the ignore lists so it never resurfaces.
