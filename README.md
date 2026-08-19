# Helixia UI Library

A clean, dark-themed module menu UI library for Roblox — inspired by Minecraft client HUDs.

> Left-click a module to toggle it. Right-click to open its settings panel.

---

## Preview

![Helixia Preview](assets/preview.png)

---

## Features

- **Category columns** — organize modules into groups
- **Toggle** — left-click any module to enable/disable
- **Settings panel** — right-click any module to open its config
- **Slider** — numeric value with drag support
- **Checkbox** — simple true/false toggle
- **Dropdown** — pick one option from a list
- **Mode** — cycle through options on click
- **Keybind** — click and press any key to bind
- **Textbox** — free text input
- **Search column** — filter modules by name in real time
- **Draggable** — drag by the title bar
- **Open/close keybind** — default `RightShift`, fully configurable
- **SaveManager** — save and load all module states automatically

---

## Installation

### Option A — Copy file directly
1. Copy `Helixia.lua` (rename from `UILibrary.lua`) into your Roblox project as a **ModuleScript**
2. Copy `addons/SaveManager.lua` as a **ModuleScript** inside the same folder (optional)
3. Add `Demo.lua` as a **LocalScript** in `StarterPlayerScripts`

### Option B — Wally (package manager)
```toml
[dependencies]
Helixia = "yourusername/helixia@1.0.0"
```

---

## Basic Usage

```lua
local Helixia = require(script.Parent.UILibrary)

local win = Helixia:CreateWindow({
    title    = "Helixia",
    subtitle = "v1.0",
    key      = Enum.KeyCode.RightShift,
})

local combat = win:AddCategory("COMBAT")

local aimAssist = combat:AddModule("Aim Assist", { desc = "Smooth aim assistance." })
aimAssist:SetToggleCallback(function(on)
    print("Aim Assist:", on)
end)
aimAssist:AddSlider("FOV", {
    min      = 10,
    max      = 360,
    default  = 90,
    suffix   = "°",
    callback = function(v) print("FOV:", v) end,
})
aimAssist:AddDropdown("Target", {
    options  = { "Closest", "Health", "Random" },
    default  = "Closest",
    callback = function(v) print("Target:", v) end,
})
aimAssist:AddKeybind("Hold Key", {
    default  = Enum.KeyCode.C,
    callback = function(k) print("Key:", k) end,
})

win:AddSearchColumn()  -- always add last
```

---

## API Reference

### `Helixia:CreateWindow(opts)`
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | string | `"Helixia"` | Large name shown in the title bar |
| `subtitle` | string | `""` | Small text below the title |
| `key` | KeyCode | `RightShift` | Keybind to show/hide the window |

---

### `win:AddCategory(name)` → Category
Creates a new column with the given name.

### `win:AddSearchColumn()` → Category
Adds a search column. Call this **last**, after all categories.

---

### `category:AddModule(name, opts)` → Module
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `desc` | string | `""` | Description shown in the settings panel |
| `default` | bool | `false` | Initial toggle state |

---

### Module methods

| Method | Description |
|--------|-------------|
| `mod:SetToggleCallback(fn)` | Called with `true`/`false` when toggled |
| `mod:SetDesc(text)` | Set description text |
| `mod:Enable()` / `mod:Disable()` | Force enable or disable |
| `mod:IsEnabled()` | Returns current state |

### Settings items

```lua
mod:AddSlider(label, { min, max, default, suffix, callback })
mod:AddCheckbox(label, { default, callback })
mod:AddDropdown(label, { options, default, callback })
mod:AddMode(label, { options, default, callback })
mod:AddKeybind(label, { default, callback })
mod:AddTextbox(label, { default, placeholder, callback })
mod:AddSeparator(label)
```

---

### SaveManager (addon)

```lua
local SaveManager = require(script.Parent.addons.SaveManager)
SaveManager:Init(win)          -- pass your window object
SaveManager:Save()             -- save all states
SaveManager:Load()             -- load all states
SaveManager:SetAutoSave(true)  -- auto-save on every change
```

---

## File Structure

```
Helixia-LIBRARY/
├── UILibrary.lua        ← core library (require this)
├── addons/
│   └── SaveManager.lua  ← optional: save/load module states
├── Demo.lua             ← example LocalScript
├── README.md
├── LICENSE
└── .gitignore
```

---

## License

MIT — see [LICENSE](LICENSE) for details.
