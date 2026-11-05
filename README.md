# Dragon City Tycoon

Roblox game. Code lives in `src/` and is synced into Studio with Rojo.

## One-time setup

1. Install Rokit from https://github.com/rojo-rbx/rokit/releases (download the Windows zip, run `rokit self-install`).
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

| Folder        | Synced to                              |
| ------------- | -------------------------------------- |
| `src/server`  | ServerScriptService/Server             |
| `src/client`  | StarterPlayer/StarterPlayerScripts/Client |
| `src/shared`  | ReplicatedStorage/Shared               |
| `Packages`    | ReplicatedStorage/Packages (from Wally) |

## Adding a package

    wally add <scope>/<name>   # or edit wally.toml
    wally install

## Formatting and linting

    stylua src
    selene src
