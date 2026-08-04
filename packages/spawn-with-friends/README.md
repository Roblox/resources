# spawn-with-friends

Server-side dev module that teleports a player to a random friend in the same experience. Useful as a respawn behavior or as a manually-triggered "find my friend" action.

Public docs: https://create.roblox.com/docs/en-us/resources/modules/spawn-with-friends

## Develop locally

```sh
cd packages/spawn-with-friends
wally install                      # resolve `t` from the public Wally registry
rojo serve dev.project.json
```

`default.project.json` (Folder-rooted) is for `rojo build` to produce the package `.rbxm`. `dev.project.json` (DataModel-rooted) is the place wrapper required by `rojo serve`.

Open Roblox Studio, enable the Rojo plugin, and **Connect**. A live `SpawnWithFriends` ModuleScript mounts under `ReplicatedStorage`. The ModuleScript exposes:

- `SpawnWithFriends.configure(opts)` — adjust teleport distance, friendship-check bypass, log verbosity, etc.
- `SpawnWithFriends.teleportToRandomFriend(player)` — manually teleport `player` to a random friend in the server. Returns a boolean.
- `SpawnWithFriends.setTeleportationValidator(fn)` — register a callback to allow/deny each teleport (e.g. team-based gating).

See `src/init.lua` for the full surface, and `src/Server.server.lua` for the default respawn behavior.
