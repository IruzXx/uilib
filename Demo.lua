--[[
    Demo.lua  —  Helixia LocalScript Example
    Place this as a LocalScript inside StarterPlayerScripts.
    Place UILibrary.lua as a ModuleScript next to it.

    Press RightShift to toggle the UI.
    Left-click a module  → toggle on/off
    Right-click a module → open its settings panel
]]

local Helixia = require(script.Parent.UILibrary)   -- adjust path as needed

local win = Helixia:CreateWindow({
    title    = "Helixia",
    subtitle = "v1.0  |  RightShift to toggle",
    key      = Enum.KeyCode.RightShift,
})

-- ──────────────────────────────────────────────
-- COMBAT
-- ──────────────────────────────────────────────
local combat = win:AddCategory("COMBAT")

local aimAssist = combat:AddModule("Aim Assist", { desc = "Smooth aim assistance." })
aimAssist:SetToggleCallback(function(on) print("Aim Assist:", on) end)
aimAssist:AddSlider("FOV",      { min=10,  max=360, default=90,  suffix="°", callback=function(v) print("FOV", v) end })
aimAssist:AddSlider("Smoothing",{ min=1,   max=20,  default=5,              callback=function(v) print("Smooth", v) end })
aimAssist:AddDropdown("Target", { options={"Closest","Health","Random"}, default="Closest", callback=function(v) print("Target:", v) end })
aimAssist:AddKeybind("Hold Key",{ default=Enum.KeyCode.C, callback=function(k) print("Key:", k) end })

local autoBlock = combat:AddModule("Auto Block")
autoBlock:SetToggleCallback(function(on) print("Auto Block:", on) end)

local hitbox = combat:AddModule("Hitbox Expander")
hitbox:SetToggleCallback(function(on) print("Hitbox:", on) end)
hitbox:AddSlider("Size", { min=1, max=20, default=4, callback=function(v) end })

local reach = combat:AddModule("Reach")
reach:AddSlider("Distance", { min=3, max=10, default=3, suffix="b", callback=function(v) end })
reach:AddCheckbox("Vertical",  { default=false, callback=function(v) end })

local triggerBot = combat:AddModule("Trigger Bot")
triggerBot:AddSlider("Delay (ms)", { min=0, max=500, default=100, suffix="ms", callback=function(v) end })

-- ──────────────────────────────────────────────
-- MOVEMENT
-- ──────────────────────────────────────────────
local movement = win:AddCategory("MOVEMENT")

local speed = movement:AddModule("Speed")
speed:SetToggleCallback(function(on) print("Speed:", on) end)
speed:AddMode("Mode",   { options={"Ground","Fly","Strafe"}, default="Ground", callback=function(v) print("SpeedMode:", v) end })
speed:AddSlider("Value",{ min=1, max=50, default=10, callback=function(v) end })

local fly = movement:AddModule("Fly")
fly:SetToggleCallback(function(on) print("Fly:", on) end)
fly:AddSlider("Speed", { min=1, max=100, default=20, callback=function(v) end })

local noFall = movement:AddModule("No Fall")
noFall:SetToggleCallback(function(on) print("NoFall:", on) end)

local bhop = movement:AddModule("BHop")
bhop:AddMode("Mode", { options={"Auto","Semi","Off"}, default="Auto", callback=function(v) end })
bhop:AddSlider("Chance %", { min=0, max=100, default=100, suffix="%", callback=function(v) end })

-- ──────────────────────────────────────────────
-- VISUAL
-- ──────────────────────────────────────────────
local visual = win:AddCategory("VISUAL")

local esp = visual:AddModule("Player ESP", { desc = "Renders player outlines and info." })
esp:SetToggleCallback(function(on) print("ESP:", on) end)
esp:AddCheckbox("Boxes",       { default=true,  callback=function(v) end })
esp:AddCheckbox("Names",       { default=true,  callback=function(v) end })
esp:AddCheckbox("Health Bars", { default=false, callback=function(v) end })
esp:AddSlider("Max Distance",  { min=10, max=5000, default=500, suffix="st", callback=function(v) end })

local chams = visual:AddModule("Chams")
chams:SetToggleCallback(function(on) print("Chams:", on) end)
chams:AddDropdown("Style", { options={"Flat","Shiny","Neon"}, default="Flat", callback=function(v) end })

local fullbright = visual:AddModule("Fullbright")
fullbright:SetToggleCallback(function(on) print("Fullbright:", on) end)
fullbright:AddSlider("Brightness", { min=1, max=10, default=5, callback=function(v)
    game:GetService("Lighting").Brightness = v
end })

-- ──────────────────────────────────────────────
-- MISC
-- ──────────────────────────────────────────────
local misc = win:AddCategory("MISC")

local autoRej = misc:AddModule("Auto Rejoin")
autoRej:SetToggleCallback(function(on) print("AutoRejoin:", on) end)
autoRej:AddSlider("Delay (s)", { min=1, max=30, default=5, suffix="s", callback=function(v) end })

local nameProt = misc:AddModule("Name Protect", { default=true })
nameProt:SetToggleCallback(function(on) print("NameProtect:", on) end)
nameProt:AddTextbox("Fake Name", { default="Player", placeholder="Enter name...", callback=function(t) print("Name:", t) end })

local webhook = misc:AddModule("Discord Webhook")
webhook:SetToggleCallback(function(on) print("Webhook:", on) end)
webhook:AddTextbox("URL", { default="", placeholder="https://discord.com/api/webhooks/...", callback=function(t) end })
webhook:AddCheckbox("Ping on Kill",  { default=false, callback=function(v) end })
webhook:AddCheckbox("Ping on Death", { default=false, callback=function(v) end })

-- ──────────────────────────────────────────────
-- SEARCH column (always add last)
-- ──────────────────────────────────────────────
win:AddSearchColumn()

-- ──────────────────────────────────────────────
-- SAVE MANAGER (optional addon)
-- ──────────────────────────────────────────────
local SaveManager = require(script.Parent.addons.SaveManager)
SaveManager:Init(win)
SaveManager:SetAutoSave(true)   -- save automatically on every change
SaveManager:Load()              -- load previous session on start

print("[Helixia] Loaded. Press RightShift to toggle.")
