# CGS React rules

React + Roblox-React idioms for `.luau` files under `UI/`. Sourced from a recent React feature migration and the conventions that fell out of it.

This file is consumed by `/cgs-react-pass` and `/cgs-review`. It covers **React-specific concerns** — feature folder shape, component shape, hook conventions, story conventions, mounting hygiene, and React-flavored style choices. In-file Luau style (casing, naming, control flow, assertions, etc.) is a style concern — see `cgs-style-rules.md`. Module organization outside of `UI/` (Systems vs Libraries, ManagedContent placement, Remote choice, startup order) is a structure concern — see `cgs-structure-rules.md`. Report-row formatting (File:Line / Snippet / tier headers) lives in `cgs-report-format-rules.md`.

Each rule has a tier:

- **must-fix** — clear rule violation; block the review until fixed.
- **cleanup** — small polish the author should handle before asking for a human review.

## Contents

- Feature folder convention
- Component shape
- Hooks
- Stories
- Mounting
- React-flavored style
- Cross-concern

---

## Feature folder convention

- **`UI/Features/<FeatureName>/` is the home for feature-scoped React views**
  - Tier: must-fix
  - Why: `UI/Features/` sits as a sibling to `UI/App/`, `UI/Components/Common/`, `UI/Hooks/`, and `UI/Utility/`. Each carries a different ownership contract. `Components/Common/` is for cross-feature primitives (buttons, panes, labels) — they take props and render. A feature, by contrast, owns its own state and remote subscriptions. Putting a feature under `Components/Common/` implies it's a reusable primitive, which is misleading; putting a primitive under `Features/` hides it from the rest of the UI.
  - ✅
    ```
    UI/Features/SomeFeature/init.luau         -- owns state, subscribes to remotes
    UI/Components/Common/Button.luau           -- pure, prop-driven, reusable
    ```
  - ❌
    ```
    UI/Components/Common/SomeFeature.luau      -- not common — it owns feature state
    ```

- **Canonical feature folder layout**
  - Tier: must-fix
  - ✅
    ```
    UI/Features/<Name>/
      init.luau              -- root FC, render-only
      init.story.luau        -- optional dev story
      Constants.luau         -- only values shared across files in this feature
      Types.luau             -- shared types
      Components/            -- feature-specific subcomponents
      Hooks/                 -- feature-specific hooks
    ```
  - Helpers that only one file in the feature uses stay local to that file — `Components/` and `Hooks/` are for things actually shared across the feature.

- **Systems vs Libraries does NOT apply to React feature components**
  - Tier: must-fix
  - Why: A React feature is neither a System nor a Library — it's a view-layer consumer of a System's remotes. It has no `start()`, no `autoLoad()`, no factory shape. Don't try to fold a feature into the System/Library taxonomy; it's a third category that lives under `UI/Features/`.

## Component shape

- **The top-level feature component is render-only**
  - Tier: must-fix
  - Why: When the root FC mixes state management with rendering, both halves get harder to read and the story file ends up duplicating logic. Keep the body thin: hook calls produce state, a derived flag decides what to render, a single ternary returns `createElement(...)` (or `nil`). Push state mutation into a feature-local hook; push children construction into a module-level helper.
  - ❌
    ```luau
    local function TodoList()
        local items, updateItems = useState({} :: { Item })
        useEffect(function()
            local connection = remotes.TodoUpdated.OnClientEvent:Connect(function(update)
                updateItems(function(previous)
                    -- ...inline reducer logic...
                end)
            end)
            return function() connection:Disconnect() end
        end, {})

        local children = { padding = createElement(Padding, { left = 10 } :: Padding.Props) }
        for id, item in items do
            children[id] = createElement(TodoEntry, { ... } :: TodoEntry.Props) :: any
        end

        return createElement(Pane, { ... } :: Pane.Props, children)
    end
    ```
  - ✅
    ```luau
    local function buildTodoChildren(items: Types.ItemMap): { [string]: React.ReactNode }
        local children = { padding = createElement(Padding, { left = LEFT_INDENT } :: Padding.Props) }
        for id, item in items do
            children[id] = createElement(TodoEntry, { ... } :: TodoEntry.Props) :: any
        end
        return children
    end

    local function TodoList()
        local items = useTodoRegistry(remotes.TodoUpdated.OnClientEvent)
        local hasItems = next(items) ~= nil

        return if hasItems
            then createElement(Pane, { ... } :: Pane.Props, buildTodoChildren(items))
            else nil
    end
    ```

## Hooks

- **Hook names are `use<Concept>` — concept-named, not action-named**
  - Tier: cleanup
  - Why: A hook's name should describe the *thing the hook gives you*, not the thing the hook *does*. `useTodoRegistry` reads as "give me the registry"; `useSubscribeTodos` reads as a verb and obscures what the caller binds to. The action-named form also tempts callers to assume the hook returns nothing.
  - ❌
    ```luau
    local items = useSubscribeTodos(updateSignal)
    ```
  - ✅
    ```luau
    local items = useTodoRegistry(updateSignal)
    ```

- **Module-level state is preferred over `useRef` when the feature mounts once**
  - Tier: cleanup
  - Why: For a UI mounted once with no remount lifecycle (the common case for top-level features), `useRef` adds `.current` ceremony with no payoff — there's only ever one instance, so module-level state is functionally equivalent and reads cleaner. Document the singleton assumption at the top of the file so the reader knows why the state isn't per-instance.
  - ❌
    ```luau
    local function useFooRegistry(signal)
        local timersRef = useRef({} :: { [string]: thread })
        -- timersRef.current[id] = ... everywhere
    end
    ```
  - ✅
    ```luau
    -- Singleton: this hook is mounted once per session by the top-level UI tree.
    local removalTimers: { [string]: thread } = {}

    local function useFooRegistry(signal)
        -- removalTimers[id] = ...
    end
    ```

- **`useState` setter is named `update<Subject>`**
  - Tier: cleanup
  - Why: The default React idiom is `setX`, but `update<Subject>` reads more naturally with the rest of the codebase's verb-first method names and makes the call site self-describing. `updateItems(function(previous) ... end)` reads as "update items with a callback"; `setItems(...)` reads as a generic React setter and hides the intent.
  - ❌
    ```luau
    local items, setItems = useState({})
    ```
  - ✅
    ```luau
    local items, updateItems = useState({})
    ```

- **Dispatch logic lives inline in the `useState` setter — no separate reducer module**
  - Tier: must-fix
  - Why: Extracting `reduce(state, update)` into its own file pulls the dispatch decision away from the place that fires it, adds a layer of indirection, and tempts the team toward a Redux-style architecture that doesn't pay off at this scale. Put the `if/elseif/else` directly inside the setter callback. Small named helpers for individual transitions (e.g. `getRegistryWithFoo`, `getRegistryWithoutFoo`) are good — what's banned is the umbrella reducer.
  - ❌ separate `reducer.luau`
    ```luau
    -- Hooks/reducer.luau
    local function reduce(state, update)
        if update.type == "add" then ... end
        if update.type == "remove" then ... end
    end
    return reduce
    ```
  - ✅ inline dispatch + small named helpers
    ```luau
    updateItems(function(previous)
        if update.type == "remove" then
            return getRegistryWithoutItem(previous, update.id)
        elseif update.type == "complete" then
            return getRegistryWithItem(previous, update, update.maxProgress)
        else
            return getRegistryWithItem(previous, update, update.progress)
        end
    end)
    ```

- **`useEffect` declaration order is the contract for ordering between a hook's effects and its caller's effects**
  - Tier: cleanup
  - Why: React runs effects top-to-bottom in declaration order. When correctness depends on this — for example, a hook's internal subscription effect must run before a sibling effect in the caller that fires a "client ready" remote — leave a one-line comment at the call site so a future reader doesn't reorder the hooks and break the connection.
  - ✅
    ```luau
    local items = useTodoRegistry(remotes.TodoUpdated.OnClientEvent)

    -- useTodoRegistry's subscription effect runs first (effects run in declaration order),
    -- so the connection is live before this fires.
    useEffect(function()
        remotes.RequestTodoState:FireServer()
    end, {})
    ```

- **Memoize hot-path callbacks, values, and components — `useCallback` / `useMemo` / `React.memo`**
  - Tier: cleanup
  - Why: A function or table allocated inline on every render gets a fresh identity every render. When that value flows into a child's props, the child sees "props changed" and re-renders even though nothing meaningful changed; when it flows into a `useEffect` or `useMemo` dependency array, the effect re-runs on every parent render. The fix is identity-stable references:
    - `useCallback(fn, deps)` — for handlers passed into children, dependency arrays, or hook parameters.
    - `useMemo(() -> derived, deps)` — for derived values whose recomputation is expensive (filtering/sorting a large list, building a children dict from a frequently-changing parent).
    - `React.memo(Component)` — for leaf components that re-render often with shallow-equal props (list rows, frequently-rendered subtrees).
    - Don't reach for these by default — every memo carries a small bookkeeping cost and a dependency array to keep correct. Apply them on the **hot path**: subscription handlers passed into hooks, list rows under a high-churn parent, derived values used in effects. For one-shot renders, leave them off.
  - ❌ inline handler causes the hook's subscription effect to re-fire on every render
    ```luau
    local function TodoList()
        local items, updateItems = useState({})

        local function onUpdate(update)
            updateItems(function(previous) ... end)
        end

        useEffect(function()
            local connection = signal:Connect(onUpdate)
            return function() connection:Disconnect() end
        end, { onUpdate })   -- new identity every render, effect re-runs every render

        ...
    end
    ```
  - ✅ `useCallback` stabilizes the handler so the effect only re-runs when its real deps change
    ```luau
    local onUpdate = useCallback(function(update)
        updateItems(function(previous) ... end)
    end, {})
    ```
  - ✅ `useMemo` for derived values consumed by effects or children
    ```luau
    local sortedItems = useMemo(function()
        return sortByOrder(items)
    end, { items })
    ```
  - ✅ `React.memo` on a list row that re-renders under a high-churn parent
    ```luau
    local function TodoEntry(props: Props) ... end
    return React.memo(TodoEntry) :: React.FC<Props>
    ```

## Stories

- **Story files use the standard signature `function(target: Instance) -> () -> ()`**
  - Tier: must-fix
  - Why: The dev story-runner expects a function that takes the mount target and returns an unmount cleanup. Build the React root with `ReactRoblox.createRoot(target)`, render via `root:render(createElement(...))`, and return a cleanup that calls `root:unmount()`.
  - ✅
    ```luau
    return function(target: Instance)
        local root = createRoot(target)
        root:render(createElement(Story))

        return function()
            root:unmount()
        end
    end
    ```

- **The story reuses the live hook — it does not duplicate state logic**
  - Tier: must-fix
  - Why: If a story has to re-implement helpers the live hook already owns, the live hook isn't sufficiently generalized — typically because it accepts only an `RBXScriptSignal` rather than any signal-shaped object. Refactor the live hook to accept a story-friendly signal type (e.g. typed as `any` or a small `Connect`-shaped interface) so the story can drive a fabricated update stream through the same code path the live UI uses. Two parallel implementations drift.
  - ❌ story duplicates the registry logic
    ```luau
    local function Story()
        local items, updateItems = useState({})
        -- ...inline copy of the dispatch logic from the real hook...
    end
    ```
  - ✅ story drives the live hook with a synthetic signal
    ```luau
    local function Story()
        local updateSignal = useSignal()
        local items = useTodoRegistry(updateSignal)
        -- script the signal in a useEffect
    end
    ```

## Mounting

- **The React-mounted `ScreenGui` has an explicit `Name`**
  - Tier: cleanup
  - Why: A `ScreenGui` left at its default `Name = "ScreenGui"` is hard to find under `PlayerGui` when many GUIs are present, and it shows up as ambiguous in dev tooling. Set `Name = "UI"` (or another descriptive name) when creating the root `ScreenGui`.
  - ❌
    ```luau
    createElement("ScreenGui", {
        ResetOnSpawn = false,
    }, ...)
    ```
  - ✅
    ```luau
    createElement("ScreenGui", {
        Name = "UI",
        ResetOnSpawn = false,
    }, ...)
    ```

## React-flavored style

- **`React` and `ReactRoblox` methods are localized at the top of the file**
  - Tier: must-fix
  - Why: Same rationale as workspace refs in the style rulebook — frequently used calls read better as bare names. `createElement` appears on nearly every line of a render body; `React.createElement` adds visual weight without information. Localize at module top alongside the `require`s. Type-only references (e.g. `React.FC<Props>`, `React.ReactNode`) are exempt — they don't repeat enough to benefit from aliasing, and keeping the namespace makes them recognizable as types.
  - ❌
    ```luau
    local React = require(ReplicatedStorage.Packages.React)

    local function TodoList()
        return React.createElement(Pane, props, children)
    end
    ```
  - ✅
    ```luau
    local React = require(ReplicatedStorage.Packages.React)
    local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

    local createElement = React.createElement
    local useEffect = React.useEffect
    local useState = React.useState
    local createRoot = ReactRoblox.createRoot

    local function TodoList()
        return createElement(Pane, props, children)
    end

    return TodoList :: React.FC<{}>    -- type-only reference, not localized
    ```

---

## Cross-concern

If you notice **in-file Luau style** issues during a React review (casing, naming, abbreviations, typing, control flow, assertions, whitespace, interpolation), do NOT list them. Instead, emit one line at the end of your report:

```
Cross-concern: run /cgs-style-pass
```

If you notice **non-React structure** issues during a React review (Systems vs Libraries, ManagedContent placement, Remote choice, startup order, factory shape, cleanup APIs, metatables), do NOT list them. Instead, emit one line at the end of your report:

```
Cross-concern: run /cgs-structure-pass
```
