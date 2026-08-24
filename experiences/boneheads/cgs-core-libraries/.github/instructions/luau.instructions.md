---
name: "Luau Coding"
description: "Coding standards and instructions for working with Luau"
applyTo: "**/*.luau"
---

# Luau Coding

## Flow

- Use guard statements and continues to reduce nesting

## Naming and Typing Conventions

- Unless otherwise specified, follow the Roblox Luau style guide
- Use PascalCase for types and library requires.
- Use camelCase for variables and functions, including requires for utility functions.
- Tags on instances use PascalCase.
- Attributes on instances use camelCase.
- Variables generally only need an explicit type when the type cannot be inferred
- Function parameters and returns should always be explicitly typed, unless the function explicitly does not return anything.

## Validation

- After making edits, `run luau-lsp analyze --flag:LuauSolverV2=true --defs=globalTypes.d.luau --sourcemap=sourcemap.json src` to check for errors.

### Static Analysis with luau-lsp

The project uses `luau-lsp` (installed via Rokit) for Static Analysis. The `analyze` subcommand requires a `globalTypes.d.luau` Definitions file containing Roblox type definitions. Without this file, analysis produces approximately 110 false errors for Roblox builtins. With it, the codebase shall pass with zero errors.

The `--platform=roblox` flag alone is NOT sufficient for `analyze` mode — the Definitions file is required.

#### Step 1: Retrieve globalTypes.d.luau

- Download the Roblox Global Type Definitions file before running analysis.
- Retrieve via curl to the project root directory:
  ```sh
  curl -sO https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau
  ```
- This file is a temporary artifact and shall NOT be committed to the repository.

#### Step 2: Generate Sourcemap and Run Analysis

- Regenerate the Rojo Sourcemap to ensure it reflects the current project structure:
  ```sh
  rojo sourcemap default.project.json --output sourcemap.json
  ```
- Run Static Analysis:
  ```sh
  luau-lsp analyze --flag:LuauSolverV2=true --sourcemap=sourcemap.json --base-luaurc=.luaurc --definitions=globalTypes.d.luau src/
  ```
- The `.luaurc` already exists in the project root and enforces Strict Mode.
- The `sourcemap.json` already exists in the repo root but shall be regenerated before each analysis run.

#### Step 3: Clean Up

- Remove the Definitions file after analysis completes:
  ```sh
  rm globalTypes.d.luau
  ```
- This file shall never persist in the repository.

### Notes

- The existing `scripts/lint.sh` runs `selene` only — it does not invoke `luau-lsp`.
- Always run both `selene` (via `scripts/lint.sh`) and `luau-lsp analyze` (via the workflow above) to ensure full Validation coverage.
