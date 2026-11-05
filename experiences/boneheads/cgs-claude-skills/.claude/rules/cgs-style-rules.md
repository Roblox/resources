# CGS style rules

Writing-style rules for Luau in this repo. Sourced from `docs/PROJECT_STRUCTURE.md`, the team Luau style guide, and recurring human reviewer feedback.

This file is consumed by `/cgs-style-pass` and `/cgs-review`. It covers **local code quality only** — how code is written inside a file. Module layout, Systems vs Libraries, factory shape, cleanup APIs, Remote choice, and startup order are structure concerns — see `cgs-structure-rules.md`. Report-row formatting (File:Line / Snippet / tier headers) lives in `cgs-report-format-rules.md`.

Each rule has a tier:

- **must-fix** — clear rule violation; block the review until fixed.
- **cleanup** — small polish the author should handle before asking for a human review.

## Contents

- Casing
- Naming
- Strict typing
- Control flow
- Assertions
- Default merging
- Redundancy
- Comments
- Whitespace
- File-top organization
- Cross-concern

---

## Casing

- **Services and libraries use PascalCase**
  - Tier: must-fix
  - ❌
    ```luau
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local myLibrary = require(replicatedStorage.Libraries.MyLibrary)
    ```
  - ✅
    ```luau
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local MyLibrary = require(ReplicatedStorage.Libraries.MyLibrary)
    ```

- **Custom types use PascalCase**
  - Tier: must-fix
  - ✅
    ```luau
    type PlayerState = { health: number, stamina: number }
    ```

- **Constants use SCREAMING_SNAKE_CASE**
  - Tier: must-fix
  - ❌
    ```luau
    local coolNumber = 1337
    ```
  - ✅
    ```luau
    local COOL_NUMBER = 1337
    ```

- **Locals, parameters, and function names use camelCase**
  - Tier: must-fix
  - Exception: single-token aliases for function-like operators (`AND`, `OR`, `NOT`, `XOR`) may use SCREAMING_SNAKE_CASE when the alias is used as an infix-style constructor that reads like a keyword. The exception covers both the local alias and the source-of-truth export in a logic-combinator library.
  - ✅
    ```luau
    local function niceFunction(player: Player)
        print(`{player.Name} did something`)
    end
    ```
  - ✅ operator-semantic alias
    ```luau
    local AND = TestLogic.AND
    local NOT = TestLogic.NOT
    test = AND(isCloseToLeader, hasToken)
    ```

- **In `Constants.luau`: tags PascalCase, attribute names camelCase**
  - Tier: cleanup
  - ✅
    ```luau
    local Constants = {
        CHARACTER_TAG = "Character",
        HEALTH_ATTRIBUTE = "health",
    }
    ```

## Naming

- **No abbreviations in identifiers**
  - Tier: must-fix
  - Why: This is the single most frequent nit in our PR reviews. Reviewers will call it out every time. Fix it before opening a PR.
  - ❌
    ```luau
    local mapPos = marker:GetPivot().Position
    local bgLabel = frame.BackgroundLabel
    local maxDist = 50
    ```
  - ✅
    ```luau
    local mapPosition = marker:GetPivot().Position
    local backgroundLabel = frame.BackgroundLabel
    local maxDistance = 50
    ```

- **Yielding functions use the `Async` suffix**
  - Tier: must-fix
  - ❌
    ```luau
    local function price(flavor: string): number
        return HttpService:GetAsync("coffee.price/" .. flavor)
    end
    ```
  - ✅
    ```luau
    local function getPriceAsync(flavor: string): number
        return HttpService:GetAsync("coffee.price/" .. flavor)
    end
    ```

- **Predicates (`is*` / `has*` / `should*`) must be side-effect-free**
  - Tier: must-fix
  - Why: A predicate name tells the reader "this is a pure check." If the function mutates state and returns a status, it's an action, not a predicate. Hiding mutation behind a boolean-returning name makes state changes invisible at call sites. Review comments repeatedly flagged `ensureJoinedGroup` / `ensureCreatedGroup` / `notInGroup` — all boolean returns with embedded side effects.
  - ❌ mutating predicate
    ```luau
    local function ensureJoinedGroup(context: Types.Context): boolean
        if not Group.getGroupName(context.character) then
            Group.join(context.character, findClosest(context))   -- side effect
        end
        return true
    end
    ```
  - ✅ name as an action that returns status
    ```luau
    local function tryJoinGroup(context: Types.Context): boolean
        if Group.getGroupName(context.character) then
            return true
        end
        local target = findClosest(context)
        if not target then
            return false
        end
        Group.join(context.character, target)
        return true
    end
    ```

- **Within a module's method table, method names are consistent about including vs dropping the module's subject noun**
  - Tier: cleanup
  - Why: Reviewer feedback verbatim: "need a pass to rename method names for consistency. some methods include 'Group' while others don't. `getGroupName` vs `create`." Pick one convention per module — either all methods describe the subject (`getGroupName`, `createGroup`, `deleteGroup`) or all methods drop it (`getName`, `create`, `delete`). Mixing reads as a partial refactor.
  - ❌ mixed
    ```luau
    Group.getGroupName(character)
    Group.create(name)
    Group.getLeader(name)
    ```
  - ✅ module as subject (drop inside)
    ```luau
    Group.getName(character)
    Group.create(name)
    Group.getLeader(name)
    ```

- **Factory functions use a `make` / `create` prefix; predicates use `is`; getters use `get`**
  - Tier: cleanup
  - Why: Reviewer feedback — "method name should be clear and predictable."
  - ❌
    ```luau
    local function goToLeaderState(context) ... end
    local function closeToLeader(context): boolean ... end
    local function distanceToLeader(context): number ... end
    ```
  - ✅
    ```luau
    local function makeGoToLeaderState(context) ... end
    local function isCloseToLeader(context): boolean ... end
    local function getDistanceToLeader(context): number ... end
    ```

- **Signal accessors match Roblox API phrasing: `get<Thing>ChangedSignal`**
  - Tier: cleanup
  - ✅
    ```luau
    local function getFlagChangedSignal(flagName: string): Signal ... end
    ```

- **Do not shadow stdlib globals (`task`, `string`, `math`, `table`, etc.)**
  - Tier: must-fix
  - Why: Shadows silently break any later code in scope that uses the real library. The rule also covers parameter names inside function-type annotations: even though type-annotation names don't shadow at runtime, readers assume they follow the same convention as runtime locals, and naming a callback parameter `task` is the same visual cue that a variable `task` would be — it reads as a shadow.
  - ❌ runtime shadow
    ```luau
    for _, task in tasks do
        task.run()
    end
    ```
  - ❌ type-annotation shadow
    ```luau
    onProgressed: (callback: (stepIndex: number, maxSteps: number, task: StepTask) -> ()) -> ()
    ```
  - ✅
    ```luau
    for _, questTask in tasks do
        questTask.run()
    end
    ```
  - ✅ type annotation
    ```luau
    onProgressed: (callback: (stepIndex: number, maxSteps: number, stepTask: StepTask) -> ()) -> ()
    ```

- **Unused parameters are `_`-prefixed or removed**
  - Tier: cleanup
  - ❌
    ```luau
    for i, flavor in coffeeFlavors do
        print(flavor)
    end
    ```
  - ✅
    ```luau
    for _, flavor in coffeeFlavors do
        print(flavor)
    end
    ```

- **No single-character locals except `i` for a loop index**
  - Tier: cleanup
  - Why: `x, y, z` referring literally to axes are excusable; everything else should be descriptive.

## Strict typing

- **Every function parameter is annotated. Return type is annotated when the function returns a value.**
  - Tier: must-fix
  - Why: `.luaurc` already enforces strict mode; annotations also document intent for callers. Void functions (functions that never return a value) may omit the `: ()` return type — the annotation carries no information in that case.
  - ❌
    ```luau
    local function foo(fizz, buzz)
        return fizz > buzz
    end
    ```
  - ✅
    ```luau
    local function foo(fizz: number, buzz: number): boolean
        return fizz > buzz
    end
    ```
  - ✅ (void — no return annotation needed)
    ```luau
    local function log(message: string)
        print(message)
    end
    ```

- **Specifically-shaped structs have a declared type, even when locally inferred**
  - Tier: must-fix
  - ✅
    ```luau
    export type Result = { alpha: Vector3, beta: string }

    local function getResult(): Result
        return { alpha = Vector3.zero, beta = "beta" }
    end
    ```

- **Shared types live in a `Types.luau` module**
  - Tier: must-fix
  - Why: Avoids circular requires once more than one module needs the same type.

- **`any` casts are discouraged — use only when the Luau type solver genuinely can't express the intent**
  - Tier: must-fix
  - Why: Defeats strict-mode coverage. Prefer a union, a generic, or a declared type.
  - Exception: the Luau type solver isn't perfect — occasionally a `:: any` cast is the only way to get a legal program through, especially around table.clone + heterogeneous merges or some generic-constraint edge cases. When that's the case, keep the cast narrow (cast the single expression that needs it, not every downstream access) and leave a short comment explaining why the straightforward typing doesn't compile. Flag in review unless such a comment is present.

## Control flow

- **Guard at function entry — flatten nesting with early return / `continue`**
  - Tier: must-fix
  - Why: Reviewers call this out repeatedly as "early exit to avoid long nesting."
  - ❌
    ```luau
    if conditionA then
        if conditionB then
            if conditionC then
                doSomething()
            end
        end
    end
    ```
  - ✅
    ```luau
    if not (conditionA and conditionB and conditionC) then
        return
    end

    doSomething()
    ```
  - ❌
    ```luau
    for _, marker in markers do
        if worldPosition then
            if not (isOnMap or (edgeConfig and not edgeConfig.enabled)) then
                renderMarker(marker)
            end
        end
    end
    ```
  - ✅
    ```luau
    for _, marker in markers do
        if not worldPosition then
            continue
        end
        if isOnMap or (edgeConfig and not edgeConfig.enabled) then
            continue
        end
        renderMarker(marker)
    end
    ```

- **No `else` after a guard return**
  - Tier: cleanup
  - ❌
    ```luau
    if not instance then
        return
    else
        instance:Destroy()
    end
    ```
  - ✅
    ```luau
    if not instance then
        return
    end
    instance:Destroy()
    ```

- **Explicit `~= nil` when the value can legitimately be `false` or `0`**
  - Tier: must-fix
  - Why: `if instance:GetAttribute(x) then` misfires when the attribute is `false`.
  - ❌
    ```luau
    if instance:GetAttribute("active") then
        return true
    end
    return false
    ```
  - ✅
    ```luau
    if instance:GetAttribute("active") ~= nil then
        return true
    end
    return false
    ```

## Assertions

- **Assert invariants at the entry of functions that depend on them — do not silently no-op**
  - Tier: must-fix
  - Why: Reviewers asked for this repeatedly ("this should be an assert", "we should assert that there are enough items in the inventory to remove"). Silent no-ops hide real bugs.
  - ❌
    ```luau
    local function removeItem(inventory, itemId: string, count: number)
        local entry = inventory[itemId]
        if not entry or entry.count < count then
            return
        end
        entry.count -= count
    end
    ```
  - ✅
    ```luau
    local function removeItem(inventory, itemId: string, count: number)
        local entry = inventory[itemId]
        assert(entry, `no inventory entry for {itemId}`)
        assert(entry.count >= count, `not enough of {itemId} to remove`)
        entry.count -= count
    end
    ```

- **Assert on `PrimaryPart` (and similar optional references) after reading them**
  - Tier: must-fix
  - Exception: if the function's return type explicitly includes `nil` (e.g., `: Vector3?` or `: (Vector3?, ...)`), an early `return nil` is the intended behavior and no assert is needed.
  - ❌
    ```luau
    local rootPart = leader.PrimaryPart
    moveTo(rootPart.Position)
    ```
  - ✅
    ```luau
    local rootPart = leader.PrimaryPart
    assert(rootPart, "Character missing primary part")
    moveTo(rootPart.Position)
    ```
  - ✅ early-return when the return type allows nil
    ```luau
    local function getPlayerPosition(): Vector3?
        local rootPart = character.PrimaryPart
        if not rootPart then
            return nil
        end
        return rootPart.Position
    end
    ```

## Default merging

- **Merge caller config into a `table.clone` of defaults — never spread a huge literal**
  - Tier: must-fix
  - Why: Verbatim reviewer guidance — "with a default config, don't need to spread a huge table." Once defaults exist, downstream code should rely on them being present.
  - ❌
    ```luau
    local function create(config: Types.MiniMapConfig?)
        local merged = {
            size = (config and config.size) or UDim2.fromOffset(200, 200),
            position = (config and config.position) or UDim2.fromScale(0.5, 0.5),
            worldRadius = (config and config.worldRadius) or 50,
            -- ...20 more lines...
        }
    end
    ```
  - ✅
    ```luau
    local function create(config: Types.MiniMapConfig?)
        local merged = table.clone(Constants.DEFAULT_MINIMAP_CONFIG)
        if config then
            for key, value in config do
                merged[key] = value
            end
        end
    end
    ```

- **Downstream code uses the merged config directly — no `(merged.x or default)` re-defaulting**
  - Tier: must-fix
  - ❌
    ```luau
    frame.Size = merged.size or UDim2.fromOffset(200, 200)
    ```
  - ✅
    ```luau
    frame.Size = merged.size
    ```

## Redundancy

- **Use `table.insert` for appending**
  - Tier: cleanup
  - ❌
    ```luau
    items[#items + 1] = item
    ```
  - ✅
    ```luau
    table.insert(items, item)
    ```

- **Use `Random.new()` — not `math.random` — for gameplay randomness**
  - Tier: must-fix
  - Why: Seedable, thread-safe, and consistent with the rest of the codebase.
  - ❌
    ```luau
    return names[math.random(1, #names)]
    ```
  - ✅
    ```luau
    local random = Random.new()
    -- ...
    return names[random:NextInteger(1, #names)]
    ```

- **Use string interpolation, not concatenation, for dynamic messages**
  - Tier: cleanup
  - ❌
    ```luau
    print(key .. " has a value of " .. tostring(value))
    ```
  - ✅
    ```luau
    print(`{key} has a value of {value}`)
    ```

- **Use the property directly when it already has the right type**
  - Tier: cleanup
  - Why: Reviewer note: `mapClip.AbsoluteSize` is already a `Vector2` — no constructor needed.
  - ❌
    ```luau
    clipSize = Vector2.new(mapClip.AbsoluteSize.X, mapClip.AbsoluteSize.Y)
    ```
  - ✅
    ```luau
    clipSize = mapClip.AbsoluteSize
    ```

- **Inline a single-use local — don't give a name something only read once**
  - Tier: cleanup

- **No leftover `print` calls — remove debug prints before committing**
  - Tier: cleanup
  - Why: Leftover debug prints clutter output and signal unfinished work. 
  - ❌
    ```luau
    local function onPlayerAdded(player: Player)
        print("player added", player.Name)
        setupInventory(player)
    end
    ```
  - ✅ (remove the print entirely — no replacement needed for debug traces)
    ```luau
    local function onPlayerAdded(player: Player)
        setupInventory(player)
    end
    ```

## Comments

- **Comments should be sparse — only write one when the WHY is non-obvious**
  - Tier: must-fix
  - Why: Code with good naming and structure reads without commentary. Excessive comments add noise, drift out of sync with the code, and often restate what the names already say. Reserve comments for: a hidden invariant, a subtle constraint, a workaround for a specific bug, a non-obvious performance trade-off, or a behavior that would surprise a reader.
  - ❌ restates the code
    ```luau
    -- increment the counter
    counter += 1
    ```
  - ❌ narrates the current task
    ```luau
    -- Step 3: Defeat goblins AND (gather healing herbs OR gather special healing herbs)
    ```
  - ❌ section-header comment for no reason
    ```luau
    -- Transitions
    local function farFromLeader(context: Types.Context): boolean ... end
    ```
  - ✅ explains a non-obvious constraint
    ```luau
    -- Navigation takes ~2 frames to register the stop; lerp to avoid jitter.
    context.targetPosition = previous:Lerp(target, alpha)
    ```
  - ✅ documents an intentional deviation
    ```luau
    -- InvokeServer would block the client thread while the server resolves saves;
    -- fire-and-subscribe keeps the GUI responsive during login.
    remotes.RequestQuestState:FireServer()
    ```

## Whitespace

- **Format with StyLua defaults — never hand-format**
  - Tier: must-fix
  - Why: The repo ships a `stylua.toml`; running the formatter resolves all whitespace concerns deterministically. Do not argue with StyLua.

- **Blank line between logical blocks inside a function**
  - Tier: cleanup
  - Why: Frequent reviewer nit ("nit: add a new line"). Separates setup, work, and return.

## File-top organization

- **All services acquired via `:GetService()` at the top of the file — never `game.X` or bare `workspace`**
  - Tier: must-fix
  - Why: Services are not technically guaranteed to have their classname as their Name.
  - ❌
    ```luau
    local object = game.ReplicatedStorage.Object:Clone()
    object.Parent = workspace
    ```
  - ✅
    ```luau
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local object = ReplicatedStorage.Object:Clone()
    object.Parent = Workspace
    ```

- **Frequently used workspace refs (camera, `RunService`, etc.) are localized at module top, not inside methods**
  - Tier: cleanup
  - ❌
    ```luau
    local function update()
        local camera = workspace.CurrentCamera
        -- ...
    end
    ```
  - ✅
    ```luau
    local Workspace = game:GetService("Workspace")
    local camera = Workspace.CurrentCamera

    local function update()
        -- use `camera`
    end
    ```

- **Type declarations live near the top of the module, above function definitions**
  - Tier: cleanup

- **Internal constants stay local to the file — don't expose them through `Constants.luau` unless another module reads them**
  - Tier: cleanup
  - Why: Verbatim reviewer guidance: "I would just keep `TAGS_SEPARATOR` as a constant in this file, no need to expose it elsewhere."
  - ✅
    ```luau
    local TAGS_SEPARATOR = "|"

    local function getTagsKey(tags: { string }): string
        return table.concat(tags, TAGS_SEPARATOR)
    end
    ```

- **Module-level state variables declared above the methods that read them**
  - Tier: cleanup

---

## Cross-concern

If you notice **structural** issues during a style review (module layout, Systems vs Libraries, factory shape, cleanup APIs, Remote choice, constants organization, startup order, metatables, ManagedContent placement), do NOT list them. Instead, emit one line at the end of your report:

```
Cross-concern: run /cgs-structure-pass
```

If you are reviewing a file under `UI/` and notice **React-specific** issues (feature folder shape, component shape, hook conventions, story conventions, mounting, React/ReactRoblox method localization), do NOT list them. Instead, emit one line at the end of your report:

```
Cross-concern: run /cgs-react-pass
```
