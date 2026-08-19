--[[
    Helixia.lua  (UILibrary.lua)
    Roblox Module Menu UI Library — by Helixia

    Usage:
        local Helixia = require(path.to.UILibrary)
        local win     = Helixia:CreateWindow({ title = "Helixia", key = Enum.KeyCode.RightShift })
        local cat     = win:AddCategory("COMBAT")
        local mod     = cat:AddModule("Aimbot")
        mod:SetToggleCallback(function(state) print("Aimbot:", state) end)
        mod:AddSlider("FOV", { min=1, max=360, default=90, callback=function(v) end })
        mod:AddDropdown("Mode", { options={"Closest","Health"}, default="Closest", callback=function(v) end })
        mod:AddCheckbox("Silent", { default=false, callback=function(v) end })
        mod:AddKeybind("Key", { default=Enum.KeyCode.V, callback=function(k) end })
        mod:AddTextbox("Value", { default="100", callback=function(t) end })
]]

local UILibrary = {}
UILibrary.__index = UILibrary

-- ──────────────────────────────────────────────
-- Services
-- ──────────────────────────────────────────────
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- ──────────────────────────────────────────────
-- Theme
-- ──────────────────────────────────────────────
local T = {
    BG          = Color3.fromRGB(18,  18,  20),   -- main background
    ColHeader   = Color3.fromRGB(24,  24,  28),   -- category header bar
    ColBody     = Color3.fromRGB(20,  20,  24),   -- category body
    ModNormal   = Color3.fromRGB(20,  20,  24),   -- module row default
    ModHover    = Color3.fromRGB(28,  28,  34),   -- module row hover
    ModActive   = Color3.fromRGB(22,  40,  60),   -- module row selected (settings open)
    Accent      = Color3.fromRGB(0,   140, 255),  -- blue accent (toggles, sliders)
    AccentDim   = Color3.fromRGB(0,    80, 160),  -- dimmed accent
    ToggleOff   = Color3.fromRGB(55,  55,  65),   -- toggle off indicator
    TextPrimary = Color3.fromRGB(220, 220, 230),  -- normal text
    TextDim     = Color3.fromRGB(130, 130, 150),  -- dim text / labels
    TextAccent  = Color3.fromRGB(80,  180, 255),  -- highlighted text
    Separator   = Color3.fromRGB(35,  35,  45),   -- thin divider lines
    SettingsBG  = Color3.fromRGB(15,  15,  18),   -- settings panel bg
    SliderFill  = Color3.fromRGB(0,   140, 255),
    SliderBG    = Color3.fromRGB(35,  35,  50),
    InputBG     = Color3.fromRGB(28,  28,  36),
    Shadow      = Color3.fromRGB(0,    0,   0),
    Font        = Enum.Font.Code,
    FontBold    = Enum.Font.GothamBold,
    FontMono    = Enum.Font.Code,
}

-- ──────────────────────────────────────────────
-- Helpers
-- ──────────────────────────────────────────────
local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function tween(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad), props):Play()
end

local function stroke(parent, color, thickness)
    return make("UIStroke", {
        Color     = color or T.Separator,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function corner(parent, radius)
    return make("UICorner", { CornerRadius = UDim.new(0, radius or 4) }, parent)
end

local function pad(parent, top, right, bottom, left)
    return make("UIPadding", {
        PaddingTop    = UDim.new(0, top    or 4),
        PaddingRight  = UDim.new(0, right  or 6),
        PaddingBottom = UDim.new(0, bottom or 4),
        PaddingLeft   = UDim.new(0, left   or 6),
    }, parent)
end

-- ──────────────────────────────────────────────
-- Constants
-- ──────────────────────────────────────────────
local COL_WIDTH      = 160   -- px width of each category column
local COL_HEADER_H   = 26    -- px height of category header
local MODULE_H       = 22    -- px height of each module row
local MODULE_PADDING = 2     -- gap between rows
local SETTINGS_W     = 220   -- px width of settings panel
local SETTINGS_ITEM  = 26    -- px height of each settings item
local SEARCH_W       = 160
local TOGGLE_SIZE    = 10    -- toggle dot size

-- ──────────────────────────────────────────────────────────────
-- Library entry point
-- ──────────────────────────────────────────────────────────────
function UILibrary:CreateWindow(opts)
    opts = opts or {}
    local title   = opts.title   or "Helixia"
    local subtitle = opts.subtitle or ""
    local openKey = opts.key     or Enum.KeyCode.RightShift

    -- ── ScreenGui ──────────────────────────────
    local screenGui = make("ScreenGui", {
        Name             = "Helixia_" .. title,
        ResetOnSpawn     = false,
        ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset   = true,
    })

    -- try CoreGui, fall back to PlayerGui
    local ok = pcall(function()
        screenGui.Parent = game:GetService("CoreGui")
    end)
    if not ok then
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- ── Root container (draggable) ───────────────
    local root = make("Frame", {
        Name             = "Root",
        BackgroundColor3 = T.BG,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.5, -400, 0.5, -250),
        Size             = UDim2.new(0, 100, 0, 300),
        ClipsDescendants = false,
        AutomaticSize    = Enum.AutomaticSize.XY,
    }, screenGui)
    corner(root, 6)
    stroke(root, T.Separator, 1)

    -- drop shadow
    make("ImageLabel", {
        Name              = "Shadow",
        BackgroundTransparency = 1,
        Image             = "rbxassetid://6014261993",
        ImageColor3       = T.Shadow,
        ImageTransparency = 0.5,
        Position          = UDim2.new(0, -15, 0, -15),
        Size              = UDim2.new(1, 30, 1, 30),
        SliceCenter       = Rect.new(49, 49, 450, 450),
        ScaleType         = Enum.ScaleType.Slice,
        ZIndex            = -1,
    }, root)

    -- ── TOP TITLE BAR ─────────────────────────
    -- Full-width bar above all columns that shows "HELIXIA" in large text
    local TITLEBAR_H = 36
    local titleBar = make("Frame", {
        Name             = "TitleBar",
        BackgroundColor3 = Color3.fromRGB(10, 10, 13),
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, TITLEBAR_H),
        ZIndex           = 5,
    }, root)

    -- left accent stripe
    make("Frame", {
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 3, 1, 0),
    }, titleBar)

    -- big client name
    make("TextLabel", {
        BackgroundTransparency = 1,
        Position   = UDim2.new(0, 12, 0, 0),
        Size       = UDim2.new(0, 200, 1, 0),
        Text       = string.upper(title),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize   = 20,
        Font       = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex     = 6,
    }, titleBar)

    -- version / subtitle tag
    if subtitle ~= "" then
        make("TextLabel", {
            BackgroundTransparency = 1,
            Position   = UDim2.new(0, 12, 0, 22),
            Size       = UDim2.new(0, 200, 0, 12),
            Text       = subtitle,
            TextColor3 = T.TextDim,
            TextSize   = 9,
            Font       = T.Font,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex     = 6,
        }, titleBar)
    end

    -- close button [X]
    local closeBtn = make("TextButton", {
        BackgroundTransparency = 1,
        Position   = UDim2.new(1, -28, 0, 0),
        Size       = UDim2.new(0, 28, 1, 0),
        Text       = "✕",
        TextColor3 = T.TextDim,
        TextSize   = 13,
        Font       = T.FontBold,
        ZIndex     = 6,
    }, titleBar)
    closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = Color3.fromRGB(255,80,80) end)
    closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = T.TextDim end)
    closeBtn.MouseButton1Click:Connect(function()
        root.Visible = false
    end)

    -- bottom accent line on title bar
    make("Frame", {
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 1, -1),
        Size             = UDim2.new(1, 0, 0, 1),
        ZIndex           = 5,
    }, titleBar)

    -- ── Column container (horizontal layout) ────
    -- pushed down by TITLEBAR_H
    local colContainer = make("Frame", {
        Name             = "Columns",
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 0, 0, TITLEBAR_H),
        Size             = UDim2.new(0, 100, 0, 100),
        AutomaticSize    = Enum.AutomaticSize.XY,
    }, root)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder     = Enum.SortOrder.LayoutOrder,
        Padding       = UDim.new(0, 1),
    }, colContainer)

    -- ── Settings panel (appended after columns) ──
    local settingsPanel = make("Frame", {
        Name            = "SettingsPanel",
        BackgroundColor3 = T.SettingsBG,
        BorderSizePixel = 0,
        Size            = UDim2.new(0, SETTINGS_W, 0, 300),
        Visible         = false,
        AutomaticSize   = Enum.AutomaticSize.Y,
        LayoutOrder     = 9999,
    }, colContainer)
    corner(settingsPanel, 4)
    stroke(settingsPanel, T.Accent, 1)

    local settingsTitleBar = make("Frame", {
        Name            = "TitleBar",
        BackgroundColor3 = T.ColHeader,
        BorderSizePixel = 0,
        Size            = UDim2.new(1, 0, 0, COL_HEADER_H),
    }, settingsPanel)
    corner(settingsTitleBar, 4)

    local settingsTitleLabel = make("TextLabel", {
        Name            = "Title",
        BackgroundTransparency = 1,
        Size            = UDim2.new(1, -8, 1, 0),
        Position        = UDim2.new(0, 8, 0, 0),
        Text            = "",
        TextColor3      = T.TextAccent,
        TextSize        = 11,
        Font            = T.FontBold,
        TextXAlignment  = Enum.TextXAlignment.Left,
        TextTruncate    = Enum.TextTruncate.AtEnd,
    }, settingsTitleBar)

    local settingsDesc = make("TextLabel", {
        Name            = "Desc",
        BackgroundTransparency = 1,
        Size            = UDim2.new(1, -16, 0, 18),
        Position        = UDim2.new(0, 8, 0, COL_HEADER_H + 2),
        Text            = "",
        TextColor3      = T.TextDim,
        TextSize        = 10,
        Font            = T.Font,
        TextXAlignment  = Enum.TextXAlignment.Left,
        TextWrapped     = true,
    }, settingsPanel)

    local settingsScroll = make("ScrollingFrame", {
        Name                 = "Scroll",
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Position             = UDim2.new(0, 0, 0, COL_HEADER_H + 22),
        Size                 = UDim2.new(1, 0, 0, 0),
        AutomaticSize        = Enum.AutomaticSize.Y,
        ScrollBarThickness   = 2,
        ScrollBarImageColor3 = T.Accent,
        CanvasSize           = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize  = Enum.AutomaticSize.Y,
    }, settingsPanel)

    make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 0),
    }, settingsScroll)

    pad(settingsScroll, 4, 8, 8, 8)

    -- ──────────────────────────────────────────
    -- Window object
    -- ──────────────────────────────────────────
    local Window = {}
    Window._root           = root
    Window._colContainer   = colContainer
    Window._settingsPanel  = settingsPanel
    Window._settingsTitle  = settingsTitleLabel
    Window._settingsDesc   = settingsDesc
    Window._settingsScroll = settingsScroll
    Window._categories     = {}
    Window._allModules     = {}  -- flat list for search
    Window._activeModule   = nil
    Window._visible        = true

    -- ── Open / close toggle ────────────────────
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == openKey then
            Window._visible = not Window._visible
            root.Visible    = Window._visible
        end
    end)

    -- ── Dragging (via title bar) ──────────────
    do
        local dragging, dragStart, startPos
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging  = true
                dragStart = input.Position
                startPos  = root.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                root.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
    end

    -- ── Settings panel builder ─────────────────
    local function openSettings(mod)
        -- clear old items
        for _, c in ipairs(settingsScroll:GetChildren()) do
            if c:IsA("GuiObject") and c.Name ~= "UIListLayout" and c.Name ~= "UIPadding" then
                c:Destroy()
            end
        end

        settingsTitleLabel.Text = mod._name
        settingsDesc.Text       = mod._desc or ""
        settingsPanel.Visible   = true

        -- build items
        for _, item in ipairs(mod._settings) do
            item._buildFn(settingsScroll, item)
        end
    end

    local function closeSettings()
        settingsPanel.Visible = false
        if Window._activeModule then
            Window._activeModule._row.BackgroundColor3 = T.ModNormal
            Window._activeModule = nil
        end
    end

    Window._openSettings  = openSettings
    Window._closeSettings = closeSettings

    -- ──────────────────────────────────────────
    -- AddCategory
    -- ──────────────────────────────────────────
    function Window:AddCategory(name)
        local Category = {}
        Category._name    = name
        Category._modules = {}
        Category._window  = self

        -- column frame
        local col = make("Frame", {
            Name            = "Cat_" .. name,
            BackgroundColor3 = T.ColBody,
            BorderSizePixel = 0,
            Size            = UDim2.new(0, COL_WIDTH, 0, 0),
            AutomaticSize   = Enum.AutomaticSize.Y,
            LayoutOrder     = #self._categories + 1,
        }, colContainer)

        -- header
        local header = make("Frame", {
            Name            = "Header",
            BackgroundColor3 = T.ColHeader,
            BorderSizePixel = 0,
            Size            = UDim2.new(1, 0, 0, COL_HEADER_H),
        }, col)

        -- header icon + name
        make("TextLabel", {
            Name           = "Title",
            BackgroundTransparency = 1,
            Size           = UDim2.new(1, -10, 1, 0),
            Position       = UDim2.new(0, 8, 0, 0),
            Text           = "☰ " .. name,
            TextColor3     = T.TextAccent,
            TextSize       = 11,
            Font           = T.FontBold,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, header)

        -- separator line under header
        make("Frame", {
            Name            = "Sep",
            BackgroundColor3 = T.Accent,
            BorderSizePixel = 0,
            Position        = UDim2.new(0, 0, 1, -1),
            Size            = UDim2.new(1, 0, 0, 1),
        }, header)

        -- module list frame
        local modList = make("Frame", {
            Name            = "ModList",
            BackgroundTransparency = 1,
            Position        = UDim2.new(0, 0, 0, COL_HEADER_H),
            Size            = UDim2.new(1, 0, 0, 0),
            AutomaticSize   = Enum.AutomaticSize.Y,
        }, col)
        make("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, MODULE_PADDING),
        }, modList)
        pad(modList, 3, 0, 3, 0)

        Category._col     = col
        Category._modList = modList

        table.insert(self._categories, Category)

        -- ──────────────────────────────────────
        -- AddModule
        -- ──────────────────────────────────────
        function Category:AddModule(modName, opts)
            opts = opts or {}
            local Module = {}
            Module._name     = modName
            Module._desc     = opts.desc or ""
            Module._enabled  = opts.default or false
            Module._settings = {}
            Module._category = self
            Module._window   = self._window
            Module._onToggle = nil

            -- row frame
            local row = make("Frame", {
                Name            = "Mod_" .. modName,
                BackgroundColor3 = T.ModNormal,
                BorderSizePixel = 0,
                Size            = UDim2.new(1, 0, 0, MODULE_H),
                LayoutOrder     = #self._modules + 1,
            }, modList)

            -- hover effect
            local rowBtn = make("TextButton", {
                Name               = "Btn",
                BackgroundTransparency = 1,
                Size               = UDim2.new(1, 0, 1, 0),
                Text               = "",
                ZIndex             = 2,
            }, row)

            -- module name label
            local nameLabel = make("TextLabel", {
                Name            = "Name",
                BackgroundTransparency = 1,
                Position        = UDim2.new(0, 8, 0, 0),
                Size            = UDim2.new(1, -30, 1, 0),
                Text            = modName,
                TextColor3      = T.TextPrimary,
                TextSize        = 11,
                Font            = T.Font,
                TextXAlignment  = Enum.TextXAlignment.Left,
                TextTruncate    = Enum.TextTruncate.AtEnd,
            }, row)

            -- toggle indicator (small circle on right)
            local toggleDot = make("Frame", {
                Name            = "ToggleDot",
                BackgroundColor3 = T.ToggleOff,
                BorderSizePixel = 0,
                Position        = UDim2.new(1, -(TOGGLE_SIZE + 6), 0.5, -(TOGGLE_SIZE / 2)),
                Size            = UDim2.new(0, TOGGLE_SIZE, 0, TOGGLE_SIZE),
                ZIndex          = 3,
            }, row)
            corner(toggleDot, 10)

            -- right-click to open settings; left-click to toggle
            local function refreshToggle()
                local col = Module._enabled and T.Accent or T.ToggleOff
                tween(toggleDot, 0.15, { BackgroundColor3 = col })
                nameLabel.TextColor3 = Module._enabled and T.TextAccent or T.TextPrimary
            end

            rowBtn.MouseButton1Click:Connect(function()
                -- toggle on/off
                Module._enabled = not Module._enabled
                refreshToggle()
                if Module._onToggle then
                    Module._onToggle(Module._enabled)
                end
            end)

            rowBtn.MouseButton2Click:Connect(function()
                -- open settings panel
                if Module._window._activeModule == Module then
                    Module._window._closeSettings()
                    row.BackgroundColor3 = T.ModNormal
                else
                    if Module._window._activeModule then
                        Module._window._activeModule._row.BackgroundColor3 = T.ModNormal
                    end
                    Module._window._activeModule = Module
                    row.BackgroundColor3 = T.ModActive
                    Module._window._openSettings(Module)
                end
            end)

            -- hover
            rowBtn.MouseEnter:Connect(function()
                if Module._window._activeModule ~= Module then
                    tween(row, 0.08, { BackgroundColor3 = T.ModHover })
                end
            end)
            rowBtn.MouseLeave:Connect(function()
                if Module._window._activeModule ~= Module then
                    tween(row, 0.08, { BackgroundColor3 = T.ModNormal })
                end
            end)

            Module._row       = row
            Module._nameLabel = nameLabel
            Module._toggleDot = toggleDot

            refreshToggle()

            table.insert(self._modules, Module)
            table.insert(self._window._allModules, Module)

            -- ── SetToggleCallback ──────────────
            function Module:SetToggleCallback(fn)
                self._onToggle = fn
            end

            -- ── SetDesc ───────────────────────
            function Module:SetDesc(text)
                self._desc = text
            end

            -- ── Enable / Disable ──────────────
            function Module:Enable()
                self._enabled = true
                refreshToggle()
                if self._onToggle then self._onToggle(true) end
            end

            function Module:Disable()
                self._enabled = false
                refreshToggle()
                if self._onToggle then self._onToggle(false) end
            end

            function Module:IsEnabled()
                return self._enabled
            end

            -- ────────────────────────────────────────────────────────
            -- Settings items
            -- ────────────────────────────────────────────────────────

            -- ── SEPARATOR (label row) ─────────
            function Module:AddSeparator(labelText)
                local item = { _type = "separator", _label = labelText or "" }
                item._buildFn = function(parent, _item)
                    local f = make("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 18),
                        LayoutOrder = #parent:GetChildren(),
                    }, parent)
                    make("TextLabel", {
                        BackgroundTransparency = 1,
                        Size     = UDim2.new(1, 0, 1, 0),
                        Text     = string.upper(_item._label),
                        TextColor3 = T.TextDim,
                        TextSize = 9,
                        Font     = T.FontBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }, f)
                    make("Frame", {
                        BackgroundColor3 = T.Separator,
                        BorderSizePixel  = 0,
                        Position = UDim2.new(0, 0, 1, -1),
                        Size     = UDim2.new(1, 0, 0, 1),
                    }, f)
                end
                table.insert(self._settings, item)
                return item
            end

            -- ── SLIDER ────────────────────────
            function Module:AddSlider(label, opts)
                opts = opts or {}
                local item = {
                    _type     = "slider",
                    _label    = label,
                    _min      = opts.min      or 0,
                    _max      = opts.max      or 100,
                    _value    = opts.default  or opts.min or 0,
                    _callback = opts.callback or function() end,
                    _suffix   = opts.suffix   or "",
                }
                item._buildFn = function(parent, _item)
                    local container = make("Frame", {
                        BackgroundTransparency = 1,
                        Size        = UDim2.new(1, 0, 0, SETTINGS_ITEM + 6),
                        LayoutOrder = #parent:GetChildren(),
                    }, parent)

                    -- label + value
                    local topRow = make("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 14),
                    }, container)
                    make("TextLabel", {
                        BackgroundTransparency = 1,
                        Size     = UDim2.new(0.65, 0, 1, 0),
                        Text     = string.upper(_item._label),
                        TextColor3 = T.TextPrimary,
                        TextSize = 10,
                        Font     = T.Font,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }, topRow)
                    local valLabel = make("TextLabel", {
                        BackgroundTransparency = 1,
                        Size     = UDim2.new(0.35, 0, 1, 0),
                        Position = UDim2.new(0.65, 0, 0, 0),
                        Text     = tostring(_item._value) .. _item._suffix,
                        TextColor3 = T.TextAccent,
                        TextSize = 10,
                        Font     = T.FontBold,
                        TextXAlignment = Enum.TextXAlignment.Right,
                    }, topRow)

                    -- track
                    local track = make("Frame", {
                        BackgroundColor3 = T.SliderBG,
                        BorderSizePixel  = 0,
                        Position = UDim2.new(0, 0, 0, 18),
                        Size     = UDim2.new(1, 0, 0, 4),
                    }, container)
                    corner(track, 4)

                    local pct = (_item._value - _item._min) / (_item._max - _item._min)
                    local fill = make("Frame", {
                        BackgroundColor3 = T.SliderFill,
                        BorderSizePixel  = 0,
                        Size             = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0),
                    }, track)
                    corner(fill, 4)

                    -- handle
                    local handle = make("Frame", {
                        BackgroundColor3 = Color3.fromRGB(255,255,255),
                        BorderSizePixel  = 0,
                        AnchorPoint      = Vector2.new(0.5, 0.5),
                        Position         = UDim2.new(math.clamp(pct,0,1), 0, 0.5, 0),
                        Size             = UDim2.new(0, 8, 0, 8),
                        ZIndex           = 2,
                    }, track)
                    corner(handle, 10)

                    -- drag logic
                    local draggingSlider = false
                    local function updateSlider(absX)
                        local tAbs  = track.AbsolutePosition.X
                        local tSize = track.AbsoluteSize.X
                        local t2    = math.clamp((absX - tAbs) / tSize, 0, 1)
                        local val   = math.floor(_item._min + t2 * (_item._max - _item._min) + 0.5)
                        _item._value = val
                        valLabel.Text = tostring(val) .. _item._suffix
                        fill.Size     = UDim2.new(t2, 0, 1, 0)
                        handle.Position = UDim2.new(t2, 0, 0.5, 0)
                        _item._callback(val)
                    end

                    track.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            draggingSlider = true
                            updateSlider(inp.Position.X)
                        end
                    end)
                    UserInputService.InputChanged:Connect(function(inp)
                        if draggingSlider and inp.UserInputType == Enum.UserInputType.MouseMovement then
                            updateSlider(inp.Position.X)
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            draggingSlider = false
                        end
                    end)
                end

                table.insert(self._settings, item)
                return item
            end

            -- ── CHECKBOX ──────────────────────
            function Module:AddCheckbox(label, opts)
                opts = opts or {}
                local item = {
                    _type     = "checkbox",
                    _label    = label,
                    _value    = opts.default  or false,
                    _callback = opts.callback or function() end,
                }
                item._buildFn = function(parent, _item)
                    local row2 = make("TextButton", {
                        BackgroundTransparency = 1,
                        Size        = UDim2.new(1, 0, 0, SETTINGS_ITEM),
                        Text        = "",
                        LayoutOrder = #parent:GetChildren(),
                    }, parent)

                    local box = make("Frame", {
                        BackgroundColor3 = _item._value and T.Accent or T.ToggleOff,
                        BorderSizePixel  = 0,
                        Position         = UDim2.new(0, 0, 0.5, -6),
                        Size             = UDim2.new(0, 12, 0, 12),
                    }, row2)
                    corner(box, 2)
                    stroke(box, T.Accent, 1)

                    local checkmark = make("TextLabel", {
                        BackgroundTransparency = 1,
                        Size     = UDim2.new(1, 0, 1, 0),
                        Text     = _item._value and "✓" or "",
                        TextColor3 = Color3.fromRGB(255,255,255),
                        TextSize = 9,
                        Font     = T.FontBold,
                    }, box)

                    make("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 18, 0, 0),
                        Size     = UDim2.new(1, -18, 1, 0),
                        Text     = _item._label,
                        TextColor3 = T.TextPrimary,
                        TextSize = 10,
                        Font     = T.Font,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }, row2)

                    row2.MouseButton1Click:Connect(function()
                        _item._value = not _item._value
                        box.BackgroundColor3 = _item._value and T.Accent or T.ToggleOff
                        checkmark.Text = _item._value and "✓" or ""
                        _item._callback(_item._value)
                    end)
                end
                table.insert(self._settings, item)
                return item
            end

            -- ── DROPDOWN ──────────────────────
            function Module:AddDropdown(label, opts)
                opts = opts or {}
                local item = {
                    _type     = "dropdown",
                    _label    = label,
                    _options  = opts.options  or {},
                    _value    = opts.default  or (opts.options and opts.options[1]) or "",
                    _callback = opts.callback or function() end,
                }
                item._buildFn = function(parent, _item)
                    local container = make("Frame", {
                        BackgroundTransparency = 1,
                        Size        = UDim2.new(1, 0, 0, SETTINGS_ITEM + 4),
                        LayoutOrder = #parent:GetChildren(),
                    }, parent)

                    make("TextLabel", {
                        BackgroundTransparency = 1,
                        Size     = UDim2.new(1, 0, 0, 12),
                        Text     = string.upper(_item._label),
                        TextColor3 = T.TextDim,
                        TextSize = 9,
                        Font     = T.FontBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }, container)

                    local btn = make("TextButton", {
                        BackgroundColor3 = T.InputBG,
                        BorderSizePixel  = 0,
                        Position         = UDim2.new(0, 0, 0, 14),
                        Size             = UDim2.new(1, 0, 0, 18),
                        Text             = "",
                    }, container)
                    corner(btn, 3)
                    stroke(btn, T.Separator, 1)

                    local btnLabel = make("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 6, 0, 0),
                        Size     = UDim2.new(1, -20, 1, 0),
                        Text     = _item._value,
                        TextColor3 = T.TextAccent,
                        TextSize = 10,
                        Font     = T.Font,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }, btn)

                    -- arrow
                    make("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -16, 0, 0),
                        Size     = UDim2.new(0, 14, 1, 0),
                        Text     = "▾",
                        TextColor3 = T.TextDim,
                        TextSize = 10,
                        Font     = T.Font,
                    }, btn)

                    -- dropdown list (appears below)
                    local listFrame = make("Frame", {
                        BackgroundColor3 = T.InputBG,
                        BorderSizePixel  = 0,
                        Position         = UDim2.new(0, 0, 1, 2),
                        Size             = UDim2.new(1, 0, 0, #_item._options * 18),
                        Visible          = false,
                        ZIndex           = 10,
                        ClipsDescendants = true,
                    }, btn)
                    corner(listFrame, 3)
                    stroke(listFrame, T.Accent, 1)
                    make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, listFrame)

                    for _, opt in ipairs(_item._options) do
                        local optBtn = make("TextButton", {
                            BackgroundTransparency = 1,
                            Size   = UDim2.new(1, 0, 0, 18),
                            Text   = opt,
                            TextColor3 = T.TextPrimary,
                            TextSize = 10,
                            Font   = T.Font,
                            ZIndex = 11,
                        }, listFrame)
                        optBtn.MouseEnter:Connect(function()
                            optBtn.TextColor3 = T.TextAccent
                        end)
                        optBtn.MouseLeave:Connect(function()
                            optBtn.TextColor3 = T.TextPrimary
                        end)
                        optBtn.MouseButton1Click:Connect(function()
                            _item._value  = opt
                            btnLabel.Text = opt
                            listFrame.Visible = false
                            _item._callback(opt)
                        end)
                    end

                    btn.MouseButton1Click:Connect(function()
                        listFrame.Visible = not listFrame.Visible
                    end)
                end
                table.insert(self._settings, item)
                return item
            end

            -- ── KEYBIND ───────────────────────
            function Module:AddKeybind(label, opts)
                opts = opts or {}
                local item = {
                    _type     = "keybind",
                    _label    = label,
                    _value    = opts.default  or Enum.KeyCode.Unknown,
                    _callback = opts.callback or function() end,
                    _listening = false,
                }
                item._buildFn = function(parent, _item)
                    local row2 = make("Frame", {
                        BackgroundTransparency = 1,
                        Size        = UDim2.new(1, 0, 0, SETTINGS_ITEM),
                        LayoutOrder = #parent:GetChildren(),
                    }, parent)

                    make("TextLabel", {
                        BackgroundTransparency = 1,
                        Size     = UDim2.new(0.5, 0, 1, 0),
                        Text     = string.upper(_item._label),
                        TextColor3 = T.TextPrimary,
                        TextSize = 10,
                        Font     = T.Font,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }, row2)

                    local kbBtn = make("TextButton", {
                        BackgroundColor3 = T.InputBG,
                        BorderSizePixel  = 0,
                        Position         = UDim2.new(0.5, 0, 0.1, 0),
                        Size             = UDim2.new(0.5, 0, 0.8, 0),
                        Text             = _item._value.Name,
                        TextColor3       = T.TextAccent,
                        TextSize         = 10,
                        Font             = T.FontBold,
                    }, row2)
                    corner(kbBtn, 3)
                    stroke(kbBtn, T.Separator, 1)

                    kbBtn.MouseButton1Click:Connect(function()
                        _item._listening = true
                        kbBtn.Text       = "..."
                        kbBtn.TextColor3 = T.TextDim
                    end)

                    UserInputService.InputBegan:Connect(function(inp, gp)
                        if _item._listening and not gp then
                            if inp.UserInputType == Enum.UserInputType.Keyboard then
                                _item._value    = inp.KeyCode
                                kbBtn.Text      = inp.KeyCode.Name
                                kbBtn.TextColor3 = T.TextAccent
                                _item._listening = false
                                _item._callback(inp.KeyCode)
                            end
                        end
                    end)
                end
                table.insert(self._settings, item)
                return item
            end

            -- ── TEXTBOX ───────────────────────
            function Module:AddTextbox(label, opts)
                opts = opts or {}
                local item = {
                    _type     = "textbox",
                    _label    = label,
                    _value    = opts.default  or "",
                    _callback = opts.callback or function() end,
                    _placeholder = opts.placeholder or "...",
                }
                item._buildFn = function(parent, _item)
                    local container = make("Frame", {
                        BackgroundTransparency = 1,
                        Size        = UDim2.new(1, 0, 0, SETTINGS_ITEM + 4),
                        LayoutOrder = #parent:GetChildren(),
                    }, parent)
                    make("TextLabel", {
                        BackgroundTransparency = 1,
                        Size     = UDim2.new(1, 0, 0, 12),
                        Text     = string.upper(_item._label),
                        TextColor3 = T.TextDim,
                        TextSize = 9,
                        Font     = T.FontBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }, container)
                    local tb = make("TextBox", {
                        BackgroundColor3 = T.InputBG,
                        BorderSizePixel  = 0,
                        Position         = UDim2.new(0, 0, 0, 14),
                        Size             = UDim2.new(1, 0, 0, 18),
                        Text             = _item._value,
                        PlaceholderText  = _item._placeholder,
                        TextColor3       = T.TextAccent,
                        PlaceholderColor3 = T.TextDim,
                        TextSize         = 10,
                        Font             = T.Font,
                        ClearTextOnFocus = false,
                        TextXAlignment   = Enum.TextXAlignment.Left,
                    }, container)
                    pad(tb, 2, 4, 2, 4)
                    corner(tb, 3)
                    stroke(tb, T.Separator, 1)

                    tb.FocusLost:Connect(function(enter)
                        _item._value = tb.Text
                        _item._callback(tb.Text)
                    end)
                end
                table.insert(self._settings, item)
                return item
            end

            -- ── MODE SELECTOR (cycle labels) ──
            function Module:AddMode(label, opts)
                opts = opts or {}
                local item = {
                    _type     = "mode",
                    _label    = label,
                    _options  = opts.options or {},
                    _index    = 1,
                    _callback = opts.callback or function() end,
                }
                -- find default index
                if opts.default then
                    for i, v in ipairs(item._options) do
                        if v == opts.default then item._index = i break end
                    end
                end
                item._buildFn = function(parent, _item)
                    local row2 = make("Frame", {
                        BackgroundTransparency = 1,
                        Size        = UDim2.new(1, 0, 0, SETTINGS_ITEM),
                        LayoutOrder = #parent:GetChildren(),
                    }, parent)

                    make("TextLabel", {
                        BackgroundTransparency = 1,
                        Size     = UDim2.new(0.5, 0, 1, 0),
                        Text     = string.upper(_item._label),
                        TextColor3 = T.TextPrimary,
                        TextSize = 10,
                        Font     = T.Font,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }, row2)

                    local valBtn = make("TextButton", {
                        BackgroundColor3 = T.InputBG,
                        BorderSizePixel  = 0,
                        Position         = UDim2.new(0.5, 0, 0.1, 0),
                        Size             = UDim2.new(0.5, 0, 0.8, 0),
                        Text             = _item._options[_item._index] or "",
                        TextColor3       = T.TextAccent,
                        TextSize         = 10,
                        Font             = T.FontBold,
                    }, row2)
                    corner(valBtn, 3)
                    stroke(valBtn, T.Separator, 1)

                    valBtn.MouseButton1Click:Connect(function()
                        _item._index = (_item._index % #_item._options) + 1
                        local v = _item._options[_item._index]
                        valBtn.Text = v
                        _item._callback(v)
                    end)
                end
                table.insert(self._settings, item)
                return item
            end

            return Module
        end -- AddModule

        -- Add search column (special, call once per window)
        function Category:_asSearchCol()
            -- repurpose col as a search column
            header:FindFirstChild("Title").Text = "⌕ SEARCH"
            local searchBox = make("TextBox", {
                BackgroundColor3  = T.InputBG,
                BorderSizePixel   = 0,
                Position          = UDim2.new(0, 6, 0, COL_HEADER_H + 4),
                Size              = UDim2.new(1, -12, 0, 20),
                Text              = "",
                PlaceholderText   = "Search modules...",
                TextColor3        = T.TextAccent,
                PlaceholderColor3 = T.TextDim,
                TextSize          = 10,
                Font              = T.Font,
                ClearTextOnFocus  = false,
                TextXAlignment    = Enum.TextXAlignment.Left,
            }, col)
            pad(searchBox, 2, 4, 2, 4)
            corner(searchBox, 3)
            stroke(searchBox, T.Separator, 1)

            -- results list
            local resultsList = make("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, COL_HEADER_H + 28),
                Size     = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
            }, col)
            make("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding   = UDim.new(0, 1),
            }, resultsList)

            searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                local q = string.lower(searchBox.Text)
                -- clear results
                for _, c in ipairs(resultsList:GetChildren()) do
                    if not c:IsA("UIListLayout") then c:Destroy() end
                end
                if q == "" then return end

                local win = self._window
                for _, mod in ipairs(win._allModules) do
                    if string.find(string.lower(mod._name), q, 1, true) then
                        local resultBtn = make("TextButton", {
                            BackgroundColor3 = T.ModNormal,
                            BorderSizePixel  = 0,
                            Size             = UDim2.new(1, 0, 0, MODULE_H),
                            Text             = "",
                            LayoutOrder      = #resultsList:GetChildren() + 1,
                        }, resultsList)
                        corner(resultBtn, 0)

                        make("TextLabel", {
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 6, 0, 0),
                            Size     = UDim2.new(1, -12, 1, 0),
                            Text     = mod._name .. " (" .. mod._category._name .. ")",
                            TextColor3 = T.TextPrimary,
                            TextSize = 10,
                            Font     = T.Font,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextTruncate   = Enum.TextTruncate.AtEnd,
                        }, resultBtn)

                        local dot2 = make("Frame", {
                            BackgroundColor3 = mod._enabled and T.Accent or T.ToggleOff,
                            BorderSizePixel  = 0,
                            Position = UDim2.new(1, -(TOGGLE_SIZE + 4), 0.5, -(TOGGLE_SIZE/2)),
                            Size     = UDim2.new(0, TOGGLE_SIZE, 0, TOGGLE_SIZE),
                            ZIndex   = 2,
                        }, resultBtn)
                        corner(dot2, 10)

                        resultBtn.MouseEnter:Connect(function()
                            resultBtn.BackgroundColor3 = T.ModHover
                        end)
                        resultBtn.MouseLeave:Connect(function()
                            resultBtn.BackgroundColor3 = T.ModNormal
                        end)

                        -- left click = toggle; right click = settings
                        resultBtn.MouseButton1Click:Connect(function()
                            mod._enabled = not mod._enabled
                            if mod._onToggle then mod._onToggle(mod._enabled) end
                            -- refresh toggle dot in both places
                            dot2.BackgroundColor3 = mod._enabled and T.Accent or T.ToggleOff
                            mod._toggleDot.BackgroundColor3 = mod._enabled and T.Accent or T.ToggleOff
                            mod._nameLabel.TextColor3 = mod._enabled and T.TextAccent or T.TextPrimary
                        end)
                        resultBtn.MouseButton2Click:Connect(function()
                            if win._activeModule then
                                win._activeModule._row.BackgroundColor3 = T.ModNormal
                            end
                            win._activeModule = mod
                            mod._row.BackgroundColor3 = T.ModActive
                            win._openSettings(mod)
                        end)
                    end
                end
            end)
        end

        return Category
    end -- AddCategory

    -- ── AddSearchColumn (convenience) ──────────
    function Window:AddSearchColumn()
        local cat = self:AddCategory("SEARCH")
        cat:_asSearchCol()
        return cat
    end

    -- ── Destroy ────────────────────────────────
    function Window:Destroy()
        screenGui:Destroy()
    end

    return Window
end

return UILibrary
