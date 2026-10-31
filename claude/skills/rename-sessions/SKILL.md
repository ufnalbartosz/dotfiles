---
name: rename-sessions
description: Use when working inside a cmux workspace whose title is generic ("~"), a sentence, or no longer matches what this session is mainly doing, and when asked to rename or name a session. Renames only the current session's workspace.
---

# Rename Session

Part of cmux session management, with `linking-sessions` (messaging other sessions, which needs a meaningful name from this skill first).

Invoked as `/rename-sessions`, optionally with a name (`/rename-sessions dotfiles-memory-audit`). A given name is used as-is after converting it to the format below; without one, pick it from the Decide steps.

The cmux workspace title is how the user finds this session later, and how other sessions address it. It should name the topic, not describe the work.

## Format

2-3 lowercase words, hyphen-separated, topic nouns first: `cmux-session-linking`, `dotfiles-memory-audit`, `invoice-export-bug`. No dates, no filler verbs, no sentences.

## Decide

1. Read the current title: `cmux workspace list --id-format both | grep "$CMUX_WORKSPACE_ID"`.
2. Keep it if it is already 2-3 kebab-case words and still names what most of this session's work is about.
3. Rename if the title is generic, a sentence, or the main goal of the session has changed since it was set. A side task or a single subtask is not a change.
4. The new name must differ from every other workspace title in `cmux workspace list`; add one distinguishing word if it collides.

## Rename

```bash
cmux workspace rename --workspace "$CMUX_WORKSPACE_ID" --title "dotfiles-memory-audit"
```

Rename only the workspace you are running in. To get another session renamed, ask it to apply rename-sessions.

## Claude's own session name

The built-in `/rename` sets the name `/resume` shows, and only the user can run it. After renaming the workspace, end your message with the line for them to paste, using the same name: `/rename dotfiles-memory-audit`. Skip the line when you kept the existing title.
