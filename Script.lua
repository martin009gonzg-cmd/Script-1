-- ╔══════════════════════════════════════════════════╗
--   CHLOE X  ✦  v6.0  ✦  Ultimate Redesign
--   • Sistema de KEY interno
--   • Partículas de nieve / copos flotantes
--   • Fondo animado con gradiente
--   • Minimizado como píldora elegante
--   • Diseño tipo NHT X Hub (sidebar icon-only)
--   • Aimbot para juegos de disparos
--   • Animaciones de entrada cinemáticas
--   • RGB + Save Config + Sliders arreglados
-- ╚══════════════════════════════════════════════════╝

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local LocalPlayer      = Players.LocalPlayer

-- Limpiar UI previa
pcall(function()
    for _, name in ipairs({"ChloeXHub"}) do
        local g = game:GetService("CoreGui"):FindFirstChild(name)
        if g then g:Destroy() end
        local p = LocalPlayer.PlayerGui:FindFirstChild(name)
        if p then p:Destroy() end
    end
end)

-- ══════════════════════════════════════════════════
-- CONSTANTES DE ESTILO (Inspirado en NHT X Hub)
-- ══════════════════════════════════════════════════
local VALID_KEY  = "CHLOEX-2025"
local WIN_W      = 620
local WIN_H      = 430
local SIDEBAR_W  = 180   -- sidebar más ancho con texto (NHT style)
local TOPBAR_H   = 48
local BOTBAR_H   = 24

local COL = {
    bg         = Color3.fromRGB(12, 14, 22),
    bgPanel    = Color3.fromRGB(18, 20, 32),
    sidebar    = Color3.fromRGB(14, 16, 26),
    titleBar   = Color3.fromRGB(10, 12, 20),
    accent     = Color3.fromRGB(0, 200, 255),
    accentDim  = Color3.fromRGB(0, 120, 180),
    white      = Color3.fromRGB(240, 245, 255),
    dim        = Color3.fromRGB(110, 125, 155),
    dimmer     = Color3.fromRGB(60, 70, 95),
    green      = Color3.fromRGB(70, 230, 130),
    red        = Color3.fromRGB(255, 75, 90),
    yellow     = Color3.fromRGB(255, 210, 50),
    dark       = Color3.fromRGB(8, 10, 16),
}

-- ══════════════════════════════════════════════════
-- FLAGS / CONFIG
-- ══════════════════════════════════════════════════
local Flags = {
    AutoFarm=false, AutoCollect=false, AntiAFK=false,
    InfJump=false,  SpeedHack=false,   ESPPlayers=false,
    ESPNpcs=false,  Aimbot=false,
}
local Config = {
    AccentR=0, AccentG=200, AccentB=255,
    UITransp=0, BlurStrength=8, BorderGlow=true,
    AnimSpeed=0.3, RGBEnabled=false, RGBSpeed=0.5,
    CornerRadius=12, FarmDist=100, SpeedVal=50,
    CollectRad=30, OrigSpeed=16, ESPFillTransp=0.5,
    AimbotFOV=80, AimbotSmooth=0.15, AimbotTeam=false,
    AimbotPart="Head",
}
local SavedConfig = {}
local function LoadConfig()
    pcall(function()
        if readfile and isfile and isfile("ChloeX_v6.json") then
            local d = game:GetService("HttpService"):JSONDecode(readfile("ChloeX_v6.json"))
            for k,v in pairs(d) do SavedConfig[k]=v end
        end
    end)
end
local function SaveConfig()
    pcall(function()
        if writefile then
            local d = {}
            for k,v in pairs(Config) do d[k]=v end
            writefile("ChloeX_v6.json", game:GetService("HttpService"):JSONEncode(d))
        end
    end)
end
LoadConfig()
for k,v in pairs(SavedConfig) do Config[k]=v end

local ESPList = {}
local farmConn,collectConn,jumpConn,afkConn,rgbConn,aimbotConn
local isMinimized = false
local isDragging  = false
local dragStart, startPos
local currentAccent = Color3.fromRGB(Config.AccentR, Config.AccentG, Config.AccentB)
local keyUnlocked   = false

-- ══════════════════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════════════════
local function GetChar() return LocalPlayer.Character end
local function GetRoot() local c=GetChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum()  local c=GetChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function T(obj, dur, props, style, dir)
    return TweenService:Create(obj, TweenInfo.new(dur or 0.3, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
end

-- ══════════════════════════════════════════════════
-- LÓGICA DE SCRIPT
-- ══════════════════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait(1)
    if Flags.SpeedHack then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = Config.SpeedVal end
    end
end)

local function StartFarm()
    if farmConn then farmConn:Disconnect() end
    farmConn = RunService.Heartbeat:Connect(function()
        if not Flags.AutoFarm then farmConn:Disconnect() return end
        local root,hum = GetRoot(),GetHum()
        if not root or not hum or hum.Health<=0 then return end
        local nearest,nearDist = nil, Config.FarmDist
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj~=GetChar() then
                local h=obj:FindFirstChildOfClass("Humanoid")
                local r=obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
                if h and h.Health>0 and r then
                    local d=(root.Position-r.Position).Magnitude
                    if d<nearDist then nearest=obj; nearDist=d end
                end
            end
        end
        if nearest then
            local r=nearest:FindFirstChild("HumanoidRootPart") or nearest:FindFirstChild("Torso")
            if r then
                root.CFrame = CFrame.new(r.Position+Vector3.new(0,2,3))
                local tool=GetChar():FindFirstChildOfClass("Tool")
                if tool then pcall(function() tool:Activate() end) end
            end
        end
    end)
end

local function StartCollect()
    if collectConn then collectConn:Disconnect() end
    collectConn = RunService.Heartbeat:Connect(function()
        if not Flags.AutoCollect then collectConn:Disconnect() return end
        local root=GetRoot()
        if not root then return end
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj.Anchored then
                local par=obj.Parent
                if par and not par:FindFirstChildOfClass("Humanoid") then
                    if (root.Position-obj.Position).Magnitude<=Config.CollectRad then
                        pcall(function() root.CFrame=CFrame.new(obj.Position+Vector3.new(0,2,0)) end)
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
        local h=GetHum()
        if h and h.Health>0 then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end

local function ApplySpeed(on)
    local h=GetHum()
    if not h then return end
    if on then Config.OrigSpeed=h.WalkSpeed; h.WalkSpeed=Config.SpeedVal
    else h.WalkSpeed=Config.OrigSpeed end
end

local function StartAntiAFK()
    if afkConn then afkConn:Disconnect() end
    local vu=game:GetService("VirtualUser")
    afkConn = LocalPlayer.Idled:Connect(function()
        if not Flags.AntiAFK then afkConn:Disconnect() return end
        vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        task.wait(0.5)
        vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    end)
end

local function CleanESP()
    for _,v in pairs(ESPList) do pcall(function() v:Destroy() end) end
    ESPList={}
end

local function RefreshESP()
    CleanESP()
    if not Flags.ESPPlayers then return end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then
            local function addHL(char)
                if not char then return end
                task.wait(0.3)
                local hl=Instance.new("Highlight")
                hl.FillColor=currentAccent; hl.OutlineColor=Color3.new(1,1,1)
                hl.FillTransparency=Config.ESPFillTransp; hl.OutlineTransparency=0
                hl.Parent=char
                table.insert(ESPList,hl)
            end
            pcall(function() addHL(p.Character) end)
            p.CharacterAdded:Connect(function(c) if Flags.ESPPlayers then pcall(function() addHL(c) end) end end)
        end
    end
end

local function RefreshNPCESP(on)
    for _,v in pairs(ESPList) do if v and v.Name=="NPCESP" then pcall(function() v:Destroy() end) end end
    if not on then return end
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj~=GetChar() then
            if obj:FindFirstChildOfClass("Humanoid") then
                pcall(function()
                    local hl=Instance.new("Highlight")
                    hl.Name="NPCESP"
                    hl.FillColor=Color3.fromRGB(255,60,60); hl.OutlineColor=Color3.fromRGB(255,180,180)
                    hl.FillTransparency=Config.ESPFillTransp; hl.OutlineTransparency=0
                    hl.Parent=obj
                    table.insert(ESPList,hl)
                end)
            end
        end
    end
end

-- ── AIMBOT ──────────────────────────────────────
local aimbotCircle
local function GetAimbotTarget()
    local cam = workspace.CurrentCamera
    local bestDist, bestPart = Config.AimbotFOV, nil
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then
            if Config.AimbotTeam and p.Team==LocalPlayer.Team then continue end
            local char=p.Character
            if not char then continue end
            local part=char:FindFirstChild(Config.AimbotPart) or char:FindFirstChild("HumanoidRootPart")
            local hum=char:FindFirstChildOfClass("Humanoid")
            if not part or not hum or hum.Health<=0 then continue end
            local pos,visible=cam:WorldToViewportPoint(part.Position)
            if visible then
                local center=Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
                local dist=(Vector2.new(pos.X,pos.Y)-center).Magnitude
                if dist<bestDist then bestDist=dist; bestPart=part end
            end
        end
    end
    return bestPart
end

local function StartAimbot()
    if aimbotConn then aimbotConn:Disconnect() end
    aimbotConn = RunService.RenderStepped:Connect(function()
        if not Flags.Aimbot then aimbotConn:Disconnect() return end
        if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
        local target=GetAimbotTarget()
        if not target then return end
        local cam=workspace.CurrentCamera
        local pos=cam:WorldToViewportPoint(target.Position)
        local center=Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
        local targetVec=Vector2.new(pos.X,pos.Y)
        local smooth=Config.AimbotSmooth
        -- Smooth aim
        pcall(function()
            local newX=center.X+(targetVec.X-center.X)*smooth
            local newY=center.Y+(targetVec.Y-center.Y)*smooth
            mousemoverel(newX-center.X, newY-center.Y)
        end)
    end)
end

local function StartRGB()
    if rgbConn then rgbConn:Disconnect() end
    local hue=0
    rgbConn = RunService.RenderStepped:Connect(function()
        if not Config.RGBEnabled then rgbConn:Disconnect() return end
        hue=(hue+Config.RGBSpeed*0.004)%1
        currentAccent=Color3.fromHSV(hue,1,1)
    end)
end

-- ══════════════════════════════════════════════════
-- CREAR SCREENGUI
-- ══════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ChloeXHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
pcall(function() syn.protect_gui(ScreenGui) end)
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if ScreenGui.Parent==nil then ScreenGui.Parent=LocalPlayer.PlayerGui end

-- ══════════════════════════════════════════════════
-- SISTEMA DE NOTIFICACIONES TOAST
-- ══════════════════════════════════════════════════
local ToastContainer = Instance.new("Frame")
ToastContainer.Size = UDim2.new(0,300,1,0)
ToastContainer.Position = UDim2.new(1,-310,0,0)
ToastContainer.BackgroundTransparency = 1
ToastContainer.Parent = ScreenGui
local TL = Instance.new("UIListLayout")
TL.VerticalAlignment = Enum.VerticalAlignment.Bottom
TL.Padding = UDim.new(0,6)
TL.Parent = ToastContainer
local TP = Instance.new("UIPadding")
TP.PaddingBottom = UDim.new(0,20)
TP.Parent = ToastContainer

local function Toast(text, color, icon)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,52)
    f.BackgroundColor3 = COL.bgPanel
    f.BackgroundTransparency = 0.1
    f.BorderSizePixel = 0
    f.LayoutOrder = -os.clock()
    f.Parent = ToastContainer
    local fc = Instance.new("UICorner"); fc.CornerRadius=UDim.new(0,10); fc.Parent=f
    local bar = Instance.new("Frame"); bar.Size=UDim2.new(0,4,0.7,0); bar.Position=UDim2.new(0,0,0.15,0)
    bar.BackgroundColor3=color or COL.green; bar.BorderSizePixel=0; bar.Parent=f
    local bc = Instance.new("UICorner"); bc.CornerRadius=UDim.new(1,0); bc.Parent=bar
    local il = Instance.new("TextLabel"); il.Size=UDim2.new(0,30,1,0); il.Position=UDim2.new(0,10,0,0)
    il.BackgroundTransparency=1; il.Text=icon or "✦"; il.TextSize=18; il.Font=Enum.Font.Gotham; il.Parent=f
    local tl = Instance.new("TextLabel"); tl.Size=UDim2.new(1,-50,1,0); tl.Position=UDim2.new(0,44,0,0)
    tl.BackgroundTransparency=1; tl.Text=text; tl.TextColor3=COL.white; tl.TextSize=11
    tl.Font=Enum.Font.GothamBold; tl.TextXAlignment=Enum.TextXAlignment.Left; tl.TextWrapped=true; tl.Parent=f
    f.Position=UDim2.new(1,20,f.Position.Y.Scale,f.Position.Y.Offset)
    T(f,0.4,{BackgroundTransparency=0.08},Enum.EasingStyle.Back,Enum.EasingDirection.Out):Play()
    task.delay(3,function()
        T(f,0.3,{BackgroundTransparency=1,Position=UDim2.new(1,20,f.Position.Y.Scale,f.Position.Y.Offset)},Enum.EasingStyle.Quad,Enum.EasingDirection.In):Play()
        task.wait(0.35)
        pcall(function() f:Destroy() end)
    end)
end

-- ══════════════════════════════════════════════════
-- ██████  PANTALLA DE KEY  ██████
-- ══════════════════════════════════════════════════
local KeyScreen = Instance.new("Frame")
KeyScreen.Name = "KeyScreen"
KeyScreen.Size = UDim2.new(0, 420, 0, 280)
KeyScreen.Position = UDim2.new(0.5,-210, 0.5,-140)
KeyScreen.BackgroundColor3 = COL.bg
KeyScreen.BackgroundTransparency = 1
KeyScreen.BorderSizePixel = 0
KeyScreen.ZIndex = 50
KeyScreen.Parent = ScreenGui

local KSCorner = Instance.new("UICorner"); KSCorner.CornerRadius=UDim.new(0,16); KSCorner.Parent=KeyScreen
local KSStroke = Instance.new("UIStroke"); KSStroke.Color=COL.accent; KSStroke.Thickness=1.5
KSStroke.Transparency=0.4; KSStroke.Parent=KeyScreen

-- Fondo gradiente del key screen
local KSGrad = Instance.new("Frame")
KSGrad.Size=UDim2.new(1,0,1,0); KSGrad.BackgroundColor3=COL.bg; KSGrad.BorderSizePixel=0; KSGrad.ZIndex=50; KSGrad.Parent=KeyScreen
local KSGc = Instance.new("UICorner"); KSGc.CornerRadius=UDim.new(0,16); KSGc.Parent=KSGrad
local KSGg = Instance.new("UIGradient")
KSGg.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(8,12,28)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12,18,35))
})
KSGg.Rotation=135; KSGg.Parent=KSGrad

-- Logo del key
local KSLogo = Instance.new("TextLabel")
KSLogo.Size=UDim2.new(1,0,0,50); KSLogo.Position=UDim2.new(0,0,0,20)
KSLogo.BackgroundTransparency=1; KSLogo.Text="✦ CHLOE X ✦"
KSLogo.TextColor3=COL.accent; KSLogo.TextSize=24; KSLogo.Font=Enum.Font.GothamBold
KSLogo.TextTransparency=0; KSLogo.ZIndex=52; KSLogo.Parent=KeyScreen

local KSSub = Instance.new("TextLabel")
KSSub.Size=UDim2.new(1,0,0,20); KSSub.Position=UDim2.new(0,0,0,62)
KSSub.BackgroundTransparency=1; KSSub.Text="Introduce tu key para continuar"
KSSub.TextColor3=COL.dim; KSSub.TextSize=12; KSSub.Font=Enum.Font.Gotham
KSSub.ZIndex=52; KSSub.Parent=KeyScreen

-- Campo de texto del key
local KSBox = Instance.new("Frame")
KSBox.Size=UDim2.new(1,-60,0,42); KSBox.Position=UDim2.new(0,30,0,100)
KSBox.BackgroundColor3=COL.dark; KSBox.BorderSizePixel=0; KSBox.ZIndex=52; KSBox.Parent=KeyScreen
local KSBc = Instance.new("UICorner"); KSBc.CornerRadius=UDim.new(0,10); KSBc.Parent=KSBox
local KSBs = Instance.new("UIStroke"); KSBs.Color=COL.dimmer; KSBs.Thickness=1; KSBs.Parent=KSBox

local KSInput = Instance.new("TextBox")
KSInput.Size=UDim2.new(1,-20,1,0); KSInput.Position=UDim2.new(0,10,0,0)
KSInput.BackgroundTransparency=1; KSInput.PlaceholderText="Pega tu key aquí..."
KSInput.PlaceholderColor3=COL.dimmer; KSInput.Text=""; KSInput.TextColor3=COL.white
KSInput.TextSize=13; KSInput.Font=Enum.Font.GothamBold; KSInput.ClearTextOnFocus=false
KSInput.ZIndex=53; KSInput.Parent=KSBox

-- Botón verificar
local KSBtn = Instance.new("TextButton")
KSBtn.Size=UDim2.new(1,-60,0,42); KSBtn.Position=UDim2.new(0,30,0,155)
KSBtn.BackgroundColor3=COL.accent; KSBtn.BorderSizePixel=0; KSBtn.Text="🔑  VERIFICAR KEY"
KSBtn.TextColor3=COL.dark; KSBtn.TextSize=14; KSBtn.Font=Enum.Font.GothamBold
KSBtn.ZIndex=52; KSBtn.Parent=KeyScreen
local KSBc2 = Instance.new("UICorner"); KSBc2.CornerRadius=UDim.new(0,10); KSBc2.Parent=KSBtn

KSBtn.MouseEnter:Connect(function() T(KSBtn,0.15,{BackgroundTransparency=0.2}):Play() end)
KSBtn.MouseLeave:Connect(function() T(KSBtn,0.15,{BackgroundTransparency=0}):Play() end)

local KSErr = Instance.new("TextLabel")
KSErr.Size=UDim2.new(1,0,0,20); KSErr.Position=UDim2.new(0,0,0,208)
KSErr.BackgroundTransparency=1; KSErr.Text=""; KSErr.TextColor3=COL.red
KSErr.TextSize=11; KSErr.Font=Enum.Font.Gotham; KSErr.ZIndex=52; KSErr.Parent=KeyScreen

local KSHint = Instance.new("TextLabel")
KSHint.Size=UDim2.new(1,0,0,20); KSHint.Position=UDim2.new(0,0,0,235)
KSHint.BackgroundTransparency=1; KSHint.Text="Key: CHLOEX-2025"
KSHint.TextColor3=COL.dimmer; KSHint.TextSize=10; KSHint.Font=Enum.Font.Gotham; KSHint.ZIndex=52; KSHint.Parent=KeyScreen

-- Animación de entrada del key screen
KeyScreen.Size = UDim2.new(0,0,0,0)
KeyScreen.Position = UDim2.new(0.5,0,0.5,0)
KeyScreen.BackgroundTransparency=1
T(KeyScreen,0.6,{Size=UDim2.new(0,420,0,280),Position=UDim2.new(0.5,-210,0.5,-140),BackgroundTransparency=0},Enum.EasingStyle.Back,Enum.EasingDirection.Out):Play()

-- Partículas de nieve en el key screen
for i=1,15 do
    local snow = Instance.new("TextLabel")
    snow.Size=UDim2.new(0,14,0,14); snow.BackgroundTransparency=1
    snow.Text=math.random(1,2)==1 and "❄" or "✦"
    snow.TextColor3=COL.accent; snow.TextSize=math.random(8,14)
    snow.Font=Enum.Font.Gotham
    snow.Position=UDim2.new(math.random(0,100)/100,0, -0.1,0)
    snow.ZIndex=51; snow.Parent=KeyScreen
    task.spawn(function()
        while KeyScreen.Parent do
            local startX=math.random(0,100)/100
            snow.Position=UDim2.new(startX,0,-0.15,0)
            snow.TextTransparency=math.random(30,70)/100
            T(snow, math.random(4,8), {
                Position=UDim2.new(startX+math.random(-10,10)/100, 0, 1.1, 0),
                TextTransparency=1
            }, Enum.EasingStyle.Linear):Play()
            task.wait(math.random(3,7))
        end
    end)
end

-- ══════════════════════════════════════════════════
-- VENTANA PRINCIPAL (oculta hasta que el key sea correcto)
-- ══════════════════════════════════════════════════
local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.Size = UDim2.new(0,WIN_W,0,WIN_H)
Main.Position = UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)
Main.BackgroundColor3 = COL.bg
Main.BackgroundTransparency = 1
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Active = true
Main.Visible = false
Main.ZIndex = 10
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner"); MainCorner.CornerRadius=UDim.new(0,14); MainCorner.Parent=Main
local MainStroke = Instance.new("UIStroke"); MainStroke.Color=currentAccent; MainStroke.Thickness=1.5
MainStroke.Transparency=0.35; MainStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; MainStroke.Parent=Main

-- Sombra exterior
local Sombra = Instance.new("Frame")
Sombra.Size=UDim2.new(1,24,1,24); Sombra.Position=UDim2.new(0,-12,0,8)
Sombra.BackgroundColor3=Color3.fromRGB(0,0,0); Sombra.BackgroundTransparency=0.65
Sombra.BorderSizePixel=0; Sombra.ZIndex=Main.ZIndex-1; Sombra.Parent=Main
local SC=Instance.new("UICorner"); SC.CornerRadius=UDim.new(0,18); SC.Parent=Sombra

-- ── FONDO ANIMADO con gradiente en movimiento ──────
local BgGrad = Instance.new("Frame")
BgGrad.Size=UDim2.new(1,0,1,0); BgGrad.BackgroundColor3=COL.bg
BgGrad.BorderSizePixel=0; BgGrad.ZIndex=10; BgGrad.Parent=Main
local BgGc=Instance.new("UICorner"); BgGc.CornerRadius=UDim.new(0,14); BgGc.Parent=BgGrad
local BgGg=Instance.new("UIGradient")
BgGg.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(8,10,20)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(12,16,30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(6,8,18))
})
BgGg.Rotation=45; BgGg.Parent=BgGrad

-- Rotar el gradiente suavemente
task.spawn(function()
    local rot=45
    while Main.Parent do
        rot=(rot+0.15)%360
        BgGg.Rotation=rot
        task.wait(0.04)
    end
end)

-- ── PARTÍCULAS DE NIEVE FLOTANTES en el main frame ─
local SnowContainer = Instance.new("Frame")
SnowContainer.Size=UDim2.new(1,0,1,0); SnowContainer.BackgroundTransparency=1
SnowContainer.ZIndex=11; SnowContainer.ClipsDescendants=false; SnowContainer.Parent=Main

for i=1,25 do
    local snow=Instance.new("TextLabel")
    snow.Size=UDim2.new(0,12,0,12); snow.BackgroundTransparency=1
    snow.Text=({" ❄ "," ✦ "," · "," ❅ "})[math.random(1,4)]
    snow.TextColor3=Color3.fromRGB(180,220,255)
    snow.TextSize=math.random(7,13)
    snow.Font=Enum.Font.Gotham
    snow.ZIndex=11; snow.Parent=SnowContainer
    task.spawn(function()
        while Main.Parent do
            local startX=math.random(0,100)/100
            local dur=math.random(6,14)
            snow.Position=UDim2.new(startX,0,-0.05,0)
            snow.TextTransparency=math.random(40,80)/100
            T(snow, dur, {
                Position=UDim2.new(startX+math.random(-8,8)/100,0,1.05,0),
                TextTransparency=0.95
            }, Enum.EasingStyle.Linear):Play()
            task.wait(dur+math.random(0,4))
        end
    end)
end

-- Blur
local Blur=Instance.new("BlurEffect"); Blur.Size=0; Blur.Parent=Lighting
T(Blur,0.7,{Size=Config.BlurStrength}):Play()

-- Glow del borde pulsante
local glowEnabled=true
task.spawn(function()
    while Main.Parent and glowEnabled do
        if Config.BorderGlow and not Config.RGBEnabled then
            T(MainStroke,2,{Transparency=0.05},Enum.EasingStyle.Sine):Play()
            task.wait(2)
            if Config.BorderGlow then T(MainStroke,2,{Transparency=0.5},Enum.EasingStyle.Sine):Play() end
            task.wait(2)
        else task.wait(0.5) end
    end
end)

-- ── TOP BAR ─────────────────────────────────────
local TBar=Instance.new("Frame")
TBar.Name="TitleBar"; TBar.Size=UDim2.new(1,0,0,TOPBAR_H)
TBar.BackgroundColor3=COL.titleBar; TBar.BackgroundTransparency=0
TBar.BorderSizePixel=0; TBar.ZIndex=15; TBar.Parent=Main
local TBC=Instance.new("UICorner"); TBC.CornerRadius=UDim.new(0,14); TBC.Parent=TBar
local TBM=Instance.new("Frame"); TBM.Size=UDim2.new(1,0,0,14); TBM.Position=UDim2.new(0,0,1,-14)
TBM.BackgroundColor3=COL.titleBar; TBM.BackgroundTransparency=0; TBM.BorderSizePixel=0; TBM.ZIndex=15; TBM.Parent=TBar
local TBGg=Instance.new("UIGradient"); TBGg.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,COL.titleBar),
    ColorSequenceKeypoint.new(1,COL.bgPanel)
}); TBGg.Rotation=90; TBGg.Parent=TBar

-- Icono / logo
local LogoIcon=Instance.new("TextLabel")
LogoIcon.Size=UDim2.new(0,32,0,32); LogoIcon.Position=UDim2.new(0,10,0.5,-16)
LogoIcon.BackgroundColor3=COL.accent; LogoIcon.BorderSizePixel=0
LogoIcon.Text="✦"; LogoIcon.TextColor3=COL.dark; LogoIcon.TextSize=16; LogoIcon.Font=Enum.Font.GothamBold
LogoIcon.TextTransparency=0; LogoIcon.ZIndex=16; LogoIcon.Parent=TBar
local LIC=Instance.new("UICorner"); LIC.CornerRadius=UDim.new(0,8); LIC.Parent=LogoIcon

local Logo=Instance.new("TextLabel")
Logo.Size=UDim2.new(0,120,1,0); Logo.Position=UDim2.new(0,48,0,0)
Logo.BackgroundTransparency=1; Logo.Text="CHLOE X"
Logo.TextColor3=COL.white; Logo.TextSize=15; Logo.Font=Enum.Font.GothamBold
Logo.TextXAlignment=Enum.TextXAlignment.Left; Logo.TextTransparency=1
Logo.ZIndex=16; Logo.Parent=TBar

local VerLabel=Instance.new("TextLabel")
VerLabel.Size=UDim2.new(0,60,1,0); VerLabel.Position=UDim2.new(0,48,0,14)
VerLabel.BackgroundTransparency=1; VerLabel.Text="v6.0"
VerLabel.TextColor3=COL.dim; VerLabel.TextSize=10; VerLabel.Font=Enum.Font.Gotham
VerLabel.TextXAlignment=Enum.TextXAlignment.Left; VerLabel.TextTransparency=1
VerLabel.ZIndex=16; VerLabel.Parent=TBar

-- Punto activo pulsante
local ADot=Instance.new("Frame"); ADot.Size=UDim2.new(0,7,0,7); ADot.Position=UDim2.new(0,170,0.5,-3.5)
ADot.BackgroundColor3=COL.green; ADot.BorderSizePixel=0; ADot.ZIndex=16; ADot.Parent=TBar
local ADOTC=Instance.new("UICorner"); ADOTC.CornerRadius=UDim.new(1,0); ADOTC.Parent=ADot
task.spawn(function()
    while Main.Parent do
        T(ADot,0.9,{BackgroundTransparency=0.85,Size=UDim2.new(0,5,0,5),Position=UDim2.new(0,171,0.5,-2.5)},Enum.EasingStyle.Sine):Play()
        task.wait(0.9)
        T(ADot,0.9,{BackgroundTransparency=0,Size=UDim2.new(0,7,0,7),Position=UDim2.new(0,170,0.5,-3.5)},Enum.EasingStyle.Sine):Play()
        task.wait(0.9)
    end
end)

-- Botones de control
local function MakeCtrlBtn(sym, posX, col)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,26,0,26); b.Position=UDim2.new(1,posX,0.5,-13)
    b.BackgroundColor3=col; b.BackgroundTransparency=0.5; b.BorderSizePixel=0
    b.Text=sym; b.TextColor3=COL.white; b.TextSize=14; b.Font=Enum.Font.GothamBold
    b.ZIndex=17; b.Parent=TBar
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=b
    local s=Instance.new("UIStroke"); s.Color=col; s.Thickness=1; s.Transparency=0.5; s.Parent=b
    b.MouseEnter:Connect(function() T(b,0.12,{BackgroundTransparency=0,Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,posX-1,0.5,-14)}):Play(); T(s,0.12,{Transparency=0}):Play() end)
    b.MouseLeave:Connect(function() T(b,0.15,{BackgroundTransparency=0.5,Size=UDim2.new(0,26,0,26),Position=UDim2.new(1,posX,0.5,-13)}):Play(); T(s,0.12,{Transparency=0.5}):Play() end)
    return b
end
local CloseBtn  = MakeCtrlBtn("×", -36, COL.red)
local MinBtn    = MakeCtrlBtn("—", -70, COL.yellow)
local CenterBtn = MakeCtrlBtn("⊞", -104, COL.green)

-- Status label en titlebar
local TBStatus=Instance.new("TextLabel")
TBStatus.Size=UDim2.new(1,-320,1,0); TBStatus.Position=UDim2.new(0,190,0,0)
TBStatus.BackgroundTransparency=1; TBStatus.Text="● Ready"
TBStatus.TextColor3=COL.green; TBStatus.TextSize=10; TBStatus.Font=Enum.Font.Gotham
TBStatus.TextXAlignment=Enum.TextXAlignment.Left; TBStatus.ZIndex=16; TBStatus.Parent=TBar

-- Reloj
local ClockLbl=Instance.new("TextLabel")
ClockLbl.Size=UDim2.new(0,90,1,0); ClockLbl.Position=UDim2.new(1,-165,0,0)
ClockLbl.BackgroundTransparency=1; ClockLbl.TextColor3=COL.dimmer
ClockLbl.TextSize=9; ClockLbl.Font=Enum.Font.Gotham; ClockLbl.ZIndex=16; ClockLbl.Parent=TBar
task.spawn(function()
    while Main.Parent do
        local t=os.date("*t")
        ClockLbl.Text=string.format("%02d:%02d:%02d",t.hour,t.min,t.sec)
        task.wait(1)
    end
end)

local function SetStatus(text,col)
    local c=col or currentAccent
    T(TBStatus,0.1,{TextTransparency=1}):Play(); task.wait(0.11)
    TBStatus.Text=text; TBStatus.TextColor3=c
    T(TBStatus,0.2,{TextTransparency=0},Enum.EasingStyle.Back):Play()
end

-- ── SIDEBAR (NHT-style: icono + texto) ───────────
local Sidebar=Instance.new("Frame")
Sidebar.Name="Sidebar"; Sidebar.Size=UDim2.new(0,SIDEBAR_W,1,-TOPBAR_H-BOTBAR_H)
Sidebar.Position=UDim2.new(0,0,0,TOPBAR_H)
Sidebar.BackgroundColor3=COL.sidebar; Sidebar.BackgroundTransparency=0
Sidebar.BorderSizePixel=0; Sidebar.ZIndex=14; Sidebar.Parent=Main

-- Separador
local SBDiv=Instance.new("Frame"); SBDiv.Size=UDim2.new(0,1,1,0); SBDiv.Position=UDim2.new(1,0,0,0)
SBDiv.BackgroundColor3=currentAccent; SBDiv.BackgroundTransparency=0.75; SBDiv.BorderSizePixel=0
SBDiv.ZIndex=14; SBDiv.Parent=Sidebar

-- Gradiente del sidebar
local SBGg=Instance.new("UIGradient"); SBGg.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,COL.sidebar),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(10,12,20))
}); SBGg.Rotation=180; SBGg.Parent=Sidebar

-- Content area
local Content=Instance.new("Frame")
Content.Name="Content"; Content.Size=UDim2.new(1,-SIDEBAR_W,1,-TOPBAR_H-BOTBAR_H)
Content.Position=UDim2.new(0,SIDEBAR_W,0,TOPBAR_H)
Content.BackgroundTransparency=1; Content.BorderSizePixel=0
Content.ClipsDescendants=true; Content.ZIndex=13; Content.Parent=Main

-- Bottom bar
local BotBar=Instance.new("Frame"); BotBar.Name="BotBar"
BotBar.Size=UDim2.new(1,0,0,BOTBAR_H); BotBar.Position=UDim2.new(0,0,1,-BOTBAR_H)
BotBar.BackgroundColor3=COL.titleBar; BotBar.BackgroundTransparency=0; BotBar.BorderSizePixel=0
BotBar.ZIndex=15; BotBar.Parent=Main
local BBC=Instance.new("UICorner"); BBC.CornerRadius=UDim.new(0,14); BBC.Parent=BotBar
local BBM=Instance.new("Frame"); BBM.Size=UDim2.new(1,0,0,14); BBM.Position=UDim2.new(0,0,0,0)
BBM.BackgroundColor3=COL.titleBar; BBM.BackgroundTransparency=0; BBM.BorderSizePixel=0; BBM.ZIndex=15; BBM.Parent=BotBar

local BBLabel=Instance.new("TextLabel"); BBLabel.Size=UDim2.new(1,-20,1,0); BBLabel.Position=UDim2.new(0,10,0,0)
BBLabel.BackgroundTransparency=1; BBLabel.Text="🟢 Chloe X v6.0 — Todos los sistemas listos"
BBLabel.TextColor3=COL.green; BBLabel.TextSize=10; BBLabel.Font=Enum.Font.Gotham
BBLabel.TextXAlignment=Enum.TextXAlignment.Left; BBLabel.ZIndex=16; BBLabel.Parent=BotBar

-- ══════════════════════════════════════════════════
-- SISTEMA DE TABS  (NHT X Hub style)
-- ══════════════════════════════════════════════════
local currentTab=nil; local tabBtns={}; local tabPanels={}

local function CreateTabBtn(id, icon, label, order)
    local btn=Instance.new("TextButton")
    btn.Name=id.."Btn"; btn.Size=UDim2.new(1,0,0,48)
    btn.Position=UDim2.new(0,0,0,(order-1)*48)
    btn.BackgroundColor3=COL.sidebar; btn.BackgroundTransparency=1
    btn.BorderSizePixel=0; btn.Text=""; btn.ZIndex=15; btn.Parent=Sidebar

    -- Hover BG
    local hBG=Instance.new("Frame"); hBG.Size=UDim2.new(1,-8,1,-4); hBG.Position=UDim2.new(0,4,0,2)
    hBG.BackgroundColor3=currentAccent; hBG.BackgroundTransparency=1; hBG.BorderSizePixel=0; hBG.ZIndex=15; hBG.Parent=btn
    local hC=Instance.new("UICorner"); hC.CornerRadius=UDim.new(0,8); hC.Parent=hBG

    -- Indicador izquierdo (barra vertical)
    local ind=Instance.new("Frame"); ind.Name="Ind"; ind.Size=UDim2.new(0,3,0,0)
    ind.Position=UDim2.new(0,0,0.5,0); ind.AnchorPoint=Vector2.new(0,0.5)
    ind.BackgroundColor3=currentAccent; ind.BorderSizePixel=0; ind.ZIndex=16; ind.Parent=btn
    local inC=Instance.new("UICorner"); inC.CornerRadius=UDim.new(1,0); inC.Parent=ind

    -- Icono
    local ico=Instance.new("TextLabel"); ico.Size=UDim2.new(0,28,0,28); ico.Position=UDim2.new(0,16,0.5,-14)
    ico.BackgroundTransparency=1; ico.Text=icon; ico.TextColor3=COL.dim
    ico.TextSize=18; ico.Font=Enum.Font.Gotham; ico.ZIndex=17; ico.Parent=btn

    -- Texto del tab
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-54,1,0); lbl.Position=UDim2.new(0,50,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=COL.dim
    lbl.TextSize=13; lbl.Font=Enum.Font.GothamBold; lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.ZIndex=17; lbl.Parent=btn

    btn.MouseEnter:Connect(function()
        if currentTab~=id then
            T(hBG,0.15,{BackgroundTransparency=0.94}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if currentTab~=id then T(hBG,0.15,{BackgroundTransparency=1}):Play() end
    end)

    tabBtns[id]={btn=btn,ico=ico,lbl=lbl,ind=ind,hBG=hBG}
    return btn
end

local function SwitchTab(tabId)
    if currentTab and tabPanels[currentTab] then
        local old=tabPanels[currentTab]
        T(old,0.18,{BackgroundTransparency=1,Position=UDim2.new(-0.08,0,0,0)},Enum.EasingStyle.Quad,Enum.EasingDirection.In):Play()
        task.wait(0.18)
        old.Visible=false; old.Position=UDim2.new(0,0,0,0)
    end
    for id,t in pairs(tabBtns) do
        if id==tabId then
            T(t.ico,0.2,{TextColor3=currentAccent,TextSize=20}):Play()
            T(t.lbl,0.2,{TextColor3=COL.white}):Play()
            T(t.ind,0.3,{Size=UDim2.new(0,3,0,36)},Enum.EasingStyle.Back):Play()
            T(t.hBG,0.2,{BackgroundTransparency=0.88}):Play()
        else
            T(t.ico,0.2,{TextColor3=COL.dim,TextSize=18}):Play()
            T(t.lbl,0.2,{TextColor3=COL.dim}):Play()
            T(t.ind,0.15,{Size=UDim2.new(0,3,0,0)}):Play()
            T(t.hBG,0.15,{BackgroundTransparency=1}):Play()
        end
    end
    if tabPanels[tabId] then
        local p=tabPanels[tabId]; p.Visible=true
        p.Position=UDim2.new(0.06,0,0,0); p.BackgroundTransparency=1
        T(p,0.25,{Position=UDim2.new(0,0,0,0)},Enum.EasingStyle.Quad):Play()
    end
    currentTab=tabId
    SetStatus("Tab: "..tabId:upper(), currentAccent)
end

local function CreatePanel(id)
    local p=Instance.new("ScrollingFrame"); p.Name=id.."Panel"
    p.Size=UDim2.new(1,0,1,0); p.Position=UDim2.new(0,0,0,0)
    p.BackgroundTransparency=1; p.BorderSizePixel=0
    p.ScrollBarThickness=3; p.ScrollBarImageColor3=currentAccent
    p.CanvasSize=UDim2.new(0,0,0,0); p.Visible=false; p.ZIndex=14; p.Parent=Content
    local lay=Instance.new("UIListLayout"); lay.Padding=UDim.new(0,6); lay.SortOrder=Enum.SortOrder.LayoutOrder; lay.Parent=p
    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() p.CanvasSize=UDim2.new(0,0,0,lay.AbsoluteContentSize.Y+20) end)
    local pad=Instance.new("UIPadding"); pad.PaddingTop=UDim.new(0,12); pad.PaddingLeft=UDim.new(0,12)
    pad.PaddingRight=UDim.new(0,12); pad.PaddingBottom=UDim.new(0,12); pad.Parent=p
    tabPanels[id]=p
    return p
end

-- ══════════════════════════════════════════════════
-- COMPONENTES
-- ══════════════════════════════════════════════════
local function Section(par, title)
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,26); f.BackgroundTransparency=1; f.ZIndex=14; f.Parent=par
    local l=Instance.new("TextLabel"); l.Size=UDim2.new(0.6,0,1,0); l.BackgroundTransparency=1
    l.Text=title; l.TextColor3=currentAccent; l.TextSize=11; l.Font=Enum.Font.GothamBold
    l.TextXAlignment=Enum.TextXAlignment.Left; l.ZIndex=15; l.Parent=f
    local line=Instance.new("Frame"); line.Size=UDim2.new(1,0,0,1); line.Position=UDim2.new(0,0,1,-3)
    line.BackgroundColor3=currentAccent; line.BackgroundTransparency=0.7; line.BorderSizePixel=0; line.ZIndex=14; line.Parent=f
    return f
end

local function Toggle(par, title, desc, cb)
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,50); f.BackgroundColor3=COL.bgPanel
    f.BackgroundTransparency=0.35; f.BorderSizePixel=0; f.ZIndex=14; f.Parent=par
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,10); c.Parent=f
    local st=Instance.new("UIStroke"); st.Color=COL.dimmer; st.Thickness=1; st.Transparency=0.5; st.Parent=f
    local tl=Instance.new("TextLabel"); tl.Size=UDim2.new(1,-70,0,20); tl.Position=UDim2.new(0,12,0,7)
    tl.BackgroundTransparency=1; tl.Text=title; tl.TextColor3=COL.white; tl.TextSize=12; tl.Font=Enum.Font.GothamBold
    tl.TextXAlignment=Enum.TextXAlignment.Left; tl.ZIndex=15; tl.Parent=f
    local dl=Instance.new("TextLabel"); dl.Size=UDim2.new(1,-70,0,14); dl.Position=UDim2.new(0,12,0,28)
    dl.BackgroundTransparency=1; dl.Text=desc; dl.TextColor3=COL.dim; dl.TextSize=9; dl.Font=Enum.Font.Gotham
    dl.TextXAlignment=Enum.TextXAlignment.Left; dl.ZIndex=15; dl.Parent=f
    local sw=Instance.new("TextButton"); sw.Size=UDim2.new(0,46,0,24); sw.Position=UDim2.new(1,-58,0.5,-12)
    sw.BackgroundColor3=COL.dark; sw.BorderSizePixel=0; sw.Text=""; sw.ZIndex=16; sw.Parent=f
    local sc=Instance.new("UICorner"); sc.CornerRadius=UDim.new(1,0); sc.Parent=sw
    local kn=Instance.new("Frame"); kn.Size=UDim2.new(0,18,0,18); kn.Position=UDim2.new(0,3,0.5,-9)
    kn.BackgroundColor3=COL.white; kn.BorderSizePixel=0; kn.ZIndex=17; kn.Parent=sw
    local kc=Instance.new("UICorner"); kc.CornerRadius=UDim.new(1,0); kc.Parent=kn
    local state=false
    local function click()
        state=not state
        if state then
            T(sw,0.18,{BackgroundColor3=currentAccent}):Play()
            T(kn,0.3,{Position=UDim2.new(1,-21,0.5,-9)},Enum.EasingStyle.Back):Play()
            T(st,0.18,{Color=currentAccent,Transparency=0.3}):Play()
        else
            T(sw,0.18,{BackgroundColor3=COL.dark}):Play()
            T(kn,0.3,{Position=UDim2.new(0,3,0.5,-9)},Enum.EasingStyle.Back):Play()
            T(st,0.18,{Color=COL.dimmer,Transparency=0.5}):Play()
        end
        T(f,0.07,{BackgroundTransparency=0.15}):Play()
        task.wait(0.08); T(f,0.15,{BackgroundTransparency=0.35}):Play()
        pcall(function() cb(state) end)
    end
    sw.MouseButton1Click:Connect(click)
    return f
end

-- SLIDER CORREGIDO
local function Slider(par, title, min, max, def, cb)
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,60); f.BackgroundColor3=COL.bgPanel
    f.BackgroundTransparency=0.35; f.BorderSizePixel=0; f.ZIndex=14; f.Parent=par
    local fc=Instance.new("UICorner"); fc.CornerRadius=UDim.new(0,10); fc.Parent=f
    local tl=Instance.new("TextLabel"); tl.Size=UDim2.new(0.65,0,0,20); tl.Position=UDim2.new(0,12,0,7)
    tl.BackgroundTransparency=1; tl.Text=title; tl.TextColor3=COL.white; tl.TextSize=11; tl.Font=Enum.Font.GothamBold
    tl.TextXAlignment=Enum.TextXAlignment.Left; tl.ZIndex=15; tl.Parent=f
    local vl=Instance.new("TextLabel"); vl.Size=UDim2.new(0.35,-12,0,20); vl.Position=UDim2.new(0.65,0,0,7)
    vl.BackgroundTransparency=1; vl.Text=tostring(def); vl.TextColor3=currentAccent; vl.TextSize=12; vl.Font=Enum.Font.GothamBold
    vl.TextXAlignment=Enum.TextXAlignment.Right; vl.ZIndex=15; vl.Parent=f
    -- Track grande para fácil click
    local track=Instance.new("Frame"); track.Size=UDim2.new(1,-24,0,22); track.Position=UDim2.new(0,12,1,-30)
    track.BackgroundTransparency=1; track.ZIndex=15; track.Parent=f
    local bg=Instance.new("Frame"); bg.Size=UDim2.new(1,0,0,6); bg.Position=UDim2.new(0,0,0.5,-3)
    bg.BackgroundColor3=COL.dark; bg.BorderSizePixel=0; bg.ZIndex=15; bg.Parent=track
    local bgC=Instance.new("UICorner"); bgC.CornerRadius=UDim.new(1,0); bgC.Parent=bg
    local pct0=(def-min)/(max-min)
    local fill=Instance.new("Frame"); fill.Size=UDim2.new(pct0,0,1,0); fill.BackgroundColor3=currentAccent
    fill.BorderSizePixel=0; fill.ZIndex=16; fill.Parent=bg
    local fC=Instance.new("UICorner"); fC.CornerRadius=UDim.new(1,0); fC.Parent=fill
    local knob=Instance.new("Frame"); knob.Size=UDim2.new(0,16,0,16); knob.Position=UDim2.new(pct0,-8,0.5,-8)
    knob.BackgroundColor3=COL.white; knob.BorderSizePixel=0; knob.ZIndex=17; knob.Parent=bg
    local kC=Instance.new("UICorner"); kC.CornerRadius=UDim.new(1,0); kC.Parent=knob
    local kS=Instance.new("UIStroke"); kS.Color=currentAccent; kS.Thickness=2; kS.Parent=knob
    local drag=false; local curVal=def
    local function upd(mx)
        local ax=bg.AbsolutePosition.X; local aw=bg.AbsoluteSize.X
        local p=math.clamp((mx-ax)/aw,0,1)
        curVal=math.floor(min+(max-min)*p+0.5)
        T(fill,0.06,{Size=UDim2.new(p,0,1,0)}):Play()
        T(knob,0.06,{Position=UDim2.new(p,-8,0.5,-8)}):Play()
        vl.Text=tostring(curVal)
        pcall(function() cb(curVal) end)
    end
    track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; upd(i.Position.X); T(knob,0.12,{Size=UDim2.new(0,20,0,20),Position=UDim2.new((curVal-min)/(max-min),-10,0.5,-10)},Enum.EasingStyle.Back):Play(); T(kS,0.1,{Thickness=3}):Play() end end)
    bg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; upd(i.Position.X) end end)
    UserInputService.InputChanged:Connect(function(i) if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then upd(i.Position.X) end end)
    UserInputService.InputEnded:Connect(function(i) if (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch) and drag then drag=false; local p2=(curVal-min)/(max-min); T(knob,0.2,{Size=UDim2.new(0,16,0,16),Position=UDim2.new(p2,-8,0.5,-8)},Enum.EasingStyle.Back):Play(); T(kS,0.15,{Thickness=2}):Play() end end)
    return f
end

local function Btn(par, title, desc, cb)
    local b=Instance.new("TextButton"); b.Size=UDim2.new(1,0,0,44); b.BackgroundColor3=currentAccent
    b.BackgroundTransparency=0.82; b.BorderSizePixel=0; b.Text=""; b.ZIndex=14; b.Parent=par
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,10); c.Parent=b
    local st=Instance.new("UIStroke"); st.Color=currentAccent; st.Thickness=1; st.Transparency=0.55; st.Parent=b
    local tl=Instance.new("TextLabel"); tl.Size=UDim2.new(1,-20,0,20); tl.Position=UDim2.new(0,12,0,6)
    tl.BackgroundTransparency=1; tl.Text=title; tl.TextColor3=COL.white; tl.TextSize=12; tl.Font=Enum.Font.GothamBold
    tl.TextXAlignment=Enum.TextXAlignment.Left; tl.ZIndex=15; tl.Parent=b
    local dl=Instance.new("TextLabel"); dl.Size=UDim2.new(1,-20,0,12); dl.Position=UDim2.new(0,12,0,26)
    dl.BackgroundTransparency=1; dl.Text=desc; dl.TextColor3=COL.dim; dl.TextSize=9; dl.Font=Enum.Font.Gotham
    dl.TextXAlignment=Enum.TextXAlignment.Left; dl.ZIndex=15; dl.Parent=b
    b.MouseEnter:Connect(function() T(b,0.15,{BackgroundTransparency=0.25}):Play(); T(st,0.15,{Thickness=2,Transparency=0}):Play(); T(tl,0.15,{Position=UDim2.new(0,16,0,6)}):Play() end)
    b.MouseLeave:Connect(function() T(b,0.15,{BackgroundTransparency=0.82}):Play(); T(st,0.15,{Thickness=1,Transparency=0.55}):Play(); T(tl,0.15,{Position=UDim2.new(0,12,0,6)}):Play() end)
    b.MouseButton1Click:Connect(function() T(b,0.07,{BackgroundTransparency=0}):Play(); task.wait(0.08); T(b,0.2,{BackgroundTransparency=0.3}):Play(); pcall(function() cb() end) end)
    return b
end

local function ColorPicker(par, title, presets, cb)
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,88); f.BackgroundColor3=COL.bgPanel
    f.BackgroundTransparency=0.35; f.BorderSizePixel=0; f.ZIndex=14; f.Parent=par
    local fc=Instance.new("UICorner"); fc.CornerRadius=UDim.new(0,10); fc.Parent=f
    local tl=Instance.new("TextLabel"); tl.Size=UDim2.new(1,-20,0,20); tl.Position=UDim2.new(0,12,0,8)
    tl.BackgroundTransparency=1; tl.Text=title; tl.TextColor3=COL.white; tl.TextSize=11; tl.Font=Enum.Font.GothamBold
    tl.TextXAlignment=Enum.TextXAlignment.Left; tl.ZIndex=15; tl.Parent=f
    local grid=Instance.new("Frame"); grid.Size=UDim2.new(1,-20,0,44); grid.Position=UDim2.new(0,10,0,32)
    grid.BackgroundTransparency=1; grid.ZIndex=15; grid.Parent=f
    local gl=Instance.new("UIGridLayout"); gl.CellSize=UDim2.new(0,36,0,36); gl.CellPadding=UDim2.new(0,6,0,6); gl.Parent=grid
    local selDot=nil
    for _,p in ipairs(presets) do
        local d=Instance.new("TextButton"); d.Size=UDim2.new(0,36,0,36); d.BackgroundColor3=p.color
        d.BorderSizePixel=0; d.Text=""; d.ZIndex=16; d.Parent=grid
        local dc=Instance.new("UICorner"); dc.CornerRadius=UDim.new(1,0); dc.Parent=d
        local ds=Instance.new("UIStroke"); ds.Color=COL.white; ds.Thickness=2; ds.Transparency=1; ds.Parent=d
        d.MouseEnter:Connect(function() if d~=selDot then T(d,0.12,{Size=UDim2.new(0,38,0,38)},Enum.EasingStyle.Back):Play() end end)
        d.MouseLeave:Connect(function() if d~=selDot then T(d,0.12,{Size=UDim2.new(0,36,0,36)}):Play() end end)
        d.MouseButton1Click:Connect(function()
            if selDot then
                local os2=selDot:FindFirstChildOfClass("UIStroke")
                if os2 then T(os2,0.12,{Transparency=1}):Play() end
                T(selDot,0.12,{Size=UDim2.new(0,36,0,36)}):Play()
            end
            selDot=d; T(ds,0.12,{Transparency=0}):Play(); T(d,0.2,{Size=UDim2.new(0,40,0,40)},Enum.EasingStyle.Back):Play()
            if cb then cb(p.color, p) end
        end)
    end
    return f
end

local function InfoBox(par, text)
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,52); f.BackgroundColor3=COL.bgPanel
    f.BackgroundTransparency=0.6; f.BorderSizePixel=0; f.ZIndex=14; f.Parent=par
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,10); c.Parent=f
    local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,-20,1,-10); l.Position=UDim2.new(0,10,0,5)
    l.BackgroundTransparency=1; l.Text=text; l.TextColor3=COL.dim; l.TextSize=10; l.Font=Enum.Font.Gotham
    l.TextXAlignment=Enum.TextXAlignment.Left; l.TextYAlignment=Enum.TextYAlignment.Top; l.TextWrapped=true; l.ZIndex=15; l.Parent=f
    return f
end

-- ══════════════════════════════════════════════════
-- ARMAR TABS  (NHT-style icons + texto)
-- ══════════════════════════════════════════════════
local fishBtn    = CreateTabBtn("fishing", "🎣", "Tab Fishing",    1)
local autoBtn    = CreateTabBtn("auto",    "⚡", "Tab Auto",       2)
local espBtn     = CreateTabBtn("esp",     "👁", "Tab ESP",        3)
local aimbotBtn  = CreateTabBtn("aimbot",  "🎯", "Tab Aimbot",     4)
local scriptBtn  = CreateTabBtn("scripts", "📜", "Tab Scripts",    5)
local miscBtn    = CreateTabBtn("misc",    "🛠", "Misc",           6)
local configBtn  = CreateTabBtn("config",  "⚙", "Settings",       7)

local pFishing  = CreatePanel("fishing")
local pAuto     = CreatePanel("auto")
local pESP      = CreatePanel("esp")
local pAimbot   = CreatePanel("aimbot")
local pScripts  = CreatePanel("scripts")
local pMisc     = CreatePanel("misc")
local pConfig   = CreatePanel("config")

fishBtn.MouseButton1Click:Connect(function()   SwitchTab("fishing") end)
autoBtn.MouseButton1Click:Connect(function()   SwitchTab("auto")    end)
espBtn.MouseButton1Click:Connect(function()    SwitchTab("esp")     end)
aimbotBtn.MouseButton1Click:Connect(function() SwitchTab("aimbot")  end)
scriptBtn.MouseButton1Click:Connect(function() SwitchTab("scripts") end)
miscBtn.MouseButton1Click:Connect(function()   SwitchTab("misc")    end)
configBtn.MouseButton1Click:Connect(function() SwitchTab("config")  end)

-- ═══ FISHING ═══════════════════════════════════════
Section(pFishing, "🎣 Fishing Features")
Toggle(pFishing, "Auto Fish", "Pesca automáticamente", function(v)
    Flags.AutoFarm=v; if v then StartFarm(); SetStatus("🎣 Auto Fish ON",COL.green); Toast("Auto Fish activado","",COL.green,"🎣")
    else SetStatus("🎣 Auto Fish OFF",COL.red); Toast("Auto Fish desactivado",COL.red,"🎣") end
end)
Section(pFishing,"⚙ Catching Settings")
Slider(pFishing,"Catching Delay",0,10,2,function(v) Config.FarmDist=v*10; SetStatus("Delay: "..v.."s",COL.yellow) end)
Slider(pFishing,"Farm Distance",10,300,100,function(v) Config.FarmDist=v; SetStatus("Dist: "..v.." studs",COL.yellow) end)
Btn(pFishing,"▶  Start Farm","Inicia el sistema de farm",function()
    if not Flags.AutoFarm then Flags.AutoFarm=true; StartFarm(); SetStatus("✅ Farm iniciado",COL.green); Toast("Auto Farm iniciado",COL.green,"✅")
    else SetStatus("ℹ Ya está activo",COL.yellow) end
end)
Btn(pFishing,"⏹  Stop Farm","Detiene el auto farm",function()
    Flags.AutoFarm=false; SetStatus("⏹ Farm detenido",COL.red); Toast("Farm detenido",COL.red,"⏹")
end)

-- ═══ AUTO ══════════════════════════════════════════
Section(pAuto,"✨ Auto Features")
Toggle(pAuto,"Auto Collect Items","Recoge drops automáticamente",function(v)
    Flags.AutoCollect=v; if v then StartCollect(); SetStatus("💎 Collect ON",COL.green) else SetStatus("💎 Collect OFF",COL.red) end
end)
Slider(pAuto,"Collect Radius",5,150,30,function(v) Config.CollectRad=v end)
Section(pAuto,"🏃 Movement")
Toggle(pAuto,"Infinite Jump","Salto infinito",function(v) Flags.InfJump=v; if v then StartInfJump() end end)
Toggle(pAuto,"Speed Hack","Aumenta tu velocidad",function(v) Flags.SpeedHack=v; ApplySpeed(v); if v then SetStatus("⚡ Speed ON",COL.green) else SetStatus("⚡ Speed OFF",COL.red) end end)
Slider(pAuto,"Speed Value",16,300,50,function(v) Config.SpeedVal=v; if Flags.SpeedHack then local h=GetHum(); if h then h.WalkSpeed=v end end end)

-- ═══ ESP ═══════════════════════════════════════════
Section(pESP,"👁 ESP Features")
Toggle(pESP,"ESP Players","Highlight en jugadores",function(v) Flags.ESPPlayers=v; RefreshESP(); if v then SetStatus("👁 ESP ON",COL.green) else CleanESP(); SetStatus("👁 ESP OFF",COL.red) end end)
Toggle(pESP,"ESP NPCs","Highlight en NPCs/enemigos",function(v) Flags.ESPNpcs=v; RefreshNPCESP(v) end)
Slider(pESP,"ESP Fill Transparency",0,9,5,function(v)
    Config.ESPFillTransp=v/10
    for _,hl in pairs(ESPList) do if hl and hl.Parent then hl.FillTransparency=Config.ESPFillTransp end end
end)
Btn(pESP,"🔄 Refresh ESP","Actualiza ESP de jugadores",function() RefreshESP(); SetStatus("🔄 ESP OK",COL.green); Toast("ESP actualizado",COL.green,"🔄") end)
Btn(pESP,"🗑 Clear ESP","Elimina todos los highlights",function() CleanESP(); SetStatus("🗑 ESP limpiado",COL.yellow) end)

-- ═══ AIMBOT ════════════════════════════════════════
Section(pAimbot,"🎯 Aimbot Settings")
InfoBox(pAimbot,"⚠️ Compatible con juegos de disparos.\nMantén clic derecho (RMB) para activar el aim.\nRequiere executor con mousemoverel.")
Toggle(pAimbot,"Aimbot Enabled","Aim automático al objetivo más cercano",function(v)
    Flags.Aimbot=v
    if v then StartAimbot(); SetStatus("🎯 Aimbot ON",COL.green); Toast("Aimbot activado — Mantén RMB",COL.green,"🎯")
    else if aimbotConn then aimbotConn:Disconnect() end; SetStatus("🎯 Aimbot OFF",COL.red) end
end)
Toggle(pAimbot,"Team Check","Ignorar compañeros de equipo",function(v) Config.AimbotTeam=v end)
Section(pAimbot,"⚙ Aimbot Config")
Slider(pAimbot,"FOV (radio en píx.)",20,300,80,function(v) Config.AimbotFOV=v end)
Slider(pAimbot,"Smooth (x10 = lento)",1,20,2,function(v) Config.AimbotSmooth=v/20 end)

-- FOV Circle visual (solo decorativo)
do
    local fovLabel=Instance.new("Frame"); fovLabel.Size=UDim2.new(1,0,0,90); fovLabel.BackgroundColor3=COL.bgPanel
    fovLabel.BackgroundTransparency=0.5; fovLabel.BorderSizePixel=0; fovLabel.ZIndex=14; fovLabel.Parent=pAimbot
    local fl=Instance.new("UICorner"); fl.CornerRadius=UDim.new(0,10); fl.Parent=fovLabel
    local fovInfo=Instance.new("TextLabel"); fovInfo.Size=UDim2.new(1,-20,0,30); fovInfo.Position=UDim2.new(0,10,0,6)
    fovInfo.BackgroundTransparency=1; fovInfo.Text="🎯  Aimbot Target Part"
    fovInfo.TextColor3=COL.white; fovInfo.TextSize=11; fovInfo.Font=Enum.Font.GothamBold
    fovInfo.TextXAlignment=Enum.TextXAlignment.Left; fovInfo.ZIndex=15; fovInfo.Parent=fovLabel
    local parts={"Head","HumanoidRootPart","Torso","UpperTorso"}
    local partBtns={}
    for i,pname in ipairs(parts) do
        local pb=Instance.new("TextButton")
        pb.Size=UDim2.new(0,100,0,28); pb.Position=UDim2.new(0,(i-1)*108+10,0,44)
        pb.BackgroundColor3=pname==Config.AimbotPart and currentAccent or COL.dark
        pb.BackgroundTransparency=pname==Config.AimbotPart and 0 or 0.3
        pb.BorderSizePixel=0; pb.Text=pname; pb.TextColor3=COL.white; pb.TextSize=10; pb.Font=Enum.Font.GothamBold
        pb.ZIndex=16; pb.Parent=fovLabel
        local pbc=Instance.new("UICorner"); pbc.CornerRadius=UDim.new(0,8); pbc.Parent=pb
        partBtns[pname]=pb
        pb.MouseButton1Click:Connect(function()
            Config.AimbotPart=pname
            for pp,btn in pairs(partBtns) do
                T(btn,0.15,{BackgroundColor3=pp==pname and currentAccent or COL.dark, BackgroundTransparency=pp==pname and 0 or 0.3}):Play()
            end
            SetStatus("🎯 Parte: "..pname,currentAccent)
        end)
    end
end

-- ═══ SCRIPTS ═══════════════════════════════════════
Section(pScripts,"📜 External Scripts")
Btn(pScripts,"▶  Climb For Brainrots","Ejecuta script externo",function()
    SetStatus("⏳ Cargando...",COL.yellow)
    task.spawn(function()
        local ok,err=pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/ClimbForBrainrots"))() end)
        if ok then SetStatus("✅ Script OK",COL.green); Toast("Script ejecutado",COL.green,"✅")
        else SetStatus("❌ Error",COL.red); Toast("Error al cargar script",COL.red,"❌"); warn(err) end
    end)
end)
Btn(pScripts,"▶  Emote Script","Script de emotes universal",function()
    SetStatus("⏳ Cargando emotes...",COL.yellow)
    task.spawn(function()
        local ok,err=pcall(function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-7yd7-I-Emote-Script-48024"))() end)
        if ok then SetStatus("✅ Emotes OK",COL.green) else SetStatus("❌ Error emotes",COL.red) end
    end)
end)
InfoBox(pScripts,"⚠️ Requiere HttpGet habilitado en Delta Executor.\n💡 Los scripts se ejecutan en segundo plano.")

-- ═══ MISC ══════════════════════════════════════════
Section(pMisc,"🛠 Utilities")
Toggle(pMisc,"Anti AFK","Evita desconexión por inactividad",function(v) Flags.AntiAFK=v; if v then StartAntiAFK() end end)
Btn(pMisc,"🔄 Rejoin Server","Reconecta al servidor",function()
    SetStatus("🔄 Reconectando...",COL.yellow); task.wait(0.5)
    pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId,LocalPlayer) end)
end)
Btn(pMisc,"💀 Reset Character","Respawnea el personaje",function()
    local h=GetHum(); if h then h.Health=0; SetStatus("💀 Reset",COL.yellow) end
end)
Btn(pMisc,"📋 Copy PlaceId","Copia el PlaceId del juego",function()
    pcall(function() setclipboard(tostring(game.PlaceId)); SetStatus("📋 PlaceId: "..game.PlaceId,COL.green); Toast("PlaceId copiado",COL.green,"📋") end)
end)
Btn(pMisc,"📸 Copy JobId","Copia el JobId del servidor",function()
    pcall(function() setclipboard(game.JobId); SetStatus("📸 JobId copiado",COL.green); Toast("JobId copiado",COL.green,"📸") end)
end)

-- ═══ CONFIG ════════════════════════════════════════
Section(pConfig,"🎨 Accent Color")
ColorPicker(pConfig,"Color de Acento",{
    {label="Cyan",   color=Color3.fromRGB(0,200,255),   r=0,  g=200,b=255},
    {label="Green",  color=Color3.fromRGB(0,220,130),   r=0,  g=220,b=130},
    {label="Purple", color=Color3.fromRGB(160,60,255),  r=160,g=60, b=255},
    {label="Pink",   color=Color3.fromRGB(255,60,160),  r=255,g=60, b=160},
    {label="Orange", color=Color3.fromRGB(255,140,30),  r=255,g=140,b=30 },
    {label="Red",    color=Color3.fromRGB(220,50,80),   r=220,g=50, b=80 },
    {label="Gold",   color=Color3.fromRGB(255,200,0),   r=255,g=200,b=0  },
    {label="Teal",   color=Color3.fromRGB(0,200,180),   r=0,  g=200,b=180},
},function(col,preset)
    Config.AccentR=preset.r; Config.AccentG=preset.g; Config.AccentB=preset.b
    currentAccent=col; Config.RGBEnabled=false
    MainStroke.Color=col; LogoIcon.BackgroundColor3=col; SBDiv.BackgroundColor3=col
    for id,t in pairs(tabBtns) do
        t.ind.BackgroundColor3=col; t.hBG.BackgroundColor3=col
        if currentTab==id then t.ico.TextColor3=col; t.lbl.TextColor3=COL.white end
    end
    for _,p in pairs(tabPanels) do p.ScrollBarImageColor3=col end
    if Flags.ESPPlayers then RefreshESP() end
    SetStatus("🎨 "..preset.label,col)
end)

Section(pConfig,"🌈 RGB Mode")
Toggle(pConfig,"RGB Effect","Efecto arcoíris animado",function(v)
    Config.RGBEnabled=v
    if v then StartRGB(); SetStatus("🌈 RGB ON",COL.green); Toast("RGB activado 🌈",COL.green,"🌈")
    else if rgbConn then rgbConn:Disconnect() end
        currentAccent=Color3.fromRGB(Config.AccentR,Config.AccentG,Config.AccentB)
        MainStroke.Color=currentAccent; SetStatus("🌈 RGB OFF",COL.red)
    end
end)
Slider(pConfig,"RGB Speed",1,20,5,function(v) Config.RGBSpeed=v/10 end)

Section(pConfig,"✨ Appearance")
Slider(pConfig,"UI Transparency",0,8,0,function(v)
    Config.UITransp=v/10
    T(Main,0.2,{BackgroundTransparency=Config.UITransp}):Play()
end)
Slider(pConfig,"Blur Strength",0,20,8,function(v)
    Config.BlurStrength=v; T(Blur,0.3,{Size=v}):Play()
end)
Slider(pConfig,"Corner Radius",0,20,14,function(v)
    Config.CornerRadius=v; MainCorner.CornerRadius=UDim.new(0,v); TBC.CornerRadius=UDim.new(0,v); BBC.CornerRadius=UDim.new(0,v)
end)
Toggle(pConfig,"Border Glow","Brillo pulsante en el borde",function(v) Config.BorderGlow=v; if not v then MainStroke.Transparency=0.35 end end)

Section(pConfig,"💾 Save Config")
Btn(pConfig,"💾 Guardar Ajustes","Guarda todos los ajustes actuales",function()
    for k,v in pairs(Config) do SavedConfig[k]=v end; SaveConfig()
    SetStatus("💾 Guardado!",COL.green); Toast("✅ Configuración guardada",COL.green,"💾")
end)
Btn(pConfig,"🔄 Reset Config","Restaura ajustes al default",function()
    Config.AccentR=0;Config.AccentG=200;Config.AccentB=255;Config.UITransp=0;Config.BlurStrength=8
    Config.BorderGlow=true;Config.RGBEnabled=false;Config.CornerRadius=14
    currentAccent=Color3.fromRGB(0,200,255); MainStroke.Color=currentAccent
    MainCorner.CornerRadius=UDim.new(0,14); TBC.CornerRadius=UDim.new(0,14); BBC.CornerRadius=UDim.new(0,14)
    T(Blur,0.3,{Size=8}):Play(); T(Main,0.2,{BackgroundTransparency=0}):Play()
    SetStatus("🔄 Config reseteada",COL.yellow); Toast("Config reseteada",COL.yellow,"🔄")
end)
InfoBox(pConfig,"💾 Se guarda en ChloeX_v6.json\n⚠️ Requiere writefile en tu executor.")

-- ══════════════════════════════════════════════════
-- MINIMIZADO: PÍLDORA ELEGANTE
-- ══════════════════════════════════════════════════
local PillBar = Instance.new("Frame")
PillBar.Name = "PillBar"
PillBar.Size = UDim2.new(0, 220, 0, 36)
PillBar.Position = UDim2.new(0.5, -110, 0, 12)
PillBar.BackgroundColor3 = COL.titleBar
PillBar.BackgroundTransparency = 1
PillBar.BorderSizePixel = 0
PillBar.ZIndex = 30
PillBar.Visible = false
PillBar.Parent = ScreenGui

local PBC=Instance.new("UICorner"); PBC.CornerRadius=UDim.new(1,0); PBC.Parent=PillBar
local PBS=Instance.new("UIStroke"); PBS.Color=currentAccent; PBS.Thickness=1.5; PBS.Transparency=0.25; PBS.Parent=PillBar

-- Fondo con gradiente
local PBG=Instance.new("Frame"); PBG.Size=UDim2.new(1,0,1,0); PBG.BackgroundColor3=COL.titleBar; PBG.BorderSizePixel=0; PBG.ZIndex=30; PBG.Parent=PillBar
local PBGC=Instance.new("UICorner"); PBGC.CornerRadius=UDim.new(1,0); PBGC.Parent=PBG
local PBGG=Instance.new("UIGradient"); PBGG.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(10,12,22)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(14,18,28))
}); PBGG.Rotation=90; PBGG.Parent=PBG

-- Icono en píldora
local PIco=Instance.new("Frame"); PIco.Size=UDim2.new(0,24,0,24); PIco.Position=UDim2.new(0,6,0.5,-12)
PIco.BackgroundColor3=currentAccent; PIco.BorderSizePixel=0; PIco.ZIndex=32; PIco.Parent=PillBar
local PICC=Instance.new("UICorner"); PICC.CornerRadius=UDim.new(1,0); PICC.Parent=PIco
local PIcoTxt=Instance.new("TextLabel"); PIcoTxt.Size=UDim2.new(1,0,1,0); PIcoTxt.BackgroundTransparency=1
PIcoTxt.Text="✦"; PIcoTxt.TextColor3=COL.dark; PIcoTxt.TextSize=12; PIcoTxt.Font=Enum.Font.GothamBold; PIcoTxt.ZIndex=33; PIcoTxt.Parent=PIco

-- Texto en píldora
local PTxt=Instance.new("TextLabel"); PTxt.Size=UDim2.new(1,-90,1,0); PTxt.Position=UDim2.new(0,36,0,0)
PTxt.BackgroundTransparency=1; PTxt.Text="CHLOE X"
PTxt.TextColor3=COL.white; PTxt.TextSize=12; PTxt.Font=Enum.Font.GothamBold
PTxt.TextXAlignment=Enum.TextXAlignment.Left; PTxt.ZIndex=32; PTxt.Parent=PillBar

-- Punto de estado en píldora
local PDot=Instance.new("Frame"); PDot.Size=UDim2.new(0,6,0,6); PDot.Position=UDim2.new(0,108,0.5,-3)
PDot.BackgroundColor3=COL.green; PDot.BorderSizePixel=0; PDot.ZIndex=32; PDot.Parent=PillBar
local PDOTC=Instance.new("UICorner"); PDOTC.CornerRadius=UDim.new(1,0); PDOTC.Parent=PDot
task.spawn(function()
    while ScreenGui.Parent do
        if PillBar.Visible then
            T(PDot,0.8,{BackgroundTransparency=0.8},Enum.EasingStyle.Sine):Play()
            task.wait(0.8)
            T(PDot,0.8,{BackgroundTransparency=0},Enum.EasingStyle.Sine):Play()
            task.wait(0.8)
        else task.wait(0.5) end
    end
end)

-- Botón expandir en píldora
local PExpandBtn=Instance.new("TextButton"); PExpandBtn.Size=UDim2.new(0,50,0,26); PExpandBtn.Position=UDim2.new(1,-58,0.5,-13)
PExpandBtn.BackgroundColor3=currentAccent; PExpandBtn.BackgroundTransparency=0.2; PExpandBtn.BorderSizePixel=0
PExpandBtn.Text="⊞"; PExpandBtn.TextColor3=COL.dark; PExpandBtn.TextSize=14; PExpandBtn.Font=Enum.Font.GothamBold
PExpandBtn.ZIndex=33; PExpandBtn.Parent=PillBar
local PEBC=Instance.new("UICorner"); PEBC.CornerRadius=UDim.new(1,0); PEBC.Parent=PExpandBtn
PExpandBtn.MouseEnter:Connect(function() T(PExpandBtn,0.12,{BackgroundTransparency=0}):Play() end)
PExpandBtn.MouseLeave:Connect(function() T(PExpandBtn,0.12,{BackgroundTransparency=0.2}):Play() end)

-- Drag de la píldora
local pillDrag=false; local pillDragStart,pillStartPos2
PillBar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        pillDrag=true; pillDragStart=i.Position; pillStartPos2=PillBar.Position
        i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then pillDrag=false end end)
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if pillDrag and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-pillDragStart
        PillBar.Position=UDim2.new(pillStartPos2.X.Scale,pillStartPos2.X.Offset+d.X,pillStartPos2.Y.Scale,pillStartPos2.Y.Offset+d.Y)
    end
end)

-- ══════════════════════════════════════════════════
-- BOTONES DE CONTROL (Cerrar / Minimizar / Centrar)
-- ══════════════════════════════════════════════════
CloseBtn.MouseButton1Click:Connect(function()
    SetStatus("👋 Cerrando...",COL.red)
    T(Blur,0.4,{Size=0}):Play()
    T(Main,0.45,{Size=UDim2.new(0,0,0,0),Position=UDim2.new(Main.Position.X.Scale,Main.Position.X.Offset+WIN_W/2,Main.Position.Y.Scale,Main.Position.Y.Offset+WIN_H/2),BackgroundTransparency=1},Enum.EasingStyle.Back,Enum.EasingDirection.In):Play()
    task.spawn(function() for i=1,5 do T(Main,0.08,{Rotation=i*9}):Play(); task.wait(0.08) end end)
    task.wait(0.5); glowEnabled=false
    if farmConn   then farmConn:Disconnect()   end
    if collectConn then collectConn:Disconnect() end
    if jumpConn   then jumpConn:Disconnect()   end
    if afkConn    then afkConn:Disconnect()    end
    if rgbConn    then rgbConn:Disconnect()    end
    if aimbotConn then aimbotConn:Disconnect() end
    CleanESP()
    pcall(function() ScreenGui:Destroy() end)
end)

MinBtn.MouseButton1Click:Connect(function()
    isMinimized = true
    -- Animar main hacia píldora
    T(Main,0.4,{
        Size=UDim2.new(0,220,0,36),
        Position=UDim2.new(0.5,-110,0,12),
        BackgroundTransparency=1
    },Enum.EasingStyle.Back,Enum.EasingDirection.In):Play()
    task.wait(0.35)
    Main.Visible=false
    -- Mostrar píldora con animación
    PillBar.Visible=true
    PillBar.Size=UDim2.new(0,0,0,36)
    PillBar.Position=UDim2.new(0.5,0,0,12)
    PillBar.BackgroundTransparency=1
    T(PillBar,0.45,{
        Size=UDim2.new(0,220,0,36),
        Position=UDim2.new(0.5,-110,0,12),
        BackgroundTransparency=0
    },Enum.EasingStyle.Back,Enum.EasingDirection.Out):Play()
    -- Pulso de entrada de la píldora
    task.spawn(function()
        task.wait(0.45)
        T(PillBar,0.15,{Size=UDim2.new(0,235,0,40),Position=UDim2.new(0.5,-117.5,0,10)}):Play()
        task.wait(0.16)
        T(PillBar,0.2,{Size=UDim2.new(0,220,0,36),Position=UDim2.new(0.5,-110,0,12)},Enum.EasingStyle.Elastic):Play()
    end)
end)

local function RestoreFromPill()
    isMinimized = false
    -- Animar píldora hacia posición del main
    T(PillBar,0.3,{
        Size=UDim2.new(0,0,0,36),
        Position=UDim2.new(0.5,0,0,12),
        BackgroundTransparency=1
    },Enum.EasingStyle.Back,Enum.EasingDirection.In):Play()
    task.wait(0.3)
    PillBar.Visible=false
    -- Restaurar main
    Main.Visible=true
    Main.Size=UDim2.new(0,0,0,0)
    Main.Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)
    Main.BackgroundTransparency=1
    Main.Rotation=0
    T(Main,0.55,{
        Size=UDim2.new(0,WIN_W,0,WIN_H),
        BackgroundTransparency=0
    },Enum.EasingStyle.Back,Enum.EasingDirection.Out):Play()
end

PExpandBtn.MouseButton1Click:Connect(RestoreFromPill)

CenterBtn.MouseButton1Click:Connect(function()
    T(Main,0.4,{
        Size=UDim2.new(0,WIN_W,0,WIN_H),
        Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2),
        Rotation=0
    },Enum.EasingStyle.Back,Enum.EasingDirection.Out):Play()
    SetStatus("⊞ Centrada",COL.green); Toast("Ventana centrada",COL.green,"⊞")
end)

-- ══════════════════════════════════════════════════
-- ARRASTRE DE LA VENTANA PRINCIPAL
-- ══════════════════════════════════════════════════
TBar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        isDragging=true; dragStart=i.Position; startPos=Main.Position
        T(MainStroke,0.12,{Thickness=2.5,Transparency=0}):Play()
        i.Changed:Connect(function()
            if i.UserInputState==Enum.UserInputState.End then
                isDragging=false; T(MainStroke,0.2,{Thickness=1.5,Transparency=0.35}):Play()
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if isDragging and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-dragStart
        Main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
end)

-- ══════════════════════════════════════════════════
-- RGB UPDATE LOOP — actualiza MainStroke en tiempo real
-- ══════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    if Config.RGBEnabled then
        MainStroke.Color=currentAccent
        PBS.Color=currentAccent
        PIco.BackgroundColor3=currentAccent
        SBDiv.BackgroundColor3=currentAccent
    end
end)

-- ══════════════════════════════════════════════════
-- LÓGICA DEL KEY
-- ══════════════════════════════════════════════════
local function UnlockHub()
    keyUnlocked=true
    -- Cerrar key screen con animación
    T(KeyScreen,0.5,{Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0),BackgroundTransparency=1},Enum.EasingStyle.Back,Enum.EasingDirection.In):Play()
    task.wait(0.5)
    KeyScreen.Visible=false

    -- Mostrar main con animación cinemática
    Main.Visible=true
    Main.Size=UDim2.new(0,0,0,0)
    Main.Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)
    Main.BackgroundTransparency=1
    Main.Rotation=0

    -- Paso 1: aparece escalando con rebote
    T(Main,0.7,{Size=UDim2.new(0,WIN_W,0,WIN_H),BackgroundTransparency=0},Enum.EasingStyle.Back,Enum.EasingDirection.Out):Play()
    task.wait(0.2)
    -- Logo entra
    T(Logo,0.5,{TextTransparency=0},Enum.EasingStyle.Quad):Play()
    T(VerLabel,0.5,{TextTransparency=0},Enum.EasingStyle.Quad):Play()

    task.wait(0.7)
    SwitchTab("fishing")
    SetStatus("🎉 Chloe X v6.0 cargado!",COL.green)
    Toast("¡Bienvenido a Chloe X v6.0! ✦",currentAccent,"✦")
    if Config.RGBEnabled then StartRGB() end

    task.spawn(function()
        task.wait(3)
        SetStatus("✅ Todos los sistemas listos",currentAccent)
        task.wait(2)
        SetStatus("💡 Navega con las pestañas",COL.dim)
    end)
end

KSBtn.MouseButton1Click:Connect(function()
    local entered=KSInput.Text:gsub("%s",""):upper()
    if entered==VALID_KEY then
        T(KSBtn,0.2,{BackgroundColor3=COL.green}):Play()
        KSErr.Text=""
        KSBtn.Text="✅  KEY VÁLIDA — Cargando..."
        task.wait(0.8)
        UnlockHub()
    else
        KSErr.Text="❌ Key incorrecta. Inténtalo de nuevo."
        T(KSBox,0.05,{Position=UDim2.new(0,35,0,100)}):Play()
        task.wait(0.06); T(KSBox,0.05,{Position=UDim2.new(0,25,0,100)}):Play()
        task.wait(0.06); T(KSBox,0.05,{Position=UDim2.new(0,30,0,100)}):Play()
        T(KSBs,0.2,{Color=COL.red,Transparency=0}):Play()
        task.wait(1)
        T(KSBs,0.3,{Color=COL.dimmer,Transparency=1}):Play()
        KSErr.Text=""
    end
end)

-- Enter en el textbox también verifica
KSInput.FocusLost:Connect(function(enter)
    if enter then KSBtn:FindFirstAncestor("ChloeXHub") and KSBtn.MouseButton1Click:Fire() end
end)

-- ══════════════════════════════════════════════════
print("══════════════════════════════════════")
print("  ✦ CHLOE X v6.0  ✦  Ultimate Edition")
print("  ✅ Sistema de KEY cargado")
print("  🌨 Partículas de nieve activas")
print("  🎯 Aimbot para juegos de disparos")
print("  🌈 RGB + Save Config")
print("  💊 Minimizado como píldora elegante")
print("  KEY: CHLOEX-2025")
print("══════════════════════════════════════")
