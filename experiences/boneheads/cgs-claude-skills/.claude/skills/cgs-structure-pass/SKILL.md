---
name: cgs-structure-pass
description: Review how Luau modules are organized across the project — where code lives, module shape, and how state is cleaned up.
argument-hint: "[file(s) or folder(s), optional]"
disable-model-invocation: true
---

## Branch diff (pre-computed)

- Committed on branch: !`git diff --name-only main...HEAD`
- Unstaged working tree: !`git diff --name-only`
- Staged for commit: !`git diff --name-only --staged`

Each bullet is replaced at runtime with its command's output. Union the three lists (deduped) to form the branch diff.

## Purpose

Run a **STRUCTURE review ONLY** of Luau code in this repo.

## Scope

Only flag rule violations from [`../../rules/cgs-structure-rules.md`](../../rules/cgs-structure-rules.md) — the categories in that file:
Systems vs Libraries, ManagedContent vs Content, Module internals, Constants organization, Factory-returned module shape (including the metatable ban), Stateful-registry cleanup, Remotes, Startup order, cgs-core-libraries submodule.

Do NOT flag local style: casing, naming, abbreviations, strict typing on a per-function basis, control flow / early return, assertions, default merging patterns, redundancy, whitespace, interpolation, or file-top organization. If you notice any of those, note them for the recommendation sentence at the end of the report — do not list them as findings.

## Target resolution

Arguments: `$ARGUMENTS`

1. If `$ARGUMENTS` is non-empty, treat it as a path or glob. Expand it to a list of files. Review any `.luau`, `.model.json`, `.rbxmx`, and directory-structure concerns implied by that set.
2. Otherwise, use the file list already injected above under **Branch diff** — keep `.luau`, `.model.json`, `.rbxmx` files and note added/removed directories.
3. If the review set is empty:
   - If `$ARGUMENTS` was non-empty, emit `## /cgs-structure-pass findings` followed by `No findings.` and stop.
   - Otherwise (no arguments, empty branch diff), emit `## /cgs-structure-pass findings` followed by `No files changed on this branch against \`main\` — nothing to review. Pass a file or glob as an argument to scope the review manually.` and stop.

## Diff scoping

When the review set comes from the **Branch diff** (no `$ARGUMENTS`), the review is **diff-scoped**: only flag violations on lines that fall within a changed hunk. For each file, run `git diff main...HEAD -- <file>` (plus `git diff -- <file>` and `git diff --staged -- <file>` when unstaged/staged changes exist) to see the actual line ranges that changed. Lines outside those hunks are out of scope — even if they violate a rule, they are pre-existing issues the author did not introduce in this patch. Do not report them.

Exception: directory-shape and file-placement findings (e.g. "this module belongs under Systems/ not Libraries/", "Remotes/ folder missing") apply to newly added files or directories in the diff regardless of individual line ranges — the act of adding the file in the wrong place is itself the violation.

When `$ARGUMENTS` is provided, review the entire file — the user explicitly asked for a full review of those paths.

## Procedure

For each file and directory change in the review set:

1. Read the file in full with the Read tool (for text files).
2. If diff-scoped (no `$ARGUMENTS`), also retrieve the patch hunks for this file and note which line ranges in the new version were added or modified.
3. For directory-shape concerns (Systems vs Libraries placement, module internals, `Remotes/` location, `ManagedContent/` vs `Content/` placement), inspect the enclosing directory with `ls` or `Glob`.
4. For each rule in [`../../rules/cgs-structure-rules.md`](../../rules/cgs-structure-rules.md), check for violations.
5. If diff-scoped, discard any line-level finding whose line number does not fall within a changed hunk. Only lines the author touched or added are reviewable. (Directory-shape findings on newly added files are still in scope.)
6. Categorize each finding by tier from the rulebook (Issues for must-fix, Suggestions for cleanup).
7. Note the file's basename or the directory name, and a line number where relevant.

Pay specific attention to:

- `setmetatable` / `__index` / class-style OOP anywhere — metatables are banned.
- Modules with methods taking a `self` parameter — flag as factory shape violations.
- Stateful registries (module-level `{ [Player]: ... }` or `{ [Instance]: ... }` tables) without a `remove*` / `clear*` export.
- **Enumerate every `.model.json` under any `Remotes/` folder.** Open each file and read `"className"`. If it says `"RemoteEvent"`, trace the caller code (both server and client `.luau` files in the review set) to see if a return value is implied. Signals: (a) a `RequestXxx`/`ReplyXxx` pair implementing a request/response flow — one `RemoteFunction` would replace both; (b) the client-side handler sets a variable from the event payload and uses it as if it were the result of a call; (c) the server fires the response event only in reaction to a specific client event. Any of those → flag under `Use RemoteFunction when the caller needs a return value; RemoteEvent for fire-and-forget`. If a `.model.json` says `"RemoteFunction"` but neither side ever invokes/yields on it, flag the reverse.
- **Literal placement**: scan every `.luau` file for string/number literals that look configurable or public (tag names, attribute name prefixes, thresholds a designer would tune, default sizes, hardcoded paths). Any such literal that isn't in `Constants.luau` → flag under `Classify literals by audience: configurable or public → Constants.luau; implementation-internal → local at the top of the file`. Implementation-internal literals (sort thresholds, string separators used only by this file, loop caps) are fine as file-top locals and should NOT be promoted.
- Remotes living outside their owning module's `Remotes/` folder.
- Modules split across server + client without the `*Server.luau` / `*Client.luau` suffix.
- Multi-method modules living inside a `Utility/` folder — a file under `Utility/` that returns a table with more than one function, or holds module-level state, has outgrown the utility shape and belongs in `Libraries/`. Cite under the must-fix rule `Utility/ holds single-function helpers — multi-method modules belong in Libraries/`.
- **Do NOT promote a single-function helper to `Libraries/` just because it's imported from multiple modules.** A single-function helper is a Utility, regardless of reach. Only a collection of related functions becomes a Library.

## Output format

See [`../../rules/cgs-report-format-rules.md`](../../rules/cgs-report-format-rules.md) for the File:Line, Snippet, tier-grouping, and deduplication conventions that apply to every row.

Emit exactly this skeleton — no preamble, no trailing summary prose:

````
## /cgs-structure-pass findings

### Issues

| File:Line | Rule — Reason | Snippet |
|-----------|---------------|---------|
| **file.luau:NN** | <rule name> — <concise reason> | `<snippet or directory note>` |

### Suggestions

| File:Line | Rule — Reason | Snippet |
|-----------|---------------|---------|
| **file.luau:NN** | <rule name> — <concise reason> | `<snippet or directory note>` |
````

If both tiers are empty, emit `## /cgs-structure-pass findings` followed by `No findings.` and stop.

## After emitting the report

1. If you noticed local style issues during the review, append one plain sentence after the Suggestions section (no header, no bullet):

   > I also noticed some style issues in the diff — running `/cgs-style-pass` will give you those.

   Skip this sentence if you did not notice anything stylistic.

2. If the report contains at least one finding (either tier is non-empty), call `AskUserQuestion` with:

   - Question: `Want me to fix these?`
   - Header: `Apply fixes`
   - Options:
     - `Yes, fix everything` — `I'll edit the files to resolve every Issue and Suggestion.`
     - `Only fix Issues` — `I'll apply only the blocking items and leave Suggestions for you.`
     - `No, I'll handle it` — `Leave the report as-is.`

   Based on the user's choice, apply the fixes by editing each cited file directly. Skip the prompt entirely if the report emitted `No findings.`.
