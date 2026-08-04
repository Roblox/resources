# feature-packages-core

Shared foundation library for Roblox feature packages. Provides runtime utilities (`ThreadQueue`, `TimerSystem`, `UITween`), config types, a DataStore wrapper, and the shared HUD prefab. Used by Bundles, Missions, SeasonPasses, and EngagementRewards.

Public docs: https://create.roblox.com/docs/en-us/resources/feature-packages

## Develop locally

```sh
cd packages/feature-packages-core
rojo serve dev.project.json
```

Open Roblox Studio, enable the Rojo plugin, and **Connect**. A live `FeaturePackagesCore` Folder mounts under `ReplicatedStorage`, mirroring `src/`. Edit Luau in your editor; edit UI prefabs (`src/Objects/*.rbxm`) in Studio — Rojo's two-way sync writes them back to the filesystem.

`default.project.json` (Folder-rooted) is for `rojo build` to produce the package `.rbxm`. `dev.project.json` (DataModel-rooted) is the place wrapper required by `rojo serve`.
