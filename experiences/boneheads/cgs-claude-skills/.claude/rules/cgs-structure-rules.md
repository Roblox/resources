# CGS structure rules

Project-structure rules for this repo. Sourced from `docs/PROJECT_STRUCTURE.md` and recurring human reviewer feedback.

This file is consumed by `/cgs-structure-pass` and `/cgs-review`. It covers **how code is organized across modules and files** — where things live, what shape modules take, how state is cleaned up, which Remote type to pick, and in what order things boot. Local code quality (casing, naming, typing, control flow, assertions) is a style concern — see `cgs-style-rules.md`. Report-row formatting (File:Line / Snippet / tier headers) lives in `cgs-report-format-rules.md`.

Each rule has a tier:

- **must-fix** — clear rule violation; block the review until fixed.
- **cleanup** — small polish the author should handle before asking for a human review.

## Contents

- Systems vs Libraries
- ManagedContent vs Content
- Module internals
- Constants organization
- Factory-returned module shape
- Stateful-registry cleanup
- Remotes
- Startup order
- cgs-core-libraries submodule
- Cross-concern

---

## Systems vs Libraries

- **A module is either a System or a Library — pick one and commit to its shape**
  - Tier: must-fix
  - Why:
    - **System** — has a startup lifecycle, exposes `start()`, holds startup state, may own services and Remotes. Lives under `Systems/`.
    - **Library** — utility surface with no startup lifecycle. May hold a module-level registry if it exports `remove*` / `clear*` cleanup (see Stateful-registry cleanup) and may own Remotes. Lives under `Libraries/`.
  - ❌
    ```
    src/shared/Libraries/Inventory/
      init.luau      -- calls Players.PlayerAdded:Connect at require time,
                     -- holds per-player state in a module-level table
    ```
  - ✅
    ```
    src/shared/Systems/Inventory/
      init.luau      -- exposes start(), owns its state and its Remotes/ folder
    ```

- **System `init.luau` exposes `start()` (and `autoLoad()` if it consumes definitions); library `init.luau` returns a plain table of functions**
  - Tier: must-fix
  - ✅ (system)
    ```luau
    local InventoryServer = {}

    function InventoryServer.start(items)
        -- connect Remotes, start background work
    end

    return InventoryServer
    ```
  - ✅ (library)
    ```luau
    local function getTagsKey(tags: { string }): string
        return table.concat(tags, "|")
    end

    return getTagsKey
    ```

- **A Utility is a single module with one function; a Library is a collection of related functions. Reuse across modules does NOT promote a single-function helper into a Library.**
  - Tier: must-fix
  - Why: The division is by shape, not reach. A *Utility* is a single module that returns a single function (e.g., `src/shared/Utility/getTaggedList.luau`). A *Library* is a module that returns a table with multiple related methods (e.g., `src/shared/Libraries/PlayerFlags/`). Widening a single-function helper into `Libraries/` just because many modules import it creates a lopsided library with one entry — worse ergonomics and wrong shape. The right reason to promote to a Library is that related single-function helpers have accumulated and should be grouped together.
  - ✅ single-function helper reused across modules — kept as a Utility
    ```
    src/shared/Utility/getTaggedList.luau    -- returns one function, imported from many places
    src/shared/Utility/getTagsKey.luau       -- returns one function
    ```
  - ✅ multi-method collection — a Library
    ```
    src/shared/Libraries/PlayerFlags/
      init.luau        -- returns { setFlag, clearFlag, hasFlag, getFlag, ... }
      Constants.luau
    ```
  - ❌ single-function helper inflated into a Library just because it's reused
    ```
    src/shared/Libraries/GetTaggedList/init.luau   -- only exports one function — this is a Utility, move it out
    ```

## ManagedContent vs Content

- **Programmatic, typed configuration belongs in `ManagedContent/`**
  - Tier: must-fix
  - Why: `ManagedContent/` is Rojo-synced; files on disk are the source of truth. Intellisense works, diffs are readable.
  - Examples: item definitions, quest definitions, faction configs, state-graph definitions.

- **Artist-authored assets belong in `Content/`**
  - Tier: must-fix
  - Why: `Content/` has no files on disk — it lives in the `.rbxl`. Required for `MeshPart` because Rojo cannot sync meshes. No intellisense.
  - Examples: environment props, meshes, lighting setups, staging.

- **Never put code-owned config under `Content/`**
  - Tier: must-fix
  - Why: Studio is the source of truth there — the config becomes invisible to code review and diffs.

- **When exporting from Studio to `ManagedContent/`, save as `.rbxmx` (XML) — not `.rbxm` (binary)**
  - Tier: must-fix
  - Why: `.rbxmx` gives readable diffs. Roblox exports `.rbxm` by default; you have to pick `.rbxmx` explicitly.

## Module internals

- **Canonical module shape**
  - Tier: must-fix
  - ✅
    ```
    MyThing/
      init.luau           -- entry point (system: start(); library: returned table)
      Constants.luau      -- user-configurable values
      Types.luau          -- public types
      Utility/            -- optional: helpers shared across files in this module
      Validation/         -- optional, server-only
      Remotes/            -- optional, owned by systems or libraries
    ```

- **Helpers used by only one file in the module stay local to that file — not promoted to `Utility/`**
  - Tier: cleanup
  - Why: `Utility/` is for helpers actually shared across files in the module.

- **`Utility/` holds single-function helpers — multi-method modules belong in `Libraries/`**
  - Tier: must-fix
  - Why: A file under `Utility/` should return one function. Once a helper grows a surface (multiple exported methods, module-level state, lifecycle calls), it has outgrown the "utility" shape and is a Library. Burying a multi-method module inside another module's `Utility/` folder — or as a sibling submodule next to `Utility/` — hides it from every other consumer that might need it.
  - ❌
    ```
    GameModes/RobustWanted/
      RespawnScheduler/init.luau    -- exports schedule, cancel, clear (three methods + state)
      Utility/
        giveWinnerAccessory.luau    -- single function, OK under Utility/
        removeWinnerAccessory.luau  -- single function, OK under Utility/
    ```
  - ✅
    ```
    Libraries/RespawnScheduler/
      init.luau                     -- three-method library, promoted out
    GameModes/RobustWanted/Utility/
      giveWinnerAccessory.luau      -- still single-function, stays
      removeWinnerAccessory.luau
    ```

- **`Validation/` is server-only; never require it from client or shared code**
  - Tier: must-fix

- **Server + client halves of a module are split into `*Server.luau` and `*Client.luau` files**
  - Tier: must-fix
  - Why: When a feature has both a server and client entry point, the filename must carry the boundary. Shared types and Remotes live in the module folder without a suffix.
  - ❌
    ```
    src/ServerScriptService/Libraries/Bounty.luau
    src/ReplicatedStorage/Client/Libraries/Bounty.luau
    ```
  - ✅
    ```
    src/ServerScriptService/Libraries/BountyServer.luau
    src/ReplicatedStorage/Client/Libraries/BountyClient.luau
    src/ReplicatedStorage/Libraries/Bounty/Types.luau    -- shared, no suffix
    src/ReplicatedStorage/Libraries/Bounty/Remotes/      -- shared, no suffix
    ```

## Constants organization

- **User-configurable values live in `Constants.luau` — never baked into per-state or per-logic files**
  - Tier: must-fix
  - Why: Verbatim reviewer guidance: "these constants shouldn't be baked into the state. could expose methods or have a shared constant group constants file."
  - ❌
    ```luau
    -- inside States/FollowLeader.luau
    local CLOSE_DISTANCE = 8
    local FAR_DISTANCE = 25
    local MOVEMENT_TARGET_THRESHOLD = 2
    -- ...logic that reads these...
    ```
  - ✅
    ```luau
    -- inside States/FollowLeader.luau
    local Constants = require(script.Parent.Parent.Constants)
    -- read Constants.CLOSE_DISTANCE, Constants.FAR_DISTANCE, Constants.MOVEMENT_TARGET_THRESHOLD
    ```

- **Default configuration tables live in `Constants.luau` as `DEFAULT_<THING>_CONFIG`**
  - Tier: must-fix
  - Why: Keeps the defaults-clone-then-merge pattern clean. See the style rulebook's "Default merging" section for the merge shape.
  - ✅
    ```luau
    -- Constants.luau
    local DEFAULT_SIZE = UDim2.fromOffset(200, 200)
    local DEFAULT_POSITION = UDim2.fromScale(0.5, 0.5)

    local Constants = {
        DEFAULT_MINIMAP_CONFIG = {
            size = DEFAULT_SIZE,
            position = DEFAULT_POSITION,
            worldRadius = 50,
        },
    }

    return Constants
    ```

- **Remove unused constants; inline single-use constants that only this file reads**
  - Tier: cleanup

- **Classify literals by audience: configurable or public → `Constants.luau`; implementation-internal → local at the top of the file**
  - Tier: must-fix
  - Why: A literal is "configurable" or "public" if a consumer of the module might reasonably want to tune it, or if it names a cross-module concept (tag names, attribute names, default configs, thresholds a designer cares about). Those belong in `Constants.luau` where they're discoverable and editable. A literal is "implementation-internal" if it's a magic number only the logic inside this file relies on (a sort threshold, a loop cap, a string separator only this file composes) — those stay as `local` at the top of the file so the reader sees them without crossing a module boundary.
  - ✅ configurable / public → `Constants.luau`
    ```luau
    -- Constants.luau
    local Constants = {
        CHARACTER_TAG = "Character",
        DEFAULT_WORLD_RADIUS = 100,
        FLAG_ATTRIBUTE_PREFIX = "flag_",
    }
    ```
  - ✅ implementation-internal → local at top of file
    ```luau
    -- inside Utility/getTagsKey.luau
    local TAGS_SEPARATOR = "|"

    local function getTagsKey(tags: { string }): string
        return table.concat(tags, TAGS_SEPARATOR)
    end
    ```
  - ❌ user-tunable value hardcoded deep in logic
    ```luau
    -- inside Steps/goToArea.luau
    if distance < 5 then     -- what's 5? a designer would tune this. move to Constants.luau.
    ```
  - ❌ implementation-internal value exposed through Constants.luau
    ```luau
    -- Constants.luau
    local Constants = {
        TAGS_SEPARATOR = "|",    -- only getTagsKey reads this; keep it local to getTagsKey.luau
    }
    ```

## Factory-returned module shape

- **Modules with methods return a factory-built table — declare methods as locals first, assign the return table at the end**
  - Tier: must-fix
  - Why: Verbatim reviewer guidance: "in this case, its fine for all methods to be local methods and initialize [the object] at the end to avoid creating empty proxy methods."
  - ❌
    ```luau
    local function create(config): Types.Minimap
        local minimap = {} :: Types.Minimap

        function minimap.addMarker(self, marker) ... end
        function minimap.updateMarkerConfig(self, id, config) ... end
        function minimap.destroy(self) ... end

        return minimap
    end
    ```
  - ✅
    ```luau
    local function create(config): Types.Minimap
        local minimap: Types.Minimap

        local function addMarker(marker) ... end
        local function updateMarkerConfig(id, config) ... end
        local function destroy() ... end

        minimap = {
            addMarker = addMarker,
            updateMarkerConfig = updateMarkerConfig,
            destroy = destroy,
        } :: Types.Minimap

        return minimap
    end
    ```

- **Factory methods do not take a `self` parameter — they close over state via locals**
  - Tier: must-fix
  - Why: The most-repeated review comment on our factory code. "don't need self" / "remove self" was left on nearly every method in one PR.
  - ❌
    ```luau
    function minimap.addMarker(self, marker: Types.Marker)
        table.insert(self.markers, marker)
    end
    ```
  - ✅
    ```luau
    local markers: { Types.Marker } = {}

    local function addMarker(marker: Types.Marker)
        table.insert(markers, marker)
    end
    ```

- **Metatables are BANNED. No `setmetatable`, no `__index`, no class-style OOP.**
  - Tier: must-fix
  - Why: Metatables confuse the Luau type system, hide control flow, and make dispatch opaque to readers. This is non-negotiable. Use the factory pattern above for anything that needs methods.
  - ❌
    ```luau
    local Inventory = {}
    Inventory.__index = Inventory

    function Inventory.new(player)
        local self = setmetatable({}, Inventory)
        self.player = player
        self.items = {}
        return self
    end

    function Inventory:addItem(item) ... end
    ```
  - ✅
    ```luau
    local function createInventory(player: Player): Types.Inventory
        local items: { Types.Item } = {}

        local function addItem(item: Types.Item)
            table.insert(items, item)
        end

        return {
            player = player,
            addItem = addItem,
        } :: Types.Inventory
    end
    ```

## Stateful-registry cleanup

- **Any module that holds per-entity state MUST export a `remove*` / `clear*` function**
  - Tier: must-fix
  - Why: Verbatim reviewer guidance: "we should have a `removeInventory` function for cleanup, otherwise we will leak! ... different things like player inventories will have different needs for when they get cleaned up (e.g. after saving)." Without this, every consumer leaks.
  - ❌
    ```luau
    local inventories: { [Player]: Types.Inventory } = {}

    local function getInventory(player: Player): Types.Inventory
        if not inventories[player] then
            inventories[player] = createInventory(player)
        end
        return inventories[player]
    end

    return { getInventory = getInventory }
    ```
  - ✅
    ```luau
    local inventories: { [Player]: Types.Inventory } = {}

    local function getInventory(player: Player): Types.Inventory ... end

    local function removeInventory(player: Player)
        inventories[player] = nil
    end

    return {
        getInventory = getInventory,
        removeInventory = removeInventory,
    }
    ```

- **The stateful module does NOT auto-cleanup — callers decide timing**
  - Tier: must-fix
  - Why: A player inventory might need to save before it's freed; a per-character registry might need to outlive the Humanoid.Died event. The module exposes the function, the caller picks the moment.
  - ❌ inside the registry module
    ```luau
    Players.PlayerRemoving:Connect(function(player)
        inventories[player] = nil
    end)
    ```
  - ✅ in the caller (server startup)
    ```luau
    Players.PlayerRemoving:Connect(function(player)
        PlayerData.saveAsync(player)
        Inventory.removeInventory(player)
    end)
    ```

- **Signal cleanup goes through `disconnectAndClear` from `ReplicatedStorage.Core.Utility`**
  - Tier: must-fix
  - Why: Hand-rolled disconnect loops drift. Reuse the canonical utility.
  - ❌
    ```luau
    for _, connection in connections do
        connection:Disconnect()
    end
    table.clear(connections)
    ```
  - ✅
    ```luau
    local disconnectAndClear = require(ReplicatedStorage.Core.Utility.disconnectAndClear)
    -- ...
    disconnectAndClear(connections)
    ```

## Remotes

- **Use `RemoteFunction` when the caller needs a return value; `RemoteEvent` for fire-and-forget**
  - Tier: must-fix
  - Why: Recurring reviewer question: "should this be a remotefunction?" When the client needs "give me the current state," it's a `RemoteFunction`. When the server fires "this happened," it's a `RemoteEvent`.
  - ❌
    ```luau
    -- client asks for current quest state via a RemoteEvent + a separate reply event
    RequestQuestState:FireServer()
    QuestStateReply.OnClientEvent:Connect(function(state) ... end)
    ```
  - ✅
    ```luau
    local state = RequestQuestState:InvokeServer()
    ```

- **Remotes live under the owning module's `Remotes/` subfolder — not scattered in `ReplicatedStorage`**
  - Tier: must-fix
  - Why: Each module (System or Library) owns its `Remotes/` subfolder. Startup binds handlers from there; nothing outside that folder is picked up.
  - ✅
    ```
    src/shared/Systems/Inventory/Remotes/
      RequestInventory.model.json   -- RemoteFunction
      InventoryChanged.model.json   -- RemoteEvent
    ```
  - ✅ (library-owned Remotes are fine)
    ```
    src/shared/Libraries/Bounty/Remotes/
      BountyAssigned.model.json    -- RemoteEvent
      BountyCompleted.model.json   -- RemoteEvent
    ```

## Startup order

- **`autoLoad()` runs before `start()`; `start()` runs before project-specific init**
  - Tier: must-fix
  - Why: Definitions (from `ManagedContent/`) have to be loaded before systems that consume them start.
  - ✅
    ```luau
    local function initialize()
        Factions.autoLoad(FactionDefinitions)
        QuestServer.autoLoad(ServerScriptService.ManagedContent.QuestDefinitions)
        Action.autoLoad(ReplicatedStorage.ManagedContent.ActionDefinitions)

        InventoryServerCore.start(Items)
        Action.start()
        -- project-specific init follows
    end

    initialize()
    ```

- **Inside `start()`, connect events BEFORE any async work**
  - Tier: must-fix
  - Why: Late-arriving events get dropped otherwise. This is the single biggest race-condition source we see.
  - ❌
    ```luau
    function System.start()
        local config = fetchConfigAsync()   -- yields
        Remotes.Action.OnServerEvent:Connect(onAction)   -- events fired during the yield are lost
    end
    ```
  - ✅
    ```luau
    function System.start()
        Remotes.Action.OnServerEvent:Connect(onAction)
        local config = fetchConfigAsync()
    end
    ```

- **One `initialize()` function per entry-point script, called at the end of the file**
  - Tier: cleanup
  - ✅
    ```luau
    local function initialize()
        -- autoLoad, then start, then project init
    end

    initialize()
    ```

## cgs-core-libraries submodule

- **Require from `Core` in a consuming project — don't reach into `cgs-core-libraries` by path**
  - Tier: must-fix
  - Why: The submodule is mapped as a folder named `Core` inside both `ReplicatedStorage` and `ServerScriptService`.
  - ✅
    ```luau
    local Signal = require(ReplicatedStorage.Core.Libraries.Signal)
    local QuestServer = require(ServerScriptService.Core.Systems.QuestServer)
    ```

- **Edits meant to stick go as an upstream PR against `cgs-core-libraries` — not committed from a consuming project**
  - Tier: must-fix
  - Why: Consuming projects pin the submodule; local commits there get lost on the next pin bump.

---

## Cross-concern

If you notice **style** issues during a structure review (casing, naming, abbreviations, typing, control flow, assertions, whitespace, interpolation), do NOT list them. Instead, emit one line at the end of your report:

```
Cross-concern: run /cgs-style-pass
```

If you are reviewing a file under `UI/` and notice **React-specific** issues (feature folder shape, component shape, hook conventions, story conventions, mounting, React/ReactRoblox method localization), do NOT list them. Instead, emit one line at the end of your report:

```
Cross-concern: run /cgs-react-pass
```
