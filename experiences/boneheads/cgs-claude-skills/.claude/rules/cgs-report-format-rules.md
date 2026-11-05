# CGS report format

Shared report-formatting conventions for `/cgs-style-pass`, `/cgs-structure-pass`, and `/cgs-review`. This file owns the vocabulary that applies to every finding row so the three skills can stay in sync without drift.

Each skill defines its own skeleton (section headers, empty-set fallback message) and then defers to this file for the per-row rules.

## Contents

- Tier → header mapping
- File:Line cell format
- Snippet cell format
- Row-level conventions
- Empty sections
- Deduplication

## Tier → header mapping

Group findings by tier from the rulebook:

- **must-fix** rules → `### Issues`
- **cleanup** rules → `### Suggestions`

Within a tier, order rows by file (and by line number within a file).

## File:Line cell format

Wrap the file:line reference in **bold** (not backticks). Backticks render as inline code, which in most Claude Code themes is a light purple that's low-contrast. Bold renders in the normal foreground color, which reads more clearly against the table.

- Regular files: **`file.luau:NN`** → cite the basename, e.g. **`Constants.luau:16`**.
- `init.luau` files: cite the parent folder name plus an `(init)` marker, e.g. **`MiniMap(init):464`**, not `init.luau:464`. The parent name is what humans remember; `(init)` disambiguates from a same-named module file.
- Directory-shape findings (structure pass only): cite the directory's short path in bold, e.g. **`Libraries/Bounty/Remotes/`**.
- If two files in the review share a basename, prepend the parent directory: **`Bounty/init.luau:NN`** — or for two init files in different modules, the `(init)` form already disambiguates.

## Snippet cell format

Each finding is one table row. The `Snippet` cell is **inline code only** — no fenced code blocks, no multi-paragraph text.

- Single-line violation: wrap the offending line in backticks, e.g. `` `local dist = math.sqrt(...)` ``.
- Multi-line violation: join each line with `<br>` and wrap each in its own backticks, e.g. `` `local w = config.size.X`<br>`local h = config.size.Y` ``.
- Truncate any line that exceeds ~80 chars with a trailing `…` inside the backticks.
- Structure findings about placement/directory shape: use a short plain-text note wrapped in backticks instead, e.g. `` `Libraries/Bounty/Remotes/ missing` `` or `` `multi-method module under Utility/` ``.

## Row-level conventions

- Use the exact rule name from the rulebook (e.g. `No abbreviations in identifiers`, `Metatables are BANNED`).
- After the rule name, append ` — ` and a short concrete reason for *this specific* finding — not a restatement of the rule. Aim for 5–15 words. Examples:
  - `Assertions — needs to assert the nilable PrimaryPart before dereferencing`
  - `Constants use SCREAMING_SNAKE_CASE — teamsSpawns is a fixed read-only mapping, rename to TEAM_SPAWNS`
  - `Utility/ holds single-function helpers — multi-method modules belong in Libraries/ — three public methods plus module-level state`
- Include the offending snippet (or directory note) in the `Snippet` cell so the author can locate it at a glance.

## Empty sections

- Omit the `### Issues` or `### Suggestions` header (and its table) entirely when that tier has no findings — do not emit `_none_` or an empty table.
- If a pass has zero findings across both tiers, emit a single `No findings.` line under its section header instead of the two tier headers.

## Deduplication

Do not duplicate a finding that applies to multiple lines or call sites in the same file — cite one and note "(and N others)" in the Reason cell when the violation is the **same idiom** (e.g. three `or Constants.DEFAULT_X` re-defaultings, five `w = config.size.X` abbreviations, three call sites all taking `self`).

Keep findings separate when lines use **different idioms** of the same rule (e.g. `dist` on one line, `p1`/`p2` on another — different abbreviation targets).
