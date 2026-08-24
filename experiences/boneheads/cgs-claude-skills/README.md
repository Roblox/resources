# cgs-claude-skills

Shared Claude Code skills and rulebooks for Creator Game Solution codebases.

> **These skills are not a replacement for human review.** They're meant for a pre-PR / draft pass — run them on your own branch before you open or re-open a PR, catch the easy stuff, and hand a cleaner diff to your human reviewer.

## Skills

Skills share the same targeting rules:

- No argument → review set is the current branch's diff against `main`.
- With argument → treat it as a list of file paths, folder paths, or globs and review only the matching files.

### `/cgs-review [file(s) or folder(s)]`

Runs a pre-PR review over your changes, covering both how the code is written and how the modules are organized. Combines the style pass and the structure pass into one report.

### `/cgs-style-pass [file(s) or folder(s)]`

Reviews how Luau code is written inside each file — naming, types, control flow, and other in-file readability concerns.

### `/cgs-structure-pass [file(s) or folder(s)]`

Reviews how Luau modules are organized across the project — where code lives, module shape, and how state is cleaned up.

## Installing as a submodule

### Setup in new projects

From your consuming project's root, add the submodule and create symlinks into `.claude/` so Claude Code can discover the skills:

```bash
# Download submodule
git submodule add https://github.com/Roblox/cgs-claude-skills.git cgs-claude-skills
git submodule update --init

# Create .claude folder and build symlinks
mkdir -p .claude/skills .claude/rules && for d in cgs-claude-skills/.claude/skills/*/; do ln -sfn "../../$d" ".claude/skills/$(basename "$d")"; done && for f in cgs-claude-skills/.claude/rules/*.md; do ln -sfn "../../$f" ".claude/rules/$(basename "$f")"; done
```

> Tip: Commit the symlinks so your teammates don't have to rerun the loops after cloning. They're just tiny pointers (~40 bytes each) to the submodule — not copies of the SKILL.md files, so no bloat.


### Updating

To pull the latest skills and rules, bump the submodule and re-run the symlink loops — this picks up any new skills or rulebooks added upstream:

```bash
# Pull submodule
git submodule update --remote cgs-claude-skills

# Update symblinks
for d in cgs-claude-skills/.claude/skills/*/; do ln -sfn "../../$d" ".claude/skills/$(basename "$d")"; done && for f in cgs-claude-skills/.claude/rules/*.md; do ln -sfn "../../$f" ".claude/rules/$(basename "$f")"; done
```

If a skill or rule was *removed* upstream, the old symlink is left dangling. Clean up with:

```bash
find .claude/skills .claude/rules -type l ! -exec test -e {} \; -delete
```
