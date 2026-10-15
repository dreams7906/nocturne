# Installation

## Remote loading

In an environment that provides client-side `loadstring` and `game:HttpGet`:

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/dreams7906/nocturne/main/Nocturne.lua"))()
local Window = Library:CreateWindow({ Title = "Nocturne" })
```

Or run the complete demo:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/dreams7906/nocturne/main/RemoteExample.lua"))()
```

The bundle includes every module, so no ModuleScript installation is needed for remote loading. Normal Studio LocalScripts should use the ModuleScript setup below. Remote loading alone does not install the optional server persistence script.

## Studio (no tools)

1. In **ReplicatedStorage**, insert a **ModuleScript** named `Nocturne` and paste in all of `Nocturne.lua`.
2. In **StarterPlayer › StarterPlayerScripts**, insert a **LocalScript** and paste in `Example.lua`, or your own script that uses the library.
3. Optional: in **ServerScriptService**, insert a **Script** and paste in `server/ConfigPersistence.server.lua` for per-player config saves.
4. Press **Play**. The dock appears at the top centre, and **Right Ctrl** toggles the window.

To test DataStore saves in Studio, enable *Game Settings › Security › Enable Studio Access to API Services*.

## Rojo

```bash
rojo serve
```

`default.project.json` maps `src/Nocturne` to `ReplicatedStorage.Nocturne` and the persistence script to `ServerScriptService`. Add your own LocalScript (for example a copy of `Example.lua` renamed to `*.client.lua`) under `StarterPlayerScripts`.

## Updating the single file

After editing anything in `src/`, rebuild the bundle:

```bash
python tools/bundle.py
```

This also regenerates `RemoteExample.lua` from `Example.lua`. Upload both generated files when updating the repository.

## Requirements

- Roblox Studio (any current version). The library uses only standard engine APIs: TweenService, UserInputService, CanvasGroup, UIStroke, UIGradient and Font objects. It has no external dependencies and no uploaded assets.
- Python 3.9+ is needed only for the build, asset and test tools.
