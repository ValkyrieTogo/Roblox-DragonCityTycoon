# Dragon City Tycoon

A "+1 per click" Roblox game. You are a dragon: every click breathes fire and
adds Fire, your whole body grows with it, ice walls between training grounds
melt once you have enough, and reaching the throne gives a Win that resets you
with a permanent multiplier.

Code lives in `src/` and is synced into Studio with Rojo. The map, dragon
costume and UI are placeholders built in code; see "Replacing placeholders".

## One-time setup

1. Install Rokit: `winget install Rojo.Rokit`, then `rokit self-install`.
2. In this folder run:

       rokit install
       wally install

3. In Roblox Studio install the Rojo plugin: `rojo plugin install`.
4. In VS Code install the recommended extensions (it will prompt you).

## Daily workflow

1. Open `Place1.rbxl` in Roblox Studio.
2. In this folder run `rojo serve`.
3. In Studio, open the Rojo plugin and click **Connect**.
4. Edit files under `src/` in VS Code. Changes appear in Studio immediately.
5. Playtest in Studio. Save the place in Studio (Ctrl+S) when you change the map.

## Layout

| Folder        | Synced to                                 |
| ------------- | ----------------------------------------- |
| `src/server`  | ServerScriptService/Server                |
| `src/client`  | StarterPlayer/StarterPlayerScripts/Client |
| `src/shared`  | ReplicatedStorage/Shared                  |
| `Packages`    | ReplicatedStorage/Packages (from Wally)   |

## How the game is wired

All numbers live in `src/shared/Config.luau`: click value, growth curve,
zones, upgrades, win multiplier.

Server (`src/server/Services`), started in order by `Main.server.luau`:

| Service          | Owns                                                                 |
| ---------------- | -------------------------------------------------------------------- |
| `StatService`    | Fire and Wins in leaderstats, FirePerClick and WinMultiplier attrs   |
| `UpgradeService` | Upgrade levels as `Upgrade_<Id>` attributes, buy requests            |
| `DataService`    | Load on join, save on leave, autosave, shutdown save                 |
| `ZoneService`    | Which zone each player stands in and the multiplier they earn there  |
| `ClickService`   | Click remote, rate limit, Fire = perClick x zone x wins              |
| `GrowthService`  | Dresses the character as a dragon and scales it with Fire            |
| `WinService`     | Win pad touch, reset, respawn, Won remote                            |

Client (`src/client`): `ClickInput` sends clicks and plays `FireEffects` at
once, `IceWalls` melts and refreezes walls locally, `Shop` buys upgrades,
`Hud` shows stats and the win banner, `CameraScale` zooms out as you grow.

The client is never trusted with numbers. It sends clicks and buy requests;
the server decides what they are worth. Walls are opened only on the client,
but the server grants a zone's multiplier from its own Fire check.

## Replacing placeholders

- **Map**: build a folder named `Map` in Workspace. Tag zone floors
  `ZoneFloor` with attribute `ZoneIndex`, tag walls `IceWall` with `ZoneIndex`
  and `RequiredFire` (optionally a BillboardGui `Sign` with TextLabel
  `Label`), tag the end pad `WinPad`, add a SpawnLocation. `DevMap` is then
  skipped.
- **Dragon**: `DragonCostume` welds placeholder wings, tail and horns to the
  avatar and adds `Head.Mouth` with a `Flame` emitter and `Glow` light.
  Replace the parts with meshes or accessories; the effects only need the
  Mouth attachment and its two children.
- **UI**: `Hud` and `Shop` are built in code and can be rebuilt in StarterGui
  reading the same leaderstats and attributes.

## Saving

`DataService` uses DataStoreService directly. In Studio, enable
**Game Settings > Security > Enable Studio Access to API Services** and
publish the place once, or saves are skipped with a warning in Output.

## Adding a package

    wally add <scope>/<name>   # or edit wally.toml
    wally install

## Formatting and linting

    stylua src
    selene src
