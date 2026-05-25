# install.sh — Design

## Goal

Single-command setup that makes every skill in this repo available to
Claude Code under the user's `~/.claude/skills/` directory, without
copying files (so `git pull` immediately picks up edits).

## Inputs / outputs

- Input: the repo on disk. Script discovers its own location via
  `${BASH_SOURCE[0]}` + `realpath`, so the user can run it from anywhere.
- Output (side effects):
  - `~/.claude/skills/<name>` → symlink to `<repo>/skills/<name>` for
    every directory under `<repo>/skills/`.
  - `~/.claude/references` → symlink to `<repo>/references`. Needed
    because SKILL.md files reference `../../references/...`, which
    resolves to `~/.claude/references/...` once the skill folder is
    linked under `~/.claude/skills/`.
- Stdout: one line per skill (`linked`, `skipped (already linked)`,
  `WARN (conflict — left alone)`), one line for `references`, and a
  final tally.

## Behaviour

1. Resolve repo root from script location.
2. Ensure `~/.claude/skills/` exists (`mkdir -p`).
3. For each entry under `<repo>/skills/`:
   - If target does not exist → create symlink, report `linked`.
   - If target is a symlink already pointing at the correct repo path →
     report `skipped (already linked)`. Idempotent.
   - Else (real dir, file, or symlink pointing elsewhere) → leave it
     alone, report `WARN (conflict — left alone)`.
4. Same logic for `~/.claude/references` → `<repo>/references`.
5. Print final tally: `N linked, M skipped, K conflicts`.
6. Exit `0` regardless of conflict count (conflicts are warnings, not
   errors — the user may have intentionally shadowed a skill).

## Constraints

- `set -euo pipefail`.
- Shellcheck-clean.
- `LOG_LEVEL=DEBUG` enables `set -x`-style path logging (per global
  CLAUDE.md logging rule).
- No flags, no subcommands, no uninstall — the user asked for the
  minimal viable script.
- No dependency beyond bash 4+, `realpath`, `ln`, `mkdir`.

## Out of scope

- Uninstall. User can `find ~/.claude/skills -lname '*security-skills-collection*' -delete` if needed; documented in README later if requested.
- Project-level (`.claude/skills/`) install. Not requested.
- Copying instead of symlinking. Not requested.
- Conflict resolution prompts. Warn-and-skip is enough.

## Verification

- Run script twice in a row; second run reports all `skipped`, no
  conflicts, exit 0.
- Pre-create a fake `~/.claude/skills/sql-injection` directory; script
  reports `WARN` for that entry, links everything else, exits 0.
- After install, `ls -la ~/.claude/skills/sql-injection` shows a symlink
  to the repo, and `readlink ~/.claude/references` points at the repo's
  `references/`.
