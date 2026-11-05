# Project Structure

The working project structure for the Creator Game Solutions team and co-development partners.

## Required Reading

- [Setting up Rojo Projects](https://github.com/edeppe/edeppe/blob/main/docs/setting-up-rojo-projects.md)
- [Luau Programming Style Guide](https://github.com/edeppe/edeppe/blob/main/docs/luau-programming-style-guide.md)

## Tooling

Installed via [rokit](https://github.com/rojo-rbx/rokit), checked in as `rokit.toml`:

- **Rojo** — syncs source files into Roblox's runtime instance tree (the "data model").
- **Selene** — linter. `selene.toml` sets `std = "roblox"`.
- **StyLua** — formatter. Configured via `stylua.toml`.
- **luau-lsp** — language server.
- **Wally** — Luau package manager.

### Recommended VS Code settings

```json
"editor.formatOnSave": true,
"luau-lsp.completion.imports.suggestRequires": true,
"workbench.editor.customLabels.patterns": {
  "**/init.*": "${dirname} (init.${extname})"
}
```

*Note: The new Luau type solver is in preview. Enable it in VS Code so everyone sees the same type-checking behavior. The exact setting key varies by luau-lsp version — check your installed schema (usually `luau-lsp.types.useNewSolver` or `luau-lsp.solver.new`).*

## Project Layout

Roblox at runtime is a tree of live instances — the "data model". Rojo syncs files on disk into that tree based on the mapping in `default.project.json` — see "Setting up Rojo Projects" in Required Reading.

### Repository root

```
project-name/
├── default.project.json       # Rojo project setup
├── .luaurc
├── selene.toml
├── stylua.toml
├── rokit.toml
├── wally.toml
├── cgs-core-libraries/        # git submodule
└── src/
```

### Source code

```
src/
├── ReplicatedStorage/         # Shared — replicated to clients
│   ├── Client/                # Client-only code, nested inside ReplicatedStorage
│   ├── Systems/
│   ├── Libraries/
│   ├── ManagedContent/
│   └── Content/               # optional
└── ServerScriptService/       # Server — not replicated
    ├── Systems/
    ├── Libraries/
    ├── ManagedContent/
    └── Content/               # optional
```

Three runtime contexts:

- **Client** — `src/ReplicatedStorage/Client/`. Nested under `ReplicatedStorage`, not a sibling. Runs on clients only.
- **Shared** — anything else under `ReplicatedStorage/`. Runnable on server and client.
- **Server** — `src/ServerScriptService/`. Not replicated. Sensitive code (anti-cheat, economy, player data) lives here.

#### A note on folder names

Rojo's default convention is `client/`, `shared/`, and `server/` — that's what you'll see in most Rojo-based projects, including `cgs-core-libraries`. Game projects on our team use `ReplicatedStorage/` and `ServerScriptService/` (with `Client/` nested under `ReplicatedStorage/`) to make it unambiguous where each folder lands in the data model. Functionally it makes no difference — pick the long names for new game projects, and don't rename the short ones in `cgs-core-libraries`.

## Code organization: Systems and Libraries

Code lives in one of two shapes. A **System** provides a service, holds startup state, and exposes a `start()` function called during project startup (see below). A **Library** is a collection of utility functions with no startup lifecycle — require it and call it. Both follow the same internal layout:

```
MyThing/
├── init.luau           # entry point
├── Constants.luau      # user-configurable values
├── Types.luau          # public types
├── Utility/            # optional — helpers local to this module
├── Validation/         # optional, server-only
└── Remotes/            # systems only, optional
```

### Remotes

Each system owns its `Remotes/` subfolder with the RemoteEvents / RemoteFunctions it uses. Example: `src/ReplicatedStorage/Systems/Inventory/Remotes/`.

### Definitions vs implementations

Some systems operate over an open-ended catalog of entries that the game wants to keep extending — new quests, new factions, new behaviors. For those, don't hard-code entries into the system. Put them under `ManagedContent/` instead and let the system discover them at startup via `autoLoad(<DefinitionsFolder>)`.

The convention is two sibling folders per catalog, one holding configuration, one holding code:

```
ManagedContent/
├── SomethingDefinitions/     # data: name, metadata, parameters
└── Somethings/               # code: the module that implements each entry
```

This is optional — plenty of systems have no catalog and need neither folder. Apply the pattern when you expect the set of entries to keep growing independently of the system that consumes them.

## Using cgs-core-libraries

`cgs-core-libraries` is our standard working collection of systems and libraries (character controllers, inventory, quests, behaviors, signals, etc.). It is included in every project as a git submodule at the repo root and mapped into a folder named `Core` inside both `ReplicatedStorage` and `ServerScriptService`.

Example access:

```lua
local Signal = require(ReplicatedStorage.Core.Libraries.Signal)
local QuestServer = require(ServerScriptService.Core.Systems.QuestServer)
```

> Local edits inside `cgs-core-libraries/` are fine for debugging, but don't commit them from a consuming project. Changes meant to stick go as an upstream PR against the submodule's own repo.

## Authored content: Content vs ManagedContent

`Content/` and `ManagedContent/` are both plain Roblox `Folder` instances under each runtime environment (typically `ReplicatedStorage` and `ServerScriptService`). Both hold authored data — models, configuration files, VFX, audio, UI. They differ in where the data comes from:

- **ManagedContent** mirrors files on disk under `src/.../ManagedContent/`. Rojo owns it.
- **Content** has no files on disk; it lives only in the `.rbxl` place file. Studio owns it.

### ManagedContent — source of truth is git

Rojo rebuilds this folder from disk on every `rojo serve`, so **Studio edits inside ManagedContent are overwritten** on the next sync.

- Files on disk are `.luau` scripts, `.model.json` descriptors, or `.rbxmx` instances.
- Prefer `.rbxmx` over `.rbxm`. Roblox exports `.rbxm` by default; `.rbxmx` is XML — intellisense and readable diffs.
- Edit on disk, then run `rojo serve` to push into Studio.

### Content — source of truth is Studio

Instances are authored and stored directly in the `.rbxl` place file, and Rojo is told to leave its contents alone.

- **No intellisense.** The objects aren't on disk, so luau-lsp can't see them.
- **Required for meshparts.** Rojo cannot sync `MeshPart` instances, so mesh-based art has to live here.

#### How to choose

Driven by intent:

- Needs Studio editing by artists (environment props, lighting, staging, terrain) → **Content**.
- Consumed programmatically as configuration (item definitions, quest data, faction configs) → **ManagedContent**.

#### Exporting from Studio to ManagedContent

When an engineering-owned asset is authored in Studio:

1. Right-click in Studio → **Save to File**.
2. Choose `.rbxmx` (not `.rbxm`).
3. Place the file under the relevant `ManagedContent/…` subtree on disk.
4. Commit.

## Project Startup

One entry-point script per runtime environment:

- `src/ServerScriptService/Server.server.luau`
- `src/ReplicatedStorage/Client/Client.client.luau`

Order:

1. `autoLoad()` — systems that consume definitions (e.g. quests, factions) load them from their `ManagedContent` folder.
2. `start()` — each system starts in a defined order. Connect events before async work so late-arriving events aren't dropped.
3. Project-specific init.

Example `src/ServerScriptService/Server.server.luau`:

```lua
local function initialize()
    Factions.autoLoad(FactionDefinitions)
    QuestServer.autoLoad(ServerScriptService.ManagedContent.QuestDefinitions)
    Action.autoLoad(ReplicatedStorage.ManagedContent.ActionDefinitions)

    InventoryServerCore.start(Items)
    Action.start()
    -- ...
end

initialize()
```

## User interface (WIP)

UI will be built with **Roblox React** — a Luau port of React — installed via Wally (see the `wally.toml` at the repo root).