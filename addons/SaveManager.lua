--[[
    SaveManager.lua  —  Helixia Addon
    Saves and loads all module toggle states and settings values
    using Roblox's DataStoreService (server-side) or a simple
    table cache for LocalScript use.

    Usage:
        local SaveManager = require(script.Parent.addons.SaveManager)
        SaveManager:Init(win)           -- pass your Helixia window
        SaveManager:SetAutoSave(true)   -- auto-save on every change
        SaveManager:Load()              -- load saved states on start
        SaveManager:Save()              -- manually save
]]

local SaveManager = {}
SaveManager.__index = SaveManager

-- ──────────────────────────────────────────────
-- Services
-- ──────────────────────────────────────────────
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ──────────────────────────────────────────────
-- Internal state
-- ──────────────────────────────────────────────
local _window      = nil
local _autoSave    = false
local _saveKey     = "Helixia_Save_v1"

-- We store config in a table keyed by "CategoryName.ModuleName"
-- Each entry holds: { enabled, settings = { label = value, ... } }
local _cache = {}

-- ──────────────────────────────────────────────
-- Helpers
-- ──────────────────────────────────────────────

-- Encode table to a compact JSON-like string (no external deps)
local function encode(tbl)
    local parts = {}
    for k, v in pairs(tbl) do
        local valStr
        if type(v) == "boolean" then
            valStr = v and "true" or "false"
        elseif type(v) == "number" then
            valStr = tostring(v)
        elseif type(v) == "string" then
            valStr = '"' .. v:gsub('"', '\\"') .. '"'
        else
            valStr = tostring(v)
        end
        table.insert(parts, '"' .. tostring(k) .. '":' .. valStr)
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

-- Persist to a folder in PlayerGui (survives respawn with ResetOnSpawn=false)
local function getStore()
    local gui = LocalPlayer:WaitForChild("PlayerGui")
    local folder = gui:FindFirstChild("HelixiaSaveStore")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "HelixiaSaveStore"
        folder.Parent = gui
    end
    return folder
end

local function writeToStore(data)
    local store = getStore()
    for key, val in pairs(data) do
        local sv = store:FindFirstChild(key)
        if not sv then
            sv = Instance.new("StringValue")
            sv.Name = key
            sv.Parent = store
        end
        sv.Value = encode(val)
    end
end

local function readFromStore()
    local store = getStore()
    local result = {}
    -- We can't fully decode our format without a parser,
    -- so we store booleans as StringValues and numbers as NumberValues.
    for _, child in ipairs(store:GetChildren()) do
        result[child.Name] = child.Value
    end
    return result
end

-- ──────────────────────────────────────────────
-- Public API
-- ──────────────────────────────────────────────

--- Initialize SaveManager with a Helixia window object.
--- Must be called before Save/Load.
function SaveManager:Init(win)
    _window = win
end

--- Enable or disable automatic saving whenever a module is toggled
--- or a setting value changes.
function SaveManager:SetAutoSave(enabled)
    _autoSave = enabled
    if enabled and _window then
        self:_hookAll()
    end
end

--- Collect current state of all modules into _cache, then persist.
function SaveManager:Save()
    if not _window then
        warn("[SaveManager] Call :Init(window) first.")
        return
    end

    _cache = {}

    for _, cat in ipairs(_window._categories) do
        for _, mod in ipairs(cat._modules) do
            local key = cat._name .. "." .. mod._name
            local entry = {
                enabled  = mod._enabled,
                settings = {},
            }
            for _, item in ipairs(mod._settings) do
                if item._type == "slider" or item._type == "textbox" then
                    entry.settings[item._label] = item._value
                elseif item._type == "checkbox" then
                    entry.settings[item._label] = item._value
                elseif item._type == "dropdown" then
                    entry.settings[item._label] = item._value
                elseif item._type == "mode" then
                    entry.settings[item._label] = item._index
                elseif item._type == "keybind" then
                    entry.settings[item._label] = item._value.Name
                end
            end
            _cache[key] = entry
        end
    end

    -- Persist using StringValues in PlayerGui folder
    local store = getStore()

    -- clear old values
    for _, child in ipairs(store:GetChildren()) do child:Destroy() end

    for key, entry in pairs(_cache) do
        -- enabled flag
        local sv = Instance.new("StringValue")
        sv.Name  = key .. "__enabled"
        sv.Value = tostring(entry.enabled)
        sv.Parent = store

        -- settings
        for label, val in pairs(entry.settings) do
            local sv2 = Instance.new("StringValue")
            sv2.Name  = key .. "__" .. label
            sv2.Value = tostring(val)
            sv2.Parent = store
        end
    end

    print("[SaveManager] Saved", #_window._allModules, "modules.")
end

--- Load previously saved state and apply it to all modules.
function SaveManager:Load()
    if not _window then
        warn("[SaveManager] Call :Init(window) first.")
        return
    end

    local store = getStore()
    if #store:GetChildren() == 0 then
        print("[SaveManager] No save data found.")
        return
    end

    -- Build lookup
    local data = {}
    for _, child in ipairs(store:GetChildren()) do
        data[child.Name] = child.Value
    end

    local loaded = 0
    for _, cat in ipairs(_window._categories) do
        for _, mod in ipairs(cat._modules) do
            local key = cat._name .. "." .. mod._name

            -- restore toggle
            local enabledVal = data[key .. "__enabled"]
            if enabledVal ~= nil then
                local on = (enabledVal == "true")
                if on ~= mod._enabled then
                    if on then mod:Enable() else mod:Disable() end
                end
            end

            -- restore settings
            for _, item in ipairs(mod._settings) do
                local savedVal = data[key .. "__" .. item._label]
                if savedVal ~= nil then
                    if item._type == "slider" then
                        local n = tonumber(savedVal)
                        if n then
                            item._value = math.clamp(n, item._min, item._max)
                            if item._callback then item._callback(item._value) end
                        end
                    elseif item._type == "checkbox" then
                        item._value = (savedVal == "true")
                        if item._callback then item._callback(item._value) end
                    elseif item._type == "dropdown" then
                        -- check option is still valid
                        for _, opt in ipairs(item._options) do
                            if opt == savedVal then
                                item._value = savedVal
                                if item._callback then item._callback(item._value) end
                                break
                            end
                        end
                    elseif item._type == "mode" then
                        local idx = tonumber(savedVal)
                        if idx and item._options[idx] then
                            item._index = idx
                            if item._callback then item._callback(item._options[idx]) end
                        end
                    elseif item._type == "keybind" then
                        local ok2, kc = pcall(function()
                            return Enum.KeyCode[savedVal]
                        end)
                        if ok2 and kc then
                            item._value = kc
                            if item._callback then item._callback(kc) end
                        end
                    elseif item._type == "textbox" then
                        item._value = savedVal
                        if item._callback then item._callback(savedVal) end
                    end
                end
            end

            loaded += 1
        end
    end

    print("[SaveManager] Loaded", loaded, "modules.")
end

--- Clear all saved data.
function SaveManager:Clear()
    local store = getStore()
    for _, child in ipairs(store:GetChildren()) do child:Destroy() end
    _cache = {}
    print("[SaveManager] Save data cleared.")
end

--- Internal: hook all existing modules for auto-save.
function SaveManager:_hookAll()
    if not _window then return end
    for _, cat in ipairs(_window._categories) do
        for _, mod in ipairs(cat._modules) do
            local original = mod._onToggle
            mod._onToggle = function(state)
                if original then original(state) end
                if _autoSave then SaveManager:Save() end
            end
            for _, item in ipairs(mod._settings) do
                local origCb = item._callback
                item._callback = function(val)
                    if origCb then origCb(val) end
                    if _autoSave then SaveManager:Save() end
                end
            end
        end
    end
end

return SaveManager
