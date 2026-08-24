---
name: cgs-style-pass
description: Review how Luau code is written inside each file — naming, types, control flow, and other in-file readability concerns.
argument-hint: "[file(s) or folder(s), optional]"
disable-model-invocation: true
---

## Branch diff (pre-computed)

- Committed on branch: !`git diff --name-only main...HEAD`
- Unstaged working tree: !`git diff --name-only`
- Staged for commit: !`git diff --name-only --staged`

Each bullet is replaced at runtime with its command's output. Union the three lists (deduped) to form the branch diff.

## Purpose

Run a **STYLE review ONLY** of Luau code in this repo.

## Scope

Only flag rule violations from [`../../rules/cgs-style-rules.md`](../../rules/cgs-style-rules.md) — the nine categories in that file:
Casing, Naming, Strict typing, Control flow, Assertions, Default merging, Redundancy, Whitespace, File-top organization.

Do NOT flag structural issues: module layout, Systems vs Libraries, ManagedContent vs Content placement, factory-returned module shape, metatables, stateful-registry cleanup, Remote choice, Constants organization across files, startup order, cgs-core-libraries access paths. If you notice any of those, note them for the recommendation sentence at the end of the report — do not list them as findings.

## Target resolution

Arguments: `$ARGUMENTS`

1. If `$ARGUMENTS` is non-empty, treat it as a path or glob. Expand it to a list of `.luau` files. Review only those files.
2. Otherwise, use the file list already injected above under **Branch diff** — keep only `.luau` files (including `Constants.luau` and `Types.luau`).
3. If the review set is empty:
   - If `$ARGUMENTS` was non-empty, emit `## /cgs-style-pass findings` followed by `No findings.` and stop.
   - Otherwise (no arguments, empty branch diff), emit `## /cgs-style-pass findings` followed by `No files changed on this branch against \`main\` — nothing to review. Pass a file or glob as an argument to scope the review manually.` and stop.

## Diff scoping

When the review set comes from the **Branch diff** (no `$ARGUMENTS`), the review is **diff-scoped**: only flag violations on lines that fall within a changed hunk. For each file, run `git diff main...HEAD -- <file>` (plus `git diff -- <file>` and `git diff --staged -- <file>` when unstaged/staged changes exist) to see the actual line ranges that changed. Lines outside those hunks are out of scope — even if they violate a rule, they are pre-existing issues the author did not introduce in this patch. Do not report them.

When `$ARGUMENTS` is provided, review the entire file — the user explicitly asked for a full review of those paths.

## Procedure

For each file in the review set:

1. Read the file in full with the Read tool.
2. If diff-scoped (no `$ARGUMENTS`), also retrieve the patch hunks for this file and note which line ranges in the new version were added or modified.
3. For each rule in [`../../rules/cgs-style-rules.md`](../../rules/cgs-style-rules.md), check the file for violations.
4. If diff-scoped, discard any finding whose line number does not fall within a changed hunk. Only lines the author touched or added are reviewable.
5. Ignore anything that already complies. Do not restate correct code.
6. Categorize each finding by tier from the rulebook (Issues for must-fix, Suggestions for cleanup).
7. Note the file's basename and line number.

Pay specific attention to:

- **Module-level state position**: for modules returning a methods-table, every module-level `local` (registry, counter, cached reference) should appear above the first method definition — not interleaved between methods. Scan each file for `local` declarations that appear after the first `function ModuleName.method` and flag under `Module-level state variables declared above the methods that read them`.
- **Getter prefix on library methods**: methods on a module table that return a value without side effects should begin with `get` (`get<Thing>`, `get<Thing>ChangedSignal`). Scan each `function ModuleName.method(...)` that returns a value and flag bare-noun names (`newName` should be `getNewName`; `position` should be `getPosition`). Apply the side-effect-free check — if the method mutates, it's an action, not a getter.
- **Predicates with side effects**: functions named `is*` / `has*` / `should*` / `ensure*` / `check*` that modify state while returning a boolean. Flag under `Predicates must be side-effect-free` — rename to an action (`try*`, `acquire*`).
- **Comment density**: scan for comments that restate the code, narrate the current task, or serve as section headers without explaining non-obvious intent. Flag under `Comments should be sparse`.

## Output format

See [`../../rules/cgs-report-format-rules.md`](../../rules/cgs-report-format-rules.md) for the File:Line, Snippet, tier-grouping, and deduplication conventions that apply to every row.

Emit exactly this skeleton — no preamble, no trailing summary prose:

````
## /cgs-style-pass findings

### Issues

| File:Line | Rule — Reason | Snippet |
|-----------|---------------|---------|
| **file.luau:NN** | <rule name> — <concise reason> | `<snippet>` |

### Suggestions

| File:Line | Rule — Reason | Snippet |
|-----------|---------------|---------|
| **file.luau:NN** | <rule name> — <concise reason> | `<snippet>` |
````

If both tiers are empty, emit `## /cgs-style-pass findings` followed by `No findings.` and stop.

## After emitting the report

1. If you noticed structural issues during the review, append one plain sentence after the Suggestions section (no header, no bullet):

   > I also noticed some structural issues in the diff — running `/cgs-structure-pass` will give you those.

   Skip this sentence if you did not notice anything structural.

2. If the report contains at least one finding (either tier is non-empty), call `AskUserQuestion` with:

   - Question: `Want me to fix these?`
   - Header: `Apply fixes`
   - Options:
     - `Yes, fix everything` — `I'll edit the files to resolve every Issue and Suggestion.`
     - `Only fix Issues` — `I'll apply only the blocking items and leave Suggestions for you.`
     - `No, I'll handle it` — `Leave the report as-is.`

   Based on the user's choice, apply the fixes by editing each cited file directly. Skip the prompt entirely if the report emitted `No findings.`.
