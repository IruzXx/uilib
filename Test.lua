--[[
    Test.lua — Helixia UI Library Test Script
    Load ini di executor Roblox (Synapse, KRNL, dll.)
    Otomatis ambil library terbaru dari GitHub.
]]

local REPO = "https://raw.githubusercontent.com/IruzXx/uilib/main/"

-- ── Load library dari GitHub ──────────────────
local function fetch(path)
    return game:HttpGet(REPO .. path)
end

-- Load core
local UILibrary = loadstring(fetch("UILibrary.lua"))()

-- Load SaveManager
local SaveManager = loadstring(fetch("addons/SaveManager.lua"))()

-- ─────────────────────────────────────────────
-- Buat window
-- ─────────────────────────────────────────────
local win = UILibrary:CreateWindow({
    title    = "Helixia",
    subtitle = "Test Script  |  RightShift to toggle",
    key      = Enum.KeyCode.RightShift,
})

-- ─────────────────────────────────────────────
-- TEST: Semua komponen UI
-- ─────────────────────────────────────────────

-- ── CATEGORY 1: Toggle & Slider ───────────────
local cat1 = win:AddCategory("TOGGLES")

local mod1 = cat1:AddModule("Basic Toggle", { desc = "Test toggle on/off." })
mod1:SetToggleCallback(function(on)
    print("[TEST] Basic Toggle:", on)
end)

local mod2 = cat1:AddModule("With Slider", { desc = "Test slider." })
mod2:SetToggleCallback(function(on) print("[TEST] With Slider:", on) end)
mod2:AddSlider("Speed", {
    min      = 1,
    max      = 100,
    default  = 16,
    suffix   = " st/s",
    callback = function(v) print("[TEST] Slider value:", v) end,
})
mod2:AddSlider("FOV", {
    min      = 10,
    max      = 360,
    default  = 90,
    suffix   = "°",
    callback = function(v) print("[TEST] FOV:", v) end,
})

local mod3 = cat1:AddModule("Default ON", { default = true, desc = "Starts enabled." })
mod3:SetToggleCallback(function(on) print("[TEST] Default ON now:", on) end)

-- ── CATEGORY 2: Checkbox & Dropdown ──────────
local cat2 = win:AddCategory("INPUTS")

local mod4 = cat2:AddModule("Checkboxes", { desc = "Test checkbox items." })
mod4:AddCheckbox("Option A", {
    default  = true,
    callback = function(v) print("[TEST] Checkbox A:", v) end,
})
mod4:AddCheckbox("Option B", {
    default  = false,
    callback = function(v) print("[TEST] Checkbox B:", v) end,
})
mod4:AddCheckbox("Option C", {
    default  = false,
    callback = function(v) print("[TEST] Checkbox C:", v) end,
})

local mod5 = cat2:AddModule("Dropdown", { desc = "Test dropdown menu." })
mod5:AddDropdown("Mode", {
    options  = { "Closest", "Health", "Distance", "Random" },
    default  = "Closest",
    callback = function(v) print("[TEST] Dropdown selected:", v) end,
})

local mod6 = cat2:AddModule("Mode Cycler", { desc = "Click value to cycle." })
mod6:AddMode("Style", {
    options  = { "Ground", "Fly", "Strafe", "Noclip" },
    default  = "Ground",
    callback = function(v) print("[TEST] Mode:", v) end,
})

-- ── CATEGORY 3: Keybind & Textbox ────────────
local cat3 = win:AddCategory("ADVANCED")

local mod7 = cat3:AddModule("Keybind Test", { desc = "Click button then press a key." })
mod7:AddKeybind("Activate Key", {
    default  = Enum.KeyCode.F,
    callback = function(k) print("[TEST] Keybind set to:", k.Name) end,
})

local mod8 = cat3:AddModule("Textbox Test", { desc = "Type in the box." })
mod8:AddTextbox("Webhook URL", {
    default     = "",
    placeholder = "https://discord.com/api/webhooks/...",
    callback    = function(t) print("[TEST] Textbox input:", t) end,
})
mod8:AddTextbox("Custom Name", {
    default     = "Player",
    placeholder = "Enter name...",
    callback    = function(t) print("[TEST] Name:", t) end,
})

-- ── CATEGORY 4: Mixed (real world example) ───
local cat4 = win:AddCategory("COMBAT")

local aimAssist = cat4:AddModule("Aim Assist", { desc = "Silent aim with FOV circle." })
aimAssist:SetToggleCallback(function(on) print("[TEST] Aim Assist:", on) end)
aimAssist:AddSlider("FOV",       { min=10,  max=360, default=90,  suffix="°",   callback=function(v) end })
aimAssist:AddSlider("Smoothing", { min=1,   max=20,  default=5,                 callback=function(v) end })
aimAssist:AddDropdown("Target",  { options={"Closest","Health","Random"}, default="Closest", callback=function(v) end })
aimAssist:AddCheckbox("Silent",  { default=false, callback=function(v) end })
aimAssist:AddKeybind("Hold",     { default=Enum.KeyCode.C, callback=function(k) end })

local reach = cat4:AddModule("Reach")
reach:SetToggleCallback(function(on) print("[TEST] Reach:", on) end)
reach:AddSlider("Distance", { min=3, max=10, default=3, suffix=" b", callback=function(v) end })
reach:AddCheckbox("Vertical", { default=false, callback=function(v) end })

local trigBot = cat4:AddModule("Trigger Bot")
trigBot:AddSlider("Delay", { min=0, max=500, default=100, suffix=" ms", callback=function(v) end })
trigBot:AddDropdown("Condition", { options={"Always","Enemy Only","Sword Only"}, default="Enemy Only", callback=function(v) end })

-- ── CATEGORY 5: Separator test ───────────────
local cat5 = win:AddCategory("VISUAL")

local espMod = cat5:AddModule("Player ESP", { desc = "Draw boxes and names on players." })
espMod:SetToggleCallback(function(on) print("[TEST] ESP:", on) end)
espMod:AddSeparator("Box Options")
espMod:AddCheckbox("Box",        { default=true,  callback=function(v) end })
espMod:AddCheckbox("Filled Box", { default=false, callback=function(v) end })
espMod:AddSeparator("Name Options")
espMod:AddCheckbox("Name",       { default=true,  callback=function(v) end })
espMod:AddCheckbox("Distance",   { default=false, callback=function(v) end })
espMod:AddSeparator("Range")
espMod:AddSlider("Max Dist", { min=10, max=5000, default=500, suffix=" st", callback=function(v) end })

-- ── SEARCH (always last) ──────────────────────
win:AddSearchColumn()

-- ─────────────────────────────────────────────
-- SaveManager test
-- ─────────────────────────────────────────────
SaveManager:Init(win)
SaveManager:SetAutoSave(true)
SaveManager:Load()

-- ─────────────────────────────────────────────
-- Console log ringkasan
-- ─────────────────────────────────────────────
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print(" Helixia UI Library — Test Loaded")
print(" Modules:", #win._allModules)
print(" Categories:", #win._categories)
print(" RightShift → toggle UI")
print(" Left Click → toggle module")
print(" Right Click → open settings")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
