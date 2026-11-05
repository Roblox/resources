---
name: cgs-review
description: Run a pre-PR review over your changes, covering both how the code is written and how the modules are organized.
argument-hint: "[file(s) or folder(s), optional]"
disable-model-invocation: true
---

## Branch diff (pre-computed)

- Committed on branch: !`git diff --name-only main...HEAD`
- Unstaged working tree: !`git diff --name-only`
- Staged for commit: !`git diff --name-only --staged`

Each bullet is replaced at runtime with its command's output. Union the three lists (deduped) to form the review set when `$ARGUMENTS` is empty.

## Purpose

Run a **composite CGS review** — both a style pass and a structure pass — and produce one unified report.

## Procedure

Run the two passes sequentially against the same target set (from `$ARGUMENTS` if provided, otherwise the **Branch diff** list above).

### 1. Style pass

Apply the procedure and rules from [`cgs-style-pass`](../cgs-style-pass/SKILL.md) using [`../../rules/cgs-style-rules.md`](../../rules/cgs-style-rules.md). Capture the findings (Issues + Suggestions) but do NOT emit the `## /cgs-style-pass findings` header, do NOT emit a recommendation sentence, and do NOT call `AskUserQuestion` from this pass — the composite handles the section header and the prompt at the end.

### 2. Structure pass

Apply the procedure and rules from [`cgs-structure-pass`](../cgs-structure-pass/SKILL.md) using [`../../rules/cgs-structure-rules.md`](../../rules/cgs-structure-rules.md). Capture the findings but do NOT emit the `## /cgs-structure-pass findings` header, do NOT emit a recommendation sentence, and do NOT call `AskUserQuestion` from this pass.

## Output format

See [`../../rules/cgs-report-format-rules.md`](../../rules/cgs-report-format-rules.md) for the File:Line, Snippet, tier-grouping, and deduplication conventions that apply to every row.

### Empty-set fallback

If `$ARGUMENTS` was empty AND the **Branch diff** list is empty, do NOT emit the two section skeletons. Emit exactly:

```
# /cgs-review

No files changed on this branch against `main` — nothing to review. Pass a file or glob as an argument to scope the review manually.
```

…and stop. Skip the `AskUserQuestion` prompt in this case.

### Normal output

Otherwise, emit exactly this structure — no preamble, no trailing summary prose:

````
# /cgs-review

---

# Style

### Issues

| File:Line | Rule — Reason | Snippet |
|-----------|---------------|---------|
| **file.luau:NN** | <rule name> — <concise reason> | `<snippet>` |

### Suggestions

| File:Line | Rule — Reason | Snippet |
|-----------|---------------|---------|
| **file.luau:NN** | <rule name> — <concise reason> | `<snippet>` |

---

# Structure

### Issues

| File:Line | Rule — Reason | Snippet |
|-----------|---------------|---------|
| **file.luau:NN** | <rule name> — <concise reason> | `<snippet or directory note>` |

### Suggestions

| File:Line | Rule — Reason | Snippet |
|-----------|---------------|---------|
| **file.luau:NN** | <rule name> — <concise reason> | `<snippet or directory note>` |
````

Section-level rules:

- Two top-level H1 sections: `# Style` then `# Structure`, in that order, each preceded by a `---` horizontal rule. The leading `---` before `# Style` separates the sections from the `# /cgs-review` banner. These section headers are always present.
- Within a section, tier-header omission follows the shared report-format rules.
- If both tiers in a section are empty, emit a single `No findings.` line under that H1 section header.
- No recommendation sentences anywhere — both passes have already run.
- Nothing outside the skeleton: no summary, no "here are the findings", no rule counts.

## After emitting the report

If at least one finding exists across both sections (any tier is non-empty), call `AskUserQuestion` once with:

- Question: `Want me to fix these?`
- Header: `Apply fixes`
- Options:
  - `Yes, fix everything` — `I'll edit the files to resolve every Issue and Suggestion across both sections.`
  - `Only fix Issues` — `I'll apply only the blocking items from both sections and leave Suggestions for you.`
  - `No, I'll handle it` — `Leave the report as-is.`

Based on the user's choice, apply the fixes by editing each cited file directly. Skip the prompt entirely if both sections emitted `No findings.`.
