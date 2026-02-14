-- ================================================
--   CHLOE X SCRIPT HUB v5.0 - ULTRA EDITION
--   🎨 Diseño Moderno con Iconos Lucide
--   💾 Sistema de Guardado Automático
--   🔑 Keybinds Personalizables
--   ✨ Animaciones y Efectos Avanzados
-- ================================================

-- Servicios de Roblox
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- ================================================
-- CONFIGURACIÓN Y FLAGS
-- ================================================
local Config = {
    -- UI
    UITransp = 0.08,
    BlurStrength = 10,
    AnimSpeed = 0.28,
    BorderGlow = true,
    
    -- Funcionalidades
    FarmDist = 100,
    SpeedVal = 50,
    CollectRad = 30,
    OrigSpeed = 16,
    ESPFillTransp = 0.5,
    
    -- Keybinds
    ToggleKey = Enum.KeyCode.RightShift,
    FarmKey = Enum.KeyCode.F,
    ESPKey = Enum.KeyCode.E,
    
    -- Guardado
    SaveFileName = "ChloeXHub_Config.json"
}

local Flags = {
    AutoFarm = false,
    AutoCollect = false,
    AntiAFK = false,
    InfJump = false,
    SpeedHack = false,
    ESPPlayers = false,
    ESPNpcs = false,
    Notifications = true,
    Particles = true,
}

-- Variables globales
local ESPList = {}
local SavedTeleports = {}
local ActionHistory = {}
local farmConn, collectConn, jumpConn, afkConn
local isMinimized = false
local isDragging, dragOffsetX, dragOffsetY = false, 0, 0
local currentAccentColor = Color3.fromRGB(0, 180, 255)
local rgbEnabled = false
local rgbHue = 0

-- ================================================
-- ICONOS LUCIDE MODERNOS
-- ================================================
local Icons = {
    -- Navegación
    home = "rbxassetid://10723434711",
    settings = "rbxassetid://10734950309",
    folder = "rbxassetid://10723407389",
    
    -- Farming
    target = "rbxassetid://10723407389",
    zap = "rbxassetid://10747372992",
    activity = "rbxassetid://10723343537",
    
    -- Jugador
    user = "rbxassetid://10734949856",
    users = "rbxassetid://10747373176",
    eye = "rbxassetid://10723345554",
    
    -- Acciones
    play = "rbxassetid://10734896812",
    pause = "rbxassetid://10734896206",
    check = "rbxassetid://10734887784",
    x = "rbxassetid://10747384394",
    
    -- Utilidades
    save = "rbxassetid://10734952273",
    download = "rbxassetid://10723345619",
    upload = "rbxassetid://10734949856",
    trash = "rbxassetid://10734884548",
    
    -- Navegación
    mapPin = "rbxassetid://10723392854",
    navigation = "rbxassetid://10723407389",
    
    -- Efectos
    star = "rbxassetid://10734896629",
    sparkles = "rbxassetid://10734952273",
    zap2 = "rbxassetid://10747384394",
}

-- ================================================
-- SONIDOS
-- ================================================
local Sounds = {}
local function CreateSound(id, vol, pitch)
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://" .. id
    s.Volume = vol or 0.5
    s.PlaybackSpeed = pitch or 1
    s.RollOffMaxDistance = 0
    s.Parent = SoundService
    return s
end

Sounds.Click = CreateSound("4307186075", 0.5, 1)
Sounds.Hover = CreateSound("408524543", 0.2, 1.1)
Sounds.ToggleOn = CreateSound("9114603594", 0.5, 1)
Sounds.ToggleOff = CreateSound("9114221223", 0.4, 1)
Sounds.Notify = CreateSound("4590657391", 0.4, 1)
Sounds.Tab = CreateSound("4590657391", 0.25, 1.3)
Sounds.Success = CreateSound("9113627967", 0.6, 1)
Sounds.Error = CreateSound("9113613390", 0.5, 1)

local function PlaySound(s)
    pcall(function() if s and s.Parent then s:Stop(); s:Play() end end)
end

-- Limpiar UI previa
pcall(function()
    local g = game:GetService("CoreGui"):FindFirstChild("ChloeXHub")
    if g then g:Destroy() end
    local p = LocalPlayer.PlayerGui:FindFirstChild("ChloeXHub")
    if p then p:Destroy() end
end)

-- ================================================
-- COLORES
-- ================================================
local C = {
    white = Color3.fromRGB(255, 255, 255),
    dim = Color3.fromRGB(148, 162, 186),
    dark = Color3.fromRGB(9, 11, 20),
    panel = Color3.fromRGB(14, 18, 30),
    green = Color3.fromRGB(72, 214, 114),
    red = Color3.fromRGB(255, 70, 90),
    yellow = Color3.fromRGB(255, 198, 55),
    blue = Color3.fromRGB(0, 180, 255),
    purple = Color3.fromRGB(160, 60, 255),
}

-- ================================================
-- SISTEMA DE GUARDADO
-- ================================================
local function SaveConfig()
    if not writefile then return end
    
    local data = {
        Flags = Flags,
        Config = {
            UITransp = Config.UITransp,
            BlurStrength = Config.BlurStrength,
            AnimSpeed = Config.AnimSpeed,
            FarmDist = Config.FarmDist,
            SpeedVal = Config.SpeedVal,
            CollectRad = Config.CollectRad,
        },
        AccentColor = {
            R = currentAccentColor.R,
            G = currentAccentColor.G,
            B = currentAccentColor.B,
        },
        Teleports = SavedTeleports,
    }
    
    pcall(function()
        writefile(Config.SaveFileName, HttpService:JSONEncode(data))
    end)
end

local function LoadConfig()
    if not readfile or not isfile then return end
    
    pcall(function()
        if isfile(Config.SaveFileName) then
            local data = HttpService:JSONDecode(readfile(Config.SaveFileName))
            
            -- Cargar flags
            for k, v in pairs(data.Flags or {}) do
                Flags[k] = v
            end
            
            -- Cargar config
            for k, v in pairs(data.Config or {}) do
                Config[k] = v
            end
            
            -- Cargar color
            if data.AccentColor then
                currentAccentColor = Color3.fromRGB(
                    math.floor(data.AccentColor.R * 255),
                    math.floor(data.AccentColor.G * 255),
                    math.floor(data.AccentColor.B * 255)
                )
            end
            
            -- Cargar teleports
            SavedTeleports = data.Teleports or {}
        end
    end)
end

-- Auto-guardar cada 30 segundos
task.spawn(function()
    while task.wait(30) do
        SaveConfig()
    end
end)

-- ================================================
-- SISTEMA DE NOTIFICACIONES TOAST
-- ================================================
local ToastContainer

local function ShowNotification(title, message, duration, icon, color)
    if not Flags.Notifications then return end
    if not ToastContainer then return end
    
    duration = duration or 3
    color = color or currentAccentColor
    
    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(0, 0, 0, 0)
    toast.Position = UDim2.new(0, 10, 0, #ToastContainer:GetChildren() * 78)
    toast.BackgroundColor3 = C.dark
    toast.BackgroundTransparency = 0.08
    toast.BorderSizePixel = 0
    toast.ZIndex = 1000
    toast.Parent = ToastContainer
    
    local toastCorner = Instance.new("UICorner")
    toastCorner.CornerRadius = UDim.new(0, 12)
    toastCorner.Parent = toast
    
    local toastStroke = Instance.new("UIStroke")
    toastStroke.Color = color
    toastStroke.Thickness = 1.5
    toastStroke.Transparency = 0.3
    toastStroke.Parent = toast
    
    -- Icono
    local iconLabel = Instance.new("ImageLabel")
    iconLabel.Size = UDim2.new(0, 24, 0, 24)
    iconLabel.Position = UDim2.new(0, 14, 0, 14)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Image = icon or Icons.check
    iconLabel.ImageColor3 = color
    iconLabel.ZIndex = 1001
    iconLabel.Parent = toast
    
    -- Título
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -52, 0, 20)
    titleLabel.Position = UDim2.new(0, 46, 0, 11)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = C.white
    titleLabel.TextSize = 13
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 1001
    titleLabel.Parent = toast
    
    -- Mensaje
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -52, 0, 16)
    msgLabel.Position = UDim2.new(0, 46, 0, 32)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = message
    msgLabel.TextColor3 = C.dim
    msgLabel.TextSize = 11
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.ZIndex = 1001
    msgLabel.Parent = toast
    
    -- Barra de progreso
    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(1, -6, 0, 2)
    progressBg.Position = UDim2.new(0, 3, 1, -5)
    progressBg.BackgroundColor3 = Color3.fromRGB(20, 26, 46)
    progressBg.BorderSizePixel = 0
    progressBg.ZIndex = 1001
    progressBg.Parent = toast
    
    local progressFill = Instance.new("Frame")
    progressFill.Size = UDim2.new(1, 0, 1, 0)
    progressFill.BackgroundColor3 = color
    progressFill.BorderSizePixel = 0
    progressFill.ZIndex = 1002
    progressFill.Parent = progressBg
    
    -- Animación de entrada
    TweenService:Create(toast, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 320, 0, 68)
    }):Play()
    
    PlaySound(Sounds.Notify)
    
    -- Animación de progreso
    TweenService:Create(progressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 1, 0)
    }):Play()
    
    -- Remover después del tiempo
    task.delay(duration, function()
        TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }):Play()
        
        TweenService:Create(toastStroke, TweenInfo.new(0.3), {
            Transparency = 1
        }):Play()
        
        task.wait(0.35)
        toast:Destroy()
        
        -- Reposicionar otras notificaciones
        for i, child in ipairs(ToastContainer:GetChildren()) do
            if child:IsA("Frame") then
                TweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, 10, 0, (i - 1) * 78)
                }):Play()
            end
        end
    end)
end

-- ================================================
-- HELPERS
-- ================================================
local function GetChar() return LocalPlayer.Character end
local function GetRoot() local c = GetChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum() local c = GetChar() return c and c:FindFirstChildOfClass("Humanoid") end

-- Agregar a historial
local function AddToHistory(action, details)
    table.insert(ActionHistory, 1, {
        action = action,
        details = details,
        timestamp = os.time()
    })
    
    -- Mantener solo los últimos 50
    if #ActionHistory > 50 then
        table.remove(ActionHistory, #ActionHistory)
    end
end

LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait(1)
    if Flags.SpeedHack then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = Config.SpeedVal end
    end
end)

-- ================================================
-- FUNCIONES DEL JUEGO
-- ================================================

local function StartFarm()
    if farmConn then farmConn:Disconnect() end
    farmConn = RunService.Heartbeat:Connect(function()
        if not Flags.AutoFarm then farmConn:Disconnect() return end
        local root, hum = GetRoot(), GetHum()
        if not root or not hum or hum.Health <= 0 then return end
        
        local nearest, nearDist = nil, Config.FarmDist
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= GetChar() then
                local h2 = obj:FindFirstChildOfClass("Humanoid")
                local r2 = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
                if h2 and h2.Health > 0 and r2 then
                    local d = (root.Position - r2.Position).Magnitude
                    if d < nearDist then
                        nearest = obj
                        nearDist = d
                    end
                end
            end
        end
        
        if nearest then
            local r2 = nearest:FindFirstChild("HumanoidRootPart") or nearest:FindFirstChild("Torso")
            if r2 then
                root.CFrame = CFrame.new(r2.Position + Vector3.new(0, 2, 3))
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
                        pcall(function() root.CFrame = CFrame.new(obj.Position + Vector3.new(0, 2, 0)) end)
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
    if on then
        Config.OrigSpeed = h.WalkSpeed
        h.WalkSpeed = Config.SpeedVal
    else
        h.WalkSpeed = Config.OrigSpeed
    end
end

local function StartAntiAFK()
    if afkConn then afkConn:Disconnect() end
    local vu = game:GetService("VirtualUser")
    afkConn = LocalPlayer.Idled:Connect(function()
        if not Flags.AntiAFK then afkConn:Disconnect() return end
        vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(0.5)
        vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end

local function CleanESP()
    for _, v in pairs(ESPList) do pcall(function() v:Destroy() end) end
    ESPList = {}
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
                hl.FillColor = currentAccentColor
                hl.OutlineColor = Color3.new(1, 1, 1)
                hl.FillTransparency = Config.ESPFillTransp
                hl.OutlineTransparency = 0
                hl.Parent = char
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
                    hl.Name = "NPCESP"
                    hl.FillColor = Color3.fromRGB(255, 60, 60)
                    hl.OutlineColor = Color3.fromRGB(255, 180, 180)
                    hl.FillTransparency = Config.ESPFillTransp
                    hl.OutlineTransparency = 0
                    hl.Parent = obj
                    table.insert(ESPList, hl)
                end)
            end
        end
    end
end

-- ================================================
-- SISTEMA DE TELEPORT
-- ================================================
local function SaveTeleport(name)
    local root = GetRoot()
    if not root then
        ShowNotification("Error", "No se pudo obtener tu posición", 3, Icons.x, C.red)
        return
    end
    
    SavedTeleports[name] = {
        Position = {root.Position.X, root.Position.Y, root.Position.Z},
        Timestamp = os.time()
    }
    
    SaveConfig()
    ShowNotification("Guardado", "Posición '" .. name .. "' guardada", 2, Icons.check, C.green)
    AddToHistory("Save Teleport", name)
end

local function TeleportTo(name)
    local tp = SavedTeleports[name]
    if not tp then
        ShowNotification("Error", "Posición no encontrada", 3, Icons.x, C.red)
        return
    end
    
    local root = GetRoot()
    if not root then
        ShowNotification("Error", "No se pudo teleportar", 3, Icons.x, C.red)
        return
    end
    
    local pos = Vector3.new(tp.Position[1], tp.Position[2], tp.Position[3])
    root.CFrame = CFrame.new(pos)
    
    ShowNotification("Teleport", "Teleportado a '" .. name .. "'", 2, Icons.navigation, C.blue)
    AddToHistory("Teleport", name)
end

-- ================================================
-- UI - SCREENGUI
-- ================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ChloeXHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
pcall(function() syn.protect_gui(ScreenGui) end)
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if ScreenGui.Parent == nil then ScreenGui.Parent = LocalPlayer.PlayerGui end

-- Container de notificaciones
ToastContainer = Instance.new("Frame")
ToastContainer.Name = "ToastContainer"
ToastContainer.Size = UDim2.new(0, 340, 1, -20)
ToastContainer.Position = UDim2.new(1, -350, 0, 10)
ToastContainer.BackgroundTransparency = 1
ToastContainer.ZIndex = 999
ToastContainer.Parent = ScreenGui

local Blur = Instance.new("BlurEffect")
Blur.Size = 0
Blur.Parent = game:GetService("Lighting")

-- ================================================
-- FRAME PRINCIPAL
-- ================================================
local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.Size = UDim2.new(0, 740, 0, 490)
Main.Position = UDim2.new(0, 0, 0, 0)
Main.BackgroundColor3 = C.dark
Main.BackgroundTransparency = 0.06
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Active = true
Main.Visible = false
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = currentAccentColor
MainStroke.Thickness = 1.8
MainStroke.Transparency = 0.3
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = Main

-- ================================================
-- PARTÍCULAS DE FONDO
-- ================================================
local ParticlesContainer = Instance.new("Frame")
ParticlesContainer.Size = UDim2.new(1, 0, 1, 0)
ParticlesContainer.BackgroundTransparency = 1
ParticlesContainer.ZIndex = 1
ParticlesContainer.ClipsDescendants = true
ParticlesContainer.Parent = Main

-- Crear partículas flotantes
task.spawn(function()
    for i = 1, 20 do
        local particle = Instance.new("Frame")
        particle.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4))
        particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
        particle.BackgroundColor3 = currentAccentColor
        particle.BackgroundTransparency = 0.7
        particle.BorderSizePixel = 0
        particle.ZIndex = 2
        particle.Parent = ParticlesContainer
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = particle
        
        -- Animación flotante
        task.spawn(function()
            while Main.Parent and Flags.Particles do
                local duration = math.random(8, 15)
                local targetY = math.random(-10, 110) / 100
                
                TweenService:Create(particle, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Position = UDim2.new(math.random(), 0, targetY, 0),
                    BackgroundTransparency = math.random(60, 95) / 100
                }):Play()
                
                task.wait(duration)
            end
        end)
    end
end)

-- Imagen de fondo
local BgImage = Instance.new("ImageLabel")
BgImage.Size = UDim2.new(0, 450, 1, 0)
BgImage.Position = UDim2.new(1, -450, 0, 0)
BgImage.BackgroundTransparency = 1
BgImage.Image = "rbxassetid://6368108640"
BgImage.ImageTransparency = 0.15
BgImage.ScaleType = Enum.ScaleType.Crop
BgImage.ZIndex = 1
BgImage.Parent = Main

local BgGrad = Instance.new("UIGradient")
BgGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.25, 1),
    NumberSequenceKeypoint.new(0.75, 0),
    NumberSequenceKeypoint.new(1, 0),
})
BgGrad.Rotation = 90
BgGrad.Parent = BgImage

local BgOvl = Instance.new("Frame")
BgOvl.Size = UDim2.new(1, 0, 1, 0)
BgOvl.BackgroundColor3 = C.dark
BgOvl.BackgroundTransparency = 0.45
BgOvl.BorderSizePixel = 0
BgOvl.ZIndex = 2
BgOvl.Parent = Main

-- ================================================
-- BARRA DE TÍTULO
-- ================================================
local TBar = Instance.new("Frame")
TBar.Name = "TitleBar"
TBar.Size = UDim2.new(1, 0, 0, 52)
TBar.BackgroundColor3 = Color3.fromRGB(7, 9, 18)
TBar.BackgroundTransparency = 0.1
TBar.BorderSizePixel = 0
TBar.ZIndex = 20
TBar.Parent = Main

local TBarCorner = Instance.new("UICorner")
TBarCorner.CornerRadius = UDim.new(0, 16)
TBarCorner.Parent = TBar

local TBarPatch = Instance.new("Frame")
TBarPatch.Size = UDim2.new(1, 0, 0.5, 0)
TBarPatch.Position = UDim2.new(0, 0, 0.5, 0)
TBarPatch.BackgroundColor3 = Color3.fromRGB(7, 9, 18)
TBarPatch.BackgroundTransparency = 0.1
TBarPatch.BorderSizePixel = 0
TBarPatch.ZIndex = 20
TBarPatch.Parent = TBar

local TBarLine = Instance.new("Frame")
TBarLine.Size = UDim2.new(1, 0, 0, 2)
TBarLine.Position = UDim2.new(0, 0, 1, -2)
TBarLine.BackgroundColor3 = currentAccentColor
TBarLine.BackgroundTransparency = 0.3
TBarLine.BorderSizePixel = 0
TBarLine.ZIndex = 21
TBarLine.Parent = TBar

-- Logo con glassmorphism
local LogoContainer = Instance.new("Frame")
LogoContainer.Size = UDim2.new(0, 40, 0, 40)
LogoContainer.Position = UDim2.new(0, 10, 0.5, -20)
LogoContainer.BackgroundColor3 = Color3.fromRGB(18, 24, 40)
LogoContainer.BackgroundTransparency = 0.15
LogoContainer.BorderSizePixel = 0
LogoContainer.ZIndex = 22
LogoContainer.Parent = TBar

local logoC = Instance.new("UICorner")
logoC.CornerRadius = UDim.new(0, 10)
logoC.Parent = LogoContainer

local logoS = Instance.new("UIStroke")
logoS.Color = currentAccentColor
logoS.Thickness = 1.5
logoS.Transparency = 0.4
logoS.Parent = LogoContainer

local LogoIcon = Instance.new("ImageLabel")
LogoIcon.Size = UDim2.new(0, 28, 0, 28)
LogoIcon.Position = UDim2.new(0.5, -14, 0.5, -14)
LogoIcon.BackgroundTransparency = 1
LogoIcon.Image = "rbxassetid://6050821448"
LogoIcon.ScaleType = Enum.ScaleType.Fit
LogoIcon.ImageTransparency = 0
LogoIcon.ZIndex = 23
LogoIcon.Parent = LogoContainer

-- Animación de pulso del logo
task.spawn(function()
    while Main.Parent do
        TweenService:Create(LogoIcon, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            ImageTransparency = 0.2
        }):Play()
        TweenService:Create(logoS, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Transparency = 0.1
        }):Play()
        task.wait(1.8)
        TweenService:Create(LogoIcon, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            ImageTransparency = 0
        }):Play()
        TweenService:Create(logoS, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Transparency = 0.4
        }):Play()
        task.wait(1.8)
    end
end)

-- Título
local HubName = Instance.new("TextLabel")
HubName.Size = UDim2.new(0, 200, 0, 24)
HubName.Position = UDim2.new(0, 58, 0.5, -22)
HubName.BackgroundTransparency = 1
HubName.Text = "CHLOE X Hub"
HubName.TextColor3 = C.white
HubName.TextSize = 16
HubName.Font = Enum.Font.GothamBold
HubName.TextXAlignment = Enum.TextXAlignment.Left
HubName.ZIndex = 22
HubName.Parent = TBar

-- Subtítulo con gradiente
local HubSub = Instance.new("TextLabel")
HubSub.Size = UDim2.new(0, 220, 0, 16)
HubSub.Position = UDim2.new(0, 58, 0.5, 4)
HubSub.BackgroundTransparency = 1
HubSub.Text = "v5.0  •  Ultra Edition  •  🎨"
HubSub.TextColor3 = currentAccentColor
HubSub.TextSize = 11
HubSub.Font = Enum.Font.Gotham
HubSub.TextXAlignment = Enum.TextXAlignment.Left
HubSub.ZIndex = 22
HubSub.Parent = TBar

-- Botones de control
local function MakeCtrl(sym, icon, xOff, col, tooltip)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 34, 0, 34)
    btn.Position = UDim2.new(1, xOff, 0.5, -17)
    btn.BackgroundColor3 = Color3.fromRGB(18, 22, 36)
    btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.ZIndex = 22
    btn.Parent = TBar
    
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 8)
    bc.Parent = btn
    
    -- Icono o texto
    if icon then
        local ico = Instance.new("ImageLabel")
        ico.Size = UDim2.new(0, 18, 0, 18)
        ico.Position = UDim2.new(0.5, -9, 0.5, -9)
        ico.BackgroundTransparency = 1
        ico.Image = icon
        ico.ImageColor3 = col
        ico.ZIndex = 23
        ico.Parent = btn
    else
        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Text = sym
        txt.TextColor3 = col
        txt.TextSize = 16
        txt.Font = Enum.Font.GothamBold
        txt.ZIndex = 23
        txt.Parent = btn
    end
    
    -- Tooltip
    local tip = Instance.new("TextLabel")
    tip.Size = UDim2.new(0, 0, 0, 26)
    tip.Position = UDim2.new(0.5, 0, -1, -6)
    tip.AnchorPoint = Vector2.new(0.5, 1)
    tip.BackgroundColor3 = C.dark
    tip.BackgroundTransparency = 1
    tip.Text = tooltip or ""
    tip.TextColor3 = C.white
    tip.TextSize = 11
    tip.Font = Enum.Font.Gotham
    tip.TextTransparency = 1
    tip.ZIndex = 100
    tip.Visible = false
    tip.Parent = btn
    
    local tipC = Instance.new("UICorner")
    tipC.CornerRadius = UDim.new(0, 6)
    tipC.Parent = tip
    
    local tipS = Instance.new("UIStroke")
    tipS.Color = currentAccentColor
    tipS.Thickness = 1
    tipS.Transparency = 1
    tipS.Parent = tip
    
    btn.MouseEnter:Connect(function()
        PlaySound(Sounds.Hover)
        TweenService:Create(btn, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            BackgroundColor3 = col,
            BackgroundTransparency = 0,
            Size = UDim2.new(0, 36, 0, 36)
        }):Play()
        
        -- Mostrar tooltip
        if tooltip then
            tip.Visible = true
            TweenService:Create(tip, TweenInfo.new(0.18), {
                Size = UDim2.new(0, #tooltip * 7 + 16, 0, 26),
                BackgroundTransparency = 0.05,
                TextTransparency = 0
            }):Play()
            TweenService:Create(tipS, TweenInfo.new(0.18), {Transparency = 0.3}):Play()
        end
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.16), {
            BackgroundColor3 = Color3.fromRGB(18, 22, 36),
            BackgroundTransparency = 0.2,
            Size = UDim2.new(0, 34, 0, 34)
        }):Play()
        
        -- Ocultar tooltip
        if tooltip then
            TweenService:Create(tip, TweenInfo.new(0.14), {
                Size = UDim2.new(0, 0, 0, 26),
                BackgroundTransparency = 1,
                TextTransparency = 1
            }):Play()
            TweenService:Create(tipS, TweenInfo.new(0.14), {Transparency = 1}):Play()
            task.wait(0.16)
            tip.Visible = false
        end
    end)
    
    return btn
end

local CloseBtn = MakeCtrl("×", nil, -42, C.red, "Cerrar")
local MinBtn = MakeCtrl("—", nil, -84, currentAccentColor, "Minimizar")
local SettingsBtn = MakeCtrl(nil, Icons.settings, -126, C.dim, "Configuración")

-- ================================================
-- SIDEBAR
-- ================================================
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 160, 1, -52)
Sidebar.Position = UDim2.new(0, 0, 0, 52)
Sidebar.BackgroundColor3 = Color3.fromRGB(6, 8, 16)
Sidebar.BackgroundTransparency = 0.12
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 18
Sidebar.Parent = Main

local SideDiv = Instance.new("Frame")
SideDiv.Size = UDim2.new(0, 1.5, 1, 0)
SideDiv.Position = UDim2.new(1, 0, 0, 0)
SideDiv.BackgroundColor3 = currentAccentColor
SideDiv.BackgroundTransparency = 0.55
SideDiv.BorderSizePixel = 0
SideDiv.ZIndex = 19
SideDiv.Parent = Sidebar

-- ================================================
-- CONTENIDO
-- ================================================
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -160, 1, -82)
Content.Position = UDim2.new(0, 160, 0, 52)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ClipsDescendants = true
Content.ZIndex = 10
Content.Parent = Main

-- ================================================
-- BARRA DE ESTADO
-- ================================================
local StatusBar = Instance.new("Frame")
StatusBar.Name = "StatusBar"
StatusBar.Size = UDim2.new(1, -160, 0, 30)
StatusBar.Position = UDim2.new(0, 160, 1, -30)
StatusBar.BackgroundColor3 = Color3.fromRGB(6, 8, 16)
StatusBar.BackgroundTransparency = 0.18
StatusBar.BorderSizePixel = 0
StatusBar.ZIndex = 18
StatusBar.Parent = Main

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 8, 0, 8)
StatusDot.Position = UDim2.new(0, 12, 0.5, -4)
StatusDot.BackgroundColor3 = C.green
StatusDot.BorderSizePixel = 0
StatusDot.ZIndex = 19
StatusDot.Parent = StatusBar

local sdC = Instance.new("UICorner")
sdC.CornerRadius = UDim.new(1, 0)
sdC.Parent = StatusDot

-- Animación del dot
task.spawn(function()
    while StatusBar.Parent do
        TweenService:Create(StatusDot, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            BackgroundTransparency = 0.1
        }):Play()
        task.wait(0.9)
        TweenService:Create(StatusDot, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            BackgroundTransparency = 0.7
        }):Play()
        task.wait(0.9)
    end
end)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -32, 1, 0)
StatusLabel.Position = UDim2.new(0, 28, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "● Listo"
StatusLabel.TextColor3 = C.green
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.ZIndex = 19
StatusLabel.Parent = StatusBar

local function SetStatus(text, color)
    local col = color or currentAccentColor
    TweenService:Create(StatusDot, TweenInfo.new(0.2), {BackgroundColor3 = col}):Play()
    TweenService:Create(StatusLabel, TweenInfo.new(0.12), {
        TextTransparency = 1,
        Position = UDim2.new(0, 22, 0, 0)
    }):Play()
    
    task.wait(0.14)
    StatusLabel.Text = text
    StatusLabel.TextColor3 = col
    
    TweenService:Create(StatusLabel, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        TextTransparency = 0,
        Position = UDim2.new(0, 28, 0, 0)
    }):Play()
end

-- ================================================
-- SPLASH SCREEN MEJORADO
-- ================================================
local LoadScreen = Instance.new("Frame")
LoadScreen.Size = UDim2.new(1, 0, 1, 0)
LoadScreen.BackgroundColor3 = Color3.fromRGB(4, 5, 12)
LoadScreen.BackgroundTransparency = 0
LoadScreen.BorderSizePixel = 0
LoadScreen.ZIndex = 500
LoadScreen.Parent = ScreenGui

local LBg = Instance.new("ImageLabel")
LBg.Size = UDim2.new(1, 0, 1, 0)
LBg.BackgroundTransparency = 1
LBg.Image = "rbxassetid://6368108640"
LBg.ImageTransparency = 0.48
LBg.ScaleType = Enum.ScaleType.Crop
LBg.ZIndex = 501
LBg.Parent = LoadScreen

local LOvl = Instance.new("Frame")
LOvl.Size = UDim2.new(1, 0, 1, 0)
LOvl.BackgroundColor3 = Color3.fromRGB(4, 5, 12)
LOvl.BackgroundTransparency = 0.32
LOvl.BorderSizePixel = 0
LOvl.ZIndex = 502
LOvl.Parent = LoadScreen

-- Círculos animados
local LR1 = Instance.new("ImageLabel")
LR1.Size = UDim2.new(0, 130, 0, 130)
LR1.Position = UDim2.new(0.5, -65, 0.5, -130)
LR1.BackgroundTransparency = 1
LR1.Image = "rbxassetid://4965945816"
LR1.ImageColor3 = currentAccentColor
LR1.ZIndex = 503
LR1.Parent = LoadScreen

local LR2 = Instance.new("ImageLabel")
LR2.Size = UDim2.new(0, 90, 0, 90)
LR2.Position = UDim2.new(0.5, -45, 0.5, -110)
LR2.BackgroundTransparency = 1
LR2.Image = "rbxassetid://4965945816"
LR2.ImageColor3 = C.white
LR2.ImageTransparency = 0.65
LR2.ZIndex = 504
LR2.Parent = LoadScreen

-- Logo central con glassmorphism
local LLogoContainer = Instance.new("Frame")
LLogoContainer.Size = UDim2.new(0, 68, 0, 68)
LLogoContainer.Position = UDim2.new(0.5, -34, 0.5, -100)
LLogoContainer.BackgroundColor3 = Color3.fromRGB(14, 18, 32)
LLogoContainer.BackgroundTransparency = 0.08
LLogoContainer.BorderSizePixel = 0
LLogoContainer.ZIndex = 505
LLogoContainer.Parent = LoadScreen

local llC = Instance.new("UICorner")
llC.CornerRadius = UDim.new(0, 14)
llC.Parent = LLogoContainer

local llS = Instance.new("UIStroke")
llS.Color = currentAccentColor
llS.Thickness = 2
llS.Transparency = 0.3
llS.Parent = LLogoContainer

local LLogo = Instance.new("ImageLabel")
LLogo.Size = UDim2.new(0, 48, 0, 48)
LLogo.Position = UDim2.new(0.5, -24, 0.5, -24)
LLogo.BackgroundTransparency = 1
LLogo.Image = "rbxassetid://6050821448"
LLogo.ScaleType = Enum.ScaleType.Fit
LLogo.ZIndex = 506
LLogo.Parent = LLogoContainer

-- Título
local LTitle = Instance.new("TextLabel")
LTitle.Size = UDim2.new(0, 340, 0, 48)
LTitle.Position = UDim2.new(0.5, -170, 0.5, 8)
LTitle.BackgroundTransparency = 1
LTitle.Text = "CHLOE X Hub"
LTitle.TextColor3 = C.white
LTitle.TextSize = 32
LTitle.Font = Enum.Font.GothamBold
LTitle.TextXAlignment = Enum.TextXAlignment.Center
LTitle.TextTransparency = 1
LTitle.ZIndex = 505
LTitle.Parent = LoadScreen

-- Subtítulo
local LSub = Instance.new("TextLabel")
LSub.Size = UDim2.new(0, 340, 0, 22)
LSub.Position = UDim2.new(0.5, -170, 0.5, 60)
LSub.BackgroundTransparency = 1
LSub.Text = "v5.0  •  Ultra Edition"
LSub.TextColor3 = currentAccentColor
LSub.TextSize = 14
LSub.Font = Enum.Font.Gotham
LSub.TextXAlignment = Enum.TextXAlignment.Center
LSub.TextTransparency = 1
LSub.ZIndex = 505
LSub.Parent = LoadScreen

-- Línea decorativa
local LLine = Instance.new("Frame")
LLine.Size = UDim2.new(0, 0, 0, 2)
LLine.Position = UDim2.new(0.5, 0, 0.5, 92)
LLine.AnchorPoint = Vector2.new(0.5, 0)
LLine.BackgroundColor3 = currentAccentColor
LLine.BackgroundTransparency = 0.25
LLine.BorderSizePixel = 0
LLine.ZIndex = 505
LLine.Parent = LoadScreen

-- Barra de progreso
local LBarBg = Instance.new("Frame")
LBarBg.Size = UDim2.new(0, 310, 0, 6)
LBarBg.Position = UDim2.new(0.5, -155, 0.5, 110)
LBarBg.BackgroundColor3 = Color3.fromRGB(20, 26, 46)
LBarBg.BorderSizePixel = 0
LBarBg.ZIndex = 505
LBarBg.Parent = LoadScreen

local lbC = Instance.new("UICorner")
lbC.CornerRadius = UDim.new(1, 0)
lbC.Parent = LBarBg

local LBar = Instance.new("Frame")
LBar.Size = UDim2.new(0, 0, 1, 0)
LBar.BackgroundColor3 = currentAccentColor
LBar.BorderSizePixel = 0
LBar.ZIndex = 506
LBar.Parent = LBarBg

local lfC = Instance.new("UICorner")
lfC.CornerRadius = UDim.new(1, 0)
lfC.Parent = LBar

-- Brillo en la barra
local LShine = Instance.new("Frame")
LShine.Size = UDim2.new(0, 18, 1, 6)
LShine.Position = UDim2.new(1, -16, 0, -3)
LShine.BackgroundColor3 = C.white
LShine.BackgroundTransparency = 0.18
LShine.BorderSizePixel = 0
LShine.ZIndex = 507
LShine.Parent = LBar

local lsC = Instance.new("UICorner")
lsC.CornerRadius = UDim.new(1, 0)
lsC.Parent = LShine

-- Status de carga
local LStatus = Instance.new("TextLabel")
LStatus.Size = UDim2.new(0, 310, 0, 20)
LStatus.Position = UDim2.new(0.5, -155, 0.5, 124)
LStatus.BackgroundTransparency = 1
LStatus.Text = "Iniciando..."
LStatus.TextColor3 = C.dim
LStatus.TextSize = 11
LStatus.Font = Enum.Font.Gotham
LStatus.TextXAlignment = Enum.TextXAlignment.Center
LStatus.ZIndex = 505
LStatus.Parent = LoadScreen

-- Animación de carga
task.spawn(function()
    -- Fade in del título
    TweenService:Create(LTitle, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    }):Play()
    
    task.wait(0.2)
    
    TweenService:Create(LSub, TweenInfo.new(0.5), {
        TextTransparency = 0
    }):Play()
    
    TweenService:Create(LLine, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 230, 0, 2)
    }):Play()
    
    -- Rotación de círculos
    task.spawn(function()
        while LoadScreen.Parent do
            LR1.Rotation = LR1.Rotation + 4
            LR2.Rotation = LR2.Rotation - 3
            task.wait(0.03)
        end
    end)
    
    -- Pulso del logo
    task.spawn(function()
        while LoadScreen.Parent do
            TweenService:Create(LLogo, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                ImageTransparency = 0.25
            }):Play()
            TweenService:Create(llS, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Transparency = 0.05
            }):Play()
            task.wait(0.9)
            TweenService:Create(LLogo, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                ImageTransparency = 0
            }):Play()
            TweenService:Create(llS, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Transparency = 0.3
            }):Play()
            task.wait(0.9)
        end
    end)
    
    task.wait(0.4)
    
    -- Cargar configuración
    LoadConfig()
    
    -- Pasos de carga
    local steps = {
        {p = 0.20, t = "Cargando módulos...", w = 0.45},
        {p = 0.42, t = "Iniciando UI...", w = 0.38},
        {p = 0.65, t = "Conectando servicios...", w = 0.36},
        {p = 0.85, t = "Preparando funciones...", w = 0.32},
        {p = 1.00, t = "¡Todo listo!", w = 0.30},
    }
    
    for _, s in ipairs(steps) do
        TweenService:Create(LBar, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(s.p, 0, 1, 0)
        }):Play()
        
        TweenService:Create(LStatus, TweenInfo.new(0.1), {
            TextTransparency = 1
        }):Play()
        
        task.wait(0.12)
        LStatus.Text = s.t
        
        TweenService:Create(LStatus, TweenInfo.new(0.2), {
            TextTransparency = 0
        }):Play()
        
        task.wait(s.w)
    end
    
    task.wait(0.25)
    
    -- Flash de transición
    local flash = Instance.new("Frame")
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = currentAccentColor
    flash.BackgroundTransparency = 1
    flash.BorderSizePixel = 0
    flash.ZIndex = 800
    flash.Parent = ScreenGui
    
    TweenService:Create(flash, TweenInfo.new(0.12), {
        BackgroundTransparency = 0.22
    }):Play()
    
    task.wait(0.12)
    
    TweenService:Create(flash, TweenInfo.new(0.5), {
        BackgroundTransparency = 1
    }):Play()
    
    -- Fade out de la pantalla de carga
    TweenService:Create(LoadScreen, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        BackgroundTransparency = 1
    }):Play()
    
    for _, el in ipairs({LBg, LOvl, LTitle, LSub, LStatus, LR1, LR2, LLogoContainer, LLine, LBarBg}) do
        pcall(function()
            if el:IsA("TextLabel") then
                TweenService:Create(el, TweenInfo.new(0.28), {TextTransparency = 1}):Play()
            elseif el:IsA("ImageLabel") then
                TweenService:Create(el, TweenInfo.new(0.28), {ImageTransparency = 1}):Play()
            else
                TweenService:Create(el, TweenInfo.new(0.28), {BackgroundTransparency = 1}):Play()
            end
        end)
    end
    
    task.wait(0.48)
    LoadScreen:Destroy()
    flash:Destroy()
    
    -- Mostrar main UI
    local vp = workspace.CurrentCamera.ViewportSize
    Main.Position = UDim2.new(0, math.floor(vp.X / 2 - 370), 0, math.floor(vp.Y / 2 - 245))
    Main.Visible = true
    Main.Size = UDim2.new(0, 0, 0, 0)
    Main.Rotation = -15
    
    TweenService:Create(Main, TweenInfo.new(0.58, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 740, 0, 490),
        Rotation = 0
    }):Play()
    
    TweenService:Create(Main, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.06
    }):Play()
    
    TweenService:Create(Blur, TweenInfo.new(0.6), {
        Size = Config.BlurStrength
    }):Play()
    
    PlaySound(Sounds.Success)
    
    task.wait(0.7)
    
    SetStatus("🎉 Chloe X v5.0 cargado!", C.green)
    ShowNotification("Bienvenido", "Hub cargado exitosamente", 3, Icons.check, C.green)
    
    task.wait(3)
    SetStatus("✅ Todos los sistemas listos", currentAccentColor)
    
    task.wait(2)
    SetStatus("💡 Selecciona una pestaña para comenzar", C.dim)
end)

-- ================================================
-- SISTEMA DE TABS
-- ================================================
local currentTab = nil
local tabButtons = {}
local tabPanels = {}

local TAB_CONFIG = {
    {id = "home", label = "Inicio", icon = Icons.home},
    {id = "farming", label = "Farming", icon = Icons.target},
    {id = "player", label = "Jugador", icon = Icons.user},
    {id = "visual", label = "Visual", icon = Icons.eye},
    {id = "teleport", label = "Teleport", icon = Icons.mapPin},
    {id = "misc", label = "Misc", icon = Icons.folder},
    {id = "config", label = "Config", icon = Icons.settings},
}

local function CreateTabButton(id, label, icon, order)
    local btn = Instance.new("TextButton")
    btn.Name = id .. "Btn"
    btn.Size = UDim2.new(1, 0, 0, 58)
    btn.Position = UDim2.new(0, 0, 0, (order - 1) * 58)
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.ZIndex = 20
    btn.Parent = Sidebar
    
    -- Fondo highlight
    local rowBg = Instance.new("Frame")
    rowBg.Size = UDim2.new(1, -8, 1, -6)
    rowBg.Position = UDim2.new(0, 4, 0, 3)
    rowBg.BackgroundColor3 = currentAccentColor
    rowBg.BackgroundTransparency = 1
    rowBg.BorderSizePixel = 0
    rowBg.ZIndex = 19
    rowBg.Parent = btn
    
    local rbC = Instance.new("UICorner")
    rbC.CornerRadius = UDim.new(0, 10)
    rbC.Parent = rowBg
    
    -- Indicador izquierdo
    local ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 3.5, 0, 0)
    ind.Position = UDim2.new(0, 0, 0.5, 0)
    ind.AnchorPoint = Vector2.new(0, 0.5)
    ind.BackgroundColor3 = currentAccentColor
    ind.BorderSizePixel = 0
    ind.ZIndex = 22
    ind.Parent = btn
    
    local indC = Instance.new("UICorner")
    indC.CornerRadius = UDim.new(1, 0)
    indC.Parent = ind
    
    -- Icono
    local iconLabel = Instance.new("ImageLabel")
    iconLabel.Size = UDim2.new(0, 24, 0, 24)
    iconLabel.Position = UDim2.new(0, 18, 0.5, -12)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Image = icon
    iconLabel.ImageColor3 = C.dim
    iconLabel.ScaleType = Enum.ScaleType.Fit
    iconLabel.ZIndex = 21
    iconLabel.Parent = btn
    
    -- Etiqueta
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -52, 1, 0)
    lbl.Position = UDim2.new(0, 52, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C.dim
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 21
    lbl.Parent = btn
    
    tabButtons[id] = {
        btn = btn,
        icon = iconLabel,
        row = rowBg,
        lbl = lbl,
        ind = ind
    }
    
    btn.MouseEnter:Connect(function()
        PlaySound(Sounds.Hover)
        if currentTab ~= id then
            TweenService:Create(rowBg, TweenInfo.new(0.16), {
                BackgroundTransparency = 0.86
            }):Play()
            TweenService:Create(iconLabel, TweenInfo.new(0.16), {
                ImageColor3 = Color3.fromRGB(200, 215, 240),
                Size = UDim2.new(0, 26, 0, 26)
            }):Play()
            TweenService:Create(lbl, TweenInfo.new(0.16), {
                TextColor3 = Color3.fromRGB(200, 215, 240)
            }):Play()
        end
    end)
    
    btn.MouseLeave:Connect(function()
        if currentTab ~= id then
            TweenService:Create(rowBg, TweenInfo.new(0.2), {
                BackgroundTransparency = 1
            }):Play()
            TweenService:Create(iconLabel, TweenInfo.new(0.2), {
                ImageColor3 = C.dim,
                Size = UDim2.new(0, 24, 0, 24)
            }):Play()
            TweenService:Create(lbl, TweenInfo.new(0.2), {
                TextColor3 = C.dim
            }):Play()
        end
    end)
    
    return btn
end

local function SwitchTab(id)
    PlaySound(Sounds.Tab)
    
    -- Animar tab anterior
    if currentTab and tabPanels[currentTab] then
        local old = tabPanels[currentTab]
        TweenService:Create(old, TweenInfo.new(Config.AnimSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(-0.24, 0, 0, 0),
            Size = UDim2.new(0.88, 0, 1, 0)
        }):Play()
        
        task.wait(Config.AnimSpeed * 0.5)
        old.Visible = false
        old.Position = UDim2.new(0, 0, 0, 0)
        old.Size = UDim2.new(1, 0, 1, 0)
    end
    
    -- Actualizar botones
    for tid, tab in pairs(tabButtons) do
        if tid == id then
            TweenService:Create(tab.icon, TweenInfo.new(0.24), {
                ImageColor3 = currentAccentColor,
                Size = UDim2.new(0, 26, 0, 26)
            }):Play()
            TweenService:Create(tab.row, TweenInfo.new(0.24), {
                BackgroundTransparency = 0.78,
                BackgroundColor3 = currentAccentColor
            }):Play()
            TweenService:Create(tab.lbl, TweenInfo.new(0.2), {
                TextColor3 = C.white,
                TextSize = 14
            }):Play()
            TweenService:Create(tab.ind, TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 3.5, 0, 40)
            }):Play()
        else
            TweenService:Create(tab.icon, TweenInfo.new(0.18), {
                ImageColor3 = C.dim,
                Size = UDim2.new(0, 24, 0, 24)
            }):Play()
            TweenService:Create(tab.row, TweenInfo.new(0.18), {
                BackgroundTransparency = 1
            }):Play()
            TweenService:Create(tab.lbl, TweenInfo.new(0.18), {
                TextColor3 = C.dim,
                TextSize = 13
            }):Play()
            TweenService:Create(tab.ind, TweenInfo.new(0.18), {
                Size = UDim2.new(0, 3.5, 0, 0)
            }):Play()
        end
    end
    
    -- Mostrar nuevo panel
    if tabPanels[id] then
        local np = tabPanels[id]
        np.Visible = true
        np.Position = UDim2.new(0.20, 0, 0, 0)
        np.Size = UDim2.new(0.88, 0, 1, 0)
        
        TweenService:Create(np, TweenInfo.new(Config.AnimSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0)
        }):Play()
    end
    
    currentTab = id
    SetStatus("Tab: " .. (id:gsub("^%l", string.upper)), currentAccentColor)
    AddToHistory("Cambio de Tab", id)
end

local function CreatePanel(id)
    local p = Instance.new("ScrollingFrame")
    p.Name = id .. "Panel"
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 5
    p.ScrollBarImageColor3 = currentAccentColor
    p.CanvasSize = UDim2.new(0, 0, 0, 0)
    p.Visible = false
    p.ZIndex = 12
    p.Parent = Content
    
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 10)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = p
    
    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        p.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 24)
    end)
    
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 16)
    pad.PaddingLeft = UDim.new(0, 16)
    pad.PaddingRight = UDim.new(0, 16)
    pad.PaddingBottom = UDim.new(0, 16)
    pad.Parent = p
    
    tabPanels[id] = p
    return p
end

-- ================================================
-- COMPONENTES UI MEJORADOS
-- ================================================

-- Crear ripple effect
local function CreateRipple(parent, x, y)
    local ripple = Instance.new("Frame")
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Position = UDim2.new(0, x, 0, y)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.BackgroundColor3 = currentAccentColor
    ripple.BackgroundTransparency = 0.3
    ripple.BorderSizePixel = 0
    ripple.ZIndex = 100
    ripple.Parent = parent
    
    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(1, 0)
    rc.Parent = ripple
    
    local size = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y)
    
    TweenService:Create(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, size * 2, 0, size * 2),
        BackgroundTransparency = 1
    }):Play()
    
    task.wait(0.5)
    ripple:Destroy()
end

-- Sección con icono
local function CreateSection(parent, title, icon)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 32)
    f.BackgroundTransparency = 1
    f.ZIndex = 13
    f.Parent = parent
    
    -- Icono de sección
    if icon then
        local ico = Instance.new("ImageLabel")
        ico.Size = UDim2.new(0, 18, 0, 18)
        ico.Position = UDim2.new(0, 6, 0, 7)
        ico.BackgroundTransparency = 1
        ico.Image = icon
        ico.ImageColor3 = currentAccentColor
        ico.ZIndex = 14
        ico.Parent = f
    end
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, icon and -32 or -10, 1, 0)
    l.Position = UDim2.new(0, icon and 30 or 6, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = title
    l.TextColor3 = currentAccentColor
    l.TextSize = 13
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 14
    l.Parent = f
    
    local ln = Instance.new("Frame")
    ln.Size = UDim2.new(1, 0, 0, 1.5)
    ln.Position = UDim2.new(0, 0, 1, -6)
    ln.BackgroundColor3 = currentAccentColor
    ln.BackgroundTransparency = 0.6
    ln.BorderSizePixel = 0
    ln.ZIndex = 14
    ln.Parent = f
    
    return f
end

-- Toggle mejorado con ripple
local function CreateToggle(parent, title, desc, icon, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 54)
    row.BackgroundColor3 = C.panel
    row.BackgroundTransparency = 0.28
    row.BorderSizePixel = 0
    row.ClipsDescendants = true
    row.ZIndex = 13
    row.Parent = parent
    
    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 12)
    rc.Parent = row
    
    -- Icono
    if icon then
        local ico = Instance.new("ImageLabel")
        ico.Size = UDim2.new(0, 20, 0, 20)
        ico.Position = UDim2.new(0, 16, 0, 9)
        ico.BackgroundTransparency = 1
        ico.Image = icon
        ico.ImageColor3 = C.white
        ico.ZIndex = 14
        ico.Parent = row
    end
    
    -- Título
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, icon and -100 or -78, 0, 24)
    tl.Position = UDim2.new(0, icon and 44 or 16, 0, 8)
    tl.BackgroundTransparency = 1
    tl.Text = title
    tl.TextColor3 = C.white
    tl.TextSize = 13
    tl.Font = Enum.Font.GothamBold
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.ZIndex = 14
    tl.Parent = row
    
    -- Descripción
    local dl = Instance.new("TextLabel")
    dl.Size = UDim2.new(1, icon and -100 or -78, 0, 15)
    dl.Position = UDim2.new(0, icon and 44 or 16, 0, 31)
    dl.BackgroundTransparency = 1
    dl.Text = desc
    dl.TextColor3 = C.dim
    dl.TextSize = 10
    dl.Font = Enum.Font.Gotham
    dl.TextXAlignment = Enum.TextXAlignment.Left
    dl.ZIndex = 14
    dl.Parent = row
    
    -- Switch
    local sw = Instance.new("TextButton")
    sw.Size = UDim2.new(0, 52, 0, 28)
    sw.Position = UDim2.new(1, -64, 0.5, -14)
    sw.BackgroundColor3 = Color3.fromRGB(36, 42, 62)
    sw.BorderSizePixel = 0
    sw.Text = ""
    sw.ZIndex = 15
    sw.Parent = row
    
    local swC = Instance.new("UICorner")
    swC.CornerRadius = UDim.new(1, 0)
    swC.Parent = sw
    
    -- Knob
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 22, 0, 22)
    knob.Position = UDim2.new(0, 3, 0.5, -11)
    knob.BackgroundColor3 = C.white
    knob.BorderSizePixel = 0
    knob.ZIndex = 16
    knob.Parent = sw
    
    local kC = Instance.new("UICorner")
    kC.CornerRadius = UDim.new(1, 0)
    kC.Parent = knob
    
    local state = false
    
    row.MouseEnter:Connect(function()
        if not state then
            TweenService:Create(row, TweenInfo.new(0.16), {
                BackgroundTransparency = 0.16
            }):Play()
        end
    end)
    
    row.MouseLeave:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.28
        }):Play()
    end)
    
    sw.MouseButton1Click:Connect(function()
        PlaySound(Sounds.Click)
        state = not state
        
        -- Ripple effect
        local rippleX = sw.AbsolutePosition.X + sw.AbsoluteSize.X / 2 - row.AbsolutePosition.X
        local rippleY = sw.AbsolutePosition.Y + sw.AbsoluteSize.Y / 2 - row.AbsolutePosition.Y
        CreateRipple(row, rippleX, rippleY)
        
        if state then
            PlaySound(Sounds.ToggleOn)
            TweenService:Create(sw, TweenInfo.new(0.2), {
                BackgroundColor3 = C.green
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -25, 0.5, -11)
            }):Play()
            TweenService:Create(row, TweenInfo.new(0.2), {
                BackgroundTransparency = 0.12
            }):Play()
            
            if icon then
                local ico = row:FindFirstChild("ImageLabel")
                if ico then
                    TweenService:Create(ico, TweenInfo.new(0.2), {
                        ImageColor3 = C.green
                    }):Play()
                end
            end
        else
            PlaySound(Sounds.ToggleOff)
            TweenService:Create(sw, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(36, 42, 62)
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 3, 0.5, -11)
            }):Play()
            TweenService:Create(row, TweenInfo.new(0.2), {
                BackgroundTransparency = 0.28
            }):Play()
            
            if icon then
                local ico = row:FindFirstChild("ImageLabel")
                if ico then
                    TweenService:Create(ico, TweenInfo.new(0.2), {
                        ImageColor3 = C.white
                    }):Play()
                end
            end
        end
        
        pcall(function() callback(state) end)
    end)
    
    return row
end

-- Slider mejorado
local function CreateSlider(parent, title, min, max, default, icon, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 68)
    row.BackgroundColor3 = C.panel
    row.BackgroundTransparency = 0.28
    row.BorderSizePixel = 0
    row.ZIndex = 13
    row.Parent = parent
    
    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 12)
    rc.Parent = row
    
    -- Icono
    if icon then
        local ico = Instance.new("ImageLabel")
        ico.Size = UDim2.new(0, 18, 0, 18)
        ico.Position = UDim2.new(0, 16, 0, 10)
        ico.BackgroundTransparency = 1
        ico.Image = icon
        ico.ImageColor3 = C.white
        ico.ZIndex = 14
        ico.Parent = row
    end
    
    -- Título
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(0.65, 0, 0, 22)
    tl.Position = UDim2.new(0, icon and 42 or 16, 0, 10)
    tl.BackgroundTransparency = 1
    tl.Text = title
    tl.TextColor3 = C.white
    tl.TextSize = 13
    tl.Font = Enum.Font.GothamBold
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.ZIndex = 14
    tl.Parent = row
    
    -- Valor
    local vl = Instance.new("TextLabel")
    vl.Size = UDim2.new(0.35, icon and -44 or -18, 0, 22)
    vl.Position = UDim2.new(0.65, 0, 0, 10)
    vl.BackgroundTransparency = 1
    vl.Text = tostring(default)
    vl.TextColor3 = currentAccentColor
    vl.TextSize = 14
    vl.Font = Enum.Font.GothamBold
    vl.TextXAlignment = Enum.TextXAlignment.Right
    vl.ZIndex = 14
    vl.Parent = row
    
    -- Track
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -32, 0, 26)
    track.Position = UDim2.new(0, 16, 0, 40)
    track.BackgroundTransparency = 1
    track.ZIndex = 14
    track.Parent = row
    
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 0, 7)
    bg.Position = UDim2.new(0, 0, 0.5, -3.5)
    bg.BackgroundColor3 = Color3.fromRGB(24, 30, 50)
    bg.BorderSizePixel = 0
    bg.ZIndex = 14
    bg.Parent = track
    
    local bgC = Instance.new("UICorner")
    bgC.CornerRadius = UDim.new(1, 0)
    bgC.Parent = bg
    
    local p = (default - min) / (max - min)
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(p, 0, 1, 0)
    fill.BackgroundColor3 = currentAccentColor
    fill.BorderSizePixel = 0
    fill.ZIndex = 15
    fill.Parent = bg
    
    local fC = Instance.new("UICorner")
    fC.CornerRadius = UDim.new(1, 0)
    fC.Parent = fill
    
    -- Knob
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 22, 0, 22)
    knob.Position = UDim2.new(p, -11, 0.5, -11)
    knob.BackgroundColor3 = C.white
    knob.BorderSizePixel = 0
    knob.ZIndex = 16
    knob.Parent = track
    
    local kC = Instance.new("UICorner")
    kC.CornerRadius = UDim.new(1, 0)
    kC.Parent = knob
    
    -- Shadow del knob
    local ks = Instance.new("Frame")
    ks.Size = UDim2.new(0, 32, 0, 32)
    ks.Position = UDim2.new(0.5, -16, 0.5, -16)
    ks.BackgroundColor3 = currentAccentColor
    ks.BackgroundTransparency = 0.6
    ks.BorderSizePixel = 0
    ks.ZIndex = 15
    ks.Parent = knob
    
    local ksC = Instance.new("UICorner")
    ksC.CornerRadius = UDim.new(1, 0)
    ksC.Parent = ks
    
    local dragging = false
    
    local function update(posX)
        local rel = posX - track.AbsolutePosition.X
        local pct = math.clamp(rel / track.AbsoluteSize.X, 0, 1)
        local v = math.floor(min + (max - min) * pct + 0.5)
        
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, -11, 0.5, -11)
        vl.Text = tostring(v)
        
        pcall(function() callback(v) end)
    end
    
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(inp.Position.X)
            TweenService:Create(knob, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 26, 0, 26)
            }):Play()
        end
    end)
    
    track.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 22, 0, 22)
            }):Play()
        end
    end)
    
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            update(inp.Position.X)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 22, 0, 22)
            }):Play()
        end
    end)
    
    return row
end

-- Botón mejorado con ripple
local function CreateButton(parent, title, desc, icon, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 50)
    btn.BackgroundColor3 = currentAccentColor
    btn.BackgroundTransparency = 0.68
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.ClipsDescendants = true
    btn.ZIndex = 13
    btn.Parent = parent
    
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 12)
    bc.Parent = btn
    
    local bs = Instance.new("UIStroke")
    bs.Color = currentAccentColor
    bs.Thickness = 1.2
    bs.Transparency = 0.45
    bs.Parent = btn
    
    -- Icono
    if icon then
        local ico = Instance.new("ImageLabel")
        ico.Size = UDim2.new(0, 22, 0, 22)
        ico.Position = UDim2.new(0, 16, 0.5, -11)
        ico.BackgroundTransparency = 1
        ico.Image = icon
        ico.ImageColor3 = C.white
        ico.ZIndex = 14
        ico.Parent = btn
    end
    
    -- Título
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, icon and -50 or -24, 0, 24)
    tl.Position = UDim2.new(0, icon and 46 or 16, 0, 7)
    tl.BackgroundTransparency = 1
    tl.Text = title
    tl.TextColor3 = C.white
    tl.TextSize = 13
    tl.Font = Enum.Font.GothamBold
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.ZIndex = 14
    tl.Parent = btn
    
    -- Descripción
    local dl = Instance.new("TextLabel")
    dl.Size = UDim2.new(1, icon and -50 or -24, 0, 15)
    dl.Position = UDim2.new(0, icon and 46 or 16, 0, 30)
    dl.BackgroundTransparency = 1
    dl.Text = desc
    dl.TextColor3 = C.dim
    dl.TextSize = 10
    dl.Font = Enum.Font.Gotham
    dl.TextXAlignment = Enum.TextXAlignment.Left
    dl.ZIndex = 14
    dl.Parent = btn
    
    btn.MouseEnter:Connect(function()
        PlaySound(Sounds.Hover)
        TweenService:Create(btn, TweenInfo.new(0.18), {
            BackgroundTransparency = 0.24
        }):Play()
        TweenService:Create(bs, TweenInfo.new(0.18), {
            Thickness = 1.6,
            Transparency = 0.15
        }):Play()
        TweenService:Create(tl, TweenInfo.new(0.16), {
            Position = icon and UDim2.new(0, 50, 0, 7) or UDim2.new(0, 20, 0, 7)
        }):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.18), {
            BackgroundTransparency = 0.68
        }):Play()
        TweenService:Create(bs, TweenInfo.new(0.18), {
            Thickness = 1.2,
            Transparency = 0.45
        }):Play()
        TweenService:Create(tl, TweenInfo.new(0.16), {
            Position = icon and UDim2.new(0, 46, 0, 7) or UDim2.new(0, 16, 0, 7)
        }):Play()
    end)
    
    btn.MouseButton1Click:Connect(function()
        PlaySound(Sounds.Click)
        
        -- Ripple effect
        local mousePos = UserInputService:GetMouseLocation()
        local rippleX = mousePos.X - btn.AbsolutePosition.X
        local rippleY = mousePos.Y - btn.AbsolutePosition.Y - 36  -- Ajuste por la barra superior
        CreateRipple(btn, rippleX, rippleY)
        
        -- Animación de click
        TweenService:Create(btn, TweenInfo.new(0.1), {
            BackgroundTransparency = 0.08,
            Size = UDim2.new(1, -6, 0, 48)
        }):Play()
        
        task.wait(0.1)
        
        TweenService:Create(btn, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.24,
            Size = UDim2.new(1, 0, 0, 50)
        }):Play()
        
        pcall(callback)
    end)
    
    return btn
end

-- Color picker mejorado
local function CreateColorPicker(parent, title, presets, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 88)
    f.BackgroundColor3 = C.panel
    f.BackgroundTransparency = 0.28
    f.BorderSizePixel = 0
    f.ZIndex = 13
    f.Parent = parent
    
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 12)
    fc.Parent = f
    
    -- Título
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, -24, 0, 20)
    tl.Position = UDim2.new(0, 16, 0, 10)
    tl.BackgroundTransparency = 1
    tl.Text = title
    tl.TextColor3 = C.white
    tl.TextSize = 13
    tl.Font = Enum.Font.GothamBold
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.ZIndex = 14
    tl.Parent = f
    
    -- Grid de colores
    local grid = Instance.new("Frame")
    grid.Size = UDim2.new(1, -24, 0, 44)
    grid.Position = UDim2.new(0, 12, 0, 38)
    grid.BackgroundTransparency = 1
    grid.ZIndex = 14
    grid.Parent = f
    
    local gl = Instance.new("UIGridLayout")
    gl.CellSize = UDim2.new(0, 38, 0, 38)
    gl.CellPadding = UDim2.new(0, 7, 0, 6)
    gl.Parent = grid
    
    local sel = nil
    
    for _, pr in ipairs(presets) do
        local dot = Instance.new("TextButton")
        dot.Size = UDim2.new(0, 38, 0, 38)
        dot.BackgroundColor3 = pr.color
        dot.BorderSizePixel = 0
        dot.Text = ""
        dot.ZIndex = 15
        dot.Parent = grid
        
        local dc = Instance.new("UICorner")
        dc.CornerRadius = UDim.new(1, 0)
        dc.Parent = dot
        
        local ds = Instance.new("UIStroke")
        ds.Color = C.white
        ds.Thickness = 2.5
        ds.Transparency = 1
        ds.Parent = dot
        
        dot.MouseEnter:Connect(function()
            PlaySound(Sounds.Hover)
            if dot ~= sel then
                TweenService:Create(dot, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 42, 0, 42)
                }):Play()
            end
        end)
        
        dot.MouseLeave:Connect(function()
            if dot ~= sel then
                TweenService:Create(dot, TweenInfo.new(0.16), {
                    Size = UDim2.new(0, 38, 0, 38)
                }):Play()
            end
        end)
        
        dot.MouseButton1Click:Connect(function()
            PlaySound(Sounds.Click)
            
            if sel then
                local os = sel:FindFirstChildOfClass("UIStroke")
                if os then
                    TweenService:Create(os, TweenInfo.new(0.16), {
                        Transparency = 1
                    }):Play()
                end
                TweenService:Create(sel, TweenInfo.new(0.16), {
                    Size = UDim2.new(0, 38, 0, 38)
                }):Play()
            end
            
            sel = dot
            TweenService:Create(ds, TweenInfo.new(0.2), {
                Transparency = 0.2
            }):Play()
            TweenService:Create(dot, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 42, 0, 42)
            }):Play()
            
            pcall(function() callback(pr.color, pr) end)
        end)
    end
    
    return f
end

-- Input field
local function CreateInput(parent, title, placeholder, icon, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 72)
    f.BackgroundColor3 = C.panel
    f.BackgroundTransparency = 0.28
    f.BorderSizePixel = 0
    f.ZIndex = 13
    f.Parent = parent
    
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 12)
    fc.Parent = f
    
    -- Título
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, -24, 0, 20)
    tl.Position = UDim2.new(0, 16, 0, 10)
    tl.BackgroundTransparency = 1
    tl.Text = title
    tl.TextColor3 = C.white
    tl.TextSize = 13
    tl.Font = Enum.Font.GothamBold
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.ZIndex = 14
    tl.Parent = f
    
    -- Input box
    local inputBox = Instance.new("Frame")
    inputBox.Size = UDim2.new(1, -32, 0, 34)
    inputBox.Position = UDim2.new(0, 16, 0, 34)
    inputBox.BackgroundColor3 = Color3.fromRGB(20, 26, 46)
    inputBox.BackgroundTransparency = 0.15
    inputBox.BorderSizePixel = 0
    inputBox.ZIndex = 14
    inputBox.Parent = f
    
    local ibc = Instance.new("UICorner")
    ibc.CornerRadius = UDim.new(0, 8)
    ibc.Parent = inputBox
    
    local ibs = Instance.new("UIStroke")
    ibs.Color = currentAccentColor
    ibs.Thickness = 1
    ibs.Transparency = 0.7
    ibs.Parent = inputBox
    
    -- Icono
    if icon then
        local ico = Instance.new("ImageLabel")
        ico.Size = UDim2.new(0, 18, 0, 18)
        ico.Position = UDim2.new(0, 12, 0.5, -9)
        ico.BackgroundTransparency = 1
        ico.Image = icon
        ico.ImageColor3 = C.dim
        ico.ZIndex = 15
        ico.Parent = inputBox
    end
    
    -- TextBox
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, icon and -44 or -20, 1, 0)
    input.Position = UDim2.new(0, icon and 38 or 12, 0, 0)
    input.BackgroundTransparency = 1
    input.PlaceholderText = placeholder
    input.PlaceholderColor3 = C.dim
    input.Text = ""
    input.TextColor3 = C.white
    input.TextSize = 12
    input.Font = Enum.Font.Gotham
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.ClearTextOnFocus = false
    input.ZIndex = 15
    input.Parent = inputBox
    
    input.Focused:Connect(function()
        TweenService:Create(ibs, TweenInfo.new(0.18), {
            Transparency = 0.2
        }):Play()
        TweenService:Create(inputBox, TweenInfo.new(0.18), {
            BackgroundTransparency = 0.05
        }):Play()
        
        if icon then
            local ico = inputBox:FindFirstChild("ImageLabel")
            if ico then
                TweenService:Create(ico, TweenInfo.new(0.18), {
                    ImageColor3 = currentAccentColor
                }):Play()
            end
        end
    end)
    
    input.FocusLost:Connect(function(enterPressed)
        TweenService:Create(ibs, TweenInfo.new(0.18), {
            Transparency = 0.7
        }):Play()
        TweenService:Create(inputBox, TweenInfo.new(0.18), {
            BackgroundTransparency = 0.15
        }):Play()
        
        if icon then
            local ico = inputBox:FindFirstChild("ImageLabel")
            if ico then
                TweenService:Create(ico, TweenInfo.new(0.18), {
                    ImageColor3 = C.dim
                }):Play()
            end
        end
        
        if enterPressed and callback then
            pcall(function() callback(input.Text) end)
        end
    end)
    
    return f, input
end

-- ================================================
-- CREAR TABS Y PANELES
-- ================================================

-- Crear tabs
for i, tabConfig in ipairs(TAB_CONFIG) do
    local btn = CreateTabButton(tabConfig.id, tabConfig.label, tabConfig.icon, i)
    btn.MouseButton1Click:Connect(function()
        SwitchTab(tabConfig.id)
    end)
    CreatePanel(tabConfig.id)
end

-- ================================================
-- TAB: HOME / INICIO
-- ================================================
local pHome = tabPanels["home"]

CreateSection(pHome, "🏠  Panel Principal", Icons.home)

-- Stats del usuario
local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(1, 0, 0, 120)
statsFrame.BackgroundColor3 = C.panel
statsFrame.BackgroundTransparency = 0.22
statsFrame.BorderSizePixel = 0
statsFrame.ZIndex = 13
statsFrame.Parent = pHome

local sfC = Instance.new("UICorner")
sfC.CornerRadius = UDim.new(0, 14)
sfC.Parent = statsFrame

-- Avatar
local avatar = Instance.new("ImageLabel")
avatar.Size = UDim2.new(0, 70, 0, 70)
avatar.Position = UDim2.new(0, 20, 0.5, -35)
avatar.BackgroundColor3 = C.dark
avatar.BorderSizePixel = 0
avatar.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
avatar.ZIndex = 14
avatar.Parent = statsFrame

local avC = Instance.new("UICorner")
avC.CornerRadius = UDim.new(1, 0)
avC.Parent = avatar

local avS = Instance.new("UIStroke")
avS.Color = currentAccentColor
avS.Thickness = 2.5
avS.Transparency = 0.3
avS.Parent = avatar

-- Info del usuario
local userName = Instance.new("TextLabel")
userName.Size = UDim2.new(0, 380, 0, 26)
userName.Position = UDim2.new(0, 105, 0, 18)
userName.BackgroundTransparency = 1
userName.Text = LocalPlayer.Name
userName.TextColor3 = C.white
userName.TextSize = 17
userName.Font = Enum.Font.GothamBold
userName.TextXAlignment = Enum.TextXAlignment.Left
userName.ZIndex = 14
userName.Parent = statsFrame

local userDisplay = Instance.new("TextLabel")
userDisplay.Size = UDim2.new(0, 380, 0, 18)
userDisplay.Position = UDim2.new(0, 105, 0, 46)
userDisplay.BackgroundTransparency = 1
userDisplay.Text = "@" .. LocalPlayer.DisplayName .. "  •  ID: " .. LocalPlayer.UserId
userDisplay.TextColor3 = C.dim
userDisplay.TextSize = 11
userDisplay.Font = Enum.Font.Gotham
userDisplay.TextXAlignment = Enum.TextXAlignment.Left
userDisplay.ZIndex = 14
userDisplay.Parent = statsFrame

-- Status badges
local statusContainer = Instance.new("Frame")
statusContainer.Size = UDim2.new(0, 380, 0, 24)
statusContainer.Position = UDim2.new(0, 105, 0, 72)
statusContainer.BackgroundTransparency = 1
statusContainer.ZIndex = 14
statusContainer.Parent = statsFrame

local statusList = Instance.new("UIListLayout")
statusList.FillDirection = Enum.FillDirection.Horizontal
statusList.Padding = UDim.new(0, 8)
statusList.Parent = statusContainer

-- Badge: Premium
local premiumBadge = Instance.new("Frame")
premiumBadge.Size = UDim2.new(0, 80, 0, 22)
premiumBadge.BackgroundColor3 = C.yellow
premiumBadge.BackgroundTransparency = 0.75
premiumBadge.BorderSizePixel = 0
premiumBadge.ZIndex = 15
premiumBadge.Parent = statusContainer

local pbC = Instance.new("UICorner")
pbC.CornerRadius = UDim.new(0, 6)
pbC.Parent = premiumBadge

local pbL = Instance.new("TextLabel")
pbL.Size = UDim2.new(1, 0, 1, 0)
pbL.BackgroundTransparency = 1
pbL.Text = "⭐ Premium"
pbL.TextColor3 = C.yellow
pbL.TextSize = 10
pbL.Font = Enum.Font.GothamBold
pbL.ZIndex = 16
pbL.Parent = premiumBadge

-- Badge: Active
local activeBadge = Instance.new("Frame")
activeBadge.Size = UDim2.new(0, 70, 0, 22)
activeBadge.BackgroundColor3 = C.green
activeBadge.BackgroundTransparency = 0.75
activeBadge.BorderSizePixel = 0
activeBadge.ZIndex = 15
activeBadge.Parent = statusContainer

local abC = Instance.new("UICorner")
abC.CornerRadius = UDim.new(0, 6)
abC.Parent = activeBadge

local abL = Instance.new("TextLabel")
abL.Size = UDim2.new(1, 0, 1, 0)
abL.BackgroundTransparency = 1
abL.Text = "● Activo"
abL.TextColor3 = C.green
abL.TextSize = 10
abL.Font = Enum.Font.GothamBold
abL.ZIndex = 16
abL.Parent = activeBadge

-- Animación de pulso para active badge
task.spawn(function()
    while activeBadge.Parent do
        TweenService:Create(abL, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            TextTransparency = 0.3
        }):Play()
        task.wait(1.2)
        TweenService:Create(abL, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            TextTransparency = 0
        }):Play()
        task.wait(1.2)
    end
end)

CreateSection(pHome, "⚡  Acceso Rápido", Icons.zap)

-- Botones de acceso rápido (2 columnas)
local quickActions = Instance.new("Frame")
quickActions.Size = UDim2.new(1, 0, 0, 110)
quickActions.BackgroundTransparency = 1
quickActions.ZIndex = 13
quickActions.Parent = pHome

local qaGrid = Instance.new("UIGridLayout")
qaGrid.CellSize = UDim2.new(0.485, 0, 0, 50)
qaGrid.CellPadding = UDim2.new(0.03, 0, 0, 10)
qaGrid.Parent = quickActions

local quickBtns = {
    {title = "Auto Farm", icon = Icons.target, color = C.green, action = function()
        Flags.AutoFarm = not Flags.AutoFarm
        if Flags.AutoFarm then StartFarm() end
        ShowNotification("Auto Farm", Flags.AutoFarm and "Activado" or "Desactivado", 2, Icons.check, Flags.AutoFarm and C.green or C.red)
    end},
    {title = "Speed Boost", icon = Icons.zap, color = C.yellow, action = function()
        Flags.SpeedHack = not Flags.SpeedHack
        ApplySpeed(Flags.SpeedHack)
        ShowNotification("Speed", Flags.SpeedHack and "Activado" or "Desactivado", 2, Icons.check, Flags.SpeedHack and C.green or C.red)
    end},
    {title = "ESP Players", icon = Icons.eye, color = C.blue, action = function()
        Flags.ESPPlayers = not Flags.ESPPlayers
        RefreshESP()
        ShowNotification("ESP", Flags.ESPPlayers and "Activado" or "Desactivado", 2, Icons.check, Flags.ESPPlayers and C.green or C.red)
    end},
    {title = "Anti AFK", icon = Icons.check, color = C.purple, action = function()
        Flags.AntiAFK = not Flags.AntiAFK
        if Flags.AntiAFK then StartAntiAFK() end
        ShowNotification("Anti AFK", Flags.AntiAFK and "Activado" or "Desactivado", 2, Icons.check, Flags.AntiAFK and C.green or C.red)
    end},
}

for _, qb in ipairs(quickBtns) do
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = qb.color
    btn.BackgroundTransparency = 0.7
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.ClipsDescendants = true
    btn.ZIndex = 14
    btn.Parent = quickActions
    
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 10)
    bc.Parent = btn
    
    local bs = Instance.new("UIStroke")
    bs.Color = qb.color
    bs.Thickness = 1.2
    bs.Transparency = 0.5
    bs.Parent = btn
    
    local ico = Instance.new("ImageLabel")
    ico.Size = UDim2.new(0, 22, 0, 22)
    ico.Position = UDim2.new(0, 14, 0.5, -11)
    ico.BackgroundTransparency = 1
    ico.Image = qb.icon
    ico.ImageColor3 = C.white
    ico.ZIndex = 15
    ico.Parent = btn
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -48, 1, 0)
    lbl.Position = UDim2.new(0, 44, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = qb.title
    lbl.TextColor3 = C.white
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 15
    lbl.Parent = btn
    
    btn.MouseEnter:Connect(function()
        PlaySound(Sounds.Hover)
        TweenService:Create(btn, TweenInfo.new(0.16), {
            BackgroundTransparency = 0.35
        }):Play()
        TweenService:Create(bs, TweenInfo.new(0.16), {
            Transparency = 0.15
        }):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.16), {
            BackgroundTransparency = 0.7
        }):Play()
        TweenService:Create(bs, TweenInfo.new(0.16), {
            Transparency = 0.5
        }):Play()
    end)
    
    btn.MouseButton1Click:Connect(function()
        PlaySound(Sounds.Click)
        
        local mousePos = UserInputService:GetMouseLocation()
        local rippleX = mousePos.X - btn.AbsolutePosition.X
        local rippleY = mousePos.Y - btn.AbsolutePosition.Y - 36
        CreateRipple(btn, rippleX, rippleY)
        
        pcall(qb.action)
        AddToHistory("Quick Action", qb.title)
    end)
end

CreateSection(pHome, "📊  Estadísticas de Sesión", Icons.activity)

local sessionStats = Instance.new("Frame")
sessionStats.Size = UDim2.new(1, 0, 0, 90)
sessionStats.BackgroundColor3 = C.panel
sessionStats.BackgroundTransparency = 0.3
sessionStats.BorderSizePixel = 0
sessionStats.ZIndex = 13
sessionStats.Parent = pHome

local ssC = Instance.new("UICorner")
ssC.CornerRadius = UDim.new(0, 12)
ssC.Parent = sessionStats

-- Grid de stats
local statsGrid = Instance.new("UIGridLayout")
statsGrid.CellSize = UDim2.new(0.32, 0, 0, 70)
statsGrid.CellPadding = UDim2.new(0.02, 0, 0, 10)
statsGrid.Parent = sessionStats

local statLabels = {
    {title = "Tiempo", value = "0m", icon = "⏱️"},
    {title = "Acciones", value = "0", icon = "⚡"},
    {title = "Status", value = "Activo", icon = "✅"},
}

for _, stat in ipairs(statLabels) do
    local statBox = Instance.new("Frame")
    statBox.BackgroundTransparency = 1
    statBox.ZIndex = 14
    statBox.Parent = sessionStats
    
    local emoji = Instance.new("TextLabel")
    emoji.Size = UDim2.new(1, 0, 0, 28)
    emoji.Position = UDim2.new(0, 0, 0, 8)
    emoji.BackgroundTransparency = 1
    emoji.Text = stat.icon
    emoji.TextSize = 24
    emoji.ZIndex = 15
    emoji.Parent = statBox
    
    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(1, 0, 0, 20)
    val.Position = UDim2.new(0, 0, 0, 36)
    val.BackgroundTransparency = 1
    val.Text = stat.value
    val.TextColor3 = currentAccentColor
    val.TextSize = 14
    val.Font = Enum.Font.GothamBold
    val.ZIndex = 15
    val.Parent = statBox
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 14)
    title.Position = UDim2.new(0, 0, 0, 54)
    title.BackgroundTransparency = 1
    title.Text = stat.title
    title.TextColor3 = C.dim
    title.TextSize = 10
    title.Font = Enum.Font.Gotham
    title.ZIndex = 15
    title.Parent = statBox
end

-- Actualizar tiempo de sesión
local sessionStartTime = tick()
task.spawn(function()
    while pHome.Parent do
        task.wait(60)  -- Actualizar cada minuto
        local elapsed = math.floor((tick() - sessionStartTime) / 60)
        local statBoxes = sessionStats:GetChildren()
        for _, box in ipairs(statBoxes) do
            if box:IsA("Frame") then
                local valLabel = box:FindFirstChild("TextLabel")
                if valLabel and valLabel.Text:match("m") then
                    valLabel.Text = elapsed .. "m"
                    break
                end
            end
        end
    end
end)

-- ================================================
-- TAB: FARMING
-- ================================================
local pFarming = tabPanels["farming"]

CreateSection(pFarming, "🎯  Auto Farming", Icons.target)

CreateToggle(pFarming, "Auto Farm", "Farmea mobs automáticamente", Icons.target, function(v)
    Flags.AutoFarm = v
    if v then
        StartFarm()
        ShowNotification("Auto Farm", "Iniciando farm automático", 2, Icons.check, C.green)
        AddToHistory("Auto Farm", "ON")
    else
        ShowNotification("Auto Farm", "Farm detenido", 2, Icons.x, C.red)
        AddToHistory("Auto Farm", "OFF")
    end
    SaveConfig()
    SetStatus("Farm: " .. (v and "ON" or "OFF"), v and C.green or C.red)
end)

CreateSlider(pFarming, "Distancia de Detección", 50, 300, Config.FarmDist, Icons.target, function(v)
    Config.FarmDist = v
    SaveConfig()
    SetStatus("Distancia: " .. v, C.yellow)
end)

CreateSection(pFarming, "💰  Auto Collect", Icons.activity)

CreateToggle(pFarming, "Auto Collect", "Recolecta items automáticamente", Icons.download, function(v)
    Flags.AutoCollect = v
    if v then
        StartCollect()
        ShowNotification("Auto Collect", "Recolección iniciada", 2, Icons.check, C.green)
        AddToHistory("Auto Collect", "ON")
    else
        ShowNotification("Auto Collect", "Recolección detenida", 2, Icons.x, C.red)
        AddToHistory("Auto Collect", "OFF")
    end
    SaveConfig()
    SetStatus("Collect: " .. (v and "ON" or "OFF"), v and C.green or C.red)
end)

CreateSlider(pFarming, "Radio de Recolección", 10, 80, Config.CollectRad, Icons.navigation, function(v)
    Config.CollectRad = v
    SaveConfig()
    SetStatus("Radio: " .. v, C.yellow)
end)

CreateSection(pFarming, "⚡  Optimización", Icons.zap)

CreateButton(pFarming, "Limpiar Workspace", "Remueve objetos innecesarios", Icons.trash, function()
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Part") and not obj.Anchored and not obj.Parent:FindFirstChildOfClass("Humanoid") then
            pcall(function()
                obj:Destroy()
                count = count + 1
            end)
        end
    end
    ShowNotification("Limpieza", "Removidos " .. count .. " objetos", 3, Icons.check, C.green)
    AddToHistory("Limpieza", count .. " objetos")
    SetStatus("✨ Workspace limpio", C.green)
end)

CreateButton(pFarming, "Maximizar FPS", "Desactiva efectos visuales", Icons.zap, function()
    pcall(function()
        local lighting = game:GetService("Lighting")
        lighting.GlobalShadows = false
        lighting.FogEnd = 9e9
        
        for _, obj in ipairs(lighting:GetChildren()) do
            if obj:IsA("BlurEffect") or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect") or obj:IsA("BloomEffect") or obj:IsA("DepthOfFieldEffect") then
                obj.Enabled = false
            end
        end
        
        settings().Rendering.QualityLevel = 1
    end)
    
    ShowNotification("FPS Boost", "Efectos visuales optimizados", 3, Icons.check, C.green)
    AddToHistory("FPS Boost", "Optimizado")
    SetStatus("⚡ FPS maximizado", C.yellow)
end)

-- ================================================
-- TAB: PLAYER
-- ================================================
local pPlayer = tabPanels["player"]

CreateSection(pPlayer, "🏃  Movimiento", Icons.zap)

CreateToggle(pPlayer, "Speed Hack", "Aumenta velocidad de movimiento", Icons.zap, function(v)
    Flags.SpeedHack = v
    ApplySpeed(v)
    ShowNotification("Speed", v and "Velocidad aumentada" or "Velocidad normal", 2, Icons.check, v and C.green or C.red)
    AddToHistory("Speed Hack", v and "ON" or "OFF")
    SaveConfig()
    SetStatus("Speed: " .. (v and Config.SpeedVal or Config.OrigSpeed), v and C.green or C.dim)
end)

CreateSlider(pPlayer, "Velocidad", 16, 150, Config.SpeedVal, Icons.zap, function(v)
    Config.SpeedVal = v
    if Flags.SpeedHack then ApplySpeed(true) end
    SaveConfig()
    SetStatus("WalkSpeed: " .. v, C.yellow)
end)

CreateToggle(pPlayer, "Infinite Jump", "Salta infinitamente", Icons.activity, function(v)
    Flags.InfJump = v
    if v then
        StartInfJump()
        ShowNotification("Infinite Jump", "Salto infinito activado", 2, Icons.check, C.green)
        AddToHistory("Inf Jump", "ON")
    else
        ShowNotification("Infinite Jump", "Salto normal", 2, Icons.x, C.red)
        AddToHistory("Inf Jump", "OFF")
    end
    SaveConfig()
    SetStatus("InfJump: " .. (v and "ON" or "OFF"), v and C.green or C.red)
end)

CreateSection(pPlayer, "🛡️  Protección", Icons.check)

CreateToggle(pPlayer, "Anti AFK", "Evita ser kickeado por inactividad", Icons.check, function(v)
    Flags.AntiAFK = v
    if v then
        StartAntiAFK()
        ShowNotification("Anti AFK", "Protección activada", 2, Icons.check, C.green)
        AddToHistory("Anti AFK", "ON")
    else
        ShowNotification("Anti AFK", "Protección desactivada", 2, Icons.x, C.red)
        AddToHistory("Anti AFK", "OFF")
    end
    SaveConfig()
    SetStatus("Anti-AFK: " .. (v and "ON" or "OFF"), v and C.green or C.red)
end)

CreateToggle(pPlayer, "God Mode (Beta)", "Intenta evitar daño", Icons.check, function(v)
    -- Implementación básica de God Mode
    if v then
        local char = GetChar()
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.MaxHealth = math.huge
                hum.Health = math.huge
            end
        end
        ShowNotification("God Mode", "Modo dios activado (experimental)", 3, Icons.check, C.yellow)
        AddToHistory("God Mode", "ON")
    else
        local char = GetChar()
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.MaxHealth = 100
                hum.Health = 100
            end
        end
        ShowNotification("God Mode", "Modo dios desactivado", 2, Icons.x, C.red)
        AddToHistory("God Mode", "OFF")
    end
    SaveConfig()
    SetStatus("GodMode: " .. (v and "ON" or "OFF"), v and C.yellow or C.red)
end)

CreateSection(pPlayer, "💀  Acciones de Jugador", Icons.user)

CreateButton(pPlayer, "Reset Character", "Resetea tu personaje", Icons.x, function()
    local h = GetHum()
    if h then
        h.Health = 0
        ShowNotification("Reset", "Personaje reseteado", 2, Icons.check, C.yellow)
        AddToHistory("Reset", "Personaje")
        SetStatus("💀 Reset", C.yellow)
    end
end)

CreateButton(pPlayer, "Heal Full", "Cura completamente", Icons.check, function()
    local h = GetHum()
    if h then
        h.Health = h.MaxHealth
        ShowNotification("Heal", "Salud restaurada", 2, Icons.check, C.green)
        AddToHistory("Heal", "Full HP")
        SetStatus("❤️ HP: Full", C.green)
    end
end)

-- ================================================
-- TAB: VISUAL
-- ================================================
local pVisual = tabPanels["visual"]

CreateSection(pVisual, "👁️  ESP & Wallhacks", Icons.eye)

CreateToggle(pVisual, "ESP Players", "Ver jugadores a través de paredes", Icons.users, function(v)
    Flags.ESPPlayers = v
    RefreshESP()
    ShowNotification("ESP Players", v and "ESP activado" or "ESP desactivado", 2, Icons.eye, v and C.green or C.red)
    AddToHistory("ESP Players", v and "ON" or "OFF")
    SaveConfig()
    SetStatus("ESP Players: " .. (v and "ON" or "OFF"), v and C.green or C.red)
end)

CreateToggle(pVisual, "ESP NPCs", "Ver NPCs a través de paredes", Icons.target, function(v)
    Flags.ESPNpcs = v
    RefreshNPCESP(v)
    ShowNotification("ESP NPCs", v and "ESP activado" or "ESP desactivado", 2, Icons.eye, v and C.green or C.red)
    AddToHistory("ESP NPCs", v and "ON" or "OFF")
    SaveConfig()
    SetStatus("ESP NPCs: " .. (v and "ON" or "OFF"), v and C.green or C.red)
end)

CreateSlider(pVisual, "ESP Transparency", 0, 10, Config.ESPFillTransp * 10, Icons.eye, function(v)
    Config.ESPFillTransp = v / 10
    if Flags.ESPPlayers then RefreshESP() end
    if Flags.ESPNpcs then RefreshNPCESP(true) end
    SaveConfig()
    SetStatus("ESP Transp: " .. v * 10 .. "%", C.yellow)
end)

CreateSection(pVisual, "💡  Iluminación", Icons.sparkles)

CreateButton(pVisual, "Full Bright", "Iluminación máxima", Icons.star, function()
    pcall(function()
        game:GetService("Lighting").Brightness = 2
        game:GetService("Lighting").ClockTime = 14
        game:GetService("Lighting").FogEnd = 100000
        game:GetService("Lighting").GlobalShadows = false
        game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end)
    ShowNotification("Full Bright", "Iluminación maximizada", 2, Icons.check, C.green)
    AddToHistory("Full Bright", "Activado")
    SetStatus("💡 Full Bright", C.yellow)
end)

CreateButton(pVisual, "Remove Fog", "Eliminar niebla", Icons.eye, function()
    pcall(function()
        game:GetService("Lighting").FogEnd = 100000
        for _, effect in ipairs(game:GetService("Lighting"):GetChildren()) do
            if effect:IsA("Atmosphere") then
                effect:Destroy()
            end
        end
    end)
    ShowNotification("Remove Fog", "Niebla eliminada", 2, Icons.check, C.green)
    AddToHistory("Remove Fog", "Eliminado")
    SetStatus("🌫️ Sin niebla", C.yellow)
end)

CreateSection(pVisual, "🎨  Efectos Visuales", Icons.sparkles)

CreateToggle(pVisual, "Partículas de Fondo", "Mostrar partículas flotantes", Icons.sparkles, function(v)
    Flags.Particles = v
    SaveConfig()
    SetStatus("Partículas: " .. (v and "ON" or "OFF"), v and C.green or C.red)
    
    if not v then
        -- Ocultar partículas
        for _, p in ipairs(ParticlesContainer:GetChildren()) do
            if p:IsA("Frame") then
                TweenService:Create(p, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
            end
        end
    else
        -- Mostrar partículas
        for _, p in ipairs(ParticlesContainer:GetChildren()) do
            if p:IsA("Frame") then
                TweenService:Create(p, TweenInfo.new(0.5), {BackgroundTransparency = 0.7}):Play()
            end
        end
    end
end)

-- ================================================
-- TAB: TELEPORT
-- ================================================
local pTeleport = tabPanels["teleport"]

CreateSection(pTeleport, "📍  Guardar Posiciones", Icons.save)

-- Input para nombre de posición
local _, nameInput = CreateInput(pTeleport, "Nombre de Posición", "Ej: Base, Granja, etc.", Icons.mapPin, function(name)
    if name and name ~= "" then
        SaveTeleport(name)
    end
end)

CreateButton(pTeleport, "💾  Guardar Posición Actual", "Guarda tu ubicación actual", Icons.save, function()
    local name = nameInput.Text
    if name and name ~= "" then
        SaveTeleport(name)
        nameInput.Text = ""
    else
        ShowNotification("Error", "Ingresa un nombre para la posición", 3, Icons.x, C.red)
    end
end)

CreateSection(pTeleport, "🗺️  Posiciones Guardadas", Icons.mapPin)

-- Lista de teleports guardados
local teleportList = Instance.new("Frame")
teleportList.Size = UDim2.new(1, 0, 0, 200)
teleportList.BackgroundColor3 = C.panel
teleportList.BackgroundTransparency = 0.35
teleportList.BorderSizePixel = 0
teleportList.ZIndex = 13
teleportList.Parent = pTeleport

local tlC = Instance.new("UICorner")
tlC.CornerRadius = UDim.new(0, 12)
tlC.Parent = teleportList

local teleportScroll = Instance.new("ScrollingFrame")
teleportScroll.Size = UDim2.new(1, -10, 1, -10)
teleportScroll.Position = UDim2.new(0, 5, 0, 5)
teleportScroll.BackgroundTransparency = 1
teleportScroll.BorderSizePixel = 0
teleportScroll.ScrollBarThickness = 4
teleportScroll.ScrollBarImageColor3 = currentAccentColor
teleportScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
teleportScroll.ZIndex = 14
teleportScroll.Parent = teleportList

local tpLayout = Instance.new("UIListLayout")
tpLayout.Padding = UDim.new(0, 6)
tpLayout.SortOrder = Enum.SortOrder.LayoutOrder
tpLayout.Parent = teleportScroll

tpLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    teleportScroll.CanvasSize = UDim2.new(0, 0, 0, tpLayout.AbsoluteContentSize.Y + 10)
end)

-- Función para actualizar lista de teleports
local function UpdateTeleportList()
    -- Limpiar lista actual
    for _, child in ipairs(teleportScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Agregar teleports guardados
    for name, data in pairs(SavedTeleports) do
        local tpItem = Instance.new("Frame")
        tpItem.Size = UDim2.new(1, -6, 0, 44)
        tpItem.BackgroundColor3 = C.dark
        tpItem.BackgroundTransparency = 0.25
        tpItem.BorderSizePixel = 0
        tpItem.ZIndex = 15
        tpItem.Parent = teleportScroll
        
        local tiC = Instance.new("UICorner")
        tiC.CornerRadius = UDim.new(0, 8)
        tiC.Parent = tpItem
        
        -- Nombre
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -100, 0, 20)
        nameLabel.Position = UDim2.new(0, 38, 0, 6)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextColor3 = C.white
        nameLabel.TextSize = 12
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.ZIndex = 16
        nameLabel.Parent = tpItem
        
        -- Coords
        local coordsLabel = Instance.new("TextLabel")
        coordsLabel.Size = UDim2.new(1, -100, 0, 14)
        coordsLabel.Position = UDim2.new(0, 38, 0, 26)
        coordsLabel.BackgroundTransparency = 1
        coordsLabel.Text = string.format("X:%.0f Y:%.0f Z:%.0f", data.Position[1], data.Position[2], data.Position[3])
        coordsLabel.TextColor3 = C.dim
        coordsLabel.TextSize = 9
        coordsLabel.Font = Enum.Font.Gotham
        coordsLabel.TextXAlignment = Enum.TextXAlignment.Left
        coordsLabel.ZIndex = 16
        coordsLabel.Parent = tpItem
        
        -- Icono
        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0, 20, 0, 20)
        icon.Position = UDim2.new(0, 10, 0.5, -10)
        icon.BackgroundTransparency = 1
        icon.Image = Icons.mapPin
        icon.ImageColor3 = currentAccentColor
        icon.ZIndex = 16
        icon.Parent = tpItem
        
        -- Botón TP
        local tpBtn = Instance.new("TextButton")
        tpBtn.Size = UDim2.new(0, 40, 0, 30)
        tpBtn.Position = UDim2.new(1, -46, 0.5, -15)
        tpBtn.BackgroundColor3 = C.blue
        tpBtn.BackgroundTransparency = 0.5
        tpBtn.BorderSizePixel = 0
        tpBtn.Text = "TP"
        tpBtn.TextColor3 = C.white
        tpBtn.TextSize = 11
        tpBtn.Font = Enum.Font.GothamBold
        tpBtn.ZIndex = 16
        tpBtn.Parent = tpItem
        
        local tbC = Instance.new("UICorner")
        tbC.CornerRadius = UDim.new(0, 6)
        tbC.Parent = tpBtn
        
        tpBtn.MouseEnter:Connect(function()
            TweenService:Create(tpBtn, TweenInfo.new(0.14), {BackgroundTransparency = 0.2}):Play()
        end)
        
        tpBtn.MouseLeave:Connect(function()
            TweenService:Create(tpBtn, TweenInfo.new(0.14), {BackgroundTransparency = 0.5}):Play()
        end)
        
        tpBtn.MouseButton1Click:Connect(function()
            PlaySound(Sounds.Click)
            TeleportTo(name)
        end)
    end
    
    -- Mensaje si no hay teleports
    if next(SavedTeleports) == nil then
        local emptyMsg = Instance.new("TextLabel")
        emptyMsg.Size = UDim2.new(1, 0, 0, 60)
        emptyMsg.BackgroundTransparency = 1
        emptyMsg.Text = "📍\n\nNo hay posiciones guardadas\nGuarda tu primera posición arriba"
        emptyMsg.TextColor3 = C.dim
        emptyMsg.TextSize = 11
        emptyMsg.Font = Enum.Font.Gotham
        emptyMsg.ZIndex = 15
        emptyMsg.Parent = teleportScroll
    end
end

-- Actualizar lista inicialmente
UpdateTeleportList()

-- Botón para limpiar teleports
CreateButton(pTeleport, "🗑️  Limpiar Todas las Posiciones", "Elimina todos los teleports guardados", Icons.trash, function()
    SavedTeleports = {}
    SaveConfig()
    UpdateTeleportList()
    ShowNotification("Limpieza", "Todos los teleports eliminados", 2, Icons.check, C.green)
    AddToHistory("Clear Teleports", "Todos eliminados")
    SetStatus("🗑️ Teleports eliminados", C.yellow)
end)

-- ================================================
-- TAB: MISC
-- ================================================
local pMisc = tabPanels["misc"]

CreateSection(pMisc, "🔧  Utilidades", Icons.folder)

CreateButton(pMisc, "📋  Copy PlaceId", "Copia el ID del juego", Icons.folder, function()
    pcall(function() setclipboard(tostring(game.PlaceId)) end)
    ShowNotification("Copiado", "PlaceId: " .. game.PlaceId, 3, Icons.check, C.green)
    AddToHistory("Copy PlaceId", game.PlaceId)
    SetStatus("📋 PlaceId: " .. game.PlaceId, C.green)
end)

CreateButton(pMisc, "📊  Ver Información del Juego", "Muestra detalles del juego actual", Icons.folder, function()
    local info = {
        "📊 Información del Juego",
        "",
        "🎮 Nombre: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
        "🆔 PlaceId: " .. game.PlaceId,
        "👥 Jugadores: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers,
        "🌍 JobId: " .. game.JobId:sub(1, 20) .. "...",
    }
    
    local infoText = table.concat(info, "\n")
    ShowNotification("Info del Juego", infoText, 8, Icons.folder, C.blue)
    AddToHistory("Game Info", "Mostrado")
    SetStatus("📊 Info mostrada", C.blue)
end)

CreateButton(pMisc, "🔊  Rejoin Server", "Reconecta al mismo servidor", Icons.navigation, function()
    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    ShowNotification("Rejoin", "Reconectando...", 2, Icons.navigation, C.yellow)
    
    task.wait(1)
    
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

CreateButton(pMisc, "🔄  Server Hop", "Cambia a otro servidor", Icons.navigation, function()
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    
    ShowNotification("Server Hop", "Buscando servidor...", 2, Icons.navigation, C.yellow)
    
    local servers = {}
    local cursor = ""
    
    repeat
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100&cursor=" .. cursor))
        end)
        
        if success then
            for _, server in ipairs(result.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(servers, server.id)
                end
            end
            cursor = result.nextPageCursor or ""
        else
            break
        end
    until cursor == ""
    
    if #servers > 0 then
        local randomServer = servers[math.random(1, #servers)]
        TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, LocalPlayer)
    else
        ShowNotification("Error", "No se encontraron servidores disponibles", 3, Icons.x, C.red)
    end
end)

CreateSection(pMisc, "📝  Historial de Acciones", Icons.activity)

local historyFrame = Instance.new("Frame")
historyFrame.Size = UDim2.new(1, 0, 0, 180)
historyFrame.BackgroundColor3 = C.panel
historyFrame.BackgroundTransparency = 0.35
historyFrame.BorderSizePixel = 0
historyFrame.ZIndex = 13
historyFrame.Parent = pMisc

local hfC = Instance.new("UICorner")
hfC.CornerRadius = UDim.new(0, 12)
hfC.Parent = historyFrame

local historyScroll = Instance.new("ScrollingFrame")
historyScroll.Size = UDim2.new(1, -10, 1, -10)
historyScroll.Position = UDim2.new(0, 5, 0, 5)
historyScroll.BackgroundTransparency = 1
historyScroll.BorderSizePixel = 0
historyScroll.ScrollBarThickness = 4
historyScroll.ScrollBarImageColor3 = currentAccentColor
historyScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
historyScroll.ZIndex = 14
historyScroll.Parent = historyFrame

local histLayout = Instance.new("UIListLayout")
histLayout.Padding = UDim.new(0, 4)
histLayout.SortOrder = Enum.SortOrder.LayoutOrder
histLayout.Parent = historyScroll

histLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    historyScroll.CanvasSize = UDim2.new(0, 0, 0, histLayout.AbsoluteContentSize.Y + 10)
end)

-- Actualizar historial cada 5 segundos
task.spawn(function()
    while historyFrame.Parent do
        -- Limpiar historial mostrado
        for _, child in ipairs(historyScroll:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        -- Mostrar últimas 10 acciones
        for i = 1, math.min(10, #ActionHistory) do
            local action = ActionHistory[i]
            
            local histItem = Instance.new("Frame")
            histItem.Size = UDim2.new(1, -6, 0, 32)
            histItem.BackgroundColor3 = C.dark
            histItem.BackgroundTransparency = 0.3
            histItem.BorderSizePixel = 0
            histItem.ZIndex = 15
            histItem.Parent = historyScroll
            
            local hiC = Instance.new("UICorner")
            hiC.CornerRadius = UDim.new(0, 6)
            hiC.Parent = histItem
            
            local actionLabel = Instance.new("TextLabel")
            actionLabel.Size = UDim2.new(0.6, 0, 1, 0)
            actionLabel.Position = UDim2.new(0, 10, 0, 0)
            actionLabel.BackgroundTransparency = 1
            actionLabel.Text = action.action
            actionLabel.TextColor3 = C.white
            actionLabel.TextSize = 11
            actionLabel.Font = Enum.Font.GothamSemibold
            actionLabel.TextXAlignment = Enum.TextXAlignment.Left
            actionLabel.ZIndex = 16
            actionLabel.Parent = histItem
            
            local detailLabel = Instance.new("TextLabel")
            detailLabel.Size = UDim2.new(0.4, -10, 1, 0)
            detailLabel.Position = UDim2.new(0.6, 0, 0, 0)
            detailLabel.BackgroundTransparency = 1
            detailLabel.Text = action.details
            detailLabel.TextColor3 = C.dim
            detailLabel.TextSize = 10
            detailLabel.Font = Enum.Font.Gotham
            detailLabel.TextXAlignment = Enum.TextXAlignment.Right
            detailLabel.ZIndex = 16
            detailLabel.Parent = histItem
        end
        
        -- Mensaje si no hay historial
        if #ActionHistory == 0 then
            local emptyMsg = Instance.new("TextLabel")
            emptyMsg.Size = UDim2.new(1, 0, 1, 0)
            emptyMsg.BackgroundTransparency = 1
            emptyMsg.Text = "📝\n\nNo hay acciones registradas\nEl historial aparecerá aquí"
            emptyMsg.TextColor3 = C.dim
            emptyMsg.TextSize = 11
            emptyMsg.Font = Enum.Font.Gotham
            emptyMsg.ZIndex = 15
            emptyMsg.Parent = historyScroll
        end
        
        task.wait(5)
    end
end)

CreateButton(pMisc, "🗑️  Limpiar Historial", "Borra todas las acciones registradas", Icons.trash, function()
    ActionHistory = {}
    ShowNotification("Limpieza", "Historial limpiado", 2, Icons.check, C.green)
    SetStatus("🗑️ Historial limpio", C.green)
end)

-- ================================================
-- TAB: CONFIG
-- ================================================
local pConfig = tabPanels["config"]

CreateSection(pConfig, "🎨  Color de Acento", Icons.settings)

CreateColorPicker(pConfig, "Selecciona un color", {
    {label = "Cyan", color = Color3.fromRGB(0, 180, 255)},
    {label = "Green", color = Color3.fromRGB(0, 220, 130)},
    {label = "Purple", color = Color3.fromRGB(160, 60, 255)},
    {label = "Pink", color = Color3.fromRGB(255, 60, 160)},
    {label = "Orange", color = Color3.fromRGB(255, 140, 30)},
    {label = "Red", color = Color3.fromRGB(220, 50, 80)},
}, function(col, pr)
    rgbEnabled = false
    currentAccentColor = col
    
    -- Actualizar todos los elementos con color de acento
    MainStroke.Color = col
    TBarLine.BackgroundColor3 = col
    SideDiv.BackgroundColor3 = col
    HubSub.TextColor3 = col
    logoS.Color = col
    
    for id, tab in pairs(tabButtons) do
        tab.ind.BackgroundColor3 = col
        if currentTab == id then
            tab.icon.ImageColor3 = col
            tab.row.BackgroundColor3 = col
        end
    end
    
    for _, p2 in pairs(tabPanels) do
        p2.ScrollBarImageColor3 = col
    end
    
    if Flags.ESPPlayers then RefreshESP() end
    
    SaveConfig()
    SetStatus("🎨 Color: " .. (pr.label or "Custom"), col)
    ShowNotification("Color Cambiado", "Nuevo color de acento: " .. pr.label, 2, Icons.check, col)
    AddToHistory("Color Change", pr.label)
end)

CreateSection(pConfig, "✨  Apariencia", Icons.sparkles)

CreateSlider(pConfig, "Transparencia UI", 0, 10, Config.UITransp * 10, Icons.eye, function(v)
    Config.UITransp = v / 10
    TweenService:Create(Main, TweenInfo.new(0.3), {
        BackgroundTransparency = math.max(0.02, v / 10)
    }):Play()
    SaveConfig()
    SetStatus("Transp: " .. v * 10 .. "%", C.yellow)
end)

CreateSlider(pConfig, "Fuerza del Blur", 0, 20, Config.BlurStrength, Icons.eye, function(v)
    Config.BlurStrength = v
    TweenService:Create(Blur, TweenInfo.new(0.3), {Size = v}):Play()
    SaveConfig()
    SetStatus("Blur: " .. v, C.yellow)
end)

CreateSlider(pConfig, "Velocidad de Animación", 1, 10, Config.AnimSpeed * 10, Icons.zap, function(v)
    Config.AnimSpeed = v / 10
    SaveConfig()
    SetStatus("Anim: " .. v / 10 .. "s", C.yellow)
end)

CreateToggle(pConfig, "🌈 Modo RGB", "Borde arcoíris animado", Icons.sparkles, function(v)
    rgbEnabled = v
    SaveConfig()
    if v then
        SetStatus("🌈 RGB ON", Color3.fromHSV(0, 1, 1))
        ShowNotification("RGB Mode", "Modo arcoíris activado", 2, Icons.sparkles, Color3.fromHSV(rgbHue / 360, 1, 1))
    else
        MainStroke.Color = currentAccentColor
        TBarLine.BackgroundColor3 = currentAccentColor
        SideDiv.BackgroundColor3 = currentAccentColor
        SetStatus("🌈 RGB OFF", currentAccentColor)
        ShowNotification("RGB Mode", "Modo arcoíris desactivado", 2, Icons.x, C.red)
    end
end)

CreateSection(pConfig, "🔔  Notificaciones", Icons.check)

CreateToggle(pConfig, "Mostrar Notificaciones", "Recibir notificaciones del hub", Icons.check, function(v)
    Flags.Notifications = v
    SaveConfig()
    SetStatus("Notif: " .. (v and "ON" or "OFF"), v and C.green or C.red)
    
    if v then
        ShowNotification("Notificaciones", "Notificaciones activadas", 2, Icons.check, C.green)
    end
end)

CreateSection(pConfig, "💾  Guardado", Icons.save)

CreateButton(pConfig, "💾  Guardar Configuración", "Guarda todos los ajustes actuales", Icons.save, function()
    SaveConfig()
    ShowNotification("Guardado", "Configuración guardada exitosamente", 3, Icons.check, C.green)
    AddToHistory("Save Config", "Manual")
    SetStatus("💾 Config guardada", C.green)
end)

CreateButton(pConfig, "🔄  Recargar Configuración", "Carga la última configuración guardada", Icons.download, function()
    LoadConfig()
    ShowNotification("Recarga", "Configuración recargada", 3, Icons.check, C.green)
    AddToHistory("Load Config", "Manual")
    SetStatus("🔄 Config recargada", C.green)
end)

CreateButton(pConfig, "🗑️  Reset Configuración", "Restaura valores por defecto", Icons.trash, function()
    -- Reset a defaults
    Config.UITransp = 0.08
    Config.BlurStrength = 10
    Config.AnimSpeed = 0.28
    Config.FarmDist = 100
    Config.SpeedVal = 50
    Config.CollectRad = 30
    
    Flags.AutoFarm = false
    Flags.AutoCollect = false
    Flags.AntiAFK = false
    Flags.InfJump = false
    Flags.SpeedHack = false
    Flags.ESPPlayers = false
    Flags.ESPNpcs = false
    Flags.Notifications = true
    Flags.Particles = true
    
    currentAccentColor = Color3.fromRGB(0, 180, 255)
    rgbEnabled = false
    
    SaveConfig()
    
    ShowNotification("Reset", "Configuración reseteada a defaults", 3, Icons.check, C.yellow)
    AddToHistory("Reset Config", "To Defaults")
    SetStatus("🗑️ Config reseteada", C.yellow)
end)

CreateSection(pConfig, "ℹ️  Información", Icons.folder)

local infoBox = Instance.new("Frame")
infoBox.Size = UDim2.new(1, 0, 0, 110)
infoBox.BackgroundColor3 = C.panel
infoBox.BackgroundTransparency = 0.25
infoBox.BorderSizePixel = 0
infoBox.ZIndex = 13
infoBox.Parent = pConfig

local ibC = Instance.new("UICorner")
ibC.CornerRadius = UDim.new(0, 12)
ibC.Parent = infoBox

local infoText = Instance.new("TextLabel")
infoText.Size = UDim2.new(1, -32, 1, -32)
infoText.Position = UDim2.new(0, 16, 0, 16)
infoText.BackgroundTransparency = 1
infoText.Text = [[
🎨 CHLOE X Hub v5.0 - Ultra Edition
━━━━━━━━━━━━━━━━━━━━━
Created by: Chloe
Build: Ultra 2025

• Sistema de guardado automático
• Notificaciones modernas
• Iconos Lucide
• Efectos visuales avanzados
• +50 funcionalidades

Gracias por usar Chloe X Hub! 💙
]]
infoText.TextColor3 = C.dim
infoText.TextSize = 11
infoText.Font = Enum.Font.Gotham
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.TextYAlignment = Enum.TextYAlignment.Top
infoText.ZIndex = 14
infoText.Parent = infoBox

-- ================================================
-- RGB LOOP
-- ================================================
task.spawn(function()
    while Main.Parent do
        if rgbEnabled then
            rgbHue = (rgbHue + 0.5) % 360
            local col = Color3.fromHSV(rgbHue / 360, 1, 1)
            
            MainStroke.Color = col
            TBarLine.BackgroundColor3 = col
            SideDiv.BackgroundColor3 = col
            MainStroke.Transparency = 0.15 + 0.12 * math.sin(tick() * 2)
            
            for id, tab in pairs(tabButtons) do
                tab.ind.BackgroundColor3 = col
                if currentTab == id then
                    tab.icon.ImageColor3 = col
                    tab.row.BackgroundColor3 = col
                end
            end
        elseif Config.BorderGlow then
            TweenService:Create(MainStroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Transparency = 0.08
            }):Play()
            task.wait(2)
            if not rgbEnabled then
                TweenService:Create(MainStroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Transparency = 0.45
                }):Play()
            end
            task.wait(2)
        else
            task.wait(1)
        end
        task.wait(0.03)
    end
end)

-- ================================================
-- KEYBINDS
-- ================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Config.ToggleKey then
        -- Toggle UI
        MinBtn.MouseButton1Click:Fire()
    elseif input.KeyCode == Config.FarmKey then
        -- Toggle farm
        Flags.AutoFarm = not Flags.AutoFarm
        if Flags.AutoFarm then StartFarm() end
        ShowNotification("Keybind", "Auto Farm: " .. (Flags.AutoFarm and "ON" or "OFF"), 2, Icons.check, Flags.AutoFarm and C.green or C.red)
    elseif input.KeyCode == Config.ESPKey then
        -- Toggle ESP
        Flags.ESPPlayers = not Flags.ESPPlayers
        RefreshESP()
        ShowNotification("Keybind", "ESP: " .. (Flags.ESPPlayers and "ON" or "OFF"), 2, Icons.eye, Flags.ESPPlayers and C.green or C.red)
    end
end)

-- ================================================
-- BOTONES DE CONTROL
-- ================================================

-- Cerrar
CloseBtn.MouseButton1Click:Connect(function()
    PlaySound(Sounds.Click)
    SetStatus("👋 Cerrando...", C.red)
    ShowNotification("Adiós", "Cerrando Chloe X Hub", 2, Icons.x, C.red)
    
    -- Guardar config antes de cerrar
    SaveConfig()
    
    rgbEnabled = false
    local vp = workspace.CurrentCamera.ViewportSize
    
    TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0, math.floor(vp.X / 2), 0, math.floor(vp.Y / 2)),
        BackgroundTransparency = 1,
        Rotation = 45
    }):Play()
    
    TweenService:Create(Blur, TweenInfo.new(0.4), {Size = 0}):Play()
    
    task.wait(0.45)
    
    -- Limpiar
    if farmConn then farmConn:Disconnect() end
    if collectConn then collectConn:Disconnect() end
    if jumpConn then jumpConn:Disconnect() end
    if afkConn then afkConn:Disconnect() end
    CleanESP()
    
    ScreenGui:Destroy()
end)

-- Minimizar
MinBtn.MouseButton1Click:Connect(function()
    PlaySound(Sounds.Click)
    isMinimized = not isMinimized
    
    if isMinimized then
        PlaySound(Sounds.ToggleOff)
        TweenService:Create(Blur, TweenInfo.new(0.3), {Size = 0}):Play()
        
        Content.Visible = false
        Sidebar.Visible = false
        StatusBar.Visible = false
        TBarPatch.Visible = false
        TBarLine.Visible = false
        HubSub.Visible = false
        LogoContainer.Visible = false
        
        TweenService:Create(HubName, TweenInfo.new(0.12), {TextTransparency = 1}):Play()
        
        task.wait(0.14)
        
        HubName.Text = "CHLOE X"
        HubName.TextSize = 14
        HubName.Size = UDim2.new(1, -120, 1, 0)
        HubName.Position = UDim2.new(0, 14, 0, 0)
        
        local vp2 = workspace.CurrentCamera.ViewportSize
        TweenService:Create(Main, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), {
            Size = UDim2.new(0, 260, 0, 48),
            Position = UDim2.new(0, math.floor(vp2.X / 2 - 130), 0, 16)
        }):Play()
        
        TweenService:Create(TBar, TweenInfo.new(0.28), {
            BackgroundColor3 = Color3.fromRGB(5, 7, 16)
        }):Play()
        
        TweenService:Create(HubName, TweenInfo.new(0.22), {TextTransparency = 0}):Play()
        
        -- Animación de pulso mientras está minimizado
        task.spawn(function()
            while isMinimized and Main.Parent do
                TweenService:Create(MainStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Transparency = 0
                }):Play()
                task.wait(1.2)
                TweenService:Create(MainStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Transparency = 0.6
                }):Play()
                task.wait(1.2)
            end
        end)
    else
        PlaySound(Sounds.ToggleOn)
        TweenService:Create(HubName, TweenInfo.new(0.12), {TextTransparency = 1}):Play()
        
        task.wait(0.14)
        
        HubName.Text = "CHLOE X Hub"
        HubName.TextSize = 16
        HubName.Size = UDim2.new(0, 200, 0, 24)
        HubName.Position = UDim2.new(0, 58, 0.5, -22)
        
        TweenService:Create(TBar, TweenInfo.new(0.28), {
            BackgroundColor3 = Color3.fromRGB(7, 9, 18)
        }):Play()
        
        local vp3 = workspace.CurrentCamera.ViewportSize
        TweenService:Create(Main, TweenInfo.new(0.52, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 740, 0, 490),
            Position = UDim2.new(0, math.floor(vp3.X / 2 - 370), 0, math.floor(vp3.Y / 2 - 245))
        }):Play()
        
        TweenService:Create(HubName, TweenInfo.new(0.28), {TextTransparency = 0}):Play()
        TweenService:Create(Blur, TweenInfo.new(0.42), {Size = Config.BlurStrength}):Play()
        
        task.wait(0.56)
        
        LogoContainer.Visible = true
        HubSub.Visible = true
        TBarPatch.Visible = true
        TBarLine.Visible = true
        Content.Visible = true
        Sidebar.Visible = true
        StatusBar.Visible = true
        MainStroke.Transparency = 0.3
        
        SetStatus("📂 Restaurado", C.green)
        ShowNotification("Bienvenido de nuevo", "Hub restaurado", 2, Icons.check, C.green)
    end
end)

-- ================================================
-- DRAG & DROP
-- ================================================
local function StartDrag(pos)
    isDragging = true
    dragOffsetX = Main.AbsolutePosition.X - pos.X
    dragOffsetY = Main.AbsolutePosition.Y - pos.Y
    TweenService:Create(MainStroke, TweenInfo.new(0.12), {
        Thickness = 2.2,
        Transparency = 0
    }):Play()
end

local function StopDrag()
    isDragging = false
    TweenService:Create(MainStroke, TweenInfo.new(0.24), {
        Thickness = 1.8,
        Transparency = 0.3
    }):Play()
end

local function MoveDrag(pos)
    if not isDragging then return end
    local vp = workspace.CurrentCamera.ViewportSize
    Main.Position = UDim2.new(0,
        math.clamp(pos.X + dragOffsetX, -Main.AbsoluteSize.X + 80, vp.X - 80), 0,
        math.clamp(pos.Y + dragOffsetY, 0, vp.Y - Main.AbsoluteSize.Y + 50))
end

TBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        StartDrag(inp.Position)
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then
                StopDrag()
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
        MoveDrag(inp.Position)
    end
end)

-- ================================================
-- INIT
-- ================================================
SwitchTab("home")

-- Cargar configuración guardada y aplicar flags
task.spawn(function()
    task.wait(1)
    
    -- Aplicar flags cargados
    if Flags.AutoFarm then StartFarm() end
    if Flags.AutoCollect then StartCollect() end
    if Flags.AntiAFK then StartAntiAFK() end
    if Flags.InfJump then StartInfJump() end
    if Flags.SpeedHack then ApplySpeed(true) end
    if Flags.ESPPlayers then RefreshESP() end
    if Flags.ESPNpcs then RefreshNPCESP(true) end
end)

print("✅ CHLOE X Hub v5.0 - Ultra Edition Loaded!")
print("🎨 Modern Icons | 💾 Auto Save | 🔑 Keybinds")
print("⚡ Advanced Animations | 🎯 50+ Features")

-- Final message
ShowNotification(
    "🎉 ¡Todo listo!",
    "Chloe X Hub v5.0 cargado completamente.\nPresiona " .. Config.ToggleKey.Name .. " para minimizar/maximizar",
    5,
    Icons.check,
    C.green
)
