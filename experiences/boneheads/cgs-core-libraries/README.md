# CGS Core Libraries

## Licensing

All `.luau` files should have the appropriate license header comment:

```lua
-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT
```

Snippets are provided in this repo to easily insert either the individual header or common starting scripts with the header included.

## Usage

### Setup in new projects

1. Run `git submodule add https://github.com/Roblox/cgs-core-libraries`
2. Add server and shared project paths to `default.project.json`

```json
"ReplicatedStorage": {
    "$path": "src/shared",
    "Core": {
        "$path": "cgs-core-libraries/shared.project.json"
    }
},
"ServerScriptService": {
    "$path": "src/server",
    "Core": {
        "$path": "cgs-core-libraries/server.project.json"
    }
},
```

### Use in current projects

1. Run `git submodule init` to setup
2. Run `git submodule update` to clone the submodule
