--[[
    Helixia UILibrary.lua
    Roblox Module Menu UI Library — by Helixia

    Usage:
        local Helixia = require(path.to.UILibrary)
        local win     = Helixia:CreateWindow({ key = Enum.KeyCode.RightShift })
        local cat     = win:AddCategory("COMBAT")
        local mod     = cat:AddModule("Aimbot")
        mod:SetToggleCallback(function(state) print("Aimbot:", state) end)
        mod:AddSlider("FOV",      { min=1, max=360, default=90, callback=function(v) end })
        mod:AddDropdown("Mode",   { options={"Closest","Health"}, default="Closest", callback=function(v) end })
        mod:AddCheckbox("Silent", { default=false, callback=function(v) end })
        mod:AddKeybind("Key",     { default=Enum.KeyCode.V, callback=function(k) end })
        mod:AddTextbox("Value",   { default="100", callback=function(t) end })
]]

local UILibrary = {}
UILibrary.__index = UILibrary

-- ────────────────────────────────────────────────────────────────
-- Services
-- ────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local LocalPlayer      = Players.LocalPlayer

-- ────────────────────────────────────────────────────────────────
-- Theme  (matched to user's screenshot exactly)
-- ────────────────────────────────────────────────────────────────
local T = {
    -- backgrounds (darker, more black)
    BG          = Color3.fromRGB(8,   8,   10),   -- outermost window bg (very dark)
    ColBG       = Color3.fromRGB(12,  12,  15),   -- column background (black)
    ColHeader   = Color3.fromRGB(15,  15,  18),   -- header bar per column (darker)
    ModNormal   = Color3.fromRGB(12,  12,  15),   -- module row default
    ModHover    = Color3.fromRGB(20,  20,  26),   -- module row hovered
    ModActive   = Color3.fromRGB(15,  45,  80),   -- module row open/settings (bright blue)
    SettingsBG  = Color3.fromRGB(10,  10,  13),   -- settings panel bg
    InputBG     = Color3.fromRGB(18,  18,  24),

    -- accents (brighter, more vibrant)
    Accent      = Color3.fromRGB(60,  160, 255),  -- bright blue toggle ON
    AccentDim   = Color3.fromRGB(30,  100, 190),
    ToggleOff   = Color3.fromRGB(180, 180, 190),  -- WHITE/light gray when OFF (like photo)
    SliderFill  = Color3.fromRGB(60,  160, 255),
    SliderBG    = Color3.fromRGB(25,   25,  35),

    -- text
    TextPrimary = Color3.fromRGB(200, 200, 215),  -- normal module text
    TextDim     = Color3.fromRGB(80,  80,  100),  -- dim labels
    TextAccent  = Color3.fromRGB(90,  190, 255),  -- bright blue when active

    -- misc
    Separator   = Color3.fromRGB(22,  22,  30),
    Shadow      = Color3.fromRGB(0,    0,   0),

    -- fonts (bolder)
    Font        = Enum.Font.GothamBold,  -- use bold for everything
    FontBold    = Enum.Font.GothamBold,
}

-- ────────────────────────────────────────────────────────────────
-- Layout constants  (tuned to match photo exactly)
-- ────────────────────────────────────────────────────────────────
local COL_WIDTH      = 155  -- column width (px)
local COL_HEADER_H   = 20   -- header bar height
local MODULE_H       = 16   -- module row height (thinner, like photo)
local MODULE_PAD     = 0    -- gap between rows (tight, like photo)
local TOGGLE_SIZE    = 7    -- smaller dot
local SETTINGS_W     = 210  -- settings panel width
local SETTINGS_ITEM  = 24

-- ────────────────────────────────────────────────────────────────
-- Helpers
-- ────────────────────────────────────────────────────────────────
local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function tw(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad), props):Play()
end

local function stroke(parent, color, thickness)
    return make("UIStroke", {
        Color           = color or T.Separator,
        Thickness       = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function corner(parent, r)
    return make("UICorner", { CornerRadius = UDim.new(0, r or 3) }, parent)
end

local function pad(parent, top, right, bottom, left)
    return make("UIPadding", {
        PaddingTop    = UDim.new(0, top    or 3),
        PaddingRight  = UDim.new(0, right  or 5),
        PaddingBottom = UDim.new(0, bottom or 3),
        PaddingLeft   = UDim.new(0, left   or 5),
    }, parent)
end

-- ════════════════════════════════════════════════════════════════
-- CreateWindow
-- ════════════════════════════════════════════════════════════════
function UILibrary:CreateWindow(opts)
    opts     = opts or {}
    local openKey = opts.key or Enum.KeyCode.RightShift

    -- ── ScreenGui ─────────────────────────────
    local screenGui = make("ScreenGui", {
        Name           = "HelixiaUI",
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    local ok = pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
    if not ok then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    -- ── Root (no title bar — matches photo 2) ──
    local root = make("Frame", {
        Name             = "Root",
        BackgroundColor3 = T.BG,
        BorderSizePixel  = 0,
        -- centered horizontally, near top (like photo 2)
        Position         = UDim2.new(0.5, -450, 0.08, 0),
        Size             = UDim2.new(0, 10, 0, 10),
        ClipsDescendants = false,
        AutomaticSize    = Enum.AutomaticSize.XY,
    }, screenGui)
    corner(root, 3)
    stroke(root, T.Separator, 1)

    -- subtle drop shadow
    make("ImageLabel", {
        Name                   = "Shadow",
        BackgroundTransparency = 1,
        Image                  = "rbxassetid://6014261993",
        ImageColor3            = T.Shadow,
        ImageTransparency      = 0.55,
        Position               = UDim2.new(0, -12, 0, -12),
        Size                   = UDim2.new(1, 24, 1, 24),
        SliceCenter            = Rect.new(49, 49, 450, 450),
        ScaleType              = Enum.ScaleType.Slice,
        ZIndex                 = -1,
    }, root)

    -- ── Column container ───────────────────────
    -- No top title bar.  Columns start right at the top of root.
    local colContainer = make("Frame", {
        Name                   = "Columns",
        BackgroundTransparency = 1,
        Size                   = UDim2.new(0, 10, 0, 10),
        AutomaticSize          = Enum.AutomaticSize.XY,
    }, root)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder     = Enum.SortOrder.LayoutOrder,
        Padding       = UDim.new(0, 5),  -- 5px gap between columns (separated like photo)
    }, colContainer)

    -- ── Settings panel ─────────────────────────
    local settingsPanel = make("Frame", {
        Name             = "SettingsPanel",
        BackgroundColor3 = T.SettingsBG,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, SETTINGS_W, 0, 100),
        Visible          = false,
        AutomaticSize    = Enum.AutomaticSize.Y,
        LayoutOrder      = 9999,
    }, colContainer)
    corner(settingsPanel, 3)
    stroke(settingsPanel, T.Accent, 1)

    -- settings header
    local sHeader = make("Frame", {
        BackgroundColor3 = T.ColHeader,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, COL_HEADER_H),
    }, settingsPanel)
    corner(sHeader, 3)

    -- blue underline on settings header
    make("Frame", {
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 1, -1),
        Size             = UDim2.new(1, 0, 0, 1),
    }, sHeader)

    local sTitleLabel = make("TextLabel", {
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 6, 0, 0),
        Size           = UDim2.new(1, -12, 1, 0),
        Text           = "",
        TextColor3     = T.TextAccent,
        TextSize       = 10,
        Font           = T.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate   = Enum.TextTruncate.AtEnd,
    }, sHeader)

    local sDesc = make("TextLabel", {
        BackgroundTransparency = 1,
        Position    = UDim2.new(0, 6, 0, COL_HEADER_H + 2),
        Size        = UDim2.new(1, -12, 0, 16),
        Text        = "",
        TextColor3  = T.TextDim,
        TextSize    = 9,
        Font        = T.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
    }, settingsPanel)

    local sScroll = make("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 0, 0, COL_HEADER_H + 20),
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        ScrollBarThickness     = 2,
        ScrollBarImageColor3   = T.Accent,
        CanvasSize             = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
    }, settingsPanel)
    make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0) }, sScroll)
    pad(sScroll, 4, 8, 8, 8)

    -- ── Window object ──────────────────────────
    local Window = {
        _root          = root,
        _colContainer  = colContainer,
        _settingsPanel = settingsPanel,
        _sTitle        = sTitleLabel,
        _sDesc         = sDesc,
        _sScroll       = sScroll,
        _categories    = {},
        _allModules    = {},
        _activeModule  = nil,
        _visible       = true,
    }

    -- toggle visibility
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == openKey then
            Window._visible = not Window._visible
            root.Visible    = Window._visible
        end
    end)

    -- ── Dragging — drag anywhere on the window ──
    do
        local drag, dStart, dPos
        root.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                drag   = true
                dStart = input.Position
                dPos   = root.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if drag and input.UserInputType == Enum.UserInputType.MouseMovement then
                local d = input.Position - dStart
                root.Position = UDim2.new(dPos.X.Scale, dPos.X.Offset + d.X,
                                          dPos.Y.Scale, dPos.Y.Offset + d.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
        end)
    end

    -- ── Settings open / close ──────────────────
    local function openSettings(mod)
        for _, c in ipairs(sScroll:GetChildren()) do
            if c:IsA("GuiObject") then c:Destroy() end
        end
        sTitleLabel.Text = mod._name
        sDesc.Text       = mod._desc or ""
        settingsPanel.Visible = true
        for _, item in ipairs(mod._settings) do
            item._buildFn(sScroll, item)
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

    -- ══════════════════════════════════════════
    -- AddCategory
    -- ══════════════════════════════════════════
    function Window:AddCategory(name)
        local Category = {
            _name    = name,
            _modules = {},
            _window  = self,
        }

        -- column frame
        local col = make("Frame", {
            Name             = "Cat_" .. name,
            BackgroundColor3 = T.ColBG,
            BorderSizePixel  = 0,
            Size             = UDim2.new(0, COL_WIDTH, 0, 0),
            AutomaticSize    = Enum.AutomaticSize.Y,
            LayoutOrder      = #self._categories + 1,
        }, colContainer)

        -- ── header bar ────────────────────────
        local header = make("Frame", {
            Name             = "Header",
            BackgroundColor3 = T.ColHeader,
            BorderSizePixel  = 0,
            Size             = UDim2.new(1, 0, 0, COL_HEADER_H),
        }, col)

        -- category icon + X button on left (matching photo exactly)
        local ICONS = {
            COMBAT    = "✕",  -- X icon like in photo
            MOVEMENT  = "≡",
            VISUAL    = "◈",
            MISC      = "≡",
            INPUTS    = "≡",
            ADVANCED  = "✕",
            TOGGLES   = "◉",
            SEARCH    = "⌕",
        }
        local icon = ICONS[string.upper(name)] or "◉"

        make("TextLabel", {
            Name                   = "Title",
            BackgroundTransparency = 1,
            Position               = UDim2.new(0, 5, 0, 0),
            Size                   = UDim2.new(1, -24, 1, 0),
            Text                   = icon .. " " .. string.upper(name),
            TextColor3             = T.TextAccent,
            TextSize               = 9,
            Font                   = T.FontBold,
            TextXAlignment         = Enum.TextXAlignment.Left,
            TextTruncate           = Enum.TextTruncate.AtEnd,
        }, header)

        -- "—" minimize button on right (matching photo)
        make("TextLabel", {
            BackgroundTransparency = 1,
            Position               = UDim2.new(1, -16, 0, 0),
            Size                   = UDim2.new(0, 14, 1, 0),
            Text                   = "—",
            TextColor3             = T.TextDim,
            TextSize               = 9,
            Font                   = T.FontBold,
        }, header)

        -- blue accent underline
        make("Frame", {
            Name             = "Line",
            BackgroundColor3 = T.Accent,
            BorderSizePixel  = 0,
            Position         = UDim2.new(0, 0, 1, -1),
            Size             = UDim2.new(1, 0, 0, 1),
        }, header)

        -- module list
        local modList = make("Frame", {
            Name                   = "ModList",
            BackgroundTransparency = 1,
            Position               = UDim2.new(0, 0, 0, COL_HEADER_H),
            Size                   = UDim2.new(1, 0, 0, 0),
            AutomaticSize          = Enum.AutomaticSize.Y,
        }, col)
        make("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, MODULE_PAD),
        }, modList)

        Category._col     = col
        Category._modList = modList
        Category._header  = header

        table.insert(self._categories, Category)

        -- ════════════════════════════════════
        -- AddModule
        -- ════════════════════════════════════
        function Category:AddModule(modName, opts)
            opts = opts or {}
            local Module = {
                _name     = modName,
                _desc     = opts.desc    or "",
                _enabled  = opts.default or false,
                _settings = {},
                _category = self,
                _window   = self._window,
                _onToggle = nil,
            }

            -- row
            local row = make("Frame", {
                Name             = "Mod_" .. modName,
                BackgroundColor3 = T.ModNormal,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, 0, 0, MODULE_H),
                LayoutOrder      = #self._modules + 1,
            }, modList)

            local rowBtn = make("TextButton", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 1, 0),
                Text                   = "",
                ZIndex                 = 2,
            }, row)

            -- name label (keep title case like photo: "Aim Assist" not "AIM ASSIST")
            local nameLabel = make("TextLabel", {
                BackgroundTransparency = 1,
                Position       = UDim2.new(0, 6, 0, 0),
                Size           = UDim2.new(1, -20, 1, 0),
                Text           = modName,  -- use original name (title case)
                TextColor3     = T.TextPrimary,
                TextSize       = 9,
                Font           = T.Font,  -- now GothamBold
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate   = Enum.TextTruncate.AtEnd,
            }, row)

            -- toggle dot (right side)
            local dot = make("Frame", {
                Name             = "Dot",
                BackgroundColor3 = T.ToggleOff,
                BorderSizePixel  = 0,
                AnchorPoint      = Vector2.new(0, 0.5),
                Position         = UDim2.new(1, -(TOGGLE_SIZE + 5), 0.5, 0),
                Size             = UDim2.new(0, TOGGLE_SIZE, 0, TOGGLE_SIZE),
                ZIndex           = 3,
            }, row)
            corner(dot, 10)

            local function refreshToggle()
                tw(dot, 0.12, { BackgroundColor3 = Module._enabled and T.Accent or T.ToggleOff })
                nameLabel.TextColor3 = Module._enabled and T.TextAccent or T.TextPrimary
            end

            -- LEFT click = toggle
            rowBtn.MouseButton1Click:Connect(function()
                Module._enabled = not Module._enabled
                refreshToggle()
                if Module._onToggle then Module._onToggle(Module._enabled) end
            end)

            -- RIGHT click = settings
            rowBtn.MouseButton2Click:Connect(function()
                local win = Module._window
                if win._activeModule == Module then
                    win._closeSettings()
                    row.BackgroundColor3 = T.ModNormal
                else
                    if win._activeModule then
                        win._activeModule._row.BackgroundColor3 = T.ModNormal
                    end
                    win._activeModule = Module
                    row.BackgroundColor3 = T.ModActive
                    win._openSettings(Module)
                end
            end)

            rowBtn.MouseEnter:Connect(function()
                if Module._window._activeModule ~= Module then
                    tw(row, 0.07, { BackgroundColor3 = T.ModHover })
                end
            end)
            rowBtn.MouseLeave:Connect(function()
                if Module._window._activeModule ~= Module then
                    tw(row, 0.07, { BackgroundColor3 = T.ModNormal })
                end
            end)

            Module._row       = row
            Module._nameLabel = nameLabel
            Module._dot       = dot
            Module._toggleDot = dot  -- alias for SaveManager compat

            refreshToggle()

            table.insert(self._modules, Module)
            table.insert(self._window._allModules, Module)

            -- ── Module methods ─────────────────
            function Module:SetToggleCallback(fn) self._onToggle = fn end
            function Module:SetDesc(text)         self._desc = text  end
            function Module:IsEnabled()           return self._enabled end

            function Module:Enable()
                self._enabled = true; refreshToggle()
                if self._onToggle then self._onToggle(true) end
            end
            function Module:Disable()
                self._enabled = false; refreshToggle()
                if self._onToggle then self._onToggle(false) end
            end

            -- ── Settings builders ──────────────

            function Module:AddSeparator(labelText)
                local item = { _type="separator", _label=labelText or "" }
                item._buildFn = function(parent, _i)
                    local f = make("Frame", {
                        BackgroundTransparency = 1,
                        Size        = UDim2.new(1, 0, 0, 16),
                        LayoutOrder = #parent:GetChildren(),
                    }, parent)
                    make("TextLabel", {
                        BackgroundTransparency = 1,
                        Size           = UDim2.new(1, 0, 1, 0),
                        Text           = string.upper(_i._label),
                        TextColor3     = T.TextDim,
                        TextSize       = 8,
                        Font           = T.FontBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }, f)
                    make("Frame", {
                        BackgroundColor3 = T.Separator,
                        BorderSizePixel  = 0,
                        Position         = UDim2.new(0, 0, 1, -1),
                        Size             = UDim2.new(1, 0, 0, 1),
                    }, f)
                end
                table.insert(self._settings, item); return item
            end

            function Module:AddSlider(label, opts2)
                opts2 = opts2 or {}
                local item = {
                    _type     = "slider",
                    _label    = label,
                    _min      = opts2.min      or 0,
                    _max      = opts2.max      or 100,
                    _value    = opts2.default  or opts2.min or 0,
                    _callback = opts2.callback or function() end,
                    _suffix   = opts2.suffix   or "",
                }
                item._buildFn = function(parent, _i)
                    local c = make("Frame", {
                        BackgroundTransparency = 1,
                        Size        = UDim2.new(1, 0, 0, SETTINGS_ITEM + 4),
                        LayoutOrder = #parent:GetChildren(),
                    }, parent)
                    local top = make("Frame", {
                        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 13),
                    }, c)
                    make("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0.65, 0, 1, 0), Text = string.upper(_i._label),
                        TextColor3 = T.TextPrimary, TextSize = 9, Font = T.Font,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }, top)
                    local valLbl = make("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0.35, 0, 1, 0), Position = UDim2.new(0.65, 0, 0, 0),
                        Text = tostring(_i._value) .. _i._suffix,
                        TextColor3 = T.TextAccent, TextSize = 9, Font = T.FontBold,
                        TextXAlignment = Enum.TextXAlignment.Right,
                    }, top)
                    local track = make("Frame", {
                        BackgroundColor3 = T.SliderBG, BorderSizePixel = 0,
                        Position = UDim2.new(0, 0, 0, 16), Size = UDim2.new(1, 0, 0, 3),
                    }, c)
                    corner(track, 3)
                    local pct0 = math.clamp((_i._value - _i._min) / (_i._max - _i._min), 0, 1)
                    local fill = make("Frame", {
                        BackgroundColor3 = T.SliderFill, BorderSizePixel = 0,
                        Size = UDim2.new(pct0, 0, 1, 0),
                    }, track)
                    corner(fill, 3)
                    local handle = make("Frame", {
                        BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(pct0, 0, 0.5, 0),
                        Size = UDim2.new(0, 7, 0, 7), ZIndex = 2,
                    }, track)
                    corner(handle, 10)

                    local sliding = false
                    local function upd(absX)
                        local p = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                        local v = math.floor(_i._min + p * (_i._max - _i._min) + 0.5)
                        _i._value = v; valLbl.Text = tostring(v) .. _i._suffix
                        fill.Size = UDim2.new(p, 0, 1, 0)
                        handle.Position = UDim2.new(p, 0, 0.5, 0)
                        _i._callback(v)
                    end
                    track.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            sliding = true; upd(inp.Position.X)
                        end
                    end)
                    UserInputService.InputChanged:Connect(function(inp)
                        if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then
                            upd(inp.Position.X)
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
                    end)
                end
                table.insert(self._settings, item); return item
            end

            function Module:AddCheckbox(label, opts2)
                opts2 = opts2 or {}
                local item = {
                    _type     = "checkbox",
                    _label    = label,
                    _value    = opts2.default  or false,
                    _callback = opts2.callback or function() end,
                }
                item._buildFn = function(parent, _i)
                    local r = make("TextButton", {
                        BackgroundTransparency = 1,
                        Size        = UDim2.new(1, 0, 0, SETTINGS_ITEM - 2),
                        Text        = "",
                        LayoutOrder = #parent:GetChildren(),
                    }, parent)
                    local box = make("Frame", {
                        BackgroundColor3 = _i._value and T.Accent or T.ToggleOff,
                        BorderSizePixel  = 0,
                        Position         = UDim2.new(0, 0, 0.5, -5),
                        Size             = UDim2.new(0, 10, 0, 10),
                    }, r)
                    corner(box, 2); stroke(box, T.Accent, 1)
                    local chk = make("TextLabel", {
                        BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0),
                        Text = _i._value and "✓" or "", TextColor3 = Color3.new(1,1,1),
                        TextSize = 8, Font = T.FontBold,
                    }, box)
                    make("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 15, 0, 0), Size = UDim2.new(1, -15, 1, 0),
                        Text = _i._label, TextColor3 = T.TextPrimary,
                        TextSize = 9, Font = T.Font, TextXAlignment = Enum.TextXAlignment.Left,
                    }, r)
                    r.MouseButton1Click:Connect(function()
                        _i._value = not _i._value
                        box.BackgroundColor3 = _i._value and T.Accent or T.ToggleOff
                        chk.Text = _i._value and "✓" or ""
                        _i._callback(_i._value)
                    end)
                end
                table.insert(self._settings, item); return item
            end

            function Module:AddDropdown(label, opts2)
                opts2 = opts2 or {}
                local item = {
                    _type     = "dropdown",
                    _label    = label,
                    _options  = opts2.options  or {},
                    _value    = opts2.default  or (opts2.options and opts2.options[1]) or "",
                    _callback = opts2.callback or function() end,
                }
                item._buildFn = function(parent, _i)
                    local c = make("Frame", {
                        BackgroundTransparency = 1,
                        Size        = UDim2.new(1, 0, 0, SETTINGS_ITEM + 2),
                        LayoutOrder = #parent:GetChildren(),
                    }, parent)
                    make("TextLabel", {
                        BackgroundTransparency = 1, Size = UDim2.new(1,0,0,11),
                        Text = string.upper(_i._label), TextColor3 = T.TextDim,
                        TextSize = 8, Font = T.FontBold, TextXAlignment = Enum.TextXAlignment.Left,
                    }, c)
                    local btn = make("TextButton", {
                        BackgroundColor3 = T.InputBG, BorderSizePixel = 0,
                        Position = UDim2.new(0,0,0,13), Size = UDim2.new(1,0,0,16), Text = "",
                    }, c)
                    corner(btn, 2); stroke(btn, T.Separator, 1)
                    local lbl = make("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0,5,0,0), Size = UDim2.new(1,-18,1,0),
                        Text = _i._value, TextColor3 = T.TextAccent,
                        TextSize = 9, Font = T.Font, TextXAlignment = Enum.TextXAlignment.Left,
                    }, btn)
                    make("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1,-14,0,0), Size = UDim2.new(0,12,1,0),
                        Text = "▾", TextColor3 = T.TextDim, TextSize = 9, Font = T.Font,
                    }, btn)
                    local list = make("Frame", {
                        BackgroundColor3 = T.InputBG, BorderSizePixel = 0,
                        Position = UDim2.new(0,0,1,2),
                        Size = UDim2.new(1,0,0,#_i._options * 16),
                        Visible = false, ZIndex = 10, ClipsDescendants = true,
                    }, btn)
                    corner(list, 2); stroke(list, T.Accent, 1)
                    make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, list)
                    for _, opt in ipairs(_i._options) do
                        local ob = make("TextButton", {
                            BackgroundTransparency = 1, Size = UDim2.new(1,0,0,16),
                            Text = opt, TextColor3 = T.TextPrimary, TextSize = 9,
                            Font = T.Font, ZIndex = 11,
                        }, list)
                        ob.MouseEnter:Connect(function() ob.TextColor3 = T.TextAccent end)
                        ob.MouseLeave:Connect(function() ob.TextColor3 = T.TextPrimary end)
                        ob.MouseButton1Click:Connect(function()
                            _i._value = opt; lbl.Text = opt
                            list.Visible = false; _i._callback(opt)
                        end)
                    end
                    btn.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
                end
                table.insert(self._settings, item); return item
            end

            function Module:AddKeybind(label, opts2)
                opts2 = opts2 or {}
                local item = {
                    _type      = "keybind",
                    _label     = label,
                    _value     = opts2.default  or Enum.KeyCode.Unknown,
                    _callback  = opts2.callback or function() end,
                    _listening = false,
                }
                item._buildFn = function(parent, _i)
                    local r = make("Frame", {
                        BackgroundTransparency = 1,
                        Size        = UDim2.new(1, 0, 0, SETTINGS_ITEM),
                        LayoutOrder = #parent:GetChildren(),
                    }, parent)
                    make("TextLabel", {
                        BackgroundTransparency = 1, Size = UDim2.new(0.55,0,1,0),
                        Text = string.upper(_i._label), TextColor3 = T.TextPrimary,
                        TextSize = 9, Font = T.Font, TextXAlignment = Enum.TextXAlignment.Left,
                    }, r)
                    local kb = make("TextButton", {
                        BackgroundColor3 = T.InputBG, BorderSizePixel = 0,
                        Position = UDim2.new(0.55,0,0.1,0), Size = UDim2.new(0.45,0,0.8,0),
                        Text = _i._value.Name, TextColor3 = T.TextAccent,
                        TextSize = 9, Font = T.FontBold,
                    }, r)
                    corner(kb, 2); stroke(kb, T.Separator, 1)
                    kb.MouseButton1Click:Connect(function()
                        _i._listening = true; kb.Text = "..."; kb.TextColor3 = T.TextDim
                    end)
                    UserInputService.InputBegan:Connect(function(inp, gp)
                        if _i._listening and not gp and inp.UserInputType == Enum.UserInputType.Keyboard then
                            _i._value = inp.KeyCode; kb.Text = inp.KeyCode.Name
                            kb.TextColor3 = T.TextAccent; _i._listening = false
                            _i._callback(inp.KeyCode)
                        end
                    end)
                end
                table.insert(self._settings, item); return item
            end

            function Module:AddTextbox(label, opts2)
                opts2 = opts2 or {}
                local item = {
                    _type        = "textbox",
                    _label       = label,
                    _value       = opts2.default     or "",
                    _callback    = opts2.callback    or function() end,
                    _placeholder = opts2.placeholder or "...",
                }
                item._buildFn = function(parent, _i)
                    local c = make("Frame", {
                        BackgroundTransparency = 1,
                        Size        = UDim2.new(1, 0, 0, SETTINGS_ITEM + 2),
                        LayoutOrder = #parent:GetChildren(),
                    }, parent)
                    make("TextLabel", {
                        BackgroundTransparency = 1, Size = UDim2.new(1,0,0,11),
                        Text = string.upper(_i._label), TextColor3 = T.TextDim,
                        TextSize = 8, Font = T.FontBold, TextXAlignment = Enum.TextXAlignment.Left,
                    }, c)
                    local tb = make("TextBox", {
                        BackgroundColor3  = T.InputBG, BorderSizePixel = 0,
                        Position          = UDim2.new(0,0,0,13), Size = UDim2.new(1,0,0,16),
                        Text              = _i._value, PlaceholderText = _i._placeholder,
                        TextColor3        = T.TextAccent, PlaceholderColor3 = T.TextDim,
                        TextSize          = 9, Font = T.Font,
                        ClearTextOnFocus  = false, TextXAlignment = Enum.TextXAlignment.Left,
                    }, c)
                    pad(tb, 1, 4, 1, 4); corner(tb, 2); stroke(tb, T.Separator, 1)
                    tb.FocusLost:Connect(function()
                        _i._value = tb.Text; _i._callback(tb.Text)
                    end)
                end
                table.insert(self._settings, item); return item
            end

            function Module:AddMode(label, opts2)
                opts2 = opts2 or {}
                local item = {
                    _type     = "mode",
                    _label    = label,
                    _options  = opts2.options or {},
                    _index    = 1,
                    _callback = opts2.callback or function() end,
                }
                if opts2.default then
                    for i, v in ipairs(item._options) do
                        if v == opts2.default then item._index = i; break end
                    end
                end
                item._buildFn = function(parent, _i)
                    local r = make("Frame", {
                        BackgroundTransparency = 1,
                        Size        = UDim2.new(1, 0, 0, SETTINGS_ITEM),
                        LayoutOrder = #parent:GetChildren(),
                    }, parent)
                    make("TextLabel", {
                        BackgroundTransparency = 1, Size = UDim2.new(0.55,0,1,0),
                        Text = string.upper(_i._label), TextColor3 = T.TextPrimary,
                        TextSize = 9, Font = T.Font, TextXAlignment = Enum.TextXAlignment.Left,
                    }, r)
                    local vb = make("TextButton", {
                        BackgroundColor3 = T.InputBG, BorderSizePixel = 0,
                        Position = UDim2.new(0.55,0,0.1,0), Size = UDim2.new(0.45,0,0.8,0),
                        Text = _i._options[_i._index] or "", TextColor3 = T.TextAccent,
                        TextSize = 9, Font = T.FontBold,
                    }, r)
                    corner(vb, 2); stroke(vb, T.Separator, 1)
                    vb.MouseButton1Click:Connect(function()
                        _i._index = (_i._index % #_i._options) + 1
                        local v = _i._options[_i._index]; vb.Text = v; _i._callback(v)
                    end)
                end
                table.insert(self._settings, item); return item
            end

            return Module
        end -- AddModule

        -- ── Search column internal setup ───────
        function Category:_asSearchCol()
            Category._header:FindFirstChild("Title").Text = "⌕ SEARCH"

            local sb = make("TextBox", {
                BackgroundColor3  = T.InputBG, BorderSizePixel = 0,
                Position          = UDim2.new(0, 5, 0, COL_HEADER_H + 3),
                Size              = UDim2.new(1, -10, 0, 16),
                Text              = "", PlaceholderText = "Search modules...",
                TextColor3        = T.TextAccent, PlaceholderColor3 = T.TextDim,
                TextSize          = 9, Font = T.Font,
                ClearTextOnFocus  = false, TextXAlignment = Enum.TextXAlignment.Left,
            }, col)
            pad(sb, 1, 4, 1, 4); corner(sb, 2); stroke(sb, T.Separator, 1)

            local resList = make("Frame", {
                BackgroundTransparency = 1,
                Position               = UDim2.new(0, 0, 0, COL_HEADER_H + 22),
                Size                   = UDim2.new(1, 0, 0, 0),
                AutomaticSize          = Enum.AutomaticSize.Y,
            }, col)
            make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,1) }, resList)

            sb:GetPropertyChangedSignal("Text"):Connect(function()
                local q = string.lower(sb.Text)
                for _, c in ipairs(resList:GetChildren()) do
                    if not c:IsA("UIListLayout") then c:Destroy() end
                end
                if q == "" then return end
                local win2 = self._window
                for _, mod in ipairs(win2._allModules) do
                    if string.find(string.lower(mod._name), q, 1, true) then
                        local rb = make("TextButton", {
                            BackgroundColor3 = T.ModNormal, BorderSizePixel = 0,
                            Size = UDim2.new(1,0,0,MODULE_H), Text = "",
                            LayoutOrder = #resList:GetChildren() + 1,
                        }, resList)
                        make("TextLabel", {
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0,6,0,0), Size = UDim2.new(1,-22,1,0),
                            Text = string.upper(mod._name),
                            TextColor3 = T.TextPrimary, TextSize = 9, Font = T.Font,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                        }, rb)
                        local d2 = make("Frame", {
                            BackgroundColor3 = mod._enabled and T.Accent or T.ToggleOff,
                            BorderSizePixel  = 0,
                            AnchorPoint      = Vector2.new(0, 0.5),
                            Position         = UDim2.new(1,-(TOGGLE_SIZE+5), 0.5, 0),
                            Size             = UDim2.new(0,TOGGLE_SIZE,0,TOGGLE_SIZE), ZIndex=2,
                        }, rb)
                        corner(d2, 10)
                        rb.MouseEnter:Connect(function() rb.BackgroundColor3 = T.ModHover end)
                        rb.MouseLeave:Connect(function() rb.BackgroundColor3 = T.ModNormal end)
                        rb.MouseButton1Click:Connect(function()
                            mod._enabled = not mod._enabled
                            if mod._onToggle then mod._onToggle(mod._enabled) end
                            d2.BackgroundColor3       = mod._enabled and T.Accent or T.ToggleOff
                            mod._dot.BackgroundColor3 = mod._enabled and T.Accent or T.ToggleOff
                            mod._nameLabel.TextColor3 = mod._enabled and T.TextAccent or T.TextPrimary
                        end)
                        rb.MouseButton2Click:Connect(function()
                            if win2._activeModule then
                                win2._activeModule._row.BackgroundColor3 = T.ModNormal
                            end
                            win2._activeModule = mod
                            mod._row.BackgroundColor3 = T.ModActive
                            win2._openSettings(mod)
                        end)
                    end
                end
            end)
        end

        return Category
    end -- AddCategory

    function Window:AddSearchColumn()
        local cat = self:AddCategory("SEARCH")
        cat:_asSearchCol()
        return cat
    end

    function Window:Destroy()
        screenGui:Destroy()
    end

    return Window
end

return UILibrary
