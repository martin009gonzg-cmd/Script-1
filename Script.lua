-- ================================================
--   CHLOE X SCRIPT HUB v5.0 - Ultimate Edition
--   RGB + Save Config + Fixed Sliders + Improved UI
--   Compatible con Delta Executor
-- ================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local LocalPlayer      = Players.LocalPlayer

-- Eliminar UI previa
pcall(function()
    local old = LocalPlayer.PlayerGui:FindFirstChild("ChloeXHub")
    if old then
        local oldMain = old:FindFirstChild("MainFrame")
        if oldMain then
            TweenService:Create(oldMain, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 0)
            }):Play()
        end
        task.wait(0.35)
        old:Destroy()
    end
end)
pcall(function()
    local old2 = game:GetService("CoreGui"):FindFirstChild("ChloeXHub")
    if old2 then old2:Destroy() end
end)

-- ================================================
-- SISTEMA DE GUARDADO DE CONFIGURACIÓN
-- ================================================
local SavedConfig = {}

local function SaveConfig()
    pcall(function()
        local data = {
            AccentR      = SavedConfig.AccentR,
            AccentG      = SavedConfig.AccentG,
            AccentB      = SavedConfig.AccentB,
            BackgroundR  = SavedConfig.BackgroundR,
            BackgroundG  = SavedConfig.BackgroundG,
            BackgroundB  = SavedConfig.BackgroundB,
            UITransp     = SavedConfig.UITransp,
            BlurStrength = SavedConfig.BlurStrength,
            BorderGlow   = SavedConfig.BorderGlow,
            AnimSpeed    = SavedConfig.AnimSpeed,
            RGBEnabled   = SavedConfig.RGBEnabled,
            RGBSpeed     = SavedConfig.RGBSpeed,
            CornerRadius = SavedConfig.CornerRadius,
            UIScale      = SavedConfig.UIScale,
        }
        if writefile then
            writefile("ChloeX_Config.json", game:GetService("HttpService"):JSONEncode(data))
        end
    end)
end

local function LoadConfig()
    pcall(function()
        if readfile and isfile and isfile("ChloeX_Config.json") then
            local data = game:GetService("HttpService"):JSONDecode(readfile("ChloeX_Config.json"))
            for k, v in pairs(data) do
                SavedConfig[k] = v
            end
        end
    end)
end

LoadConfig()

-- ================================================
-- CONFIGURACIÓN Y FLAGS
-- ================================================
local Flags = {
    AutoFarm    = false,
    AutoCollect = false,
    AntiAFK     = false,
    InfJump     = false,
    SpeedHack   = false,
    ESPPlayers  = false,
    ESPNpcs     = false,
    Nametags    = false,
}

local Config = {
    AccentR       = SavedConfig.AccentR      or 0,
    AccentG       = SavedConfig.AccentG      or 180,
    AccentB       = SavedConfig.AccentB      or 255,
    BackgroundR   = SavedConfig.BackgroundR  or 10,
    BackgroundG   = SavedConfig.BackgroundG  or 15,
    BackgroundB   = SavedConfig.BackgroundB  or 25,
    UITransp      = SavedConfig.UITransp     or 0.05,
    BlurStrength  = SavedConfig.BlurStrength or 10,
    BorderGlow    = SavedConfig.BorderGlow ~= nil and SavedConfig.BorderGlow or true,
    AnimSpeed     = SavedConfig.AnimSpeed    or 0.3,
    RGBEnabled    = SavedConfig.RGBEnabled   or false,
    RGBSpeed      = SavedConfig.RGBSpeed     or 0.5,
    CornerRadius  = SavedConfig.CornerRadius or 12,
    UIScale       = SavedConfig.UIScale      or 1.0,

    FarmDist      = 100,
    SpeedVal      = 50,
    CollectRad    = 30,
    OrigSpeed     = 16,
    ESPFillTransp = 0.5,
}

local ESPList  = {}
local TagList  = {}
local farmConn, collectConn, jumpConn, afkConn, rgbConn
local isMinimized = false
local isDragging = false
local dragStart, startPos
local currentAccentColor = Color3.fromRGB(Config.AccentR, Config.AccentG, Config.AccentB)

-- ================================================
-- SISTEMA DE COLORES
-- ================================================
local C = {
    accent      = function() return Color3.fromRGB(Config.AccentR, Config.AccentG, Config.AccentB) end,
    background  = function() return Color3.fromRGB(Config.BackgroundR, Config.BackgroundG, Config.BackgroundB) end,
    white       = Color3.fromRGB(255, 255, 255),
    dim         = Color3.fromRGB(150, 160, 180),
    darkGray    = Color3.fromRGB(20, 25, 35),
    medGray     = Color3.fromRGB(30, 35, 45),
    green       = Color3.fromRGB(80, 220, 120),
    red         = Color3.fromRGB(255, 80, 100),
    yellow      = Color3.fromRGB(255, 200, 60),
}

-- ================================================
-- HELPERS
-- ================================================
local function GetChar() return LocalPlayer.Character end
local function GetRoot()
    local c = GetChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function GetHum()
    local c = GetChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait(1)
    if Flags.SpeedHack then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = Config.SpeedVal end
    end
end)

-- ================================================
-- LÓGICA DEL SCRIPT
-- ================================================
local function StartFarm()
    if farmConn then farmConn:Disconnect() end
    farmConn = RunService.Heartbeat:Connect(function()
        if not Flags.AutoFarm then farmConn:Disconnect() return end
        local root = GetRoot()
        local hum  = GetHum()
        if not root or not hum or hum.Health <= 0 then return end
        local nearest, nearDist = nil, Config.FarmDist
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= GetChar() then
                local h = obj:FindFirstChildOfClass("Humanoid")
                local r = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
                if h and h.Health > 0 and r then
                    local d = (root.Position - r.Position).Magnitude
                    if d < nearDist then nearest = obj; nearDist = d end
                end
            end
        end
        if nearest then
            local r = nearest:FindFirstChild("HumanoidRootPart") or nearest:FindFirstChild("Torso")
            if r then
                root.CFrame = CFrame.new(r.Position + Vector3.new(0, 2, 3))
                local tool = GetChar():FindFirstChildOfClass("Tool")
                if tool then pcall(function() tool:Activate() end) end
            end
        end
    end)
end

local function StartCollect()
    if collectConn then collectConn:Disconnect() end
    collectConn = RunService.Heartbeat:Connect(function()
        if not Flags.AutoCollect then collectConn:Disconnect() return end
        local root = GetRoot()
        if not root then return end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj.Anchored then
                local par = obj.Parent
                if par and not par:FindFirstChildOfClass("Humanoid") then
                    if (root.Position - obj.Position).Magnitude <= Config.CollectRad then
                        pcall(function()
                            root.CFrame = CFrame.new(obj.Position + Vector3.new(0, 2, 0))
                        end)
                    end
                end
            end
        end
    end)
end

local function StartInfJump()
    if jumpConn then jumpConn:Disconnect() end
    jumpConn = UserInputService.JumpRequest:Connect(function()
        if not Flags.InfJump then jumpConn:Disconnect() return end
        local h = GetHum()
        if h and h.Health > 0 then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end

local function ApplySpeed(on)
    local h = GetHum()
    if not h then return end
    if on then Config.OrigSpeed = h.WalkSpeed; h.WalkSpeed = Config.SpeedVal
    else h.WalkSpeed = Config.OrigSpeed end
end

local function StartAntiAFK()
    if afkConn then afkConn:Disconnect() end
    local vu = game:GetService("VirtualUser")
    afkConn = LocalPlayer.Idled:Connect(function()
        if not Flags.AntiAFK then afkConn:Disconnect() return end
        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(0.5)
        vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

local function CleanESP()
    for _, v in pairs(ESPList) do pcall(function() v:Destroy() end) end
    ESPList = {}
end

local function CleanTags()
    for _, v in pairs(TagList) do pcall(function() v:Destroy() end) end
    TagList = {}
end

local function RefreshESP()
    CleanESP()
    if not Flags.ESPPlayers then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local function addHL(char)
                if not char then return end
                task.wait(0.3)
                local hl = Instance.new("Highlight")
                hl.FillColor           = currentAccentColor
                hl.OutlineColor        = Color3.new(1,1,1)
                hl.FillTransparency    = Config.ESPFillTransp
                hl.OutlineTransparency = 0
                hl.Parent              = char
                table.insert(ESPList, hl)
            end
            pcall(function() addHL(p.Character) end)
            p.CharacterAdded:Connect(function(c)
                if Flags.ESPPlayers then pcall(function() addHL(c) end) end
            end)
        end
    end
end

local function RefreshNPCESP(on)
    for _, v in pairs(ESPList) do
        if v and v.Name == "NPCESP" then pcall(function() v:Destroy() end) end
    end
    if not on then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= GetChar() then
            local h = obj:FindFirstChildOfClass("Humanoid")
            if h then
                pcall(function()
                    local hl = Instance.new("Highlight")
                    hl.Name                = "NPCESP"
                    hl.FillColor           = Color3.fromRGB(255, 60, 60)
                    hl.OutlineColor        = Color3.fromRGB(255, 180, 180)
                    hl.FillTransparency    = Config.ESPFillTransp
                    hl.OutlineTransparency = 0
                    hl.Parent              = obj
                    table.insert(ESPList, hl)
                end)
            end
        end
    end
end

-- ================================================
-- SISTEMA DE NOTIFICACIONES TOAST
-- ================================================
local notifQueue = {}
local notifActive = false

local function ShowNotification(text, color, icon)
    table.insert(notifQueue, {text=text, color=color or C.green, icon=icon or "✅"})
end

-- ================================================
-- CREAR INTERFAZ
-- ================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ChloeXHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999

pcall(function() syn.protect_gui(ScreenGui) end)
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if ScreenGui.Parent == nil then ScreenGui.Parent = LocalPlayer.PlayerGui end

-- Container de notificaciones (Toast)
local NotifContainer = Instance.new("Frame")
NotifContainer.Name = "NotifContainer"
NotifContainer.Size = UDim2.new(0, 280, 1, 0)
NotifContainer.Position = UDim2.new(1, -290, 0, 0)
NotifContainer.BackgroundTransparency = 1
NotifContainer.Parent = ScreenGui

local NotifLayout = Instance.new("UIListLayout")
NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifLayout.Padding = UDim.new(0, 8)
NotifLayout.Parent = NotifContainer

local NotifPadding = Instance.new("UIPadding")
NotifPadding.PaddingBottom = UDim.new(0, 20)
NotifPadding.PaddingRight = UDim.new(0, 5)
NotifPadding.Parent = NotifContainer

-- Función para mostrar notificaciones
local function FireNotif(text, color, icon)
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(1, 0, 0, 50)
    notif.BackgroundColor3 = C.darkGray
    notif.BackgroundTransparency = 0.1
    notif.BorderSizePixel = 0
    notif.LayoutOrder = -os.clock()
    notif.Parent = NotifContainer

    local nc = Instance.new("UICorner")
    nc.CornerRadius = UDim.new(0, 10)
    nc.Parent = notif

    local ns = Instance.new("UIStroke")
    ns.Color = color or C.green
    ns.Thickness = 1.5
    ns.Transparency = 0.3
    ns.Parent = notif

    -- Barra de color lateral
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 4, 1, -10)
    bar.Position = UDim2.new(0, 0, 0, 5)
    bar.BackgroundColor3 = color or C.green
    bar.BorderSizePixel = 0
    bar.Parent = notif
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(1, 0)
    bc.Parent = bar

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 30, 1, 0)
    iconLabel.Position = UDim2.new(0, 10, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon or "✅"
    iconLabel.TextSize = 18
    iconLabel.Font = Enum.Font.Gotham
    iconLabel.Parent = notif

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -55, 1, 0)
    textLabel.Position = UDim2.new(0, 45, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = C.white
    textLabel.TextSize = 11
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextWrapped = true
    textLabel.Parent = notif

    -- Entrada
    notif.BackgroundTransparency = 1
    notif.Position = UDim2.new(1, 10, notif.Position.Y.Scale, notif.Position.Y.Offset)
    TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.1,
        Position = UDim2.new(0, 0, notif.Position.Y.Scale, notif.Position.Y.Offset)
    }):Play()

    -- Auto-destruir
    task.delay(3, function()
        TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, 10, notif.Position.Y.Scale, notif.Position.Y.Offset)
        }):Play()
        task.wait(0.35)
        pcall(function() notif:Destroy() end)
    end)
end

-- Frame principal
local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.Size = UDim2.new(0, 0, 0, 0)
Main.Position = UDim2.new(0.5, -300, 0.5, -200)
Main.BackgroundColor3 = C.background()
Main.BackgroundTransparency = 1
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Active = true
Main.Parent = ScreenGui

-- Animación de apertura con rebote
task.spawn(function()
    task.wait(0.05)
    TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 620, 0, 420),
        Position = UDim2.new(0.5, -310, 0.5, -210)
    }):Play()
    TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = Config.UITransp
    }):Play()
end)

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, Config.CornerRadius)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = currentAccentColor
MainStroke.Thickness = 2
MainStroke.Transparency = 0.3
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = Main

-- Sombra suave
local Shadow = Instance.new("Frame")
Shadow.Name = "Shadow"
Shadow.Size = UDim2.new(1, 20, 1, 20)
Shadow.Position = UDim2.new(0, -10, 0, 8)
Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Shadow.BackgroundTransparency = 0.7
Shadow.BorderSizePixel = 0
Shadow.ZIndex = Main.ZIndex - 1
Shadow.Parent = Main
local ShadowCorner = Instance.new("UICorner")
ShadowCorner.CornerRadius = UDim.new(0, 16)
ShadowCorner.Parent = Shadow

-- Glow animado del borde
local glowEnabled = true
task.spawn(function()
    while Main.Parent and glowEnabled do
        if Config.BorderGlow and not Config.RGBEnabled then
            TweenService:Create(MainStroke, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.05}):Play()
            task.wait(1.8)
            if Config.BorderGlow then
                TweenService:Create(MainStroke, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.55}):Play()
            end
            task.wait(1.8)
        else
            task.wait(0.5)
        end
    end
end)

-- Blur de fondo
local Blur = Instance.new("BlurEffect")
Blur.Size = 0
Blur.Parent = game:GetService("Lighting")
TweenService:Create(Blur, TweenInfo.new(0.6), {Size = Config.BlurStrength}):Play()

-- ================================================
-- SISTEMA RGB
-- ================================================
local rgbHue = 0
local function StartRGB()
    if rgbConn then rgbConn:Disconnect() end
    rgbConn = RunService.RenderStepped:Connect(function()
        if not Config.RGBEnabled then
            rgbConn:Disconnect()
            return
        end
        rgbHue = (rgbHue + Config.RGBSpeed * 0.005) % 1
        local col = Color3.fromHSV(rgbHue, 1, 1)
        currentAccentColor = col
        MainStroke.Color = col
        -- Actualiza elementos acento en tiempo real
    end)
end

-- ================================================
-- BARRA DE TÍTULO
-- ================================================
local TBar = Instance.new("Frame")
TBar.Name = "TitleBar"
TBar.Size = UDim2.new(1, 0, 0, 42)
TBar.BackgroundColor3 = C.darkGray
TBar.BackgroundTransparency = 0
TBar.BorderSizePixel = 0
TBar.ZIndex = 2
TBar.Parent = Main

local TBarCorner = Instance.new("UICorner")
TBarCorner.CornerRadius = UDim.new(0, 12)
TBarCorner.Parent = TBar

local TBarMask = Instance.new("Frame")
TBarMask.Size = UDim2.new(1, 0, 0, 12)
TBarMask.Position = UDim2.new(0, 0, 1, -12)
TBarMask.BackgroundColor3 = C.darkGray
TBarMask.BackgroundTransparency = 0
TBarMask.BorderSizePixel = 0
TBarMask.ZIndex = 2
TBarMask.Parent = TBar

-- Gradiente de la barra título
local TBarGrad = Instance.new("UIGradient")
TBarGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.darkGray),
    ColorSequenceKeypoint.new(1, C.medGray),
})
TBarGrad.Rotation = 90
TBarGrad.Parent = TBar

local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(0, 200, 1, 0)
Logo.Position = UDim2.new(0, 15, 0, 0)
Logo.BackgroundTransparency = 1
Logo.Text = "✦ CHLOE X"
Logo.TextColor3 = currentAccentColor
Logo.TextSize = 16
Logo.Font = Enum.Font.GothamBold
Logo.TextXAlignment = Enum.TextXAlignment.Left
Logo.TextTransparency = 1
Logo.ZIndex = 3
Logo.Parent = TBar

TweenService:Create(Logo, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()

local Version = Instance.new("TextLabel")
Version.Size = UDim2.new(0, 100, 1, 0)
Version.Position = UDim2.new(0, 100, 0, 0)
Version.BackgroundTransparency = 1
Version.Text = "[v5.0]"
Version.TextColor3 = C.dim
Version.TextSize = 10
Version.Font = Enum.Font.Gotham
Version.TextXAlignment = Enum.TextXAlignment.Left
Version.TextTransparency = 1
Version.ZIndex = 3
Version.Parent = TBar

TweenService:Create(Version, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()

-- Indicador de estado activo (punto pulsante)
local ActiveDot = Instance.new("Frame")
ActiveDot.Size = UDim2.new(0, 8, 0, 8)
ActiveDot.Position = UDim2.new(0, 155, 0.5, -4)
ActiveDot.BackgroundColor3 = C.green
ActiveDot.BorderSizePixel = 0
ActiveDot.ZIndex = 3
ActiveDot.Parent = TBar
local ADCorner = Instance.new("UICorner")
ADCorner.CornerRadius = UDim.new(1, 0)
ADCorner.Parent = ActiveDot

task.spawn(function()
    while Main.Parent do
        TweenService:Create(ActiveDot, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.8, Size = UDim2.new(0, 6, 0, 6)}):Play()
        task.wait(0.8)
        TweenService:Create(ActiveDot, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0, Size = UDim2.new(0, 8, 0, 8)}):Play()
        task.wait(0.8)
    end
end)

-- Botones de control mejorados
local function CreateControlButton(text, pos, color, shape)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 28, 0, 28)
    btn.Position = UDim2.new(1, pos, 0.5, -14)
    btn.BackgroundColor3 = color
    btn.BackgroundTransparency = 0.4
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = C.white
    btn.TextSize = 15
    btn.Font = Enum.Font.GothamBold
    btn.ZIndex = 4
    btn.Parent = TBar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = btn

    local stroke2 = Instance.new("UIStroke")
    stroke2.Color = color
    stroke2.Thickness = 1
    stroke2.Transparency = 0.6
    stroke2.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(1, pos - 1, 0.5, -15)
        }):Play()
        TweenService:Create(stroke2, TweenInfo.new(0.15), {Transparency = 0}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.4,
            Size = UDim2.new(0, 28, 0, 28),
            Position = UDim2.new(1, pos, 0.5, -14)
        }):Play()
        TweenService:Create(stroke2, TweenInfo.new(0.15), {Transparency = 0.6}):Play()
    end)
    return btn
end

local CloseBtn = CreateControlButton("×", -38, C.red)
local MinBtn   = CreateControlButton("—", -75, C.yellow)
local MaxBtn   = CreateControlButton("⊞", -112, C.green)  -- botón de restaurar/maximizar

-- ================================================
-- BARRA DE ESTADO
-- ================================================
local StatusBar = Instance.new("Frame")
StatusBar.Name = "StatusBar"
StatusBar.Size = UDim2.new(1, 0, 0, 26)
StatusBar.Position = UDim2.new(0, 0, 1, -26)
StatusBar.BackgroundColor3 = C.darkGray
StatusBar.BackgroundTransparency = 0
StatusBar.BorderSizePixel = 0
StatusBar.ZIndex = 2
StatusBar.Parent = Main

local SBCorner = Instance.new("UICorner")
SBCorner.CornerRadius = UDim.new(0, 12)
SBCorner.Parent = StatusBar

local SBMask = Instance.new("Frame")
SBMask.Size = UDim2.new(1, 0, 0, 12)
SBMask.Position = UDim2.new(0, 0, 0, 0)
SBMask.BackgroundColor3 = C.darkGray
SBMask.BackgroundTransparency = 0
SBMask.BorderSizePixel = 0
SBMask.ZIndex = 2
SBMask.Parent = StatusBar

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 6, 0, 6)
StatusDot.Position = UDim2.new(0, 10, 0.5, -3)
StatusDot.BackgroundColor3 = C.green
StatusDot.BorderSizePixel = 0
StatusDot.ZIndex = 3
StatusDot.Parent = StatusBar
local SDCorner = Instance.new("UICorner")
SDCorner.CornerRadius = UDim.new(1, 0)
SDCorner.Parent = StatusDot

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -90, 1, 0)
StatusLabel.Position = UDim2.new(0, 22, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "🟢 Ready"
StatusLabel.TextColor3 = C.green
StatusLabel.TextSize = 10
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.ZIndex = 3
StatusLabel.Parent = StatusBar

-- Reloj en tiempo real
local ClockLabel = Instance.new("TextLabel")
ClockLabel.Size = UDim2.new(0, 80, 1, 0)
ClockLabel.Position = UDim2.new(1, -85, 0, 0)
ClockLabel.BackgroundTransparency = 1
ClockLabel.TextColor3 = C.dim
ClockLabel.TextSize = 9
ClockLabel.Font = Enum.Font.Gotham
ClockLabel.TextXAlignment = Enum.TextXAlignment.Right
ClockLabel.ZIndex = 3
ClockLabel.Parent = StatusBar

task.spawn(function()
    while Main.Parent do
        local t = os.date("*t")
        ClockLabel.Text = string.format("%02d:%02d:%02d  ", t.hour, t.min, t.sec)
        task.wait(1)
    end
end)

local function SetStatus(text, color)
    local c = color or currentAccentColor
    TweenService:Create(StatusLabel, TweenInfo.new(0.12), {TextTransparency = 1, Position = UDim2.new(0, 18, 0, 0)}):Play()
    TweenService:Create(StatusDot, TweenInfo.new(0.12), {BackgroundColor3 = c}):Play()
    task.wait(0.13)
    StatusLabel.Text = text
    StatusLabel.TextColor3 = c
    TweenService:Create(StatusLabel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextTransparency = 0, Position = UDim2.new(0, 22, 0, 0)}):Play()
end

-- ================================================
-- SIDEBAR
-- ================================================
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 62, 1, -68)
Sidebar.Position = UDim2.new(0, 0, 0, 42)
Sidebar.BackgroundColor3 = C.darkGray
Sidebar.BackgroundTransparency = 0
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2
Sidebar.Parent = Main

-- Separador vertical
local SidebarDivider = Instance.new("Frame")
SidebarDivider.Size = UDim2.new(0, 1, 1, -10)
SidebarDivider.Position = UDim2.new(1, 0, 0, 5)
SidebarDivider.BackgroundColor3 = currentAccentColor
SidebarDivider.BackgroundTransparency = 0.7
SidebarDivider.BorderSizePixel = 0
SidebarDivider.ZIndex = 3
SidebarDivider.Parent = Sidebar

-- Área de contenido
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -62, 1, -68)
Content.Position = UDim2.new(0, 62, 0, 42)
Content.BackgroundColor3 = C.background()
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ClipsDescendants = true
Content.ZIndex = 2
Content.Parent = Main

-- ================================================
-- SISTEMA DE PESTAÑAS
-- ================================================
local currentTab = nil
local tabButtons = {}
local tabPanels = {}

local function CreateTabButton(id, icon, label, order)
    local btn = Instance.new("TextButton")
    btn.Name = id .. "Btn"
    btn.Size = UDim2.new(1, 0, 0, 52)
    btn.Position = UDim2.new(0, 0, 0, (order-1)*52)
    btn.BackgroundColor3 = C.medGray
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.ZIndex = 3
    btn.Parent = Sidebar

    -- Fondo activo
    local activeBg = Instance.new("Frame")
    activeBg.Size = UDim2.new(1, -4, 1, -4)
    activeBg.Position = UDim2.new(0, 2, 0, 2)
    activeBg.BackgroundColor3 = currentAccentColor
    activeBg.BackgroundTransparency = 1
    activeBg.BorderSizePixel = 0
    activeBg.ZIndex = 3
    activeBg.Parent = btn
    local abCorner = Instance.new("UICorner")
    abCorner.CornerRadius = UDim.new(0, 8)
    abCorner.Parent = activeBg

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(1, 0, 0, 26)
    iconLabel.Position = UDim2.new(0, 0, 0, 7)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.TextColor3 = C.dim
    iconLabel.TextSize = 20
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.ZIndex = 4
    iconLabel.Parent = btn

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 12)
    nameLabel.Position = UDim2.new(0, 0, 1, -14)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = label
    nameLabel.TextColor3 = C.dim
    nameLabel.TextSize = 8
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.ZIndex = 4
    nameLabel.Parent = btn

    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 3, 0, 0)
    indicator.Position = UDim2.new(0, 0, 0.5, 0)
    indicator.AnchorPoint = Vector2.new(0, 0.5)
    indicator.BackgroundColor3 = currentAccentColor
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 5
    indicator.Parent = btn
    local iCorner = Instance.new("UICorner")
    iCorner.CornerRadius = UDim.new(1, 0)
    iCorner.Parent = indicator

    tabButtons[id] = {btn=btn, icon=iconLabel, name=nameLabel, indicator=indicator, activeBg=activeBg}
    return btn
end

local function SwitchTab(tabId)
    if currentTab and tabPanels[currentTab] then
        local oldPanel = tabPanels[currentTab]
        TweenService:Create(oldPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(-0.15, 0, 0, 0)
        }):Play()
        TweenService:Create(oldPanel, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
        task.wait(0.2)
        oldPanel.Visible = false
        oldPanel.Position = UDim2.new(0, 0, 0, 0)
    end

    for id, tab in pairs(tabButtons) do
        if id == tabId then
            TweenService:Create(tab.icon, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextColor3 = currentAccentColor, TextSize = 22}):Play()
            TweenService:Create(tab.name, TweenInfo.new(0.2), {TextColor3 = currentAccentColor}):Play()
            TweenService:Create(tab.indicator, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 3, 0, 38)}):Play()
            TweenService:Create(tab.activeBg, TweenInfo.new(0.2), {BackgroundTransparency = 0.88}):Play()
        else
            TweenService:Create(tab.icon, TweenInfo.new(0.2), {TextColor3 = C.dim, TextSize = 20}):Play()
            TweenService:Create(tab.name, TweenInfo.new(0.2), {TextColor3 = C.dim}):Play()
            TweenService:Create(tab.indicator, TweenInfo.new(0.2), {Size = UDim2.new(0, 3, 0, 0)}):Play()
            TweenService:Create(tab.activeBg, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        end
    end

    if tabPanels[tabId] then
        local newPanel = tabPanels[tabId]
        newPanel.Visible = true
        newPanel.Position = UDim2.new(0.12, 0, 0, 0)
        newPanel.BackgroundTransparency = 1
        TweenService:Create(newPanel, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()
    end

    currentTab = tabId
end

local function CreatePanel(id)
    local panel = Instance.new("ScrollingFrame")
    panel.Name = id .. "Panel"
    panel.Size = UDim2.new(1, 0, 1, 0)
    panel.Position = UDim2.new(0, 0, 0, 0)
    panel.BackgroundTransparency = 1
    panel.BorderSizePixel = 0
    panel.ScrollBarThickness = 3
    panel.ScrollBarImageColor3 = currentAccentColor
    panel.CanvasSize = UDim2.new(0, 0, 0, 0)
    panel.Visible = false
    panel.ZIndex = 3
    panel.Parent = Content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = panel

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        panel.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)

    local padding = Instance.new("UIPadding")
    padding.PaddingTop    = UDim.new(0, 12)
    padding.PaddingLeft   = UDim.new(0, 12)
    padding.PaddingRight  = UDim.new(0, 12)
    padding.PaddingBottom = UDim.new(0, 12)
    padding.Parent = panel

    tabPanels[id] = panel
    return panel
end

-- ================================================
-- COMPONENTES DE UI
-- ================================================

local function CreateSection(parent, title)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 28)
    section.BackgroundTransparency = 1
    section.ZIndex = 3
    section.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = currentAccentColor
    label.TextSize = 11
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 4
    label.Parent = section

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 1, -4)
    line.BackgroundColor3 = currentAccentColor
    line.BackgroundTransparency = 0.65
    line.BorderSizePixel = 0
    line.ZIndex = 3
    line.Parent = section

    return section
end

-- Toggle
local function CreateToggle(parent, title, desc, callback)
    local toggle = Instance.new("Frame")
    toggle.Size = UDim2.new(1, 0, 0, 48)
    toggle.BackgroundColor3 = C.medGray
    toggle.BackgroundTransparency = 0.45
    toggle.BorderSizePixel = 0
    toggle.ZIndex = 3
    toggle.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = toggle

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.medGray
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = toggle

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -72, 0, 20)
    titleLabel.Position = UDim2.new(0, 12, 0, 6)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = C.white
    titleLabel.TextSize = 12
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 4
    titleLabel.Parent = toggle

    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -72, 0, 14)
    descLabel.Position = UDim2.new(0, 12, 0, 26)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = desc
    descLabel.TextColor3 = C.dim
    descLabel.TextSize = 9
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.ZIndex = 4
    descLabel.Parent = toggle

    local switchBtn = Instance.new("TextButton")
    switchBtn.Size = UDim2.new(0, 46, 0, 24)
    switchBtn.Position = UDim2.new(1, -58, 0.5, -12)
    switchBtn.BackgroundColor3 = C.darkGray
    switchBtn.BorderSizePixel = 0
    switchBtn.Text = ""
    switchBtn.ZIndex = 5
    switchBtn.Parent = toggle

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switchBtn

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = C.white
    knob.BorderSizePixel = 0
    knob.ZIndex = 6
    knob.Parent = switchBtn

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local state = false

    local function toggleClick()
        state = not state
        if state then
            TweenService:Create(switchBtn, TweenInfo.new(0.2), {BackgroundColor3 = currentAccentColor}):Play()
            TweenService:Create(knob, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(1, -21, 0.5, -9)}):Play()
            TweenService:Create(stroke, TweenInfo.new(0.2), {Color = currentAccentColor, Transparency = 0.2}):Play()
        else
            TweenService:Create(switchBtn, TweenInfo.new(0.2), {BackgroundColor3 = C.darkGray}):Play()
            TweenService:Create(knob, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 3, 0.5, -9)}):Play()
            TweenService:Create(stroke, TweenInfo.new(0.2), {Color = C.medGray, Transparency = 0.5}):Play()
        end
        TweenService:Create(toggle, TweenInfo.new(0.08), {BackgroundTransparency = 0.2}):Play()
        task.wait(0.09)
        TweenService:Create(toggle, TweenInfo.new(0.18), {BackgroundTransparency = 0.45}):Play()
        pcall(function() callback(state) end)
    end

    switchBtn.MouseButton1Click:Connect(toggleClick)
    toggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then toggleClick() end
    end)

    return toggle
end

-- ================================================
-- SLIDER ARREGLADO (problema del drag corregido)
-- ================================================
local function CreateSlider(parent, title, min, max, default, callback)
    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(1, 0, 0, 58)
    slider.BackgroundColor3 = C.medGray
    slider.BackgroundTransparency = 0.45
    slider.BorderSizePixel = 0
    slider.ZIndex = 3
    slider.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = slider

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0.65, 0, 0, 20)
    titleLabel.Position = UDim2.new(0, 12, 0, 6)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = C.white
    titleLabel.TextSize = 11
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 4
    titleLabel.Parent = slider

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.35, -12, 0, 20)
    valueLabel.Position = UDim2.new(0.65, 0, 0, 6)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = currentAccentColor
    valueLabel.TextSize = 12
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.ZIndex = 4
    valueLabel.Parent = slider

    -- Track del slider (zona clicable más grande)
    local trackFrame = Instance.new("Frame")
    trackFrame.Size = UDim2.new(1, -24, 0, 20)
    trackFrame.Position = UDim2.new(0, 12, 1, -28)
    trackFrame.BackgroundTransparency = 1
    trackFrame.ZIndex = 4
    trackFrame.Parent = slider

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, 0, 0, 6)
    sliderBg.Position = UDim2.new(0, 0, 0.5, -3)
    sliderBg.BackgroundColor3 = C.darkGray
    sliderBg.BorderSizePixel = 0
    sliderBg.ZIndex = 4
    sliderBg.Parent = trackFrame

    local sliderBgCorner = Instance.new("UICorner")
    sliderBgCorner.CornerRadius = UDim.new(1, 0)
    sliderBgCorner.Parent = sliderBg

    local initPct = (default - min) / (max - min)

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(initPct, 0, 1, 0)
    sliderFill.BackgroundColor3 = currentAccentColor
    sliderFill.BorderSizePixel = 0
    sliderFill.ZIndex = 5
    sliderFill.Parent = sliderBg

    local sliderFillCorner = Instance.new("UICorner")
    sliderFillCorner.CornerRadius = UDim.new(1, 0)
    sliderFillCorner.Parent = sliderFill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(initPct, -8, 0.5, -8)
    knob.BackgroundColor3 = C.white
    knob.BorderSizePixel = 0
    knob.ZIndex = 6
    knob.Parent = sliderBg

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local knobStroke = Instance.new("UIStroke")
    knobStroke.Color = currentAccentColor
    knobStroke.Thickness = 2
    knobStroke.Parent = knob

    local dragging = false
    local currentValue = default

    -- ARREGLO PRINCIPAL: usar AbsolutePosition y AbsoluteSize del sliderBg
    local function updateFromX(mouseX)
        local absX    = sliderBg.AbsolutePosition.X
        local absW    = sliderBg.AbsoluteSize.X
        local pct     = math.clamp((mouseX - absX) / absW, 0, 1)
        local value   = math.floor(min + (max - min) * pct + 0.5)
        currentValue  = value

        TweenService:Create(sliderFill, TweenInfo.new(0.07), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
        TweenService:Create(knob,       TweenInfo.new(0.07), {Position = UDim2.new(pct, -8, 0.5, -8)}):Play()
        valueLabel.Text = tostring(value)
        pcall(function() callback(value) end)
    end

    -- Iniciar drag con InputBegan en el track completo
    trackFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(input.Position.X)
            TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new((currentValue-min)/(max-min), -10, 0.5, -10)}):Play()
            TweenService:Create(knobStroke, TweenInfo.new(0.1), {Thickness = 3}):Play()
        end
    end)

    -- También en sliderBg por si acaso
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(input.Position.X)
            TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 20, 0, 20)}):Play()
            TweenService:Create(knobStroke, TweenInfo.new(0.1), {Thickness = 3}):Play()
        end
    end)

    -- MouseMovement global mientras dragging
    local moveConn = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                         input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end)

    -- Soltar en cualquier lugar
    local endConn = UserInputService.InputEnded:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or
            input.UserInputType == Enum.UserInputType.Touch) and dragging then
            dragging = false
            local pct = (currentValue - min) / (max - min)
            TweenService:Create(knob, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 16, 0, 16),
                Position = UDim2.new(pct, -8, 0.5, -8)
            }):Play()
            TweenService:Create(knobStroke, TweenInfo.new(0.15), {Thickness = 2}):Play()
        end
    end)

    return slider
end

-- Botón
local function CreateButton(parent, title, desc, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.BackgroundColor3 = currentAccentColor
    btn.BackgroundTransparency = 0.82
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.ZIndex = 3
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = currentAccentColor
    stroke.Thickness = 1
    stroke.Transparency = 0.55
    stroke.Parent = btn

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 20)
    titleLabel.Position = UDim2.new(0, 12, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = C.white
    titleLabel.TextSize = 12
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 4
    titleLabel.Parent = btn

    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -20, 0, 12)
    descLabel.Position = UDim2.new(0, 12, 0, 26)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = desc
    descLabel.TextColor3 = C.dim
    descLabel.TextSize = 9
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.ZIndex = 4
    descLabel.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.25}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {Thickness = 2, Transparency = 0}):Play()
        TweenService:Create(titleLabel, TweenInfo.new(0.2), {Position = UDim2.new(0, 16, 0, 5)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.82}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {Thickness = 1, Transparency = 0.55}):Play()
        TweenService:Create(titleLabel, TweenInfo.new(0.2), {Position = UDim2.new(0, 12, 0, 5)}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundTransparency = 0}):Play()
        task.wait(0.09)
        TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.3}):Play()
        pcall(function() callback() end)
    end)

    return btn
end

-- Color Picker
local function CreateColorPicker(parent, title, presets, callback)
    local picker = Instance.new("Frame")
    picker.Size = UDim2.new(1, 0, 0, 85)
    picker.BackgroundColor3 = C.medGray
    picker.BackgroundTransparency = 0.45
    picker.BorderSizePixel = 0
    picker.ZIndex = 3
    picker.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = picker

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 20)
    titleLabel.Position = UDim2.new(0, 12, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = C.white
    titleLabel.TextSize = 11
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 4
    titleLabel.Parent = picker

    local colorGrid = Instance.new("Frame")
    colorGrid.Size = UDim2.new(1, -20, 0, 44)
    colorGrid.Position = UDim2.new(0, 10, 0, 32)
    colorGrid.BackgroundTransparency = 1
    colorGrid.ZIndex = 4
    colorGrid.Parent = picker

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 36, 0, 36)
    gridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
    gridLayout.Parent = colorGrid

    local selectedDot = nil

    for _, preset in ipairs(presets) do
        local dot = Instance.new("TextButton")
        dot.Size = UDim2.new(0, 36, 0, 36)
        dot.BackgroundColor3 = preset.color
        dot.BorderSizePixel = 0
        dot.Text = ""
        dot.ZIndex = 5
        dot.Parent = colorGrid

        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dot

        local dotStroke = Instance.new("UIStroke")
        dotStroke.Color = C.white
        dotStroke.Thickness = 2
        dotStroke.Transparency = 1
        dotStroke.Parent = dot

        dot.MouseEnter:Connect(function()
            if dot ~= selectedDot then
                TweenService:Create(dot, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 39, 0, 39)}):Play()
            end
        end)
        dot.MouseLeave:Connect(function()
            if dot ~= selectedDot then
                TweenService:Create(dot, TweenInfo.new(0.15), {Size = UDim2.new(0, 36, 0, 36)}):Play()
            end
        end)
        dot.MouseButton1Click:Connect(function()
            if selectedDot then
                local os2 = selectedDot:FindFirstChildOfClass("UIStroke")
                if os2 then TweenService:Create(os2, TweenInfo.new(0.15), {Transparency = 1}):Play() end
                TweenService:Create(selectedDot, TweenInfo.new(0.15), {Size = UDim2.new(0, 36, 0, 36)}):Play()
            end
            selectedDot = dot
            TweenService:Create(dotStroke, TweenInfo.new(0.15), {Transparency = 0}):Play()
            TweenService:Create(dot, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 40, 0, 40)}):Play()
            if callback then callback(preset.color, preset) end
        end)
    end

    return picker
end

-- Label de información
local function CreateInfoLabel(parent, text)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundColor3 = C.medGray
    frame.BackgroundTransparency = 0.7
    frame.BorderSizePixel = 0
    frame.ZIndex = 3
    frame.Parent = parent

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 10)
    fc.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, -12)
    label.Position = UDim2.new(0, 10, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = C.dim
    label.TextSize = 10
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.TextWrapped = true
    label.ZIndex = 4
    label.Parent = frame

    return frame
end

-- ================================================
-- ARMAR PESTAÑAS
-- ================================================
local fishBtn   = CreateTabButton("fishing", "🎣", "Fishing", 1)
local autoBtn   = CreateTabButton("auto",    "⚡", "Auto",    2)
local miniBtn   = CreateTabButton("mini",    "👁️", "ESP",     3)
local scriptBtn = CreateTabButton("scripts", "📜", "Scripts", 4)
local miscBtn   = CreateTabButton("misc",    "🛠️", "Misc",    5)
local configBtn = CreateTabButton("config",  "🎨", "Config",  6)

local pFishing = CreatePanel("fishing")
local pAuto    = CreatePanel("auto")
local pMini    = CreatePanel("mini")
local pScripts = CreatePanel("scripts")
local pMisc    = CreatePanel("misc")
local pConfig  = CreatePanel("config")

fishBtn.MouseButton1Click:Connect(function()   SwitchTab("fishing") end)
autoBtn.MouseButton1Click:Connect(function()   SwitchTab("auto")    end)
miniBtn.MouseButton1Click:Connect(function()   SwitchTab("mini")    end)
scriptBtn.MouseButton1Click:Connect(function() SwitchTab("scripts") end)
miscBtn.MouseButton1Click:Connect(function()   SwitchTab("misc")    end)
configBtn.MouseButton1Click:Connect(function() SwitchTab("config")  end)

-- ═══════════════════════ FISHING ═══════════════════════
CreateSection(pFishing, "🎣 Fishing Features")
CreateToggle(pFishing, "Auto Fish", "Pesca automáticamente", function(v)
    Flags.AutoFarm = v
    if v then StartFarm(); SetStatus("🎣 Auto Fish activado", C.green)
    else SetStatus("🎣 Auto Fish desactivado", C.red) end
    FireNotif(v and "Auto Fish activado" or "Auto Fish desactivado", v and C.green or C.red, "🎣")
end)

CreateSection(pFishing, "⚙️ Catching Settings")
CreateSlider(pFishing, "Catching Delay", 0, 10, 2, function(v)
    Config.FarmDist = v * 10
    SetStatus("Delay: " .. v .. "s", C.yellow)
end)

CreateSlider(pFishing, "Farm Distance", 10, 300, 100, function(v)
    Config.FarmDist = v
    SetStatus("Distancia: " .. v .. " studs", C.yellow)
end)

CreateButton(pFishing, "▶️  Start Farm", "Inicia el sistema de farm", function()
    if not Flags.AutoFarm then
        Flags.AutoFarm = true; StartFarm()
        SetStatus("✅ Auto farm iniciado", C.green)
        FireNotif("Auto Farm iniciado correctamente", C.green, "✅")
    else
        SetStatus("ℹ️ Ya está activo", C.yellow)
    end
end)

CreateButton(pFishing, "⏹️  Stop Farm", "Detiene el auto farm", function()
    Flags.AutoFarm = false
    SetStatus("⏹️ Farm detenido", C.red)
    FireNotif("Auto Farm detenido", C.red, "⏹️")
end)

-- ═══════════════════════ AUTO ═══════════════════════
CreateSection(pAuto, "✨ Auto Features")
CreateToggle(pAuto, "Auto Collect Items", "Recoge drops automáticamente", function(v)
    Flags.AutoCollect = v
    if v then StartCollect(); SetStatus("💎 Auto Collect activado", C.green)
    else SetStatus("💎 Auto Collect desactivado", C.red) end
    FireNotif(v and "Auto Collect activado" or "Auto Collect desactivado", v and C.green or C.red, "💎")
end)

CreateSlider(pAuto, "Collect Radius", 5, 150, 30, function(v)
    Config.CollectRad = v
    SetStatus("Radio: " .. v .. " studs", C.yellow)
end)

CreateSection(pAuto, "🏃 Movement")
CreateToggle(pAuto, "Infinite Jump", "Salto infinito activado", function(v)
    Flags.InfJump = v
    if v then StartInfJump(); SetStatus("🦘 Infinite Jump activado", C.green)
    else SetStatus("🦘 Infinite Jump desactivado", C.red) end
end)

CreateToggle(pAuto, "Speed Hack", "Aumenta tu velocidad", function(v)
    Flags.SpeedHack = v; ApplySpeed(v)
    if v then SetStatus("⚡ Speed Hack activado", C.green)
    else SetStatus("⚡ Speed Hack desactivado", C.red) end
end)

CreateSlider(pAuto, "Speed Value", 16, 300, 50, function(v)
    Config.SpeedVal = v
    if Flags.SpeedHack then local h = GetHum(); if h then h.WalkSpeed = v end end
    SetStatus("Velocidad: " .. v, C.yellow)
end)

-- ═══════════════════════ ESP ═══════════════════════
CreateSection(pMini, "👁️ ESP Features")
CreateToggle(pMini, "ESP Players", "Highlight en jugadores", function(v)
    Flags.ESPPlayers = v; RefreshESP()
    if v then SetStatus("👁️ ESP Players activado", C.green)
    else CleanESP(); SetStatus("👁️ ESP Players desactivado", C.red) end
end)

CreateToggle(pMini, "ESP NPCs", "Highlight en enemigos/NPCs", function(v)
    Flags.ESPNpcs = v; RefreshNPCESP(v)
    if v then SetStatus("🎯 ESP NPCs activado", C.green)
    else SetStatus("🎯 ESP NPCs desactivado", C.red) end
end)

CreateSlider(pMini, "ESP Fill Transparency", 0, 9, 5, function(v)
    Config.ESPFillTransp = v / 10
    for _, hl in pairs(ESPList) do
        if hl and hl.Parent then hl.FillTransparency = Config.ESPFillTransp end
    end
    SetStatus("ESP Transparencia: " .. (v * 10) .. "%", C.yellow)
end)

CreateSection(pMini, "🔄 ESP Actions")
CreateButton(pMini, "🔄 Refresh ESP", "Actualiza el ESP de jugadores", function()
    RefreshESP(); SetStatus("🔄 ESP actualizado", C.green)
    FireNotif("ESP actualizado", C.green, "🔄")
end)

CreateButton(pMini, "🗑️ Clear All ESP", "Elimina todos los highlights", function()
    CleanESP(); CleanTags(); SetStatus("🗑️ ESP limpiado", C.yellow)
end)

-- ═══════════════════════ SCRIPTS ═══════════════════════
CreateSection(pScripts, "📜 External Scripts")

CreateButton(pScripts, "▶️  Climb For Brainrots", "Ejecuta script externo", function()
    SetStatus("⏳ Cargando script...", C.yellow)
    task.spawn(function()
        local ok, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/ClimbForBrainrots"))()
        end)
        if ok then
            SetStatus("✅ Script ejecutado", C.green)
            FireNotif("Script ejecutado correctamente", C.green, "✅")
        else
            SetStatus("❌ Error al cargar", C.red)
            FireNotif("Error al ejecutar script", C.red, "❌")
            warn("Error:", err)
        end
    end)
end)

CreateButton(pScripts, "▶️  Emote Script", "Ejecuta el script de emotes", function()
    SetStatus("⏳ Cargando emotes...", C.yellow)
    task.spawn(function()
        local ok, err = pcall(function()
            loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-7yd7-I-Emote-Script-48024"))()
        end)
        if ok then SetStatus("✅ Emote Script cargado", C.green)
        else SetStatus("❌ Error al cargar emotes", C.red); warn(err) end
    end)
end)

CreateInfoLabel(pScripts, "⚠️ Requiere HttpGet habilitado en Delta Executor.\n💡 Los scripts se ejecutan en segundo plano.")

-- ═══════════════════════ MISC ═══════════════════════
CreateSection(pMisc, "🛠️ Utilities")
CreateToggle(pMisc, "Anti AFK", "Evita desconexión por inactividad", function(v)
    Flags.AntiAFK = v
    if v then StartAntiAFK(); SetStatus("😴 Anti AFK activado", C.green)
    else SetStatus("😴 Anti AFK desactivado", C.red) end
end)

CreateButton(pMisc, "🔄 Rejoin Server", "Reconecta al servidor actual", function()
    SetStatus("🔄 Reconectando...", C.yellow)
    task.wait(0.5)
    pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end)
end)

CreateButton(pMisc, "💀 Reset Character", "Respawnea tu personaje", function()
    local h = GetHum()
    if h then h.Health = 0; SetStatus("💀 Personaje reseteado", C.yellow) end
end)

CreateButton(pMisc, "📋 Copy PlaceId", "Copia el ID del juego actual", function()
    pcall(function()
        setclipboard(tostring(game.PlaceId))
        SetStatus("📋 PlaceId copiado: " .. game.PlaceId, C.green)
        FireNotif("PlaceId copiado!", C.green, "📋")
    end)
end)

CreateButton(pMisc, "📸 Copy Job Id", "Copia el ID del servidor", function()
    pcall(function()
        setclipboard(game.JobId)
        SetStatus("📸 JobId copiado", C.green)
        FireNotif("JobId copiado!", C.green, "📸")
    end)
end)

-- ═══════════════════════ CONFIG ═══════════════════════
CreateSection(pConfig, "🎨 Accent Color")
CreateColorPicker(pConfig, "Color de Acento", {
    {label="Cyan",   color=Color3.fromRGB(0,   180, 255), r=0,   g=180, b=255},
    {label="Green",  color=Color3.fromRGB(0,   220, 130), r=0,   g=220, b=130},
    {label="Purple", color=Color3.fromRGB(160, 60,  255), r=160, g=60,  b=255},
    {label="Pink",   color=Color3.fromRGB(255, 60,  160), r=255, g=60,  b=160},
    {label="Orange", color=Color3.fromRGB(255, 140, 30),  r=255, g=140, b=30 },
    {label="Red",    color=Color3.fromRGB(220, 50,  80),  r=220, g=50,  b=80 },
    {label="Gold",   color=Color3.fromRGB(255, 200, 0),   r=255, g=200, b=0  },
    {label="Teal",   color=Color3.fromRGB(0,   200, 180), r=0,   g=200, b=180},
}, function(col, preset)
    Config.AccentR = preset.r; Config.AccentG = preset.g; Config.AccentB = preset.b
    currentAccentColor = col

    -- Desactivar RGB si se elige un color manual
    Config.RGBEnabled = false

    MainStroke.Color = col
    Logo.TextColor3 = col
    SidebarDivider.BackgroundColor3 = col

    for id, tab in pairs(tabButtons) do
        tab.indicator.BackgroundColor3 = col
        tab.activeBg.BackgroundColor3 = col
        if currentTab == id then
            tab.icon.TextColor3 = col
            tab.name.TextColor3 = col
        end
    end
    for _, panel in pairs(tabPanels) do
        panel.ScrollBarImageColor3 = col
    end
    if Flags.ESPPlayers then RefreshESP() end
    SetStatus("🎨 Color: " .. preset.label, col)
end)

CreateSection(pConfig, "🌈 RGB Mode")
CreateToggle(pConfig, "RGB Effect", "Color de acento arcoíris animado", function(v)
    Config.RGBEnabled = v
    if v then
        StartRGB()
        SetStatus("🌈 RGB activado", C.green)
        FireNotif("Modo RGB activado 🌈", C.green, "🌈")
    else
        if rgbConn then rgbConn:Disconnect() end
        currentAccentColor = Color3.fromRGB(Config.AccentR, Config.AccentG, Config.AccentB)
        MainStroke.Color = currentAccentColor
        SetStatus("🌈 RGB desactivado", C.red)
    end
end)

CreateSlider(pConfig, "RGB Speed", 1, 20, 5, function(v)
    Config.RGBSpeed = v / 10
    SetStatus("Velocidad RGB: " .. (v / 10), C.yellow)
end)

CreateSection(pConfig, "✨ Transparency")
CreateSlider(pConfig, "UI Transparency", 0, 8, 0, function(v)
    Config.UITransp = v / 10
    TweenService:Create(Main,    TweenInfo.new(0.2), {BackgroundTransparency = Config.UITransp}):Play()
    TweenService:Create(TBar,    TweenInfo.new(0.2), {BackgroundTransparency = Config.UITransp == 0 and 0 or Config.UITransp}):Play()
    TweenService:Create(Sidebar, TweenInfo.new(0.2), {BackgroundTransparency = Config.UITransp}):Play()
    TweenService:Create(StatusBar, TweenInfo.new(0.2), {BackgroundTransparency = Config.UITransp}):Play()
    SetStatus("Transparencia: " .. (v * 10) .. "%", C.yellow)
end)

CreateSlider(pConfig, "Blur Strength", 0, 20, 10, function(v)
    Config.BlurStrength = v
    TweenService:Create(Blur, TweenInfo.new(0.3), {Size = v}):Play()
    SetStatus("Blur: " .. v, C.yellow)
end)

CreateSection(pConfig, "🖼️ Background")
CreateColorPicker(pConfig, "Color de Fondo", {
    {label="Dark Blue",   color=Color3.fromRGB(10, 15, 25)},
    {label="Dark Purple", color=Color3.fromRGB(15, 10, 25)},
    {label="Dark Gray",   color=Color3.fromRGB(15, 15, 20)},
    {label="Black",       color=Color3.fromRGB(5,  5,  10)},
    {label="Navy",        color=Color3.fromRGB(5,  10, 30)},
    {label="Forest",      color=Color3.fromRGB(5,  15, 10)},
}, function(col)
    TweenService:Create(Main,    TweenInfo.new(0.3), {BackgroundColor3 = col}):Play()
    TweenService:Create(Content, TweenInfo.new(0.3), {BackgroundColor3 = col}):Play()
    Config.BackgroundR = math.floor(col.R * 255)
    Config.BackgroundG = math.floor(col.G * 255)
    Config.BackgroundB = math.floor(col.B * 255)
    SetStatus("🖼️ Fondo actualizado", currentAccentColor)
end)

CreateSection(pConfig, "🔵 Corner & Scale")
CreateSlider(pConfig, "Corner Radius", 0, 20, Config.CornerRadius, function(v)
    Config.CornerRadius = v
    MainCorner.CornerRadius = UDim.new(0, v)
    TBarCorner.CornerRadius = UDim.new(0, v)
    SBCorner.CornerRadius   = UDim.new(0, v)
    SetStatus("Radio esquinas: " .. v, C.yellow)
end)

CreateSlider(pConfig, "UI Scale", 7, 13, 10, function(v)
    Config.UIScale = v / 10
    local w = math.floor(620 * Config.UIScale)
    local h = math.floor(420 * Config.UIScale)
    TweenService:Create(Main, TweenInfo.new(0.3), {
        Size = UDim2.new(0, w, 0, h),
        Position = UDim2.new(0.5, -w/2, 0.5, -h/2)
    }):Play()
    SetStatus("Escala UI: " .. Config.UIScale, C.yellow)
end)

CreateSection(pConfig, "⚡ Animation")
CreateSlider(pConfig, "Animation Speed", 1, 10, 3, function(v)
    Config.AnimSpeed = v / 10
    SetStatus("Velocidad animación: " .. (v / 10) .. "s", C.yellow)
end)

CreateToggle(pConfig, "Border Glow Effect", "Efecto de brillo pulsante en el borde", function(v)
    Config.BorderGlow = v
    if v then SetStatus("✨ Border Glow activado", C.green)
    else MainStroke.Transparency = 0.35; SetStatus("✨ Border Glow desactivado", C.red) end
end)

-- ── Botón de guardar configuración ──────────────────────
CreateSection(pConfig, "💾 Save Config")
CreateButton(pConfig, "💾 Guardar Ajustes", "Guarda todos los ajustes actuales", function()
    SavedConfig.AccentR      = Config.AccentR
    SavedConfig.AccentG      = Config.AccentG
    SavedConfig.AccentB      = Config.AccentB
    SavedConfig.BackgroundR  = Config.BackgroundR
    SavedConfig.BackgroundG  = Config.BackgroundG
    SavedConfig.BackgroundB  = Config.BackgroundB
    SavedConfig.UITransp     = Config.UITransp
    SavedConfig.BlurStrength = Config.BlurStrength
    SavedConfig.BorderGlow   = Config.BorderGlow
    SavedConfig.AnimSpeed    = Config.AnimSpeed
    SavedConfig.RGBEnabled   = Config.RGBEnabled
    SavedConfig.RGBSpeed     = Config.RGBSpeed
    SavedConfig.CornerRadius = Config.CornerRadius
    SavedConfig.UIScale      = Config.UIScale
    SaveConfig()
    SetStatus("💾 Configuración guardada!", C.green)
    FireNotif("✅ Ajustes guardados correctamente", C.green, "💾")
end)

CreateButton(pConfig, "🔄 Reset Config", "Resetea todos los ajustes al default", function()
    Config.AccentR = 0; Config.AccentG = 180; Config.AccentB = 255
    Config.UITransp = 0.05; Config.BlurStrength = 10
    Config.BorderGlow = true; Config.AnimSpeed = 0.3
    Config.RGBEnabled = false; Config.CornerRadius = 12
    currentAccentColor = Color3.fromRGB(0, 180, 255)
    MainStroke.Color = currentAccentColor
    MainCorner.CornerRadius = UDim.new(0, 12)
    Logo.TextColor3 = currentAccentColor
    TweenService:Create(Blur, TweenInfo.new(0.3), {Size = 10}):Play()
    TweenService:Create(Main, TweenInfo.new(0.3), {
        Size = UDim2.new(0, 620, 0, 420),
        Position = UDim2.new(0.5, -310, 0.5, -210)
    }):Play()
    SetStatus("🔄 Config reseteada al default", C.yellow)
    FireNotif("Configuración reseteada", C.yellow, "🔄")
end)

CreateInfoLabel(pConfig, "💾 Los ajustes se guardan en ChloeX_Config.json\n⚠️ Requiere executor con soporte de writefile.")

-- ================================================
-- BOTONES DE CONTROL (Cerrar / Minimizar / Maximizar)
-- ================================================
local normalW, normalH = 620, 420

-- Cerrar
CloseBtn.MouseButton1Click:Connect(function()
    SetStatus("👋 Cerrando...", C.red)

    TweenService:Create(Blur, TweenInfo.new(0.4), {Size = 0}):Play()

    -- Efecto de cierre: escalar hacia el centro + rotar leve + fade
    TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(Main.Position.X.Scale, Main.Position.X.Offset + normalW/2,
                             Main.Position.Y.Scale, Main.Position.Y.Offset + normalH/2),
        BackgroundTransparency = 1
    }):Play()

    task.spawn(function()
        for i = 1, 6 do
            TweenService:Create(Main, TweenInfo.new(0.07), {Rotation = i * 8}):Play()
            task.wait(0.07)
        end
    end)

    task.wait(0.5)
    glowEnabled = false
    if farmConn   then farmConn:Disconnect()   end
    if collectConn then collectConn:Disconnect() end
    if jumpConn   then jumpConn:Disconnect()   end
    if afkConn    then afkConn:Disconnect()    end
    if rgbConn    then rgbConn:Disconnect()    end
    CleanESP(); CleanTags()
    pcall(function() ScreenGui:Destroy() end)
end)

-- Minimizar
local minimizedW, minimizedH = 240, 44
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized

    if isMinimized then
        SetStatus("📦 Minimizado", C.yellow)

        -- Fade out del contenido
        Content.Visible   = false
        Sidebar.Visible   = false
        StatusBar.Visible = false
        ActiveDot.Visible = false

        -- Animar a la barra mínima con bounce
        TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), {
            Size     = UDim2.new(0, minimizedW, 0, minimizedH),
            Position = UDim2.new(0.5, -minimizedW/2, 0, 15)
        }):Play()

        -- Actualizar logo
        task.wait(0.3)
        TweenService:Create(Logo, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        task.wait(0.21)
        Logo.Text = "✦ CHLOE X  •  minimized"
        Logo.TextSize = 11
        TweenService:Create(Logo, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
        Version.Visible = false

        MinBtn.Text = "□"
        MinBtn.BackgroundColor3 = C.green

        -- Pulso en el borde cuando minimizado
        task.spawn(function()
            while isMinimized and Main.Parent do
                TweenService:Create(MainStroke, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {Transparency = 0}):Play()
                task.wait(0.6)
                TweenService:Create(MainStroke, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {Transparency = 0.75}):Play()
                task.wait(0.6)
            end
        end)

        -- Arrastre funciona en modo minimizado también
        isDragging = false

    else
        -- Restaurar
        MinBtn.Text = "—"
        MinBtn.BackgroundColor3 = C.yellow
        Version.Visible = true

        TweenService:Create(Logo, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        task.wait(0.21)
        Logo.Text = "✦ CHLOE X"
        Logo.TextSize = 16
        TweenService:Create(Logo, TweenInfo.new(0.2), {TextTransparency = 0}):Play()

        -- Calcular posición restaurada centrada
        local scaledW = math.floor(normalW * Config.UIScale)
        local scaledH = math.floor(normalH * Config.UIScale)

        TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size     = UDim2.new(0, scaledW, 0, scaledH),
            Position = UDim2.new(0.5, -scaledW/2, 0.5, -scaledH/2)
        }):Play()

        task.wait(0.48)
        Content.Visible   = true
        Sidebar.Visible   = true
        StatusBar.Visible = true
        ActiveDot.Visible = true

        -- Fade in del contenido
        for _, child in ipairs(Content:GetChildren()) do
            if child:IsA("ScrollingFrame") then
                TweenService:Create(child, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
            end
        end

        MainStroke.Transparency = 0.3
        SetStatus("📂 Restaurado", C.green)
    end
end)

-- Maximizar / centrar (botón verde ⊞)
MaxBtn.MouseButton1Click:Connect(function()
    if not isMinimized then
        local scaledW = math.floor(normalW * Config.UIScale)
        local scaledH = math.floor(normalH * Config.UIScale)
        TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size     = UDim2.new(0, scaledW, 0, scaledH),
            Position = UDim2.new(0.5, -scaledW/2, 0.5, -scaledH/2),
            Rotation = 0
        }):Play()
        SetStatus("⊞ Ventana centrada", C.green)
        FireNotif("Ventana centrada", C.green, "⊞")
    end
end)

-- ================================================
-- SISTEMA DE ARRASTRE MEJORADO
-- ================================================
-- Funciona tanto normal como minimizado
TBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        dragStart  = input.Position
        startPos   = Main.Position

        TweenService:Create(MainStroke, TweenInfo.new(0.15), {Thickness = 3, Transparency = 0}):Play()

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
                TweenService:Create(MainStroke, TweenInfo.new(0.25), {Thickness = 2, Transparency = 0.3}):Play()
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ================================================
-- INICIALIZACIÓN
-- ================================================
task.wait(0.1)
SwitchTab("fishing")
SetStatus("🎉 Chloe X v5.0 cargado!", C.green)

-- Si había RGB guardado, iniciarlo
if Config.RGBEnabled then
    task.wait(0.5)
    StartRGB()
end

-- Secuencia de bienvenida
task.spawn(function()
    task.wait(0.8)
    FireNotif("¡Bienvenido a Chloe X v5.0! ✨", currentAccentColor, "🎮")
    task.wait(3)
    SetStatus("✅ Todos los sistemas listos", currentAccentColor)
    task.wait(2)
    SetStatus("💡 Usa las pestañas para navegar", C.dim)
end)

print("════════════════════════════════════════")
print("  🎮 CHLOE X v5.0 - Ultimate Edition")
print("  ✅ Cargado correctamente!")
print("  🌈 RGB + Save Config + Fixed Sliders")
print("  ✨ Improved Animations & Toast Notifs")
print("  💾 Auto-load config enabled")
print("════════════════════════════════════════")
