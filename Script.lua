do
	local function destroyNamed(parent, names)
		if not parent then return end
		local ok, children = pcall(function() return parent:GetChildren() end)
		if not ok then return end
		for _, gui in ipairs(children) do
			for _, n in ipairs(names) do
				if gui.Name == n then
					pcall(function() gui:Destroy() end)
					break
				end
			end
		end
	end

	local NAMES = { "Luna UI", "LunaUI", "BladeX_MusicPlayer", "Luna", "Luna-Old" }
	-- Fix: también destruir BladeXKeyUI anterior para evitar ventanas duplicadas al re-ejecutar
	local KEY_NAMES = { "BladeXKeyUI" }

	local _cg = game:GetService("CoreGui")
	destroyNamed(_cg, NAMES)
	destroyNamed(_cg, KEY_NAMES)

	local _rcg = _cg:FindFirstChild("RobloxGui")
	if _rcg then destroyNamed(_rcg, NAMES) destroyNamed(_rcg, KEY_NAMES) end

	if gethui then
		local ok, hui = pcall(gethui)
		if ok and hui then
			destroyNamed(hui, NAMES)
			destroyNamed(hui, KEY_NAMES)
		end
	end

	local _pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
	destroyNamed(_pg, NAMES)
	destroyNamed(_pg, KEY_NAMES)

	-- Fix: limpiar LunaBlur y DepthOfField residuales del BlurModule anterior
	pcall(function()
		local cam = workspace.CurrentCamera
		if cam then
			for _, v in ipairs(cam:GetChildren()) do
				if v.Name == "LunaBlur" then v:Destroy() end
			end
		end
		local lighting = game:GetService("Lighting")
		for _, v in ipairs(lighting:GetChildren()) do
			if v:IsA("DepthOfFieldEffect") and v.Name:sub(1,4) == "DPT_" then
				v:Destroy()
			end
		end
	end)

	if _G.BladeXMusic then
		pcall(function() _G.BladeXMusic:Stop() _G.BladeXMusic:Destroy() end)
		_G.BladeXMusic = nil
	end

	if _G.BladeXProgressConn then
		pcall(function() _G.BladeXProgressConn:Disconnect() end)
		_G.BladeXProgressConn = nil
	end

	local ss = game:GetService("SoundService")
	for _, s in ipairs(ss:GetChildren()) do
		if s.Name == "BladeX_Music" then
			pcall(function() s:Stop() s:Destroy() end)
		end
	end

	if getgenv then getgenv().ConfirmLuna = nil end

	-- ── LIMPIEZA POR REFERENCIA GLOBAL ─────────────────────────────
	-- Si existe una ejecución anterior, destruir su LunaUI directamente
	-- (independientemente de su nombre o contenedor actual)
	if _G.BladeX_LunaUI then
		pcall(function() _G.BladeX_LunaUI:Destroy() end)
		_G.BladeX_LunaUI = nil
	end

	-- Desconectar el enforcer Heartbeat de ejecuciones anteriores
	if getgenv then
		local genv = getgenv()
		if genv._BladeXDragGuard then
			pcall(function() genv._BladeXDragGuard:Disconnect() end)
			genv._BladeXDragGuard = nil
		end
		if genv._BladeXLoaderDone ~= nil then
			genv._BladeXLoaderDone = nil
		end
	end

	-- Destruir cualquier elemento suelto residual (Drag, ShadowHolder, MobileSupport)
	-- que no haya sido eliminado junto con LunaUI
	local _cleanContainers = {game:GetService("CoreGui")}
	pcall(function()
		local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
		if pg then table.insert(_cleanContainers, pg) end
	end)
	if gethui then
		pcall(function()
			local h = gethui()
			if h then table.insert(_cleanContainers, h) end
		end)
	end
	local _GHOST_NAMES = {Drag=true, ShadowHolder=true, MobileSupport=true, BladeXLoader=true}
	for _, container in ipairs(_cleanContainers) do
		pcall(function()
			for _, child in ipairs(container:GetDescendants()) do
				if _GHOST_NAMES[child.Name] then
					pcall(function() child:Destroy() end)
				end
			end
		end)
	end

	task.wait(0.15)
end

-- ================================================================
--   BLADEX LOADING SCREEN
--   _loaderDone se activa al terminar completamente la animación
-- ================================================================
local _loaderDone = false
task.spawn(function()
	local ok, _TS  = pcall(function() return game:GetService("TweenService") end)
	local ok2, _RS = pcall(function() return game:GetService("RunService")   end)
	if not ok or not ok2 then return end

	local _guiParent = game:GetService("CoreGui")
	pcall(function()
		local h = gethui()
		if h then _guiParent = h end
	end)

	local C_OVERLAY = Color3.fromRGB(8,  4, 10)
	local C_M_BG    = Color3.fromRGB(110, 18, 28)
	local C_LOGO    = Color3.fromRGB(240, 55, 90)
	local C_TEXT    = Color3.fromRGB(210, 75, 75)
	local C_STAR    = Color3.fromRGB(255, 245, 245)

	local _sg = Instance.new("ScreenGui")
	_sg.Name           = "BladeXLoader"
	_sg.IgnoreGuiInset = true
	_sg.ResetOnSpawn   = false
	_sg.DisplayOrder   = 9999
	pcall(function() _sg.Parent = _guiParent end)

	local _ov = Instance.new("Frame", _sg)
	_ov.Size                   = UDim2.new(1, 0, 1, 0)
	_ov.BackgroundColor3       = C_OVERLAY
	_ov.BackgroundTransparency = 1
	_ov.BorderSizePixel        = 0

	-- Estrellas
	math.randomseed(42)
	for _ = 1, 60 do
		local s = Instance.new("Frame", _ov)
		local sz = math.random(1, 3)
		s.Size                   = UDim2.new(0, sz, 0, sz)
		s.Position               = UDim2.new(math.random(), 0, math.random(), 0)
		s.BackgroundColor3       = C_STAR
		s.BackgroundTransparency = math.random(55, 88) / 100
		s.BorderSizePixel        = 0
		s.ZIndex                 = 2
		Instance.new("UICorner", s).CornerRadius = UDim.new(1, 0)
	end

	-- Gran "B" de fondo
	local _bigB = Instance.new("TextLabel", _ov)
	_bigB.Size                   = UDim2.new(0, 860, 0, 860)
	_bigB.AnchorPoint            = Vector2.new(0.5, 0.5)
	_bigB.Position               = UDim2.new(0.5, 0, 0.44, 0)
	_bigB.BackgroundTransparency = 1
	_bigB.Text                   = "B"
	_bigB.TextColor3             = C_M_BG
	_bigB.Font                   = Enum.Font.GothamBold
	_bigB.TextScaled             = true
	_bigB.TextTransparency       = 1
	_bigB.ZIndex                 = 3

	-- Logo container
	local _lh = Instance.new("Frame", _ov)
	_lh.Size                   = UDim2.new(0, 120, 0, 120)
	_lh.AnchorPoint            = Vector2.new(0.5, 0.5)
	_lh.Position               = UDim2.new(0.5, 0, 0.30, 0)
	_lh.BackgroundTransparency = 1
	_lh.ZIndex                 = 6

	local _lglow = Instance.new("Frame", _lh)
	_lglow.Size                   = UDim2.new(1, 30, 1, 30)
	_lglow.Position               = UDim2.new(0, -15, 0, -15)
	_lglow.BackgroundColor3       = C_LOGO
	_lglow.BackgroundTransparency = 1
	_lglow.BorderSizePixel        = 0
	_lglow.ZIndex                 = 6
	Instance.new("UICorner", _lglow).CornerRadius = UDim.new(1, 0)

	local _lbase = Instance.new("Frame", _lh)
	_lbase.Size                   = UDim2.new(1, 0, 1, 0)
	_lbase.BackgroundColor3       = Color3.fromRGB(30, 6, 10)
	_lbase.BackgroundTransparency = 1
	_lbase.BorderSizePixel        = 0
	_lbase.ZIndex                 = 7
	Instance.new("UICorner", _lbase).CornerRadius = UDim.new(1, 0)

	local _ltop = Instance.new("Frame", _lh)
	_ltop.Size                   = UDim2.new(0.88, 0, 0.55, 0)
	_ltop.Position               = UDim2.new(0.06, 0, 0.04, 0)
	_ltop.BackgroundColor3       = C_LOGO
	_ltop.BackgroundTransparency = 1
	_ltop.BorderSizePixel        = 0
	_ltop.ZIndex                 = 8
	Instance.new("UICorner", _ltop).CornerRadius = UDim.new(0.4, 0)
	local _tg = Instance.new("UIGradient", _ltop)
	_tg.Rotation = 135
	_tg.Color    = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 85, 115)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 30,  55))
	})

	local _lhole = Instance.new("Frame", _lh)
	_lhole.Size                   = UDim2.new(0.55, 0, 0.50, 0)
	_lhole.Position               = UDim2.new(0.22, 0, 0.30, 0)
	_lhole.BackgroundColor3       = Color3.fromRGB(30, 6, 10)
	_lhole.BackgroundTransparency = 1
	_lhole.BorderSizePixel        = 0
	_lhole.ZIndex                 = 9
	Instance.new("UICorner", _lhole).CornerRadius = UDim.new(1, 0)

	local _lbot = Instance.new("Frame", _lh)
	_lbot.Size                   = UDim2.new(0.40, 0, 0.38, 0)
	_lbot.Position               = UDim2.new(0.30, 0, 0.58, 0)
	_lbot.BackgroundColor3       = C_LOGO
	_lbot.BackgroundTransparency = 1
	_lbot.BorderSizePixel        = 0
	_lbot.ZIndex                 = 8
	Instance.new("UICorner", _lbot).CornerRadius = UDim.new(0.5, 0)

	-- Letras B L A D E X
	local WORD    = {"B","L","A","D","E","X"}
	local STEP    = 74
	local TOTAL_W = #WORD * STEP - 14
	local _letters = {}
	for i, char in ipairs(WORD) do
		local lbl = Instance.new("TextLabel", _ov)
		lbl.Size                   = UDim2.new(0, 60, 0, 72)
		lbl.AnchorPoint            = Vector2.new(0.5, 0.5)
		lbl.Position               = UDim2.new(0.5, -TOTAL_W/2 + (i-0.5)*STEP, 0.68, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text                   = char
		lbl.TextColor3             = C_TEXT
		lbl.Font                   = Enum.Font.GothamBold
		lbl.TextScaled             = true
		lbl.TextTransparency       = 1
		lbl.ZIndex                 = 10
		local g = Instance.new("UIGradient", lbl)
		g.Rotation = 90
		g.Color    = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(235, 95, 95)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(165, 42, 42))
		})
		_letters[i] = lbl
	end

	-- Spinner
	local _spinAngle = 0
	local _doSpin    = true
	local _spinConn  = _RS.Heartbeat:Connect(function(dt)
		if not _doSpin then return end
		_spinAngle        = (_spinAngle + dt * 180) % 360
		_ltop.Rotation    =  _spinAngle
		_lbot.Rotation    = -_spinAngle
		_lhole.Rotation   =  _spinAngle * 1.5
		_lglow.BackgroundTransparency = 0.70 + math.sin(tick() * 3) * 0.10
	end)

	-- Fade-in overlay
	_TS:Create(_ov, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {BackgroundTransparency = 0.30}):Play()
	task.wait(0.25)

	-- Gran B aparece
	_TS:Create(_bigB, TweenInfo.new(1.0, Enum.EasingStyle.Quart), {TextTransparency = 0.58}):Play()

	-- Logo aparece (poner visible y animar)
	_lglow.BackgroundTransparency = 0.75
	_lbase.BackgroundTransparency = 0
	_ltop.BackgroundTransparency  = 0
	_lhole.BackgroundTransparency = 0
	_lbot.BackgroundTransparency  = 0
	_TS:Create(_lh, TweenInfo.new(0.75, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.38, 0)
	}):Play()
	task.wait(0.6)

	-- Letras aparecen una por una
	for i, lbl in ipairs(_letters) do
		local px, ox = lbl.Position.X.Scale, lbl.Position.X.Offset
		_TS:Create(lbl, TweenInfo.new(0.30, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextTransparency = 0,
			Position         = UDim2.new(px, ox, 0.62, 0)
		}):Play()
		task.wait(0.075)
	end
	task.wait(0.8)

	-- Fade-out
	_doSpin = false
	_TS:Create(_lh, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 0.22, 0)
	}):Play()
	for _, d in ipairs(_lh:GetDescendants()) do
		if d:IsA("Frame") then
			_TS:Create(d, TweenInfo.new(0.45), {BackgroundTransparency = 1}):Play()
		end
	end
	local _half = (#_letters + 1) / 2
	for i, lbl in ipairs(_letters) do
		local dir = (i - _half) / _half
		_TS:Create(lbl, TweenInfo.new(0.40, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
			TextTransparency = 1,
			Position         = UDim2.new(lbl.Position.X.Scale + dir * 0.15, lbl.Position.X.Offset, 0.70, 0)
		}):Play()
		task.wait(0.025)
	end
	task.wait(0.15)
	_TS:Create(_bigB, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
	_TS:Create(_ov,   TweenInfo.new(0.65, Enum.EasingStyle.Quart), {BackgroundTransparency = 1}):Play()
	task.wait(0.7)
	_spinConn:Disconnect()
	pcall(function() _sg:Destroy() end)
	_loaderDone = true  -- ✓ animación completada
end)
-- ================================================================


-- ================================================================
-- BLADEX TRANSPARENCY GUARD
-- Función centralizada que corrige elementos transparentes residuales.
-- Llámala si en el futuro modificas la UI y aparecen frames fantasma.
-- ================================================================
-- ================================================================
-- BLADEX GHOST SCANNER & ENFORCER
-- Escanea TODOS los hijos de LunaUI y neutraliza cualquier Frame
-- o ImageLabel que esté renderizándose de forma no deseada.
-- Se ejecuta al inicio y puede llamarse manualmente en cualquier momento.
-- ================================================================
local _ALLOWED_LUNAUI_CHILDREN = {
	SmartWindow   = true,
	Notifications = true,
	Drag          = true,
	-- ShadowHolder existe en el asset pero debe mantenerse invisible hasta que la ventana abra
	ShadowHolder  = true,
}

-- ── Helper: neutraliza un elemento GUI por completo ──────────────
-- Pone transparencia = 1, Visible = false y Active = false.
-- Esto evita que frames INVISIBLES sigan mostrando el cursor de mano
-- y capturando clics/toques en el juego.
local function _neutralizeElement(obj)
	pcall(function()
		if obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
			obj.BackgroundTransparency = 1
			obj.Visible = false
			-- Active=false: impide que el Frame capture input y muestre "manita"
			pcall(function() obj.Active = false end)
		elseif obj:IsA("ImageLabel") then
			obj.ImageTransparency = 1
			obj.BackgroundTransparency = 1
			obj.Visible = false
		elseif obj:IsA("ImageButton") or obj:IsA("TextButton") then
			obj.ImageTransparency    = 1
			obj.BackgroundTransparency = 1
			obj.Visible  = false
			obj.AutoButtonColor = false
			-- Botones invisibles: desactivar para no mostrar cursor de mano
			pcall(function() obj.Active = false end)
		elseif obj:IsA("TextLabel") then
			obj.TextTransparency = 1
			obj.BackgroundTransparency = 1
			obj.Visible = false
		end
	end)
end

local function BladeX_Guard()
	pcall(function()
		if not LunaUI then return end

		-- 1. Escanear TODOS los hijos directos de LunaUI
		--    y forzar transparencia + Active=false en los desconocidos
		for _, child in ipairs(LunaUI:GetChildren()) do
			if not _ALLOWED_LUNAUI_CHILDREN[child.Name] then
				_neutralizeElement(child)
				pcall(function()
					for _, d in ipairs(child:GetDescendants()) do
						_neutralizeElement(d)
					end
				end)
			end
		end

		-- 2. ShadowHolder específico: transparente y sin input cuando Main no es visible
		local sh = LunaUI:FindFirstChild("ShadowHolder")
		if sh then
			sh.BackgroundTransparency = 1
			sh.Visible = false
			pcall(function() sh.Active = false end)
			for _, d in ipairs(sh:GetDescendants()) do
				_neutralizeElement(d)
			end
		end

		-- 3. dragBar: siempre transparente (el enforcer Heartbeat lo cubre también)
		local db = LunaUI:FindFirstChild("Drag")
		if db then
			db.BackgroundTransparency = 1
			for _, d in ipairs(db:GetDescendants()) do
				if d:IsA("Frame") and d.Name ~= "Drag" then
					d.BackgroundTransparency = 1
				end
			end
		end

		-- 4. MobileSupport: destruir si existe (causa línea derecha y captura input)
		local ms = LunaUI:FindFirstChild("MobileSupport")
		if ms then pcall(function() ms:Destroy() end) end

		-- 5. Limpiar ScreenGuis residuales del loader en todos los contenedores
		local containers = {game:GetService("CoreGui"), Players.LocalPlayer:FindFirstChild("PlayerGui")}
		if gethui then pcall(function() table.insert(containers, gethui()) end) end
		for _, container in ipairs(containers) do
			if container then
				for _, sg in ipairs(container:GetChildren()) do
					if sg.Name == "BladeXLoader" then
						pcall(function() sg:Destroy() end)
					end
				end
			end
		end
	end)
end

-- Esperar a que la animación de carga termine ANTES de inicializar Luna UI
repeat task.wait(0.05) until _loaderDone
BladeX_Guard()
-- ================================================================

local Release = "Prerelease Beta 6.1"

local Luna = {
	Folder = "Luna",
	Options = {},
	ThemeGradient = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(117, 164, 206)), ColorSequenceKeypoint.new(0.50, Color3.fromRGB(123, 201, 201)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(224, 138, 175))}
}

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Localization = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")

local isStudio
local website = "github.com/Nebula-Softworks"

if RunService:IsStudio() then
	isStudio = true
end

local IconModule = {
	Lucide = nil,
	Material = {
		["perm_media"] = "http://www.roblox.com/asset/?id=6031215982";
		["sticky_note_2"] = "http://www.roblox.com/asset/?id=6031265972";
		["gavel"] = "http://www.roblox.com/asset/?id=6023565902";
		["table_view"] = "http://www.roblox.com/asset/?id=6031233835";
		["home"] = "http://www.roblox.com/asset/?id=6026568195";
		["list"] = "http://www.roblox.com/asset/?id=6026568229";
		["alarm_add"] = "http://www.roblox.com/asset/?id=6023426898";
		["speaker_notes"] = "http://www.roblox.com/asset/?id=6031266001";
		["check_circle_outline"] = "http://www.roblox.com/asset/?id=6023426909";
		["extension"] = "http://www.roblox.com/asset/?id=6023565892";
		["pending"] = "http://www.roblox.com/asset/?id=6031084745";
		["pageview"] = "http://www.roblox.com/asset/?id=6031216007";
		["group_work"] = "http://www.roblox.com/asset/?id=6023565910";
		["zoom_in"] = "http://www.roblox.com/asset/?id=6031075573";
		["aspect_ratio"] = "http://www.roblox.com/asset/?id=6022668895";
		["code"] = "http://www.roblox.com/asset/?id=6022668955";
		["3d_rotation"] = "http://www.roblox.com/asset/?id=6022668893";
		["translate"] = "http://www.roblox.com/asset/?id=6031225812";
		["star_rate"] = "http://www.roblox.com/asset/?id=6031265978";
		["system_update_alt"] = "http://www.roblox.com/asset/?id=6031251515";
		["open_with"] = "http://www.roblox.com/asset/?id=6026568265";
		["build_circle"] = "http://www.roblox.com/asset/?id=6023426952";
		["toc"] = "http://www.roblox.com/asset/?id=6031229341";
		["settings_phone"] = "http://www.roblox.com/asset/?id=6031289445";
		["open_in_full"] = "http://www.roblox.com/asset/?id=6026568245";
		["history"] = "http://www.roblox.com/asset/?id=6026568197";
		["accessibility_new"] = "http://www.roblox.com/asset/?id=6022668945";
		["hourglass_disabled"] = "http://www.roblox.com/asset/?id=6026568193";
		["line_style"] = "http://www.roblox.com/asset/?id=6026568276";
		["account_circle"] = "http://www.roblox.com/asset/?id=6022668898";
		["settings_cell"] = "http://www.roblox.com/asset/?id=6031280890";
		["search_off"] = "http://www.roblox.com/asset/?id=6031260783";
		["shop"] = "http://www.roblox.com/asset/?id=6031265983";
		["anchor"] = "http://www.roblox.com/asset/?id=6023426906";
		["language"] = "http://www.roblox.com/asset/?id=6026568213";
		["settings_brightness"] = "http://www.roblox.com/asset/?id=6031280902";
		["restore_page"] = "http://www.roblox.com/asset/?id=6031154877";
		["chrome_reader_mode"] = "http://www.roblox.com/asset/?id=6023426912";
		["sync_alt"] = "http://www.roblox.com/asset/?id=6031233840";
		["book"] = "http://www.roblox.com/asset/?id=6022860343";
		["smart_button"] = "http://www.roblox.com/asset/?id=6031265962";
		["request_page"] = "http://www.roblox.com/asset/?id=6031154873";
		["lock_clock"] = "http://www.roblox.com/asset/?id=6026568260";
		["android"] = "http://www.roblox.com/asset/?id=6022668966";
		["outgoing_mail"] = "http://www.roblox.com/asset/?id=6026568242";
		["dynamic_form"] = "http://www.roblox.com/asset/?id=6023426970";
		["track_changes"] = "http://www.roblox.com/asset/?id=6031225814";
		["source"] = "http://www.roblox.com/asset/?id=6031289451";
		["thumb_down"] = "http://www.roblox.com/asset/?id=6031229336";
		["integration_instructions"] = "http://www.roblox.com/asset/?id=6026568214";
		["opacity"] = "http://www.roblox.com/asset/?id=6026568295";
		["perm_identity"] = "http://www.roblox.com/asset/?id=6031215978";
		["view_module"] = "http://www.roblox.com/asset/?id=6031079152";
		["perm_data_setting"] = "http://www.roblox.com/asset/?id=6031215991";
		["assignment_turned_in"] = "http://www.roblox.com/asset/?id=6023426904";
		["change_history"] = "http://www.roblox.com/asset/?id=6023426914";
		["thumb_down_off_alt"] = "http://www.roblox.com/asset/?id=6031229354";
		["text_rotation_angledown"] = "http://www.roblox.com/asset/?id=6031251513";
		["bookmark"] = "http://www.roblox.com/asset/?id=6022852108";
		["view_stream"] = "http://www.roblox.com/asset/?id=6031079164";
		["remove_done"] = "http://www.roblox.com/asset/?id=6031086169";
		["markunread_mailbox"] = "http://www.roblox.com/asset/?id=6031082531";
		["store"] = "http://www.roblox.com/asset/?id=6031265968";
		["text_rotation_angleup"] = "http://www.roblox.com/asset/?id=6031229337";
		["eco"] = "http://www.roblox.com/asset/?id=6023426988";
		["find_in_page"] = "http://www.roblox.com/asset/?id=6023426986";
		["api"] = "http://www.roblox.com/asset/?id=6022668911";
		["launch"] = "http://www.roblox.com/asset/?id=6026568211";
		["text_rotation_down"] = "http://www.roblox.com/asset/?id=6031229334";
		["flip_to_back"] = "http://www.roblox.com/asset/?id=6023565896";
		["contact_page"] = "http://www.roblox.com/asset/?id=6022668881";
		["preview"] = "http://www.roblox.com/asset/?id=6031260793";
		["restore"] = "http://www.roblox.com/asset/?id=6031260800";
		["favorite_border"] = "http://www.roblox.com/asset/?id=6023565882";
		["assignment_late"] = "http://www.roblox.com/asset/?id=6022668880";
		["youtube_searched_for"] = "http://www.roblox.com/asset/?id=6031075934";
		["hourglass_full"] = "http://www.roblox.com/asset/?id=6026568190";
		["timeline"] = "http://www.roblox.com/asset/?id=6031229350";
		["turned_in"] = "http://www.roblox.com/asset/?id=6031225808";
		["info"] = "http://www.roblox.com/asset/?id=6026568227";
		["restore_from_trash"] = "http://www.roblox.com/asset/?id=6031154869";
		["arrow_circle_down"] = "http://www.roblox.com/asset/?id=6022668877";
		["flaky"] = "http://www.roblox.com/asset/?id=6031082523";
		["alarm_on"] = "http://www.roblox.com/asset/?id=6023426920";
		["swap_vertical_circle"] = "http://www.roblox.com/asset/?id=6031233839";
		["open_in_new"] = "http://www.roblox.com/asset/?id=6026568256";
		["watch_later"] = "http://www.roblox.com/asset/?id=6031075924";
		["alarm_off"] = "http://www.roblox.com/asset/?id=6023426901";
		["maximize"] = "http://www.roblox.com/asset/?id=6026568267";
		["lock_outline"] = "http://www.roblox.com/asset/?id=6031082533";
		["outbond"] = "http://www.roblox.com/asset/?id=6026568244";
		["view_carousel"] = "http://www.roblox.com/asset/?id=6031251507";
		["published_with_changes"] = "http://www.roblox.com/asset/?id=6031243328";
		["verified_user"] = "http://www.roblox.com/asset/?id=6031225819";
		["drag_indicator"] = "http://www.roblox.com/asset/?id=6023426962";
		["lightbulb_outline"] = "http://www.roblox.com/asset/?id=6026568254";
		["segment"] = "http://www.roblox.com/asset/?id=6031260773";
		["assignment"] = "http://www.roblox.com/asset/?id=6022668882";
		["work_outline"] = "http://www.roblox.com/asset/?id=6031075930";
		["line_weight"] = "http://www.roblox.com/asset/?id=6026568226";
		["dangerous"] = "http://www.roblox.com/asset/?id=6022668916";
		["assessment"] = "http://www.roblox.com/asset/?id=6022668897";
		["view_day"] = "http://www.roblox.com/asset/?id=6031079153";
		["help_center"] = "http://www.roblox.com/asset/?id=6026568192";
		["logout"] = "http://www.roblox.com/asset/?id=6031082522";
		["event"] = "http://www.roblox.com/asset/?id=6023426959";
		["get_app"] = "http://www.roblox.com/asset/?id=6023565889";
		["tab"] = "http://www.roblox.com/asset/?id=6031233851";
		["label"] = "http://www.roblox.com/asset/?id=6031082525";
		["g_translate"] = "http://www.roblox.com/asset/?id=6031082526";
		["view_week"] = "http://www.roblox.com/asset/?id=6031079154";
		["view_in_ar"] = "http://www.roblox.com/asset/?id=6031079158";
		["card_travel"] = "http://www.roblox.com/asset/?id=6023426925";
		["lock_open"] = "http://www.roblox.com/asset/?id=6026568220";
		["voice_over_off"] = "http://www.roblox.com/asset/?id=6031075927";
		["app_blocking"] = "http://www.roblox.com/asset/?id=6022668952";
		["settings_ethernet"] = "http://www.roblox.com/asset/?id=6031280883";
		["supervised_user_circle"] = "http://www.roblox.com/asset/?id=6031289449";
		["done_all"] = "http://www.roblox.com/asset/?id=6023426929";
		["lightbulb"] = "http://www.roblox.com/asset/?id=6026568247";
		["find_replace"] = "http://www.roblox.com/asset/?id=6023426979";
		["bookmarks"] = "http://www.roblox.com/asset/?id=6023426924";
		["today"] = "http://www.roblox.com/asset/?id=6031229352";
		["class"] = "http://www.roblox.com/asset/?id=6022668949";
		["supervisor_account"] = "http://www.roblox.com/asset/?id=6031251516";
		["support"] = "http://www.roblox.com/asset/?id=6031251532";
		["done_outline"] = "http://www.roblox.com/asset/?id=6023426936";
		["reorder"] = "http://www.roblox.com/asset/?id=6031154868";
		["fact_check"] = "http://www.roblox.com/asset/?id=6023426951";
		["thumb_up"] = "http://www.roblox.com/asset/?id=6031229347";
		["assignment_returned"] = "http://www.roblox.com/asset/?id=6023426899";
		["card_giftcard"] = "http://www.roblox.com/asset/?id=6023426978";
		["trending_down"] = "http://www.roblox.com/asset/?id=6031225811";
		["settings_backup_restore"] = "http://www.roblox.com/asset/?id=6031280886";
		["settings_voice"] = "http://www.roblox.com/asset/?id=6031265966";
		["dns"] = "http://www.roblox.com/asset/?id=6023426958";
		["perm_scan_wifi"] = "http://www.roblox.com/asset/?id=6031215985";
		["plagiarism"] = "http://www.roblox.com/asset/?id=6031243320";
		["commute"] = "http://www.roblox.com/asset/?id=6022668901";
		["gif"] = "http://www.roblox.com/asset/?id=6031082540";
		["work"] = "http://www.roblox.com/asset/?id=6031075939";
		["picture_in_picture_alt"] = "http://www.roblox.com/asset/?id=6031215979";
		["query_builder"] = "http://www.roblox.com/asset/?id=6031086183";
		["label_off"] = "http://www.roblox.com/asset/?id=6026568209";
		["all_out"] = "http://www.roblox.com/asset/?id=6022668876";
		["article"] = "http://www.roblox.com/asset/?id=6022668907";
		["shopping_basket"] = "http://www.roblox.com/asset/?id=6031265997";
		["mark_as_unread"] = "http://www.roblox.com/asset/?id=6026568223";
		["work_off"] = "http://www.roblox.com/asset/?id=6031075937";
		["delete_outline"] = "http://www.roblox.com/asset/?id=6022668962";
		["account_box"] = "http://www.roblox.com/asset/?id=6023426915";
		["home_filled"] = "rbxassetid://9080449299";
		["lock"] = "http://www.roblox.com/asset/?id=6026568224";
		["perm_device_information"] = "http://www.roblox.com/asset/?id=6031215996";
		["add_task"] = "http://www.roblox.com/asset/?id=6022668912";
		["text_rotate_up"] = "http://www.roblox.com/asset/?id=6031251526";
		["swipe"] = "http://www.roblox.com/asset/?id=6031233863";
		["eject"] = "http://www.roblox.com/asset/?id=6023426930";
		["mediation"] = "http://www.roblox.com/asset/?id=6026568249";
		["label_important_outline"] = "http://www.roblox.com/asset/?id=6026568199";
		["settings_remote"] = "http://www.roblox.com/asset/?id=6031289442";
		["history_toggle_off"] = "http://www.roblox.com/asset/?id=6026568196";
		["invert_colors"] = "http://www.roblox.com/asset/?id=6026568253";
		["visibility_off"] = "http://www.roblox.com/asset/?id=6031075929";
		["addchart"] = "http://www.roblox.com/asset/?id=6023426905";
		["cancel_schedule_send"] = "http://www.roblox.com/asset/?id=6022668963";
		["loyalty"] = "http://www.roblox.com/asset/?id=6026568237";
		["speaker_notes_off"] = "http://www.roblox.com/asset/?id=6031265965";
		["online_prediction"] = "http://www.roblox.com/asset/?id=6026568239";
		["remove_shopping_cart"] = "http://www.roblox.com/asset/?id=6031260778";
		["text_rotate_vertical"] = "http://www.roblox.com/asset/?id=6031251518";
		["visibility"] = "http://www.roblox.com/asset/?id=6031075931";
		["add_to_drive"] = "http://www.roblox.com/asset/?id=6022860335";
		["accessible"] = "http://www.roblox.com/asset/?id=6022668902";
		["bookmark_border"] = "http://www.roblox.com/asset/?id=6022860339";
		["tour"] = "http://www.roblox.com/asset/?id=6031229362";
		["compare_arrows"] = "http://www.roblox.com/asset/?id=6022668951";
		["view_sidebar"] = "http://www.roblox.com/asset/?id=6031079160";
		["face"] = "http://www.roblox.com/asset/?id=6023426944";
		["wysiwyg"] = "http://www.roblox.com/asset/?id=6031075938";
		["camera_enhance"] = "http://www.roblox.com/asset/?id=6023426935";
		["perm_camera_mic"] = "http://www.roblox.com/asset/?id=6031215983";
		["model_training"] = "http://www.roblox.com/asset/?id=6026568222";
		["arrow_circle_up"] = "http://www.roblox.com/asset/?id=6022668934";
		["euro_symbol"] = "http://www.roblox.com/asset/?id=6023426954";
		["pending_actions"] = "http://www.roblox.com/asset/?id=6031260777";
		["not_accessible"] = "http://www.roblox.com/asset/?id=6026568269";
		["explore_off"] = "http://www.roblox.com/asset/?id=6023426953";
		["build"] = "http://www.roblox.com/asset/?id=6023426938";
		["backup"] = "http://www.roblox.com/asset/?id=6023426911";
		["settings_input_antenna"] = "http://www.roblox.com/asset/?id=6031280891";
		["disabled_by_default"] = "http://www.roblox.com/asset/?id=6023426939";
		["upgrade"] = "http://www.roblox.com/asset/?id=6031225815";
		["contactless"] = "http://www.roblox.com/asset/?id=6022668886";
		["trending_flat"] = "http://www.roblox.com/asset/?id=6031225818";
		["schedule"] = "http://www.roblox.com/asset/?id=6031260808";
		["offline_pin"] = "http://www.roblox.com/asset/?id=6031084770";
		["date_range"] = "http://www.roblox.com/asset/?id=6022668894";
		["flight_land"] = "http://www.roblox.com/asset/?id=6023565897";
		["view_headline"] = "http://www.roblox.com/asset/?id=6031079151";
		["cached"] = "http://www.roblox.com/asset/?id=6023426921";
		["unpublished"] = "http://www.roblox.com/asset/?id=6031225817";
		["outlet"] = "http://www.roblox.com/asset/?id=6031084748";
		["favorite"] = "http://www.roblox.com/asset/?id=6023426974";
		["vertical_split"] = "http://www.roblox.com/asset/?id=6031225820";
		["report_problem"] = "http://www.roblox.com/asset/?id=6031086176";
		["fingerprint"] = "http://www.roblox.com/asset/?id=6023565895";
		["important_devices"] = "http://www.roblox.com/asset/?id=6026568202";
		["outbox"] = "http://www.roblox.com/asset/?id=6026568263";
		["all_inbox"] = "http://www.roblox.com/asset/?id=6022668909";
		["label_important"] = "http://www.roblox.com/asset/?id=6026568215";
		["print"] = "http://www.roblox.com/asset/?id=6031243324";
		["settings_bluetooth"] = "http://www.roblox.com/asset/?id=6031280905";
		["power_settings_new"] = "http://www.roblox.com/asset/?id=6031260781";
		["zoom_out"] = "http://www.roblox.com/asset/?id=6031075577";
		["stars"] = "http://www.roblox.com/asset/?id=6031265971";
		["offline_bolt"] = "http://www.roblox.com/asset/?id=6031084742";
		["feedback"] = "http://www.roblox.com/asset/?id=6023426957";
		["accessibility"] = "http://www.roblox.com/asset/?id=6022668887";
		["announcement"] = "http://www.roblox.com/asset/?id=6022668946";
		["settings_input_hdmi"] = "http://www.roblox.com/asset/?id=6031280970";
		["leaderboard"] = "http://www.roblox.com/asset/?id=6026568216";
		["view_quilt"] = "http://www.roblox.com/asset/?id=6031079155";
		["note_add"] = "http://www.roblox.com/asset/?id=6031084749";
		["theaters"] = "http://www.roblox.com/asset/?id=6031229335";
		["alarm"] = "http://www.roblox.com/asset/?id=6023426910";
		["settings_input_composite"] = "http://www.roblox.com/asset/?id=6031280896";
		["grade"] = "http://www.roblox.com/asset/?id=6026568189";
		["tab_unselected"] = "http://www.roblox.com/asset/?id=6031251505";
		["swap_vert"] = "http://www.roblox.com/asset/?id=6031233847";
		["assignment_return"] = "http://www.roblox.com/asset/?id=6023426931";
		["highlight_alt"] = "http://www.roblox.com/asset/?id=6023565913";
		["shopping_bag"] = "http://www.roblox.com/asset/?id=6031265970";
		["contact_support"] = "http://www.roblox.com/asset/?id=6022668879";
		["flip_to_front"] = "http://www.roblox.com/asset/?id=6023565894";
		["touch_app"] = "http://www.roblox.com/asset/?id=6031229361";
		["room"] = "http://www.roblox.com/asset/?id=6031154875";
		["send_and_archive"] = "http://www.roblox.com/asset/?id=6031280889";
		["view_array"] = "http://www.roblox.com/asset/?id=6031225842";
		["settings_power"] = "http://www.roblox.com/asset/?id=6031289446";
		["admin_panel_settings"] = "http://www.roblox.com/asset/?id=6022668961";
		["open_in_browser"] = "http://www.roblox.com/asset/?id=6026568266";
		["card_membership"] = "http://www.roblox.com/asset/?id=6023426942";
		["rule"] = "http://www.roblox.com/asset/?id=6031154859";
		["schedule_send"] = "http://www.roblox.com/asset/?id=6031154866";
		["calendar_today"] = "http://www.roblox.com/asset/?id=6022668917";
		["info_outline"] = "http://www.roblox.com/asset/?id=6026568210";
		["description"] = "http://www.roblox.com/asset/?id=6022668888";
		["dashboard_customize"] = "http://www.roblox.com/asset/?id=6022668899";
		["rowing"] = "http://www.roblox.com/asset/?id=6031154857";
		["swap_horizontal_circle"] = "http://www.roblox.com/asset/?id=6031233833";
		["account_balance_wallet"] = "http://www.roblox.com/asset/?id=6022668892";
		["view_agenda"] = "http://www.roblox.com/asset/?id=6031225831";
		["shop_two"] = "http://www.roblox.com/asset/?id=6031289461";
		["done"] = "http://www.roblox.com/asset/?id=6023426926";
		["circle_notifications"] = "http://www.roblox.com/asset/?id=6023426923";
		["compress"] = "http://www.roblox.com/asset/?id=6022668878";
		["calendar_view_day"] = "http://www.roblox.com/asset/?id=6023426946";
		["thumbs_up_down"] = "http://www.roblox.com/asset/?id=6031229373";
		["account_balance"] = "http://www.roblox.com/asset/?id=6022668900";
		["play_for_work"] = "http://www.roblox.com/asset/?id=6031260776";
		["pets"] = "http://www.roblox.com/asset/?id=6031260782";
		["view_column"] = "http://www.roblox.com/asset/?id=6031079172";
		["search"] = "http://www.roblox.com/asset/?id=6031154871";
		["autorenew"] = "http://www.roblox.com/asset/?id=6023565901";
		["copyright"] = "http://www.roblox.com/asset/?id=6023565898";
		["privacy_tip"] = "http://www.roblox.com/asset/?id=6031260784";
		["arrow_right_alt"] = "http://www.roblox.com/asset/?id=6022668890";
		["delete"] = "http://www.roblox.com/asset/?id=6022668885";
		["nightlight_round"] = "http://www.roblox.com/asset/?id=6031084743";
		["batch_prediction"] = "http://www.roblox.com/asset/?id=6022860334";
		["shopping_cart"] = "http://www.roblox.com/asset/?id=6031265976";
		["login"] = "http://www.roblox.com/asset/?id=6031082527";
		["settings_input_svideo"] = "http://www.roblox.com/asset/?id=6031289444";
		["payment"] = "http://www.roblox.com/asset/?id=6031084751";
		["update"] = "http://www.roblox.com/asset/?id=6031225810";
		["text_rotation_none"] = "http://www.roblox.com/asset/?id=6031229344";
		["perm_contact_calendar"] = "http://www.roblox.com/asset/?id=6031215990";
		["explore"] = "http://www.roblox.com/asset/?id=6023426941";
		["delete_forever"] = "http://www.roblox.com/asset/?id=6022668939";
		["rounded_corner"] = "http://www.roblox.com/asset/?id=6031154861";
		["book_online"] = "http://www.roblox.com/asset/?id=6022860332";
		["quickreply"] = "http://www.roblox.com/asset/?id=6031243319";
		["bug_report"] = "http://www.roblox.com/asset/?id=6022852107";
		["subtitles_off"] = "http://www.roblox.com/asset/?id=6031289466";
		["close_fullscreen"] = "http://www.roblox.com/asset/?id=6023426928";
		["horizontal_split"] = "http://www.roblox.com/asset/?id=6026568194";
		["minimize"] = "http://www.roblox.com/asset/?id=6026568240";
		["filter_list_alt"] = "http://www.roblox.com/asset/?id=6023426955";
		["add_shopping_cart"] = "http://www.roblox.com/asset/?id=6022668875";
		["next_plan"] = "http://www.roblox.com/asset/?id=6026568231";
		["view_list"] = "http://www.roblox.com/asset/?id=6031079156";
		["receipt"] = "http://www.roblox.com/asset/?id=6031086173";
		["polymer"] = "http://www.roblox.com/asset/?id=6031260785";
		["spellcheck"] = "http://www.roblox.com/asset/?id=6031289450";
		["wifi_protected_setup"] = "http://www.roblox.com/asset/?id=6031075926";
		["label_outline"] = "http://www.roblox.com/asset/?id=6026568207";
		["highlight_off"] = "http://www.roblox.com/asset/?id=6023565916";
		["turned_in_not"] = "http://www.roblox.com/asset/?id=6031225806";
		["edit_off"] = "http://www.roblox.com/asset/?id=6023426983";
		["question_answer"] = "http://www.roblox.com/asset/?id=6031086172";
		["settings_overscan"] = "http://www.roblox.com/asset/?id=6031289459";
		["trending_up"] = "http://www.roblox.com/asset/?id=6031225816";
		["verified"] = "http://www.roblox.com/asset/?id=6031225809";
		["flight_takeoff"] = "http://www.roblox.com/asset/?id=6023565891";
		["grading"] = "http://www.roblox.com/asset/?id=6026568191";
		["dashboard"] = "http://www.roblox.com/asset/?id=6022668883";
		["expand"] = "http://www.roblox.com/asset/?id=6022668891";
		["backup_table"] = "http://www.roblox.com/asset/?id=6022860338";
		["analytics"] = "http://www.roblox.com/asset/?id=6022668884";
		["picture_in_picture"] = "http://www.roblox.com/asset/?id=6031215994";
		["settings"] = "http://www.roblox.com/asset/?id=6031280882";
		["accessible_forward"] = "http://www.roblox.com/asset/?id=6022668906";
		["pan_tool"] = "http://www.roblox.com/asset/?id=6031084771";
		["https"] = "http://www.roblox.com/asset/?id=6026568200";
		["filter_alt"] = "http://www.roblox.com/asset/?id=6023426984";
		["thumb_up_off_alt"] = "http://www.roblox.com/asset/?id=6031229342";
		["record_voice_over"] = "http://www.roblox.com/asset/?id=6031243318";
		["help_outline"] = "http://www.roblox.com/asset/?id=6026568201";
		["check_circle"] = "http://www.roblox.com/asset/?id=6023426945";
		["comment_bank"] = "http://www.roblox.com/asset/?id=6023426937";
		["perm_phone_msg"] = "http://www.roblox.com/asset/?id=6031215986";
		["settings_applications"] = "http://www.roblox.com/asset/?id=6031280894";
		["exit_to_app"] = "http://www.roblox.com/asset/?id=6023426922";
		["saved_search"] = "http://www.roblox.com/asset/?id=6031154867";
		["toll"] = "http://www.roblox.com/asset/?id=6031229343";
		["not_started"] = "http://www.roblox.com/asset/?id=6026568232";
		["subject"] = "http://www.roblox.com/asset/?id=6031289452";
		["redeem"] = "http://www.roblox.com/asset/?id=6031086170";
		["input"] = "http://www.roblox.com/asset/?id=6026568225";
		["settings_input_component"] = "http://www.roblox.com/asset/?id=6031280884";
		["assignment_ind"] = "http://www.roblox.com/asset/?id=6022668935";
		["swap_horiz"] = "http://www.roblox.com/asset/?id=6031233841";
		["fullscreen"] = "http://www.roblox.com/asset/?id=6031094681";
		["cancel"] = "http://www.roblox.com/asset/?id=6031094677";
		["subdirectory_arrow_left"] = "http://www.roblox.com/asset/?id=6031104654";
		["close"] = "http://www.roblox.com/asset/?id=6031094678";
		["arrow_back_ios"] = "http://www.roblox.com/asset/?id=6031091003";
		["east"] = "http://www.roblox.com/asset/?id=6031094675";
		["unfold_more"] = "http://www.roblox.com/asset/?id=6031104644";
		["south"] = "http://www.roblox.com/asset/?id=6031104646";
		["arrow_drop_up"] = "http://www.roblox.com/asset/?id=6031090990";
		["arrow_back"] = "http://www.roblox.com/asset/?id=6031091000";
		["arrow_downward"] = "http://www.roblox.com/asset/?id=6031090991";
		["west"] = "http://www.roblox.com/asset/?id=6031104677";
		["legend_toggle"] = "http://www.roblox.com/asset/?id=6031097233";
		["fullscreen_exit"] = "http://www.roblox.com/asset/?id=6031094691";
		["last_page"] = "http://www.roblox.com/asset/?id=6031094686";
		["switch_right"] = "http://www.roblox.com/asset/?id=6031104649";
		["check"] = "http://www.roblox.com/asset/?id=6031094667";
		["home_work"] = "http://www.roblox.com/asset/?id=6031094683";
		["north_east"] = "http://www.roblox.com/asset/?id=6031097228";
		["double_arrow"] = "http://www.roblox.com/asset/?id=6031094674";
		["more_vert"] = "http://www.roblox.com/asset/?id=6031104648";
		["chevron_left"] = "http://www.roblox.com/asset/?id=6031094670";
		["more_horiz"] = "http://www.roblox.com/asset/?id=6031104650";
		["unfold_less"] = "http://www.roblox.com/asset/?id=6031104681";
		["first_page"] = "http://www.roblox.com/asset/?id=6031094682";
		["payments"] = "http://www.roblox.com/asset/?id=6031097227";
		["arrow_right"] = "http://www.roblox.com/asset/?id=6031090994";
		["offline_share"] = "http://www.roblox.com/asset/?id=6031097267";
		["south_west"] = "http://www.roblox.com/asset/?id=6031104652";
		["expand_less"] = "http://www.roblox.com/asset/?id=6031094679";
		["south_east"] = "http://www.roblox.com/asset/?id=6031104642";
		["assistant_navigation"] = "http://www.roblox.com/asset/?id=6031091006";
		["apps"] = "http://www.roblox.com/asset/?id=6031090999";
		["arrow_upward"] = "http://www.roblox.com/asset/?id=6031090997";
		["app_settings_alt"] = "http://www.roblox.com/asset/?id=6031090998";
		["subdirectory_arrow_right"] = "http://www.roblox.com/asset/?id=6031104647";
		["north_west"] = "http://www.roblox.com/asset/?id=6031104630";
		["switch_left"] = "http://www.roblox.com/asset/?id=6031104651";
		["chevron_right"] = "http://www.roblox.com/asset/?id=6031094680";
		["arrow_forward"] = "http://www.roblox.com/asset/?id=6031090995";
		["arrow_forward_ios"] = "http://www.roblox.com/asset/?id=6031091008";
		["arrow_drop_down"] = "http://www.roblox.com/asset/?id=6031091004";
		["refresh"] = "http://www.roblox.com/asset/?id=6031097226";
		["pivot_table_chart"] = "http://www.roblox.com/asset/?id=6031097234";
		["expand_more"] = "http://www.roblox.com/asset/?id=6031094687";
		["campaign"] = "http://www.roblox.com/asset/?id=6031094666";
		["arrow_left"] = "http://www.roblox.com/asset/?id=6031091002";
		["arrow_drop_down_circle"] = "http://www.roblox.com/asset/?id=6031091001";
		["menu_open"] = "http://www.roblox.com/asset/?id=6031097229";
		["waterfall_chart"] = "http://www.roblox.com/asset/?id=6031104632";
		["assistant_direction"] = "http://www.roblox.com/asset/?id=6031091005";
		["menu"] = "http://www.roblox.com/asset/?id=6031097225";
		["personal_video"] = "http://www.roblox.com/asset/?id=6034457070";
		["power_off"] = "http://www.roblox.com/asset/?id=6034457087";
		["wifi_off"] = "http://www.roblox.com/asset/?id=6034461625";
		["adb"] = "http://www.roblox.com/asset/?id=6034418515";
		["airline_seat_recline_normal"] = "http://www.roblox.com/asset/?id=6034418512";
		["sync_problem"] = "http://www.roblox.com/asset/?id=6034452653";
		["network_check"] = "http://www.roblox.com/asset/?id=6034461631";
		["event_busy"] = "http://www.roblox.com/asset/?id=6034439634";
		["airline_seat_flat"] = "http://www.roblox.com/asset/?id=6034418511";
		["disc_full"] = "http://www.roblox.com/asset/?id=6034418518";
		["sd_card"] = "http://www.roblox.com/asset/?id=6034457089";
		["time_to_leave"] = "http://www.roblox.com/asset/?id=6034452660";
		["phone_bluetooth_speaker"] = "http://www.roblox.com/asset/?id=6034457057";
		["phone_paused"] = "http://www.roblox.com/asset/?id=6034457066";
		["phone_locked"] = "http://www.roblox.com/asset/?id=6034457058";
		["more"] = "http://www.roblox.com/asset/?id=6034461627";
		["add_call"] = "http://www.roblox.com/asset/?id=6034418524";
		["account_tree"] = "http://www.roblox.com/asset/?id=6034418507";
		["do_not_disturb_on"] = "http://www.roblox.com/asset/?id=6034439649";
		["event_note"] = "http://www.roblox.com/asset/?id=6034439637";
		["sync_disabled"] = "http://www.roblox.com/asset/?id=6034452649";
		["mms"] = "http://www.roblox.com/asset/?id=6034461621";
		["airline_seat_flat_angled"] = "http://www.roblox.com/asset/?id=6034418513";
		["bluetooth_audio"] = "http://www.roblox.com/asset/?id=6034418522";
		["vibration"] = "http://www.roblox.com/asset/?id=6034452651";
		["system_update"] = "http://www.roblox.com/asset/?id=6034452663";
		["enhanced_encryption"] = "http://www.roblox.com/asset/?id=6034439652";
		["wc"] = "http://www.roblox.com/asset/?id=6034452643";
		["live_tv"] = "http://www.roblox.com/asset/?id=6034439648";
		["folder_special"] = "http://www.roblox.com/asset/?id=6034439639";
		["phone_missed"] = "http://www.roblox.com/asset/?id=6034457056";
		["airline_seat_recline_extra"] = "http://www.roblox.com/asset/?id=6034418528";
		["sms"] = "http://www.roblox.com/asset/?id=6034452645";
		["tap_and_play"] = "http://www.roblox.com/asset/?id=6034452650";
		["confirmation_number"] = "http://www.roblox.com/asset/?id=6034418519";
		["event_available"] = "http://www.roblox.com/asset/?id=6034439643";
		["sms_failed"] = "http://www.roblox.com/asset/?id=6034452676";
		["do_not_disturb_alt"] = "http://www.roblox.com/asset/?id=6034461619";
		["do_not_disturb"] = "http://www.roblox.com/asset/?id=6034439645";
		["ondemand_video"] = "http://www.roblox.com/asset/?id=6034457065";
		["no_encryption"] = "http://www.roblox.com/asset/?id=6034457059";
		["airline_seat_legroom_extra"] = "http://www.roblox.com/asset/?id=6034418508";
		["tv_off"] = "http://www.roblox.com/asset/?id=6034452646";
		["sim_card_alert"] = "http://www.roblox.com/asset/?id=6034452641";
		["airline_seat_legroom_normal"] = "http://www.roblox.com/asset/?id=6034418532";
		["wifi"] = "http://www.roblox.com/asset/?id=6034461626";
		["do_not_disturb_off"] = "http://www.roblox.com/asset/?id=6034439642";
		["imagesearch_roller"] = "http://www.roblox.com/asset/?id=6034439635";
		["power"] = "http://www.roblox.com/asset/?id=6034457105";
		["airline_seat_legroom_reduced"] = "http://www.roblox.com/asset/?id=6034418520";
		["phone_in_talk"] = "http://www.roblox.com/asset/?id=6034457067";
		["airline_seat_individual_suite"] = "http://www.roblox.com/asset/?id=6034418514";
		["priority_high"] = "http://www.roblox.com/asset/?id=6034457092";
		["phone_callback"] = "http://www.roblox.com/asset/?id=6034457104";
		["phone_forwarded"] = "http://www.roblox.com/asset/?id=6034457106";
		["sync"] = "http://www.roblox.com/asset/?id=6034452662";
		["vpn_lock"] = "http://www.roblox.com/asset/?id=6034452648";
		["support_agent"] = "http://www.roblox.com/asset/?id=6034452656";
		["network_locked"] = "http://www.roblox.com/asset/?id=6034457064";
		["directions_off"] = "http://www.roblox.com/asset/?id=6034418517";
		["drive_eta"] = "http://www.roblox.com/asset/?id=6034464371";
		["sensor_window"] = "http://www.roblox.com/asset/?id=6031067242";
		["sensor_door"] = "http://www.roblox.com/asset/?id=6031067241";
		["keyboard_return"] = "http://www.roblox.com/asset/?id=6034818370";
		["monitor"] = "http://www.roblox.com/asset/?id=6034837803";
		["device_hub"] = "http://www.roblox.com/asset/?id=6034789877";
		["keyboard"] = "http://www.roblox.com/asset/?id=6034818398";
		["keyboard_voice"] = "http://www.roblox.com/asset/?id=6034818360";
		["cast"] = "http://www.roblox.com/asset/?id=6034789876";
		["developer_board"] = "http://www.roblox.com/asset/?id=6034789883";
		["tablet"] = "http://www.roblox.com/asset/?id=6034848733";
		["keyboard_hide"] = "http://www.roblox.com/asset/?id=6034818386";
		["dock"] = "http://www.roblox.com/asset/?id=6034789888";
		["phonelink"] = "http://www.roblox.com/asset/?id=6034837801";
		["device_unknown"] = "http://www.roblox.com/asset/?id=6034789884";
		["speaker_group"] = "http://www.roblox.com/asset/?id=6034848732";
		["desktop_mac"] = "http://www.roblox.com/asset/?id=6034789898";
		["point_of_sale"] = "http://www.roblox.com/asset/?id=6034837798";
		["memory"] = "http://www.roblox.com/asset/?id=6034837807";
		["keyboard_tab"] = "http://www.roblox.com/asset/?id=6034818363";
		["router"] = "http://www.roblox.com/asset/?id=6034837806";
		["sim_card"] = "http://www.roblox.com/asset/?id=6034837800";
		["headset"] = "http://www.roblox.com/asset/?id=6034789880";
		["gamepad"] = "http://www.roblox.com/asset/?id=6034789879";
		["speaker"] = "http://www.roblox.com/asset/?id=6034848746";
		["devices_other"] = "http://www.roblox.com/asset/?id=6034789873";
		["laptop"] = "http://www.roblox.com/asset/?id=6034818367";
		["scanner"] = "http://www.roblox.com/asset/?id=6034837799";
		["tv"] = "http://www.roblox.com/asset/?id=6034848740";
		["headset_mic"] = "http://www.roblox.com/asset/?id=6034818383";
		["browser_not_supported"] = "http://www.roblox.com/asset/?id=6034789875";
		["computer"] = "http://www.roblox.com/asset/?id=6034789874";
		["connected_tv"] = "http://www.roblox.com/asset/?id=6034789870";
		["phonelink_off"] = "http://www.roblox.com/asset/?id=6034837804";
		["headset_off"] = "http://www.roblox.com/asset/?id=6034818402";
		["cast_connected"] = "http://www.roblox.com/asset/?id=6034789895";
		["watch"] = "http://www.roblox.com/asset/?id=6034848747";
		["keyboard_arrow_up"] = "http://www.roblox.com/asset/?id=6034818379";
		["keyboard_backspace"] = "http://www.roblox.com/asset/?id=6034818381";
		["laptop_chromebook"] = "http://www.roblox.com/asset/?id=6034818364";
		["phone_iphone"] = "http://www.roblox.com/asset/?id=6034837811";
		["smartphone"] = "http://www.roblox.com/asset/?id=6034848731";
		["power_input"] = "http://www.roblox.com/asset/?id=6034837794";
		["videogame_asset"] = "http://www.roblox.com/asset/?id=6034848748";
		["desktop_windows"] = "http://www.roblox.com/asset/?id=6034789893";
		["keyboard_arrow_down"] = "http://www.roblox.com/asset/?id=6034818372";
		["laptop_mac"] = "http://www.roblox.com/asset/?id=6034837808";
		["laptop_windows"] = "http://www.roblox.com/asset/?id=6034837796";
		["keyboard_arrow_right"] = "http://www.roblox.com/asset/?id=6034818365";
		["cast_for_education"] = "http://www.roblox.com/asset/?id=6034789872";
		["keyboard_capslock"] = "http://www.roblox.com/asset/?id=6034818403";
		["toys"] = "http://www.roblox.com/asset/?id=6034848752";
		["tablet_android"] = "http://www.roblox.com/asset/?id=6034848734";
		["mouse"] = "http://www.roblox.com/asset/?id=6034837797";
		["phone_android"] = "http://www.roblox.com/asset/?id=6034837793";
		["keyboard_arrow_left"] = "http://www.roblox.com/asset/?id=6034818375";
		["security"] = "http://www.roblox.com/asset/?id=6034837802";
		["dry_cleaning"] = "http://www.roblox.com/asset/?id=6034754456";
		["bakery_dining"] = "http://www.roblox.com/asset/?id=6034767610";
		["place"] = "http://www.roblox.com/asset/?id=6034503372";
		["run_circle"] = "http://www.roblox.com/asset/?id=6034503367";
		["local_post_office"] = "http://www.roblox.com/asset/?id=6034513883";
		["takeout_dining"] = "http://www.roblox.com/asset/?id=6034467808";
		["nightlife"] = "http://www.roblox.com/asset/?id=6034510003";
		["design_services"] = "http://www.roblox.com/asset/?id=6034754453";
		["celebration"] = "http://www.roblox.com/asset/?id=6034767613";
		["near_me_disabled"] = "http://www.roblox.com/asset/?id=6034509988";
		["add_location_alt"] = "http://www.roblox.com/asset/?id=6034483678";
		["directions_run"] = "http://www.roblox.com/asset/?id=6034754445";
		["local_fire_department"] = "http://www.roblox.com/asset/?id=6034684949";
		["add_road"] = "http://www.roblox.com/asset/?id=6034483677";
		["my_location"] = "http://www.roblox.com/asset/?id=6034509987";
		["dinner_dining"] = "http://www.roblox.com/asset/?id=6034754457";
		["local_airport"] = "http://www.roblox.com/asset/?id=6034687951";
		["zoom_out_map"] = "http://www.roblox.com/asset/?id=6035229856";
		["pin_drop"] = "http://www.roblox.com/asset/?id=6034470807";
		["subway"] = "http://www.roblox.com/asset/?id=6034467790";
		["electric_moped"] = "http://www.roblox.com/asset/?id=6034744027";
		["restaurant_menu"] = "http://www.roblox.com/asset/?id=6034503378";
		["local_gas_station"] = "http://www.roblox.com/asset/?id=6034684935";
		["local_cafe"] = "http://www.roblox.com/asset/?id=6034687954";
		["theater_comedy"] = "http://www.roblox.com/asset/?id=6034467796";
		["directions_bus"] = "http://www.roblox.com/asset/?id=6034754434";
		["hail"] = "http://www.roblox.com/asset/?id=6034744033";
		["satellite"] = "http://www.roblox.com/asset/?id=6034503370";
		["local_phone"] = "http://www.roblox.com/asset/?id=6034513884";
		["electric_bike"] = "http://www.roblox.com/asset/?id=6034744032";
		["local_see"] = "http://www.roblox.com/asset/?id=6034513887";
		["transit_enterexit"] = "http://www.roblox.com/asset/?id=6034467805";
		["local_convenience_store"] = "http://www.roblox.com/asset/?id=6034687956";
		["local_offer"] = "http://www.roblox.com/asset/?id=6034513891";
		["electric_car"] = "http://www.roblox.com/asset/?id=6034744029";
		["beenhere"] = "http://www.roblox.com/asset/?id=6034483675";
		["miscellaneous_services"] = "http://www.roblox.com/asset/?id=6034509993";
		["maps_ugc"] = "http://www.roblox.com/asset/?id=6034509992";
		["moped"] = "http://www.roblox.com/asset/?id=6034509999";
		["medical_services"] = "http://www.roblox.com/asset/?id=6034510001";
		["money"] = "http://www.roblox.com/asset/?id=6034509997";
		["transfer_within_a_station"] = "http://www.roblox.com/asset/?id=6034467809";
		["electrical_services"] = "http://www.roblox.com/asset/?id=6034744038";
		["museum"] = "http://www.roblox.com/asset/?id=6034510005";
		["add_location"] = "http://www.roblox.com/asset/?id=6034483672";
		["layers"] = "http://www.roblox.com/asset/?id=6034687957";
		["handyman"] = "http://www.roblox.com/asset/?id=6034744057";
		["local_pharmacy"] = "http://www.roblox.com/asset/?id=6034513903";
		["electric_rickshaw"] = "http://www.roblox.com/asset/?id=6034744043";
		["alt_route"] = "http://www.roblox.com/asset/?id=6034483670";
		["no_transfer"] = "http://www.roblox.com/asset/?id=6034503363";
		["pedal_bike"] = "http://www.roblox.com/asset/?id=6034503374";
		["directions_transit"] = "http://www.roblox.com/asset/?id=6034754436";
		["railway_alert"] = "http://www.roblox.com/asset/?id=6034470823";
		["local_police"] = "http://www.roblox.com/asset/?id=6034513895";
		["directions_car"] = "http://www.roblox.com/asset/?id=6034754441";
		["category"] = "http://www.roblox.com/asset/?id=6034767621";
		["attractions"] = "http://www.roblox.com/asset/?id=6034767620";
		["person_pin_circle"] = "http://www.roblox.com/asset/?id=6034503375";
		["cleaning_services"] = "http://www.roblox.com/asset/?id=6034767619";
		["terrain"] = "http://www.roblox.com/asset/?id=6034467794";
		["no_meals"] = "http://www.roblox.com/asset/?id=6034510024";
		["train"] = "http://www.roblox.com/asset/?id=6034467803";
		["delivery_dining"] = "http://www.roblox.com/asset/?id=6034767644";
		["pest_control"] = "http://www.roblox.com/asset/?id=6034470809";
		["directions"] = "http://www.roblox.com/asset/?id=6034754449";
		["atm"] = "http://www.roblox.com/asset/?id=6034767614";
		["rate_review"] = "http://www.roblox.com/asset/?id=6034503385";
		["local_bar"] = "http://www.roblox.com/asset/?id=6034687950";
		["local_drink"] = "http://www.roblox.com/asset/?id=6034687965";
		["directions_railway"] = "http://www.roblox.com/asset/?id=6034754433";
		["person_pin"] = "http://www.roblox.com/asset/?id=6034503364";
		["ev_station"] = "http://www.roblox.com/asset/?id=6034744037";
		["home_repair_service"] = "http://www.roblox.com/asset/?id=6034744064";
		["bus_alert"] = "http://www.roblox.com/asset/?id=6034767618";
		["agriculture"] = "http://www.roblox.com/asset/?id=6034483674";
		["volunteer_activism"] = "http://www.roblox.com/asset/?id=6034467799";
		["breakfast_dining"] = "http://www.roblox.com/asset/?id=6034483671";
		["layers_clear"] = "http://www.roblox.com/asset/?id=6034687975";
		["plumbing"] = "http://www.roblox.com/asset/?id=6034470800";
		["taxi_alert"] = "http://www.roblox.com/asset/?id=6034467792";
		["add_business"] = "http://www.roblox.com/asset/?id=6034483666";
		["badge"] = "http://www.roblox.com/asset/?id=6034767607";
		["edit_attributes"] = "http://www.roblox.com/asset/?id=6034754443";
		["directions_walk"] = "http://www.roblox.com/asset/?id=6034754448";
		["local_play"] = "http://www.roblox.com/asset/?id=6034513889";
		["bike_scooter"] = "http://www.roblox.com/asset/?id=6034483669";
		["two_wheeler"] = "http://www.roblox.com/asset/?id=6034467795";
		["local_florist"] = "http://www.roblox.com/asset/?id=6034684940";
		["local_hotel"] = "http://www.roblox.com/asset/?id=6034684939";
		["no_meals_ouline"] = "http://www.roblox.com/asset/?id=6034510025";
		["festival"] = "http://www.roblox.com/asset/?id=6034744031";
		["local_shipping"] = "http://www.roblox.com/asset/?id=6034684926";
		["directions_boat"] = "http://www.roblox.com/asset/?id=6034754442";
		["wrong_location"] = "http://www.roblox.com/asset/?id=6034467801";
		["restaurant"] = "http://www.roblox.com/asset/?id=6034503366";
		["directions_subway"] = "http://www.roblox.com/asset/?id=6034754440";
		["not_listed_location"] = "http://www.roblox.com/asset/?id=6034503380";
		["electric_scooter"] = "http://www.roblox.com/asset/?id=6034744041";
		["ramen_dining"] = "http://www.roblox.com/asset/?id=6034503377";
		["edit_road"] = "http://www.roblox.com/asset/?id=6034744035";
		["local_printshop"] = "http://www.roblox.com/asset/?id=6034513897";
		["map"] = "http://www.roblox.com/asset/?id=6034684930";
		["car_rental"] = "http://www.roblox.com/asset/?id=6034767641";
		["multiple_stop"] = "http://www.roblox.com/asset/?id=6034510026";
		["brunch_dining"] = "http://www.roblox.com/asset/?id=6034767611";
		["local_laundry_service"] = "http://www.roblox.com/asset/?id=6034684943";
		["set_meal"] = "http://www.roblox.com/asset/?id=6034503368";
		["local_car_wash"] = "http://www.roblox.com/asset/?id=6034687976";
		["pest_control_rodent"] = "http://www.roblox.com/asset/?id=6034470803";
		["local_pizza"] = "http://www.roblox.com/asset/?id=6034513885";
		["local_grocery_store"] = "http://www.roblox.com/asset/?id=6034684933";
		["traffic"] = "http://www.roblox.com/asset/?id=6034467797";
		["departure_board"] = "http://www.roblox.com/asset/?id=6034767615";
		["icecream"] = "http://www.roblox.com/asset/?id=6034687967";
		["navigation"] = "http://www.roblox.com/asset/?id=6034509984";
		["near_me"] = "http://www.roblox.com/asset/?id=6034509996";
		["fastfood"] = "http://www.roblox.com/asset/?id=6034744034";
		["local_library"] = "http://www.roblox.com/asset/?id=6034684931";
		["local_activity"] = "http://www.roblox.com/asset/?id=6034687955";
		["local_hospital"] = "http://www.roblox.com/asset/?id=6034684956";
		["menu_book"] = "http://www.roblox.com/asset/?id=6034509994";
		["directions_bike"] = "http://www.roblox.com/asset/?id=6034754459";
		["store_mall_directory"] = "http://www.roblox.com/asset/?id=6034470811";
		["trip_origin"] = "http://www.roblox.com/asset/?id=6034467804";
		["tram"] = "http://www.roblox.com/asset/?id=6034467806";
		["edit_location"] = "http://www.roblox.com/asset/?id=6034754439";
		["streetview"] = "http://www.roblox.com/asset/?id=6034470805";
		["hvac"] = "http://www.roblox.com/asset/?id=6034687960";
		["lunch_dining"] = "http://www.roblox.com/asset/?id=6034684928";
		["car_repair"] = "http://www.roblox.com/asset/?id=6034767617";
		["compass_calibration"] = "http://www.roblox.com/asset/?id=6034767623";
		["360"] = "http://www.roblox.com/asset/?id=6034767608";
		["flight"] = "http://www.roblox.com/asset/?id=6034744030";
		["local_mall"] = "http://www.roblox.com/asset/?id=6034684934";
		["hotel"] = "http://www.roblox.com/asset/?id=6034687977";
		["local_parking"] = "http://www.roblox.com/asset/?id=6034513893";
		["hardware"] = "http://www.roblox.com/asset/?id=6034744036";
		["local_dining"] = "http://www.roblox.com/asset/?id=6034687963";
		["park"] = "http://www.roblox.com/asset/?id=6034503369";
		["location_pin"] = "http://www.roblox.com/asset/?id=6034684937";
		["local_movies"] = "http://www.roblox.com/asset/?id=6034684936";
		["local_atm"] = "http://www.roblox.com/asset/?id=6034687953";
		["local_taxi"] = "http://www.roblox.com/asset/?id=6034684927";
		["brightness_low"] = "http://www.roblox.com/asset/?id=6034989542";
		["screen_lock_landscape"] = "http://www.roblox.com/asset/?id=6034996700";
		["graphic_eq"] = "http://www.roblox.com/asset/?id=6034989551";
		["screen_lock_rotation"] = "http://www.roblox.com/asset/?id=6034996710";
		["signal_cellular_4_bar"] = "http://www.roblox.com/asset/?id=6035030076";
		["airplanemode_inactive"] = "http://www.roblox.com/asset/?id=6034983848";
		["signal_wifi_0_bar"] = "http://www.roblox.com/asset/?id=6035030067";
		["battery_full"] = "http://www.roblox.com/asset/?id=6034983854";
		["gps_fixed"] = "http://www.roblox.com/asset/?id=6034989550";
		["brightness_high"] = "http://www.roblox.com/asset/?id=6034989541";
		["ad_units"] = "http://www.roblox.com/asset/?id=6034983845";
		["signal_cellular_alt"] = "http://www.roblox.com/asset/?id=6035030079";
		["bluetooth_connected"] = "http://www.roblox.com/asset/?id=6034983855";
		["wifi_tethering"] = "http://www.roblox.com/asset/?id=6035039430";
		["dvr"] = "http://www.roblox.com/asset/?id=6034989561";
		["screen_search_desktop"] = "http://www.roblox.com/asset/?id=6034996711";
		["network_wifi"] = "http://www.roblox.com/asset/?id=6034996712";
		["access_alarms"] = "http://www.roblox.com/asset/?id=6034983853";
		["nfc"] = "http://www.roblox.com/asset/?id=6034996698";
		["location_disabled"] = "http://www.roblox.com/asset/?id=6034996694";
		["signal_wifi_4_bar"] = "http://www.roblox.com/asset/?id=6035030077";
		["access_time"] = "http://www.roblox.com/asset/?id=6034983856";
		["mobile_off"] = "http://www.roblox.com/asset/?id=6034996702";
		["battery_unknown"] = "http://www.roblox.com/asset/?id=6034983842";
		["signal_cellular_null"] = "http://www.roblox.com/asset/?id=6035030075";
		["bluetooth_disabled"] = "http://www.roblox.com/asset/?id=6034989562";
		["developer_mode"] = "http://www.roblox.com/asset/?id=6034989549";
		["network_cell"] = "http://www.roblox.com/asset/?id=6034996709";
		["sd_storage"] = "http://www.roblox.com/asset/?id=6034996719";
		["signal_cellular_no_sim"] = "http://www.roblox.com/asset/?id=6035030078";
		["devices"] = "http://www.roblox.com/asset/?id=6034989540";
		["screen_rotation"] = "http://www.roblox.com/asset/?id=6034996701";
		["device_thermostat"] = "http://www.roblox.com/asset/?id=6034989544";
		["signal_wifi_off"] = "http://www.roblox.com/asset/?id=6035030074";
		["widgets"] = "http://www.roblox.com/asset/?id=6035039429";
		["bluetooth"] = "http://www.roblox.com/asset/?id=6034983880";
		["battery_charging_full"] = "http://www.roblox.com/asset/?id=6034983849";
		["mobile_friendly"] = "http://www.roblox.com/asset/?id=6034996699";
		["signal_cellular_0_bar"] = "http://www.roblox.com/asset/?id=6035030072";
		["storage"] = "http://www.roblox.com/asset/?id=6035030083";
		["send_to_mobile"] = "http://www.roblox.com/asset/?id=6034996697";
		["location_searching"] = "http://www.roblox.com/asset/?id=6034996695";
		["brightness_auto"] = "http://www.roblox.com/asset/?id=6034989545";
		["wifi_lock"] = "http://www.roblox.com/asset/?id=6035039428";
		["gps_not_fixed"] = "http://www.roblox.com/asset/?id=6034989547";
		["access_alarm"] = "http://www.roblox.com/asset/?id=6034983844";
		["battery_alert"] = "http://www.roblox.com/asset/?id=6034983843";
		["signal_cellular_off"] = "http://www.roblox.com/asset/?id=6035030084";
		["signal_cellular_connected_no_internet_4"] = "http://www.roblox.com/asset/?id=6035229858";
		["gps_off"] = "http://www.roblox.com/asset/?id=6034989548";
		["add_alarm"] = "http://www.roblox.com/asset/?id=6034983850";
		["brightness_medium"] = "http://www.roblox.com/asset/?id=6034989543";
		["usb"] = "http://www.roblox.com/asset/?id=6035030080";
		["airplanemode_active"] = "http://www.roblox.com/asset/?id=6034983864";
		["reset_tv"] = "http://www.roblox.com/asset/?id=6034996696";
		["wallpaper"] = "http://www.roblox.com/asset/?id=6035030102";
		["settings_system_daydream"] = "http://www.roblox.com/asset/?id=6035030081";
		["bluetooth_searching"] = "http://www.roblox.com/asset/?id=6034989553";
		["add_to_home_screen"] = "http://www.roblox.com/asset/?id=6034983858";
		["screen_lock_portrait"] = "http://www.roblox.com/asset/?id=6034996706";
		["data_usage"] = "http://www.roblox.com/asset/?id=6034989568";
		["_auto_delete"] = "http://www.roblox.com/asset/?id=6031071068";
		["_error"] = "http://www.roblox.com/asset/?id=6031071057";
		["_notification_important"] = "http://www.roblox.com/asset/?id=6031071056";
		["_add_alert"] = "http://www.roblox.com/asset/?id=6031071067";
		["_warning"] = "http://www.roblox.com/asset/?id=6031071053";
		["_error_outline"] = "http://www.roblox.com/asset/?id=6031071050";
		["check_box_outline_blank"] = "http://www.roblox.com/asset/?id=6031068420";
		["toggle_off"] = "http://www.roblox.com/asset/?id=6031068429";
		["indeterminate_check_box"] = "http://www.roblox.com/asset/?id=6031068445";
		["radio_button_checked"] = "http://www.roblox.com/asset/?id=6031068426";
		["toggle_on"] = "http://www.roblox.com/asset/?id=6031068430";
		["check_box"] = "http://www.roblox.com/asset/?id=6031068421";
		["radio_button_unchecked"] = "http://www.roblox.com/asset/?id=6031068433";
		["star"] = "http://www.roblox.com/asset/?id=6031068423";
		["star_border"] = "http://www.roblox.com/asset/?id=6031068425";
		["star_half"] = "http://www.roblox.com/asset/?id=6031068427";
		["star_outline"] = "http://www.roblox.com/asset/?id=6031068428";
		["multiline_chart"] = "http://www.roblox.com/asset/?id=6034941721";
		["pie_chart"] = "http://www.roblox.com/asset/?id=6034973076";
		["format_line_spacing"] = "http://www.roblox.com/asset/?id=6034910905";
		["format_align_left"] = "http://www.roblox.com/asset/?id=6034900727";
		["linear_scale"] = "http://www.roblox.com/asset/?id=6034941707";
		["insert_photo"] = "http://www.roblox.com/asset/?id=6034941703";
		["scatter_plot"] = "http://www.roblox.com/asset/?id=6034973094";
		["post_add"] = "http://www.roblox.com/asset/?id=6034973083";
		["format_textdirection_r_to_l"] = "http://www.roblox.com/asset/?id=6034925623";
		["format_size"] = "http://www.roblox.com/asset/?id=6034910908";
		["format_color_fill"] = "http://www.roblox.com/asset/?id=6034910903";
		["format_paint"] = "http://www.roblox.com/asset/?id=6034925618";
		["format_underlined"] = "http://www.roblox.com/asset/?id=6034925627";
		["format_shapes"] = "http://www.roblox.com/asset/?id=6034910909";
		["title"] = "http://www.roblox.com/asset/?id=6034934042";
		["highlight"] = "http://www.roblox.com/asset/?id=6034925617";
		["bar_chart"] = "http://www.roblox.com/asset/?id=6034898096";
		["format_indent_increase"] = "http://www.roblox.com/asset/?id=6034900724";
		["merge_type"] = "http://www.roblox.com/asset/?id=6034941705";
		["bubble_chart"] = "http://www.roblox.com/asset/?id=6034925612";
		["publish"] = "http://www.roblox.com/asset/?id=6034973085";
		["format_indent_decrease"] = "http://www.roblox.com/asset/?id=6034900733";
		["margin"] = "http://www.roblox.com/asset/?id=6034941701";
		["table_rows"] = "http://www.roblox.com/asset/?id=6034934025";
		["stacked_line_chart"] = "http://www.roblox.com/asset/?id=6034934039";
		["border_clear"] = "http://www.roblox.com/asset/?id=6034898135";
		["border_color"] = "http://www.roblox.com/asset/?id=6034898100";
		["border_inner"] = "http://www.roblox.com/asset/?id=6034898131";
		["insert_chart"] = "http://www.roblox.com/asset/?id=6034925628";
		["border_top"] = "http://www.roblox.com/asset/?id=6034900726";
		["padding"] = "http://www.roblox.com/asset/?id=6034973078";
		["border_vertical"] = "http://www.roblox.com/asset/?id=6034900725";
		["score"] = "http://www.roblox.com/asset/?id=6034934041";
		["border_right"] = "http://www.roblox.com/asset/?id=6034898120";
		["add_chart"] = "http://www.roblox.com/asset/?id=6034898093";
		["space_bar"] = "http://www.roblox.com/asset/?id=6034934037";
		["border_outer"] = "http://www.roblox.com/asset/?id=6034898104";
		["mode_comment"] = "http://www.roblox.com/asset/?id=6034941700";
		["attach_money"] = "http://www.roblox.com/asset/?id=6034898098";
		["drag_handle"] = "http://www.roblox.com/asset/?id=6034910907";
		["format_align_right"] = "http://www.roblox.com/asset/?id=6034900723";
		["pie_chart_outlined"] = "http://www.roblox.com/asset/?id=6034973077";
		["horizontal_rule"] = "http://www.roblox.com/asset/?id=6034925610";
		["border_all"] = "http://www.roblox.com/asset/?id=6034898101";
		["border_style"] = "http://www.roblox.com/asset/?id=6034898097";
		["insert_comment"] = "http://www.roblox.com/asset/?id=6034925609";
		["vertical_align_top"] = "http://www.roblox.com/asset/?id=6034973080";
		["vertical_align_center"] = "http://www.roblox.com/asset/?id=6034934051";
		["format_color_text"] = "http://www.roblox.com/asset/?id=6034910910";
		["format_quote"] = "http://www.roblox.com/asset/?id=6034925629";
		["height"] = "http://www.roblox.com/asset/?id=6034925613";
		["add_comment"] = "http://www.roblox.com/asset/?id=6034898128";
		["format_strikethrough"] = "http://www.roblox.com/asset/?id=6034910904";
		["strikethrough_s"] = "http://www.roblox.com/asset/?id=6034934030";
		["border_left"] = "http://www.roblox.com/asset/?id=6034898099";
		["format_list_bulleted"] = "http://www.roblox.com/asset/?id=6034925620";
		["format_italic"] = "http://www.roblox.com/asset/?id=6034910912";
		["format_list_numbered"] = "http://www.roblox.com/asset/?id=6034925622";
		["attach_file"] = "http://www.roblox.com/asset/?id=6034898102";
		["wrap_text"] = "http://www.roblox.com/asset/?id=6034973118";
		["insert_invitation"] = "http://www.roblox.com/asset/?id=6034973091";
		["format_list_numbered_rtl"] = "http://www.roblox.com/asset/?id=6034910906";
		["border_horizontal"] = "http://www.roblox.com/asset/?id=6034898105";
		["format_align_center"] = "http://www.roblox.com/asset/?id=6034900718";
		["format_textdirection_l_to_r"] = "http://www.roblox.com/asset/?id=6034925619";
		["show_chart"] = "http://www.roblox.com/asset/?id=6034934032";
		["insert_chart_outlined"] = "http://www.roblox.com/asset/?id=6034925606";
		["vertical_align_bottom"] = "http://www.roblox.com/asset/?id=6034934023";
		["subscript"] = "http://www.roblox.com/asset/?id=6034934059";
		["format_align_justify"] = "http://www.roblox.com/asset/?id=6034900721";
		["format_clear"] = "http://www.roblox.com/asset/?id=6034910902";
		["notes"] = "http://www.roblox.com/asset/?id=6034973084";
		["insert_drive_file"] = "http://www.roblox.com/asset/?id=6034941697";
		["functions"] = "http://www.roblox.com/asset/?id=6034925614";
		["insert_emoticon"] = "http://www.roblox.com/asset/?id=6034973079";
		["insert_link"] = "http://www.roblox.com/asset/?id=6034973074";
		["format_color_reset"] = "http://www.roblox.com/asset/?id=6034900743";
		["monetization_on"] = "http://www.roblox.com/asset/?id=6034973115";
		["short_text"] = "http://www.roblox.com/asset/?id=6034934035";
		["mode_edit"] = "http://www.roblox.com/asset/?id=6034941708";
		["superscript"] = "http://www.roblox.com/asset/?id=6034934034";
		["table_chart"] = "http://www.roblox.com/asset/?id=6034973081";
		["format_bold"] = "http://www.roblox.com/asset/?id=6034900732";
		["money_off"] = "http://www.roblox.com/asset/?id=6034973088";
		["border_bottom"] = "http://www.roblox.com/asset/?id=6034898094";
		["text_fields"] = "http://www.roblox.com/asset/?id=6034934040";
		["note"] = "http://www.roblox.com/asset/?id=6026663734";
		["shuffle"] = "http://www.roblox.com/asset/?id=6026667003";
		["library_books"] = "http://www.roblox.com/asset/?id=6026660085";
		["library_music"] = "http://www.roblox.com/asset/?id=6026660075";
		["surround_sound"] = "http://www.roblox.com/asset/?id=6026671209";
		["forward_30"] = "http://www.roblox.com/asset/?id=6026660088";
		["music_video"] = "http://www.roblox.com/asset/?id=6026663704";
		["videocam_off"] = "http://www.roblox.com/asset/?id=6026671212";
		["control_camera"] = "http://www.roblox.com/asset/?id=6026647916";
		["explicit"] = "http://www.roblox.com/asset/?id=6026647913";
		["3k_plus"] = "http://www.roblox.com/asset/?id=6026681598";
		["fiber_pin"] = "http://www.roblox.com/asset/?id=6026660064";
		["skip_previous"] = "http://www.roblox.com/asset/?id=6026667011";
		["pause_circle_filled"] = "http://www.roblox.com/asset/?id=6026663718";
		["video_settings"] = "http://www.roblox.com/asset/?id=6026671211";
		["movie"] = "http://www.roblox.com/asset/?id=6026660081";
		["add_to_queue"] = "http://www.roblox.com/asset/?id=6026647903";
		["6k"] = "http://www.roblox.com/asset/?id=6026681579";
		["web_asset"] = "http://www.roblox.com/asset/?id=6026671239";
		["play_circle_outline"] = "http://www.roblox.com/asset/?id=6026663726";
		["volume_off"] = "http://www.roblox.com/asset/?id=6026671224";
		["mic_off"] = "http://www.roblox.com/asset/?id=6026660076";
		["featured_play_list"] = "http://www.roblox.com/asset/?id=6026647932";
		["pause_circle_outline"] = "http://www.roblox.com/asset/?id=6026663701";
		["slow_motion_video"] = "http://www.roblox.com/asset/?id=6026681583";
		["7k"] = "http://www.roblox.com/asset/?id=6026681584";
		["playlist_add"] = "http://www.roblox.com/asset/?id=6026663728";
		["fiber_smart_record"] = "http://www.roblox.com/asset/?id=6026660080";
		["8k"] = "http://www.roblox.com/asset/?id=6026643014";
		["hd"] = "http://www.roblox.com/asset/?id=6026660065";
		["repeat_one_on"] = "http://www.roblox.com/asset/?id=6026666992";
		["recent_actors"] = "http://www.roblox.com/asset/?id=6026663773";
		["fiber_new"] = "http://www.roblox.com/asset/?id=6026647930";
		["fiber_dvr"] = "http://www.roblox.com/asset/?id=6026647912";
		["hearing_disabled"] = "http://www.roblox.com/asset/?id=6026660068";
		["forward_10"] = "http://www.roblox.com/asset/?id=6026660062";
		["4k_plus"] = "http://www.roblox.com/asset/?id=6026643005";
		["repeat_one"] = "http://www.roblox.com/asset/?id=6026681590";
		["equalizer"] = "http://www.roblox.com/asset/?id=6026647906";
		["stop"] = "http://www.roblox.com/asset/?id=6026681576";
		["2k"] = "http://www.roblox.com/asset/?id=6026643032";
		["playlist_add_check"] = "http://www.roblox.com/asset/?id=6026663727";
		["not_interested"] = "http://www.roblox.com/asset/?id=6026663743";
		["videocam"] = "http://www.roblox.com/asset/?id=6026671213";
		["sort_by_alpha"] = "http://www.roblox.com/asset/?id=6026667009";
		["library_add"] = "http://www.roblox.com/asset/?id=6026660063";
		["stop_circle"] = "http://www.roblox.com/asset/?id=6026681577";
		["pause"] = "http://www.roblox.com/asset/?id=6026663719";
		["new_releases"] = "http://www.roblox.com/asset/?id=6026663730";
		["album"] = "http://www.roblox.com/asset/?id=6026647905";
		["sd"] = "http://www.roblox.com/asset/?id=6026681582";
		["volume_up"] = "http://www.roblox.com/asset/?id=6026671215";
		["replay_5"] = "http://www.roblox.com/asset/?id=6026666993";
		["high_quality"] = "http://www.roblox.com/asset/?id=6026660059";
		["shuffle_on"] = "http://www.roblox.com/asset/?id=6026666996";
		["play_arrow"] = "http://www.roblox.com/asset/?id=6026663699";
		["snooze"] = "http://www.roblox.com/asset/?id=6026667006";
		["closed_caption_disabled"] = "http://www.roblox.com/asset/?id=6026647900";
		["subscriptions"] = "http://www.roblox.com/asset/?id=6026671207";
		["skip_next"] = "http://www.roblox.com/asset/?id=6026667005";
		["branding_watermark"] = "http://www.roblox.com/asset/?id=6026647911";
		["speed"] = "http://www.roblox.com/asset/?id=6026681578";
		["art_track"] = "http://www.roblox.com/asset/?id=6026647908";
		["3k"] = "http://www.roblox.com/asset/?id=6026681574";
		["4k"] = "http://www.roblox.com/asset/?id=6026643017";
		["volume_mute"] = "http://www.roblox.com/asset/?id=6026671214";
		["playlist_play"] = "http://www.roblox.com/asset/?id=6026663723";
		["remove_from_queue"] = "http://www.roblox.com/asset/?id=6026663771";
		["fast_forward"] = "http://www.roblox.com/asset/?id=6026647902";
		["play_disabled"] = "http://www.roblox.com/asset/?id=6026663702";
		["fast_rewind"] = "http://www.roblox.com/asset/?id=6026647942";
		["5k"] = "http://www.roblox.com/asset/?id=6026681575";
		["replay_10"] = "http://www.roblox.com/asset/?id=6026667007";
		["video_library"] = "http://www.roblox.com/asset/?id=6026671208";
		["loop"] = "http://www.roblox.com/asset/?id=6026660087";
		["replay_circle_filled"] = "http://www.roblox.com/asset/?id=6026667002";
		["5g"] = "http://www.roblox.com/asset/?id=6026643007";
		["library_add_check"] = "http://www.roblox.com/asset/?id=6026660083";
		["repeat"] = "http://www.roblox.com/asset/?id=6026666998";
		["queue_play_next"] = "http://www.roblox.com/asset/?id=6026663700";
		["forward_5"] = "http://www.roblox.com/asset/?id=6026660067";
		["web"] = "http://www.roblox.com/asset/?id=6026671234";
		["mic_none"] = "http://www.roblox.com/asset/?id=6026660066";
		["queue"] = "http://www.roblox.com/asset/?id=6026663724";
		["closed_caption_off"] = "http://www.roblox.com/asset/?id=6026647943";
		["hearing"] = "http://www.roblox.com/asset/?id=6026660060";
		["queue_music"] = "http://www.roblox.com/asset/?id=6026663725";
		["airplay"] = "http://www.roblox.com/asset/?id=6026647929";
		["9k"] = "http://www.roblox.com/asset/?id=6026643013";
		["video_label"] = "http://www.roblox.com/asset/?id=6026671204";
		["8k_plus"] = "http://www.roblox.com/asset/?id=6026643003";
		["play_circle_filled"] = "http://www.roblox.com/asset/?id=6026663705";
		["1k"] = "http://www.roblox.com/asset/?id=6026643002";
		["fiber_manual_record"] = "http://www.roblox.com/asset/?id=6026647909";
		["closed_caption"] = "http://www.roblox.com/asset/?id=6026647896";
		["subtitles"] = "http://www.roblox.com/asset/?id=6026671203";
		["featured_video"] = "http://www.roblox.com/asset/?id=6026647910";
		["replay_30"] = "http://www.roblox.com/asset/?id=6026667010";
		["10k"] = "http://www.roblox.com/asset/?id=6026643035";
		["5k_plus"] = "http://www.roblox.com/asset/?id=6026643028";
		["6k_plus"] = "http://www.roblox.com/asset/?id=6026643019";
		["replay"] = "http://www.roblox.com/asset/?id=6026666999";
		["repeat_on"] = "http://www.roblox.com/asset/?id=6026666994";
		["1k_plus"] = "http://www.roblox.com/asset/?id=6026681580";
		["2k_plus"] = "http://www.roblox.com/asset/?id=6026681588";
		["games"] = "http://www.roblox.com/asset/?id=6026660074";
		["volume_down"] = "http://www.roblox.com/asset/?id=6026671206";
		["mic"] = "http://www.roblox.com/asset/?id=6026660078";
		["call_to_action"] = "http://www.roblox.com/asset/?id=6026647898";
		["7k_plus"] = "http://www.roblox.com/asset/?id=6026643012";
		["av_timer"] = "http://www.roblox.com/asset/?id=6026647934";
		["9k_plus"] = "http://www.roblox.com/asset/?id=6026681585";
		["radio"] = "http://www.roblox.com/asset/?id=6026663698";
		["10mp"] = "http://www.roblox.com/asset/?id=6031328149";
		["20mp"] = "http://www.roblox.com/asset/?id=6031488940";
		["wb_twighlight"] = "http://www.roblox.com/asset/?id=6034412760";
		["movie_creation"] = "http://www.roblox.com/asset/?id=6034323681";
		["crop_portrait"] = "http://www.roblox.com/asset/?id=6031630198";
		["filter_5"] = "http://www.roblox.com/asset/?id=6031597518";
		["broken_image"] = "http://www.roblox.com/asset/?id=6031471480";
		["flip_camera_android"] = "http://www.roblox.com/asset/?id=6034333280";
		["flip_camera_ios"] = "http://www.roblox.com/asset/?id=6034333267";
		["circle"] = "http://www.roblox.com/asset/?id=6031625146";
		["photo_camera_front"] = "http://www.roblox.com/asset/?id=6031771000";
		["assistant"] = "http://www.roblox.com/asset/?id=6031360356";
		["face_retouching_natural"] = "http://www.roblox.com/asset/?id=6034333274";
		["palette"] = "http://www.roblox.com/asset/?id=6034316009";
		["nature_people"] = "http://www.roblox.com/asset/?id=6034323711";
		["14mp"] = "http://www.roblox.com/asset/?id=6031328161";
		["gradient"] = "http://www.roblox.com/asset/?id=6034333261";
		["filter_4"] = "http://www.roblox.com/asset/?id=6031597512";
		["panorama_wide_angle_select"] = "http://www.roblox.com/asset/?id=6031770990";
		["photo"] = "http://www.roblox.com/asset/?id=6031770993";
		["grid_off"] = "http://www.roblox.com/asset/?id=6034333286";
		["leak_add"] = "http://www.roblox.com/asset/?id=6034407074";
		["landscape"] = "http://www.roblox.com/asset/?id=6034407069";
		["exposure_plus_1"] = "http://www.roblox.com/asset/?id=6034328970";
		["slideshow"] = "http://www.roblox.com/asset/?id=6031754546";
		["camera_alt"] = "http://www.roblox.com/asset/?id=6031572307";
		["audiotrack"] = "http://www.roblox.com/asset/?id=6031471489";
		["filter_none"] = "http://www.roblox.com/asset/?id=6031600815";
		["blur_off"] = "http://www.roblox.com/asset/?id=6031371055";
		["crop_16_9"] = "http://www.roblox.com/asset/?id=6031630205";
		["blur_on"] = "http://www.roblox.com/asset/?id=6031371068";
		["brightness_4"] = "http://www.roblox.com/asset/?id=6031471483";
		["details"] = "http://www.roblox.com/asset/?id=6034328968";
		["panorama_horizontal"] = "http://www.roblox.com/asset/?id=6034315966";
		["camera_rear"] = "http://www.roblox.com/asset/?id=6031572316";
		["hdr_weak"] = "http://www.roblox.com/asset/?id=6034407083";
		["collections"] = "http://www.roblox.com/asset/?id=6031625145";
		["hdr_enhanced_select"] = "http://www.roblox.com/asset/?id=6034333281";
		["adjust"] = "http://www.roblox.com/asset/?id=6031339048";
		["burst_mode"] = "http://www.roblox.com/asset/?id=6031572306";
		["nature"] = "http://www.roblox.com/asset/?id=6034323695";
		["brightness_6"] = "http://www.roblox.com/asset/?id=6031572309";
		["19mp"] = "http://www.roblox.com/asset/?id=6031339054";
		["grain"] = "http://www.roblox.com/asset/?id=6034333288";
		["receipt_long"] = "http://www.roblox.com/asset/?id=6031763428";
		["photo_filter"] = "http://www.roblox.com/asset/?id=6031770992";
		["edit"] = "http://www.roblox.com/asset/?id=6034328955";
		["healing"] = "http://www.roblox.com/asset/?id=6034407071";
		["exposure_neg_1"] = "http://www.roblox.com/asset/?id=6034328957";
		["exposure"] = "http://www.roblox.com/asset/?id=6034328962";
		["wb_shade"] = "http://www.roblox.com/asset/?id=6034315974";
		["compare"] = "http://www.roblox.com/asset/?id=6031625151";
		["cases"] = "http://www.roblox.com/asset/?id=6031572324";
		["timer_3"] = "http://www.roblox.com/asset/?id=6031754540";
		["exposure_plus_2"] = "http://www.roblox.com/asset/?id=6034328961";
		["12mp"] = "http://www.roblox.com/asset/?id=6031328140";
		["22mp"] = "http://www.roblox.com/asset/?id=6031360353";
		["timer_off"] = "http://www.roblox.com/asset/?id=6031734881";
		["auto_stories"] = "http://www.roblox.com/asset/?id=6031360360";
		["rotate_left"] = "http://www.roblox.com/asset/?id=6031763427";
		["wb_iridescent"] = "http://www.roblox.com/asset/?id=6034315972";
		["shutter_speed"] = "http://www.roblox.com/asset/?id=6031763443";
		["switch_video"] = "http://www.roblox.com/asset/?id=6031754536";
		["23mp"] = "http://www.roblox.com/asset/?id=6031339045";
		["euro"] = "http://www.roblox.com/asset/?id=6034328963";
		["15mp"] = "http://www.roblox.com/asset/?id=6031328158";
		["filter_center_focus"] = "http://www.roblox.com/asset/?id=6031600817";
		["photo_library"] = "http://www.roblox.com/asset/?id=6031770998";
		["mp"] = "http://www.roblox.com/asset/?id=6034323674";
		["looks_4"] = "http://www.roblox.com/asset/?id=6034407089";
		["filter_2"] = "http://www.roblox.com/asset/?id=6031597521";
		["crop_3_2"] = "http://www.roblox.com/asset/?id=6034328956";
		["auto_fix_normal"] = "http://www.roblox.com/asset/?id=6031371074";
		["auto_fix_off"] = "http://www.roblox.com/asset/?id=6031360381";
		["wb_auto"] = "http://www.roblox.com/asset/?id=6031734875";
		["switch_camera"] = "http://www.roblox.com/asset/?id=6031754550";
		["filter_vintage"] = "http://www.roblox.com/asset/?id=6031600811";
		["photo_size_select_small"] = "http://www.roblox.com/asset/?id=6031763457";
		["blur_linear"] = "http://www.roblox.com/asset/?id=6031488930";
		["hdr_on"] = "http://www.roblox.com/asset/?id=6034333279";
		["tag_faces"] = "http://www.roblox.com/asset/?id=6031754560";
		["21mp"] = "http://www.roblox.com/asset/?id=6031339065";
		["camera"] = "http://www.roblox.com/asset/?id=6031572312";
		["image_aspect_ratio"] = "http://www.roblox.com/asset/?id=6034407073";
		["filter_b_and_w"] = "http://www.roblox.com/asset/?id=6031600824";
		["crop_landscape"] = "http://www.roblox.com/asset/?id=6031630202";
		["13mp"] = "http://www.roblox.com/asset/?id=6031328137";
		["grid_on"] = "http://www.roblox.com/asset/?id=6034333276";
		["motion_photos_pause"] = "http://www.roblox.com/asset/?id=6034323668";
		["filter_6"] = "http://www.roblox.com/asset/?id=6031597524";
		["linked_camera"] = "http://www.roblox.com/asset/?id=6034407082";
		["panorama_fish_eye"] = "http://www.roblox.com/asset/?id=6034315969";
		["panorama"] = "http://www.roblox.com/asset/?id=6034315955";
		["color_lens"] = "http://www.roblox.com/asset/?id=6031625148";
		["lens"] = "http://www.roblox.com/asset/?id=6034407081";
		["crop_din"] = "http://www.roblox.com/asset/?id=6031630208";
		["exposure_neg_2"] = "http://www.roblox.com/asset/?id=6034328973";
		["mic_external_off"] = "http://www.roblox.com/asset/?id=6034323672";
		["crop_free"] = "http://www.roblox.com/asset/?id=6031630212";
		["crop_original"] = "http://www.roblox.com/asset/?id=6031630204";
		["panorama_photosphere_select"] = "http://www.roblox.com/asset/?id=6034315975";
		["photo_size_select_actual"] = "http://www.roblox.com/asset/?id=6031771012";
		["leak_remove"] = "http://www.roblox.com/asset/?id=6034407080";
		["collections_bookmark"] = "http://www.roblox.com/asset/?id=6034328965";
		["straighten"] = "http://www.roblox.com/asset/?id=6031754545";
		["timelapse"] = "http://www.roblox.com/asset/?id=6031754541";
		["picture_as_pdf"] = "http://www.roblox.com/asset/?id=6031763425";
		["crop_rotate"] = "http://www.roblox.com/asset/?id=6031630203";
		["control_point_duplicate"] = "http://www.roblox.com/asset/?id=6034328959";
		["photo_camera_back"] = "http://www.roblox.com/asset/?id=6031771007";
		["looks_3"] = "http://www.roblox.com/asset/?id=6034407088";
		["motion_photos_off"] = "http://www.roblox.com/asset/?id=6034323670";
		["rotate_right"] = "http://www.roblox.com/asset/?id=6031763429";
		["view_compact"] = "http://www.roblox.com/asset/?id=6031734878";
		["crop_7_5"] = "http://www.roblox.com/asset/?id=6031630197";
		["style"] = "http://www.roblox.com/asset/?id=6031754538";
		["exposure_zero"] = "http://www.roblox.com/asset/?id=6034329000";
		["camera_front"] = "http://www.roblox.com/asset/?id=6031572318";
		["hdr_strong"] = "http://www.roblox.com/asset/?id=6034333272";
		["view_comfy"] = "http://www.roblox.com/asset/?id=6031734876";
		["panorama_vertical"] = "http://www.roblox.com/asset/?id=6034315963";
		["panorama_vertical_select"] = "http://www.roblox.com/asset/?id=6034315961";
		["looks_two"] = "http://www.roblox.com/asset/?id=6034412757";
		["filter_drama"] = "http://www.roblox.com/asset/?id=6031600813";
		["center_focus_strong"] = "http://www.roblox.com/asset/?id=6031625147";
		["18mp"] = "http://www.roblox.com/asset/?id=6031339064";
		["7mp"] = "http://www.roblox.com/asset/?id=6031328139";
		["wb_sunny"] = "http://www.roblox.com/asset/?id=6034412758";
		["filter_9_plus"] = "http://www.roblox.com/asset/?id=6031600812";
		["crop"] = "http://www.roblox.com/asset/?id=6034328964";
		["vignette"] = "http://www.roblox.com/asset/?id=6031734905";
		["brightness_2"] = "http://www.roblox.com/asset/?id=6031488938";
		["crop_square"] = "http://www.roblox.com/asset/?id=6031630222";
		["looks_5"] = "http://www.roblox.com/asset/?id=6034412764";
		["flip"] = "http://www.roblox.com/asset/?id=6034333275";
		["looks_one"] = "http://www.roblox.com/asset/?id=6034412761";
		["flash_off"] = "http://www.roblox.com/asset/?id=6034333270";
		["hdr_off"] = "http://www.roblox.com/asset/?id=6034333266";
		["photo_album"] = "http://www.roblox.com/asset/?id=6031770989";
		["motion_photos_paused"] = "http://www.roblox.com/asset/?id=6034323675";
		["photo_camera"] = "http://www.roblox.com/asset/?id=6031770997";
		["2mp"] = "http://www.roblox.com/asset/?id=6031328138";
		["3mp"] = "http://www.roblox.com/asset/?id=6031328136";
		["24mp"] = "http://www.roblox.com/asset/?id=6031360352";
		["filter_9"] = "http://www.roblox.com/asset/?id=6031597534";
		["6mp"] = "http://www.roblox.com/asset/?id=6031328131";
		["remove_red_eye"] = "http://www.roblox.com/asset/?id=6031763426";
		["4mp"] = "http://www.roblox.com/asset/?id=6031328152";
		["add_a_photo"] = "http://www.roblox.com/asset/?id=6031339049";
		["filter_3"] = "http://www.roblox.com/asset/?id=6031597513";
		["crop_5_4"] = "http://www.roblox.com/asset/?id=6034328960";
		["8mp"] = "http://www.roblox.com/asset/?id=6031328133";
		["camera_roll"] = "http://www.roblox.com/asset/?id=6031572314";
		["panorama_wide_angle"] = "http://www.roblox.com/asset/?id=6031770995";
		["transform"] = "http://www.roblox.com/asset/?id=6031734873";
		["flare"] = "http://www.roblox.com/asset/?id=6031600816";
		["image_search"] = "http://www.roblox.com/asset/?id=6034407084";
		["auto_awesome"] = "http://www.roblox.com/asset/?id=6031360365";
		["motion_photos_on"] = "http://www.roblox.com/asset/?id=6034323669";
		["rotate_90_degrees_ccw"] = "http://www.roblox.com/asset/?id=6031763456";
		["filter_1"] = "http://www.roblox.com/asset/?id=6031597511";
		["filter_tilt_shift"] = "http://www.roblox.com/asset/?id=6031600814";
		["image"] = "http://www.roblox.com/asset/?id=6034407078";
		["center_focus_weak"] = "http://www.roblox.com/asset/?id=6031625144";
		["blur_circular"] = "http://www.roblox.com/asset/?id=6031488945";
		["bedtime"] = "http://www.roblox.com/asset/?id=6031371054";
		["auto_fix_high"] = "http://www.roblox.com/asset/?id=6031360355";
		["monochrome_photos"] = "http://www.roblox.com/asset/?id=6034323678";
		["flash_auto"] = "http://www.roblox.com/asset/?id=6034333287";
		["5mp"] = "http://www.roblox.com/asset/?id=6031328144";
		["photo_size_select_large"] = "http://www.roblox.com/asset/?id=6031763423";
		["assistant_photo"] = "http://www.roblox.com/asset/?id=6031339052";
		["animation"] = "http://www.roblox.com/asset/?id=6031625150";
		["looks"] = "http://www.roblox.com/asset/?id=6034407096";
		["17mp"] = "http://www.roblox.com/asset/?id=6031339055";
		["panorama_horizontal_select"] = "http://www.roblox.com/asset/?id=6034315965";
		["flash_on"] = "http://www.roblox.com/asset/?id=6034333271";
		["iso"] = "http://www.roblox.com/asset/?id=6034407106";
		["music_note"] = "http://www.roblox.com/asset/?id=6034323673";
		["music_off"] = "http://www.roblox.com/asset/?id=6034323679";
		["navigate_next"] = "http://www.roblox.com/asset/?id=6034315956";
		["timer"] = "http://www.roblox.com/asset/?id=6031754564";
		["loupe"] = "http://www.roblox.com/asset/?id=6034412770";
		["navigate_before"] = "http://www.roblox.com/asset/?id=6034323696";
		["brightness_1"] = "http://www.roblox.com/asset/?id=6031471488";
		["brightness_7"] = "http://www.roblox.com/asset/?id=6031471491";
		["tonality"] = "http://www.roblox.com/asset/?id=6031734891";
		["brush"] = "http://www.roblox.com/asset/?id=6031572320";
		["colorize"] = "http://www.roblox.com/asset/?id=6031625161";
		["filter_7"] = "http://www.roblox.com/asset/?id=6031597515";
		["16mp"] = "http://www.roblox.com/asset/?id=6031328168";
		["timer_10"] = "http://www.roblox.com/asset/?id=6031734880";
		["portrait"] = "http://www.roblox.com/asset/?id=6031763434";
		["tune"] = "http://www.roblox.com/asset/?id=6031734877";
		["image_not_supported"] = "http://www.roblox.com/asset/?id=6034407076";
		["wb_cloudy"] = "http://www.roblox.com/asset/?id=6031734907";
		["auto_awesome_motion"] = "http://www.roblox.com/asset/?id=6031360370";
		["filter_8"] = "http://www.roblox.com/asset/?id=6031597532";
		["brightness_5"] = "http://www.roblox.com/asset/?id=6031471479";
		["movie_filter"] = "http://www.roblox.com/asset/?id=6034323687";
		["add_photo_alternate"] = "http://www.roblox.com/asset/?id=6031471484";
		["add_to_photos"] = "http://www.roblox.com/asset/?id=6031371075";
		["texture"] = "http://www.roblox.com/asset/?id=6031754553";
		["11mp"] = "http://www.roblox.com/asset/?id=6031328141";
		["mic_external_on"] = "http://www.roblox.com/asset/?id=6034323671";
		["looks_6"] = "http://www.roblox.com/asset/?id=6034412759";
		["dehaze"] = "http://www.roblox.com/asset/?id=6031630200";
		["control_point"] = "http://www.roblox.com/asset/?id=6031625131";
		["panorama_photosphere"] = "http://www.roblox.com/asset/?id=6034412763";
		["filter_frames"] = "http://www.roblox.com/asset/?id=6031600833";
		["auto_awesome_mosaic"] = "http://www.roblox.com/asset/?id=6031371053";
		["9mp"] = "http://www.roblox.com/asset/?id=6031328146";
		["filter"] = "http://www.roblox.com/asset/?id=6031597514";
		["brightness_3"] = "http://www.roblox.com/asset/?id=6031572317";
		["dirty_lens"] = "http://www.roblox.com/asset/?id=6034328967";
		["wb_incandescent"] = "http://www.roblox.com/asset/?id=6034316010";
		["filter_hdr"] = "http://www.roblox.com/asset/?id=6031600819";
		["textsms"] = "http://www.roblox.com/asset/?id=6035202006";
		["comment"] = "http://www.roblox.com/asset/?id=6035181871";
		["call_end"] = "http://www.roblox.com/asset/?id=6035173845";
		["qr_code_scanner"] = "http://www.roblox.com/asset/?id=6035202022";
		["phonelink_setup"] = "http://www.roblox.com/asset/?id=6035202025";
		["call_merge"] = "http://www.roblox.com/asset/?id=6035173843";
		["phonelink_erase"] = "http://www.roblox.com/asset/?id=6035202085";
		["contact_mail"] = "http://www.roblox.com/asset/?id=6035181868";
		["contact_phone"] = "http://www.roblox.com/asset/?id=6035181861";
		["screen_share"] = "http://www.roblox.com/asset/?id=6035202008";
		["present_to_all"] = "http://www.roblox.com/asset/?id=6035202020";
		["stay_primary_portrait"] = "http://www.roblox.com/asset/?id=6035202009";
		["message"] = "http://www.roblox.com/asset/?id=6035202033";
		["sentiment_satisfied_alt"] = "http://www.roblox.com/asset/?id=6035202069";
		["stay_current_portrait"] = "http://www.roblox.com/asset/?id=6035202004";
		["voicemail"] = "http://www.roblox.com/asset/?id=6035202019";
		["business"] = "http://www.roblox.com/asset/?id=6035173853";
		["mail_outline"] = "http://www.roblox.com/asset/?id=6035190844";
		["vpn_key"] = "http://www.roblox.com/asset/?id=6035202034";
		["forward_to_inbox"] = "http://www.roblox.com/asset/?id=6035190840";
		["contacts"] = "http://www.roblox.com/asset/?id=6035181864";
		["phonelink_ring"] = "http://www.roblox.com/asset/?id=6035202066";
		["domain_disabled"] = "http://www.roblox.com/asset/?id=6035181862";
		["person_add_disabled"] = "http://www.roblox.com/asset/?id=6035202007";
		["stay_primary_landscape"] = "http://www.roblox.com/asset/?id=6035202026";
		["alternate_email"] = "http://www.roblox.com/asset/?id=6035173865";
		["phone_disabled"] = "http://www.roblox.com/asset/?id=6035202028";
		["email"] = "http://www.roblox.com/asset/?id=6035181866";
		["mobile_screen_share"] = "http://www.roblox.com/asset/?id=6035202021";
		["live_help"] = "http://www.roblox.com/asset/?id=6035190836";
		["chat_bubble"] = "http://www.roblox.com/asset/?id=6035181858";
		["stop_screen_share"] = "http://www.roblox.com/asset/?id=6035202042";
		["location_on"] = "http://www.roblox.com/asset/?id=6035190846";
		["chat_bubble_outline"] = "http://www.roblox.com/asset/?id=6035181869";
		["dialer_sip"] = "http://www.roblox.com/asset/?id=6035181865";
		["no_sim"] = "http://www.roblox.com/asset/?id=6035202030";
		["list_alt"] = "http://www.roblox.com/asset/?id=6035190838";
		["call"] = "http://www.roblox.com/asset/?id=6035173859";
		["pause_presentation"] = "http://www.roblox.com/asset/?id=6035202015";
		["invert_colors_off"] = "http://www.roblox.com/asset/?id=6035190842";
		["call_missed_outgoing"] = "http://www.roblox.com/asset/?id=6035173847";
		["stay_current_landscape"] = "http://www.roblox.com/asset/?id=6035202011";
		["import_export"] = "http://www.roblox.com/asset/?id=6035202040";
		["add_ic_call"] = "http://www.roblox.com/asset/?id=6035173839";
		["dialpad"] = "http://www.roblox.com/asset/?id=6035181892";
		["nat"] = "http://www.roblox.com/asset/?id=6035202082";
		["unsubscribe"] = "http://www.roblox.com/asset/?id=6035202044";
		["mark_chat_unread"] = "http://www.roblox.com/asset/?id=6035190841";
		["portable_wifi_off"] = "http://www.roblox.com/asset/?id=6035202091";
		["location_off"] = "http://www.roblox.com/asset/?id=6035202049";
		["person_search"] = "http://www.roblox.com/asset/?id=6035202013";
		["phonelink_lock"] = "http://www.roblox.com/asset/?id=6035202064";
		["desktop_access_disabled"] = "http://www.roblox.com/asset/?id=6035181863";
		["import_contacts"] = "http://www.roblox.com/asset/?id=6035190854";
		["rss_feed"] = "http://www.roblox.com/asset/?id=6035202016";
		["chat"] = "http://www.roblox.com/asset/?id=6035173838";
		["print_disabled"] = "http://www.roblox.com/asset/?id=6035202041";
		["mark_email_read"] = "http://www.roblox.com/asset/?id=6035202038";
		["hourglass_top"] = "http://www.roblox.com/asset/?id=6035190886";
		["clear_all"] = "http://www.roblox.com/asset/?id=6035181870";
		["forum"] = "http://www.roblox.com/asset/?id=6035202002";
		["qr_code"] = "http://www.roblox.com/asset/?id=6035202012";
		["speaker_phone"] = "http://www.roblox.com/asset/?id=6035202018";
		["rtt"] = "http://www.roblox.com/asset/?id=6035202010";
		["domain_verification"] = "http://www.roblox.com/asset/?id=6035181867";
		["app_registration"] = "http://www.roblox.com/asset/?id=6035173870";
		["call_split"] = "http://www.roblox.com/asset/?id=6035173861";
		["cell_wifi"] = "http://www.roblox.com/asset/?id=6035173852";
		["phone_enabled"] = "http://www.roblox.com/asset/?id=6035202089";
		["call_made"] = "http://www.roblox.com/asset/?id=6035173858";
		["call_received"] = "http://www.roblox.com/asset/?id=6035173844";
		["phone"] = "http://www.roblox.com/asset/?id=6035202017";
		["ring_volume"] = "http://www.roblox.com/asset/?id=6035202032";
		["mark_email_unread"] = "http://www.roblox.com/asset/?id=6035202027";
		["hourglass_bottom"] = "http://www.roblox.com/asset/?id=6035202043";
		["read_more"] = "http://www.roblox.com/asset/?id=6035202014";
		["duo"] = "http://www.roblox.com/asset/?id=6035181860";
		["more_time"] = "http://www.roblox.com/asset/?id=6035202036";
		["wifi_calling"] = "http://www.roblox.com/asset/?id=6035202065";
		["swap_calls"] = "http://www.roblox.com/asset/?id=6035202037";
		["cancel_presentation"] = "http://www.roblox.com/asset/?id=6035173837";
		["call_missed"] = "http://www.roblox.com/asset/?id=6035173850";
		["mark_chat_read"] = "http://www.roblox.com/asset/?id=6035202031";
		["text_snippet"] = "http://www.roblox.com/asset/?id=6031302995";
		["snippet_folder"] = "http://www.roblox.com/asset/?id=6031302947";
		["workspaces_outline"] = "http://www.roblox.com/asset/?id=6031302952";
		["file_download"] = "http://www.roblox.com/asset/?id=6031302931";
		["request_quote"] = "http://www.roblox.com/asset/?id=6031302941";
		["approval"] = "http://www.roblox.com/asset/?id=6031302928";
		["drive_folder_upload"] = "http://www.roblox.com/asset/?id=6031302929";
		["rule_folder"] = "http://www.roblox.com/asset/?id=6031302940";
		["attach_email"] = "http://www.roblox.com/asset/?id=6031302935";
		["topic"] = "http://www.roblox.com/asset/?id=6031302976";
		["upload_file"] = "http://www.roblox.com/asset/?id=6031302959";
		["attachment"] = "http://www.roblox.com/asset/?id=6031302921";
		["file_download_done"] = "http://www.roblox.com/asset/?id=6031302926";
		["drive_file_move_outline"] = "http://www.roblox.com/asset/?id=6031302924";
		["cloud_upload"] = "http://www.roblox.com/asset/?id=6031302992";
		["cloud_circle"] = "http://www.roblox.com/asset/?id=6031302919";
		["folder_shared"] = "http://www.roblox.com/asset/?id=6031302945";
		["cloud_download"] = "http://www.roblox.com/asset/?id=6031302917";
		["file_upload"] = "http://www.roblox.com/asset/?id=6031302996";
		["workspaces_filled"] = "http://www.roblox.com/asset/?id=6031302961";
		["cloud_queue"] = "http://www.roblox.com/asset/?id=6031302916";
		["cloud"] = "http://www.roblox.com/asset/?id=6031302918";
		["folder_open"] = "http://www.roblox.com/asset/?id=6031302934";
		["grid_view"] = "http://www.roblox.com/asset/?id=6031302950";
		["cloud_off"] = "http://www.roblox.com/asset/?id=6031302993";
		["create_new_folder"] = "http://www.roblox.com/asset/?id=6031302933";
		["cloud_done"] = "http://www.roblox.com/asset/?id=6031302927";
		["folder"] = "http://www.roblox.com/asset/?id=6031302932";
		["drive_file_move"] = "http://www.roblox.com/asset/?id=6031302922";
		["drive_file_rename_outline"] = "http://www.roblox.com/asset/?id=6031302994";
		["notifications_active"] = "http://www.roblox.com/asset/?id=6034304908";
		["sentiment_neutral"] = "http://www.roblox.com/asset/?id=6034230636";
		["sick"] = "http://www.roblox.com/asset/?id=6034230642";
		["poll"] = "http://www.roblox.com/asset/?id=6034267991";
		["emoji_events"] = "http://www.roblox.com/asset/?id=6034275726";
		["groups"] = "http://www.roblox.com/asset/?id=6034281935";
		["sports_soccer"] = "http://www.roblox.com/asset/?id=6034227075";
		["person_add"] = "http://www.roblox.com/asset/?id=6034287514";
		["mood_bad"] = "http://www.roblox.com/asset/?id=6034295706";
		["person_remove_alt_1"] = "http://www.roblox.com/asset/?id=6034287515";
		["king_bed"] = "http://www.roblox.com/asset/?id=6034281948";
		["architecture"] = "http://www.roblox.com/asset/?id=6034275730";
		["deck"] = "http://www.roblox.com/asset/?id=6034295703";
		["group_add"] = "http://www.roblox.com/asset/?id=6034281909";
		["sports_basketball"] = "http://www.roblox.com/asset/?id=6034230649";
		["emoji_symbols"] = "http://www.roblox.com/asset/?id=6034281899";
		["switch_account"] = "http://www.roblox.com/asset/?id=6034227138";
		["remove_moderator"] = "http://www.roblox.com/asset/?id=6034267998";
		["coronavirus"] = "http://www.roblox.com/asset/?id=6034275724";
		["people"] = "http://www.roblox.com/asset/?id=6034287513";
		["person"] = "http://www.roblox.com/asset/?id=6034287594";
		["elderly"] = "http://www.roblox.com/asset/?id=6034295698";
		["clean_hands"] = "http://www.roblox.com/asset/?id=6034275729";
		["emoji_flags"] = "http://www.roblox.com/asset/?id=6034304898";
		["psychology"] = "http://www.roblox.com/asset/?id=6034287516";
		["person_add_alt"] = "http://www.roblox.com/asset/?id=6034267994";
		["sports_volleyball"] = "http://www.roblox.com/asset/?id=6034227139";
		["domain"] = "http://www.roblox.com/asset/?id=6034275722";
		["emoji_objects"] = "http://www.roblox.com/asset/?id=6034281900";
		["ios_share"] = "http://www.roblox.com/asset/?id=6034281941";
		["history_edu"] = "http://www.roblox.com/asset/?id=6034281934";
		["share"] = "http://www.roblox.com/asset/?id=6034230648";
		["military_tech"] = "http://www.roblox.com/asset/?id=6034295711";
		["sports_kabaddi"] = "http://www.roblox.com/asset/?id=6034227141";
		["cake"] = "http://www.roblox.com/asset/?id=6034295702";
		["engineering"] = "http://www.roblox.com/asset/?id=6034281908";
		["emoji_food_beverage"] = "http://www.roblox.com/asset/?id=6034304883";
		["notifications_none"] = "http://www.roblox.com/asset/?id=6034308947";
		["emoji_people"] = "http://www.roblox.com/asset/?id=6034281904";
		["thumb_down_alt"] = "http://www.roblox.com/asset/?id=6034227069";
		["sentiment_very_satisfied"] = "http://www.roblox.com/asset/?id=6034230650";
		["nights_stay"] = "http://www.roblox.com/asset/?id=6034304881";
		["reduce_capacity"] = "http://www.roblox.com/asset/?id=6034268013";
		["add_moderator"] = "http://www.roblox.com/asset/?id=6034295699";
		["science"] = "http://www.roblox.com/asset/?id=6034230640";
		["pages"] = "http://www.roblox.com/asset/?id=6034304892";
		["sentiment_satisfied"] = "http://www.roblox.com/asset/?id=6034230668";
		["plus_one"] = "http://www.roblox.com/asset/?id=6034268012";
		["party_mode"] = "http://www.roblox.com/asset/?id=6034287521";
		["person_remove"] = "http://www.roblox.com/asset/?id=6034267996";
		["single_bed"] = "http://www.roblox.com/asset/?id=6034230651";
		["mood"] = "http://www.roblox.com/asset/?id=6034295704";
		["public"] = "http://www.roblox.com/asset/?id=6034287522";
		["sports_rugby"] = "http://www.roblox.com/asset/?id=6034227073";
		["sports_handball"] = "http://www.roblox.com/asset/?id=6034227074";
		["person_add_alt_1"] = "http://www.roblox.com/asset/?id=6034287519";
		["people_alt"] = "http://www.roblox.com/asset/?id=6034287518";
		["notifications_off"] = "http://www.roblox.com/asset/?id=6034304894";
		["whatshot"] = "http://www.roblox.com/asset/?id=6034287525";
		["emoji_transportation"] = "http://www.roblox.com/asset/?id=6034281894";
		["outdoor_grill"] = "http://www.roblox.com/asset/?id=6034304900";
		["sentiment_very_dissatisfied"] = "http://www.roblox.com/asset/?id=6034230659";
		["masks"] = "http://www.roblox.com/asset/?id=6034295710";
		["luggage"] = "http://www.roblox.com/asset/?id=6034295708";
		["sports_motorsports"] = "http://www.roblox.com/asset/?id=6034227071";
		["sports_esports"] = "http://www.roblox.com/asset/?id=6034227061";
		["location_city"] = "http://www.roblox.com/asset/?id=6034304889";
		["sports_golf"] = "http://www.roblox.com/asset/?id=6034227060";
		["sentiment_dissatisfied"] = "http://www.roblox.com/asset/?id=6034230637";
		["no_luggage"] = "http://www.roblox.com/asset/?id=6034304891";
		["fireplace"] = "http://www.roblox.com/asset/?id=6034281910";
		["emoji_nature"] = "http://www.roblox.com/asset/?id=6034281896";
		["group"] = "http://www.roblox.com/asset/?id=6034281901";
		["thumb_up_alt"] = "http://www.roblox.com/asset/?id=6034227076";
		["sports_tennis"] = "http://www.roblox.com/asset/?id=6034227068";
		["facebook"] = "http://www.roblox.com/asset/?id=6034281898";
		["sports_mma"] = "http://www.roblox.com/asset/?id=6034227072";
		["person_outline"] = "http://www.roblox.com/asset/?id=6034268008";
		["sports_baseball"] = "http://www.roblox.com/asset/?id=6034230652";
		["sports_cricket"] = "http://www.roblox.com/asset/?id=6034230660";
		["people_outline"] = "http://www.roblox.com/asset/?id=6034287528";
		["notifications_paused"] = "http://www.roblox.com/asset/?id=6034304896";
		["emoji_emotions"] = "http://www.roblox.com/asset/?id=6034275731";
		["follow_the_signs"] = "http://www.roblox.com/asset/?id=6034281911";
		["sanitizer"] = "http://www.roblox.com/asset/?id=6034287586";
		["self_improvement"] = "http://www.roblox.com/asset/?id=6034230634";
		["notifications"] = "http://www.roblox.com/asset/?id=6034308946";
		["public_off"] = "http://www.roblox.com/asset/?id=6034287538";
		["recommend"] = "http://www.roblox.com/asset/?id=6034287524";
		["sports_football"] = "http://www.roblox.com/asset/?id=6034227067";
		["sports_hockey"] = "http://www.roblox.com/asset/?id=6034227064";
		["school"] = "http://www.roblox.com/asset/?id=6034230641";
		["connect_without_contact"] = "http://www.roblox.com/asset/?id=6034275800";
		["sports"] = "http://www.roblox.com/asset/?id=6034230647";
		["construction"] = "http://www.roblox.com/asset/?id=6034275725";
		["inventory"] = "http://www.roblox.com/asset/?id=6035056487";
		["add_box"] = "http://www.roblox.com/asset/?id=6035047375";
		["how_to_reg"] = "http://www.roblox.com/asset/?id=6035053288";
		["unarchive"] = "http://www.roblox.com/asset/?id=6035078921";
		["block_flipped"] = "http://www.roblox.com/asset/?id=6035047378";
		["file_copy"] = "http://www.roblox.com/asset/?id=6035053293";
		["bolt"] = "http://www.roblox.com/asset/?id=6035047381";
		["remove_circle_outline"] = "http://www.roblox.com/asset/?id=6035067843";
		["move_to_inbox"] = "http://www.roblox.com/asset/?id=6035067838";
		["save_alt"] = "http://www.roblox.com/asset/?id=6035067842";
		["weekend"] = "http://www.roblox.com/asset/?id=6035078894";
		["where_to_vote"] = "http://www.roblox.com/asset/?id=6035078913";
		["biotech"] = "http://www.roblox.com/asset/?id=6035047385";
		["report_off"] = "http://www.roblox.com/asset/?id=6035067830";
		["clear"] = "http://www.roblox.com/asset/?id=6035047409";
		["redo"] = "http://www.roblox.com/asset/?id=6035056483";
		["link"] = "http://www.roblox.com/asset/?id=6035056475";
		["drafts"] = "http://www.roblox.com/asset/?id=6035053297";
		["push_pin"] = "http://www.roblox.com/asset/?id=6035056481";
		["reply"] = "http://www.roblox.com/asset/?id=6035067844";
		["undo"] = "http://www.roblox.com/asset/?id=6035078896";
		["archive"] = "http://www.roblox.com/asset/?id=6035047379";
		["add"] = "http://www.roblox.com/asset/?id=6035047377";
		["insights"] = "http://www.roblox.com/asset/?id=6035067839";
		["flag"] = "http://www.roblox.com/asset/?id=6035053279";
		["save"] = "http://www.roblox.com/asset/?id=6035067857";
		["text_format"] = "http://www.roblox.com/asset/?id=6035078890";
		["content_cut"] = "http://www.roblox.com/asset/?id=6035053280";
		["ballot"] = "http://www.roblox.com/asset/?id=6035047386";
		["remove"] = "http://www.roblox.com/asset/?id=6035067836";
		["calculate"] = "http://www.roblox.com/asset/?id=6035047384";
		["report"] = "http://www.roblox.com/asset/?id=6035067826";
		["markunread"] = "http://www.roblox.com/asset/?id=6035056476";
		["delete_sweep"] = "http://www.roblox.com/asset/?id=6035053301";
		["gesture"] = "http://www.roblox.com/asset/?id=6035053287";
		["link_off"] = "http://www.roblox.com/asset/?id=6035056484";
		["forward"] = "http://www.roblox.com/asset/?id=6035053298";
		["reply_all"] = "http://www.roblox.com/asset/?id=6035067824";
		["how_to_vote"] = "http://www.roblox.com/asset/?id=6035053295";
		["square_foot"] = "http://www.roblox.com/asset/?id=6035078918";
		["outlined_flag"] = "http://www.roblox.com/asset/?id=6035056486";
		["add_circle"] = "http://www.roblox.com/asset/?id=6035047380";
		["stacked_bar_chart"] = "http://www.roblox.com/asset/?id=6035078892";
		["policy"] = "http://www.roblox.com/asset/?id=6035056512";
		["backspace"] = "http://www.roblox.com/asset/?id=6035047397";
		["sort"] = "http://www.roblox.com/asset/?id=6035078888";
		["content_paste"] = "http://www.roblox.com/asset/?id=6035053285";
		["low_priority"] = "http://www.roblox.com/asset/?id=6035056491";
		["font_download"] = "http://www.roblox.com/asset/?id=6035053275";
		["shield"] = "http://www.roblox.com/asset/?id=6035078889";
		["waves"] = "http://www.roblox.com/asset/?id=6035078898";
		["select_all"] = "http://www.roblox.com/asset/?id=6035067834";
		["dynamic_feed"] = "http://www.roblox.com/asset/?id=6035053289";
		["mail"] = "http://www.roblox.com/asset/?id=6035056477";
		["amp_stories"] = "http://www.roblox.com/asset/?id=6035047382";
		["filter_list"] = "http://www.roblox.com/asset/?id=6035053294";
		["send"] = "http://www.roblox.com/asset/?id=6035067832";
		["create"] = "http://www.roblox.com/asset/?id=6035053304";
		["stream"] = "http://www.roblox.com/asset/?id=6035078897";
		["next_week"] = "http://www.roblox.com/asset/?id=6035067835";
		["inbox"] = "http://www.roblox.com/asset/?id=6035067831";
		["add_link"] = "http://www.roblox.com/asset/?id=6035047374";
		["content_copy"] = "http://www.roblox.com/asset/?id=6035053278";
		["remove_circle"] = "http://www.roblox.com/asset/?id=6035067837";
		["add_circle_outline"] = "http://www.roblox.com/asset/?id=6035047391";
		["block"] = "http://www.roblox.com/asset/?id=6035047387";
		["tag"] = "http://www.roblox.com/asset/?id=6035078895";
		["beach_access"] = "http://www.roblox.com/asset/?id=6035107923";
		["stroller"] = "http://www.roblox.com/asset/?id=6035161535";
		["family_restroom"] = "http://www.roblox.com/asset/?id=6035121916";
		["corporate_fare"] = "http://www.roblox.com/asset/?id=6035121908";
		["no_meeting_room"] = "http://www.roblox.com/asset/?id=6035153649";
		["do_not_touch"] = "http://www.roblox.com/asset/?id=6035121915";
		["ac_unit"] = "http://www.roblox.com/asset/?id=6035107929";
		["business_center"] = "http://www.roblox.com/asset/?id=6035107933";
		["spa"] = "http://www.roblox.com/asset/?id=6035153639";
		["no_flash"] = "http://www.roblox.com/asset/?id=6035145424";
		["no_cell"] = "http://www.roblox.com/asset/?id=6035145376";
		["room_service"] = "http://www.roblox.com/asset/?id=6035153648";
		["tapas"] = "http://www.roblox.com/asset/?id=6035161533";
		["microwave"] = "http://www.roblox.com/asset/?id=6035145367";
		["meeting_room"] = "http://www.roblox.com/asset/?id=6035145361";
		["wash"] = "http://www.roblox.com/asset/?id=6035161540";
		["escalator"] = "http://www.roblox.com/asset/?id=6035121939";
		["house_siding"] = "http://www.roblox.com/asset/?id=6035145393";
		["food_bank"] = "http://www.roblox.com/asset/?id=6035121921";
		["foundation"] = "http://www.roblox.com/asset/?id=6035121918";
		["elevator"] = "http://www.roblox.com/asset/?id=6035121912";
		["room_preferences"] = "http://www.roblox.com/asset/?id=6035153642";
		["do_not_step"] = "http://www.roblox.com/asset/?id=6035121910";
		["free_breakfast"] = "http://www.roblox.com/asset/?id=6035145363";
		["house"] = "http://www.roblox.com/asset/?id=6035145364";
		["child_care"] = "http://www.roblox.com/asset/?id=6035107927";
		["night_shelter"] = "http://www.roblox.com/asset/?id=6035145378";
		["child_friendly"] = "http://www.roblox.com/asset/?id=6035121942";
		["checkroom"] = "http://www.roblox.com/asset/?id=6035107931";
		["hot_tub"] = "http://www.roblox.com/asset/?id=6035145382";
		["dry"] = "http://www.roblox.com/asset/?id=6035121909";
		["charging_station"] = "http://www.roblox.com/asset/?id=6035107925";
		["all_inclusive"] = "http://www.roblox.com/asset/?id=6035107920";
		["bento"] = "http://www.roblox.com/asset/?id=6035107924";
		["no_backpack"] = "http://www.roblox.com/asset/?id=6035145368";
		["storefront"] = "http://www.roblox.com/asset/?id=6035161534";
		["no_food"] = "http://www.roblox.com/asset/?id=6035145372";
		["backpack"] = "http://www.roblox.com/asset/?id=6035107928";
		["stairs"] = "http://www.roblox.com/asset/?id=6035153637";
		["carpenter"] = "http://www.roblox.com/asset/?id=6035107955";
		["no_stroller"] = "http://www.roblox.com/asset/?id=6035153661";
		["roofing"] = "http://www.roblox.com/asset/?id=6035153656";
		["umbrella"] = "http://www.roblox.com/asset/?id=6035161550";
		["sports_bar"] = "http://www.roblox.com/asset/?id=6035153638";
		["apartment"] = "http://www.roblox.com/asset/?id=6035107922";
		["smoke_free"] = "http://www.roblox.com/asset/?id=6035153647";
		["pool"] = "http://www.roblox.com/asset/?id=6035153655";
		["bathtub"] = "http://www.roblox.com/asset/?id=6035107939";
		["no_drinks"] = "http://www.roblox.com/asset/?id=6035145390";
		["escalator_warning"] = "http://www.roblox.com/asset/?id=6035121930";
		["wheelchair_pickup"] = "http://www.roblox.com/asset/?id=6035161536";
		["smoking_rooms"] = "http://www.roblox.com/asset/?id=6035153636";
		["rice_bowl"] = "http://www.roblox.com/asset/?id=6035153662";
		["tty"] = "http://www.roblox.com/asset/?id=6035161541";
		["no_photography"] = "http://www.roblox.com/asset/?id=6035153664";
		["casino"] = "http://www.roblox.com/asset/?id=6035107936";
		["fence"] = "http://www.roblox.com/asset/?id=6035121923";
		["grass"] = "http://www.roblox.com/asset/?id=6035145359";
		["countertops"] = "http://www.roblox.com/asset/?id=6035121914";
		["kitchen"] = "http://www.roblox.com/asset/?id=6035145362";
		["golf_course"] = "http://www.roblox.com/asset/?id=6035145423";
		["soap"] = "http://www.roblox.com/asset/?id=6035153645";
		["water_damage"] = "http://www.roblox.com/asset/?id=6035161563";
		["airport_shuttle"] = "http://www.roblox.com/asset/?id=6035107921";
		["fitness_center"] = "http://www.roblox.com/asset/?id=6035121907";
		["baby_changing_station"] = "http://www.roblox.com/asset/?id=6035107930";
		["fire_extinguisher"] = "http://www.roblox.com/asset/?id=6035121913";
		["sparkle"] = "http://www.roblox.com/asset/?id=4483362748"
	}
}

-- request: disponible para uso futuro por el framework (http request cross-executor)
local request = (syn and syn.request) or (http and http.request) or (rawget(_G,"http_request")) or nil
local tweeninfo = TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local PresetGradients = {
	-- ── Clásicos originales ─────────────────────────────────────────
	["Nightlight (Classic)"] = {Color3.fromRGB(147, 255, 239), Color3.fromRGB(201, 211, 233), Color3.fromRGB(255, 167, 227)},
	["Nightlight (Neo)"]     = {Color3.fromRGB(117, 164, 206), Color3.fromRGB(123, 201, 201), Color3.fromRGB(224, 138, 175)},
	Starlight = {Color3.fromRGB(147, 255, 239), Color3.fromRGB(181, 206, 241), Color3.fromRGB(214, 158, 243)},
	Solar     = {Color3.fromRGB(242, 157,  76), Color3.fromRGB(240, 179,  81), Color3.fromRGB(238, 201,  86)},
	Sparkle   = {Color3.fromRGB(199, 130, 242), Color3.fromRGB(221, 130, 238), Color3.fromRGB(243, 129, 233)},
	Lime      = {Color3.fromRGB(170, 255, 127), Color3.fromRGB(163, 220, 138), Color3.fromRGB(155, 185, 149)},
	Vine      = {Color3.fromRGB(  0, 191, 143), Color3.fromRGB(  0, 126,  94), Color3.fromRGB(  0,  61,  46)},
	Cherry    = {Color3.fromRGB(148,  54,  54), Color3.fromRGB(168,  67,  70), Color3.fromRGB(188,  80,  86)},
	Daylight  = {Color3.fromRGB( 51, 156, 255), Color3.fromRGB( 89, 171, 237), Color3.fromRGB(127, 186, 218)},
	Blossom   = {Color3.fromRGB(255, 165, 243), Color3.fromRGB(213, 129, 231), Color3.fromRGB(170,  92, 218)},
	-- ── Nuevos presets ──────────────────────────────────────────────
	-- Naranja → Magenta. Vibrante y llamativo.
	Sunset    = {Color3.fromRGB(255,  94,  77), Color3.fromRGB(255, 154,  68), Color3.fromRGB(255, 206,  84)},
	-- Azul eléctrico → Cyan puro. Estilo hacker.
	Neon      = {Color3.fromRGB( 30, 215, 255), Color3.fromRGB( 20, 160, 255), Color3.fromRGB( 10,  90, 235)},
	-- Índigo profundo → Violeta → Rosa. Estilo galaxia.
	Galaxy    = {Color3.fromRGB( 70,  30, 160), Color3.fromRGB(130,  50, 200), Color3.fromRGB(210,  80, 180)},
	-- Verde menta → Azul cielo. Fresco y limpio.
	Arctic    = {Color3.fromRGB(160, 245, 220), Color3.fromRGB(110, 210, 240), Color3.fromRGB( 70, 160, 255)},
	-- Rojo → Naranja intenso. Energético y agresivo.
	Ember     = {Color3.fromRGB(255,  45,  45), Color3.fromRGB(255, 100,  20), Color3.fromRGB(255, 165,   0)},
	-- Turquesa → Verde esmeralda. Elegante.
	Emerald   = {Color3.fromRGB( 80, 235, 200), Color3.fromRGB( 30, 195, 145), Color3.fromRGB(  0, 145,  90)},
	-- Magenta → Violeta oscuro. Llamativo y oscuro.
	Amethyst  = {Color3.fromRGB(220,  80, 220), Color3.fromRGB(170,  50, 210), Color3.fromRGB(100,  20, 180)},
	-- Dorado → Ámbar. Premium y lujoso.
	Gold      = {Color3.fromRGB(255, 215,   0), Color3.fromRGB(235, 175,  20), Color3.fromRGB(200, 130,  40)},
	-- Blanco → Gris plata. Minimalista y limpio.
	Silver    = {Color3.fromRGB(240, 240, 245), Color3.fromRGB(190, 195, 210), Color3.fromRGB(130, 140, 165)},
	-- Verde neón → Lima. Clásico gamer.
	["Toxic"] = {Color3.fromRGB(100, 255,  50), Color3.fromRGB(155, 230,  30), Color3.fromRGB(200, 200,  10)},
}

local function GetIcon(icon, source)
	if source == "Custom" then
		return "rbxassetid://" .. icon
	elseif source == "Lucide" then
		local iconData = not isStudio and game:HttpGet("https://raw.githubusercontent.com/latte-soft/lucide-roblox/refs/heads/master/lib/Icons.luau")
		local icons = isStudio and IconModule.Lucide or loadstring(iconData)()
		if not isStudio then
			icon = string.match(string.lower(icon), "^%s*(.*)%s*$") :: string
			local sizedicons = icons['48px']

			local r = sizedicons[icon]
			if not r then
				error("Lucide Icons: Failed to find icon by the name of \"" .. icon .. "\.", 2)
			end

			local rirs = r[2]
			local riro = r[3]

			if type(r[1]) ~= "number" or type(rirs) ~= "table" or type(riro) ~= "table" then
				error("Lucide Icons: Internal error: Invalid auto-generated asset entry")
			end

			local irs = Vector2.new(rirs[1], rirs[2])
			local iro = Vector2.new(riro[1], riro[2])

			local asset = {
				id = r[1],
				imageRectSize = irs,
				imageRectOffset = iro,
			}

			return asset
		else
			return "rbxassetid://10723434557"
		end
	else
		if icon ~= nil and IconModule[source] then
			local sourceicon = IconModule[source]
			return sourceicon[icon]
		else
			return nil
		end
	end
end

local function RemoveTable(tablre, value)
	for i,v in pairs(tablre) do
		if tostring(v) == tostring(value) then
			table.remove(tablre, i)
		end
	end
end

local function Kwargify(defaults, passed)
	for i, v in pairs(defaults) do
		if passed[i] == nil then
			passed[i] = v
		end
	end
	return passed
end

local function PackColor(Color)
	return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
end

local function UnpackColor(Color)
	return Color3.fromRGB(Color.R, Color.G, Color.B)
end

function tween(object, goal, callback, tweenin)
	local tween = TweenService:Create(object,tweenin or tweeninfo, goal)
	tween.Completed:Connect(callback or function() end)
	tween:Play()
end

local function BlurModule(Frame)
	local RunService = game:GetService('RunService')
	local camera = workspace.CurrentCamera
	local MTREL = "Glass"
	local binds = {}
	local root = Instance.new('Folder', camera)
	root.Name = 'LunaBlur'

	local gTokenMH = 99999999
	local gToken = math.random(1, gTokenMH)

	local DepthOfField = Instance.new('DepthOfFieldEffect', game:GetService('Lighting'))
	DepthOfField.FarIntensity = 0
	DepthOfField.FocusDistance = 51.6
	DepthOfField.InFocusRadius = 50
	DepthOfField.NearIntensity = 6
	DepthOfField.Name = "DPT_"..gToken

	local frame = Instance.new('Frame')
	frame.Parent = Frame
	frame.Size = UDim2.new(0.95, 0, 0.95, 0)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundTransparency = 1

	local GenUid; do
		local id = 0
		function GenUid()
			id = id + 1
			return 'neon::'..tostring(id)
		end
	end

	do
		local function IsNotNaN(x)
			return x == x
		end
		local continue = IsNotNaN(camera:ScreenPointToRay(0,0).Origin.x)
		while not continue do
			RunService.RenderStepped:Wait()
			continue = IsNotNaN(camera:ScreenPointToRay(0,0).Origin.x)
		end
	end

	local DrawQuad; do

		local acos, max, pi, sqrt = math.acos, math.max, math.pi, math.sqrt
		local sz = 0.22
		local function DrawTriangle(v1, v2, v3, p0, p1)

			local s1 = (v1 - v2).magnitude
			local s2 = (v2 - v3).magnitude
			local s3 = (v3 - v1).magnitude
			local smax = max(s1, s2, s3)
			local A, B, C
			if s1 == smax then
				A, B, C = v1, v2, v3
			elseif s2 == smax then
				A, B, C = v2, v3, v1
			elseif s3 == smax then
				A, B, C = v3, v1, v2
			end

			local para = ( (B-A).x*(C-A).x + (B-A).y*(C-A).y + (B-A).z*(C-A).z ) / (A-B).magnitude
			local perp = sqrt((C-A).magnitude^2 - para*para)
			local dif_para = (A - B).magnitude - para

			local st = CFrame.new(B, A)
			local za = CFrame.Angles(pi/2,0,0)

			local cf0 = st

			local Top_Look = (cf0 * za).lookVector
			local Mid_Point = A + CFrame.new(A, B).lookVector * para
			local Needed_Look = CFrame.new(Mid_Point, C).lookVector
			local dot = Top_Look.x*Needed_Look.x + Top_Look.y*Needed_Look.y + Top_Look.z*Needed_Look.z

			local ac = CFrame.Angles(0, 0, acos(dot))

			cf0 = cf0 * ac
			if ((cf0 * za).lookVector - Needed_Look).magnitude > 0.01 then
				cf0 = cf0 * CFrame.Angles(0, 0, -2*acos(dot))
			end
			cf0 = cf0 * CFrame.new(0, perp/2, -(dif_para + para/2))

			local cf1 = st * ac * CFrame.Angles(0, pi, 0)
			if ((cf1 * za).lookVector - Needed_Look).magnitude > 0.01 then
				cf1 = cf1 * CFrame.Angles(0, 0, 2*acos(dot))
			end
			cf1 = cf1 * CFrame.new(0, perp/2, dif_para/2)

			if not p0 then
				p0 = Instance.new('Part')
				p0.FormFactor = 'Custom'
				p0.TopSurface = 0
				p0.BottomSurface = 0
				p0.Anchored = true
				p0.CanCollide = false
				p0.CastShadow = false
				p0.Material = MTREL
				p0.Size = Vector3.new(sz, sz, sz)
				local mesh = Instance.new('SpecialMesh', p0)
				mesh.MeshType = 2
				mesh.Name = 'WedgeMesh'
			end
			p0.WedgeMesh.Scale = Vector3.new(0, perp/sz, para/sz)
			p0.CFrame = cf0

			if not p1 then
				p1 = p0:clone()
			end
			p1.WedgeMesh.Scale = Vector3.new(0, perp/sz, dif_para/sz)
			p1.CFrame = cf1

			return p0, p1
		end

		function DrawQuad(v1, v2, v3, v4, parts)
			parts[1], parts[2] = DrawTriangle(v1, v2, v3, parts[1], parts[2])
			parts[3], parts[4] = DrawTriangle(v3, v2, v4, parts[3], parts[4])
		end
	end

	if binds[frame] then
		return binds[frame].parts
	end

	local uid = GenUid()
	local parts = {}
	local f = Instance.new('Folder', root)
	f.Name = frame.Name

	local parents = {}
	do
		local function add(child)
			if child:IsA'GuiObject' then
				parents[#parents + 1] = child
				add(child.Parent)
			end
		end
		add(frame)
	end

	local function UpdateOrientation(fetchProps)
		local properties = {
			Transparency = 0.98;
			BrickColor = BrickColor.new('Institutional white');
		}
		local zIndex = 1 - 0.05*frame.ZIndex

		local tl, br = frame.AbsolutePosition, frame.AbsolutePosition + frame.AbsoluteSize
		local tr, bl = Vector2.new(br.x, tl.y), Vector2.new(tl.x, br.y)
		do
			local rot = 0;
			for _, v in ipairs(parents) do
				rot = rot + v.Rotation
			end
			if rot ~= 0 and rot%180 ~= 0 then
				local mid = tl:lerp(br, 0.5)
				local s, c = math.sin(math.rad(rot)), math.cos(math.rad(rot))
				local vec = tl
				tl = Vector2.new(c*(tl.x - mid.x) - s*(tl.y - mid.y), s*(tl.x - mid.x) + c*(tl.y - mid.y)) + mid
				tr = Vector2.new(c*(tr.x - mid.x) - s*(tr.y - mid.y), s*(tr.x - mid.x) + c*(tr.y - mid.y)) + mid
				bl = Vector2.new(c*(bl.x - mid.x) - s*(bl.y - mid.y), s*(bl.x - mid.x) + c*(bl.y - mid.y)) + mid
				br = Vector2.new(c*(br.x - mid.x) - s*(br.y - mid.y), s*(br.x - mid.x) + c*(br.y - mid.y)) + mid
			end
		end
		DrawQuad(
			camera:ScreenPointToRay(tl.x, tl.y, zIndex).Origin,
			camera:ScreenPointToRay(tr.x, tr.y, zIndex).Origin,
			camera:ScreenPointToRay(bl.x, bl.y, zIndex).Origin,
			camera:ScreenPointToRay(br.x, br.y, zIndex).Origin,
			parts
		)
		if fetchProps then
			for _, pt in pairs(parts) do
				pt.Parent = f
			end
			for propName, propValue in pairs(properties) do
				for _, pt in pairs(parts) do
					pt[propName] = propValue
				end
			end
		end

	end

	UpdateOrientation(true)
	RunService:BindToRenderStep(uid, 2000, UpdateOrientation)
end

local function unpackt(array : table)

	local val = ""
	local i = 0
	for _,v in pairs(array) do
		if i < 3 then
			val = val .. v .. ", "
			i += 1
		else
			val = "Various"
			break
		end
	end

	return val
end

local LunaUI
if isStudio then
	LunaUI = script.Parent:WaitForChild("Luna UI")
else
	local ok, result = pcall(function()
		return game:GetObjects("rbxassetid://86467455075715")[1]
	end)
	if ok and result then
		LunaUI = result
	else
		error("[BladeX] Error al cargar Luna UI. Verifica que tu executor soporte game:GetObjects.")
	end
end
-- Guardar referencia global para que futuras ejecuciones puedan destruir esta instancia
_G.BladeX_LunaUI = LunaUI

local SizeBleh = nil

local function Hide(Window, bind, notif)
	SizeBleh = Window.Size
	bind = string.split(tostring(bind), "Enum.KeyCode.")
	bind = bind[2]
	if notif then
		Luna:Notification({Title = "Interface Hidden", Content = "The interface has been hidden, you may reopen the interface by Pressing the UI Bind In Settings ("..tostring(bind)..")", Icon = "visibility_off"})
	end
	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = "http://www.roblox.com/asset/?id=6031097225"
		snd.Volume = 0.6
		snd.Parent = game:GetService("SoundService")
		snd:Play()
		game:GetService("Debris"):AddItem(snd, 3)
	end)
	tween(Window, {BackgroundTransparency = 1})
	tween(Window.Elements, {BackgroundTransparency = 1})
	tween(Window.Line, {BackgroundTransparency = 1})
	tween(Window.Title.Title, {TextTransparency = 1})
	local _ti = Window.Title:FindFirstChild("TitleImage") or Main:FindFirstChild("TitleImage")
	if _ti then _ti.Visible = false end
	tween(Window.Title.subtitle, {TextTransparency = 1})
	tween(Window.Logo, {ImageTransparency = 1})
	tween(Window.Navigation.Line, {BackgroundTransparency = 1})

	for _, TopbarButton in ipairs(Window.Controls:GetChildren()) do
		if TopbarButton.ClassName == "Frame" then
			tween(TopbarButton, {BackgroundTransparency = 1})
			tween(TopbarButton.UIStroke, {Transparency = 1})
			tween(TopbarButton.ImageLabel, {ImageTransparency = 1})
			TopbarButton.Visible = false
		end
	end
	for _, tabbtn in ipairs(Window.Navigation.Tabs:GetChildren()) do
		if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "InActive Template" then
			TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
			TweenService:Create(tabbtn.ImageLabel, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
			TweenService:Create(tabbtn.DropShadowHolder.DropShadow, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
			TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
		end
	end

	task.wait(0.28)
	Window.Size = UDim2.new(0,0,0,0)
	Window.Parent.ShadowHolder.Visible = false
	task.wait()
	Window.Elements.Parent.Visible = false
	Window.Visible = false
	-- Colapsar dragBar al ocultar la ventana (usa FindFirstChild para no depender del upvalue)
	pcall(function()
		local db = LunaUI and LunaUI:FindFirstChild("Drag")
		if db then
			db.Visible = false
			db.Size = UDim2.new(0, 0, 0, 0)
			db.BackgroundTransparency = 1
		end
	end)
end

local _gethuiValid = false
if gethui then
	local _ok, _hui = pcall(gethui)
	if _ok and _hui and typeof(_hui) == "Instance" then
		_gethuiValid = true
	end
end
if _gethuiValid then
	LunaUI.Enabled = false
	pcall(function()
		for _, child in ipairs(LunaUI:GetChildren()) do
			if child:IsA("Frame") or child:IsA("ScrollingFrame") then
				child.BackgroundTransparency = 1
				child.Visible = false
			elseif child:IsA("ImageLabel") then
				child.ImageTransparency = 1
				child.Visible = false
			end
		end
	end)
	local _ok2, _hui2 = pcall(gethui)
	LunaUI.Parent = (_ok2 and _hui2) or CoreGui
elseif pcall(function() return syn ~= nil and syn.protect_gui ~= nil end) and syn and syn.protect_gui then
	LunaUI.Enabled = false
	pcall(function()
		for _, child in ipairs(LunaUI:GetChildren()) do
			if child:IsA("Frame") or child:IsA("ScrollingFrame") then
				child.BackgroundTransparency = 1
				child.Visible = false
			elseif child:IsA("ImageLabel") then
				child.ImageTransparency = 1
				child.Visible = false
			end
		end
	end)
	pcall(function() syn.protect_gui(LunaUI) end)
	LunaUI.Parent = CoreGui
elseif not isStudio and CoreGui:FindFirstChild("RobloxGui") then
	LunaUI.Enabled = false
	LunaUI.Parent = CoreGui:FindFirstChild("RobloxGui")
elseif not isStudio then
	LunaUI.Enabled = false
	LunaUI.Parent = CoreGui
end

if gethui then
	for _, Interface in ipairs(gethui():GetChildren()) do
		if Interface.Name == LunaUI.Name and Interface ~= LunaUI then
			Hide(Interface.SmartWindow)
			Interface.Enabled = false
			Interface.Name = "Luna-Old"
		end
	end
elseif not isStudio then
	for _, Interface in ipairs(CoreGui:GetChildren()) do
		if Interface.Name == LunaUI.Name and Interface ~= LunaUI then
			Hide(Interface.SmartWindow)
			Interface.Enabled = false
			Interface.Name = "Luna-Old"
		end
	end
end

LunaUI.Enabled = false
LunaUI.SmartWindow.Visible = false
LunaUI.Notifications.Template.Visible = false
LunaUI.DisplayOrder = 1000000000

-- Fix: ocultar el dragBar al inicio para evitar el frame fantasma en la izquierda
if LunaUI:FindFirstChild("Drag") then
	LunaUI.Drag.Visible = false
	LunaUI.Drag.BackgroundTransparency = 1
	LunaUI.Drag.Size = UDim2.new(0, 0, 0, 0)  -- tamaño cero: imposible renderizar
end
-- Fix: ocultar MobileSupport al inicio para evitar la línea fantasma en la derecha
if LunaUI:FindFirstChild("MobileSupport") then
	pcall(function() LunaUI.MobileSupport:Destroy() end)
end

local Main : Frame = LunaUI.SmartWindow
local Dragger = Main.Drag
local dragBar = LunaUI.Drag
local dragInteract = dragBar and dragBar.Interact or nil
local dragBarCosmetic = dragBar and dragBar.Drag or nil
-- Fix: hardcodear el tamaño real del dragBar (no leerlo después de zeroearlo)
local _dragBarOriginalSize = UDim2.new(1, 0, 0, 48)

-- ================================================================
-- DRAGBAR TRANSPARENCY ENFORCER (igual que v9 - sin restricción móvil)
-- El dragBar puede resetearse por tweens, eventos o race conditions.
-- Este enforcer Heartbeat lo corrige cada frame de forma permanente.
-- ================================================================
if dragBar then
	dragBar.BackgroundTransparency = 1
	dragBar.Size = UDim2.new(0, 0, 0, 0)
	pcall(function()
		for _, d in ipairs(dragBar:GetDescendants()) do
			if d:IsA("Frame") and d ~= dragBarCosmetic then
				d.BackgroundTransparency = 1
			end
		end
	end)
	local _dragGuardConn
	_dragGuardConn = RunService.Heartbeat:Connect(function()
		if not dragBar or not dragBar.Parent then
			_dragGuardConn:Disconnect()
			if getgenv then getgenv()._BladeXDragGuard = nil end
			return
		end
		-- Cuando dragBar NO está visible: colapsar a tamaño cero Y transparente
		if not dragBar.Visible then
			if dragBar.BackgroundTransparency ~= 1 then dragBar.BackgroundTransparency = 1 end
			if dragBar.Size ~= UDim2.new(0,0,0,0) then dragBar.Size = UDim2.new(0,0,0,0) end
			return
		end
		-- Cuando SÍ está visible: restaurar tamaño si fue colapsado y mantener fondo transparente
		if dragBar.Size == UDim2.new(0,0,0,0) then
			dragBar.Size = _dragBarOriginalSize
		end
		if dragBar.BackgroundTransparency ~= 1 then
			dragBar.BackgroundTransparency = 1
		end
		for _, d in ipairs(dragBar:GetDescendants()) do
			if d:IsA("Frame") and d ~= dragBarCosmetic and d.BackgroundTransparency ~= 1 then
				d.BackgroundTransparency = 1
			end
		end
		-- Mantener ShadowHolder invisible cuando Main no es visible
		pcall(function()
			local sh = LunaUI:FindFirstChild("ShadowHolder")
			if sh and not (Main and Main.Visible) then
				if sh.BackgroundTransparency ~= 1 then sh.BackgroundTransparency = 1 end
				for _, d in ipairs(sh:GetDescendants()) do
					if d:IsA("ImageLabel") and d.ImageTransparency ~= 1 then d.ImageTransparency = 1 end
					if d:IsA("Frame") and d.BackgroundTransparency ~= 1 then d.BackgroundTransparency = 1 end
				end
			end
		end)
		-- Mantener otros hijos desconocidos siempre transparentes
		if LunaUI and LunaUI.Parent then
			for _, child in ipairs(LunaUI:GetChildren()) do
				if not _ALLOWED_LUNAUI_CHILDREN[child.Name] then
					pcall(function()
						if child:IsA("Frame") and child.BackgroundTransparency ~= 1 then
							child.BackgroundTransparency = 1
						end
						if child:IsA("ImageLabel") and child.ImageTransparency ~= 1 then
							child.ImageTransparency = 1
						end
					end)
				end
			end
		end
	end)
	-- Guardar la conexión para poder desconectarla si se re-ejecuta el script
	if getgenv then getgenv()._BladeXDragGuard = _dragGuardConn end
end
-- ================================================================
-- Llamada inicial del Guard: LunaUI ya está declarado aquí,
-- limpia ShadowHolder, hijos desconocidos y residuos del loader.
BladeX_Guard()

local Elements = Main.Elements.Interactions
local LoadingFrame = Main.LoadingFrame
local Navigation = Main.Navigation
local Tabs = Navigation.Tabs
local Notifications = LunaUI.Notifications
local KeySystem : Frame = Main.KeySystem

local function Draggable(Bar, Window, enableTaptic, tapticOffset)
	pcall(function()
		local Dragging, DragInput, MousePos, FramePos

		local function connectFunctions()
			if dragBar and enableTaptic then
				dragBar.MouseEnter:Connect(function()
					if not Dragging then
						TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5, Size = UDim2.new(0, 120, 0, 4)}):Play()
					end
				end)

				dragBar.MouseLeave:Connect(function()
					if not Dragging then
						TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.7, Size = UDim2.new(0, 100, 0, 4)}):Play()
					end
				end)
			end
		end

		connectFunctions()

		Bar.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				Dragging = false  -- no activar hasta superar el umbral
				MousePos = Input.Position
				FramePos = Window.Position

				Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then
						Dragging = false
						DragInput = nil
						connectFunctions()

						if enableTaptic then
							TweenService:Create(dragBarCosmetic, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 100, 0, 4), BackgroundTransparency = 0.7}):Play()
						end
					end
				end)
			end
		end)

		Bar.InputChanged:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
				DragInput = Input
			end
		end)

		UserInputService.InputChanged:Connect(function(Input)
			if Input == DragInput and MousePos then
				local Delta = Input.Position - MousePos
				local dist  = math.sqrt(Delta.X^2 + Delta.Y^2)

				-- Umbral de 30px antes de empezar a arrastrar (evita movimientos accidentales)
				if not Dragging and dist < 30 then return end

				if not Dragging then
					Dragging = true
					FramePos = Window.Position
					if enableTaptic then
						TweenService:Create(dragBarCosmetic, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 110, 0, 4), BackgroundTransparency = 0}):Play()
					end
				end

				local newMainPosition = UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
				TweenService:Create(Window, TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = newMainPosition}):Play()

				if dragBar then
					local newDragBarPosition = UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y + 240)
					dragBar.Position = newDragBarPosition
				end
			end
		end)

	end)
end

function Luna:Notification(data)
	task.spawn(function()
		data = Kwargify({
			Title = "Missing Title",
			Content = "Missing or Unknown Content",
			Icon = "view_in_ar",
			ImageSource = "Material"
		}, data or {})

		pcall(function()
			Notifications.Visible = true
			Notifications.BackgroundTransparency = 1
		end)
		local newNotification = Notifications.Template:Clone()
		newNotification.Name = data.Title
		newNotification.Parent = Notifications
		newNotification.LayoutOrder = #Notifications:GetChildren()
		newNotification.Visible = false
		BlurModule(newNotification)

		newNotification.Title.Text = data.Title
		newNotification.Description.Text = data.Content
		newNotification.Icon.Image = GetIcon(data.Icon, data.ImageSource)

		newNotification.BackgroundTransparency = 1
		newNotification.Title.TextTransparency = 1
		newNotification.Description.TextTransparency = 1
		newNotification.UIStroke.Transparency = 1
		newNotification.Shadow.ImageTransparency = 1
		newNotification.Icon.ImageTransparency = 1
		newNotification.Icon.BackgroundTransparency = 1

		task.wait()

		newNotification.Size = UDim2.new(1, 0, 0, -Notifications:FindFirstChild("UIListLayout").Padding.Offset)

		newNotification.Icon.Size = UDim2.new(0, 28, 0, 28)
		newNotification.Icon.Position = UDim2.new(0, 16, 0.5, -1)

		newNotification.Visible = true

		newNotification.Description.Size = UDim2.new(1, -65, 0, math.huge)
		local bounds = newNotification.Description.TextBounds.Y + 55
		newNotification.Description.Size = UDim2.new(1,-65,0, bounds - 35)
		newNotification.Size = UDim2.new(1, 0, 0, -Notifications:FindFirstChild("UIListLayout").Padding.Offset)
		TweenService:Create(newNotification, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, 0, 0, bounds)}):Play()

		task.wait(0.15)
		TweenService:Create(newNotification, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.45}):Play()
		TweenService:Create(newNotification.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

		task.wait(0.05)

		TweenService:Create(newNotification.Icon, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()

		task.wait(0.05)
		TweenService:Create(newNotification.Description, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.35}):Play()
		TweenService:Create(newNotification.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.95}):Play()
		TweenService:Create(newNotification.Shadow, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0.82}):Play()

		local waitDuration = 1
		task.wait(data.Duration or waitDuration)

		newNotification.Icon.Visible = false
		TweenService:Create(newNotification, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
		TweenService:Create(newNotification.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
		TweenService:Create(newNotification.Shadow, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
		TweenService:Create(newNotification.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
		TweenService:Create(newNotification.Description, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()

		TweenService:Create(newNotification, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -90, 0, 0)}):Play()

		task.wait(1)

		TweenService:Create(newNotification, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -90, 0, -Notifications:FindFirstChild("UIListLayout").Padding.Offset)}):Play()

		newNotification.Visible = false
		newNotification:Destroy()
	end)
end

local function Unhide(Window, currentTab)
	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = "http://www.roblox.com/asset/?id=6031097229"
		snd.Volume = 0.6
		snd.Parent = game:GetService("SoundService")
		snd:Play()
		game:GetService("Debris"):AddItem(snd, 3)
	end)
	Window.Size = SizeBleh
	Window.Elements.Visible = true
	Window.Visible = true
	task.wait()
	tween(Window, {BackgroundTransparency = 0.2})
	tween(Window.Elements, {BackgroundTransparency = 0.08})
	tween(Window.Line, {BackgroundTransparency = 0})
	tween(Window.Title.Title, {TextTransparency = 0})
	local _ti2 = Window.Title:FindFirstChild("TitleImage") or Main:FindFirstChild("TitleImage")
	if _ti2 then _ti2.Visible = true end
	tween(Window.Title.subtitle, {TextTransparency = 0})
	tween(Window.Logo, {ImageTransparency = 0})
	tween(Window.Navigation.Line, {BackgroundTransparency = 0})

	for _, TopbarButton in ipairs(Window.Controls:GetChildren()) do
		if TopbarButton.ClassName == "Frame" and TopbarButton.Name ~= "Theme" then
			TopbarButton.Visible = true
			tween(TopbarButton, {BackgroundTransparency = 0.25})
			tween(TopbarButton.UIStroke, {Transparency = 0.5})
			tween(TopbarButton.ImageLabel, {ImageTransparency = 0.25})
		end
	end
	for _, tabbtn in ipairs(Window.Navigation.Tabs:GetChildren()) do
		if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "InActive Template" then
			if tabbtn.Name == currentTab then
				TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
				TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0.41}):Play()
			end
			TweenService:Create(tabbtn.ImageLabel, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
			TweenService:Create(tabbtn.DropShadowHolder.DropShadow, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
		end
	end

end

local MainSize
local MinSize
if Camera.ViewportSize.X > 774 and Camera.ViewportSize.Y > 503 then
	MainSize = UDim2.fromOffset(675, 424)
	MinSize = UDim2.fromOffset(500, 42)
else
	MainSize = UDim2.fromOffset(Camera.ViewportSize.X - 100, Camera.ViewportSize.Y - 100)
	MinSize = UDim2.fromOffset(Camera.ViewportSize.X - 275, 42)
end

local function Maximise(Window)
	Window.Controls.ToggleSize.ImageLabel.Image = "rbxassetid://10137941941"
	tween(Window, {Size = MainSize})
	Window.Elements.Visible = true
	Window.Navigation.Visible = true
end

local function Minimize(Window)
	Window.Controls.ToggleSize.ImageLabel.Image = "rbxassetid://11036884234"
	Window.Elements.Visible = false
	Window.Navigation.Visible = false
	tween(Window, {Size = MinSize})
end

function Luna:CreateWindow(WindowSettings)

	WindowSettings = Kwargify({
		Name = "Luna UI Example Window",
		Subtitle = "",
		LogoID = "6031097225",
		LoadingEnabled = false,
		LoadingTitle = "Luna Interface Suite",
		LoadingSubtitle = "by Nebula Softworks",

		ConfigSettings = {},

		KeySystem = false,
		KeySettings = {}
	}, WindowSettings or {})

	WindowSettings.ConfigSettings = Kwargify({
		RootFolder = nil,
		ConfigFolder = "Big Hub"
	}, WindowSettings.ConfigSettings or {})

	WindowSettings.KeySettings = Kwargify({
		Title = WindowSettings.Name,
		Subtitle = "Key System",
		Note = "No Instructions",
		SaveInRoot = false,
		SaveKey = true,
		Key = {""},
		SecondAction = {}
	}, WindowSettings.KeySettings or {})

	WindowSettings.KeySettings.SecondAction = Kwargify({
		Enabled = false,
		Type = "Discord",
		Parameter = ""
	}, WindowSettings.KeySettings.SecondAction)

	local Passthrough = false

	local Window = { Bind = Enum.KeyCode.K, CurrentTab = nil, State = true, Size = false, Settings = nil }

	Main.Title.Title.Text = WindowSettings.Name
	Main.Title.subtitle.Text = WindowSettings.Subtitle

	if WindowSettings.Name == "BladeX" then
		Main.Title.Title.TextTransparency = 1
		local TitleImg = Instance.new("ImageLabel", Main)
		TitleImg.Name = "TitleImage"
		TitleImg.Size = UDim2.new(0, 130, 0, 28)
		TitleImg.Position = UDim2.new(0, 88, 0, 11)
		TitleImg.AnchorPoint = Vector2.new(0, 0)
		TitleImg.BackgroundTransparency = 1
		TitleImg.Image = "rbxassetid://12187371840"
		TitleImg.ScaleType = Enum.ScaleType.Fit
		TitleImg.ImageTransparency = 0
		TitleImg.ZIndex = 20
		TitleImg.Visible = true
	end
	Main.Logo.Image = "rbxassetid://" .. WindowSettings.LogoID
	Main.Visible = true
	Main.BackgroundTransparency = 1
	Main.Size = MainSize
	Main.Size = UDim2.fromOffset(Main.Size.X.Offset - 70, Main.Size.Y.Offset - 55)
	Main.Parent.ShadowHolder.Size = Main.Size
	LoadingFrame.Frame.Frame.Title.TextTransparency = 1
	LoadingFrame.Frame.Frame.Subtitle.TextTransparency = 1
	LoadingFrame.Version.TextTransparency = 1
	LoadingFrame.Frame.ImageLabel.ImageTransparency = 1

	tween(Elements.Parent, {BackgroundTransparency = 1})
	Elements.Parent.Visible = false

	LoadingFrame.Frame.Frame.Title.Text = WindowSettings.LoadingTitle
	LoadingFrame.Frame.Frame.Subtitle.Text = WindowSettings.LoadingSubtitle
	LoadingFrame.Version.Text = ""

	-- Fix 2.6: GetUserThumbnailAsync envuelto en pcall para evitar crash por timeout/error de red
	do
		local okThumb, thumbUrl = pcall(function()
			return Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		Navigation.Player.icon.ImageLabel.Image = okThumb and thumbUrl or "rbxassetid://0"
	end
	Navigation.Player.Namez.Text = Players.LocalPlayer.DisplayName
	Navigation.Player.TextLabel.Text = Players.LocalPlayer.Name

	for i,v in pairs(Main.Controls:GetChildren()) do
		v.Visible = false
	end

	Main.Parent.ShadowHolder.Visible = false
	Main.Parent.ShadowHolder.Visible = false
	Main:GetPropertyChangedSignal("Position"):Connect(function()
		Main.Parent.ShadowHolder.Position = Main.Position
	end)
	Main:GetPropertyChangedSignal("Size"):Connect(function()
		Main.Parent.ShadowHolder.Size = Main.Size
	end)

	LoadingFrame.Visible = true

	if not WindowSettings.KeySystem then
		LunaUI.Enabled = true
		-- Fix: solo activar BlurModule cuando NO hay KeySystem activo
		BlurModule(Main)
	end

	if WindowSettings.KeySystem then
		local KeySettings = WindowSettings.KeySettings

		Main.Visible = false
		LoadingFrame.Visible = false
	pcall(function() LoadingFrame.Active = false end)
		LunaUI.Enabled = false
		pcall(function()
			LunaUI.SmartWindow.Visible = false
			local sh = LunaUI:FindFirstChild("ShadowHolder")
			if sh then
				sh.Visible = false
				sh.BackgroundTransparency = 1
				for _, c in ipairs(sh:GetDescendants()) do
					if c:IsA("ImageLabel") or c:IsA("Frame") then
						pcall(function() c.Visible = false end)
					end
				end
			end
		end)

		Draggable(Dragger, Main)
	pcall(function() Draggable(LunaUI.MobileSupport, LunaUI.MobileSupport) end)
		if dragBar then Draggable(dragInteract, Main, true, 255) end

		if not WindowSettings.KeySettings then
			Passthrough = true
			return
		end

		-- Fix 2.2: Función recursiva para crear carpetas anidadas con pcall
		local function createFolderRecursive(path)
			local parts = {}
			for part in path:gmatch("[^/\\]+") do
				table.insert(parts, part)
			end
			local current = ""
			for i, part in ipairs(parts) do
				current = current == "" and part or (current .. "/" .. part)
				pcall(function()
					if not isfolder(current) then makefolder(current) end
				end)
			end
		end

		WindowSettings.KeySettings.FileName = "key"

		if typeof(WindowSettings.KeySettings.Key) == "string" then WindowSettings.KeySettings.Key = {WindowSettings.KeySettings.Key} end

		local direc = WindowSettings.KeySettings.SaveInRoot and "Luna/Configurations/" .. WindowSettings.ConfigSettings.RootFolder .. "/" .. WindowSettings.ConfigSettings.ConfigFolder .. "/Key System/" or "Luna/Configurations/" ..  WindowSettings.ConfigSettings.ConfigFolder .. "/Key System/"

		if isfile and isfile(direc .. WindowSettings.KeySettings.FileName .. ".luna") then
			local savedKey = readfile(direc .. WindowSettings.KeySettings.FileName .. ".luna")
			local savedValid = false
			if #WindowSettings.KeySettings.Key > 0 then
				for i, Key in ipairs(WindowSettings.KeySettings.Key) do
					if savedKey == Key then
						savedValid = true
						Passthrough = true
						break
					end
				end
				if not savedValid then
					pcall(writefile, direc .. WindowSettings.KeySettings.FileName .. ".luna", "")
					pcall(delfile, direc .. WindowSettings.KeySettings.FileName .. ".luna")
				end
			else
				Passthrough = true
			end
		end

		if Passthrough then
			LunaUI.Enabled = true
			Main.Visible = true
			Main.BackgroundTransparency = 1
			LoadingFrame.Visible = true
			LoadingFrame.BackgroundTransparency = 0
			pcall(function() Main.Parent.Visible = true end)
			pcall(function() Main.Parent.ShadowHolder.Visible = true end)
			-- Fix: activar BlurModule aquí cuando la key ya está guardada (Passthrough)
			BlurModule(Main)
		end

		if not Passthrough then
			local KGui = Instance.new("ScreenGui")
			KGui.Name = "BladeXKeyUI"
			KGui.ResetOnSpawn = false
			KGui.DisplayOrder = 999999999
			KGui.IgnoreGuiInset = true
			if gethui then
				KGui.Parent = gethui()
			else
				pcall(function() KGui.Parent = game:GetService("CoreGui") end)
				if not KGui.Parent or not KGui.Parent:IsA("Instance") then
					KGui.Parent = Players.LocalPlayer.PlayerGui
				end
			end

			local Panel = Instance.new("Frame", KGui)
			Panel.Size = UDim2.new(0, 400, 0, 265)
			Panel.Position = UDim2.new(0.5, 0, 0.5, 0)
			Panel.AnchorPoint = Vector2.new(0.5, 0.5)
			Panel.ClipsDescendants = true
			Panel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
			Panel.BackgroundTransparency = 0
			Panel.BorderSizePixel = 0
			Panel.ZIndex = 2
			Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 14)
			local PStroke = Instance.new("UIStroke", Panel)
			PStroke.Color = Color3.fromRGB(50, 50, 50)
			PStroke.Thickness = 1
			PStroke.Transparency = 0.4

			local Header = Instance.new("Frame", Panel)
			Header.Size = UDim2.new(1, 0, 0, 60)
			Header.Position = UDim2.new(0, 0, 0, 0)
			Header.BackgroundTransparency = 1
			Header.ZIndex = 3

			local Logo = Instance.new("ImageLabel", Header)
			Logo.Size = UDim2.new(0, 36, 0, 36)
			Logo.Position = UDim2.new(0, 14, 0.5, -18)
			Logo.BackgroundTransparency = 1
			Logo.Image = "rbxassetid://113679886240651"
			Logo.ZIndex = 3
			Instance.new("UICorner", Logo).CornerRadius = UDim.new(0, 8)

			local Title = Instance.new("TextLabel", Header)
			Title.Size = UDim2.new(1, -110, 0, 20)
			Title.Position = UDim2.new(0, 58, 0, 12)
			Title.BackgroundTransparency = 1
			Title.Text = WindowSettings.KeySettings.Title
			Title.TextColor3 = Color3.fromRGB(255, 255, 255)
			Title.Font = Enum.Font.GothamBold
			Title.TextSize = 15
			Title.TextXAlignment = Enum.TextXAlignment.Left
			Title.ZIndex = 3

			local Subtitle = Instance.new("TextLabel", Header)
			Subtitle.Size = UDim2.new(1, -110, 0, 16)
			Subtitle.Position = UDim2.new(0, 58, 0, 34)
			Subtitle.BackgroundTransparency = 1
			Subtitle.Text = WindowSettings.KeySettings.Subtitle
			Subtitle.TextColor3 = Color3.fromRGB(160, 160, 160)
			Subtitle.Font = Enum.Font.Gotham
			Subtitle.TextSize = 11
			Subtitle.TextXAlignment = Enum.TextXAlignment.Left
			Subtitle.ZIndex = 3

			local MinBtnFrame = Instance.new("Frame", Panel)
			MinBtnFrame.Size = UDim2.new(0, 28, 0, 28)
			MinBtnFrame.Position = UDim2.new(1, -72, 0, 14)
			MinBtnFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			MinBtnFrame.BorderSizePixel = 0
			MinBtnFrame.ZIndex = 6
			Instance.new("UICorner", MinBtnFrame).CornerRadius = UDim.new(0, 7)
			local MinImg = Instance.new("ImageButton", MinBtnFrame)
			MinImg.Size = UDim2.new(0, 16, 0, 16)
			MinImg.Position = UDim2.new(0.5, -8, 0.5, -8)
			MinImg.BackgroundTransparency = 1
			MinImg.Image = "http://www.roblox.com/asset/?id=10137941941"
			MinImg.ImageColor3 = Color3.fromRGB(195, 195, 195)
			MinImg.ZIndex = 7
			local minimized = false
			local panelFullSize = UDim2.new(0, 400, 0, 265)
			local panelMinSize  = UDim2.new(0, 400, 0, 58)
			local hideOnMin = {}
			MinImg.MouseEnter:Connect(function()
				TweenService:Create(MinImg, TweenInfo.new(0.15), {ImageColor3 = Color3.new(1,1,1)}):Play()
			end)
			MinImg.MouseLeave:Connect(function()
				TweenService:Create(MinImg, TweenInfo.new(0.15), {ImageColor3 = Color3.fromRGB(195,195,195)}):Play()
			end)
			MinImg.MouseButton1Click:Connect(function()
				minimized = not minimized
				if minimized then
					MinImg.Image = "http://www.roblox.com/asset/?id=11036884234"
					TweenService:Create(Panel, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Size = panelMinSize}):Play()
					task.wait(0.15)
					for _, c in ipairs(hideOnMin) do c.Visible = false end
				else
					MinImg.Image = "http://www.roblox.com/asset/?id=10137941941"
					for _, c in ipairs(hideOnMin) do c.Visible = true end
					TweenService:Create(Panel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = panelFullSize}):Play()
				end
			end)

			local CloseBtnFrame = Instance.new("Frame", Panel)
			CloseBtnFrame.Size = UDim2.new(0, 28, 0, 28)
			CloseBtnFrame.Position = UDim2.new(1, -38, 0, 14)
			CloseBtnFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			CloseBtnFrame.BorderSizePixel = 0
			CloseBtnFrame.ZIndex = 6
			Instance.new("UICorner", CloseBtnFrame).CornerRadius = UDim.new(0, 7)
			local CloseImg = Instance.new("ImageButton", CloseBtnFrame)
			CloseImg.Size = UDim2.new(0, 16, 0, 16)
			CloseImg.Position = UDim2.new(0.5, -8, 0.5, -8)
			CloseImg.BackgroundTransparency = 1
			CloseImg.Image = "http://www.roblox.com/asset/?id=6031094678"
			CloseImg.ImageColor3 = Color3.fromRGB(195, 195, 195)
			CloseImg.ZIndex = 7
			local CloseBtn = CloseImg
			CloseImg.MouseEnter:Connect(function()
				TweenService:Create(CloseImg, TweenInfo.new(0.15), {ImageColor3 = Color3.new(1,1,1)}):Play()
			end)
			CloseImg.MouseLeave:Connect(function()
				TweenService:Create(CloseImg, TweenInfo.new(0.15), {ImageColor3 = Color3.fromRGB(195,195,195)}):Play()
			end)

			local Sep = Instance.new("Frame", Panel)
			Sep.Size = UDim2.new(1, -28, 0, 1)
			Sep.Position = UDim2.new(0, 14, 0, 62)
			Sep.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
			Sep.BorderSizePixel = 0
			Sep.ZIndex = 3

			local InputFrame = Instance.new("Frame", Panel)
			InputFrame.Size = UDim2.new(1, -28, 0, 38)
			InputFrame.Position = UDim2.new(0, 14, 0, 76)
			InputFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
			InputFrame.BorderSizePixel = 0
			InputFrame.ZIndex = 3
			Instance.new("UICorner", InputFrame).CornerRadius = UDim.new(0, 8)
			local IStroke = Instance.new("UIStroke", InputFrame)
			IStroke.Color = Color3.fromRGB(50, 50, 50)
			IStroke.Thickness = 1
			IStroke.Transparency = 0.4

			local KeyIcon = Instance.new("ImageLabel", InputFrame)
			KeyIcon.Size = UDim2.new(0, 18, 0, 18)
			KeyIcon.Position = UDim2.new(0, 10, 0.5, -9)
			KeyIcon.BackgroundTransparency = 1
			KeyIcon.Image = "http://www.roblox.com/asset/?id=6026568224"
			KeyIcon.ImageColor3 = Color3.fromRGB(140, 140, 140)
			KeyIcon.ZIndex = 4

			local InputBox = Instance.new("TextBox", InputFrame)
			InputBox.Size = UDim2.new(1, -44, 1, 0)
			InputBox.Position = UDim2.new(0, 38, 0, 0)
			InputBox.BackgroundTransparency = 1
			InputBox.PlaceholderText = "Enter Key here..."
			InputBox.PlaceholderColor3 = Color3.fromRGB(70, 70, 70)
			InputBox.Text = ""
			InputBox.TextColor3 = Color3.fromRGB(220, 220, 220)
			InputBox.Font = Enum.Font.Gotham
			InputBox.TextSize = 13
			InputBox.ClearTextOnFocus = false
			InputBox.TextXAlignment = Enum.TextXAlignment.Left
			InputBox.ZIndex = 4

			local GetKeyBtn = Instance.new("TextButton", Panel)
			GetKeyBtn.Size = UDim2.new(0.48, -7, 0, 36)
			GetKeyBtn.Position = UDim2.new(0, 14, 0, 126)
			GetKeyBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
			GetKeyBtn.Text = ""
			GetKeyBtn.BorderSizePixel = 0
			GetKeyBtn.ZIndex = 3
			Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 8)
			local GStroke = Instance.new("UIStroke", GetKeyBtn)
			GStroke.Color = Color3.fromRGB(60, 60, 60)
			GStroke.Thickness = 1.2
			GStroke.Transparency = 0.3
			local GIcon = Instance.new("ImageLabel", GetKeyBtn)
			GIcon.Size = UDim2.new(0, 16, 0, 16)
			GIcon.Position = UDim2.new(0, 10, 0.5, -8)
			GIcon.BackgroundTransparency = 1
			GIcon.Image = "http://www.roblox.com/asset/?id=6026568211"
			GIcon.ImageColor3 = Color3.fromRGB(200, 200, 200)
			GIcon.ZIndex = 4
			local GText = Instance.new("TextLabel", GetKeyBtn)
			GText.Size = UDim2.new(1, -32, 1, 0)
			GText.Position = UDim2.new(0, 32, 0, 0)
			GText.BackgroundTransparency = 1
			GText.Text = "Get Key"
			GText.TextColor3 = Color3.fromRGB(220, 220, 220)
			GText.Font = Enum.Font.GothamBold
			GText.TextSize = 13
			GText.TextXAlignment = Enum.TextXAlignment.Center
			GText.ZIndex = 4

			local VerifyBtn = Instance.new("TextButton", Panel)
			VerifyBtn.Size = UDim2.new(0.48, -7, 0, 36)
			VerifyBtn.Position = UDim2.new(0.52, -7, 0, 126)
			VerifyBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
			VerifyBtn.Text = ""
			VerifyBtn.BorderSizePixel = 0
			VerifyBtn.ZIndex = 3
			Instance.new("UICorner", VerifyBtn).CornerRadius = UDim.new(0, 8)
			local VStroke = Instance.new("UIStroke", VerifyBtn)
			VStroke.Color = Color3.fromRGB(60, 60, 60)
			VStroke.Thickness = 1.2
			VStroke.Transparency = 0.3
			local VIcon = Instance.new("ImageLabel", VerifyBtn)
			VIcon.Size = UDim2.new(0, 16, 0, 16)
			VIcon.Position = UDim2.new(0, 10, 0.5, -8)
			VIcon.BackgroundTransparency = 1
			VIcon.Image = "http://www.roblox.com/asset/?id=6023426909"
			VIcon.ImageColor3 = Color3.fromRGB(100, 220, 160)
			VIcon.ZIndex = 4
			local VText = Instance.new("TextLabel", VerifyBtn)
			VText.Size = UDim2.new(1, -32, 1, 0)
			VText.Position = UDim2.new(0, 32, 0, 0)
			VText.BackgroundTransparency = 1
			VText.Text = "Verify Key"
			VText.TextColor3 = Color3.fromRGB(220, 220, 220)
			VText.Font = Enum.Font.GothamBold
			VText.TextSize = 13
			VText.TextXAlignment = Enum.TextXAlignment.Center
			VText.ZIndex = 4

			local Note = Instance.new("TextLabel", Panel)
			Note.Size = UDim2.new(1, -28, 0, 16)
			Note.Position = UDim2.new(0, 14, 0, 174)
			Note.BackgroundTransparency = 1
			Note.Text = WindowSettings.KeySettings.Note
			Note.TextColor3 = Color3.fromRGB(100, 100, 100)
			Note.Font = Enum.Font.Gotham
			Note.TextSize = 11
			Note.TextXAlignment = Enum.TextXAlignment.Center
			Note.ZIndex = 3

			local DiscordBtn = Instance.new("TextButton", Panel)
			DiscordBtn.Size = UDim2.new(1, -28, 0, 40)
			DiscordBtn.Position = UDim2.new(0, 14, 0, 198)
			DiscordBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
			DiscordBtn.Text = ""
			DiscordBtn.BorderSizePixel = 0
			DiscordBtn.ZIndex = 3
			Instance.new("UICorner", DiscordBtn).CornerRadius = UDim.new(0, 10)
			local DStroke = Instance.new("UIStroke", DiscordBtn)
			DStroke.Color = Color3.fromRGB(88, 101, 242)
			DStroke.Thickness = 1.5
			DStroke.Transparency = 0.2
			local DGrad = Instance.new("UIGradient", DiscordBtn)
			DGrad.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 35)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 20))
			}
			DGrad.Rotation = 90
			local DIcon = Instance.new("ImageLabel", DiscordBtn)
			DIcon.Size = UDim2.new(0, 20, 0, 20)
			DIcon.Position = UDim2.new(0, 14, 0.5, -10)
			DIcon.BackgroundTransparency = 1
			DIcon.Image = "http://www.roblox.com/asset/?id=6031225819"
			DIcon.ImageColor3 = Color3.fromRGB(88, 101, 242)
			DIcon.ZIndex = 4
			local DText = Instance.new("TextLabel", DiscordBtn)
			DText.Size = UDim2.new(1, -44, 1, 0)
			DText.Position = UDim2.new(0, 44, 0, 0)
			DText.BackgroundTransparency = 1
			DText.Text = "Join our Discord"
			DText.TextColor3 = Color3.fromRGB(220, 220, 220)
			DText.Font = Enum.Font.GothamBold
			DText.TextSize = 14
			DText.TextXAlignment = Enum.TextXAlignment.Center
			DText.ZIndex = 4

			local StatusLabel = Instance.new("TextLabel", Panel)
			StatusLabel.Size = UDim2.new(1, -28, 0, 16)
			StatusLabel.Position = UDim2.new(0, 14, 0, 248)
			StatusLabel.BackgroundTransparency = 1
			StatusLabel.Text = ""
				StatusLabel.TextColor3 = Color3.fromRGB(100, 220, 160)
			StatusLabel.Font = Enum.Font.GothamBold
			StatusLabel.TextSize = 11
			StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
			StatusLabel.ZIndex = 3

			table.insert(hideOnMin, Sep)
			table.insert(hideOnMin, InputFrame)
			table.insert(hideOnMin, GetKeyBtn)
			table.insert(hideOnMin, VerifyBtn)
			table.insert(hideOnMin, Note)
			table.insert(hideOnMin, DiscordBtn)
			table.insert(hideOnMin, StatusLabel)

			local dragging = false
			local dragStart, startPos
			Header.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					dragStart = input.Position
					startPos = Panel.Position
					input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then
							dragging = false
						end
					end)
				end
			end)
			game:GetService("UserInputService").InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local delta = input.Position - dragStart
					Panel.Position = UDim2.new(
						startPos.X.Scale,
						startPos.X.Offset + delta.X,
						startPos.Y.Scale,
						startPos.Y.Offset + delta.Y
					)
				end
			end)

			CloseBtn.MouseButton1Click:Connect(function()
				KGui:Destroy()
				Luna:Destroy()
			end)

			GetKeyBtn.MouseButton1Click:Connect(function()
				local link = "https://discord.com/invite/GB5C5CKDk"
				local opened = false
				pcall(function() openurl(link) opened = true end)
				if not opened then pcall(function() syn.open_url(link) opened = true end) end
				if not opened then pcall(function() open_url(link) opened = true end) end
				pcall(setclipboard, link)
				StatusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
				StatusLabel.Text = opened and "Abriendo Discord..." or "Link copiado al portapapeles!"
			end)

			DiscordBtn.MouseButton1Click:Connect(function()
				local link = "https://discord.com/invite/GB5C5CKDk"
				local opened = false
				pcall(function() openurl(link) opened = true end)
				if not opened then pcall(function() syn.open_url(link) opened = true end) end
				if not opened then pcall(function() open_url(link) opened = true end) end
				pcall(setclipboard, link)
				StatusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
				StatusLabel.Text = opened and "Abriendo Discord..." or "Link copiado al portapapeles!"
			end)

			VerifyBtn.MouseButton1Click:Connect(function()
				local entered = InputBox.Text
				if entered == "" then return end
				local KeyFound = false
				local FoundKey = ""
				for _, Key in ipairs(WindowSettings.KeySettings.Key) do
					if entered == Key then
						KeyFound = true
						FoundKey = Key
						break
					end
				end
				if KeyFound then
					StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
					StatusLabel.Text = "✔ Key correcta! Cargando..."
					task.wait(0.4)
					if WindowSettings.KeySettings.SaveKey and writefile then
						pcall(function()
							-- Fix 2.2: Crear subcarpetas recursivamente
							createFolderRecursive(direc)
							writefile(direc .. WindowSettings.KeySettings.FileName .. ".luna", FoundKey)
						end)
					end
					KGui:Destroy()
					Passthrough = true
					LunaUI.Enabled = true
					Main.Visible = true
					Main.BackgroundTransparency = 1
					LoadingFrame.Visible = true
					LoadingFrame.BackgroundTransparency = 0
					pcall(function() Main.Parent.Visible = true end)
					pcall(function() Main.Parent.ShadowHolder.Visible = true end)
					-- Fix: activar BlurModule después de verificar la key correctamente
					BlurModule(Main)
				else
					StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
					StatusLabel.Text = "✖ Key incorrecta. Intenta de nuevo."
					task.wait(2)
					StatusLabel.Text = ""
				StatusLabel.TextColor3 = Color3.fromRGB(100, 220, 160)
				end
			end)

			repeat task.wait(0.05) until Passthrough or not KGui.Parent

		end
	end

	if WindowSettings.KeySystem then
		repeat task.wait() until Passthrough
	end

	if WindowSettings.LoadingEnabled then
		task.wait(0.3)
		TweenService:Create(LoadingFrame.Frame.Frame.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
		TweenService:Create(LoadingFrame.Frame.ImageLabel, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
		task.wait(0.05)
		TweenService:Create(LoadingFrame.Frame.Frame.Subtitle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
		TweenService:Create(LoadingFrame.Version, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
		task.wait(0.29)
		TweenService:Create(LoadingFrame.Frame.ImageLabel, TweenInfo.new(1.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 2, false, 0.2), {Rotation = 450}):Play()

		task.wait(3.32)

		TweenService:Create(LoadingFrame.Frame.Frame.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
		TweenService:Create(LoadingFrame.Frame.ImageLabel, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
		task.wait(0.05)
		TweenService:Create(LoadingFrame.Frame.Frame.Subtitle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
		TweenService:Create(LoadingFrame.Version, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
		task.wait(0.3)
		TweenService:Create(LoadingFrame, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
	end

	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundTransparency = 0.2, Size = MainSize}):Play()
	TweenService:Create(Main.Parent.ShadowHolder, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = MainSize}):Play()
	if not Main.Title:FindFirstChild("TitleImage") then
		TweenService:Create(Main.Title.Title, TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
	end
	TweenService:Create(Main.Title.subtitle, TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
	TweenService:Create(Main.Logo, TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
	TweenService:Create(Navigation.Player.icon.ImageLabel, TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
	TweenService:Create(Navigation.Player.icon.UIStroke, TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Transparency = 0}):Play()
	TweenService:Create(Main.Line, TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
	task.wait(0.4)
	LoadingFrame.Visible = false
	pcall(function() LoadingFrame.Active = false end)

	Draggable(Dragger, Main)
	pcall(function() Draggable(LunaUI.MobileSupport, LunaUI.MobileSupport) end)
	if dragBar then
		dragBar.Size = _dragBarOriginalSize
		dragBar.Visible = true
		dragBar.BackgroundTransparency = 1
		Draggable(dragInteract, Main, true, 255)
	end

	Elements.Template.LayoutOrder = 1000000000
	Elements.Template.Visible = false
	Navigation.Tabs["InActive Template"].LayoutOrder = 1000000000
	Navigation.Tabs["InActive Template"].Visible = false

	local FirstTab = true

	function Window:CreateHomeTab(HomeTabSettings)

		HomeTabSettings = Kwargify({
			Icon = 1,
			SupportedExecutors = {"Vega X", "Delta", "Nihon", "Xeno"},
			DiscordInvite = "GB5C5CKDk"
		}, HomeTabSettings or {})

		local HomeTab = {}

		local HomeTabButton = Navigation.Tabs.Home
		HomeTabButton.Visible = true
		if HomeTabSettings.Icon == 2 then
			HomeTabButton.ImageLabel.Image = GetIcon("dashboard", "Material")
		end

		local HomeTabPage = Elements.Home
		HomeTabPage.Visible = true

		function HomeTab:Activate()
			tween(HomeTabButton.ImageLabel, {ImageColor3 = Color3.fromRGB(255,255,255)})
			tween(HomeTabButton, {BackgroundTransparency = 0})
			tween(HomeTabButton.UIStroke, {Transparency = 0.41})

			Elements.UIPageLayout:JumpTo(HomeTabPage)

			task.wait(0.05)

			for _, OtherTabButton in ipairs(Navigation.Tabs:GetChildren()) do
				if OtherTabButton.Name ~= "InActive Template" and OtherTabButton.ClassName == "Frame" and OtherTabButton ~= HomeTabButton then
					tween(OtherTabButton.ImageLabel, {ImageColor3 = Color3.fromRGB(221,221,221)})
					tween(OtherTabButton, {BackgroundTransparency = 1})
					tween(OtherTabButton.UIStroke, {Transparency = 1})
				end

			end

			Window.CurrentTab = "Home"
		end

		HomeTab:Activate()
		FirstTab = false
		HomeTabButton.Interact.MouseButton1Click:Connect(function()
			HomeTab:Activate()
		end)

		-- Fix 2.6: GetUserThumbnailAsync envuelto en pcall (HomeTab)
		do
			local okThumb2, thumbUrl2 = pcall(function()
				return Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
			end)
			HomeTabPage.icon.ImageLabel.Image = okThumb2 and thumbUrl2 or "rbxassetid://0"
		end
		HomeTabPage.player.Text.Text = "Hello, " .. Players.LocalPlayer.DisplayName
		HomeTabPage.player.user.Text = Players.LocalPlayer.Name .. " - ".. WindowSettings.Name

		-- Fix 2.11: identifyexecutor envuelto en pcall para ejecutores que no lo soportan
		local _executorName = "Executor desconocido"
		if isStudio then
			_executorName = "Debugging (Studio)"
		else
			local okExec, execName = pcall(identifyexecutor)
			_executorName = (okExec and execName) or "Tu executor no soporta identifyexecutor."
		end
		HomeTabPage.detailsholder.dashboard.Client.Title.Text = _executorName
		for i,v in pairs(HomeTabSettings.SupportedExecutors) do
			if isStudio then HomeTabPage.detailsholder.dashboard.Client.Subtitle.Text = "Luna Interface Suite - Debugging Mode" break end
			local okExec2, execName2 = pcall(identifyexecutor)
			if execName2 and v == execName2 then
				HomeTabPage.detailsholder.dashboard.Client.Subtitle.Text = "Your Executor Supports This Script."
				break
			else
				HomeTabPage.detailsholder.dashboard.Client.Subtitle.Text = "Your Executor Isn't Officialy Supported By This Script."
				break
			end
		end

		HomeTabPage.detailsholder.dashboard.Discord.Interact.MouseButton1Click:Connect(function()
			pcall(function() openurl("https://discord.gg/GB5C5CKDk") end)
			pcall(function() syn.open_url("https://discord.gg/GB5C5CKDk") end)
			pcall(setclipboard, "https://discord.gg/GB5C5CKDk")
		end)

		local friendsCooldown = 0
		local function getPing() return math.clamp(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue(), 10, 700) end

		local function checkFriends()
			if friendsCooldown == 0 then

				friendsCooldown = 25

				local playersFriends = {}
				local friendsInTotal = 0
				local onlineFriends = 0
				local friendsInGame = 0

				local list = Players:GetFriendsAsync(Player.UserId)
				while true do
					for _, data in list:GetCurrentPage() do
						friendsInTotal +=1
						table.insert(playersFriends, Data)
					end

					if list.IsFinished then
						break
					else
						list:AdvanceToNextPageAsync()
					end
				end
				for i, v in pairs(Player:GetFriendsOnline()) do
					onlineFriends += 1
				end

				for i,v in pairs(playersFriends) do
					if Players:FindFirstChild(v.Username) then
						friendsInGame = friendsInGame + 1
					end
				end

				HomeTabPage.detailsholder.dashboard.Friends.All.Value.Text = tostring(friendsInTotal).." friends"
				HomeTabPage.detailsholder.dashboard.Friends.Offline.Value.Text = tostring(friendsInTotal - onlineFriends).." friends"
				HomeTabPage.detailsholder.dashboard.Friends.Online.Value.Text = tostring(onlineFriends).." friends"
				HomeTabPage.detailsholder.dashboard.Friends.InGame.Value.Text = tostring(friendsInGame).." friends"

			else
				friendsCooldown -= 1
			end
		end

		local function format(Int)
			return string.format("%02i", Int)
		end

		local function convertToHMS(Seconds)
			local Minutes = (Seconds - Seconds%60)/60
			Seconds = Seconds - Minutes*60
			local Hours = (Minutes - Minutes%60)/60
			Minutes = Minutes - Hours*60
			return format(Hours)..":"..format(Minutes)..":"..format(Seconds)
		end

		coroutine.wrap(function()
			while task.wait() do

				HomeTabPage.detailsholder.dashboard.Server.Players.Value.Text = #Players:GetPlayers().." playing"
				HomeTabPage.detailsholder.dashboard.Server.MaxPlayers.Value.Text = Players.MaxPlayers.." players can join this server"

				HomeTabPage.detailsholder.dashboard.Server.Latency.Value.Text = isStudio and tostring(math.round((Players.LocalPlayer:GetNetworkPing() * 2 ) / 0.01)) .."ms" or tostring(math.floor(getPing()) .."ms")

				HomeTabPage.detailsholder.dashboard.Server.Time.Value.Text = convertToHMS(time())

				HomeTabPage.detailsholder.dashboard.Server.Region.Value.Text = Localization:GetCountryRegionForPlayerAsync(Players.LocalPlayer)

				checkFriends()
			end
		end)()

	end

	function Window:CreateTab(TabSettings)

		local Tab = {}

		TabSettings = Kwargify({
			Name = "Tab",
			ShowTitle = true,
			Icon = "view_in_ar",
			ImageSource = "Material"
		}, TabSettings or {})

		local TabButton = Navigation.Tabs["InActive Template"]:Clone()

		TabButton.Name = TabSettings.Name
		TabButton.TextLabel.Text = TabSettings.Name
		TabButton.Parent = Navigation.Tabs
		TabButton.ImageLabel.Image = GetIcon(TabSettings.Icon, TabSettings.ImageSource)

		TabButton.Visible = true

		local TabPage = Elements.Template:Clone()
		TabPage.Name = TabSettings.Name
		TabPage.Title.Visible = TabSettings.ShowTitle
		TabPage.Title.Text = TabSettings.Name
		TabPage.Visible = true

		Tab.Page = TabPage

		if TabSettings.ShowTitle == false then
			TabPage.UIPadding.PaddingTop = UDim.new(0,10)
		end

		TabPage.LayoutOrder = #Elements:GetChildren() - 3

		for _, TemplateElement in ipairs(TabPage:GetChildren()) do
			if TemplateElement.ClassName == "Frame" or TemplateElement.ClassName == "TextLabel" and TemplateElement.Name ~= "Title" then
				TemplateElement:Destroy()
			end
		end
		TabPage.Parent = Elements

		function Tab:Activate()
			tween(TabButton.ImageLabel, {ImageColor3 = Color3.fromRGB(255,255,255)})
			tween(TabButton, {BackgroundTransparency = 0})
			tween(TabButton.UIStroke, {Transparency = 0.41})

			Elements.UIPageLayout:JumpTo(TabPage)

			task.wait(0.05)

			for _, OtherTabButton in ipairs(Navigation.Tabs:GetChildren()) do
				if OtherTabButton.Name ~= "InActive Template" and OtherTabButton.ClassName == "Frame" and OtherTabButton ~= TabButton then
					tween(OtherTabButton.ImageLabel, {ImageColor3 = Color3.fromRGB(221,221,221)})
					tween(OtherTabButton, {BackgroundTransparency = 1})
					tween(OtherTabButton.UIStroke, {Transparency = 1})
				end

			end

			Window.CurrentTab = TabSettings.Name
		end

		if FirstTab then
			Tab:Activate()
		end

		task.wait(0.01)

		TabButton.Interact.MouseButton1Click:Connect(function()
			Tab:Activate()
		end)

		FirstTab = false

		function Tab:CreateSection(name : string)

			local Section = {}

			if name == nil then name = "Section" end

			Section.Name = name

			local Sectiont = Elements.Template.Section:Clone()
			Sectiont.Text = name
			Sectiont.Visible = true
			Sectiont.Parent = TabPage
			local TabPage = Sectiont.Frame

			Sectiont.TextTransparency = 1
			tween(Sectiont, {TextTransparency = 0})

			function Section:Set(NewSection)
				Sectiont.Text = NewSection
			end

			function Section:Destroy()
				Sectiont:Destroy()
			end

			function Section:CreateDivider()
				TabPage.Position = UDim2.new(0,0,0,28)
				local b = Elements.Template.Divider:Clone()
				b.Parent = TabPage
				b.Size = UDim2.new(1,0,0,18)
				b.Line.BackgroundTransparency = 1
				tween(b.Line, {BackgroundTransparency = 0})
			end

			function Section:CreateButton(ButtonSettings)
				TabPage.Position = UDim2.new(0,0,0,28)

				ButtonSettings = Kwargify({
					Name = "Button",
					Description = nil,
					Callback = function()

					end,
				}, ButtonSettings or {})

				local ButtonV = {
					Hover = false,
					Settings = ButtonSettings
				}

				local Button
				if ButtonSettings.Description == nil or ButtonSettings.Description == "" then
					Button = Elements.Template.Button:Clone()
				else
					Button = Elements.Template.ButtonDesc:Clone()
				end
				Button.Name = ButtonSettings.Name
				Button.Title.Text = ButtonSettings.Name
				if ButtonSettings.Description ~= nil and ButtonSettings.Description ~= "" then
					Button.Desc.Text = ButtonSettings.Description
				end
				Button.Visible = true
				Button.Parent = TabPage

				Button.UIStroke.Transparency = 1
				Button.Title.TextTransparency = 1
				if ButtonSettings.Description ~= nil and ButtonSettings.Description ~= "" then
					Button.Desc.TextTransparency = 1
				end

				TweenService:Create(Button, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
				TweenService:Create(Button.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
				TweenService:Create(Button.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
				if ButtonSettings.Description ~= nil and ButtonSettings.Description ~= "" then
					TweenService:Create(Button.Desc, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
				end

				Button.Interact["MouseButton1Click"]:Connect(function()
					local Success,Response = pcall(ButtonSettings.Callback)

					if not Success then
						TweenService:Create(Button, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
						TweenService:Create(Button, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
						TweenService:Create(Button.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
						Button.Title.Text = "Callback Error"
						print("Luna Interface Suite | "..ButtonSettings.Name.." Callback Error " ..tostring(Response))
						task.wait(0.5)
						Button.Title.Text = ButtonSettings.Name
						TweenService:Create(Button, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
						TweenService:Create(Button, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
						TweenService:Create(Button.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
					else
						tween(Button.UIStroke, {Color = Color3.fromRGB(136, 131, 163)})
						task.wait(0.2)
						if ButtonV.Hover then
							tween(Button.UIStroke, {Color = Color3.fromRGB(87, 84, 104)})
						else
							tween(Button.UIStroke, {Color = Color3.fromRGB(64,61,76)})
						end
					end
				end)

				Button["MouseEnter"]:Connect(function()
					ButtonV.Hover = true
					tween(Button.UIStroke, {Color = Color3.fromRGB(87, 84, 104)})
				end)

				Button["MouseLeave"]:Connect(function()
					ButtonV.Hover = false
					tween(Button.UIStroke, {Color = Color3.fromRGB(64,61,76)})
				end)

				function ButtonV:Set(ButtonSettings2)
					ButtonSettings2 = Kwargify({
						Name = ButtonSettings.Name,
						Description = ButtonSettings.Description,
						Callback = ButtonSettings.Callback
					}, ButtonSettings2 or {})

					ButtonSettings = ButtonSettings2
					ButtonV.Settings = ButtonSettings2

					Button.Name = ButtonSettings.Name
					Button.Title.Text = ButtonSettings.Name
					if ButtonSettings.Description ~= nil and ButtonSettings.Description ~= "" and Button.Desc ~= nil then
						Button.Desc.Text = ButtonSettings.Description
					end
				end

				function ButtonV:Destroy()
					Button.Visible = false
					Button:Destroy()
				end

				return ButtonV
			end

			function Section:CreateLabel(LabelSettings)
				TabPage.Position = UDim2.new(0,0,0,28)

				local LabelV = {}

				LabelSettings = Kwargify({
					Text = "Label",
					Style = 1
				}, LabelSettings or {})

				LabelV.Settings = LabelSettings

				local Label
				if LabelSettings.Style == 1 then
					Label = Elements.Template.Label:Clone()
				elseif LabelSettings.Style == 2 then
					Label = Elements.Template.Info:Clone()
				elseif LabelSettings.Style == 3 then
					Label = Elements.Template.Warn:Clone()
				end

				Label.Text.Text = LabelSettings.Text
				Label.Visible = true
				Label.Parent = TabPage

				Label.BackgroundTransparency = 1
				Label.UIStroke.Transparency = 1
				Label.Text.TextTransparency = 1

				if LabelSettings.Style ~= 1 then
					TweenService:Create(Label, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.8}):Play()
				else
					TweenService:Create(Label, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
				end
				TweenService:Create(Label.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
				TweenService:Create(Label.Text, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

				function LabelV:Set(NewLabel)
					LabelSettings.Text = NewLabel
					LabelV.Settings = LabelSettings
					Label.Text.Text = NewLabel
				end

				function LabelV:Destroy()
					Label.Visible = false
					Label:Destroy()
				end

				return LabelV
			end

			function Section:CreateParagraph(ParagraphSettings)
				TabPage.Position = UDim2.new(0,0,0,28)

				ParagraphSettings = Kwargify({
					Title = "Paragraph",
					Text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus venenatis lacus sed tempus eleifend. Mauris interdum bibendum felis, in tempor augue egestas vel. Praesent tristique consectetur ex, eu pretium sem placerat non. Vestibulum a nisi sit amet augue facilisis consectetur sit amet et nunc. Integer fermentum ornare cursus. Pellentesque sed ultricies metus, ut egestas metus. Vivamus auctor erat ac sapien vulputate, nec ultricies sem tempor. Quisque leo lorem, faucibus nec pulvinar nec, congue eu velit. Duis sodales massa efficitur imperdiet ultrices. Donec eros ipsum, ornare pharetra purus aliquam, tincidunt elementum nisi. Ut mi tortor, feugiat eget nunc vitae, facilisis interdum dui. Vivamus ullamcorper nunc dui, a dapibus nisi pretium ac. Integer eleifend placerat nibh, maximus malesuada tellus. Cras in justo in ligula scelerisque suscipit vel vitae quam."
				}, ParagraphSettings or {})

				local ParagraphV = {
					Settings = ParagraphSettings
				}

				local Paragraph = Elements.Template.Paragraph:Clone()
				Paragraph.Title.Text = ParagraphSettings.Title
				Paragraph.Text.Text = ParagraphSettings.Text
				Paragraph.Visible = true
				Paragraph.Parent = TabPage

				Paragraph.BackgroundTransparency = 1
				Paragraph.UIStroke.Transparency = 1
				Paragraph.Title.TextTransparency = 1
				Paragraph.Text.TextTransparency = 1

				TweenService:Create(Paragraph, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
				TweenService:Create(Paragraph.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
				TweenService:Create(Paragraph.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
				TweenService:Create(Paragraph.Text, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

				function ParagraphV:Update()
					Paragraph.Text.Size = UDim2.new(Paragraph.Text.Size.X.Scale, Paragraph.Text.Size.X.Offset, 0, math.huge)
					Paragraph.Text.Size = UDim2.new(Paragraph.Text.Size.X.Scale, Paragraph.Text.Size.X.Offset, 0, Paragraph.Text.TextBounds.Y)
					tween(Paragraph, {Size = UDim2.new(Paragraph.Size.X.Scale, Paragraph.Size.X.Offset, 0, Paragraph.Text.TextBounds.Y + 40)})
				end

				function ParagraphV:Set(NewParagraphSettings)

					NewParagraphSettings = Kwargify({
						Title = ParagraphSettings.Title,
						Text = ParagraphSettings.Text
					}, NewParagraphSettings or {})

					ParagraphV.Settings = NewParagraphSettings

					Paragraph.Title.Text = NewParagraphSettings.Title
					Paragraph.Text.Text = NewParagraphSettings.Text

					ParagraphV:Update()

				end

				function ParagraphV:Destroy()
					Paragraph.Visible = false
					Paragraph:Destroy()
				end

				ParagraphV:Update()

				return ParagraphV
			end

			function Section:CreateSlider(SliderSettings, Flag)
				TabPage.Position = UDim2.new(0,0,0,28)
				local SliderV = { IgnoreConfig = false, Class = "Slider", Settings = SliderSettings }

				SliderSettings = Kwargify({
					Name = "Slider",
					Range = {0, 200},
					Increment = 1,
					CurrentValue = 100,
					Callback = function(Value)

					end,
				}, SliderSettings or {})

				local SLDragging = false
				local Slider = Elements.Template.Slider:Clone()
				Slider.Name = SliderSettings.Name .. " - Slider"
				Slider.Title.Text = SliderSettings.Name
				Slider.Visible = true
				Slider.Parent = TabPage

				Slider.BackgroundTransparency = 1
				Slider.UIStroke.Transparency = 1
				Slider.Title.TextTransparency = 1

				TweenService:Create(Slider, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
				TweenService:Create(Slider.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
				TweenService:Create(Slider.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

				Slider.Main.Progress.Size =	UDim2.new(0, Slider.Main.AbsoluteSize.X * ((SliderSettings.CurrentValue + SliderSettings.Range[1]) / (SliderSettings.Range[2] - SliderSettings.Range[1])) > 5 and Slider.Main.AbsoluteSize.X * (SliderSettings.CurrentValue / (SliderSettings.Range[2] - SliderSettings.Range[1])) or 5, 1, 0)

				Slider.Value.Text = tostring(SliderSettings.CurrentValue)
				SliderV.CurrentValue = Slider.Value.Text

				SliderSettings.Callback(SliderSettings.CurrentValue)

				Slider["MouseEnter"]:Connect(function()
					tween(Slider.UIStroke, {Color = Color3.fromRGB(87, 84, 104)})
				end)

				Slider["MouseLeave"]:Connect(function()
					tween(Slider.UIStroke, {Color = Color3.fromRGB(64,61,76)})
				end)

				Slider.Interact.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
						SLDragging = true
					end
				end)

				Slider.Interact.InputEnded:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
						SLDragging = false
					end
				end)

				Slider.Interact.MouseButton1Down:Connect(function()
					local Current = Slider.Main.Progress.AbsolutePosition.X + Slider.Main.Progress.AbsoluteSize.X
					local Start = Current
					local Location
					local Loop; Loop = RunService.Stepped:Connect(function()
						if SLDragging then
							Location = UserInputService:GetMouseLocation().X
							Current = Current + 0.025 * (Location - Start)

							if Location < Slider.Main.AbsolutePosition.X then
								Location = Slider.Main.AbsolutePosition.X
							elseif Location > Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X then
								Location = Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X
							end

							if Current < Slider.Main.AbsolutePosition.X + 5 then
								Current = Slider.Main.AbsolutePosition.X + 5
							elseif Current > Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X then
								Current = Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X
							end

							if Current <= Location and (Location - Start) < 0 then
								Start = Location
							elseif Current >= Location and (Location - Start) > 0 then
								Start = Location
							end
							Slider.Main.Progress.Size = UDim2.new(0, Location - Slider.Main.AbsolutePosition.X, 1, 0)
							local NewValue = SliderSettings.Range[1] + (Location - Slider.Main.AbsolutePosition.X) / Slider.Main.AbsoluteSize.X * (SliderSettings.Range[2] - SliderSettings.Range[1])

							NewValue = math.floor(NewValue / SliderSettings.Increment + 0.5) * (SliderSettings.Increment * 10000000) / 10000000

							Slider.Value.Text = tostring(NewValue)

							if SliderSettings.CurrentValue ~= NewValue then
								local Success, Response = pcall(function()
									SliderSettings.Callback(NewValue)
								end)
								if not Success then
									TweenService:Create(Slider, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
									TweenService:Create(Slider, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
									TweenService:Create(Slider.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
									Slider.Title.Text = "Callback Error"
									print("Luna Interface Suite | "..SliderSettings.Name.." Callback Error " ..tostring(Response))
									task.wait(0.5)
									Slider.Title.Text = SliderSettings.Name
									TweenService:Create(Slider, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
									TweenService:Create(Slider, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
									TweenService:Create(Slider.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
								end

								SliderSettings.CurrentValue = NewValue
								SliderV.CurrentValue = SliderSettings.CurrentValue
							end
						else
							TweenService:Create(Slider.Main.Progress, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.In, 0, false), {Size = UDim2.new(0, Location - Slider.Main.AbsolutePosition.X > 5 and Location - Slider.Main.AbsolutePosition.X or 5, 1, 0)}):Play()
							Loop:Disconnect()
						end
					end)
				end)

				local function Set(NewVal, bleh)

					NewVal = NewVal or SliderSettings.CurrentValue

					TweenService:Create(Slider.Main.Progress, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), {Size = UDim2.new(0, Slider.Main.AbsoluteSize.X * ((NewVal + SliderSettings.Range[1]) / (SliderSettings.Range[2] - SliderSettings.Range[1])) > 5 and Slider.Main.AbsoluteSize.X * (NewVal / (SliderSettings.Range[2] - SliderSettings.Range[1])) or 5, 1, 0)}):Play()
					if not bleh then Slider.Value.Text = tostring(NewVal) end
					local Success, Response = pcall(function()
						SliderSettings.Callback(NewVal)
					end)
					if not Success then
						TweenService:Create(Slider, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
						TweenService:Create(Slider, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
						TweenService:Create(Slider.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
						Slider.Title.Text = "Callback Error"
						print("Luna Interface Suite | "..SliderSettings.Name.." Callback Error " ..tostring(Response))
						task.wait(0.5)
						Slider.Title.Text = SliderSettings.Name
						TweenService:Create(Slider, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
						TweenService:Create(Slider, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(30, 33, 40)}):Play()
						TweenService:Create(Slider.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
					end

					SliderSettings.CurrentValue = NewVal
					SliderV.CurrentValue = SliderSettings.CurrentValue

				end

				function SliderV:UpdateValue(Value)
					Set(tonumber(Value))
				end

				Slider.Value:GetPropertyChangedSignal("Text"):Connect(function()
					local text = Slider.Value.Text
					if not tonumber(text) and text ~= "." then
						Slider.Value.Text = text:match("[0-9.]*") or ""
					end
					if SliderSettings.Range[2] < (tonumber(Slider.Value.Text) or 0) then Slider.Value.Text = SliderSettings.Range[2] end
					Slider.Value.Size = UDim2.fromOffset(Slider.Value.TextBounds.X, 23)
					Set(tonumber(Slider.Value.Text), true)
				end)

				function SliderV:Set(NewSliderSettings)
					NewSliderSettings = Kwargify({
						Name = SliderSettings.Name,
						Range = SliderSettings.Range,
						Increment = SliderSettings.Increment,
						CurrentValue = SliderSettings.CurrentValue,
						Callback = SliderSettings.Callback
					}, NewSliderSettings or {})

					SliderSettings = NewSliderSettings
					SliderV.Settings = NewSliderSettings

					Slider.Name = SliderSettings.Name .. " - Slider"
					Slider.Title.Text = SliderSettings.Name

					Set()

				end

				function SliderV:Destroy()
					Slider.Visible = false
					Slider:Destroy()
				end

				if Flag then
					Luna.Options[Flag] = SliderV
				end

				LunaUI.ThemeRemote:GetPropertyChangedSignal("Value"):Connect(function()
					Slider.Main.color.Color = Luna.ThemeGradient
					Slider.Main.UIStroke.color.Color = Luna.ThemeGradient
				end)

				return SliderV

			end

			function Section:CreateToggle(ToggleSettings, Flag)
				TabPage.Position = UDim2.new(0,0,0,28)
				local ToggleV = { IgnoreConfig = false, Class = "Toggle" }

				ToggleSettings = Kwargify({
					Name = "Toggle",
					Description = nil,
					CurrentValue = false,
					Callback = function(Value)
					end,
				}, ToggleSettings or {})

				local Toggle

				if ToggleSettings.Description ~= nil and ToggleSettings.Description ~= "" then
					Toggle = Elements.Template.ToggleDesc:Clone()
				else
					Toggle = Elements.Template.Toggle:Clone()
				end

				Toggle.Visible = true
				Toggle.Parent = TabPage

				Toggle.Name = ToggleSettings.Name .. " - Toggle"
				Toggle.Title.Text = ToggleSettings.Name
				if ToggleSettings.Description ~= nil and ToggleSettings.Description ~= "" then
					Toggle.Desc.Text = ToggleSettings.Description
				end

				Toggle.UIStroke.Transparency = 1
				Toggle.Title.TextTransparency = 1
				if ToggleSettings.Description ~= nil and ToggleSettings.Description ~= "" then
					Toggle.Desc.TextTransparency = 1
				end

				TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
				if ToggleSettings.Description ~= nil and ToggleSettings.Description ~= "" then
					TweenService:Create(Toggle.Desc, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
				end
				TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
				TweenService:Create(Toggle.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

				local function Set(bool)
					if bool then
						Toggle.toggle.color.Enabled = true
						tween(Toggle.toggle, {BackgroundTransparency = 0})

						Toggle.toggle.UIStroke.color.Enabled = true
						tween(Toggle.toggle.UIStroke, {Color = Color3.new(255,255,255)})

						tween(Toggle.toggle.val, {BackgroundColor3 = Color3.fromRGB(255,255,255), Position = UDim2.new(1,-23,0.5,0), BackgroundTransparency = 0.45})
					else
						Toggle.toggle.color.Enabled = false
						Toggle.toggle.UIStroke.color.Enabled = false

						Toggle.toggle.UIStroke.Color = Color3.fromRGB(97,97,97)

						tween(Toggle.toggle, {BackgroundTransparency = 1})

						tween(Toggle.toggle.val, {BackgroundColor3 = Color3.fromRGB(97,97,97), Position = UDim2.new(0,5,0.5,0), BackgroundTransparency = 0})
					end

					ToggleV.CurrentValue = bool
				end

				Toggle.Interact.MouseButton1Click:Connect(function()
					ToggleSettings.CurrentValue = not ToggleSettings.CurrentValue
					Set(ToggleSettings.CurrentValue)

					local Success, Response = pcall(function()
						ToggleSettings.Callback(ToggleSettings.CurrentValue)
					end)
					if not Success then
						TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
						TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
						TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
						Toggle.Title.Text = "Callback Error"
						print("Luna Interface Suite | "..ToggleSettings.Name.." Callback Error " ..tostring(Response))
						task.wait(0.5)
						Toggle.Title.Text = ToggleSettings.Name
						TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
						TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
						TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
					end
				end)

				Toggle["MouseEnter"]:Connect(function()
					tween(Toggle.UIStroke, {Color = Color3.fromRGB(87, 84, 104)})
				end)

				Toggle["MouseLeave"]:Connect(function()
					tween(Toggle.UIStroke, {Color = Color3.fromRGB(64,61,76)})
				end)

				if ToggleSettings.CurrentValue then
					Set(ToggleSettings.CurrentValue)
					local Success, Response = pcall(function()
						ToggleSettings.Callback(ToggleSettings.CurrentValue)
					end)
					if not Success then
						TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
						TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
						TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
						Toggle.Title.Text = "Callback Error"
						print("Luna Interface Suite | "..ToggleSettings.Name.." Callback Error " ..tostring(Response))
						task.wait(0.5)
						Toggle.Title.Text = ToggleSettings.Name
						TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
						TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
						TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
					end
				end

				function ToggleV:UpdateState(State)
					ToggleSettings.CurrentValue = State
					Set(ToggleSettings.CurrentValue)
				end

				function ToggleV:Set(NewToggleSettings)

					NewToggleSettings = Kwargify({
						Name = ToggleSettings.Name,
						Description = ToggleSettings.Description,
						CurrentValue = ToggleSettings.CurrentValue,
						Callback = ToggleSettings.Callback
					}, NewToggleSettings or {})

					ToggleV.Settings = NewToggleSettings
					ToggleSettings = NewToggleSettings

					Toggle.Name = ToggleSettings.Name .. " - Toggle"
					Toggle.Title.Text = ToggleSettings.Name
					if ToggleSettings.Description ~= nil and ToggleSettings.Description ~= "" and Toggle.Desc ~= nil then
						Toggle.Desc.Text = ToggleSettings.Description
					end

					Set(ToggleSettings.CurrentValue)

					ToggleV.CurrentValue = ToggleSettings.CurrentValue

					local Success, Response = pcall(function()
						ToggleSettings.Callback(ToggleSettings.CurrentValue)
					end)
					if not Success then
						TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
						TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
						TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
						Toggle.Title.Text = "Callback Error"
						print("Luna Interface Suite | "..ToggleSettings.Name.." Callback Error " ..tostring(Response))
						task.wait(0.5)
						Toggle.Title.Text = ToggleSettings.Name
						TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
						TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
						TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
					end
				end

				function ToggleV:Destroy()
					Toggle.Visible = false
					Toggle:Destroy()
				end

				LunaUI.ThemeRemote:GetPropertyChangedSignal("Value"):Connect(function()
					Toggle.toggle.color.Color = Luna.ThemeGradient
					Toggle.toggle.UIStroke.color.Color = Luna.ThemeGradient
				end)

				if Flag then
					Luna.Options[Flag] = ToggleV
				end

				return ToggleV

			end

			function Section:CreateBind(BindSettings, Flag)
				TabPage.Position = UDim2.new(0,0,0,28)
				local BindV = { Class = "Keybind", IgnoreConfig = false, Settings = BindSettings, Active = false }

				BindSettings = Kwargify({
					Name = "Bind",
					Description = nil,
					CurrentBind = "Q",
					HoldToInteract = false,
					Callback = function(Bind)
					end,

					OnChangedCallback = function(Bind)
					end,
				}, BindSettings or {})

				local CheckingForKey = false

				local Bind
				if BindSettings.Description ~= nil and BindSettings.Description ~= "" then
					Bind = Elements.Template.BindDesc:Clone()
				else
					Bind = Elements.Template.Bind:Clone()
				end

				Bind.Visible = true
				Bind.Parent = TabPage

				Bind.Name = BindSettings.Name
				Bind.Title.Text = BindSettings.Name
				if BindSettings.Description ~= nil and BindSettings.Description ~= "" then
					Bind.Desc.Text = BindSettings.Description
				end

				Bind.Title.TextTransparency = 1
				if BindSettings.Description ~= nil and BindSettings.Description ~= "" then
					Bind.Desc.TextTransparency = 1
				end
				Bind.BindFrame.BackgroundTransparency = 1
				Bind.BindFrame.UIStroke.Transparency = 1
				Bind.BindFrame.BindBox.TextTransparency = 1

				TweenService:Create(Bind, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
				TweenService:Create(Bind.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
				if BindSettings.Description ~= nil and BindSettings.Description ~= "" then
					TweenService:Create(Bind.Desc, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
				end
				TweenService:Create(Bind.BindFrame, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.9}):Play()
				TweenService:Create(Bind.BindFrame.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0.3}):Play()
				TweenService:Create(Bind.BindFrame.BindBox, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

				Bind.BindFrame.BindBox.Text = BindSettings.CurrentBind
				Bind.BindFrame.BindBox.Size = UDim2.new(0, Bind.BindFrame.BindBox.TextBounds.X + 20, 0, 42)

				Bind.BindFrame.BindBox.Focused:Connect(function()
					CheckingForKey = true
					Bind.BindFrame.BindBox.Text = ""
				end)

				Bind.BindFrame.BindBox.FocusLost:Connect(function()
					CheckingForKey = false
					if Bind.BindFrame.BindBox.Text == (nil or "") then
						Bind.BindFrame.BindBox.Text = BindSettings.CurrentBind
					end
				end)

				Bind["MouseEnter"]:Connect(function()
					tween(Bind.UIStroke, {Color = Color3.fromRGB(87, 84, 104)})
				end)

				Bind["MouseLeave"]:Connect(function()
					tween(Bind.UIStroke, {Color = Color3.fromRGB(64,61,76)})
				end)
				UserInputService.InputBegan:Connect(function(input, processed)

					if CheckingForKey then
						if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Window.Bind then
							local SplitMessage = string.split(tostring(input.KeyCode), ".")
							local NewKeyNoEnum = SplitMessage[3]
							Bind.BindFrame.BindBox.Text = tostring(NewKeyNoEnum)
							BindSettings.CurrentBind = tostring(NewKeyNoEnum)
							local Success, Response = pcall(function()
								BindSettings.OnChangedCallback(BindSettings.CurrentBind)
							end)
							if not Success then
								TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
								TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
								TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
								Bind.Title.Text = "Callback Error"
								print("Luna Interface Suite | "..BindSettings.Name.." Callback Error " ..tostring(Response))
								task.wait(0.5)
								Bind.Title.Text = BindSettings.Name
								TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
								TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
								TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
							end
							Bind.BindFrame.BindBox:ReleaseFocus()
						end
					elseif BindSettings.CurrentBind ~= nil and (input.KeyCode == Enum.KeyCode[BindSettings.CurrentBind] and not processed) then
						local Held = true
						local Connection
						Connection = input.Changed:Connect(function(prop)
							if prop == "UserInputState" then
								Connection:Disconnect()
								Held = false
							end
						end)

						if not BindSettings.HoldToInteract then
							BindV.Active = not BindV.Active
							local Success, Response = pcall(function()
								BindSettings.Callback(BindV.Active)
							end)
							if not Success then
								TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
								TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
								TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
								Bind.Title.Text = "Callback Error"
								print("Luna Interface Suite | "..BindSettings.Name.." Callback Error " ..tostring(Response))
								task.wait(0.5)
								Bind.Title.Text = BindSettings.Name
								TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
								TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
								TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
							end
						else
							task.wait(0.1)
							if Held then
								local Loop; Loop = RunService.Stepped:Connect(function()
									if not Held then
										local Success, Response = pcall(function()
											BindSettings.Callback(false)
										end)
										if not Success then
											TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
											TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
											TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
											Bind.Title.Text = "Callback Error"
											print("Luna Interface Suite | "..BindSettings.Name.." Callback Error " ..tostring(Response))
											task.wait(0.5)
											Bind.Title.Text = BindSettings.Name
											TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
											TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
											TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
										end
										Loop:Disconnect()
									else
										local Success, Response = pcall(function()
											BindSettings.Callback(true)
										end)
										if not Success then
											TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
											TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
											TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
											Bind.Title.Text = "Callback Error"
											print("Luna Interface Suite | "..BindSettings.Name.." Callback Error " ..tostring(Response))
											task.wait(0.5)
											Bind.Title.Text = BindSettings.Name
											TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
											TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
											TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
										end
									end
								end)
							end
						end
					end
				end)

				Bind.BindFrame.BindBox:GetPropertyChangedSignal("Text"):Connect(function()
					TweenService:Create(Bind.BindFrame, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Bind.BindFrame.BindBox.TextBounds.X + 20, 0, 30)}):Play()
				end)

				function BindV:Set(NewBindSettings)

					NewBindSettings = Kwargify({
						Name = BindSettings.Name,
						Description = BindSettings.Description,
						CurrentBind =  BindSettings.CurrentBind,
						HoldToInteract = BindSettings.HoldToInteract,
						Callback = BindSettings.Callback
					}, NewBindSettings or {})

					BindV.Settings = NewBindSettings
					BindSettings = NewBindSettings

					Bind.Name = BindSettings.Name
					Bind.Title.Text = BindSettings.Name
					if BindSettings.Description ~= nil and BindSettings.Description ~= "" and Bind.Desc ~= nil then
						Bind.Desc.Text = BindSettings.Description
					end

					Bind.BindFrame.BindBox.Text = BindSettings.CurrentBind
					Bind.BindFrame.Size = UDim2.new(0, Bind.BindFrame.BindBox.TextBounds.X + 20, 0, 42)

					BindV.CurrentBind = BindSettings.CurrentBind
				end

				function BindV:Destroy()
					Bind.Visible = false
					Bind:Destroy()
				end

				if Flag then
					Luna.Options[Flag] = BindV
				end

				return BindV

			end

			function Section:CreateInput(InputSettings, Flag)
				TabPage.Position = UDim2.new(0,0,0,28)
				local InputV = { IgnoreConfig = false, Class = "Input", Settings = InputSettings }

				InputSettings = Kwargify({
					Name = "Dynamic Input",
					Description = nil,
					CurrentValue = "",
					PlaceholderText = "Input Placeholder",
					RemoveTextAfterFocusLost = false,
					Numeric = false,
					Enter = false,
					MaxCharacters = nil,
					Callback = function(Text)

					end,
				}, InputSettings or {})

				InputV.CurrentValue = InputSettings.CurrentValue

				local descriptionbool
				if InputSettings.Description ~= nil and InputSettings.Description ~= "" then
					descriptionbool = true
				end

				local Input
				if descriptionbool then
					Input = Elements.Template.InputDesc:Clone()
				else
					Input = Elements.Template.Input:Clone()
				end

				Input.Name = InputSettings.Name
				Input.Title.Text = InputSettings.Name
				if descriptionbool then Input.Desc.Text = InputSettings.Description end
				Input.Visible = true
				Input.Parent = TabPage

				Input.BackgroundTransparency = 1
				Input.UIStroke.Transparency = 1
				Input.Title.TextTransparency = 1
				if descriptionbool then Input.Desc.TextTransparency = 1 end
				Input.InputFrame.BackgroundTransparency = 1
				Input.InputFrame.UIStroke.Transparency = 1
				Input.InputFrame.InputBox.TextTransparency = 1

				TweenService:Create(Input, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
				TweenService:Create(Input.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
				TweenService:Create(Input.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
				if descriptionbool then TweenService:Create(Input.Desc, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play() end
				TweenService:Create(Input.InputFrame, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.9}):Play()
				TweenService:Create(Input.InputFrame.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0.3}):Play()
				TweenService:Create(Input.InputFrame.InputBox, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

				Input.InputFrame.InputBox.PlaceholderText = InputSettings.PlaceholderText
				Input.InputFrame.Size = UDim2.new(0, Input.InputFrame.InputBox.TextBounds.X + 52, 0, 30)

				Input.InputFrame.InputBox.FocusLost:Connect(function(bleh)

					if InputSettings.Enter then
						if bleh then
							local Success, Response = pcall(function()
								InputSettings.Callback(Input.InputFrame.InputBox.Text)
								InputV.CurrentValue = Input.InputFrame.InputBox.Text
							end)
							if not Success then
								TweenService:Create(Input, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
								TweenService:Create(Input, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
								TweenService:Create(Input.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
								Input.Title.Text = "Callback Error"
								print("Luna Interface Suite | "..InputSettings.Name.." Callback Error " ..tostring(Response))
								task.wait(0.5)
								Input.Title.Text = InputSettings.Name
								TweenService:Create(Input, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
								TweenService:Create(Input, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
								TweenService:Create(Input.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
							end
						end
					end

					if InputSettings.RemoveTextAfterFocusLost then
						Input.InputFrame.InputBox.Text = ""
					end

				end)

				if InputSettings.Numeric then
					Input.InputFrame.InputBox:GetPropertyChangedSignal("Text"):Connect(function()
						local text = Input.InputFrame.InputBox.Text
						if not tonumber(text) and text ~= "." then
							Input.InputFrame.InputBox.Text = text:match("[0-9.]*") or ""
						end
					end)
				end

				Input.InputFrame.InputBox:GetPropertyChangedSignal("Text"):Connect(function()
					if tonumber(InputSettings.MaxCharacters) then
						if (#Input.InputFrame.InputBox.Text - 1) == InputSettings.MaxCharacters then
							Input.InputFrame.InputBox.Text = Input.InputFrame.InputBox.Text:sub(1, InputSettings.MaxCharacters)
						end
					end
					TweenService:Create(Input.InputFrame, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Input.InputFrame.InputBox.TextBounds.X + 52, 0, 30)}):Play()
					if not InputSettings.Enter then
						local Success, Response = pcall(function()
							InputSettings.Callback(Input.InputFrame.InputBox.Text)
						end)
						if not Success then
							TweenService:Create(Input, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
							TweenService:Create(Input, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
							TweenService:Create(Input.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
							Input.Title.Text = "Callback Error"
							print("Luna Interface Suite | "..InputSettings.Name.." Callback Error " ..tostring(Response))
							task.wait(0.5)
							Input.Title.Text = InputSettings.Name
							TweenService:Create(Input, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
							TweenService:Create(Input, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
							TweenService:Create(Input.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
						end
					end
					InputV.CurrentValue = Input.InputFrame.InputBox.Text
				end)

				Input["MouseEnter"]:Connect(function()
					tween(Input.UIStroke, {Color = Color3.fromRGB(87, 84, 104)})
				end)

				Input["MouseLeave"]:Connect(function()
					tween(Input.UIStroke, {Color = Color3.fromRGB(64,61,76)})
				end)

				function InputV:Set(NewInputSettings)

					NewInputSettings = Kwargify(InputSettings, NewInputSettings or {})

					InputV.Settings = NewInputSettings
					InputSettings = NewInputSettings

					Input.Name = InputSettings.Name
					Input.Title.Text = InputSettings.Name
					if InputSettings.Description ~= nil and InputSettings.Description ~= "" and Input.Desc ~= nil then
						Input.Desc.Text = InputSettings.Description
					end

					Input.InputFrame.InputBox:CaptureFocus()
					Input.InputFrame.InputBox.Text = tostring(InputSettings.CurrentValue)
					Input.InputFrame.InputBox:ReleaseFocus()
					Input.InputFrame.Size = UDim2.new(0, Input.InputFrame.InputBox.TextBounds.X + 52, 0, 42)

					InputV.CurrentValue = InputSettings.CurrentValue
				end

				function InputV:Destroy()
					Input.Visible = false
					Input:Destroy()
				end

				if Flag then
					Luna.Options[Flag] = InputV
				end

				return InputV

			end

			function Section:CreateDropdown(DropdownSettings, Flag)
				TabPage.Position = UDim2.new(0,0,0,28)
				local DropdownV = { IgnoreConfig = false, Class = "Dropdown", Settings = DropdownSettings}

				DropdownSettings = Kwargify({
					Name = "Dropdown",
					Description = nil,
					Options = {"Option 1", "Option 2"},
					CurrentOption = {"Option 1"},
					MultipleOptions = false,
					SpecialType = nil,
					Callback = function(Options)
					end,
				}, DropdownSettings or {})

				DropdownV.CurrentOption = DropdownSettings.CurrentOption

				local descriptionbool = false
				if DropdownSettings.Description ~= nil and DropdownSettings.Description ~= "" then
					descriptionbool = true
				end
				local closedsize
				local openedsize
				if descriptionbool then
					closedsize = 48
					openedsize = 170
				elseif not descriptionbool then
					closedsize = 38
					openedsize = 160
				end
				local opened = false

				local Dropdown
				if descriptionbool then Dropdown = Elements.Template.DropdownDesc:Clone() else Dropdown = Elements.Template.Dropdown:Clone() end

				Dropdown.Name = DropdownSettings.Name
				Dropdown.Title.Text = DropdownSettings.Name
				if descriptionbool then Dropdown.Desc.Text = DropdownSettings.Description end

				Dropdown.Parent = TabPage
				Dropdown.Visible = true

				local function Toggle()
					opened = not opened
					if opened then
						tween(Dropdown.icon, {Rotation = 180})
						tween(Dropdown, {Size = UDim2.new(1, -25, 0, openedsize)})
					else
						tween(Dropdown.icon, {Rotation = 0})
						tween(Dropdown, {Size = UDim2.new(1, -25, 0, closedsize)})
					end
				end

				local function SafeCallback(param, c2)
					local Success, Response = pcall(function()
						DropdownSettings.Callback(param)
					end)
					if not Success then
						TweenService:Create(Dropdown, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
						TweenService:Create(Dropdown, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
						TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
						Dropdown.Title.Text = "Callback Error"
						print("Luna Interface Suite | "..DropdownSettings.Name.." Callback Error " ..tostring(Response))
						task.wait(0.5)
						Dropdown.Title.Text = DropdownSettings.Name
						TweenService:Create(Dropdown, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
						TweenService:Create(Dropdown, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
						TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
					end
					if Success and c2 then
						c2()
					end
				end

				Dropdown.Selected:GetPropertyChangedSignal("Text"):Connect(function()
					local text = Dropdown.Selected.Text:lower()
					for _, Item in ipairs(Dropdown.List:GetChildren()) do
						if Item:IsA("TextLabel") and Item.Name ~= "Template" then
							Item.Visible = text == "" or string.find(Item.Name:lower(), text, 1, true) ~= nil
						end
					end
				end)

				local function Clear()
					for _, option in ipairs(Dropdown.List:GetChildren()) do
						if option.ClassName == "TextLabel" and option.Name ~= "Template" then
							option:Destroy()
						end
					end
				end

				local function ActivateColorSingle(name)
					for _, Option in pairs(Dropdown.List:GetChildren()) do
						if Option.ClassName == "TextLabel" and Option.Name ~= "Template" then
							tween(Option, {BackgroundTransparency = 0.98})
						end
					end

					Toggle()
					tween(Dropdown.List[name], {BackgroundTransparency = 0.95, TextColor3 = Color3.fromRGB(240,240,240)})
				end

				local function Refresh()
					Clear()
					for i,v in pairs(DropdownSettings.Options) do
						local Option = Dropdown.List.Template:Clone()
						local optionhover = false
						Option.Text = v
						if v == "Template" then v = "Template (Name)" end
						Option.Name = v
						Option.Interact.MouseButton1Click:Connect(function()
							local bleh
							if DropdownSettings.MultipleOptions then
								if table.find(DropdownSettings.CurrentOption, v) then
									RemoveTable(DropdownSettings.CurrentOption, v)
									DropdownV.CurrentOption = DropdownSettings.CurrentOption
									if not optionhover then
										tween(Option, {TextColor3 = Color3.fromRGB(200,200,200)})
									end
									tween(Option, {BackgroundTransparency = 0.98})
								else
									table.insert(DropdownSettings.CurrentOption, v)
									DropdownV.CurrentOption = DropdownSettings.CurrentOption
									tween(Option, {TextColor3 = Color3.fromRGB(240,240,240), BackgroundTransparency = 0.95})
								end
								bleh = DropdownSettings.CurrentOption
							else
								DropdownSettings.CurrentOption = {v}
								bleh = v
								DropdownV.CurrentOption = bleh
								ActivateColorSingle(v)
							end

							SafeCallback(bleh, function()
								if DropdownSettings.MultipleOptions then
									if DropdownSettings.CurrentOption and type(DropdownSettings.CurrentOption) == "table" then
										if #DropdownSettings.CurrentOption == 1 then
											Dropdown.Selected.PlaceholderText = DropdownSettings.CurrentOption[1]
										elseif #DropdownSettings.CurrentOption == 0 then
											Dropdown.Selected.PlaceholderText = "None"
										else
											Dropdown.Selected.PlaceholderText = unpackt(DropdownSettings.CurrentOption)
										end
									else
										DropdownSettings.CurrentOption = {}
										Dropdown.Selected.PlaceholderText = "None"
									end
								end
								if not DropdownSettings.MultipleOptions then
									Dropdown.Selected.PlaceholderText = DropdownSettings.CurrentOption[1] or "None"
								end
								Dropdown.Selected.Text = ""
							end)
						end)
						Option.Visible = true
						Option.Parent = Dropdown.List
						Option.MouseEnter:Connect(function()
							optionhover = true
							if Option.BackgroundTransparency == 0.95 then
								return
							else
								tween(Option, {TextColor3 = Color3.fromRGB(240,240,240)})
							end
						end)
						Option.MouseLeave:Connect(function()
							optionhover = false
							if Option.BackgroundTransparency == 0.95 then
								return
							else
								tween(Option, {TextColor3 = Color3.fromRGB(200,200,200)})
							end
						end)
					end
				end

				local function PlayerTableRefresh()
					for i,v in pairs(DropdownSettings.Options) do
						table.remove(DropdownSettings.Options, i)
					end

					for i,v in pairs(Players:GetChildren()) do
						table.insert(DropdownSettings.Options, v.Name)
					end
				end

				Dropdown.Interact.MouseButton1Click:Connect(function()
					Toggle()
				end)

				Dropdown["MouseEnter"]:Connect(function()
					tween(Dropdown.UIStroke, {Color = Color3.fromRGB(87, 84, 104)})
				end)

				Dropdown["MouseLeave"]:Connect(function()
					tween(Dropdown.UIStroke, {Color = Color3.fromRGB(64,61,76)})
				end)

				if DropdownSettings.SpecialType == "Player" then

					for i,v in pairs(DropdownSettings.Options) do
						table.remove(DropdownSettings.Options, i)
					end
					PlayerTableRefresh()
					DropdownSettings.CurrentOption = DropdownSettings.Options[1]

					Players.PlayerAdded:Connect(function() PlayerTableRefresh() end)
					Players.PlayerRemoving:Connect(function() PlayerTableRefresh() end)

				end

				Refresh()

				if DropdownSettings.CurrentOption then
					if type(DropdownSettings.CurrentOption) == "string" then
						DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption}
					end
					if not DropdownSettings.MultipleOptions and type(DropdownSettings.CurrentOption) == "table" then
						DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption[1]}
					end
				else
					DropdownSettings.CurrentOption = {}
				end

				local bleh, ind = nil,0
				for i,v in pairs(DropdownSettings.CurrentOption) do
					ind = ind + 1
				end
				if ind == 1 then bleh = DropdownSettings.CurrentOption[1] else bleh = DropdownSettings.CurrentOption end
				SafeCallback(bleh)
				if type(bleh) == "string" then
					tween(Dropdown.List[bleh], {TextColor3 = Color3.fromRGB(240,240,240), BackgroundTransparency = 0.95})
				else
					for i,v in pairs(bleh) do
						tween(Dropdown.List[v], {TextColor3 = Color3.fromRGB(240,240,240), BackgroundTransparency = 0.95})
					end
				end

				if DropdownSettings.MultipleOptions then
					if DropdownSettings.CurrentOption and type(DropdownSettings.CurrentOption) == "table" then
						if #DropdownSettings.CurrentOption == 1 then
							Dropdown.Selected.PlaceholderText = DropdownSettings.CurrentOption[1]
						elseif #DropdownSettings.CurrentOption == 0 then
							Dropdown.Selected.PlaceholderText = "None"
						else
							Dropdown.Selected.PlaceholderText = unpackt(DropdownSettings.CurrentOption)
						end
					else
						DropdownSettings.CurrentOption = {}
						Dropdown.Selected.PlaceholderText = "None"
					end
					for _, name in pairs(DropdownSettings.CurrentOption) do
						tween(Dropdown.List[name], {TextColor3 = Color3.fromRGB(227,227,227), BackgroundTransparency = 0.95})
					end
				else
					Dropdown.Selected.PlaceholderText = DropdownSettings.CurrentOption[1] or "None"
				end
				Dropdown.Selected.Text = ""

				function DropdownV:Set(NewDropdownSettings)
					NewDropdownSettings = Kwargify(DropdownSettings, NewDropdownSettings or {})

					DropdownV.Settings = NewDropdownSettings
					DropdownSettings = NewDropdownSettings

					Dropdown.Name = DropdownSettings.Name
					Dropdown.Title.Text = DropdownSettings.Name
					if DropdownSettings.Description ~= nil and DropdownSettings.Description ~= "" and Dropdown.Desc ~= nil then
						Dropdown.Desc.Text = DropdownSettings.Description
					end

					if DropdownSettings.SpecialType == "Player" then

						for i,v in pairs(DropdownSettings.Options) do
							table.remove(DropdownSettings.Options, i)
						end
						PlayerTableRefresh()
						DropdownSettings.CurrentOption = DropdownSettings.Options[1]
						Players.PlayerAdded:Connect(function() PlayerTableRefresh() end)
						Players.PlayerRemoving:Connect(function() PlayerTableRefresh() end)

					end

					Refresh()

					if DropdownSettings.CurrentOption then
						if type(DropdownSettings.CurrentOption) == "string" then
							DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption}
						end
						if not DropdownSettings.MultipleOptions and type(DropdownSettings.CurrentOption) == "table" then
							DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption[1]}
						end
					else
						DropdownSettings.CurrentOption = {}
					end

					local bleh, ind = nil,0
					for i,v in pairs(DropdownSettings.CurrentOption) do
						ind = ind + 1
					end
					if ind == 1 then bleh = DropdownSettings.CurrentOption[1] else bleh = DropdownSettings.CurrentOption end
					SafeCallback(bleh)
					for _, Option in pairs(Dropdown.List:GetChildren()) do
						if Option.ClassName == "TextLabel" then
							tween(Option, {TextColor3 = Color3.fromRGB(200,200,200), BackgroundTransparency = 0.98})
						end
					end
					tween(Dropdown.List[bleh], {TextColor3 = Color3.fromRGB(240,240,240), BackgroundTransparency = 0.95})

					if DropdownSettings.MultipleOptions then
						if DropdownSettings.CurrentOption and type(DropdownSettings.CurrentOption) == "table" then
							if #DropdownSettings.CurrentOption == 1 then
								Dropdown.Selected.PlaceholderText = DropdownSettings.CurrentOption[1]
							elseif #DropdownSettings.CurrentOption == 0 then
								Dropdown.Selected.PlaceholderText = "None"
							else
								Dropdown.Selected.PlaceholderText = unpackt(DropdownSettings.CurrentOption)
							end
						else
							DropdownSettings.CurrentOption = {}
							Dropdown.Selected.PlaceholderText = "None"
						end
						for _, name in pairs(DropdownSettings.CurrentOption) do
							tween(Dropdown.List[name], {TextColor3 = Color3.fromRGB(227,227,227), BackgroundTransparency = 0.95})
						end
					else
						Dropdown.Selected.PlaceholderText = DropdownSettings.CurrentOption[1] or "None"
					end
					Dropdown.Selected.Text = ""

				end

				function DropdownV:Destroy()
					Dropdown.Visible = false
					Dropdown:Destroy()
				end

				if Flag then
					Luna.Options[Flag] = DropdownV
				end

				return DropdownV

			end

			function Section:CreateColorPicker(ColorPickerSettings, Flag)
				TabPage.Position = UDim2.new(0,0,0,28)
				local ColorPickerV = {IgnoreClass = false, Class = "Colorpicker", Settings = ColorPickerSettings}

				ColorPickerSettings = Kwargify({
					Name = "Color Picker",
					Color = Color3.fromRGB(255,255,255),
					Callback = function(Value)
					end
				}, ColorPickerSettings or {})

				local function Color3ToHex(color)
					return string.format("#%02X%02X%02X", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
				end

				ColorPickerV.Color = Color3ToHex(ColorPickerSettings.Color)

				local closedsize = UDim2.new(0, 75, 0, 22)
				local openedsize = UDim2.new(0, 219, 0, 129)

				local ColorPicker = Elements.Template.ColorPicker:Clone()
				local Background = ColorPicker.CPBackground
				local Display = Background.Display
				local Main = Background.MainCP
				local Slider = ColorPicker.ColorSlider

				ColorPicker.Name = ColorPickerSettings.Name
				ColorPicker.Title.Text = ColorPickerSettings.Name
				ColorPicker.Visible = true
				ColorPicker.Parent = TabPage
				ColorPicker.Size = UDim2.new(1.042, -25,0, 38)
				Background.Size = closedsize
				Display.BackgroundTransparency = 0

				ColorPicker["MouseEnter"]:Connect(function()
					tween(ColorPicker.UIStroke, {Color = Color3.fromRGB(87, 84, 104)})
				end)
				ColorPicker["MouseLeave"]:Connect(function()
					tween(ColorPicker.UIStroke, {Color = Color3.fromRGB(64,61,76)})
				end)

				local function SafeCallback(param, c2)
					local Success, Response = pcall(function()
						ColorPickerSettings.Callback(param)
					end)
					if not Success then
						TweenService:Create(ColorPicker, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
						TweenService:Create(ColorPicker, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
						TweenService:Create(ColorPicker.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
						ColorPicker.Title.Text = "Callback Error"
						print("Luna Interface Suite | "..ColorPickerSettings.Name.." Callback Error " ..tostring(Response))
						task.wait(0.5)
						ColorPicker.Title.Text = ColorPickerSettings.Name
						TweenService:Create(ColorPicker, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
						TweenService:Create(ColorPicker, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
						TweenService:Create(ColorPicker.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
					end
					if Success and c2 then
						c2()
					end
				end

				local opened = false

				local mouse = game.Players.LocalPlayer:GetMouse()
				Main.Image = "http://www.roblox.com/asset/?id=11415645739"
				local mainDragging = false
				local sliderDragging = false
				ColorPicker.Interact.MouseButton1Down:Connect(function()
					if not opened then
						opened = true
						tween(ColorPicker, {Size = UDim2.new( 1.042, -25,0, 165)}, nil, TweenInfo.new(0.6, Enum.EasingStyle.Exponential))
						tween(Background, {Size = openedsize})
						tween(Display, {BackgroundTransparency = 1})
					else
						opened = false
						tween(ColorPicker, {Size = UDim2.new(1.042, -25,0, 38)}, nil, TweenInfo.new(0.6, Enum.EasingStyle.Exponential))
						tween(Background, {Size = closedsize})
						tween(Display, {BackgroundTransparency = 0})
					end
				end)
				UserInputService.InputEnded:Connect(function(input, gameProcessed) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						mainDragging = false
						sliderDragging = false
					end end)
				Main.MouseButton1Down:Connect(function()
					if opened then
						mainDragging = true
					end
				end)
				Main.MainPoint.MouseButton1Down:Connect(function()
					if opened then
						mainDragging = true
					end
				end)
				Slider.MouseButton1Down:Connect(function()
					sliderDragging = true
				end)
				Slider.SliderPoint.MouseButton1Down:Connect(function()
					sliderDragging = true
				end)
				local h,s,v = ColorPickerSettings.Color:ToHSV()
				local color = Color3.fromHSV(h,s,v)
				local r,g,b = math.floor((h*255)+0.5),math.floor((s*255)+0.5),math.floor((v*255)+0.5)
				local hex = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
				ColorPicker.HexInput.InputBox.Text = hex
				local function setDisplay(hp,sp,vp)
					Main.MainPoint.Position = UDim2.new(s,-Main.MainPoint.AbsoluteSize.X/2,1-v,-Main.MainPoint.AbsoluteSize.Y/2)
					Main.MainPoint.ImageColor3 = Color3.fromHSV(hp,sp,vp)
					Background.BackgroundColor3 = Color3.fromHSV(hp,1,1)
					Display.BackgroundColor3 = Color3.fromHSV(hp,sp,vp)
					local x = hp * Slider.AbsoluteSize.X
					Slider.SliderPoint.Position = UDim2.new(0,x-Slider.SliderPoint.AbsoluteSize.X/2,0.5,0)
					Slider.SliderPoint.ImageColor3 = Color3.fromHSV(hp,1,1)
					local color = Color3.fromHSV(hp,sp,vp)
					local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
					ColorPicker.RInput.InputBox.Text = tostring(r)
					ColorPicker.GInput.InputBox.Text = tostring(g)
					ColorPicker.BInput.InputBox.Text = tostring(b)
					hex = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
					ColorPicker.HexInput.InputBox.Text = hex
				end
				setDisplay(h,s,v)
				ColorPicker.HexInput.InputBox.FocusLost:Connect(function()
					if not pcall(function()
							local r, g, b = string.match(ColorPicker.HexInput.InputBox.Text, "^#?(%w%w)(%w%w)(%w%w)$")
							local rgbColor = Color3.fromRGB(tonumber(r, 16),tonumber(g, 16), tonumber(b, 16))
							h,s,v = rgbColor:ToHSV()
							hex = ColorPicker.HexInput.InputBox.Text
							setDisplay()
							ColorPickerSettings.Color = rgbColor
						end)
					then
						ColorPicker.HexInput.InputBox.Text = hex
					end
					local r,g,b = math.floor((h*255)+0.5),math.floor((s*255)+0.5),math.floor((v*255)+0.5)
					ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
					SafeCallback( Color3.fromRGB(r,g,b))
				end)
				local function rgbBoxes(box,toChange)
					local value = tonumber(box.Text)
					local color = Color3.fromHSV(h,s,v)
					local oldR,oldG,oldB = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
					local save
					if toChange == "R" then save = oldR;oldR = value elseif toChange == "G" then save = oldG;oldG = value else save = oldB;oldB = value end
					if value then
						value = math.clamp(value,0,255)
						h,s,v = Color3.fromRGB(oldR,oldG,oldB):ToHSV()
						setDisplay()
					else
						box.Text = tostring(save)
					end
					local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
					ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
				end
				ColorPicker.RInput.InputBox.FocusLost:Connect(function()
					rgbBoxes(ColorPicker.RInput.InputBox,"R")
					SafeCallback(Color3.fromRGB(r,g,b))
				end)
				ColorPicker.GInput.InputBox.FocusLost:Connect(function()
					rgbBoxes(ColorPicker.GInput.InputBox,"G")
					SafeCallback(Color3.fromRGB(r,g,b))
				end)
				ColorPicker.BInput.InputBox.FocusLost:Connect(function()
					rgbBoxes(ColorPicker.BInput.InputBox,"B")
					SafeCallback(Color3.fromRGB(r,g,b))
				end)
				RunService.RenderStepped:Connect(function()
					if mainDragging then
						local localX = math.clamp(mouse.X-Main.AbsolutePosition.X,0,Main.AbsoluteSize.X)
						local localY = math.clamp(mouse.Y-Main.AbsolutePosition.Y,0,Main.AbsoluteSize.Y)
						Main.MainPoint.Position = UDim2.new(0,localX-Main.MainPoint.AbsoluteSize.X/2,0,localY-Main.MainPoint.AbsoluteSize.Y/2)
						s = localX / Main.AbsoluteSize.X
						v = 1 - (localY / Main.AbsoluteSize.Y)
						Display.BackgroundColor3 = Color3.fromHSV(h,s,v)
						Main.MainPoint.ImageColor3 = Color3.fromHSV(h,s,v)
						Background.BackgroundColor3 = Color3.fromHSV(h,1,1)
						local color = Color3.fromHSV(h,s,v)
						local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
						ColorPicker.RInput.InputBox.Text = tostring(r)
						ColorPicker.GInput.InputBox.Text = tostring(g)
						ColorPicker.BInput.InputBox.Text = tostring(b)
						ColorPicker.HexInput.InputBox.Text = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
						SafeCallback(Color3.fromRGB(r,g,b))
						ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
						ColorPickerV.Color = ColorPickerSettings.Color
					end
					if sliderDragging then
						local localX = math.clamp(mouse.X-Slider.AbsolutePosition.X,0,Slider.AbsoluteSize.X)
						h = localX / Slider.AbsoluteSize.X
						Display.BackgroundColor3 = Color3.fromHSV(h,s,v)
						Slider.SliderPoint.Position = UDim2.new(0,localX-Slider.SliderPoint.AbsoluteSize.X/2,0.5,0)
						Slider.SliderPoint.ImageColor3 = Color3.fromHSV(h,1,1)
						Background.BackgroundColor3 = Color3.fromHSV(h,1,1)
						Main.MainPoint.ImageColor3 = Color3.fromHSV(h,s,v)
						local color = Color3.fromHSV(h,s,v)
						local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
						ColorPicker.RInput.InputBox.Text = tostring(r)
						ColorPicker.GInput.InputBox.Text = tostring(g)
						ColorPicker.BInput.InputBox.Text = tostring(b)
						ColorPicker.HexInput.InputBox.Text = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
						SafeCallback(Color3.fromRGB(r,g,b))
						ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
						ColorPickerV.Color = ColorPickerSettings.Color
					end
				end)

				function ColorPickerV:Set(NewColorPickerSettings)

					NewColorPickerSettings = Kwargify(ColorPickerSettings, NewColorPickerSettings or {})

					ColorPickerV.Settings = NewColorPickerSettings
					ColorPickerSettings = NewColorPickerSettings

					ColorPicker.Name = ColorPickerSettings.Name
					ColorPicker.Title.Text = ColorPickerSettings.Name
					ColorPicker.Visible = true

					local h,s,v = ColorPickerSettings.Color:ToHSV()
					local color = Color3.fromHSV(h,s,v)
					local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
					local hex = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
					ColorPicker.HexInput.InputBox.Text = hex
					setDisplay(h,s,v)
					SafeCallback(Color3.fromRGB(r,g,b))

					ColorPickerV.Color = ColorPickerSettings.Color
				end

				function ColorPickerV:Destroy()
					ColorPicker:Destroy()
				end

				if Flag then
					Luna.Options[Flag] = ColorPickerV
				end

				SafeCallback(ColorPickerSettings.Color)

				return ColorPickerV
			end

			return Section

		end

		function Tab:CreateDivider()
			local b = Elements.Template.Divider:Clone()
			b.Parent = TabPage
			b.Line.BackgroundTransparency = 1
			tween(b.Line, {BackgroundTransparency = 0})
		end

		function Tab:CreateButton(ButtonSettings)

			ButtonSettings = Kwargify({
				Name = "Button",
				Description = nil,
				Callback = function()

				end,
			}, ButtonSettings or {})

			local ButtonV = {
				Hover = false,
				Settings = ButtonSettings
			}

			local Button
			if ButtonSettings.Description == nil or ButtonSettings.Description == "" then
				Button = Elements.Template.Button:Clone()
			else
				Button = Elements.Template.ButtonDesc:Clone()
			end
			Button.Name = ButtonSettings.Name
			Button.Title.Text = ButtonSettings.Name
			if ButtonSettings.Description ~= nil and ButtonSettings.Description ~= "" then
				Button.Desc.Text = ButtonSettings.Description
			end
			Button.Visible = true
			Button.Parent = TabPage

			Button.UIStroke.Transparency = 1
			Button.Title.TextTransparency = 1
			if ButtonSettings.Description ~= nil and ButtonSettings.Description ~= "" then
				Button.Desc.TextTransparency = 1
			end

			TweenService:Create(Button, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
			TweenService:Create(Button.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
			TweenService:Create(Button.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			if ButtonSettings.Description ~= nil and ButtonSettings.Description ~= "" then
				TweenService:Create(Button.Desc, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			end

			Button.Interact["MouseButton1Click"]:Connect(function()
				local Success,Response = pcall(ButtonSettings.Callback)

				if not Success then
					TweenService:Create(Button, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
					TweenService:Create(Button, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
					TweenService:Create(Button.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					Button.Title.Text = "Callback Error"
					print("Luna Interface Suite | "..ButtonSettings.Name.." Callback Error " ..tostring(Response))
					task.wait(0.5)
					Button.Title.Text = ButtonSettings.Name
					TweenService:Create(Button, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
					TweenService:Create(Button, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
					TweenService:Create(Button.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
				else
					tween(Button.UIStroke, {Color = Color3.fromRGB(136, 131, 163)})
					task.wait(0.2)
					if ButtonV.Hover then
						tween(Button.UIStroke, {Color = Color3.fromRGB(87, 84, 104)})
					else
						tween(Button.UIStroke, {Color = Color3.fromRGB(64,61,76)})
					end
				end
			end)

			Button["MouseEnter"]:Connect(function()
				ButtonV.Hover = true
				tween(Button.UIStroke, {Color = Color3.fromRGB(87, 84, 104)})
			end)

			Button["MouseLeave"]:Connect(function()
				ButtonV.Hover = false
				tween(Button.UIStroke, {Color = Color3.fromRGB(64,61,76)})
			end)

			function ButtonV:Set(ButtonSettings2)
				ButtonSettings2 = Kwargify({
					Name = ButtonSettings.Name,
					Description = ButtonSettings.Description,
					Callback = ButtonSettings.Callback
				}, ButtonSettings2 or {})

				ButtonSettings = ButtonSettings2
				ButtonV.Settings = ButtonSettings2

				Button.Name = ButtonSettings.Name
				Button.Title.Text = ButtonSettings.Name
				if ButtonSettings.Description ~= nil and ButtonSettings.Description ~= "" and Button.Desc ~= nil then
					Button.Desc.Text = ButtonSettings.Description
				end
			end

			function ButtonV:Destroy()
				Button.Visible = false
				Button:Destroy()
			end

			return ButtonV
		end

		function Tab:CreateLabel(LabelSettings)

			local LabelV = {}

			LabelSettings = Kwargify({
				Text = "Label",
				Style = 1
			}, LabelSettings or {})

			LabelV.Settings = LabelSettings

			local Label
			if LabelSettings.Style == 1 then
				Label = Elements.Template.Label:Clone()
			elseif LabelSettings.Style == 2 then
				Label = Elements.Template.Info:Clone()
			elseif LabelSettings.Style == 3 then
				Label = Elements.Template.Warn:Clone()
			end

			Label.Text.Text = LabelSettings.Text
			Label.Visible = true
			Label.Parent = TabPage

			Label.BackgroundTransparency = 1
			Label.UIStroke.Transparency = 1
			Label.Text.TextTransparency = 1

			if LabelSettings.Style ~= 1 then
				TweenService:Create(Label, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.8}):Play()
			else
				TweenService:Create(Label, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
			end
			TweenService:Create(Label.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
			TweenService:Create(Label.Text, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

			function LabelV:Set(NewLabel)
				LabelSettings.Text = NewLabel
				LabelV.Settings = LabelSettings
				Label.Text.Text = NewLabel
			end

			function LabelV:Destroy()
				Label.Visible = false
				Label:Destroy()
			end

			return LabelV
		end

		function Tab:CreateParagraph(ParagraphSettings)

			ParagraphSettings = Kwargify({
				Title = "Paragraph",
				Text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus venenatis lacus sed tempus eleifend. Mauris interdum bibendum felis, in tempor augue egestas vel. Praesent tristique consectetur ex, eu pretium sem placerat non. Vestibulum a nisi sit amet augue facilisis consectetur sit amet et nunc. Integer fermentum ornare cursus. Pellentesque sed ultricies metus, ut egestas metus. Vivamus auctor erat ac sapien vulputate, nec ultricies sem tempor. Quisque leo lorem, faucibus nec pulvinar nec, congue eu velit. Duis sodales massa efficitur imperdiet ultrices. Donec eros ipsum, ornare pharetra purus aliquam, tincidunt elementum nisi. Ut mi tortor, feugiat eget nunc vitae, facilisis interdum dui. Vivamus ullamcorper nunc dui, a dapibus nisi pretium ac. Integer eleifend placerat nibh, maximus malesuada tellus. Cras in justo in ligula scelerisque suscipit vel vitae quam."
			}, ParagraphSettings or {})

			local ParagraphV = {
				Settings = ParagraphSettings
			}

			local Paragraph = Elements.Template.Paragraph:Clone()
			Paragraph.Title.Text = ParagraphSettings.Title
			Paragraph.Text.Text = ParagraphSettings.Text
			Paragraph.Visible = true
			Paragraph.Parent = TabPage

			Paragraph.BackgroundTransparency = 1
			Paragraph.UIStroke.Transparency = 1
			Paragraph.Title.TextTransparency = 1
			Paragraph.Text.TextTransparency = 1

			TweenService:Create(Paragraph, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
			TweenService:Create(Paragraph.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
			TweenService:Create(Paragraph.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			TweenService:Create(Paragraph.Text, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

			function ParagraphV:Update()
				Paragraph.Text.Size = UDim2.new(Paragraph.Text.Size.X.Scale, Paragraph.Text.Size.X.Offset, 0, math.huge)
				Paragraph.Text.Size = UDim2.new(Paragraph.Text.Size.X.Scale, Paragraph.Text.Size.X.Offset, 0, Paragraph.Text.TextBounds.Y)
				tween(Paragraph, {Size = UDim2.new(Paragraph.Size.X.Scale, Paragraph.Size.X.Offset, 0, Paragraph.Text.TextBounds.Y + 40)})
			end

			function ParagraphV:Set(NewParagraphSettings)

				NewParagraphSettings = Kwargify({
					Title = ParagraphSettings.Title,
					Text = ParagraphSettings.Text
				}, NewParagraphSettings or {})

				ParagraphV.Settings = NewParagraphSettings

				Paragraph.Title.Text = NewParagraphSettings.Title
				Paragraph.Text.Text = NewParagraphSettings.Text

				ParagraphV:Update()

			end

			function ParagraphV:Destroy()
				Paragraph.Visible = false
				Paragraph:Destroy()
			end

			ParagraphV:Update()

			return ParagraphV
		end

		function Tab:CreateSlider(SliderSettings, Flag)
			local SliderV = { IgnoreConfig = false, Class = "Slider", Settings = SliderSettings }

			SliderSettings = Kwargify({
				Name = "Slider",
				Range = {0, 200},
				Increment = 1,
				CurrentValue = 100,
				Callback = function(Value)

				end,
			}, SliderSettings or {})

			local SLDragging = false
			local Slider = Elements.Template.Slider:Clone()
			Slider.Name = SliderSettings.Name .. " - Slider"
			Slider.Title.Text = SliderSettings.Name
			Slider.Visible = true
			Slider.Parent = TabPage

			Slider.BackgroundTransparency = 1
			Slider.UIStroke.Transparency = 1
			Slider.Title.TextTransparency = 1

			TweenService:Create(Slider, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
			TweenService:Create(Slider.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
			TweenService:Create(Slider.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

			Slider.Main.Progress.Size =	UDim2.new(0, Slider.Main.AbsoluteSize.X * ((SliderSettings.CurrentValue + SliderSettings.Range[1]) / (SliderSettings.Range[2] - SliderSettings.Range[1])) > 5 and Slider.Main.AbsoluteSize.X * (SliderSettings.CurrentValue / (SliderSettings.Range[2] - SliderSettings.Range[1])) or 5, 1, 0)

			Slider.Value.Text = tostring(SliderSettings.CurrentValue)
			SliderV.CurrentValue = Slider.Value.Text

			SliderSettings.Callback(SliderSettings.CurrentValue)

			Slider["MouseEnter"]:Connect(function()
				tween(Slider.UIStroke, {Color = Color3.fromRGB(87, 84, 104)})
			end)

			Slider["MouseLeave"]:Connect(function()
				tween(Slider.UIStroke, {Color = Color3.fromRGB(64,61,76)})
			end)

			Slider.Interact.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
					SLDragging = true
				end
			end)

			Slider.Interact.InputEnded:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
					SLDragging = false
				end
			end)

			Slider.Interact.MouseButton1Down:Connect(function()
				local Current = Slider.Main.Progress.AbsolutePosition.X + Slider.Main.Progress.AbsoluteSize.X
				local Start = Current
				local Location
				local Loop; Loop = RunService.Stepped:Connect(function()
					if SLDragging then
						Location = UserInputService:GetMouseLocation().X
						Current = Current + 0.025 * (Location - Start)

						if Location < Slider.Main.AbsolutePosition.X then
							Location = Slider.Main.AbsolutePosition.X
						elseif Location > Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X then
							Location = Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X
						end

						if Current < Slider.Main.AbsolutePosition.X + 5 then
							Current = Slider.Main.AbsolutePosition.X + 5
						elseif Current > Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X then
							Current = Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X
						end

						if Current <= Location and (Location - Start) < 0 then
							Start = Location
						elseif Current >= Location and (Location - Start) > 0 then
							Start = Location
						end
						Slider.Main.Progress.Size = UDim2.new(0, Location - Slider.Main.AbsolutePosition.X, 1, 0)
						local NewValue = SliderSettings.Range[1] + (Location - Slider.Main.AbsolutePosition.X) / Slider.Main.AbsoluteSize.X * (SliderSettings.Range[2] - SliderSettings.Range[1])

						NewValue = math.floor(NewValue / SliderSettings.Increment + 0.5) * (SliderSettings.Increment * 10000000) / 10000000

						Slider.Value.Text = tostring(NewValue)

						if SliderSettings.CurrentValue ~= NewValue then
							local Success, Response = pcall(function()
								SliderSettings.Callback(NewValue)
							end)
							if not Success then
								TweenService:Create(Slider, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
								TweenService:Create(Slider, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
								TweenService:Create(Slider.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
								Slider.Title.Text = "Callback Error"
								print("Luna Interface Suite | "..SliderSettings.Name.." Callback Error " ..tostring(Response))
								task.wait(0.5)
								Slider.Title.Text = SliderSettings.Name
								TweenService:Create(Slider, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
								TweenService:Create(Slider, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
								TweenService:Create(Slider.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
							end

							SliderSettings.CurrentValue = NewValue
							SliderV.CurrentValue = SliderSettings.CurrentValue
						end
					else
						TweenService:Create(Slider.Main.Progress, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.In, 0, false), {Size = UDim2.new(0, Location - Slider.Main.AbsolutePosition.X > 5 and Location - Slider.Main.AbsolutePosition.X or 5, 1, 0)}):Play()
						Loop:Disconnect()
					end
				end)
			end)

			local function Set(NewVal, bleh)

				NewVal = NewVal or SliderSettings.CurrentValue

				TweenService:Create(Slider.Main.Progress, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), {Size = UDim2.new(0, Slider.Main.AbsoluteSize.X * ((NewVal + SliderSettings.Range[1]) / (SliderSettings.Range[2] - SliderSettings.Range[1])) > 5 and Slider.Main.AbsoluteSize.X * (NewVal / (SliderSettings.Range[2] - SliderSettings.Range[1])) or 5, 1, 0)}):Play()
				if not bleh then Slider.Value.Text = tostring(NewVal) end
				local Success, Response = pcall(function()
					SliderSettings.Callback(NewVal)
				end)
				if not Success then
					TweenService:Create(Slider, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
					TweenService:Create(Slider, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
					TweenService:Create(Slider.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					Slider.Title.Text = "Callback Error"
					print("Luna Interface Suite | "..SliderSettings.Name.." Callback Error " ..tostring(Response))
					task.wait(0.5)
					Slider.Title.Text = SliderSettings.Name
					TweenService:Create(Slider, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
					TweenService:Create(Slider, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(30, 33, 40)}):Play()
					TweenService:Create(Slider.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
				end

				SliderSettings.CurrentValue = NewVal
				SliderV.CurrentValue = SliderSettings.CurrentValue

			end

			function SliderV:UpdateValue(Value)
				Set(tonumber(Value))
			end

			Slider.Value:GetPropertyChangedSignal("Text"):Connect(function()
				local text = Slider.Value.Text
				if not tonumber(text) and text ~= "." then
					Slider.Value.Text = text:match("[0-9.]*") or ""
				end
				if SliderSettings.Range[2] < (tonumber(Slider.Value.Text) or 0) then Slider.Value.Text = SliderSettings.Range[2] end
				Slider.Value.Size = UDim2.fromOffset(Slider.Value.TextBounds.X, 23)
				Set(tonumber(Slider.Value.Text), true)
			end)

			function SliderV:Set(NewSliderSettings)
				NewSliderSettings = Kwargify({
					Name = SliderSettings.Name,
					Range = SliderSettings.Range,
					Increment = SliderSettings.Increment,
					CurrentValue = SliderSettings.CurrentValue,
					Callback = SliderSettings.Callback
				}, NewSliderSettings or {})

				SliderSettings = NewSliderSettings
				SliderV.Settings = NewSliderSettings

				Slider.Name = SliderSettings.Name .. " - Slider"
				Slider.Title.Text = SliderSettings.Name

				Set()

			end

			function SliderV:Destroy()
				Slider.Visible = false
				Slider:Destroy()
			end

			if Flag then
				Luna.Options[Flag] = SliderV
			end

			LunaUI.ThemeRemote:GetPropertyChangedSignal("Value"):Connect(function()
				Slider.Main.color.Color = Luna.ThemeGradient
				Slider.Main.UIStroke.color.Color = Luna.ThemeGradient
			end)

			return SliderV

		end

		function Tab:CreateToggle(ToggleSettings, Flag)
			local ToggleV = { IgnoreConfig = false, Class = "Toggle" }

			ToggleSettings = Kwargify({
				Name = "Toggle",
				Description = nil,
				CurrentValue = false,
				Callback = function(Value)
				end,
			}, ToggleSettings or {})

			local Toggle

			if ToggleSettings.Description ~= nil and ToggleSettings.Description ~= "" then
				Toggle = Elements.Template.ToggleDesc:Clone()
			else
				Toggle = Elements.Template.Toggle:Clone()
			end

			Toggle.Visible = true
			Toggle.Parent = TabPage

			Toggle.Name = ToggleSettings.Name .. " - Toggle"
			Toggle.Title.Text = ToggleSettings.Name
			if ToggleSettings.Description ~= nil and ToggleSettings.Description ~= "" then
				Toggle.Desc.Text = ToggleSettings.Description
			end

			Toggle.UIStroke.Transparency = 1
			Toggle.Title.TextTransparency = 1
			if ToggleSettings.Description ~= nil and ToggleSettings.Description ~= "" then
				Toggle.Desc.TextTransparency = 1
			end

			TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
			if ToggleSettings.Description ~= nil and ToggleSettings.Description ~= "" then
				TweenService:Create(Toggle.Desc, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			end
			TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
			TweenService:Create(Toggle.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

			local function Set(bool)
				if bool then
					Toggle.toggle.color.Enabled = true
					tween(Toggle.toggle, {BackgroundTransparency = 0})

					Toggle.toggle.UIStroke.color.Enabled = true
					tween(Toggle.toggle.UIStroke, {Color = Color3.new(255,255,255)})

					tween(Toggle.toggle.val, {BackgroundColor3 = Color3.fromRGB(255,255,255), Position = UDim2.new(1,-23,0.5,0), BackgroundTransparency = 0.45})
				else
					Toggle.toggle.color.Enabled = false
					Toggle.toggle.UIStroke.color.Enabled = false

					Toggle.toggle.UIStroke.Color = Color3.fromRGB(97,97,97)

					tween(Toggle.toggle, {BackgroundTransparency = 1})

					tween(Toggle.toggle.val, {BackgroundColor3 = Color3.fromRGB(97,97,97), Position = UDim2.new(0,5,0.5,0), BackgroundTransparency = 0})
				end

				ToggleV.CurrentValue = bool
			end

			Toggle.Interact.MouseButton1Click:Connect(function()
				ToggleSettings.CurrentValue = not ToggleSettings.CurrentValue
				Set(ToggleSettings.CurrentValue)

				local Success, Response = pcall(function()
					ToggleSettings.Callback(ToggleSettings.CurrentValue)
				end)
				if not Success then
					TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
					TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					Toggle.Title.Text = "Callback Error"
					print("Luna Interface Suite | "..ToggleSettings.Name.." Callback Error " ..tostring(Response))
					task.wait(0.5)
					Toggle.Title.Text = ToggleSettings.Name
					TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
					TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
				end
			end)

			Toggle["MouseEnter"]:Connect(function()
				tween(Toggle.UIStroke, {Color = Color3.fromRGB(87, 84, 104)})
			end)

			Toggle["MouseLeave"]:Connect(function()
				tween(Toggle.UIStroke, {Color = Color3.fromRGB(64,61,76)})
			end)

			if ToggleSettings.CurrentValue then
				Set(ToggleSettings.CurrentValue)
				local Success, Response = pcall(function()
					ToggleSettings.Callback(ToggleSettings.CurrentValue)
				end)
				if not Success then
					TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
					TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					Toggle.Title.Text = "Callback Error"
					print("Luna Interface Suite | "..ToggleSettings.Name.." Callback Error " ..tostring(Response))
					task.wait(0.5)
					Toggle.Title.Text = ToggleSettings.Name
					TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
					TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
				end
			end

			function ToggleV:UpdateState(State)
				ToggleSettings.CurrentValue = State
				Set(ToggleSettings.CurrentValue)
			end

			function ToggleV:Set(NewToggleSettings)

				NewToggleSettings = Kwargify({
					Name = ToggleSettings.Name,
					Description = ToggleSettings.Description,
					CurrentValue = ToggleSettings.CurrentValue,
					Callback = ToggleSettings.Callback
				}, NewToggleSettings or {})

				ToggleV.Settings = NewToggleSettings
				ToggleSettings = NewToggleSettings

				Toggle.Name = ToggleSettings.Name .. " - Toggle"
				Toggle.Title.Text = ToggleSettings.Name
				if ToggleSettings.Description ~= nil and ToggleSettings.Description ~= "" and Toggle.Desc ~= nil then
					Toggle.Desc.Text = ToggleSettings.Description
				end

				Set(ToggleSettings.CurrentValue)

				ToggleV.CurrentValue = ToggleSettings.CurrentValue

				local Success, Response = pcall(function()
					ToggleSettings.Callback(ToggleSettings.CurrentValue)
				end)
				if not Success then
					TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
					TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
					Toggle.Title.Text = "Callback Error"
					print("Luna Interface Suite | "..ToggleSettings.Name.." Callback Error " ..tostring(Response))
					task.wait(0.5)
					Toggle.Title.Text = ToggleSettings.Name
					TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
					TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
				end
			end

			function ToggleV:Destroy()
				Toggle.Visible = false
				Toggle:Destroy()
			end

			LunaUI.ThemeRemote:GetPropertyChangedSignal("Value"):Connect(function()
				Toggle.toggle.color.Color = Luna.ThemeGradient
				Toggle.toggle.UIStroke.color.Color = Luna.ThemeGradient
			end)

			if Flag then
				Luna.Options[Flag] = ToggleV
			end

			return ToggleV

		end

		function Tab:CreateBind(BindSettings, Flag)
			local BindV = { Class = "Keybind", IgnoreConfig = false, Settings = BindSettings, Active = false }

			BindSettings = Kwargify({
				Name = "Bind",
				Description = nil,
				CurrentBind = "Q",
				HoldToInteract = false,
				Callback = function(Bind)
				end,

				OnChangedCallback = function(Bind)
				end,
			}, BindSettings or {})

			local CheckingForKey = false

			local Bind
			if BindSettings.Description ~= nil and BindSettings.Description ~= "" then
				Bind = Elements.Template.BindDesc:Clone()
			else
				Bind = Elements.Template.Bind:Clone()
			end

			Bind.Visible = true
			Bind.Parent = TabPage

			Bind.Name = BindSettings.Name
			Bind.Title.Text = BindSettings.Name
			if BindSettings.Description ~= nil and BindSettings.Description ~= "" then
				Bind.Desc.Text = BindSettings.Description
			end

			Bind.Title.TextTransparency = 1
			if BindSettings.Description ~= nil and BindSettings.Description ~= "" then
				Bind.Desc.TextTransparency = 1
			end
			Bind.BindFrame.BackgroundTransparency = 1
			Bind.BindFrame.UIStroke.Transparency = 1
			Bind.BindFrame.BindBox.TextTransparency = 1

			TweenService:Create(Bind, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
			TweenService:Create(Bind.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			if BindSettings.Description ~= nil and BindSettings.Description ~= "" then
				TweenService:Create(Bind.Desc, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			end
			TweenService:Create(Bind.BindFrame, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.9}):Play()
			TweenService:Create(Bind.BindFrame.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0.3}):Play()
			TweenService:Create(Bind.BindFrame.BindBox, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

			Bind.BindFrame.BindBox.Text = BindSettings.CurrentBind
			Bind.BindFrame.BindBox.Size = UDim2.new(0, Bind.BindFrame.BindBox.TextBounds.X + 20, 0, 42)

			Bind.BindFrame.BindBox.Focused:Connect(function()
				CheckingForKey = true
				Bind.BindFrame.BindBox.Text = ""
			end)

			Bind.BindFrame.BindBox.FocusLost:Connect(function()
				CheckingForKey = false
				if Bind.BindFrame.BindBox.Text == (nil or "") then
					Bind.BindFrame.BindBox.Text = BindSettings.CurrentBind
				end
			end)

			Bind["MouseEnter"]:Connect(function()
				tween(Bind.UIStroke, {Color = Color3.fromRGB(87, 84, 104)})
			end)

			Bind["MouseLeave"]:Connect(function()
				tween(Bind.UIStroke, {Color = Color3.fromRGB(64,61,76)})
			end)
			UserInputService.InputBegan:Connect(function(input, processed)

				if CheckingForKey then
					if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Window.Bind then
						local SplitMessage = string.split(tostring(input.KeyCode), ".")
						local NewKeyNoEnum = SplitMessage[3]
						Bind.BindFrame.BindBox.Text = tostring(NewKeyNoEnum)
						BindSettings.CurrentBind = tostring(NewKeyNoEnum)
						local Success, Response = pcall(function()
							BindSettings.OnChangedCallback(BindSettings.CurrentBind)
						end)
						if not Success then
							TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
							TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
							TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
							Bind.Title.Text = "Callback Error"
							print("Luna Interface Suite | "..BindSettings.Name.." Callback Error " ..tostring(Response))
							task.wait(0.5)
							Bind.Title.Text = BindSettings.Name
							TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
							TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
							TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
						end
						Bind.BindFrame.BindBox:ReleaseFocus()
					end
				elseif BindSettings.CurrentBind ~= nil and (input.KeyCode == Enum.KeyCode[BindSettings.CurrentBind] and not processed) then
					local Held = true
					local Connection
					Connection = input.Changed:Connect(function(prop)
						if prop == "UserInputState" then
							Connection:Disconnect()
							Held = false
						end
					end)

					if not BindSettings.HoldToInteract then
						BindV.Active = not BindV.Active
						local Success, Response = pcall(function()
							BindSettings.Callback(BindV.Active)
						end)
						if not Success then
							TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
							TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
							TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
							Bind.Title.Text = "Callback Error"
							print("Luna Interface Suite | "..BindSettings.Name.." Callback Error " ..tostring(Response))
							task.wait(0.5)
							Bind.Title.Text = BindSettings.Name
							TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
							TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
							TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
						end
					else
						task.wait(0.1)
						if Held then
							local Loop; Loop = RunService.Stepped:Connect(function()
								if not Held then
									local Success, Response = pcall(function()
										BindSettings.Callback(false)
									end)
									if not Success then
										TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
										TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
										TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
										Bind.Title.Text = "Callback Error"
										print("Luna Interface Suite | "..BindSettings.Name.." Callback Error " ..tostring(Response))
										task.wait(0.5)
										Bind.Title.Text = BindSettings.Name
										TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
										TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
										TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
									end
									Loop:Disconnect()
								else
									local Success, Response = pcall(function()
										BindSettings.Callback(true)
									end)
									if not Success then
										TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
										TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
										TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
										Bind.Title.Text = "Callback Error"
										print("Luna Interface Suite | "..BindSettings.Name.." Callback Error " ..tostring(Response))
										task.wait(0.5)
										Bind.Title.Text = BindSettings.Name
										TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
										TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
										TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
									end
								end
							end)
						end
					end
				end
			end)

			Bind.BindFrame.BindBox:GetPropertyChangedSignal("Text"):Connect(function()
				TweenService:Create(Bind.BindFrame, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Bind.BindFrame.BindBox.TextBounds.X + 20, 0, 30)}):Play()
			end)

			function BindV:Set(NewBindSettings)

				NewBindSettings = Kwargify({
					Name = BindSettings.Name,
					Description = BindSettings.Description,
					CurrentBind =  BindSettings.CurrentBind,
					HoldToInteract = BindSettings.HoldToInteract,
					Callback = BindSettings.Callback
				}, NewBindSettings or {})

				BindV.Settings = NewBindSettings
				BindSettings = NewBindSettings

				Bind.Name = BindSettings.Name
				Bind.Title.Text = BindSettings.Name
				if BindSettings.Description ~= nil and BindSettings.Description ~= "" and Bind.Desc ~= nil then
					Bind.Desc.Text = BindSettings.Description
				end

				Bind.BindFrame.BindBox.Text = BindSettings.CurrentBind
				Bind.BindFrame.Size = UDim2.new(0, Bind.BindFrame.BindBox.TextBounds.X + 20, 0, 42)

				BindV.CurrentBind = BindSettings.CurrentBind
			end

			function BindV:Destroy()
				Bind.Visible = false
				Bind:Destroy()
			end

			if Flag then
				Luna.Options[Flag] = BindV
			end

			return BindV

		end

		function Tab:CreateKeybind(BindSettings)

			BindSettings = Kwargify({
				Name = "Bind",
				Description = nil,
				CurrentBind = "Q",
				HoldToInteract = false,
				Callback = function(Bind)
				end
			}, BindSettings or {})

			local BindV = { Settings = BindSettings, Active = false }
			local CheckingForKey = false

			local Bind
			if BindSettings.Description ~= nil and BindSettings.Description ~= "" then
				Bind = Elements.Template.BindDesc:Clone()
			else
				Bind = Elements.Template.Bind:Clone()
			end

			Bind.Visible = true
			Bind.Parent = TabPage

			Bind.Name = BindSettings.Name
			Bind.Title.Text = BindSettings.Name
			if BindSettings.Description ~= nil and BindSettings.Description ~= "" then
				Bind.Desc.Text = BindSettings.Description
			end

			Bind.Title.TextTransparency = 1
			if BindSettings.Description ~= nil and BindSettings.Description ~= "" then
				Bind.Desc.TextTransparency = 1
			end
			Bind.BindFrame.BackgroundTransparency = 1
			Bind.BindFrame.UIStroke.Transparency = 1
			Bind.BindFrame.BindBox.TextTransparency = 1

			TweenService:Create(Bind, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
			TweenService:Create(Bind.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			if BindSettings.Description ~= nil and BindSettings.Description ~= "" then
				TweenService:Create(Bind.Desc, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			end
			TweenService:Create(Bind.BindFrame, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.9}):Play()
			TweenService:Create(Bind.BindFrame.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0.3}):Play()
			TweenService:Create(Bind.BindFrame.BindBox, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

			Bind.BindFrame.BindBox.Text = BindSettings.CurrentBind
			Bind.BindFrame.BindBox.Size = UDim2.new(0, Bind.BindFrame.BindBox.TextBounds.X + 16, 0, 42)

			Bind.BindFrame.BindBox.Focused:Connect(function()
				CheckingForKey = true
				Bind.BindFrame.BindBox.Text = ""
			end)

			Bind.BindFrame.BindBox.FocusLost:Connect(function()
				CheckingForKey = false
				if Bind.BindFrame.BindBox.Text == (nil or "") then
					Bind.BindFrame.BindBox.Text = BindSettings.CurrentBind
				end
			end)

			Bind["MouseEnter"]:Connect(function()
				tween(Bind.UIStroke, {Color = Color3.fromRGB(87, 84, 104)})
			end)

			Bind["MouseLeave"]:Connect(function()
				tween(Bind.UIStroke, {Color = Color3.fromRGB(64,61,76)})
			end)
			UserInputService.InputBegan:Connect(function(input, processed)

				if CheckingForKey then
					if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.K then
						local SplitMessage = string.split(tostring(input.KeyCode), ".")
						local NewKeyNoEnum = SplitMessage[3]
						Bind.BindFrame.BindBox.Text = tostring(NewKeyNoEnum)
						BindSettings.CurrentBind = tostring(NewKeyNoEnum)
						Bind.BindFrame.BindBox:ReleaseFocus()
					end
				elseif BindSettings.CurrentBind ~= nil and (input.KeyCode == Enum.KeyCode[BindSettings.CurrentBind] and not processed) then
					local Held = true
					local Connection
					Connection = input.Changed:Connect(function(prop)
						if prop == "UserInputState" then
							Connection:Disconnect()
							Held = false
						end
					end)

					if not BindSettings.HoldToInteract then
						BindV.Active = not BindV.Active
						local Success, Response = pcall(function()
							BindSettings.Callback(BindV.Active)
						end)
						if not Success then
							TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
							TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
							TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
							Bind.Title.Text = "Callback Error"
							print("Luna Interface Suite | "..BindSettings.Name.." Callback Error " ..tostring(Response))
							task.wait(0.5)
							Bind.Title.Text = BindSettings.Name
							TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
							TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
							TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
						end
					else
						task.wait(0.1)
						if Held then
							local Loop; Loop = RunService.Stepped:Connect(function()
								if not Held then
									local Success, Response = pcall(function()
										BindSettings.Callback(false)
									end)
									if not Success then
										TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
										TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
										TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
										Bind.Title.Text = "Callback Error"
										print("Luna Interface Suite | "..BindSettings.Name.." Callback Error " ..tostring(Response))
										task.wait(0.5)
										Bind.Title.Text = BindSettings.Name
										TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
										TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
										TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
									end
									Loop:Disconnect()
								else
									local Success, Response = pcall(function()
										BindSettings.Callback(true)
									end)
									if not Success then
										TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
										TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
										TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
										Bind.Title.Text = "Callback Error"
										print("Luna Interface Suite | "..BindSettings.Name.." Callback Error " ..tostring(Response))
										task.wait(0.5)
										Bind.Title.Text = BindSettings.Name
										TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
										TweenService:Create(Bind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
										TweenService:Create(Bind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
									end
								end
							end)
						end
					end
				end
			end)

			Bind.BindFrame.BindBox:GetPropertyChangedSignal("Text"):Connect(function()
				TweenService:Create(Bind.BindFrame, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Bind.BindFrame.BindBox.TextBounds.X + 16, 0, 30)}):Play()
			end)

			function BindV:Set(NewBindSettings)

				NewBindSettings = Kwargify({
					Name = BindSettings.Name,
					Description = BindSettings.Description,
					CurrentBind =  BindSettings.CurrentBind,
					HoldToInteract = BindSettings.HoldToInteract,
					Callback = BindSettings.Callback
				}, NewBindSettings or {})

				BindV.Settings = NewBindSettings
				BindSettings = NewBindSettings

				Bind.Name = BindSettings.Name
				Bind.Title.Text = BindSettings.Name
				if BindSettings.Description ~= nil and BindSettings.Description ~= "" and Bind.Desc ~= nil then
					Bind.Desc.Text = BindSettings.Description
				end

				Bind.BindFrame.BindBox.Text = BindSettings.CurrentBind
				Bind.BindFrame.BindBox.Size = UDim2.new(0, Bind.BindFrame.BindBox.TextBounds.X + 16, 0, 42)

			end

			function BindV:Destroy()
				Bind.Visible = false
				Bind:Destroy()
			end

			return BindV

		end

		function Tab:CreateInput(InputSettings, Flag)
			local InputV = { IgnoreConfig = false, Class = "Input", Settings = InputSettings }

			InputSettings = Kwargify({
				Name = "Dynamic Input",
				Description = nil,
				CurrentValue = "",
				PlaceholderText = "Input Placeholder",
				RemoveTextAfterFocusLost = false,
				Numeric = false,
				Enter = false,
				MaxCharacters = nil,
				Callback = function(Text)

				end,
			}, InputSettings or {})

			InputV.CurrentValue = InputSettings.CurrentValue

			local descriptionbool
			if InputSettings.Description ~= nil and InputSettings.Description ~= "" then
				descriptionbool = true
			end

			local Input
			if descriptionbool then
				Input = Elements.Template.InputDesc:Clone()
			else
				Input = Elements.Template.Input:Clone()
			end

			Input.Name = InputSettings.Name
			Input.Title.Text = InputSettings.Name
			if descriptionbool then Input.Desc.Text = InputSettings.Description end
			Input.Visible = true
			Input.Parent = TabPage

			Input.BackgroundTransparency = 1
			Input.UIStroke.Transparency = 1
			Input.Title.TextTransparency = 1
			if descriptionbool then Input.Desc.TextTransparency = 1 end
			Input.InputFrame.BackgroundTransparency = 1
			Input.InputFrame.UIStroke.Transparency = 1
			Input.InputFrame.InputBox.TextTransparency = 1

			TweenService:Create(Input, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
			TweenService:Create(Input.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
			TweenService:Create(Input.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			if descriptionbool then TweenService:Create(Input.Desc, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play() end
			TweenService:Create(Input.InputFrame, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.9}):Play()
			TweenService:Create(Input.InputFrame.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0.3}):Play()
			TweenService:Create(Input.InputFrame.InputBox, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

			Input.InputFrame.InputBox.PlaceholderText = InputSettings.PlaceholderText
			Input.InputFrame.Size = UDim2.new(0, Input.InputFrame.InputBox.TextBounds.X + 52, 0, 30)

			Input.InputFrame.InputBox.FocusLost:Connect(function(bleh)

				if InputSettings.Enter then
					if bleh then
						local Success, Response = pcall(function()
							InputSettings.Callback(Input.InputFrame.InputBox.Text)
							InputV.CurrentValue = Input.InputFrame.InputBox.Text
						end)
						if not Success then
							TweenService:Create(Input, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
							TweenService:Create(Input, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
							TweenService:Create(Input.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
							Input.Title.Text = "Callback Error"
							print("Luna Interface Suite | "..InputSettings.Name.." Callback Error " ..tostring(Response))
							task.wait(0.5)
							Input.Title.Text = InputSettings.Name
							TweenService:Create(Input, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
							TweenService:Create(Input, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
							TweenService:Create(Input.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
						end
					end
				end

				if InputSettings.RemoveTextAfterFocusLost then
					Input.InputFrame.InputBox.Text = ""
				end

			end)

			if InputSettings.Numeric then
				Input.InputFrame.InputBox:GetPropertyChangedSignal("Text"):Connect(function()
					local text = Input.InputFrame.InputBox.Text
					if not tonumber(text) and text ~= "." then
						Input.InputFrame.InputBox.Text = text:match("[0-9.]*") or ""
					end
				end)
			end

			Input.InputFrame.InputBox:GetPropertyChangedSignal("Text"):Connect(function()
				if tonumber(InputSettings.MaxCharacters) then
					if (#Input.InputFrame.InputBox.Text - 1) == InputSettings.MaxCharacters then
						Input.InputFrame.InputBox.Text = Input.InputFrame.InputBox.Text:sub(1, InputSettings.MaxCharacters)
					end
				end
				TweenService:Create(Input.InputFrame, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Input.InputFrame.InputBox.TextBounds.X + 52, 0, 30)}):Play()
				if not InputSettings.Enter then
					local Success, Response = pcall(function()
						InputSettings.Callback(Input.InputFrame.InputBox.Text)
					end)
					if not Success then
						TweenService:Create(Input, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
						TweenService:Create(Input, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
						TweenService:Create(Input.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
						Input.Title.Text = "Callback Error"
						print("Luna Interface Suite | "..InputSettings.Name.." Callback Error " ..tostring(Response))
						task.wait(0.5)
						Input.Title.Text = InputSettings.Name
						TweenService:Create(Input, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
						TweenService:Create(Input, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
						TweenService:Create(Input.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
					end
				end
				InputV.CurrentValue = Input.InputFrame.InputBox.Text
			end)

			Input["MouseEnter"]:Connect(function()
				tween(Input.UIStroke, {Color = Color3.fromRGB(87, 84, 104)})
			end)

			Input["MouseLeave"]:Connect(function()
				tween(Input.UIStroke, {Color = Color3.fromRGB(64,61,76)})
			end)

			function InputV:Set(NewInputSettings)

				NewInputSettings = Kwargify(InputSettings, NewInputSettings or {})

				InputV.Settings = NewInputSettings
				InputSettings = NewInputSettings

				Input.Name = InputSettings.Name
				Input.Title.Text = InputSettings.Name
				if InputSettings.Description ~= nil and InputSettings.Description ~= "" and Input.Desc ~= nil then
					Input.Desc.Text = InputSettings.Description
				end

				Input.InputFrame.InputBox:CaptureFocus()
				Input.InputFrame.InputBox.Text = tostring(InputSettings.CurrentValue)
				Input.InputFrame.InputBox:ReleaseFocus()
				Input.InputFrame.Size = UDim2.new(0, Input.InputFrame.InputBox.TextBounds.X + 52, 0, 42)

				InputV.CurrentValue = InputSettings.CurrentValue
			end

			function InputV:Destroy()
				Input.Visible = false
				Input:Destroy()
			end

			if Flag then
				Luna.Options[Flag] = InputV
			end

			return InputV

		end

		function Tab:CreateDropdown(DropdownSettings, Flag)
			local DropdownV = { IgnoreConfig = false, Class = "Dropdown", Settings = DropdownSettings}

			DropdownSettings = Kwargify({
				Name = "Dropdown",
				Description = nil,
				Options = {"Option 1", "Option 2"},
				CurrentOption = {"Option 1"},
				MultipleOptions = false,
				SpecialType = nil,
				Callback = function(Options)
				end,
			}, DropdownSettings or {})

			DropdownV.CurrentOption = DropdownSettings.CurrentOption

			local descriptionbool = false
			if DropdownSettings.Description ~= nil and DropdownSettings.Description ~= "" then
				descriptionbool = true
			end
			local closedsize
			local openedsize
			if descriptionbool then
				closedsize = 48
				openedsize = 170
			elseif not descriptionbool then
				closedsize = 38
				openedsize = 160
			end
			local opened = false

			local Dropdown
			if descriptionbool then Dropdown = Elements.Template.DropdownDesc:Clone() else Dropdown = Elements.Template.Dropdown:Clone() end

			Dropdown.Name = DropdownSettings.Name
			Dropdown.Title.Text = DropdownSettings.Name
			if descriptionbool then Dropdown.Desc.Text = DropdownSettings.Description end

			Dropdown.Parent = TabPage
			Dropdown.Visible = true

			local function Toggle()
				opened = not opened
				if opened then
					tween(Dropdown.icon, {Rotation = 180})
					tween(Dropdown, {Size = UDim2.new(1, -25, 0, openedsize)})
				else
					tween(Dropdown.icon, {Rotation = 0})
					tween(Dropdown, {Size = UDim2.new(1, -25, 0, closedsize)})
				end
			end

			local function SafeCallback(param, c2)
				local Success, Response = pcall(function()
					DropdownSettings.Callback(param)
				end)
				if not Success then
					TweenService:Create(Dropdown, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
					TweenService:Create(Dropdown, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
					TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					Dropdown.Title.Text = "Callback Error"
					print("Luna Interface Suite | "..DropdownSettings.Name.." Callback Error " ..tostring(Response))
					task.wait(0.5)
					Dropdown.Title.Text = DropdownSettings.Name
					TweenService:Create(Dropdown, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
					TweenService:Create(Dropdown, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
					TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
				end
				if Success and c2 then
					c2()
				end
			end

			Dropdown.Selected:GetPropertyChangedSignal("Text"):Connect(function()
				local text = Dropdown.Selected.Text:lower()
				for _, Item in ipairs(Dropdown.List:GetChildren()) do
					if Item:IsA("TextLabel") and Item.Name ~= "Template" then
						Item.Visible = text == "" or string.find(Item.Name:lower(), text, 1, true) ~= nil
					end
				end
			end)

			local function Clear()
				for _, option in ipairs(Dropdown.List:GetChildren()) do
					if option.ClassName == "TextLabel" and option.Name ~= "Template" then
						option:Destroy()
					end
				end
			end

			local function ActivateColorSingle(name)
				for _, Option in pairs(Dropdown.List:GetChildren()) do
					if Option.ClassName == "TextLabel" and Option.Name ~= "Template" then
						tween(Option, {BackgroundTransparency = 0.98})
					end
				end

				Toggle()
				tween(Dropdown.List[name], {BackgroundTransparency = 0.95, TextColor3 = Color3.fromRGB(240,240,240)})
			end

			local function Refresh()
				Clear()
				for i,v in pairs(DropdownSettings.Options) do
					local Option = Dropdown.List.Template:Clone()
					local optionhover = false
					Option.Text = v
					if v == "Template" then v = "Template (Name)" end
					Option.Name = v
					Option.Interact.MouseButton1Click:Connect(function()
						local bleh
						if DropdownSettings.MultipleOptions then
							if table.find(DropdownSettings.CurrentOption, v) then
								RemoveTable(DropdownSettings.CurrentOption, v)
								DropdownV.CurrentOption = DropdownSettings.CurrentOption
								if not optionhover then
									tween(Option, {TextColor3 = Color3.fromRGB(200,200,200)})
								end
								tween(Option, {BackgroundTransparency = 0.98})
							else
								table.insert(DropdownSettings.CurrentOption, v)
								DropdownV.CurrentOption = DropdownSettings.CurrentOption
								tween(Option, {TextColor3 = Color3.fromRGB(240,240,240), BackgroundTransparency = 0.95})
							end
							bleh = DropdownSettings.CurrentOption
						else
							DropdownSettings.CurrentOption = {v}
							bleh = v
							DropdownV.CurrentOption = bleh
							ActivateColorSingle(v)
						end

						SafeCallback(bleh, function()
							if DropdownSettings.MultipleOptions then
								if DropdownSettings.CurrentOption and type(DropdownSettings.CurrentOption) == "table" then
									if #DropdownSettings.CurrentOption == 1 then
										Dropdown.Selected.PlaceholderText = DropdownSettings.CurrentOption[1]
									elseif #DropdownSettings.CurrentOption == 0 then
										Dropdown.Selected.PlaceholderText = "None"
									else
										Dropdown.Selected.PlaceholderText = unpackt(DropdownSettings.CurrentOption)
									end
								else
									DropdownSettings.CurrentOption = {}
									Dropdown.Selected.PlaceholderText = "None"
								end
							end
							if not DropdownSettings.MultipleOptions then
								Dropdown.Selected.PlaceholderText = DropdownSettings.CurrentOption[1] or "None"
							end
							Dropdown.Selected.Text = ""
						end)
					end)
					Option.Visible = true
					Option.Parent = Dropdown.List
					Option.MouseEnter:Connect(function()
						optionhover = true
						if Option.BackgroundTransparency == 0.95 then
							return
						else
							tween(Option, {TextColor3 = Color3.fromRGB(240,240,240)})
						end
					end)
					Option.MouseLeave:Connect(function()
						optionhover = false
						if Option.BackgroundTransparency == 0.95 then
							return
						else
							tween(Option, {TextColor3 = Color3.fromRGB(200,200,200)})
						end
					end)
				end
			end

			local function PlayerTableRefresh()
				for i,v in pairs(DropdownSettings.Options) do
					table.remove(DropdownSettings.Options, i)
				end

				for i,v in pairs(Players:GetChildren()) do
					table.insert(DropdownSettings.Options, v.Name)
				end
			end

			Dropdown.Interact.MouseButton1Click:Connect(function()
				Toggle()
			end)

			Dropdown["MouseEnter"]:Connect(function()
				tween(Dropdown.UIStroke, {Color = Color3.fromRGB(87, 84, 104)})
			end)

			Dropdown["MouseLeave"]:Connect(function()
				tween(Dropdown.UIStroke, {Color = Color3.fromRGB(64,61,76)})
			end)

			if DropdownSettings.SpecialType == "Player" then

				for i,v in pairs(DropdownSettings.Options) do
					table.remove(DropdownSettings.Options, i)
				end
				PlayerTableRefresh()
				DropdownSettings.CurrentOption = DropdownSettings.Options[1]

				Players.PlayerAdded:Connect(function() PlayerTableRefresh() end)
				Players.PlayerRemoving:Connect(function() PlayerTableRefresh() end)

			end

			Refresh()

			if DropdownSettings.CurrentOption then
				if type(DropdownSettings.CurrentOption) == "string" then
					DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption}
				end
				if not DropdownSettings.MultipleOptions and type(DropdownSettings.CurrentOption) == "table" then
					DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption[1]}
				end
			else
				DropdownSettings.CurrentOption = {}
			end

			local bleh, ind = nil,0
			for i,v in pairs(DropdownSettings.CurrentOption) do
				ind = ind + 1
			end
			if ind == 1 then bleh = DropdownSettings.CurrentOption[1] else bleh = DropdownSettings.CurrentOption end
			SafeCallback(bleh)
			if type(bleh) == "string" then
				tween(Dropdown.List[bleh], {TextColor3 = Color3.fromRGB(240,240,240), BackgroundTransparency = 0.95})
			else
				for i,v in pairs(bleh) do
					tween(Dropdown.List[v], {TextColor3 = Color3.fromRGB(240,240,240), BackgroundTransparency = 0.95})
				end
			end

			if DropdownSettings.MultipleOptions then
				if DropdownSettings.CurrentOption and type(DropdownSettings.CurrentOption) == "table" then
					if #DropdownSettings.CurrentOption == 1 then
						Dropdown.Selected.PlaceholderText = DropdownSettings.CurrentOption[1]
					elseif #DropdownSettings.CurrentOption == 0 then
						Dropdown.Selected.PlaceholderText = "None"
					else
						Dropdown.Selected.PlaceholderText = unpackt(DropdownSettings.CurrentOption)
					end
				else
					DropdownSettings.CurrentOption = {}
					Dropdown.Selected.PlaceholderText = "None"
				end
				for _, name in pairs(DropdownSettings.CurrentOption) do
					tween(Dropdown.List[name], {TextColor3 = Color3.fromRGB(227,227,227), BackgroundTransparency = 0.95})
				end
			else
				Dropdown.Selected.PlaceholderText = DropdownSettings.CurrentOption[1] or "None"
			end
			Dropdown.Selected.Text = ""

			function DropdownV:Set(NewDropdownSettings)
				NewDropdownSettings = Kwargify(DropdownSettings, NewDropdownSettings or {})

				DropdownV.Settings = NewDropdownSettings
				DropdownSettings = NewDropdownSettings

				Dropdown.Name = DropdownSettings.Name
				Dropdown.Title.Text = DropdownSettings.Name
				if DropdownSettings.Description ~= nil and DropdownSettings.Description ~= "" and Dropdown.Desc ~= nil then
					Dropdown.Desc.Text = DropdownSettings.Description
				end

				if DropdownSettings.SpecialType == "Player" then

					for i,v in pairs(DropdownSettings.Options) do
						table.remove(DropdownSettings.Options, i)
					end
					PlayerTableRefresh()
					DropdownSettings.CurrentOption = DropdownSettings.Options[1]
					Players.PlayerAdded:Connect(function() PlayerTableRefresh() end)
					Players.PlayerRemoving:Connect(function() PlayerTableRefresh() end)

				end

				Refresh()

				if DropdownSettings.CurrentOption then
					if type(DropdownSettings.CurrentOption) == "string" then
						DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption}
					end
					if not DropdownSettings.MultipleOptions and type(DropdownSettings.CurrentOption) == "table" then
						DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption[1]}
					end
				else
					DropdownSettings.CurrentOption = {}
				end

				local bleh, ind = nil,0
				for i,v in pairs(DropdownSettings.CurrentOption) do
					ind = ind + 1
				end
				if ind == 1 then bleh = DropdownSettings.CurrentOption[1] else bleh = DropdownSettings.CurrentOption end
				SafeCallback(bleh)
				for _, Option in pairs(Dropdown.List:GetChildren()) do
					if Option.ClassName == "TextLabel" then
						tween(Option, {TextColor3 = Color3.fromRGB(200,200,200), BackgroundTransparency = 0.98})
					end
				end
				tween(Dropdown.List[bleh], {TextColor3 = Color3.fromRGB(240,240,240), BackgroundTransparency = 0.95})

				if DropdownSettings.MultipleOptions then
					if DropdownSettings.CurrentOption and type(DropdownSettings.CurrentOption) == "table" then
						if #DropdownSettings.CurrentOption == 1 then
							Dropdown.Selected.PlaceholderText = DropdownSettings.CurrentOption[1]
						elseif #DropdownSettings.CurrentOption == 0 then
							Dropdown.Selected.PlaceholderText = "None"
						else
							Dropdown.Selected.PlaceholderText = unpackt(DropdownSettings.CurrentOption)
						end
					else
						DropdownSettings.CurrentOption = {}
						Dropdown.Selected.PlaceholderText = "None"
					end
					for _, name in pairs(DropdownSettings.CurrentOption) do
						tween(Dropdown.List[name], {TextColor3 = Color3.fromRGB(227,227,227), BackgroundTransparency = 0.95})
					end
				else
					Dropdown.Selected.PlaceholderText = DropdownSettings.CurrentOption[1] or "None"
				end
				Dropdown.Selected.Text = ""

			end

			function DropdownV:Destroy()
				Dropdown.Visible = false
				Dropdown:Destroy()
			end

			if Flag then
				Luna.Options[Flag] = DropdownV
			end

			return DropdownV

		end

		function Tab:CreateColorPicker(ColorPickerSettings, Flag)
			local ColorPickerV = {IgnoreClass = false, Class = "Colorpicker", Settings = ColorPickerSettings}

			ColorPickerSettings = Kwargify({
				Name = "Color Picker",
				Color = Color3.fromRGB(255,255,255),
				Callback = function(Value)
				end
			}, ColorPickerSettings or {})

			local function Color3ToHex(color)
				return string.format("#%02X%02X%02X", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
			end

			ColorPickerV.Color = Color3ToHex(ColorPickerSettings.Color)

			local closedsize = UDim2.new(0, 75, 0, 22)
			local openedsize = UDim2.new(0, 219, 0, 129)

			local ColorPicker = Elements.Template.ColorPicker:Clone()
			local Background = ColorPicker.CPBackground
			local Display = Background.Display
			local Main = Background.MainCP
			local Slider = ColorPicker.ColorSlider

			ColorPicker.Name = ColorPickerSettings.Name
			ColorPicker.Title.Text = ColorPickerSettings.Name
			ColorPicker.Visible = true
			ColorPicker.Parent = TabPage
			ColorPicker.Size = UDim2.new(1.042, -25,0, 38)
			Background.Size = closedsize
			Display.BackgroundTransparency = 0

			ColorPicker["MouseEnter"]:Connect(function()
				tween(ColorPicker.UIStroke, {Color = Color3.fromRGB(87, 84, 104)})
			end)
			ColorPicker["MouseLeave"]:Connect(function()
				tween(ColorPicker.UIStroke, {Color = Color3.fromRGB(64,61,76)})
			end)

			local function SafeCallback(param, c2)
				local Success, Response = pcall(function()
					ColorPickerSettings.Callback(param)
				end)
				if not Success then
					TweenService:Create(ColorPicker, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
					TweenService:Create(ColorPicker, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
					TweenService:Create(ColorPicker.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					ColorPicker.Title.Text = "Callback Error"
					print("Luna Interface Suite | "..ColorPickerSettings.Name.." Callback Error " ..tostring(Response))
					task.wait(0.5)
					ColorPicker.Title.Text = ColorPickerSettings.Name
					TweenService:Create(ColorPicker, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.5}):Play()
					TweenService:Create(ColorPicker, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(32, 30, 38)}):Play()
					TweenService:Create(ColorPicker.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
				end
				if Success and c2 then
					c2()
				end
			end

			local opened = false

			local mouse = game.Players.LocalPlayer:GetMouse()
			Main.Image = "http://www.roblox.com/asset/?id=11415645739"
			local mainDragging = false
			local sliderDragging = false
			ColorPicker.Interact.MouseButton1Down:Connect(function()
				if not opened then
					opened = true
					tween(ColorPicker, {Size = UDim2.new( 1.042, -25,0, 165)}, nil, TweenInfo.new(0.6, Enum.EasingStyle.Exponential))
					tween(Background, {Size = openedsize})
					tween(Display, {BackgroundTransparency = 1})
				else
					opened = false
					tween(ColorPicker, {Size = UDim2.new(1.042, -25,0, 38)}, nil, TweenInfo.new(0.6, Enum.EasingStyle.Exponential))
					tween(Background, {Size = closedsize})
					tween(Display, {BackgroundTransparency = 0})
				end
			end)
			UserInputService.InputEnded:Connect(function(input, gameProcessed) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					mainDragging = false
					sliderDragging = false
				end end)
			Main.MouseButton1Down:Connect(function()
				if opened then
					mainDragging = true
				end
			end)
			Main.MainPoint.MouseButton1Down:Connect(function()
				if opened then
					mainDragging = true
				end
			end)
			Slider.MouseButton1Down:Connect(function()
				sliderDragging = true
			end)
			Slider.SliderPoint.MouseButton1Down:Connect(function()
				sliderDragging = true
			end)
			local h,s,v = ColorPickerSettings.Color:ToHSV()
			local color = Color3.fromHSV(h,s,v)
			local r,g,b = math.floor((h*255)+0.5),math.floor((s*255)+0.5),math.floor((v*255)+0.5)
			local hex = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
			ColorPicker.HexInput.InputBox.Text = hex
			local function setDisplay(hp,sp,vp)
				Main.MainPoint.Position = UDim2.new(s,-Main.MainPoint.AbsoluteSize.X/2,1-v,-Main.MainPoint.AbsoluteSize.Y/2)
				Main.MainPoint.ImageColor3 = Color3.fromHSV(hp,sp,vp)
				Background.BackgroundColor3 = Color3.fromHSV(hp,1,1)
				Display.BackgroundColor3 = Color3.fromHSV(hp,sp,vp)
				local x = hp * Slider.AbsoluteSize.X
				Slider.SliderPoint.Position = UDim2.new(0,x-Slider.SliderPoint.AbsoluteSize.X/2,0.5,0)
				Slider.SliderPoint.ImageColor3 = Color3.fromHSV(hp,1,1)
				local color = Color3.fromHSV(hp,sp,vp)
				local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
				ColorPicker.RInput.InputBox.Text = tostring(r)
				ColorPicker.GInput.InputBox.Text = tostring(g)
				ColorPicker.BInput.InputBox.Text = tostring(b)
				hex = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
				ColorPicker.HexInput.InputBox.Text = hex
			end
			setDisplay(h,s,v)
			ColorPicker.HexInput.InputBox.FocusLost:Connect(function()
				if not pcall(function()
						local r, g, b = string.match(ColorPicker.HexInput.InputBox.Text, "^#?(%w%w)(%w%w)(%w%w)$")
						local rgbColor = Color3.fromRGB(tonumber(r, 16),tonumber(g, 16), tonumber(b, 16))
						h,s,v = rgbColor:ToHSV()
						hex = ColorPicker.HexInput.InputBox.Text
						setDisplay()
						ColorPickerSettings.Color = rgbColor
					end)
				then
					ColorPicker.HexInput.InputBox.Text = hex
				end
				local r,g,b = math.floor((h*255)+0.5),math.floor((s*255)+0.5),math.floor((v*255)+0.5)
				ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
				SafeCallback( Color3.fromRGB(r,g,b))
			end)
			local function rgbBoxes(box,toChange)
				local value = tonumber(box.Text)
				local color = Color3.fromHSV(h,s,v)
				local oldR,oldG,oldB = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
				local save
				if toChange == "R" then save = oldR;oldR = value elseif toChange == "G" then save = oldG;oldG = value else save = oldB;oldB = value end
				if value then
					value = math.clamp(value,0,255)
					h,s,v = Color3.fromRGB(oldR,oldG,oldB):ToHSV()
					setDisplay()
				else
					box.Text = tostring(save)
				end
				local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
				ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
			end
			ColorPicker.RInput.InputBox.FocusLost:Connect(function()
				rgbBoxes(ColorPicker.RInput.InputBox,"R")
				SafeCallback(Color3.fromRGB(r,g,b))
			end)
			ColorPicker.GInput.InputBox.FocusLost:Connect(function()
				rgbBoxes(ColorPicker.GInput.InputBox,"G")
				SafeCallback(Color3.fromRGB(r,g,b))
			end)
			ColorPicker.BInput.InputBox.FocusLost:Connect(function()
				rgbBoxes(ColorPicker.BInput.InputBox,"B")
				SafeCallback(Color3.fromRGB(r,g,b))
			end)
			RunService.RenderStepped:Connect(function()
				if mainDragging then
					local localX = math.clamp(mouse.X-Main.AbsolutePosition.X,0,Main.AbsoluteSize.X)
					local localY = math.clamp(mouse.Y-Main.AbsolutePosition.Y,0,Main.AbsoluteSize.Y)
					Main.MainPoint.Position = UDim2.new(0,localX-Main.MainPoint.AbsoluteSize.X/2,0,localY-Main.MainPoint.AbsoluteSize.Y/2)
					s = localX / Main.AbsoluteSize.X
					v = 1 - (localY / Main.AbsoluteSize.Y)
					Display.BackgroundColor3 = Color3.fromHSV(h,s,v)
					Main.MainPoint.ImageColor3 = Color3.fromHSV(h,s,v)
					Background.BackgroundColor3 = Color3.fromHSV(h,1,1)
					local color = Color3.fromHSV(h,s,v)
					local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
					ColorPicker.RInput.InputBox.Text = tostring(r)
					ColorPicker.GInput.InputBox.Text = tostring(g)
					ColorPicker.BInput.InputBox.Text = tostring(b)
					ColorPicker.HexInput.InputBox.Text = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
					SafeCallback(Color3.fromRGB(r,g,b))
					ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
					ColorPickerV.Color = ColorPickerSettings.Color
				end
				if sliderDragging then
					local localX = math.clamp(mouse.X-Slider.AbsolutePosition.X,0,Slider.AbsoluteSize.X)
					h = localX / Slider.AbsoluteSize.X
					Display.BackgroundColor3 = Color3.fromHSV(h,s,v)
					Slider.SliderPoint.Position = UDim2.new(0,localX-Slider.SliderPoint.AbsoluteSize.X/2,0.5,0)
					Slider.SliderPoint.ImageColor3 = Color3.fromHSV(h,1,1)
					Background.BackgroundColor3 = Color3.fromHSV(h,1,1)
					Main.MainPoint.ImageColor3 = Color3.fromHSV(h,s,v)
					local color = Color3.fromHSV(h,s,v)
					local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
					ColorPicker.RInput.InputBox.Text = tostring(r)
					ColorPicker.GInput.InputBox.Text = tostring(g)
					ColorPicker.BInput.InputBox.Text = tostring(b)
					ColorPicker.HexInput.InputBox.Text = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
					SafeCallback(Color3.fromRGB(r,g,b))
					ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
					ColorPickerV.Color = ColorPickerSettings.Color
				end
			end)

			function ColorPickerV:Set(NewColorPickerSettings)

				NewColorPickerSettings = Kwargify(ColorPickerSettings, NewColorPickerSettings or {})

				ColorPickerV.Settings = NewColorPickerSettings
				ColorPickerSettings = NewColorPickerSettings

				ColorPicker.Name = ColorPickerSettings.Name
				ColorPicker.Title.Text = ColorPickerSettings.Name
				ColorPicker.Visible = true

				local h,s,v = ColorPickerSettings.Color:ToHSV()
				local color = Color3.fromHSV(h,s,v)
				local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
				local hex = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
				ColorPicker.HexInput.InputBox.Text = hex
				setDisplay(h,s,v)
				SafeCallback(Color3.fromRGB(r,g,b))

				ColorPickerV.Color = ColorPickerSettings.Color
			end

			function ColorPickerV:Destroy()
				ColorPicker:Destroy()
			end

			if Flag then
				Luna.Options[Flag] = ColorPickerV
			end

			SafeCallback(ColorPickerSettings.Color)

			return ColorPickerV
		end

		function Tab:BuildConfigSection()
			if isStudio then
				Tab:CreateLabel({Text = "Config system unavailable. (Environment isStudio)", Style = 3})
				return "Config system unavailable."
			end

			local inputPath = nil
			local selectedConfig = nil

			local Title = Elements.Template.Title:Clone()
			Title.Text = "Configurations"
			Title.Visible = true
			Title.Parent = TabPage
			Title.TextTransparency = 1
			TweenService:Create(Title, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()

			Tab:CreateSection("Config Creator")

			Tab:CreateInput({
				Name = "Config Name",
				Description = "Insert a name for your to be created config.",
				PlaceholderText = "Name",
				CurrentValue = "",
				Numeric = false,
				MaxCharacters = nil,
				Enter = false,
				Callback = function(input)
					inputPath = input
				end,
			})

			local configSelection

			Tab:CreateButton({
				Name = "Create Config",
				Description = "Create a config with all of your current settings.",
				Callback = function()
					if not inputPath or string.gsub(inputPath, " ", "") == "" then
						Luna:Notification({
							Title = "Interface",
							Icon = "warning",
							ImageSource = "Material",
							Content = "Config name cannot be empty."
						})
						return
					end

					local success, returned = Luna:SaveConfig(inputPath)
					if not success then
						Luna:Notification({
							Title = "Interface",
							Icon = "error",
							ImageSource = "Material",
							Content = "Unable to save config, return error: " .. returned
						})
					end

					Luna:Notification({
						Title = "Interface",
						Icon = "info",
						ImageSource = "Material",
						Content = string.format("Created config %q", inputPath),
					})

					configSelection:Set({ Options = Luna:RefreshConfigList() })
				end
			})

			Tab:CreateSection("Config Load/Settings")

			configSelection = Tab:CreateDropdown({
				Name = "Select Config",
				Description = "Select a config to load your settings on.",
				Options = Luna:RefreshConfigList(),
				CurrentOption = {},
				MultipleOptions = false,
				SpecialType = nil,
				Callback = function(Value)
					selectedConfig = Value
				end,
			})

			Tab:CreateButton({
				Name = "Load Config",
				Description = "Load your saved config settings.",
				Callback = function()
					local success, returned = Luna:LoadConfig(selectedConfig)
					if not success then
						Luna:Notification({
							Title = "Interface",
							Icon = "error",
							ImageSource = "Material",
							Content = "Unable to load config, return error: " .. returned
						})
						return
					end

					Luna:Notification({
						Title = "Interface",
						Icon = "info",
						ImageSource = "Material",
						Content = string.format("Loaded config %q", selectedConfig),
					})
				end
			})

			Tab:CreateButton({
				Name = "Overwrite Config",
				Description = "Overwrite your current config settings.",
				Callback = function()
					local success, returned = Luna:SaveConfig(selectedConfig)
					if not success then
						Luna:Notification({
							Title = "Interface",
							Icon = "error",
							ImageSource = "Material",
							Content = "Unable to overwrite config, return error: " .. returned
						})
						return
					end

					Luna:Notification({
						Title = "Interface",
						Icon = "info",
						ImageSource = "Material",
						Content = string.format("Overwrote config %q", selectedConfig),
					})
				end
			})

			Tab:CreateButton({
				Name = "Refresh Config List",
				Description = "Refresh the current config list.",
				Callback = function()
					configSelection:Set({ Options = Luna:RefreshConfigList() })
				end,
			})

			local loadlabel
			Tab:CreateButton({
				Name = "Set as autoload",
				Description = "Set a config to auto load setting in your next session.",
				Callback = function()
					local name = selectedConfig
					writefile(Luna.Folder .. "/settings/autoload.txt", name)
					loadlabel:Set({ Text = "Current autoload config: " .. name })

					Luna:Notification({
						Title = "Interface",
						Icon = "info",
						ImageSource = "Material",
						Content = string.format("Set %q to auto load", name),
					})
				end,
			})

			loadlabel = Tab:CreateParagraph({
				Title = "Current Auto Load",
				Text = "None"
			})

			Tab:CreateButton({
				Name = "Delete Autoload",
				Description = "Delete The Autoload File",
				Callback = function()
					local name = selectedConfig
					delfile(Luna.Folder .. "/settings/autoload.txt")
					loadlabel:Set({ Text = "None" })

					Luna:Notification({
						Title = "Interface",
						Icon = "info",
						ImageSource = "Material",
						Content = "Deleted Autoload",
					})
				end,
			})

			if isfile(Luna.Folder .. "/settings/autoload.txt") then
				local name = readfile(Luna.Folder .. "/settings/autoload.txt")
				loadlabel:Set( { Text = "Current autoload config: " .. name })
			end
		end

		local ClassParser = {
			["Toggle"] = {
				Save = function(Flag, data)
					return {
						type = "Toggle",
						flag = Flag,
						state = data.CurrentValue or false
					}
				end,
				Load = function(Flag, data)
					if Luna.Options[Flag] then
						Luna.Options[Flag]:Set({ CurrentValue = data.state })
					end
				end
			},
			["Slider"] = {
				Save = function(Flag, data)
					return {
						type = "Slider",
						flag = Flag,
						value = (data.CurrentValue and tostring(data.CurrentValue)),
					}
				end,
				Load = function(Flag, data)
					if Luna.Options[Flag] and data.value then
						Luna.Options[Flag]:Set({ CurrentValue = data.value })
					end
				end
			},
			["Input"] = {
				Save = function(Flag, data)
					return {
						type = "Input",
						flag = Flag,
						text = data.CurrentValue
					}
				end,
				Load = function(Flag, data)
					if Luna.Options[Flag] and data.text and type(data.text) == "string" then
						Luna.Options[Flag]:Set({ CurrentValue = data.text })
					end
				end
			},
			["Dropdown"] = {
				Save = function(Flag, data)
					return {
						type = "Dropdown",
						flag = Flag,
						value = data.CurrentOption
					}
				end,
				Load = function(Flag, data)
					if Luna.Options[Flag] and data.value then
						Luna.Options[Flag]:Set({ CurrentOption = data.value })
					end
				end
			},
			["Colorpicker"] = {
				Save = function(Flag, data)
					local function Color3ToHex(color)
						return string.format("#%02X%02X%02X", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
					end

					return {
						type = "Colorpicker",
						flag = Flag,
						color = Color3ToHex(data.Color) or nil,
						alpha = data.Alpha
					}
				end,
				Load = function(Flag, data)
					local function HexToColor3(hex)
						local r = tonumber(hex:sub(2, 3), 16) / 255
						local g = tonumber(hex:sub(4, 5), 16) / 255
						local b = tonumber(hex:sub(6, 7), 16) / 255
						return Color3.new(r, g, b)
					end

					if Luna.Options[Flag] and data.color then
						Luna.Options[Flag]:Set({Color = HexToColor3(data.color)})
					end
				end
			}
		}

		function Tab:BuildThemeSection()

			local Title = Elements.Template.Title:Clone()
			Title.Text = "Theming"
			Title.Visible = true
			Title.Parent = TabPage
			Title.TextTransparency = 1
			TweenService:Create(Title, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()

			Tab:CreateSection("Custom Editor")

			local c1cp = Tab:CreateColorPicker({
				Name = "Color 1",
				Color = Color3.fromRGB(117, 164, 206),
			}, "LunaInterfaceSuitePrebuiltCPC1")

			local c2cp = Tab:CreateColorPicker({
				Name = "Color 2",
				Color = Color3.fromRGB(123, 201, 201),
			}, "LunaInterfaceSuitePrebuiltCPC2")

			local c3cp = Tab:CreateColorPicker({
				Name = "Color 3",
				Color = Color3.fromRGB(224, 138, 184),
			}, "LunaInterfaceSuitePrebuiltCPC3")

			task.wait(1)

			c1cp:Set({
				Callback = function(Value)
					if c2cp and c3cp then
						Luna.ThemeGradient = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Value or Color3.fromRGB(255,255,255)), ColorSequenceKeypoint.new(0.50, c2cp.Color or Color3.fromRGB(255,255,255)), ColorSequenceKeypoint.new(1.00, c3cp.Color or Color3.fromRGB(255,255,255))}
						LunaUI.ThemeRemote.Value = not LunaUI.ThemeRemote.Value
					end
				end
			})

			c2cp:Set({
				Callback = function(Value)
					if c1cp and c3cp then
						Luna.ThemeGradient = ColorSequence.new{ColorSequenceKeypoint.new(0.00, c1cp.Color or Color3.fromRGB(255,255,255)), ColorSequenceKeypoint.new(0.50, Value or Color3.fromRGB(255,255,255)), ColorSequenceKeypoint.new(1.00, c3cp.Color or Color3.fromRGB(255,255,255))}
						LunaUI.ThemeRemote.Value = not LunaUI.ThemeRemote.Value
					end
				end
			})

			c3cp:Set({
				Callback = function(Valuex)
					if c2cp and c1cp then
						Luna.ThemeGradient = ColorSequence.new{ColorSequenceKeypoint.new(0.00, c1cp.Color or Color3.fromRGB(255,255,255)), ColorSequenceKeypoint.new(0.50, c2cp.Color or Color3.fromRGB(255,255,255)), ColorSequenceKeypoint.new(1.00, Valuex or Color3.fromRGB(255,255,255))}
						LunaUI.ThemeRemote.Value = not LunaUI.ThemeRemote.Value
					end
				end
			})

			Tab:CreateSection("Preset Gradients")

			for i,v in pairs(PresetGradients) do
				Tab:CreateButton({
					Name = tostring(i),
					Callback = function()
						c1cp:Set({ Color = v[1] })
						c2cp:Set({ Color = v[2] })
						c3cp:Set({ Color = v[3] })
					end,
				})
			end

		end

		local function BuildFolderTree()
			if isStudio then return "Config system unavailable." end
			local paths = {
				Luna.Folder,
				Luna.Folder .. "/settings"
			}

			for i = 1, #paths do
				local str = paths[i]
				if not isfolder(str) then
					makefolder(str)
				end
			end
		end

		local function SetFolder()

			if isStudio then return "Config system unavailable." end

			if WindowSettings.ConfigSettings.RootFolder ~= nil and WindowSettings.ConfigSettings.RootFolder ~= "" then
				Luna.Folder = WindowSettings.ConfigSettings.RootFolder .. "/" .. WindowSettings.ConfigSettings.ConfigFolder
			else
				Luna.Folder = WindowSettings.ConfigSettings.ConfigFolder
			end

			BuildFolderTree()
		end

		SetFolder()

		function Luna:SaveConfig(Path)
			if isStudio then return "Config system unavailable." end

			if (not Path) then
				return false, "Please select a config file."
			end

			local fullPath = Luna.Folder .. "/settings/" .. Path .. ".luna"

			local data = {
				objects = {}
			}

			for flag, option in next, Luna.Options do
				if not ClassParser[option.Class] then continue end
				if option.IgnoreConfig then continue end

				table.insert(data.objects, ClassParser[option.Class].Save(flag, option))
			end

			local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
			if not success then
				return false, "Unable to encode into JSON data"
			end

			writefile(fullPath, encoded)
			return true
		end

		function Luna:LoadConfig(Path)
			if isStudio then return "Config system unavailable." end

			if (not Path) then
				return false, "Please select a config file."
			end

			local file = Luna.Folder .. "/settings/" .. Path .. ".luna"
			if not isfile(file) then return false, "Invalid file" end

			local success, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(file))
			if not success then return false, "Unable to decode JSON data." end

			for _, option in next, decoded.objects do
				if ClassParser[option.type] then
					task.spawn(function()
						ClassParser[option.type].Load(option.flag, option)
					end)
				end
			end

			return true
		end

		function Luna:LoadAutoloadConfig()
			if isfile(Luna.Folder .. "/settings/autoload.txt") then

				if isStudio then return "Config system unavailable." end

				local name = readfile(Luna.Folder .. "/settings/autoload.txt")

				local success, err = Luna:LoadConfig(name)
				if not success then
					return Luna:Notification({
						Title = "Interface",
						Icon = "sparkle",
						ImageSource = "Material",
						Content = "Failed to load autoload config: " .. err,
					})
				end

				Luna:Notification({
					Title = "Interface",
					Icon = "sparkle",
					ImageSource = "Material",
					Content = string.format("Auto loaded config %q", name),
				})

			end
		end

		function Luna:RefreshConfigList()
			if isStudio then return "Config system unavailable." end

			local list = listfiles(Luna.Folder .. "/settings")

			local out = {}
			for i = 1, #list do
				local file = list[i]
				if file:sub(-5) == ".luna" then
					local pos = file:find(".luna", 1, true)
					local start = pos

					local char = file:sub(pos, pos)
					while char ~= "/" and char ~= "\\" and char ~= "" do
						pos = pos - 1
						char = file:sub(pos, pos)
					end

					if char == "/" or char == "\\" then
						local name = file:sub(pos + 1, start - 1)
						if name ~= "options" then
							table.insert(out, name)
						end
					end
				end
			end

			return out
		end
		return Tab
	end

	Elements.Parent.Visible = true
	tween(Elements.Parent, {BackgroundTransparency = 0.1})
	Navigation.Visible = true
	tween(Navigation.Line, {BackgroundTransparency = 0})

	-- Fix: re-saltar al tab activo para que el UIPageLayout lo muestre correctamente
	-- (Elements.Parent estaba invisible cuando CreateHomeTab llamó JumpTo por primera vez)
	task.defer(function()
		pcall(function()
			local currentPage = Elements:FindFirstChild(Window.CurrentTab or "Home")
			if currentPage then
				Elements.UIPageLayout:JumpTo(currentPage)
			end
		end)
	end)

	for _, TopbarButton in ipairs(Main.Controls:GetChildren()) do
		if TopbarButton.ClassName == "Frame" and TopbarButton.Name ~= "Theme" then
			TopbarButton.Visible = true
			tween(TopbarButton, {BackgroundTransparency = 0.25})
			tween(TopbarButton.UIStroke, {Transparency = 0.5})
			tween(TopbarButton.ImageLabel, {ImageTransparency = 0.25})
		end
	end

	Main.Controls.Close.ImageLabel.MouseButton1Click:Connect(function()
		Luna:Destroy()
		if getgenv then
			getgenv().BladeXLoaded = nil
		end
	end)
	Main.Controls.Close["MouseEnter"]:Connect(function()
		tween(Main.Controls.Close.ImageLabel, {ImageColor3 = Color3.new(1,1,1)})
	end)
	Main.Controls.Close["MouseLeave"]:Connect(function()
		tween(Main.Controls.Close.ImageLabel, {ImageColor3 = Color3.fromRGB(195,195,195)})
	end)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if Window.State then return end
		if input.KeyCode == Window.Bind then
			Unhide(Main, Window.CurrentTab)
	pcall(function() LunaUI.MobileSupport.Visible = false end)
			dragBar.Size = _dragBarOriginalSize
			dragBar.Visible = true
			dragBar.BackgroundTransparency = 1
			Window.State = true
		end
	end)

	Main.Logo.MouseButton1Click:Connect(function()
		if Navigation.Size.X.Offset == 205 then
			tween(Elements.Parent, {Size = UDim2.new(1, -55, Elements.Parent.Size.Y.Scale, Elements.Parent.Size.Y.Offset)})
			tween(Navigation, {Size = UDim2.new(Navigation.Size.X.Scale, 55, Navigation.Size.Y.Scale, Navigation.Size.Y.Offset)})
		else
			tween(Elements.Parent, {Size = UDim2.new(1, -205, Elements.Parent.Size.Y.Scale, Elements.Parent.Size.Y.Offset)})
			tween(Navigation, {Size = UDim2.new(Navigation.Size.X.Scale, 205, Navigation.Size.Y.Scale, Navigation.Size.Y.Offset)})
		end
	end)

	Main.Controls.ToggleSize.ImageLabel.MouseButton1Click:Connect(function()
		Window.Size = not Window.Size
		if Window.Size then
			Minimize(Main)
			dragBar.Visible = false
		else
			Maximise(Main)
			dragBar.Size = _dragBarOriginalSize
			dragBar.Visible = true
			dragBar.BackgroundTransparency = 1
		end
	end)
	Main.Controls.ToggleSize["MouseEnter"]:Connect(function()
		tween(Main.Controls.ToggleSize.ImageLabel, {ImageColor3 = Color3.new(1,1,1)})
	end)
	Main.Controls.ToggleSize["MouseLeave"]:Connect(function()
		tween(Main.Controls.ToggleSize.ImageLabel, {ImageColor3 = Color3.fromRGB(195,195,195)})
	end)

	Main.Controls.Theme.ImageLabel.MouseButton1Click:Connect(function()
		if Window.Settings then
			Window.Settings:Activate()
			Elements.Settings.CanvasPosition = Vector2.new(0,698)
		end
	end)
	Main.Controls.Theme["MouseEnter"]:Connect(function()
		tween(Main.Controls.Theme.ImageLabel, {ImageColor3 = Color3.new(1,1,1)})
	end)
	Main.Controls.Theme["MouseLeave"]:Connect(function()
		tween(Main.Controls.Theme.ImageLabel, {ImageColor3 = Color3.fromRGB(195,195,195)})
	end)

	pcall(function()
		LunaUI.MobileSupport.Interact.MouseButton1Click:Connect(function()
			Unhide(Main, Window.CurrentTab)
			dragBar.Size = _dragBarOriginalSize
			dragBar.Visible = true
			dragBar.BackgroundTransparency = 1
			Window.State = true
			pcall(function() LunaUI.MobileSupport.Visible = false end)
		end)
	end)

	return Window
end

function Luna:Destroy()
	-- Limpiar Music player
	if _G.BladeXProgressConn then
		pcall(function() _G.BladeXProgressConn:Disconnect() end)
		_G.BladeXProgressConn = nil
	end
	if _G.BladeXMusic then
		pcall(function() _G.BladeXMusic:Stop() _G.BladeXMusic:Destroy() end)
		_G.BladeXMusic = nil
	end
	local playerGuiMusic = Player:FindFirstChild("PlayerGui")
	if playerGuiMusic then
		local mp = playerGuiMusic:FindFirstChild("BladeX_MusicPlayer")
		if mp then pcall(function() mp:Destroy() end) end
	end
	-- Limpiar AntiAFK
	if _G.AntiAFK then
		pcall(function() _G.AntiAFK:Disconnect() end)
		_G.AntiAFK = nil
	end
	-- Limpiar NoClip
	if _G.NoClipConn then
		pcall(function() _G.NoClipConn:Disconnect() end)
		_G.NoClipConn = nil
		_G.NoClip = nil
	end
	-- Fix 2.7: Limpiar LunaBlur y DepthOfFieldEffect del BlurModule
	pcall(function()
		local cam = workspace.CurrentCamera
		if cam then
			for _, v in ipairs(cam:GetChildren()) do
				if v.Name == "LunaBlur" then v:Destroy() end
			end
		end
		local lighting = game:GetService("Lighting")
		for _, v in ipairs(lighting:GetChildren()) do
			if v:IsA("DepthOfFieldEffect") and v.Name:sub(1,4) == "DPT_" then
				v:Destroy()
			end
		end
	end)
	-- Desconectar enforcer Heartbeat
	if getgenv then
		local genv = getgenv()
		if genv._BladeXDragGuard then
			pcall(function() genv._BladeXDragGuard:Disconnect() end)
			genv._BladeXDragGuard = nil
		end
	end
	Main.Visible = false
	for _, Notification in ipairs(Notifications:GetChildren()) do
		if Notification.ClassName == "Frame" then
			Notification.Visible = false
			Notification:Destroy()
		end
	end
	-- Destruir la UI y limpiar referencia global
	pcall(function() LunaUI:Destroy() end)
	_G.BladeX_LunaUI = nil
	-- Limpiar cualquier elemento residual suelto en todos los contenedores
	local _containers = {game:GetService("CoreGui")}
	pcall(function()
		local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
		if pg then table.insert(_containers, pg) end
	end)
	if gethui then pcall(function()
		local h = gethui()
		if h then table.insert(_containers, h) end
	end) end
	local _ghostNames = {Drag=true, ShadowHolder=true, MobileSupport=true, BladeXLoader=true}
	for _, container in ipairs(_containers) do
		pcall(function()
			for _, child in ipairs(container:GetDescendants()) do
				if _ghostNames[child.Name] then
					pcall(function() child:Destroy() end)
				end
			end
		end)
	end
end

if getgenv then getgenv().ConfirmLuna = true end

;(function()
	local KEY_URL   = "https://raw.githubusercontent.com/martin009gonzg-cmd/bladex-keys/refs/heads/main/bladex-keys.txt"

	local remoteKeys = {}
	local remoteKeysFailed = false
	local ok, data = pcall(game.HttpGet, game, KEY_URL)
	if ok and data then
		for line in data:gmatch("[^\r\n]+") do
			local k = line:match("^%s*(.-)%s*$")
			if k ~= "" then table.insert(remoteKeys, k) end
		end
	end
	-- Fix 2.14: Si no hay keys remotas, no bloquear ciegamente.
	-- Se intentará usar la key guardada localmente. Si tampoco hay, entonces bloquear.
	if #remoteKeys == 0 then
		remoteKeysFailed = true
		-- Intentar leer la key guardada para usarla como única válida
		local _savedKeyPath = "Luna/Configurations/BladeX/Key System/key.luna"
		local _hasSavedKey = false
		pcall(function()
			if isfile and isfile(_savedKeyPath) then
				local savedK = readfile(_savedKeyPath)
				if savedK and savedK ~= "" then
					table.insert(remoteKeys, savedK)
					_hasSavedKey = true
				end
			end
		end)
		-- Si no hay ninguna key guardada, bloquear con mensaje claro
		if not _hasSavedKey then
			remoteKeys = {"CLAVE_INVALIDA_SIN_CONEXION"}
		end
	end

	local Window = Luna:CreateWindow({
		Name            = "BladeX",
		Subtitle        = "",
		LogoID          = "113679886240651",
		LoadingEnabled  = false,
		LoadingTitle    = "BladeX",
		LoadingSubtitle = "",
		KeySystem       = true,
		KeySettings     = {
			Title       = "BladeX | Key System",
			Subtitle    = "Ingresa tu key para continuar",
			Note        = "Obtén la key en discord.com/invite/GB5C5CKDk",
			FileName    = "bladex_key",
			SaveKey     = true,
			Key         = remoteKeys,
			SecondAction = {
				Enabled   = true,
				Type      = "Discord",
				Parameter = "https://discord.com/invite/GB5C5CKDk"
			}
		}
	})

	-- Pestaña Favoritos eliminada: dummy para evitar errores en rebuildFn
	local _dummyTab = setmetatable({}, {__index = function() return function() end end})
	local Tabs = {
		Extra = _dummyTab,
		Farm = Window:CreateTab({
			Name = "Farm",
			Icon = "nature",
			ImageSource = "Material",
			ShowTitle = true
		}),
		Aimbot = Window:CreateTab({
			Name = "Aimbot",
			Icon = "adjust",
			ImageSource = "Material",
			ShowTitle = true
		}),
		FPSBoost = Window:CreateTab({
			Name = "FPS Boost",
			Icon = "sports_esports",
			ImageSource = "Material",
			ShowTitle = true
		}),
		Scripts2 = Window:CreateTab({
			Name = "Scripts",
			Icon = "code",
			ImageSource = "Material",
			ShowTitle = true
		}),
		Music = Window:CreateTab({
			Name = "Música",
			Icon = "queue_music",
			ImageSource = "Material",
			ShowTitle = true
		}),
		Scripts = Window:CreateTab({
			Name = "Image ID",
			Icon = "image_search",
			ImageSource = "Material",
			ShowTitle = true
		}),
		Info = Window:CreateTab({
			Name = "Redes",
			Icon = "people",
			ImageSource = "Material",
			ShowTitle = true
		})
	}
	Window:CreateHomeTab({
		DiscordInvite = "GB5C5CKDk"
	})

	-- Fix Delta: espera dinámica hasta que LunaUI esté activo
	task.spawn(function()
		local _waited = 0
		repeat task.wait(0.1) _waited = _waited + 0.1
		until (LunaUI and LunaUI.Enabled) or _waited >= 8
		task.wait(0.5)
		if LunaUI and LunaUI.Enabled then
			Luna:Notification({
				Title = "Bienvenido a BladeX",
				Content = "Hola, " .. Player.DisplayName .. "! BladeX " .. Release .. " cargado correctamente.",
				Icon = "113679886240651",
				ImageSource = "Custom",
				Duration = 1
			})
		end
	end)


	-- ─── CONFIG PERSISTENCE (guardado general) ───────────────────────────────
	local _cfgFolder = "BladeX"
	local _cfgFile   = _cfgFolder .. "/utilidades.json"
	local _cfg = { walkSpeed=16, jumpPower=50, noClip=false, antiAFK=false, espEnabled=false, espTeamColor=false }

	local function _loadCfg()
		-- Fix 2.3: Verificar soporte de sistema de archivos antes de usarlo
		if not (isfolder and makefolder and readfile and writefile) then return end
		pcall(function() if not isfolder(_cfgFolder) then makefolder(_cfgFolder) end end)
		if isfile(_cfgFile) then
			local ok, data = pcall(function() return HttpService:JSONDecode(readfile(_cfgFile)) end)
			if ok and type(data)=="table" then
				for k,v in pairs(data) do _cfg[k]=v end
			end
		end
	end
	local function _saveCfg()
		-- Fix 2.3: Verificar soporte de sistema de archivos antes de usarlo
		if not (isfolder and makefolder and writefile) then return end
		pcall(function()
			if not isfolder(_cfgFolder) then makefolder(_cfgFolder) end
			writefile(_cfgFile, HttpService:JSONEncode(_cfg))
		end)
	end
	_loadCfg()

	-- ═══════════════════════════════════════════════════════════════════════════
	--   SISTEMA DE FAVORITOS AUTOMÁTICOS
	--   Rastrea cuántas veces se usa cada opción y rellena la pestaña Favoritos
	-- ═══════════════════════════════════════════════════════════════════════════
	local _favFile    = _cfgFolder .. "/favorites.json"
	local _favUsage   = {}   -- {[nombre] = count}
	local _favItems   = {}   -- lista ordenada para reconstruir la UI

	-- Detectar si el executor soporta filesystem
	local _hasFS = pcall(function()
		return type(isfolder) == "function" and type(isfile) == "function"
			and type(readfile) == "function" and type(writefile) == "function"
			and type(makefolder) == "function"
	end)
	_hasFS = _hasFS and type(isfolder) == "function"

	-- Cargar datos de uso guardados (filesystem + _G como fallback)
	local function _loadFavUsage()
		-- Primero intentar desde _G (memoria de sesión anterior si no se reinició)
		if _G._BladeXFavUsage and type(_G._BladeXFavUsage) == "table" then
			for k, v in pairs(_G._BladeXFavUsage) do
				_favUsage[k] = v
			end
		end
		-- Luego sobreescribir con datos del archivo (más recientes)
		if _hasFS then
			pcall(function()
				if isfile(_favFile) then
					local raw = readfile(_favFile)
					local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
					if ok and type(data) == "table" then
						for k, v in pairs(data) do
							_favUsage[k] = math.max(_favUsage[k] or 0, v)
						end
					end
				end
			end)
		end
	end

	-- Guardar datos de uso (filesystem + _G como respaldo en memoria)
	local function _saveFavUsage()
		-- Siempre guardar en _G (persiste mientras Roblox no se cierre)
		_G._BladeXFavUsage = _favUsage

		-- Si hay filesystem, guardar también en disco
		if _hasFS then
			pcall(function()
				if not isfolder(_cfgFolder) then makefolder(_cfgFolder) end
				writefile(_favFile, HttpService:JSONEncode(_favUsage))
			end)
		end
	end

	-- Registrar un item trackeable
	local function _registerFavItem(data)
		-- data = {name, description, type, rebuildFn}
		table.insert(_favItems, data)
	end

	-- Incrementar uso de una opción y actualizar Favoritos en tiempo real
	local function _trackUse(name)
		local wasZero = (_favUsage[name] or 0) == 0
		_favUsage[name] = (_favUsage[name] or 0) + 1
		_saveFavUsage()

		-- Si es la primera vez que se usa, reconstruir Favoritos en tiempo real
		if wasZero then
			task.spawn(function()
				task.wait(0.05)
				-- Limpiar contenido actual de la página Favoritos
				pcall(function()
					local page = Tabs.Extra.Page
					if page then
						for _, child in ipairs(page:GetChildren()) do
							local n = child.Name
							if n ~= "UIListLayout" and n ~= "UIPadding" and n ~= "Title" then
								pcall(function() child:Destroy() end)
							end
						end
					end
				end)
				task.wait(0.05)
				_buildFavoritos()
			end)
		end
	end

	_loadFavUsage()

	-- Pestaña Favoritos eliminada: función vacía para evitar errores
	local function _buildFavoritos()
	end

	-- ─── FARM ────────────────────────────────────────────────────────────────
	local _autoFarmConn    = nil
	local _autoCollectConn = nil
	local _farmEnabled     = false
	local _collectEnabled  = false

	local _farmRange = 150
	local function _getNearestEnemy(maxDist)
		local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end
		local best, bestDist = nil, maxDist or _farmRange
		for _, obj in pairs(workspace:GetDescendants()) do
			if obj:IsA("Humanoid") and obj.Health > 0 then
				local model = obj.Parent
				if model ~= Player.Character then
					local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
					if root then
						local d = (hrp.Position - root.Position).Magnitude
						if d < bestDist then bestDist=d best=model end
					end
				end
			end
		end
		return best
	end

	Tabs.Farm:CreateSection("⚔️ Farm")
	Tabs.Farm:CreateToggle({
		Name = "Auto Farm",
		Description = "Ataca automáticamente al enemigo más cercano",
		CurrentValue = false,
		Callback = function(Value)
			if Value then _trackUse("Auto Farm") end
			_farmEnabled = Value
			if Value then
				local _farmTimer = 0
				_autoFarmConn = RunService.Heartbeat:Connect(function(dt)
					if not _farmEnabled then return end
					_farmTimer = _farmTimer + dt
					if _farmTimer < 0.35 then return end
					_farmTimer = 0
					local char = Player.Character
					if not char then return end
					local hrp  = char:FindFirstChild("HumanoidRootPart")
					local hum  = char:FindFirstChildOfClass("Humanoid")
					if not hrp or not hum or hum.Health <= 0 then return end
					local target = _getNearestEnemy(_farmRange)
					if not target then return end
					local targetRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")
					if not targetRoot then return end
					hrp.CFrame = CFrame.new(targetRoot.Position + Vector3.new(0,0,3))
					local tool = char:FindFirstChildOfClass("Tool")
					if tool then
						local remote = tool:FindFirstChildOfClass("RemoteEvent") or tool:FindFirstChildOfClass("RemoteFunction")
						if remote and remote:IsA("RemoteEvent") then
							pcall(function() remote:FireServer() end)
						end
						pcall(function()
							local activate = tool:FindFirstChild("Activate") or tool:FindFirstChild("Slash")
							if activate then activate:Fire() end
						end)
					end
					local targetHum = target:FindFirstChildOfClass("Humanoid")
					if targetHum then
						pcall(function() targetHum:TakeDamage(25) end)
					end
				end)
				Luna:Notification({Title="Farm", Content="Auto Farm activado!", Icon="eco", ImageSource="Material", Duration=3})
			else
				if _autoFarmConn then _autoFarmConn:Disconnect() _autoFarmConn=nil end
				Luna:Notification({Title="Farm", Content="Auto Farm desactivado.", Icon="eco", ImageSource="Material", Duration=2})
			end
		end
	})
	Tabs.Farm:CreateSlider({
		Name = "Rango de Farm",
		Description = "Distancia máxima en studs para detectar enemigos",
		Range = {20, 500}, Increment = 10, CurrentValue = 150,
		Callback = function(v)
			_farmRange = v
		end
	})
	Tabs.Farm:CreateToggle({
		Name = "Auto Collect",
		Description = "Recoge automáticamente items y drops del suelo cercanos",
		CurrentValue = false,
		Callback = function(Value)
			if Value then _trackUse("Auto Collect") end
			_collectEnabled = Value
			if Value then
				if _autoCollectConn then _autoCollectConn:Disconnect() _autoCollectConn = nil end
				local _collectTimer = 0
				_autoCollectConn = RunService.Heartbeat:Connect(function(dt)
					if not _collectEnabled then return end
					_collectTimer = _collectTimer + dt
					if _collectTimer < 0.5 then return end
					_collectTimer = 0
					local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
					if not hrp then return end
					for _, obj in pairs(workspace:GetDescendants()) do
						if (obj:IsA("Tool") or obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("UnionOperation"))
						and obj.Parent == workspace then
							local ok, dist = pcall(function()
								return (hrp.Position - obj.Position).Magnitude
							end)
							if ok and dist and dist < 60 then
								pcall(function()
									local tEvent = obj:FindFirstChild("TouchInterest")
									if tEvent then
										hrp.CFrame = CFrame.new(obj.Position + Vector3.new(0,3,0))
									end
								end)
								if obj:IsA("Tool") then
									pcall(function() obj.Parent = Player.Backpack end)
								end
							end
						end
					end
				end)
				Luna:Notification({Title="Farm", Content="Auto Collect activado! (rango 60 studs)", Icon="eco", ImageSource="Material", Duration=3})
			else
				if _autoCollectConn then _autoCollectConn:Disconnect() _autoCollectConn=nil end
				Luna:Notification({Title="Farm", Content="Auto Collect desactivado.", Icon="eco", ImageSource="Material", Duration=2})
			end
		end
	})
	Tabs.Farm:CreateButton({
		Name = "Ir al Enemigo Más Cercano",
		Description = "Teletransporta tu personaje junto al NPC más cercano",
		Callback = function()
			local target = _getNearestEnemy(500)
			if not target then
				Luna:Notification({Title="Farm", Content="No hay enemigos en 500 studs.", Icon="dangerous", ImageSource="Material", Duration=3})
				return
			end
			local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
			local root = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")
			if hrp and root then
				hrp.CFrame = CFrame.new(root.Position + Vector3.new(0,0,4))
				Luna:Notification({Title="Farm", Content="Teleport a '"..target.Name.."'!", Icon="room", ImageSource="Material", Duration=3})
			end
		end
	})

	local Lighting = game:GetService("Lighting")

	-- Guardar estado original de Lighting para restaurar correctamente
	local _origLighting = {
		GlobalShadows = Lighting.GlobalShadows,
		Brightness    = Lighting.Brightness,
		Ambient       = Lighting.Ambient,
		FogEnd        = Lighting.FogEnd,
		FogStart      = Lighting.FogStart,
		ClockTime     = Lighting.ClockTime,
	}

	Tabs.FPSBoost:CreateSection("⚡ FPS Boost")

	Tabs.FPSBoost:CreateToggle({
		Name = "FPS Boost",
		Description = "Activa todas las optimizaciones al mismo tiempo",
		CurrentValue = false,
		Callback = function(v)
			if v then _trackUse("FPS Boost") end
			pcall(function() settings().Rendering.QualityLevel = v and 1 or 10 end)
			Lighting.GlobalShadows = v and false or _origLighting.GlobalShadows
			Lighting.FogEnd        = v and 100000 or _origLighting.FogEnd
			Lighting.FogStart      = v and 99999  or _origLighting.FogStart
			for _, obj in pairs(Lighting:GetDescendants()) do
				if obj:IsA("PostEffect") then obj.Enabled = not v end
			end
			for _, obj in pairs(workspace:GetDescendants()) do
				if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
					obj.Enabled = not v
				end
			end
			Luna:Notification({
				Title = "FPS Boost",
				Content = v and "Optimizaciones activadas!" or "Optimizaciones desactivadas!",
				Icon = "16781406675", ImageSource = "Custom", Duration = 3
			})
		end
	})

	Tabs.FPSBoost:CreateToggle({
		Name = "Fullbright",
		Description = "Máximo brillo, sin oscuridad ni niebla",
		CurrentValue = false,
		Callback = function(v)
			if v then _trackUse("Fullbright") end
			Lighting.Brightness    = v and 2   or _origLighting.Brightness
			Lighting.Ambient       = v and Color3.fromRGB(178,178,178) or _origLighting.Ambient
			Lighting.GlobalShadows = v and false or _origLighting.GlobalShadows
			Lighting.FogEnd        = v and 100000 or _origLighting.FogEnd
			Lighting.FogStart      = v and 99999  or _origLighting.FogStart
			Lighting.ClockTime     = v and 14 or _origLighting.ClockTime
		end
	})

	local _savedMaterials = {}
	Tabs.FPSBoost:CreateToggle({
		Name = "Remove Textures",
		Description = "Elimina texturas, decals y partículas del mapa",
		CurrentValue = false,
		Callback = function(v)
			if v then _trackUse("Remove Textures") end
			if v then
				_savedMaterials = {}
				for _, obj in pairs(workspace:GetDescendants()) do
					if obj:IsA("BasePart") then
						_savedMaterials[obj] = obj.Material
						obj.Material = Enum.Material.SmoothPlastic
					end
					if obj:IsA("Decal") or obj:IsA("Texture") then
						obj.Transparency = 1
					end
					if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
						obj.Enabled = false
					end
				end
			else
				for _, obj in pairs(workspace:GetDescendants()) do
					if obj:IsA("BasePart") and _savedMaterials[obj] then
						obj.Material = _savedMaterials[obj]
					end
					if obj:IsA("Decal") or obj:IsA("Texture") then
						obj.Transparency = 0
					end
					if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
						obj.Enabled = true
					end
				end
				_savedMaterials = {}
			end
		end
	})

	Tabs.FPSBoost:CreateButton({
		Name = "Nuke Effects",
		Description = "⚠️ Elimina permanentemente partículas, efectos y SelectionBoxes. Usa 'Restore' para los demás valores.",
		Callback = function()
			_trackUse("Nuke Effects")
			pcall(function() settings().Rendering.QualityLevel = 1 end)
			Lighting.GlobalShadows = false
			for _, obj in pairs(Lighting:GetDescendants()) do
				if obj:IsA("PostEffect") then obj.Enabled = false end
			end
			for _, obj in pairs(workspace:GetDescendants()) do
				if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire")
				or obj:IsA("Sparkles") or obj:IsA("SelectionBox") then
					pcall(function() obj:Destroy() end)
				end
			end
			Luna:Notification({Title="FPS Boost", Content="Efectos nukiados! (permanente en esta sesión)", Icon="16781406675", ImageSource="Custom", Duration=4})
		end
	})

	Tabs.FPSBoost:CreateButton({
		Name = "Restore",
		Description = "Restaura gráficos al estado original del juego",
		Callback = function()
			pcall(function() settings().Rendering.QualityLevel = 10 end)
			Lighting.GlobalShadows = _origLighting.GlobalShadows
			Lighting.Brightness    = _origLighting.Brightness
			Lighting.Ambient       = _origLighting.Ambient
			Lighting.FogEnd        = _origLighting.FogEnd
			Lighting.FogStart      = _origLighting.FogStart
			Lighting.ClockTime     = _origLighting.ClockTime
			for _, obj in pairs(Lighting:GetDescendants()) do
				if obj:IsA("PostEffect") then obj.Enabled = true end
			end
			Luna:Notification({Title="FPS Boost", Content="Gráficos restaurados al estado original!", Icon="16781406675", ImageSource="Custom", Duration=3})
		end
	})

	Tabs.Scripts:CreateSection("🖼️ Image ID")

	Main.ClipsDescendants = true

	local bgImageLabel = Instance.new("ImageLabel")
	bgImageLabel.Name = "BackgroundImage"
	bgImageLabel.Size = UDim2.new(1, 0, 1, 0)
	bgImageLabel.Position = UDim2.new(0, 0, 0, 0)
	bgImageLabel.AnchorPoint = Vector2.new(0, 0)
	bgImageLabel.BackgroundTransparency = 1
	bgImageLabel.ImageTransparency = 0
	bgImageLabel.ScaleType = Enum.ScaleType.Crop
	bgImageLabel.ZIndex = 1
	bgImageLabel.Visible = false
	bgImageLabel.Parent = Main.Elements.Parent

	local HttpService = game:GetService("HttpService")
	local DEFAULT_ID = "91100393730169"
	local saveFolder = "BladeX"
	local saveFile = saveFolder .. "/bgSettings.txt"

	if not isfolder(saveFolder) then
		pcall(function() makefolder(saveFolder) end)
	end

	local currentID = DEFAULT_ID
	local currentTransparency = 0
	local currentEnabled = false

	local function loadSettings()
		if not isfile(saveFile) then return end
		local ok, data = pcall(function()
			return HttpService:JSONDecode(readfile(saveFile))
		end)
		if ok and type(data) == "table" then
			currentID          = (type(data.imageID) == "string" and data.imageID ~= "") and data.imageID or DEFAULT_ID
			currentTransparency = type(data.transparency) == "number" and math.clamp(data.transparency, 0, 1) or 0
			currentEnabled     = data.enabled ~= false
		end
	end

	local function saveSettings()
		pcall(function()
			writefile(saveFile, HttpService:JSONEncode({
				imageID      = currentID,
				transparency = currentTransparency,
				enabled      = currentEnabled,
			}))
		end)
	end

	local function applyImage(id)
		if not id or id == "" then return end
		local numericID = tostring(id):match("%d+")
		if not numericID then return end

		local finalImage = "rbxassetid://" .. numericID
		pcall(function()
			local obj = game:GetObjects("rbxassetid://" .. numericID)[1]
			if obj and obj:IsA("Decal") and obj.Texture ~= "" then
				finalImage = obj.Texture
			elseif obj and obj:IsA("Texture") and obj.Texture ~= "" then
				finalImage = obj.Texture
			end
		end)

		currentID = numericID
		bgImageLabel.Image = finalImage
		bgImageLabel.Visible = currentEnabled
		saveSettings()
	end

	local function applyTransparency(value)
		currentTransparency = math.clamp(value, 0, 1)
		bgImageLabel.ImageTransparency = currentTransparency
		saveSettings()
	end

	local origMain       = Main.BackgroundTransparency
	local origElements   = Main.Elements.BackgroundTransparency
	local origNav        = Main.Navigation.BackgroundTransparency
	local _okLine, origLine = pcall(function() return Main.Line.BackgroundTransparency end)
	origLine = _okLine and origLine or 0
	local _okNavLine, origNavLine = pcall(function() return Main.Navigation.Line.BackgroundTransparency end)
	origNavLine = _okNavLine and origNavLine or 0
	local origElementsParent = Main.Elements.Parent.BackgroundTransparency

	local function setBgTransparent(transparent)
		local t = TweenInfo.new(0.3, Enum.EasingStyle.Exponential)
		if transparent then
			TweenService:Create(Main, t, {BackgroundTransparency = 1}):Play()
			TweenService:Create(Main.Elements, t, {BackgroundTransparency = 1}):Play()
			TweenService:Create(Main.Navigation, t, {BackgroundTransparency = 1}):Play()
			TweenService:Create(Main.Elements.Parent, t, {BackgroundTransparency = 1}):Play()
			pcall(function() TweenService:Create(Main.Line, t, {BackgroundTransparency = 1}):Play() end)
			pcall(function() TweenService:Create(Main.Navigation.Line, t, {BackgroundTransparency = 1}):Play() end)
		else
			TweenService:Create(Main, t, {BackgroundTransparency = origMain}):Play()
			TweenService:Create(Main.Elements, t, {BackgroundTransparency = origElements}):Play()
			TweenService:Create(Main.Navigation, t, {BackgroundTransparency = origNav}):Play()
			TweenService:Create(Main.Elements.Parent, t, {BackgroundTransparency = origElementsParent}):Play()
			pcall(function() TweenService:Create(Main.Line, t, {BackgroundTransparency = origLine}):Play() end)
			pcall(function() TweenService:Create(Main.Navigation.Line, t, {BackgroundTransparency = origNavLine}):Play() end)
		end
	end

	local function applyEnabled(value)
		currentEnabled = value
		bgImageLabel.Visible = value and currentID ~= ""
		setBgTransparent(value)
		saveSettings()
	end

	loadSettings()
	if currentID == "6368108640" then
		currentID = DEFAULT_ID
		saveSettings()
	end
	if not isfile(saveFile) then
		saveSettings()
	end
	local initImage = "rbxassetid://" .. currentID
	pcall(function()
		local obj = game:GetObjects("rbxassetid://" .. currentID)[1]
		if obj and obj:IsA("Decal") and obj.Texture ~= "" then
			initImage = obj.Texture
		elseif obj and obj:IsA("Texture") and obj.Texture ~= "" then
			initImage = obj.Texture
		end
	end)
	bgImageLabel.Image = initImage
	bgImageLabel.ImageTransparency = currentTransparency
	bgImageLabel.Visible = currentEnabled
	if currentEnabled then
		Main.BackgroundTransparency = 1
		pcall(function() Main.Elements.BackgroundTransparency = 1 end)
		pcall(function() Main.Elements.Parent.BackgroundTransparency = 1 end)
		pcall(function() Main.Navigation.BackgroundTransparency = 1 end)
		pcall(function() Main.Line.BackgroundTransparency = 1 end)
		pcall(function() Main.Navigation.Line.BackgroundTransparency = 1 end)
	end

	Tabs.Scripts:CreateToggle({
		Name = "Enable Background Image",
		Description = "Mostrar/ocultar imagen de fondo",
		CurrentValue = currentEnabled,
		Callback = function(Value)
			applyEnabled(Value)
		end
	})

	Tabs.Scripts:CreateSlider({
		Name = "Image Transparency",
		Description = "Set transparency of the Image",
		Range = {0, 100},
		Increment = 5,
		CurrentValue = math.floor(currentTransparency * 100),
		Callback = function(Value)
			applyTransparency(Value / 100)
		end
	})

	-- Fix 2.1: Parámetros corregidos de CreateInput (DefaultText→CurrentValue, NumbersOnly→Numeric, ClearTextAfterFocusLost→RemoveTextAfterFocusLost)
	Tabs.Scripts:CreateInput({
		Name = "Background Image ID",
		Description = "Change GUI background image",
		PlaceholderText = "rbxassetid://" .. currentID,
		CurrentValue = currentID,
		Numeric = false,
		RemoveTextAfterFocusLost = false,
		Callback = function(Value)
			if Value and Value ~= "" then
				applyImage(Value)
			end
		end
	})

	Tabs.Scripts2:CreateSection("📜 Scripts")
	Tabs.Scripts2:CreateButton({
		Name = "Climb For Brainrots",
		Description = "Carga el script Climb For Brainrots",
		Callback = function()
			local ok, err = pcall(function()
				loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/ClimbForBrainrots"))()
			end)
			if ok then
				Luna:Notification({Title="Scripts", Content="Climb For Brainrots cargado!", Icon="integration_instructions", ImageSource="Material", Duration=3})
			else
				Luna:Notification({Title="Error al cargar", Content="ClimbForBrainrots: "..tostring(err):sub(1,80), Icon="dangerous", ImageSource="Material", Duration=5})
			end
		end
	})
	Tabs.Scripts2:CreateButton({
		Name = "Climb Worm Tower",
		Description = "Carga el script Climb Worm Tower For Brainrots",
		Callback = function()
			local ok, err = pcall(function()
				loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/ClimbWormTowerforBrainrots"))()
			end)
			if ok then
				Luna:Notification({Title="Scripts", Content="Climb Worm Tower cargado!", Icon="integration_instructions", ImageSource="Material", Duration=3})
			else
				Luna:Notification({Title="Error al cargar", Content="ClimbWormTower: "..tostring(err):sub(1,80), Icon="dangerous", ImageSource="Material", Duration=5})
			end
		end
	})
	Tabs.Scripts2:CreateButton({
		Name = "Infinite Yield",
		Description = "Carga el admin command script Infinite Yield",
		Callback = function()
			local ok, err = pcall(function()
				loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
			end)
			if ok then
				Luna:Notification({Title="Scripts", Content="Infinite Yield cargado!", Icon="integration_instructions", ImageSource="Material", Duration=3})
			else
				Luna:Notification({Title="Error al cargar", Content="InfiniteYield: "..tostring(err):sub(1,80), Icon="dangerous", ImageSource="Material", Duration=5})
			end
		end
	})
	Tabs.Scripts2:CreateButton({
		Name = "Dark Dex",
		Description = "Explorador del juego (Dark Dex v3)",
		Callback = function()
			local ok, err = pcall(function()
				loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
			end)
			if ok then
				Luna:Notification({Title="Scripts", Content="Dark Dex cargado!", Icon="integration_instructions", ImageSource="Material", Duration=3})
			else
				Luna:Notification({Title="Error al cargar", Content="DarkDex: "..tostring(err):sub(1,80), Icon="dangerous", ImageSource="Material", Duration=5})
			end
		end
	})
	Tabs.Scripts2:CreateButton({
		Name = "Remote Spy",
		Description = "Espía los eventos remotos del juego",
		Callback = function()
			local ok, err = pcall(function()
				loadstring(game:HttpGet("https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua"))()
			end)
			if ok then
				Luna:Notification({Title="Scripts", Content="Remote Spy cargado!", Icon="integration_instructions", ImageSource="Material", Duration=3})
			else
				Luna:Notification({Title="Error al cargar", Content="RemoteSpy: "..tostring(err):sub(1,80), Icon="dangerous", ImageSource="Material", Duration=5})
			end
		end
	})
	Tabs.Scripts2:CreateSection("⚡ Utilidades")

	-- ── Anti AFK (con persistencia) ─────────────────────────────────────────
	local function _startAntiAFK()
		if _G.AntiAFK then
			pcall(function() _G.AntiAFK:Disconnect() end)
			_G.AntiAFK = nil
		end
		local _afkTimer = 0
		_G.AntiAFK = RunService.Heartbeat:Connect(function(dt)
			_afkTimer = _afkTimer + dt
			if _afkTimer < 60 then return end -- simular actividad cada 60s
			_afkTimer = 0
			pcall(function()
				local VirtualUser = game:GetService("VirtualUser")
				VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
				VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
			end)
		end)
	end

	Tabs.Scripts2:CreateToggle({
		Name = "Anti AFK",
		Description = "Evita que Roblox te expulse por inactividad",
		CurrentValue = _cfg.antiAFK,
		Callback = function(v)
			if v then _trackUse("Anti AFK") end
			_cfg.antiAFK = v
			_saveCfg()
			if v then
				_startAntiAFK()
			elseif _G.AntiAFK then
				pcall(function() _G.AntiAFK:Disconnect() end)
				_G.AntiAFK = nil
			end
		end
	})
	-- Aplicar Anti AFK guardado al cargar
	if _cfg.antiAFK then
		_startAntiAFK()
	end

	-- ── No Clip (persistencia + respawn) ────────────────────────────────────
	local _noClipActive = _cfg.noClip
	local function _applyNoClip(char)
		if not char or not _noClipActive then return end
		for _, p in pairs(char:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end

	Tabs.Scripts2:CreateToggle({
		Name = "No Clip",
		Description = "Atraviesa paredes y objetos del mapa",
		CurrentValue = _cfg.noClip,
		Callback = function(v)
			if v then _trackUse("No Clip") end
			_noClipActive = v
			_G.NoClip = v
			_cfg.noClip = v
			_saveCfg()
			if v then
				_G.NoClipConn = game:GetService("RunService").Stepped:Connect(function()
					if _noClipActive then
						_applyNoClip(game.Players.LocalPlayer.Character)
					end
				end)
			elseif _G.NoClipConn then
				_G.NoClipConn:Disconnect()
				_G.NoClipConn = nil
				-- Restaurar colisión
				local char = Player.Character
				if char then
					for _, p in pairs(char:GetDescendants()) do
						if p:IsA("BasePart") then
							pcall(function() p.CanCollide = true end)
						end
					end
				end
			end
		end
	})
	-- Aplicar NoClip guardado al cargar
	if _cfg.noClip then
		_G.NoClip = true
		_G.NoClipConn = game:GetService("RunService").Stepped:Connect(function()
			if _noClipActive then _applyNoClip(Player.Character) end
		end)
	end

	-- ── Walk Speed (persistencia + respawn) ─────────────────────────────────
	local _savedWalkSpeed = _cfg.walkSpeed
	local function _applyWalkSpeed(char)
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = _savedWalkSpeed end
	end

	Tabs.Scripts2:CreateSlider({
		Name = "Walk Speed",
		Description = "Velocidad de movimiento del personaje (se mantiene al respawnear)",
		Range = {5, 300},
		Increment = 1,
		CurrentValue = _cfg.walkSpeed,
		Callback = function(v)
			_trackUse("Walk Speed")
			_savedWalkSpeed = v
			_cfg.walkSpeed = v
			_saveCfg()
			_applyWalkSpeed(Player.Character)
		end
	})

	-- ── Jump Power (persistencia + respawn) ─────────────────────────────────
	local _savedJumpPower = _cfg.jumpPower
	local function _applyJumpPower(char)
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum.JumpPower = _savedJumpPower end
	end

	Tabs.Scripts2:CreateSlider({
		Name = "Jump Power",
		Description = "Potencia de salto (default: 50). Nota: juegos con JumpHeight pueden ignorarlo.",
		Range = {0, 500},
		Increment = 5,
		CurrentValue = _cfg.jumpPower,
		Callback = function(v)
			_trackUse("Jump Power")
			_savedJumpPower = v
			_cfg.jumpPower = v
			_saveCfg()
			_applyJumpPower(Player.Character)
		end
	})

	-- ── Aplicar stats al cargar y en cada respawn ────────────────────────────
	_applyWalkSpeed(Player.Character)
	_applyJumpPower(Player.Character)
	Player.CharacterAdded:Connect(function(char)
		task.wait(0.5) -- esperar a que el personaje esté listo
		_applyWalkSpeed(char)
		_applyJumpPower(char)
		if _noClipActive then _applyNoClip(char) end
	end)

	do
			local playlists = {
				{
					genre = "Phonk / Drift",
					songs = {
						{ name = "Metamorphosis",          id = "rbxassetid://15689451063"         },
						{ name = "Sinistra",               id = "rbxassetid://15689443663"         },
						{ name = "Dionic",                 id = "rbxassetid://15689445424"         },
						{ name = "Invade Groom",           id = "rbxassetid://15689453529"         },
						{ name = "The Final Phonk",        id = "rbxassetid://14145620056"         },
						{ name = "Emotional Damage",       id = "rbxassetid://14145621151"         },
						{ name = "Raven Theme",            id = "rbxassetid://14145621445"         },
						{ name = "No Lights",              id = "rbxassetid://14145623221"         },
						{ name = "Monster Bass",           id = "rbxassetid://14145623658"         },
						{ name = "Bell Pepper",            id = "rbxassetid://14145626111"         },
					}
				},
				{
					genre = "Phonk Hard",
					songs = {
						{ name = "Phonk't Out",            id = "rbxassetid://14145625743"         },
						{ name = "Unbreakable",            id = "rbxassetid://14145626744"         },
						{ name = "Black Seed",             id = "rbxassetid://14145622615"         },
						{ name = "Back & Front",           id = "rbxassetid://14145627474"         },
						{ name = "Cowbell God",            id = "rbxassetid://16190760005"         },
						{ name = "Down2Kill",              id = "rbxassetid://16190760285"         },
						{ name = "HR -Eeyuh",              id = "rbxassetid://16190782181"         },
						{ name = "Infinite",               id = "rbxassetid://16190784875"         },
						{ name = "Ultima",                 id = "rbxassetid://16190756998"         },
						{ name = "Redemption",             id = "rbxassetid://16190783774"         },
					}
				},
				{
					genre = "Phonk Chill",
					songs = {
						{ name = "Drooly",                 id = "rbxassetid://8053389869"          },
						{ name = "Heptraxous",             id = "rbxassetid://8185857772"          },
						{ name = "Stupid Remix",           id = "rbxassetid://16662833837"         },
						{ name = "AB4T",                   id = "rbxassetid://17422173467"         },
						{ name = "Alanwaad",               id = "rbxassetid://17422074849"         },
						{ name = "Metaverse",              id = "rbxassetid://17422168798"         },
						{ name = "Wassa",                  id = "rbxassetid://17422207260"         },
						{ name = "Gabbermix",              id = "rbxassetid://18841887539"         },
						{ name = "Uzipack",                id = "rbxassetid://18841894272"         },
					}
				},
			}
		local allSongs = {}
		for _, pl in ipairs(playlists) do
			for _, s in ipairs(pl.songs) do
				table.insert(allSongs, { name = s.name, id = s.id, genre = pl.genre })
			end
		end

		local SoundService = game:GetService("SoundService")
		local _musicSound = Instance.new("Sound")
		_musicSound.Name   = "BladeX_Music"
		_musicSound.Volume = 0.5
		-- Fix 2.4: Siempre false; el loop se maneja en el evento Ended
		_musicSound.Looped = false
		_musicSound.Parent = SoundService
		_G.BladeXMusic = _musicSound

		local _isPlaying   = false
		local _isShuffle   = false
		local _isLoop      = true
		local _currentIdx  = 1
		local _currentList = allSongs
		local _progressConn = nil
		local _loaded      = false

		local playerGui = Player:WaitForChild("PlayerGui")
		local screenGui = Instance.new("ScreenGui", playerGui)
		screenGui.Name = "BladeX_MusicPlayer"
		screenGui.ResetOnSpawn = false
		screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

		-- ══════════════════════════════════════════════════════
		-- BLADEX MUSIC PLAYER  v3  ·  estilo RELICS
		-- ══════════════════════════════════════════════════════
		local CA  = Color3.fromRGB(180, 40, 220)     -- magenta accent
		local CB  = Color3.fromRGB(22,  22,  30)    -- fondo base (más oscuro)
		local CC  = Color3.fromRGB(30,  30,  42)    -- card
		local CT  = Color3.fromRGB(245, 245, 255)   -- texto claro
		local CM  = Color3.fromRGB(120, 118, 148)   -- texto muted

		local ICON_SHUFFLE = "rbxassetid://6026667003"
		local ICON_PREV    = "rbxassetid://6026667011"
		local ICON_PLAY    = "rbxassetid://6026663699"
		local ICON_PAUSE   = "rbxassetid://6026663719"
		local ICON_NEXT    = "rbxassetid://6026667005"
		local ICON_LOOP    = "rbxassetid://6026666998"

		-- ══════════════════════════════════════════════════════
		-- FRAME RAÍZ – diseño HORIZONTAL COMPACTO estilo RELICSxyz
		-- Tamaño: 420 × 260  (ancho > alto, compacto)
		-- ══════════════════════════════════════════════════════
		local PW, PH = 420, 260   -- ancho, alto EXPANDIDO
		local PH_MIN = 44          -- alto MINIMIZADO (solo header)

		local playerFrame = Instance.new("Frame", screenGui)
		playerFrame.Name             = "PlayerFrame"
		playerFrame.Size             = UDim2.fromOffset(PW, PH)
		playerFrame.Position         = UDim2.new(0.5,-PW/2, 1,-PH-18)
		playerFrame.BackgroundColor3 = CB
		playerFrame.BorderSizePixel  = 0
		playerFrame.Active           = true
		playerFrame.Draggable        = true
		playerFrame.Visible          = false
		playerFrame.ClipsDescendants = true
		Instance.new("UICorner", playerFrame).CornerRadius = UDim.new(0,14)
		local _pfStroke = Instance.new("UIStroke", playerFrame)
		_pfStroke.Color = Color3.fromRGB(60,52,88) _pfStroke.Thickness = 1 _pfStroke.Transparency = 0.38

		-- ── HEADER (siempre visible, incluye minimize) ───────────────────
		local _hdr = Instance.new("Frame", playerFrame)
		_hdr.Size = UDim2.new(1,0,0,44)
		_hdr.Position = UDim2.new(0,0,0,0)   -- SIEMPRE en la cima, posición absoluta
		_hdr.BackgroundColor3 = Color3.fromRGB(16,15,22)
		_hdr.BorderSizePixel = 0
		_hdr.ZIndex = 10
		local _hdrCorner = Instance.new("UICorner",_hdr)
		_hdrCorner.CornerRadius = UDim.new(0,14)

		local _hdrBotFill = Instance.new("Frame",_hdr)
		_hdrBotFill.Size=UDim2.new(1,0,0,14) _hdrBotFill.Position=UDim2.new(0,0,1,-14)
		_hdrBotFill.BackgroundColor3=Color3.fromRGB(16,15,22) _hdrBotFill.BorderSizePixel=0 _hdrBotFill.ZIndex=10

		local _hdrLine = Instance.new("Frame", playerFrame)
		_hdrLine.Size = UDim2.new(1,0,0,1) _hdrLine.Position = UDim2.new(0,0,0,44)
		_hdrLine.BackgroundColor3 = Color3.fromRGB(44,38,62) _hdrLine.BorderSizePixel = 0

		-- ícono diamante
		local _hdrIcon = Instance.new("ImageLabel", _hdr)
		_hdrIcon.Size = UDim2.fromOffset(20,20) _hdrIcon.Position = UDim2.new(0,12,0.5,-10)
		_hdrIcon.BackgroundTransparency = 1 _hdrIcon.ZIndex = 11
		_hdrIcon.Image = "rbxassetid://99259191458226"
		_hdrIcon.ImageColor3 = CA _hdrIcon.ScaleType = Enum.ScaleType.Fit

		local _hdrLbl = Instance.new("TextLabel", _hdr)
		_hdrLbl.Size = UDim2.new(1,-110,1,0) _hdrLbl.Position = UDim2.new(0,38,0,0)
		_hdrLbl.BackgroundTransparency = 1 _hdrLbl.ZIndex = 11
		_hdrLbl.Text = "Bladex reproductor"
		_hdrLbl.TextColor3 = CM _hdrLbl.TextSize = 12 _hdrLbl.Font = Enum.Font.Gotham
		_hdrLbl.TextXAlignment = Enum.TextXAlignment.Left

		-- Botón MINIMIZAR (—/▲)
		local _minimized = false
		local minimizeBtn = Instance.new("TextButton", _hdr)
		minimizeBtn.Size = UDim2.fromOffset(28,28) minimizeBtn.Position = UDim2.new(1,-64,0.5,-14)
		minimizeBtn.BackgroundColor3 = Color3.fromRGB(38,30,55) minimizeBtn.ZIndex = 12
		minimizeBtn.Text = "—" minimizeBtn.TextColor3 = CT
		minimizeBtn.TextSize = 14 minimizeBtn.Font = Enum.Font.GothamBold
		minimizeBtn.BorderSizePixel = 0 minimizeBtn.AutoButtonColor = false
		Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(1,0)

		-- Botón CERRAR (×)
		local closeBtn = Instance.new("TextButton", _hdr)
		closeBtn.Size = UDim2.fromOffset(28,28) closeBtn.Position = UDim2.new(1,-30,0.5,-14)
		closeBtn.BackgroundColor3 = Color3.fromRGB(38,30,55) closeBtn.ZIndex = 12
		closeBtn.Text = "×" closeBtn.TextColor3 = CT
		closeBtn.TextSize = 18 closeBtn.Font = Enum.Font.GothamBold
		closeBtn.BorderSizePixel = 0 closeBtn.AutoButtonColor = false
		Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1,0)

		-- ── CUERPO COLAPSABLE (todo lo que NO es el header) ─────────────
		-- Se oculta/muestra al minimizar, en lugar de redimensionar el frame completo
		local _body = Instance.new("Frame", playerFrame)
		_body.Name = "Body"
		_body.Size = UDim2.new(1,0,0, PH - 44)
		_body.Position = UDim2.new(0,0,0,45)
		_body.BackgroundTransparency = 1
		_body.ClipsDescendants = true

		-- Lógica minimizar / expandir  (toggle Visible del body)
		local TweenService2 = game:GetService("TweenService")
		minimizeBtn.MouseButton1Click:Connect(function()
			_minimized = not _minimized
			if _minimized then
				-- Colapsar: animar hacia 44px y ocultar body al final
				local tw = TweenService2:Create(playerFrame,
					TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
					{Size = UDim2.fromOffset(PW, PH_MIN)}
				)
				tw:Play()
				tw.Completed:Connect(function()
					_body.Visible = false
				end)
				minimizeBtn.Text = "▲"
				minimizeBtn.TextSize = 11
			else
				-- Expandir: mostrar body primero, luego animar tamaño completo
				_body.Visible = true
				local tw = TweenService2:Create(playerFrame,
					TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
					{Size = UDim2.fromOffset(PW, PH)}
				)
				tw:Play()
				minimizeBtn.Text = "—"
				minimizeBtn.TextSize = 14
			end
		end)

		-- ── BARRA DE PESTAÑAS (dentro del body, en la parte inferior) ───
		local _tabBar = Instance.new("Frame", _body)
		_tabBar.Size = UDim2.new(1,0,0,46) _tabBar.Position = UDim2.new(0,0,1,-46)
		_tabBar.BackgroundColor3 = Color3.fromRGB(14,14,20) _tabBar.BorderSizePixel = 0
		local _tbCorner = Instance.new("UICorner",_tabBar)
		_tbCorner.CornerRadius = UDim.new(0,14)
		local _tbTopFill = Instance.new("Frame",_tabBar)
		_tbTopFill.Size=UDim2.new(1,0,0,14) _tbTopFill.Position=UDim2.new(0,0,0,0)
		_tbTopFill.BackgroundColor3=Color3.fromRGB(14,14,20) _tbTopFill.BorderSizePixel=0

		local _tabSep = Instance.new("Frame", _body)
		_tabSep.Size = UDim2.new(1,0,0,1) _tabSep.Position = UDim2.new(0,0,1,-47)
		_tabSep.BackgroundColor3 = Color3.fromRGB(44,38,62) _tabSep.BorderSizePixel = 0

		-- ícono pestaña helper
		local function _makeTab(parent, name, icon, label, xFrac)
			local btn = Instance.new("TextButton", parent)
			btn.Name = name btn.Text = ""
			btn.Size = UDim2.new(1/3,0,1,0) btn.Position = UDim2.new(xFrac,0,0,0)
			btn.BackgroundTransparency = 1 btn.BorderSizePixel = 0
			local ic = Instance.new("ImageLabel", btn)
			ic.Name = "Ic" ic.Size = UDim2.fromOffset(20,20)
			ic.AnchorPoint = Vector2.new(0.5,0.5) ic.Position = UDim2.new(0.5,0,0.35,0)
			ic.BackgroundTransparency = 1 ic.Image = icon ic.ImageColor3 = CM
			ic.ScaleType = Enum.ScaleType.Fit
			local lbl = Instance.new("TextLabel", btn)
			lbl.Name = "Lbl" lbl.Size = UDim2.new(1,0,0,11) lbl.Position = UDim2.new(0,0,0.65,0)
			lbl.BackgroundTransparency = 1 lbl.Text = label lbl.TextColor3 = CM
			lbl.TextSize = 8 lbl.Font = Enum.Font.Gotham
			return btn
		end
		local _tabPlayer  = _makeTab(_tabBar,"player",  ICON_PLAY,               "Reproductor", 0)
		local _tabLibrary = _makeTab(_tabBar,"library", "rbxassetid://6031233835","Buscar",     1/3)
		local _tabFavs    = _makeTab(_tabBar,"favs",    "rbxassetid://6023426974","Favoritos", 2/3)

		-- ── ÁREA DE CONTENIDO (dentro de _body) ─────────────────────────
		-- _body height = PH-44 = 216px; tabBar = 46px; content = 170px
		local _content = Instance.new("Frame", _body)
		_content.Size = UDim2.new(1,0,0, PH - 44 - 46)   -- 170px
		_content.Position = UDim2.new(0,0,0,0)
		_content.BackgroundTransparency = 1 _content.ClipsDescendants = true

		-- ═══════════════════════════════════
		-- PÁGINA 1 : REPRODUCTOR  (layout horizontal compacto)
		-- ═══════════════════════════════════
		local _pagePlayer = Instance.new("Frame", _content)
		_pagePlayer.Size = UDim2.fromScale(1,1)
		_pagePlayer.BackgroundTransparency = 1

		--  ┌──────────────────────────────────────────┐
		--  │ Título              [↺] [♡]              │  y=10 h=24
		--  │ Género                                   │  y=34 h=14
		--  │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │  y=56 h=4
		--  │ 00:00                           01:42    │  y=64 h=12
		--  │ [waveform left 45%] << [II] >>  [right]  │  y=82 h=54
		-- volume row
		--  │ 🔈 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 🔊  │  y=154 h=20
		--  └──────────────────────────────────────────┘

		-- Título
		local _bigTitle = Instance.new("TextLabel", _pagePlayer)
		_bigTitle.Size = UDim2.new(1,-74,0,26) _bigTitle.Position = UDim2.new(0,16,0,10)
		_bigTitle.BackgroundTransparency = 1
		_bigTitle.Text = "SIN REPRODUCCIÓN"
		_bigTitle.TextColor3 = CT _bigTitle.TextSize = 18 _bigTitle.Font = Enum.Font.GothamBold
		_bigTitle.TextXAlignment = Enum.TextXAlignment.Left _bigTitle.ClipsDescendants = true

		-- Género
		local _bigGenre = Instance.new("TextLabel", _pagePlayer)
		_bigGenre.Size = UDim2.new(1,-74,0,13) _bigGenre.Position = UDim2.new(0,16,0,36)
		_bigGenre.BackgroundTransparency = 1
		_bigGenre.Text = "Género"
		_bigGenre.TextColor3 = CM _bigGenre.TextSize = 10 _bigGenre.Font = Enum.Font.Gotham
		_bigGenre.TextXAlignment = Enum.TextXAlignment.Left

		-- Loop button (arriba derecha)
		local _loopIco = Instance.new("ImageButton", _pagePlayer)
		_loopIco.Size = UDim2.fromOffset(24,24) _loopIco.Position = UDim2.new(1,-52,0,20)
		_loopIco.BackgroundTransparency = 1 _loopIco.Image = ICON_LOOP
		_loopIco.ImageColor3 = CA _loopIco.ScaleType = Enum.ScaleType.Fit _loopIco.BorderSizePixel = 0

		-- Heart button (arriba derecha)
		local _heartTop = Instance.new("ImageButton", _pagePlayer)
		_heartTop.Size = UDim2.fromOffset(24,24) _heartTop.Position = UDim2.new(1,-24,0,20)
		_heartTop.BackgroundTransparency = 1 _heartTop.Image = "rbxassetid://6023426974"
		_heartTop.ImageColor3 = CM _heartTop.ScaleType = Enum.ScaleType.Fit _heartTop.BorderSizePixel = 0
		-- (La lógica de favoritos se conecta más abajo, tras definir toggleFavorite)

		-- Barra de progreso (delgada, blanca con fill morado)
		local _progBg = Instance.new("Frame", _pagePlayer)
		_progBg.Size = UDim2.new(1,-32,0,3) _progBg.Position = UDim2.new(0,16,0,56)
		_progBg.BackgroundColor3 = Color3.fromRGB(50,40,75) _progBg.BorderSizePixel = 0
		Instance.new("UICorner",_progBg).CornerRadius = UDim.new(1,0)

		local progressFill = Instance.new("Frame", _progBg)
		progressFill.Size = UDim2.fromScale(0,1) progressFill.BorderSizePixel = 0
		Instance.new("UICorner",progressFill).CornerRadius = UDim.new(1,0)
		local _pfGrad = Instance.new("UIGradient",progressFill)
		_pfGrad.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(120,30,195)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(215,75,255)),
		}

		local progDot = Instance.new("Frame", _progBg)
		progDot.Size = UDim2.fromOffset(10,10)
		progDot.AnchorPoint = Vector2.new(0.5,0.5) progDot.Position = UDim2.new(0,0,0.5,0)
		progDot.BackgroundColor3 = CT progDot.BorderSizePixel = 0 progDot.ZIndex = 3
		Instance.new("UICorner",progDot).CornerRadius = UDim.new(1,0)

		-- Tiempos
		local timeLeft = Instance.new("TextLabel", _pagePlayer)
		timeLeft.Size = UDim2.fromOffset(44,12) timeLeft.Position = UDim2.new(0,16,0,63)
		timeLeft.BackgroundTransparency = 1 timeLeft.Text = "00:00"
		timeLeft.TextColor3 = CM timeLeft.TextSize = 9 timeLeft.Font = Enum.Font.GothamBold
		timeLeft.TextXAlignment = Enum.TextXAlignment.Left
		local timeLabel = timeLeft

		local timeRight = Instance.new("TextLabel", _pagePlayer)
		timeRight.Size = UDim2.fromOffset(44,12) timeRight.Position = UDim2.new(1,-60,0,63)
		timeRight.BackgroundTransparency = 1 timeRight.Text = "00:00"
		timeRight.TextColor3 = CM timeRight.TextSize = 9 timeRight.Font = Enum.Font.GothamBold
		timeRight.TextXAlignment = Enum.TextXAlignment.Right

		-- ── WAVEFORM (izquierda ~42% del ancho, pequeño, azul) ─────────
		local _waveW = math.floor(PW * 0.40) - 16   -- ~152px
		local _wave = Instance.new("Frame", _pagePlayer)
		_wave.Size = UDim2.fromOffset(_waveW, 42) _wave.Position = UDim2.new(0,16,0,82)
		_wave.BackgroundTransparency = 1 _wave.ClipsDescendants = true
		local _wGrad = Instance.new("UIGradient", _wave)
		_wGrad.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(60,20,220)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(130,40,255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(35,8,120)),
		}
		_wGrad.Rotation = 90

		local _waveBars = {}
		local _wCount = 22
		local _wBW = math.floor(_waveW / _wCount) - 1
		math.randomseed(777)
		local _wH = {}
		for wi=1,_wCount do _wH[wi]=math.random(3,32) end
		for wi=1,_wCount do
			local bar = Instance.new("Frame",_wave)
			bar.Size = UDim2.fromOffset(_wBW, _wH[wi])
			bar.AnchorPoint = Vector2.new(0,1)
			bar.Position = UDim2.new(0,(wi-1)*(_wBW+1),1,0)
			bar.BackgroundColor3 = Color3.fromRGB(255,255,255)
			bar.BackgroundTransparency = 0.28 bar.BorderSizePixel = 0
			Instance.new("UICorner",bar).CornerRadius = UDim.new(0,2)
			_waveBars[wi] = bar
		end

		-- ── CONTROLES (derecha) ────────────────────────────────────────
		local _ctrlW = PW - _waveW - 32 - 16
		local _ctrlRow = Instance.new("Frame", _pagePlayer)
		_ctrlRow.Size = UDim2.fromOffset(_ctrlW, 58)
		_ctrlRow.Position = UDim2.new(0, 16 + _waveW + 10, 0, 80)
		_ctrlRow.BackgroundTransparency = 1

		local ctrlBtns = {}

		-- PlayPause
		local _ppBtn = Instance.new("ImageButton", _ctrlRow)
		_ppBtn.Name = "PlayPause"
		_ppBtn.Size = UDim2.fromOffset(52,52)
		_ppBtn.AnchorPoint = Vector2.new(0.5,0.5)
		_ppBtn.Position = UDim2.new(0.5,0,0.5,0)
		_ppBtn.BackgroundColor3 = Color3.fromRGB(38,34,56)
		_ppBtn.Image = ICON_PAUSE _ppBtn.ImageColor3 = CT
		_ppBtn.ScaleType = Enum.ScaleType.Fit _ppBtn.BorderSizePixel = 0 _ppBtn.AutoButtonColor = false
		Instance.new("UICorner",_ppBtn).CornerRadius = UDim.new(1,0)
		local _ppStroke = Instance.new("UIStroke",_ppBtn)
		_ppStroke.Color=Color3.fromRGB(95,60,140) _ppStroke.Thickness=1.8
		local _ppPad = Instance.new("UIPadding",_ppBtn)
		_ppPad.PaddingTop=UDim.new(0,12) _ppPad.PaddingBottom=UDim.new(0,12)
		_ppPad.PaddingLeft=UDim.new(0,12) _ppPad.PaddingRight=UDim.new(0,12)
		ctrlBtns["PlayPause"] = _ppBtn

		-- Prev <<
		local _prevBtn = Instance.new("ImageButton", _ctrlRow)
		_prevBtn.Name = "Prev"
		_prevBtn.Size = UDim2.fromOffset(40,40)
		_prevBtn.AnchorPoint = Vector2.new(0.5,0.5)
		_prevBtn.Position = UDim2.new(0.5,-58,0.5,0)
		_prevBtn.BackgroundTransparency = 1
		_prevBtn.Image = ICON_PREV _prevBtn.ImageColor3 = CT
		_prevBtn.ScaleType = Enum.ScaleType.Fit _prevBtn.BorderSizePixel = 0
		local _prPad = Instance.new("UIPadding",_prevBtn)
		_prPad.PaddingTop=UDim.new(0,4) _prPad.PaddingBottom=UDim.new(0,4)
		_prPad.PaddingLeft=UDim.new(0,4) _prPad.PaddingRight=UDim.new(0,4)
		ctrlBtns["Prev"] = _prevBtn

		-- Next >>
		local _nextBtn = Instance.new("ImageButton", _ctrlRow)
		_nextBtn.Name = "Next"
		_nextBtn.Size = UDim2.fromOffset(40,40)
		_nextBtn.AnchorPoint = Vector2.new(0.5,0.5)
		_nextBtn.Position = UDim2.new(0.5,58,0.5,0)
		_nextBtn.BackgroundTransparency = 1
		_nextBtn.Image = ICON_NEXT _nextBtn.ImageColor3 = CT
		_nextBtn.ScaleType = Enum.ScaleType.Fit _nextBtn.BorderSizePixel = 0
		local _nxPad = Instance.new("UIPadding",_nextBtn)
		_nxPad.PaddingTop=UDim.new(0,4) _nxPad.PaddingBottom=UDim.new(0,4)
		_nxPad.PaddingLeft=UDim.new(0,4) _nxPad.PaddingRight=UDim.new(0,4)
		ctrlBtns["Next"] = _nextBtn

		-- Shuffle (pequeño, extremo izq)
		local _shufBtn = Instance.new("ImageButton", _ctrlRow)
		_shufBtn.Name = "Shuffle"
		_shufBtn.Size = UDim2.fromOffset(20,20)
		_shufBtn.AnchorPoint = Vector2.new(0.5,0.5)
		_shufBtn.Position = UDim2.new(0,14,0.5,0)
		_shufBtn.BackgroundTransparency = 1
		_shufBtn.Image = ICON_SHUFFLE _shufBtn.ImageColor3 = CM
		_shufBtn.ScaleType = Enum.ScaleType.Fit _shufBtn.BorderSizePixel = 0
		ctrlBtns["Shuffle"] = _shufBtn

		-- Loop (pequeño, extremo der)
		local _loopBtn = Instance.new("ImageButton", _ctrlRow)
		_loopBtn.Name = "Loop"
		_loopBtn.Size = UDim2.fromOffset(20,20)
		_loopBtn.AnchorPoint = Vector2.new(0.5,0.5)
		_loopBtn.Position = UDim2.new(1,-14,0.5,0)
		_loopBtn.BackgroundTransparency = 1
		_loopBtn.Image = ICON_LOOP _loopBtn.ImageColor3 = CA
		_loopBtn.ScaleType = Enum.ScaleType.Fit _loopBtn.BorderSizePixel = 0
		ctrlBtns["Loop"] = _loopBtn

		-- texto "play for others"
		local _playForOthers = Instance.new("TextLabel", _pagePlayer)
		_playForOthers.Size = UDim2.fromOffset(_ctrlW, 12)
		_playForOthers.Position = UDim2.new(0, 16 + _waveW + 10, 0, 141)
		_playForOthers.BackgroundTransparency = 1
		_playForOthers.Text = ""
		_playForOthers.TextColor3 = CM _playForOthers.TextSize = 9
		_playForOthers.Font = Enum.Font.Gotham
		_playForOthers.TextXAlignment = Enum.TextXAlignment.Center

		-- ── SLIDER DE VOLUMEN (ancho completo, al fondo) ─────────────────
		local _volRow = Instance.new("Frame", _pagePlayer)
		_volRow.Size = UDim2.new(1,-32,0,18) _volRow.Position = UDim2.new(0,16,0,156)
		_volRow.BackgroundTransparency = 1

		local _volIcoL = Instance.new("ImageLabel",_volRow)
		_volIcoL.Size = UDim2.fromOffset(14,14) _volIcoL.Position = UDim2.new(0,0,0.5,-7)
		_volIcoL.BackgroundTransparency=1 _volIcoL.Image="rbxassetid://6026568242"
		_volIcoL.ImageColor3=CM _volIcoL.ScaleType=Enum.ScaleType.Fit

		local _volTrack = Instance.new("Frame",_volRow)
		_volTrack.Size = UDim2.new(1,-38,0,5) _volTrack.Position = UDim2.new(0,20,0.5,-2)
		_volTrack.BackgroundColor3 = Color3.fromRGB(48,38,72) _volTrack.BorderSizePixel=0
		Instance.new("UICorner",_volTrack).CornerRadius = UDim.new(1,0)

		local _volFill = Instance.new("Frame",_volTrack)
		_volFill.Size = UDim2.fromScale(0.5,1) _volFill.BackgroundColor3 = CA _volFill.BorderSizePixel=0
		Instance.new("UICorner",_volFill).CornerRadius = UDim.new(1,0)
		local _vGrad = Instance.new("UIGradient",_volFill)
		_vGrad.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0,Color3.fromRGB(110,30,190)),
			ColorSequenceKeypoint.new(1,Color3.fromRGB(220,80,255)),
		}

		local _volIcoR = Instance.new("ImageLabel",_volRow)
		_volIcoR.Size = UDim2.fromOffset(18,18) _volIcoR.Position = UDim2.new(1,-18,0.5,-9)
		_volIcoR.BackgroundTransparency=1 _volIcoR.Image="rbxassetid://6026568242"
		_volIcoR.ImageColor3=CT _volIcoR.ScaleType=Enum.ScaleType.Fit

		-- badge VALID
		local statusBadge = Instance.new("TextLabel", _pagePlayer)
		statusBadge.Size = UDim2.fromOffset(58,15) statusBadge.Position = UDim2.new(0,16,0,156)
		statusBadge.BackgroundColor3 = Color3.fromRGB(22,148,70)
		statusBadge.TextColor3 = CT statusBadge.Text = "● VALID"
		statusBadge.TextSize = 8 statusBadge.Font = Enum.Font.GothamBold
		statusBadge.BorderSizePixel = 0 statusBadge.Visible = false
		Instance.new("UICorner",statusBadge).CornerRadius = UDim.new(0,5)

		local volLabel = Instance.new("TextLabel", _pagePlayer)
		volLabel.Size = UDim2.fromOffset(55,12) volLabel.Position = UDim2.new(1,-71,0,156)
		volLabel.BackgroundTransparency=1 volLabel.Text="Vol: 50"
		volLabel.TextColor3=CA volLabel.TextSize=9 volLabel.Font=Enum.Font.Gotham
		volLabel.ZIndex=5 volLabel.Visible=false

		-- ═══════════════════════════════════
		-- PÁGINA 2 : BIBLIOTECA (Lista + búsqueda)
		-- ═══════════════════════════════════
		local _pageLibrary = Instance.new("Frame", _content)
		_pageLibrary.Size = UDim2.fromScale(1,1)
		_pageLibrary.BackgroundTransparency = 1
		_pageLibrary.Visible = false

		-- Barra de búsqueda blanca (igual que referencia)
		local _searchWrap = Instance.new("Frame", _pageLibrary)
		_searchWrap.Size = UDim2.new(1,-24,0,38) _searchWrap.Position = UDim2.new(0,12,0,6)
		_searchWrap.BackgroundColor3 = CT _searchWrap.BorderSizePixel = 0
		Instance.new("UICorner",_searchWrap).CornerRadius = UDim.new(0,10)
		local searchBar = _searchWrap

		local _srchIco = Instance.new("ImageLabel",_searchWrap)
		_srchIco.Size=UDim2.fromOffset(16,16) _srchIco.Position=UDim2.new(0,10,0.5,-8)
		_srchIco.BackgroundTransparency=1 _srchIco.Image="rbxassetid://6031154871"
		_srchIco.ImageColor3=Color3.fromRGB(80,80,100) _srchIco.ScaleType=Enum.ScaleType.Fit

		local searchBox = Instance.new("TextBox", _searchWrap)
		searchBox.Size = UDim2.new(1,-32,1,0) searchBox.Position = UDim2.new(0,28,0,0)
		searchBox.BackgroundTransparency = 1 searchBox.Text = ""
		searchBox.PlaceholderText = "Buscar canción..."
		searchBox.PlaceholderColor3 = Color3.fromRGB(140,140,170)
		searchBox.TextColor3 = Color3.fromRGB(20,20,30)
		searchBox.TextSize = 13 searchBox.Font = Enum.Font.Gotham
		searchBox.TextXAlignment = Enum.TextXAlignment.Left
		searchBox.ClearTextOnFocus = false

		-- Lista de canciones (compacta, sin mini-bar ya que es horizontal)
		local songListFrame = Instance.new("ScrollingFrame", _pageLibrary)
		songListFrame.Size = UDim2.new(1,0,1,-100)
		songListFrame.Position = UDim2.new(0,0,0,50)
		songListFrame.BackgroundTransparency = 1 songListFrame.BorderSizePixel = 0
		songListFrame.ScrollBarThickness = 2
		songListFrame.ScrollBarImageColor3 = CA songListFrame.ScrollBarImageTransparency = 0.5
		songListFrame.CanvasSize = UDim2.new(0,0,0,0)
		songListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		songListFrame.ClipsDescendants = true
		local _llayout = Instance.new("UIListLayout",songListFrame)
		_llayout.SortOrder = Enum.SortOrder.LayoutOrder _llayout.Padding = UDim.new(0,1)
		local _lpad = Instance.new("UIPadding",songListFrame)
		_lpad.PaddingLeft=UDim.new(0,0) _lpad.PaddingRight=UDim.new(0,4)

		-- Mini-bar (horizontal compacto en parte inferior)
		local _miniBar = Instance.new("Frame", _pageLibrary)
		_miniBar.Size = UDim2.new(1,-24,0,42) _miniBar.Position = UDim2.new(0,12,1,-48)
		_miniBar.BackgroundColor3 = Color3.fromRGB(36,32,52) _miniBar.BorderSizePixel = 0
		Instance.new("UICorner",_miniBar).CornerRadius = UDim.new(0,10)
		local _mbStroke = Instance.new("UIStroke",_miniBar)
		_mbStroke.Color = Color3.fromRGB(100,60,180) _mbStroke.Thickness = 1 _mbStroke.Transparency = 0.5

		local _mProgBg = Instance.new("Frame",_miniBar)
		_mProgBg.Size=UDim2.new(1,0,0,3) _mProgBg.Position=UDim2.new(0,0,1,-3)
		_mProgBg.BackgroundColor3=Color3.fromRGB(50,36,80) _mProgBg.BorderSizePixel=0
		Instance.new("UICorner",_mProgBg).CornerRadius=UDim.new(0,10)
		local _mProgFill = Instance.new("Frame",_mProgBg)
		_mProgFill.Size=UDim2.fromScale(0,1) _mProgFill.BackgroundColor3=CA
		_mProgFill.BorderSizePixel=0 Instance.new("UICorner",_mProgFill).CornerRadius=UDim.new(1,0)
		local _mProgGrad=Instance.new("UIGradient",_mProgFill)
		_mProgGrad.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(120,30,195)),ColorSequenceKeypoint.new(1,Color3.fromRGB(220,80,255))}

		local _miniTitle = Instance.new("TextLabel",_miniBar)
		_miniTitle.Size=UDim2.new(1,-108,0,16) _miniTitle.Position=UDim2.new(0,10,0,6)
		_miniTitle.BackgroundTransparency=1 _miniTitle.Text="SIN REPRODUCCIÓN"
		_miniTitle.TextColor3=CT _miniTitle.TextSize=11 _miniTitle.Font=Enum.Font.GothamBold
		_miniTitle.TextXAlignment=Enum.TextXAlignment.Left _miniTitle.ClipsDescendants=true

		local _miniGenre = Instance.new("TextLabel",_miniBar)
		_miniGenre.Size=UDim2.new(1,-108,0,11) _miniGenre.Position=UDim2.new(0,10,0,23)
		_miniGenre.BackgroundTransparency=1 _miniGenre.Text="Género"
		_miniGenre.TextColor3=CM
		_miniGenre.TextSize=9 _miniGenre.Font=Enum.Font.Gotham
		_miniGenre.TextXAlignment=Enum.TextXAlignment.Left

		-- mini texto "play for others"
		local _miniPFO = Instance.new("TextLabel",_miniBar)
		_miniPFO.Size=UDim2.fromOffset(120,10) _miniPFO.Position=UDim2.new(0,10,0,32)
		_miniPFO.BackgroundTransparency=1 _miniPFO.Text=""
		_miniPFO.TextColor3=CM _miniPFO.TextSize=8 _miniPFO.Font=Enum.Font.Gotham
		_miniPFO.TextXAlignment=Enum.TextXAlignment.Left _miniPFO.Visible=false

		local _miniHeart = Instance.new("ImageButton",_miniBar)
		_miniHeart.Size=UDim2.fromOffset(20,20) _miniHeart.Position=UDim2.new(1,-80,0.5,-10)
		_miniHeart.BackgroundTransparency=1 _miniHeart.Image="rbxassetid://6023426974"
		_miniHeart.ImageColor3=CM _miniHeart.ScaleType=Enum.ScaleType.Fit _miniHeart.BorderSizePixel=0

		local _miniPause = Instance.new("ImageButton",_miniBar)
		_miniPause.Name="MiniPause"
		_miniPause.Size=UDim2.fromOffset(30,30) _miniPause.Position=UDim2.new(1,-52,0.5,-15)
		_miniPause.BackgroundColor3=Color3.fromRGB(48,36,75)
		_miniPause.Image=ICON_PAUSE _miniPause.ImageColor3=CT
		_miniPause.ScaleType=Enum.ScaleType.Fit _miniPause.BorderSizePixel=0
		_miniPause.AutoButtonColor=false
		Instance.new("UICorner",_miniPause).CornerRadius=UDim.new(1,0)
		local _mpPad=Instance.new("UIPadding",_miniPause)
		_mpPad.PaddingTop=UDim.new(0,6) _mpPad.PaddingBottom=UDim.new(0,6)
		_mpPad.PaddingLeft=UDim.new(0,6) _mpPad.PaddingRight=UDim.new(0,6)

		local _miniNext = Instance.new("ImageButton",_miniBar)
		_miniNext.Size=UDim2.fromOffset(20,20) _miniNext.Position=UDim2.new(1,-18,0.5,-10)
		_miniNext.BackgroundTransparency=1 _miniNext.Image=ICON_NEXT
		_miniNext.ImageColor3=CT _miniNext.ScaleType=Enum.ScaleType.Fit _miniNext.BorderSizePixel=0

		-- ── LÓGICA DE PESTAÑAS – forward declaration (body se define más abajo) ──
		local _switchTab
		-- ── playSongPlayer – forward declaration (definida más abajo, usada en rebuildFavList) ──
		local playSongPlayer

		-- ═══════════════════════════════════
		-- PÁGINA 3 : FAVORITOS (lista funcional)
		-- ═══════════════════════════════════
		local _pageFavs = Instance.new("Frame", _content)
		_pageFavs.Size = UDim2.fromScale(1,1)
		_pageFavs.BackgroundTransparency = 1 _pageFavs.Visible = false

		local _favHdr = Instance.new("TextLabel",_pageFavs)
		_favHdr.Size=UDim2.new(1,-24,0,26) _favHdr.Position=UDim2.new(0,12,0,6)
		_favHdr.BackgroundTransparency=1 _favHdr.Text="♥  Favoritos"
		_favHdr.TextColor3=CT _favHdr.TextSize=14 _favHdr.Font=Enum.Font.GothamBold
		_favHdr.TextXAlignment=Enum.TextXAlignment.Left

		local _favEmpty = Instance.new("TextLabel",_pageFavs)
		_favEmpty.Size=UDim2.new(1,-24,0,28) _favEmpty.Position=UDim2.new(0,12,0.35,-14)
		_favEmpty.BackgroundTransparency=1 _favEmpty.Text="Toca el ♥ en una canción para añadirla"
		_favEmpty.TextColor3=CM _favEmpty.TextSize=10 _favEmpty.Font=Enum.Font.Gotham

		local _favListFrame = Instance.new("ScrollingFrame",_pageFavs)
		_favListFrame.Size=UDim2.new(1,0,1,-40) _favListFrame.Position=UDim2.new(0,0,0,36)
		_favListFrame.BackgroundTransparency=1 _favListFrame.BorderSizePixel=0
		_favListFrame.ScrollBarThickness=2
		_favListFrame.ScrollBarImageColor3=CA _favListFrame.ScrollBarImageTransparency=0.5
		_favListFrame.CanvasSize=UDim2.new(0,0,0,0)
		_favListFrame.AutomaticCanvasSize=Enum.AutomaticSize.Y
		_favListFrame.ClipsDescendants=true
		local _favLayout=Instance.new("UIListLayout",_favListFrame)
		_favLayout.SortOrder=Enum.SortOrder.LayoutOrder _favLayout.Padding=UDim.new(0,1)
		local _favPad=Instance.new("UIPadding",_favListFrame)
		_favPad.PaddingRight=UDim.new(0,4)

		-- ── SISTEMA DE FAVORITOS ──────────────────────────────────────────
		local _favorites = {}    -- tabla {[songId]=true}
		local _favRows   = {}    -- filas en la página favoritos
		local _favFile   = "BladeX/favorites.json"

		-- Cargar favoritos guardados
		pcall(function()
			if isfile(_favFile) then
				local ok, data = pcall(function()
					return game:GetService("HttpService"):JSONDecode(readfile(_favFile))
				end)
				if ok and type(data) == "table" then
					for _, id in ipairs(data) do _favorites[id] = true end
				end
			end
		end)

		local function saveFavorites()
			pcall(function()
				local list = {}
				for id in pairs(_favorites) do table.insert(list, id) end
				writefile(_favFile, game:GetService("HttpService"):JSONEncode(list))
			end)
		end

		local function rebuildFavList()
			-- Limpiar filas anteriores
			for _, r in ipairs(_favRows) do if r and r.Parent then r:Destroy() end end
			_favRows = {}
			-- Buscar canciones favoritas
			local count = 0
			for i, s in ipairs(allSongs) do
				if _favorites[s.id] then
					count = count + 1
					local row = Instance.new("TextButton", _favListFrame)
					row.Size=UDim2.new(1,-10,0,26) row.BackgroundColor3=Color3.fromRGB(26,24,36)
					row.BackgroundTransparency=0 row.BorderSizePixel=0
					row.Text="" row.LayoutOrder=count
					Instance.new("UICorner",row).CornerRadius=UDim.new(0,7)

					local numLbl=Instance.new("TextLabel",row)
					numLbl.Size=UDim2.fromOffset(22,26) numLbl.Position=UDim2.new(0,5,0,0)
					numLbl.BackgroundTransparency=1 numLbl.Text=tostring(count).."."
					numLbl.TextColor3=Color3.fromRGB(120,116,150) numLbl.TextSize=10
					numLbl.Font=Enum.Font.GothamBold

					local nameLbl=Instance.new("TextLabel",row)
					nameLbl.Size=UDim2.new(0.62,-28,1,0) nameLbl.Position=UDim2.new(0,28,0,0)
					nameLbl.BackgroundTransparency=1 nameLbl.Text=s.name
					nameLbl.TextColor3=Color3.fromRGB(225,225,242) nameLbl.TextSize=11
					nameLbl.Font=Enum.Font.GothamBold nameLbl.TextXAlignment=Enum.TextXAlignment.Left
					nameLbl.ClipsDescendants=true

					local genreLbl=Instance.new("TextLabel",row)
					genreLbl.Size=UDim2.new(0.32,-22,1,0) genreLbl.Position=UDim2.new(0.63,0,0,0)
					genreLbl.BackgroundTransparency=1 genreLbl.Text=s.genre
					genreLbl.TextColor3=Color3.fromRGB(110,106,140) genreLbl.TextSize=9
					genreLbl.Font=Enum.Font.Gotham genreLbl.TextXAlignment=Enum.TextXAlignment.Left
					genreLbl.ClipsDescendants=true

					-- Botón quitar de favoritos
					local removeBtn=Instance.new("ImageButton",row)
					removeBtn.Size=UDim2.fromOffset(16,16) removeBtn.Position=UDim2.new(1,-20,0.5,-8)
					removeBtn.BackgroundTransparency=1 removeBtn.Image="rbxassetid://6023426974"
					removeBtn.ImageColor3=CA removeBtn.ScaleType=Enum.ScaleType.Fit removeBtn.BorderSizePixel=0
					removeBtn.MouseButton1Click:Connect(function()
						_favorites[s.id] = nil
						saveFavorites()
						rebuildFavList()
						-- Actualizar corazón en lista principal
						if songRows[i] then
							local hb = songRows[i]:FindFirstChildOfClass("ImageButton")
							if hb then hb.ImageColor3=Color3.fromRGB(100,96,135) end
						end
						-- Actualizar corazón principal
						if _currentList[_currentIdx] and _currentList[_currentIdx].id == s.id then
							_heartTop.ImageColor3 = CM
						end
					end)

					local favSongId = s.id
					row.MouseButton1Click:Connect(function()
						-- Construir lista SOLO de favoritos en el momento del clic
						local favList = {}
						local favIdx  = 1
						for _, song in ipairs(allSongs) do
							if _favorites[song.id] then
								table.insert(favList, song)
								if song.id == favSongId then favIdx = #favList end
							end
						end
						_currentList = favList
						playSongPlayer(favIdx)
						playerFrame.Visible = true
						_switchTab("player")
					end)
					table.insert(_favRows, row)
				end
			end
			_favEmpty.Visible = (count == 0)
		end

		-- Función global para toggle favorito desde cualquier corazón
		local function toggleFavorite(songId, songIdx, heartBtn)
			if _favorites[songId] then
				_favorites[songId] = nil
				if heartBtn then heartBtn.ImageColor3 = Color3.fromRGB(100,96,135) end
			else
				_favorites[songId] = true
				if heartBtn then heartBtn.ImageColor3 = CA end
			end
			saveFavorites()
			rebuildFavList()
		end

		-- Conectar corazón principal (arriba derecha en _pagePlayer)
		_heartTop.MouseButton1Click:Connect(function()
			local s = _currentList[_currentIdx]
			if not s then return end
			toggleFavorite(s.id, _currentIdx, _heartTop)
		end)

		rebuildFavList()

		-- Definir cuerpo de _switchTab ahora que todas las páginas existen
		_switchTab = function(name)
			_pagePlayer.Visible  = (name == "player")
			_pageLibrary.Visible = (name == "library")
			_pageFavs.Visible    = (name == "favs")
			local tabs = {player=_tabPlayer, library=_tabLibrary, favs=_tabFavs}
			for k,tb in pairs(tabs) do
				local on = (k == name)
				tb.Ic.ImageColor3  = on and CA or CM
				tb.Lbl.TextColor3  = on and CA or CM
			end
		end
		-- Conectar los botones de pestañas (aquí _switchTab ya tiene su cuerpo)
		_tabPlayer.MouseButton1Click:Connect(function() _switchTab("player") end)
		_tabLibrary.MouseButton1Click:Connect(function() _switchTab("library") end)
		_tabFavs.MouseButton1Click:Connect(function() _switchTab("favs") end)
		_switchTab("player")

		-- ── BARRA DE PROGRESO DESLIZABLE (seek) ─────────────────────────
		local _seeking = false
		local function _applySeek(pct)
			if _musicSound.TimeLength > 0 then
				_musicSound.TimePosition = pct * _musicSound.TimeLength
				progressFill.Size = UDim2.fromScale(pct, 1)
				updateProgDot(pct)
				timeLeft.Text = formatTime(_musicSound.TimePosition)
			end
		end
		-- Botón invisible encima de la barra para capturar clics y arrastre
		local _seekBtn = Instance.new("TextButton", _progBg)
		_seekBtn.Size = UDim2.new(1, 16, 0, 26)
		_seekBtn.Position = UDim2.new(0, -8, 0.5, -13)
		_seekBtn.BackgroundTransparency = 1
		_seekBtn.Text = "" _seekBtn.ZIndex = 5
		_seekBtn.BorderSizePixel = 0 _seekBtn.AutoButtonColor = false

		local function _calcPct(x)
			local ap = _progBg.AbsolutePosition
			local as = _progBg.AbsoluteSize
			return math.clamp((x - ap.X) / as.X, 0, 1)
		end
		_seekBtn.MouseButton1Down:Connect(function(x, _y)
			_seeking = true
			_applySeek(_calcPct(x))
		end)
		_seekBtn.MouseButton1Up:Connect(function() _seeking = false end)
		_seekBtn.MouseMoved:Connect(function(x, _y)
			if _seeking then _applySeek(_calcPct(x)) end
		end)
		-- Touch (mobile)
		_seekBtn.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.Touch then
				_seeking = true
				_applySeek(_calcPct(inp.Position.X))
			end
		end)
		_seekBtn.InputChanged:Connect(function(inp)
			if _seeking and inp.UserInputType == Enum.UserInputType.Touch then
				_applySeek(_calcPct(inp.Position.X))
			end
		end)
		_seekBtn.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.Touch then
				_seeking = false
			end
		end)

		-- Mini-bar controls
		_miniPause.MouseButton1Click:Connect(function()
			if _isPlaying then
				_musicSound:Pause() _isPlaying=false
				ctrlBtns["PlayPause"].Image=ICON_PLAY _miniPause.Image=ICON_PLAY
			else
				_musicSound:Resume() _isPlaying=true
				ctrlBtns["PlayPause"].Image=ICON_PAUSE _miniPause.Image=ICON_PAUSE
			end
		end)
		_miniNext.MouseButton1Click:Connect(function()
			local n=_currentIdx+1 if n>#_currentList then n=1 end
			playSongPlayer(n)
		end)

		-- Waveform animation
		local _wAngle = 0
		RunService.Heartbeat:Connect(function(dt)
			_wAngle = _wAngle + dt * 3.2
			for wi, bar in ipairs(_waveBars) do
				local base = _wH[wi]
				local anim = _isPlaying and math.abs(math.sin(_wAngle + wi*0.44))*12 or 0
				bar.Size = UDim2.fromOffset(_wBW, math.max(3, base + anim))
			end
		end)

		-- Aliases para que la lógica existente funcione sin cambios
		local songTitle  = _bigTitle
		local genreLabel = _bigGenre

		local function updateProgDot(pct)
			progDot.Position = UDim2.new(math.clamp(pct,0,1),0,0.5,0)
			_mProgFill.Size  = UDim2.fromScale(pct,1)
			_miniTitle.Text  = songTitle.Text
			_miniGenre.Text  = genreLabel.Text
		end

		local function formatTime(secs)
			if not secs or secs ~= secs or secs == math.huge then return "0:00" end
			secs = math.floor(secs)
			return string.format("%d:%02d", math.floor(secs/60), secs%60)
		end

		local function stopProgress()
			if _progressConn then _progressConn:Disconnect() _progressConn = nil end
		end

		local function startProgress()
			stopProgress()
			_progressConn = RunService.Heartbeat:Connect(function()
				if _musicSound.IsPlaying and _musicSound.TimeLength > 0 then
					local pct = math.clamp(_musicSound.TimePosition / _musicSound.TimeLength, 0, 1)
					progressFill.Size = UDim2.fromScale(pct, 1)
					updateProgDot(pct)
					local tPos = formatTime(_musicSound.TimePosition)
					local tLen = formatTime(_musicSound.TimeLength)
					timeLeft.Text  = tPos
					timeRight.Text = tLen
				end
			end)
			_G.BladeXProgressConn = _progressConn
		end

		local songRows = {}

		local function highlightRow(idx)
			for i, row in ipairs(songRows) do
				if row and row.Parent then
					local isActive = (i == idx)
					row.BackgroundColor3 = isActive and CA or Color3.fromRGB(26,24,36)
					row.BackgroundTransparency = isActive and 0.25 or 0
					local numLbl = row:FindFirstChild("Num")
					local nameLbl = row:FindFirstChild("SongName")
					if numLbl then numLbl.TextColor3 = isActive and Color3.fromRGB(255,255,255) or Color3.fromRGB(120,116,150) end
					if nameLbl then nameLbl.TextColor3 = isActive and Color3.fromRGB(255,255,255) or Color3.fromRGB(225,225,242) end
				end
			end
		end

		-- Fix 2.4: checkSoundValid mejorado — usa temporizador y verifica TimeLength tras breve espera
		local function checkSoundValid(soundId, callback)
			task.spawn(function()
				local testSound = Instance.new("Sound")
				testSound.SoundId = soundId
				testSound.Volume = 0
				testSound.Parent = game:GetService("SoundService")
				local ok = false
				local loaded = false
				local conn
				conn = testSound.Loaded:Connect(function()
					loaded = true
					ok = testSound.TimeLength > 0
					conn:Disconnect()
				end)
				testSound:Play()
				-- Esperar hasta 4s para que cargue; verificar TimeLength también por si Loaded no dispara
				local t = 0
				repeat
					task.wait(0.1)
					t = t + 0.1
					if not loaded and testSound.TimeLength > 0 then
						ok = true
						loaded = true
					end
				until t >= 2 or loaded
				pcall(function() conn:Disconnect() end)
				testSound:Stop()
				testSound:Destroy()
				callback(ok)
			end)
		end

		playSongPlayer = function(index)
			if #_currentList == 0 then return end
			index = math.clamp(index, 1, #_currentList)
			_currentIdx = index
			local s = _currentList[index]
			-- Fix 2.4: Sound.Looped siempre false — el loop se gestiona en el evento Ended
			_musicSound.Looped = false
			_musicSound.SoundId = s.id
			_musicSound:Stop()
			_musicSound:Play()
			_isPlaying = true
			ctrlBtns["PlayPause"].Image = ICON_PAUSE  -- era .Text = "II" (bug: ImageButton no tiene .Text)
			ctrlBtns["PlayPause"].BackgroundColor3 = Color3.fromRGB(35,35,50)
			songTitle.Text  = s.name
			genreLabel.Text = s.genre
			_miniTitle.Text = s.name
			_miniGenre.Text = s.genre
			_miniPause.Image = ICON_PAUSE
			-- Actualizar corazón principal según favoritos
			if _favorites then
				_heartTop.ImageColor3 = _favorites[s.id] and CA or CM
			end
			highlightRow(index)
			statusBadge.Text = "● CHECK"
			statusBadge.BackgroundColor3 = Color3.fromRGB(180,140,20)
			checkSoundValid(s.id, function(valid)
				if valid then
					statusBadge.Text = "● VALID"
					statusBadge.BackgroundColor3 = Color3.fromRGB(50,180,80)
				else
					statusBadge.Text = "● INVALID"
					statusBadge.BackgroundColor3 = Color3.fromRGB(200,50,50)
					task.wait(1.5)
					local nxt = _currentIdx + 1
					if nxt > #_currentList then nxt = 1 end
					playSongPlayer(nxt)
				end
			end)
			startProgress()
			Luna:Notification({ Title="BladeX Music", Content=s.name, Icon="perm_media", ImageSource="Material", Duration=1 })
		end

		-- Fix 2.4: Ended siempre dispara (Looped=false). Si _isLoop=true, repetir la misma canción.
		_musicSound.Ended:Connect(function()
			if not _isPlaying then return end
			if _isLoop then
				-- Repetir la misma canción
				playSongPlayer(_currentIdx)
			elseif _isShuffle then
				playSongPlayer(math.random(1, #_currentList))
			else
				local n = _currentIdx + 1
				if n > #_currentList then
					_isPlaying = false
					ctrlBtns["PlayPause"].Image = ICON_PLAY
					stopProgress()
					return
				end
				playSongPlayer(n)
			end
		end)

		ctrlBtns["PlayPause"].MouseButton1Click:Connect(function()
			if _isPlaying then _musicSound:Pause() _isPlaying=false ctrlBtns["PlayPause"].Image = ICON_PLAY stopProgress()
			else _musicSound:Resume() _isPlaying=true ctrlBtns["PlayPause"].Image = ICON_PAUSE startProgress() end
		end)
		ctrlBtns["Prev"].MouseButton1Click:Connect(function()
			local p=_currentIdx-1 if p<1 then p=#_currentList end playSongPlayer(p)
		end)
		ctrlBtns["Next"].MouseButton1Click:Connect(function()
			local n=_currentIdx+1 if n>#_currentList then n=1 end playSongPlayer(n)
		end)
		ctrlBtns["Shuffle"].MouseButton1Click:Connect(function()
			_isShuffle = not _isShuffle
			ctrlBtns["Shuffle"].ImageColor3 = _isShuffle and CA or CM
		end)
		ctrlBtns["Loop"].MouseButton1Click:Connect(function()
			_isLoop = not _isLoop
			-- Fix 2.4: Sound.Looped permanece false; _isLoop controla la lógica en Ended
			ctrlBtns["Loop"].ImageColor3 = _isLoop and CA or CM
		end)
		closeBtn.MouseButton1Click:Connect(function()
			playerFrame.Visible = false
			if _toggleMostrarReproductor and _toggleMostrarReproductor.Set then
				pcall(function() _toggleMostrarReproductor:Set(false) end)
			end
			if _isPlaying then
				_musicSound:Pause()
				_isPlaying = false
				ctrlBtns["PlayPause"].Image = ICON_PLAY
				_miniPause.Image = ICON_PLAY
				stopProgress()
			end
		end)

		local function buildSongList(list)
			for _, r in ipairs(songRows) do if r and r.Parent then r:Destroy() end end
			songRows = {}
			for i, s in ipairs(list) do
				local row = Instance.new("TextButton", songListFrame)
				row.Name              = "Row"..i
				row.Size              = UDim2.new(1, -10, 0, 26)
				row.BackgroundColor3  = Color3.fromRGB(26, 24, 36)
				row.BackgroundTransparency = 0
				row.BorderSizePixel   = 0
				row.Text              = ""
				row.LayoutOrder       = i
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

				local numLbl = Instance.new("TextLabel", row)
				numLbl.Name = "Num"
				numLbl.Size = UDim2.fromOffset(24, 26)
				numLbl.Position = UDim2.new(0, 5, 0, 0)
				numLbl.BackgroundTransparency = 1
				numLbl.Text = tostring(i) .. "."
				numLbl.TextColor3 = Color3.fromRGB(120, 116, 150)
				numLbl.TextSize = 10
				numLbl.Font = Enum.Font.GothamBold

				local nameLbl = Instance.new("TextLabel", row)
				nameLbl.Name = "SongName"
				nameLbl.Size = UDim2.new(0.55, -30, 1, 0)
				nameLbl.Position = UDim2.new(0, 30, 0, 0)
				nameLbl.BackgroundTransparency = 1
				nameLbl.Text = s.name
				nameLbl.TextColor3 = Color3.fromRGB(225, 225, 242)
				nameLbl.TextSize = 11
				nameLbl.Font = Enum.Font.GothamBold
				nameLbl.TextXAlignment = Enum.TextXAlignment.Left
				nameLbl.ClipsDescendants = true

				-- Genre inline (right side)
				local genreLbl = Instance.new("TextLabel", row)
				genreLbl.Size = UDim2.new(0.4, -22, 1, 0)
				genreLbl.Position = UDim2.new(0.56, 0, 0, 0)
				genreLbl.BackgroundTransparency = 1
				genreLbl.Text = s.genre
				genreLbl.TextColor3 = Color3.fromRGB(110, 106, 140)
				genreLbl.TextSize = 9
				genreLbl.Font = Enum.Font.Gotham
				genreLbl.TextXAlignment = Enum.TextXAlignment.Left
				genreLbl.ClipsDescendants = true

				local heartBtn = Instance.new("ImageButton", row)
				heartBtn.Size = UDim2.fromOffset(16, 16)
				heartBtn.Position = UDim2.new(1, -20, 0.5, -8)
				heartBtn.BackgroundTransparency = 1
				heartBtn.Image = "rbxassetid://6023426974"
				heartBtn.ImageColor3 = (_favorites and _favorites[s.id]) and CA or Color3.fromRGB(100, 96, 135)
				heartBtn.ScaleType = Enum.ScaleType.Fit
				heartBtn.BorderSizePixel = 0
				heartBtn.MouseButton1Click:Connect(function()
					toggleFavorite(s.id, i, heartBtn)
					-- actualizar corazón principal si es la canción actual
					if _currentList[_currentIdx] and _currentList[_currentIdx].id == s.id then
						_heartTop.ImageColor3 = _favorites[s.id] and CA or CM
					end
				end)

				local ci = i
				row.MouseButton1Click:Connect(function()
					_currentList = allSongs
					playSongPlayer(ci)
					playerFrame.Visible = true
					_switchTab("player")
				end)
				songRows[i] = row
			end
		end
		buildSongList(allSongs)

		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			local q = searchBox.Text:lower()
			for i, row in ipairs(songRows) do
				if row and row.Parent then
					row.Visible = (q=="" or allSongs[i].name:lower():find(q,1,true)~=nil)
				end
			end
		end)

		Tabs.Music:CreateSection("Reproductor Visual")
		local _toggleMostrarReproductor = Tabs.Music:CreateToggle({
			Name    = "Mostrar Reproductor",
			Description = "Muestra u oculta el mini-reproductor en pantalla",
			CurrentValue = false,
			Callback = function(v)
				playerFrame.Visible = v
			end
		})

		Tabs.Music:CreateSlider({
			Name = "Volumen", Description = "Ajusta el volumen (0 - 100)",
			Range = {0,100}, Increment = 5, CurrentValue = 50,
			Callback = function(v)
				_musicSound.Volume = v/100
				volLabel.Text = "Vol: "..v
			end
		})

		-- ── Canción personalizada por ID ──────────────────────────────────────
		Tabs.Music:CreateSection("🎵 Canción Personalizada")

		local _lastCustomID = ""

		local function _playCustomID(Value)
			if not Value or Value == "" then
				Luna:Notification({Title="Música", Content="No hay ningún ID. Copia el ID primero.", Icon="info", ImageSource="Material", Duration=3})
				return
			end
			local numID = tostring(Value):match("%d+")
			if not numID then
				Luna:Notification({Title="Música", Content="ID inválido. Solo números.", Icon="dangerous", ImageSource="Material", Duration=3})
				return
			end
			local newSong = { name = "Custom - "..numID, id = "rbxassetid://"..numID, genre = "Custom" }
			table.insert(allSongs, newSong)
			buildSongList(allSongs)
			_currentList = allSongs
			_currentIdx  = #allSongs
			playSongPlayer(_currentIdx)
			playerFrame.Visible = true
			Luna:Notification({Title="Música", Content="Reproduciendo ID "..numID.."...", Icon="music_note", ImageSource="Material", Duration=3})
		end

		-- Botón 1: Pegar desde portapapeles (ideal para móvil)
		Tabs.Music:CreateButton({
			Name = "📋  Pegar ID del portapapeles",
			Description = "Copia el ID numérico y toca aquí para pegarlo",
			Callback = function()
				local ok, clipboard = pcall(getclipboard)
				if not ok or not clipboard or clipboard == "" then
					Luna:Notification({Title="Música", Content="Portapapeles vacío. Copia un ID primero.", Icon="info", ImageSource="Material", Duration=3})
					return
				end
				_lastCustomID = clipboard
				local numID = tostring(clipboard):match("%d+")
				if numID then
					Luna:Notification({Title="Música", Content="ID pegado: "..numID..". Toca Reproducir.", Icon="content_paste", ImageSource="Material", Duration=3})
				else
					Luna:Notification({Title="Música", Content="El portapapeles no tiene un ID válido.", Icon="dangerous", ImageSource="Material", Duration=3})
				end
			end
		})

		-- Botón 2: Reproducir el ID pegado
		Tabs.Music:CreateButton({
			Name = "▶  Reproducir ID pegado",
			Description = "Toca después de pegar el ID",
			Callback = function()
				-- Intentar leer portapapeles directo por si no pegaron antes
				local val = _lastCustomID
				if val == "" then
					local ok, cb = pcall(getclipboard)
					if ok and cb and cb ~= "" then val = cb end
				end
				_playCustomID(val)
			end
		})

		task.defer(function() _loaded = true end)
	end




	-- ================================================================
	--   AIMBOT (RIVALS / KOVARI STYLE)
	-- ================================================================

	-- Variables
	local _aimbotEnabled    = _cfg.aimbotEnabled    or false
	local _aimbotFOV        = _cfg.aimbotFOV        or 100
	local _aimbotSmooth     = _cfg.aimbotSmooth     or 14
	local _aimbotPredMS     = _cfg.aimbotPredMS     or 120
	local _aimbotWallCheck  = _cfg.aimbotWallCheck  ~= false
	local _aimbotPrediction = _cfg.aimbotPrediction ~= false
	local _aimbotTarget     = _cfg.aimbotTarget     or "UpperTorso"
	local _aimbotShowFOV    = _cfg.aimbotShowFOV    ~= false
	local _aimbotTeamCheck  = _cfg.aimbotTeamCheck  ~= false  -- SIEMPRE ignora compañeros por defecto
	local _aimbotConn       = nil

	-- Auto-Fire
	local _autoFireEnabled  = _cfg.autoFireEnabled  or false
	local _autoFireRate     = _cfg.autoFireRate     or 0.12   -- segundos entre disparos (0.08~0.20 = legit)
	local _autoFireConn     = nil
	local _autoLastFire     = 0

	local _silentEnabled    = _cfg.silentEnabled    or false
	local _silentFOV        = _cfg.silentFOV        or 120
	local _silentPredMS     = _cfg.silentPredMS     or 120
	local _silentHitChance  = _cfg.silentHitChance  or 100
	local _silentWallCheck  = _cfg.silentWallCheck  ~= false
	local _silentPrediction = _cfg.silentPrediction ~= false
	local _silentShowTarget = _cfg.silentShowTarget ~= false
	local _silentTarget     = _cfg.silentTarget     or "Head"
	local _silentConn       = nil
	local _origIndexMouse   = nil

	local _humanizerStr  = _cfg.humanizerStr  or 50
	local _randomDelay   = _cfg.randomDelay   ~= false
	local _delayMS       = _cfg.delayMS       or 12
	local _curveAim      = _cfg.curveAim      ~= false
	local _curveStrength = _cfg.curveStrength or 12
	local _maxSpeed      = _cfg.maxSpeed      or 320
	local _jitter        = _cfg.jitter        or 2
	local _distScaling   = _cfg.distScaling   ~= false
	local _velSmoothing  = _cfg.velSmoothing  ~= false
	local _adaptivePred  = _cfg.adaptivePred  ~= false
	local _angleComp     = _cfg.angleComp     ~= false
	local _smoothEntry   = _cfg.smoothEntry   ~= false
	local _entrySmooth   = _cfg.entrySmooth   or 40

	local _espBoxEnabled  = _cfg.espBoxEnabled  or false
	local _espBoxes       = _cfg.espBoxes       ~= false
	local _espTracers     = _cfg.espTracers     ~= false
	local _espNames       = _cfg.espNames       ~= false
	local _espHealth      = _cfg.espHealth      ~= false
	local _espDistV       = _cfg.espDistV       ~= false
	local _espMaxDistV    = _cfg.espMaxDistV    or 1500
	local _espBoxDrawings = {}
	local _espBoxConn     = nil

	-- FOV Circle
	local _fovCircle = nil
	pcall(function()
		_fovCircle = Drawing.new("Circle")
		_fovCircle.Visible   = false
		_fovCircle.Thickness = 1.5
		_fovCircle.Color     = Color3.fromRGB(180, 80, 255)
		_fovCircle.Filled    = false
		_fovCircle.NumSides  = 64
		_fovCircle.Radius    = _aimbotFOV
		local vp = game:GetService("Workspace").CurrentCamera.ViewportSize
		_fovCircle.Position = Vector2.new(vp.X/2, vp.Y/2)
	end)

	game:GetService("RunService").RenderStepped:Connect(function()
		if not _fovCircle then return end
		if (_aimbotEnabled or _silentEnabled) and _aimbotShowFOV then
			_fovCircle.Visible  = true
			_fovCircle.Radius   = _aimbotEnabled and _aimbotFOV or _silentFOV
			local vp = game:GetService("Workspace").CurrentCamera.ViewportSize
			_fovCircle.Position = Vector2.new(vp.X/2, vp.Y/2)
		else
			_fovCircle.Visible = false
		end
	end)

	-- ── Helper: detectar si un jugador es compañero ──────────────────
	-- Rivals usa equipos nativos de Roblox (Teams). También detecta
	-- sistemas custom buscando valores "Team" en el personaje.
	local function _isTeammate(p)
		-- 1. Equipo nativo de Roblox
		pcall(function()
			if Player.Team and p.Team and Player.Team == p.Team then
				return true
			end
		end)
		if Player.Team and p.Team and Player.Team == p.Team then return true end
		-- 2. Búsqueda por valores "Team" / "TeamColor" en el personaje (juegos custom)
		if p.Character then
			local tv = p.Character:FindFirstChild("Team") or p.Character:FindFirstChild("TeamColor")
			local lv = Player.Character and (Player.Character:FindFirstChild("Team") or Player.Character:FindFirstChild("TeamColor"))
			if tv and lv and tostring(tv.Value) == tostring(lv.Value) then return true end
		end
		-- 3. Fallback: mismo color de equipo nativo
		if Player.TeamColor and p.TeamColor and Player.TeamColor == p.TeamColor then return true end
		return false
	end

	-- Helper: mejor objetivo (con team check)
	local function _getBestTarget(fov, target, wallCheck, teamCheck)
		local cam    = game:GetService("Workspace").CurrentCamera
		local center = cam.ViewportSize / 2
		local best, bestDist = nil, math.huge
		for _, p in ipairs(Players:GetPlayers()) do
			if p == Player or not p.Character then continue end
			-- ── Team Check ── ignora compañeros si está activado
			if teamCheck and _isTeammate(p) then continue end
			local hum = p.Character:FindFirstChild("Humanoid")
			if not hum or hum.Health <= 0 then continue end
			local part = p.Character:FindFirstChild(target) or p.Character:FindFirstChild("HumanoidRootPart")
			if not part then continue end
			if wallCheck then
				local origin = cam.CFrame.Position
				local dir    = (part.Position - origin).Unit * 2000
				local ray    = Ray.new(origin, dir)
				local hit    = game:GetService("Workspace"):FindPartOnRayWithIgnoreList(
					ray, {Player.Character, game:GetService("Workspace").Terrain}
				)
				-- Si el rayo golpeó algo que NO es parte del personaje enemigo → skip
				if hit and not hit:IsDescendantOf(p.Character) then continue end
			end
			local sp, onScreen = cam:WorldToViewportPoint(part.Position)
			if not onScreen then continue end
			local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
			if dist < fov and dist < bestDist then
				best, bestDist = part, dist
			end
		end
		return best
	end

	-- Aimbot loop
	local function _startAimbot()
		if _aimbotConn then pcall(function() _aimbotConn:Disconnect() end) end
		_aimbotConn = game:GetService("RunService").RenderStepped:Connect(function()
			if not _aimbotEnabled then return end
			local target = _getBestTarget(_aimbotFOV, _aimbotTarget, _aimbotWallCheck, _aimbotTeamCheck)
			if not target then return end
			local predOffset = Vector3.new()
			if _aimbotPrediction then
				local vel = target.Velocity or Vector3.new()
				local hum = _humanizerStr / 100
				local spd = math.min(vel.Magnitude, _maxSpeed)
				predOffset = vel.Unit * spd * (_aimbotPredMS / 1000) * (1 - hum * 0.5)
				if _distScaling then
					local d = (target.Position - game:GetService("Workspace").CurrentCamera.CFrame.Position).Magnitude
					predOffset = predOffset * math.clamp(d / 500, 0.5, 2)
				end
			end
			local aimPos = target.Position + predOffset
			if _curveAim then
				local cs = _curveStrength / 100
				aimPos = aimPos + Vector3.new(math.sin(tick()*3)*cs, math.cos(tick()*2)*cs*0.5, 0)
			end
			local cam = game:GetService("Workspace").CurrentCamera
			local smooth = math.clamp((_aimbotSmooth / 100) + (_humanizerStr / 200), 0.05, 0.98)
			if _smoothEntry then smooth = smooth + (_entrySmooth / 1000) end
			local delay = _randomDelay and (_delayMS + math.random(-3,3)) or _delayMS
			if delay > 0 then task.wait(delay/1000) end
			local targetCF = CFrame.new(cam.CFrame.Position, aimPos)
			cam.CFrame = cam.CFrame:Lerp(targetCF, 1 - smooth)
			if _jitter > 0 then
				local j = _jitter / 10
				cam.CFrame = cam.CFrame * CFrame.Angles(
					math.rad(math.random(-j*10, j*10)/10),
					math.rad(math.random(-j*10, j*10)/10), 0)
			end
		end)
	end

	-- ── AutoFire (Rivals / FPS Roblox) ───────────────────────────────
	-- Simula clics del mouse automáticamente mientras haya un enemigo
	-- dentro del FOV. Compatible con Rivals, Arsenal, Phantom Forces, etc.
	-- Usa mouse1click (método nativo de executors) para máxima compatibilidad.
	local function _startAutoFire()
		if _autoFireConn then pcall(function() _autoFireConn:Disconnect() end) end
		_autoLastFire = 0
		_autoFireConn = game:GetService("RunService").Heartbeat:Connect(function()
			if not _autoFireEnabled then return end
			local now = tick()
			if now - _autoLastFire < _autoFireRate then return end
			-- Solo dispara si hay un objetivo válido dentro del FOV
			local t = _getBestTarget(_aimbotFOV, _aimbotTarget, _aimbotWallCheck, _aimbotTeamCheck)
			if not t then return end
			_autoLastFire = now
			-- Intentar múltiples métodos de click (compatibilidad entre executors)
			pcall(function() mouse1click() end)
			if not pcall(function() mouse1click() end) then
				pcall(function()
					local VIM = game:GetService("VirtualInputManager")
					VIM:SendMouseButtonEvent(0, 0, 0, true,  game, 1)
					task.wait(0.015)
					VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
				end)
			end
		end)
	end

	local function _stopAutoFire()
		if _autoFireConn then
			pcall(function() _autoFireConn:Disconnect() end)
			_autoFireConn = nil
		end
	end

	-- Silent Aim
	local function _enableSilentAim()
		if _silentConn then pcall(function() _silentConn:Disconnect() end) _silentConn=nil end
		_origIndexMouse = _origIndexMouse or nil
		pcall(function()
			local mt = getrawmetatable(game)
			local oldIndex = mt.__index
			_origIndexMouse = oldIndex
			local chance = _silentHitChance / 100
			setreadonly(mt, false)
			mt.__index = newcclosure(function(self, k)
				if k == "Hit" and tostring(self):find("Mouse") then
					if math.random() <= chance then
						local t2 = _getBestTarget(_silentFOV, _silentTarget, _silentWallCheck, _aimbotTeamCheck)
						if t2 then
							local predOff = Vector3.new()
							if _silentPrediction then
								predOff = (t2.Velocity or Vector3.new()) * (_silentPredMS / 1000)
							end
							return CFrame.new(t2.Position + predOff)
						end
					end
				end
				return oldIndex(self, k)
			end)
			setreadonly(mt, true)
		end)
	end

	local function _disableSilentAim()
		if not _origIndexMouse then return end
		pcall(function()
			local mt = getrawmetatable(game)
			setreadonly(mt, false)
			mt.__index = _origIndexMouse
			setreadonly(mt, true)
		end)
		_origIndexMouse = nil
	end

	-- ESP Box Drawing
	local function _clearEspBoxDrawings()
		for _, d in pairs(_espBoxDrawings) do
			for _, obj in pairs(d) do pcall(function() obj:Remove() end) end
		end
		_espBoxDrawings = {}
	end

	local function _startEspBox()
		if _espBoxConn then pcall(function() _espBoxConn:Disconnect() end) end
		_clearEspBoxDrawings()
		_espBoxConn = game:GetService("RunService").RenderStepped:Connect(function()
			if not _espBoxEnabled then _clearEspBoxDrawings() return end
			local cam = game:GetService("Workspace").CurrentCamera
			local alive = {}
			for _, p in ipairs(Players:GetPlayers()) do
				if p == Player or not p.Character then continue end
				local hum = p.Character:FindFirstChild("Humanoid")
				if not hum or hum.Health <= 0 then continue end
				local root = p.Character:FindFirstChild("HumanoidRootPart")
				if not root then continue end
				local dist = (root.Position - cam.CFrame.Position).Magnitude
				if dist > _espMaxDistV then continue end
				alive[p.UserId] = true
				if not _espBoxDrawings[p.UserId] then
					local d = {}
					if _espBoxes   then d.box=Drawing.new("Square"); d.box.Color=Color3.fromRGB(255,50,50); d.box.Thickness=1.5; d.box.Filled=false; d.box.Visible=true end
					if _espTracers then d.tracer=Drawing.new("Line"); d.tracer.Color=Color3.fromRGB(255,50,50); d.tracer.Thickness=1; d.tracer.Visible=true end
					if _espNames   then d.name=Drawing.new("Text"); d.name.Color=Color3.new(1,1,1); d.name.Size=13; d.name.Center=true; d.name.Outline=true; d.name.Visible=true end
					if _espHealth  then d.health=Drawing.new("Text"); d.health.Color=Color3.fromRGB(80,255,80); d.health.Size=11; d.health.Center=true; d.health.Outline=true; d.health.Visible=true end
					if _espDistV   then d.distLbl=Drawing.new("Text"); d.distLbl.Color=Color3.fromRGB(255,220,50); d.distLbl.Size=11; d.distLbl.Center=true; d.distLbl.Outline=true; d.distLbl.Visible=true end
					_espBoxDrawings[p.UserId] = d
				end
				local head = p.Character:FindFirstChild("Head")
				local feet = p.Character:FindFirstChild("HumanoidRootPart")
				if not head or not feet then continue end
				local topSP, topOn   = cam:WorldToViewportPoint(head.Position + Vector3.new(0,0.7,0))
				local botSP          = cam:WorldToViewportPoint(feet.Position - Vector3.new(0,2.5,0))
				local rootSP         = cam:WorldToViewportPoint(root.Position)
				if not topOn then continue end
				local h2 = math.abs(topSP.Y - botSP.Y); local w2 = h2 * 0.55
				local d = _espBoxDrawings[p.UserId]
				if d.box    then d.box.Size=Vector2.new(w2,h2); d.box.Position=Vector2.new(rootSP.X-w2/2,topSP.Y) end
				if d.tracer then local vp=cam.ViewportSize; d.tracer.From=Vector2.new(vp.X/2,vp.Y); d.tracer.To=Vector2.new(rootSP.X,rootSP.Y) end
				if d.name   then d.name.Text=p.Name; d.name.Position=Vector2.new(rootSP.X,topSP.Y-15) end
				if d.health then d.health.Text=math.floor(hum.Health).."HP"; d.health.Position=Vector2.new(rootSP.X,botSP.Y+2) end
				if d.distLbl then d.distLbl.Text=math.floor(dist).."m"; d.distLbl.Position=Vector2.new(rootSP.X,botSP.Y+14) end
			end
			for uid in pairs(_espBoxDrawings) do
				if not alive[uid] then
					for _, obj in pairs(_espBoxDrawings[uid]) do pcall(function() obj:Remove() end) end
					_espBoxDrawings[uid] = nil
				end
			end
		end)
	end

	-- Preset helper
	local function _applyPreset(p)
		_aimbotEnabled=p.ae; _aimbotFOV=p.af; _aimbotSmooth=p.as; _aimbotPredMS=p.ap
		_aimbotWallCheck=p.aw; _aimbotPrediction=p.apr; _aimbotTarget=p.at; _aimbotShowFOV=true
		_silentEnabled=p.se; _silentFOV=p.sf; _silentPredMS=p.sp; _silentHitChance=p.sh
		_silentWallCheck=p.sw; _silentPrediction=p.spr; _silentTarget=p.st
		_humanizerStr=p.hum; _randomDelay=p.rd; _delayMS=p.dm; _curveAim=p.ca
		_curveStrength=p.cs; _maxSpeed=p.ms; _jitter=p.ji
		_distScaling=p.ds; _velSmoothing=p.vs; _adaptivePred=p.adp; _angleComp=p.ac
		_smoothEntry=p.sme; _entrySmooth=p.es
		_cfg.aimbotEnabled=p.ae; _cfg.aimbotFOV=p.af; _cfg.aimbotSmooth=p.as; _cfg.aimbotPredMS=p.ap
		_cfg.aimbotWallCheck=p.aw; _cfg.aimbotTarget=p.at
		_cfg.silentEnabled=p.se; _cfg.silentFOV=p.sf; _cfg.silentPredMS=p.sp
		_cfg.silentHitChance=p.sh; _cfg.silentTarget=p.st
		_cfg.humanizerStr=p.hum; _cfg.randomDelay=p.rd; _cfg.delayMS=p.dm
		_cfg.curveAim=p.ca; _cfg.curveStrength=p.cs; _cfg.maxSpeed=p.ms
		_cfg.jitter=p.ji; _cfg.distScaling=p.ds; _cfg.velSmoothing=p.vs
		_cfg.adaptivePred=p.adp; _cfg.angleComp=p.ac; _cfg.smoothEntry=p.sme; _cfg.entrySmooth=p.es
		_saveCfg()
		if p.ae then _startAimbot() elseif _aimbotConn then pcall(function() _aimbotConn:Disconnect() end) _aimbotConn=nil end
		if p.se then _enableSilentAim() else _disableSilentAim() end
	end

	-- ================================================================
	--   UI — AIMBOT TAB
	-- ================================================================
	Tabs.Aimbot:CreateSection("Aimbot")
	Tabs.Aimbot:CreateToggle({ Name="Enabled", CurrentValue=_aimbotEnabled,
		Callback=function(v) _aimbotEnabled=v; _cfg.aimbotEnabled=v; _saveCfg()
			if v then _startAimbot() elseif _aimbotConn then pcall(function() _aimbotConn:Disconnect() end) _aimbotConn=nil end
		end })
	Tabs.Aimbot:CreateToggle({ Name="Show FOV", CurrentValue=_aimbotShowFOV,
		Callback=function(v) _aimbotShowFOV=v; _cfg.aimbotShowFOV=v; _saveCfg() end })
	Tabs.Aimbot:CreateToggle({ Name="Wall Check", CurrentValue=_aimbotWallCheck,
		Callback=function(v) _aimbotWallCheck=v; _cfg.aimbotWallCheck=v; _saveCfg() end })
	Tabs.Aimbot:CreateToggle({ Name="Team Check", CurrentValue=_aimbotTeamCheck,
		Callback=function(v) _aimbotTeamCheck=v; _cfg.aimbotTeamCheck=v; _saveCfg() end })
	Tabs.Aimbot:CreateToggle({ Name="Prediction", CurrentValue=_aimbotPrediction,
		Callback=function(v) _aimbotPrediction=v; _cfg.aimbotPrediction=v; _saveCfg() end })
	Tabs.Aimbot:CreateSlider({ Name="FOV", Range={10,400}, Increment=5, CurrentValue=_aimbotFOV,
		Callback=function(v) _aimbotFOV=v; _cfg.aimbotFOV=v; _saveCfg()
			if _fovCircle then _fovCircle.Radius=v end end })
	Tabs.Aimbot:CreateSlider({ Name="Smoothness", Range={1,100}, Increment=1, CurrentValue=_aimbotSmooth,
		Callback=function(v) _aimbotSmooth=v; _cfg.aimbotSmooth=v; _saveCfg() end })
	Tabs.Aimbot:CreateSlider({ Name="Prediction (ms)", Range={0,300}, Increment=5, CurrentValue=_aimbotPredMS,
		Callback=function(v) _aimbotPredMS=v; _cfg.aimbotPredMS=v; _saveCfg() end })
	Tabs.Aimbot:CreateDropdown({ Name="Target", Options={"Head","UpperTorso","HumanoidRootPart"}, CurrentOption={_aimbotTarget},
		Callback=function(v) _aimbotTarget=v[1] or v; _cfg.aimbotTarget=_aimbotTarget; _saveCfg() end })

	-- ── AutoFire ──────────────────────────────────────────────────────
	Tabs.Aimbot:CreateSection("Auto Fire")
	Tabs.Aimbot:CreateToggle({
		Name="Enabled",
		Description="Dispara automáticamente cuando hay un enemigo en el FOV. Compatible con Rivals, Arsenal, etc.",
		CurrentValue=_autoFireEnabled,
		Callback=function(v)
			_autoFireEnabled=v; _cfg.autoFireEnabled=v; _saveCfg()
			if v then _startAutoFire() else _stopAutoFire() end
		end
	})
	Tabs.Aimbot:CreateSlider({
		Name="Fire Rate (seg)", Description="Tiempo entre disparos. 0.08 = muy rápido / 0.20 = más legit.",
		Range={0.05, 0.50}, Increment=0.01, CurrentValue=_autoFireRate,
		Callback=function(v) _autoFireRate=v; _cfg.autoFireRate=v; _saveCfg() end
	})

	Tabs.Aimbot:CreateSection("Silent Aim")
	Tabs.Aimbot:CreateToggle({ Name="Enabled", CurrentValue=_silentEnabled,
		Callback=function(v) _silentEnabled=v; _cfg.silentEnabled=v; _saveCfg()
			if v then _enableSilentAim() else _disableSilentAim() end end })
	Tabs.Aimbot:CreateToggle({ Name="Show FOV", CurrentValue=_aimbotShowFOV,
		Callback=function(v) _aimbotShowFOV=v; _cfg.aimbotShowFOV=v; _saveCfg() end })
	Tabs.Aimbot:CreateToggle({ Name="Wall Check", CurrentValue=_silentWallCheck,
		Callback=function(v) _silentWallCheck=v; _cfg.silentWallCheck=v; _saveCfg() end })
	Tabs.Aimbot:CreateToggle({ Name="Prediction", CurrentValue=_silentPrediction,
		Callback=function(v) _silentPrediction=v; _cfg.silentPrediction=v; _saveCfg() end })
	Tabs.Aimbot:CreateToggle({ Name="Show Target", CurrentValue=_silentShowTarget,
		Callback=function(v) _silentShowTarget=v; _cfg.silentShowTarget=v; _saveCfg() end })
	Tabs.Aimbot:CreateSlider({ Name="FOV", Range={10,400}, Increment=5, CurrentValue=_silentFOV,
		Callback=function(v) _silentFOV=v; _cfg.silentFOV=v; _saveCfg() end })
	Tabs.Aimbot:CreateSlider({ Name="Prediction (ms)", Range={0,300}, Increment=5, CurrentValue=_silentPredMS,
		Callback=function(v) _silentPredMS=v; _cfg.silentPredMS=v; _saveCfg() end })
	Tabs.Aimbot:CreateSlider({ Name="Hit Chance", Range={1,100}, Increment=1, CurrentValue=_silentHitChance,
		Callback=function(v) _silentHitChance=v; _cfg.silentHitChance=v; _saveCfg() end })
	Tabs.Aimbot:CreateDropdown({ Name="Target", Options={"Head","UpperTorso","HumanoidRootPart"}, CurrentOption={_silentTarget},
		Callback=function(v) _silentTarget=v[1] or v; _cfg.silentTarget=_silentTarget; _saveCfg() end })

	Tabs.Aimbot:CreateSection("ESP")
	Tabs.Aimbot:CreateToggle({ Name="Enabled", CurrentValue=_espBoxEnabled,
		Callback=function(v) _espBoxEnabled=v; _cfg.espBoxEnabled=v; _saveCfg()
			if v then _startEspBox() else _clearEspBoxDrawings()
				if _espBoxConn then pcall(function() _espBoxConn:Disconnect() end) _espBoxConn=nil end end end })
	Tabs.Aimbot:CreateToggle({ Name="Boxes", CurrentValue=_espBoxes,
		Callback=function(v) _espBoxes=v; _cfg.espBoxes=v; _saveCfg(); if _espBoxEnabled then _startEspBox() end end })
	Tabs.Aimbot:CreateToggle({ Name="Tracers", CurrentValue=_espTracers,
		Callback=function(v) _espTracers=v; _cfg.espTracers=v; _saveCfg(); if _espBoxEnabled then _startEspBox() end end })
	Tabs.Aimbot:CreateToggle({ Name="Names", CurrentValue=_espNames,
		Callback=function(v) _espNames=v; _cfg.espNames=v; _saveCfg(); if _espBoxEnabled then _startEspBox() end end })
	Tabs.Aimbot:CreateToggle({ Name="Health", CurrentValue=_espHealth,
		Callback=function(v) _espHealth=v; _cfg.espHealth=v; _saveCfg(); if _espBoxEnabled then _startEspBox() end end })
	Tabs.Aimbot:CreateToggle({ Name="Distance", CurrentValue=_espDistV,
		Callback=function(v) _espDistV=v; _cfg.espDistV=v; _saveCfg(); if _espBoxEnabled then _startEspBox() end end })
	Tabs.Aimbot:CreateSlider({ Name="Max Distance (studs)", Range={100,5000}, Increment=100, CurrentValue=_espMaxDistV,
		Callback=function(v) _espMaxDistV=v; _cfg.espMaxDistV=v; _saveCfg() end })

	Tabs.Aimbot:CreateSection("Detection")
	Tabs.Aimbot:CreateSlider({ Name="Humanizer Strength", Range={0,100}, Increment=1, CurrentValue=_humanizerStr,
		Callback=function(v) _humanizerStr=v; _cfg.humanizerStr=v; _saveCfg() end })
	Tabs.Aimbot:CreateToggle({ Name="Random Delay", CurrentValue=_randomDelay,
		Callback=function(v) _randomDelay=v; _cfg.randomDelay=v; _saveCfg() end })
	Tabs.Aimbot:CreateSlider({ Name="Delay (ms)", Range={0,100}, Increment=1, CurrentValue=_delayMS,
		Callback=function(v) _delayMS=v; _cfg.delayMS=v; _saveCfg() end })
	Tabs.Aimbot:CreateToggle({ Name="Curve Aim", CurrentValue=_curveAim,
		Callback=function(v) _curveAim=v; _cfg.curveAim=v; _saveCfg() end })
	Tabs.Aimbot:CreateSlider({ Name="Curve Strength", Range={0,100}, Increment=1, CurrentValue=_curveStrength,
		Callback=function(v) _curveStrength=v; _cfg.curveStrength=v; _saveCfg() end })
	Tabs.Aimbot:CreateSlider({ Name="Max Speed (px)", Range={50,1200}, Increment=10, CurrentValue=_maxSpeed,
		Callback=function(v) _maxSpeed=v; _cfg.maxSpeed=v; _saveCfg() end })
	Tabs.Aimbot:CreateSlider({ Name="Jitter (px)", Range={0,20}, Increment=1, CurrentValue=_jitter,
		Callback=function(v) _jitter=v; _cfg.jitter=v; _saveCfg() end })
	Tabs.Aimbot:CreateToggle({ Name="Distance Scaling", CurrentValue=_distScaling,
		Callback=function(v) _distScaling=v; _cfg.distScaling=v; _saveCfg() end })
	Tabs.Aimbot:CreateToggle({ Name="Velocity Smoothing", CurrentValue=_velSmoothing,
		Callback=function(v) _velSmoothing=v; _cfg.velSmoothing=v; _saveCfg() end })
	Tabs.Aimbot:CreateToggle({ Name="Adaptive Prediction", CurrentValue=_adaptivePred,
		Callback=function(v) _adaptivePred=v; _cfg.adaptivePred=v; _saveCfg() end })
	Tabs.Aimbot:CreateToggle({ Name="Angle Compensation", CurrentValue=_angleComp,
		Callback=function(v) _angleComp=v; _cfg.angleComp=v; _saveCfg() end })
	Tabs.Aimbot:CreateToggle({ Name="Smooth Entry", CurrentValue=_smoothEntry,
		Callback=function(v) _smoothEntry=v; _cfg.smoothEntry=v; _saveCfg() end })
	Tabs.Aimbot:CreateSlider({ Name="Entry Smoothing", Range={0,100}, Increment=1, CurrentValue=_entrySmooth,
		Callback=function(v) _entrySmooth=v; _cfg.entrySmooth=v; _saveCfg() end })

	Tabs.Aimbot:CreateSection("Presets")
	Tabs.Aimbot:CreateButton({ Name="Light", Description="FOV 60 - Smooth 30 - Hum 80% - Silent OFF. Anti-ban.",
		Callback=function()
			_applyPreset({ae=true,af=60,as=30,ap=100,aw=true,apr=true,at="UpperTorso",
				se=false,sf=60,sp=100,sh=70,sw=true,spr=true,st="Head",
				hum=80,rd=true,dm=25,ca=true,cs=18,ms=180,ji=3,ds=true,vs=true,adp=true,ac=true,sme=true,es=60})
			Luna:Notification({Title="Light",Content="FOV 60 - Hum 80% - Anti-ban activo",Icon="shield",ImageSource="Material",Duration=4})
		end })
	Tabs.Aimbot:CreateButton({ Name="Medium", Description="FOV 100 - Smooth 14 - Hum 50% - Silent HEAD 100%. Config KOVARI.",
		Callback=function()
			_applyPreset({ae=true,af=100,as=14,ap=120,aw=true,apr=true,at="UpperTorso",
				se=true,sf=120,sp=120,sh=100,sw=true,spr=true,st="Head",
				hum=50,rd=true,dm=12,ca=true,cs=12,ms=320,ji=2,ds=true,vs=true,adp=true,ac=true,sme=true,es=40})
			Luna:Notification({Title="Medium",Content="FOV 100/120 - Smooth 14 - Silent HEAD ON",Icon="tune",ImageSource="Material",Duration=4})
		end })
	Tabs.Aimbot:CreateButton({ Name="Hard", Description="FOV 280 - Smooth 6 - Hum 10% - HEAD 100%. Alto riesgo.",
		Callback=function()
			_applyPreset({ae=true,af=280,as=6,ap=130,aw=false,apr=true,at="Head",
				se=true,sf=280,sp=130,sh=100,sw=false,spr=true,st="Head",
				hum=10,rd=false,dm=0,ca=false,cs=0,ms=800,ji=0,ds=true,vs=true,adp=true,ac=true,sme=false,es=10})
			Luna:Notification({Title="Hard",Content="FOV 280 - Sin humanizer - HEAD 100%",Icon="warning",ImageSource="Material",Duration=5})
		end })

	-- Iniciar sistemas si estaban activos al cargar
	if _aimbotEnabled  then _startAimbot() end
	if _silentEnabled  then _enableSilentAim() end
	if _espBoxEnabled  then _startEspBox() end
	if _autoFireEnabled then _startAutoFire() end

	-- ================================================================
	--   ESP BÁSICO (Highlight)
	-- ================================================================
	Tabs.Scripts2:CreateSection("🔍 ESP")
	local _espEnabled = _cfg.espEnabled or false
	local _espHighlights = {}
	local _espTeamColor = _cfg.espTeamColor or false
	local _espConn = nil
	local _espRemoveConn = nil

	local function removeESP()
		for _, h in pairs(_espHighlights) do
			pcall(function() h:Destroy() end)
		end
		_espHighlights = {}
	end

	local function addESPToPlayer(p)
		if p == Player or not p.Character then return end
		-- Quitar highlight viejo si existe
		if _espHighlights[p.UserId] then
			pcall(function() _espHighlights[p.UserId]:Destroy() end)
		end
		local h = Instance.new("Highlight")
		h.FillColor        = (_espTeamColor and p.TeamColor) and p.TeamColor.Color or Color3.fromRGB(255, 50, 50)
		h.OutlineColor     = Color3.fromRGB(255, 255, 255)
		h.FillTransparency = 0.5
		h.OutlineTransparency = 0
		h.Parent           = p.Character
		_espHighlights[p.UserId] = h

		-- Fix 2.5: Actualizar color del highlight cuando el jugador cambia de equipo
		pcall(function()
			p:GetPropertyChangedSignal("Team"):Connect(function()
				if _espEnabled and _espTeamColor and _espHighlights[p.UserId] then
					_espHighlights[p.UserId].FillColor = p.TeamColor and p.TeamColor.Color or Color3.fromRGB(255, 50, 50)
				end
			end)
		end)
	end

	local function applyESP()
		removeESP()
		for _, p in pairs(Players:GetPlayers()) do
			addESPToPlayer(p)
		end
	end

	Tabs.Scripts2:CreateToggle({
		Name = "ESP Jugadores",
		Description = "Muestra a todos los jugadores a través de las paredes",
		CurrentValue = _espEnabled,
		Callback = function(v)
			_espEnabled = v
			_cfg.espEnabled = v
			_saveCfg()
			if v then
				applyESP()
				-- Nuevo jugador entra
				_espConn = Players.PlayerAdded:Connect(function(p)
					p.CharacterAdded:Connect(function()
						if _espEnabled then
							task.wait(0.5)
							addESPToPlayer(p)
						end
					end)
				end)
				-- Jugador sale → limpiar highlight
				_espRemoveConn = Players.PlayerRemoving:Connect(function(p)
					if _espHighlights[p.UserId] then
						pcall(function() _espHighlights[p.UserId]:Destroy() end)
						_espHighlights[p.UserId] = nil
					end
				end)
			else
				removeESP()
				if _espConn       then _espConn:Disconnect()       _espConn=nil       end
				if _espRemoveConn then _espRemoveConn:Disconnect() _espRemoveConn=nil end
			end
		end
	})
	-- Aplicar ESP guardado al cargar
	-- Aplicar ESP guardado al cargar (solo si el toggle no lo activó ya)
	if _espEnabled and not _espConn then
		applyESP()
		_espConn = Players.PlayerAdded:Connect(function(p)
			p.CharacterAdded:Connect(function()
				if _espEnabled then task.wait(0.5) addESPToPlayer(p) end
			end)
		end)
		_espRemoveConn = Players.PlayerRemoving:Connect(function(p)
			if _espHighlights[p.UserId] then
				pcall(function() _espHighlights[p.UserId]:Destroy() end)
				_espHighlights[p.UserId] = nil
			end
		end)
	end

	Tabs.Scripts2:CreateToggle({
		Name = "ESP Equipos (Color)",
		Description = "Colorea el ESP según el equipo de cada jugador",
		CurrentValue = _cfg.espTeamColor,
		Callback = function(v)
			_espTeamColor = v
			_cfg.espTeamColor = v
			_saveCfg()
			for _, p in pairs(Players:GetPlayers()) do
				if p ~= Player and _espHighlights[p.UserId] then
					_espHighlights[p.UserId].FillColor = v and (p.TeamColor and p.TeamColor.Color or Color3.fromRGB(255,50,50)) or Color3.fromRGB(255,50,50)
				end
			end
		end
	})

	Tabs.Scripts2:CreateSlider({
		Name = "ESP Transparencia",
		Description = "Ajusta la transparencia del relleno del ESP",
		Range = {0, 100}, Increment = 5, CurrentValue = 50,
		Callback = function(v)
			local t = v / 100
			for _, h in pairs(_espHighlights) do
				h.FillTransparency = t
			end
		end
	})

	Tabs.Info:CreateSection("Redes Sociales")

	local function InjectSocialIcon(btnName, bgColor, iconImage, iconColor)
		task.defer(function()
			-- Dar tiempo a que el tab cargue sus elementos
			local page = nil
			for _ = 1, 10 do
				local ok, result = pcall(function() return Tabs.Info.Page end)
				if ok and result then page = result break end
				task.wait(0.1)
			end
			if not page then return end
			local frame = page:FindFirstChild(btnName, true)
			if not frame then return end
			-- Verificar que no ya se inyectó antes
			if frame:FindFirstChild("_SocialCircle") then return end
			local title = frame:FindFirstChild("Title")
			local desc  = frame:FindFirstChild("Desc")
			if title then
				title.Position = UDim2.new(0, 58, title.Position.Y.Scale, title.Position.Y.Offset)
				title.Size     = UDim2.new(1, -72, title.Size.Y.Scale, title.Size.Y.Offset)
			end
			if desc then
				desc.Position = UDim2.new(0, 58, desc.Position.Y.Scale, desc.Position.Y.Offset)
				desc.Size     = UDim2.new(1, -72, desc.Size.Y.Scale, desc.Size.Y.Offset)
			end
			local circle = Instance.new("Frame", frame)
			circle.Name             = "_SocialCircle"
			circle.Size             = UDim2.fromOffset(38, 38)
			circle.Position         = UDim2.new(0, 8, 0.5, -19)
			circle.BackgroundColor3 = bgColor
			circle.BorderSizePixel  = 0
			circle.ZIndex           = 5
			Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
			local cStroke = Instance.new("UIStroke", circle)
			cStroke.Color       = bgColor
			cStroke.Thickness   = 1.5
			cStroke.Transparency = 0.5
			local img = Instance.new("ImageLabel", circle)
			img.Size                = UDim2.new(0.75, 0, 0.75, 0)
			img.Position            = UDim2.new(0.125, 0, 0.125, 0)
			img.BackgroundTransparency = 1
			img.Image               = iconImage
			img.ImageColor3         = iconColor
			img.ScaleType           = Enum.ScaleType.Fit
			img.ZIndex              = 6
		end)
	end

	Tabs.Info:CreateButton({
		Name = "Discord",
		Callback = function()
			local discordURL = "https://discord.gg/GB5C5CKDk"
			local opened = false
			pcall(function() openurl(discordURL) opened = true end)
			if not opened then pcall(function() syn.open_url(discordURL) opened = true end) end
			if not opened then pcall(function() open_url(discordURL) opened = true end) end
			pcall(setclipboard, discordURL)
			Luna:Notification({
				Title = "Discord",
				Content = opened and "Abriendo Discord..." or "Link copiado!  discord.gg/GB5C5CKDk",
				Icon = "18505728201",
				ImageSource = "Custom",
				Duration = 4
			})
		end
	})
	InjectSocialIcon(
		"Discord",
		Color3.fromRGB(88, 101, 242),
		"rbxassetid://18505728201",
		Color3.fromRGB(255, 255, 255)
	)

	Tabs.Info:CreateButton({
		Name = "TikTok",
		Callback = function()
			local tiktokURL = "https://www.tiktok.com/@_m.a.r.t.i.n_2"
			local opened = false
			pcall(function() openurl(tiktokURL) opened = true end)
			if not opened then pcall(function() syn.open_url(tiktokURL) opened = true end) end
			if not opened then pcall(function() open_url(tiktokURL) opened = true end) end
			pcall(setclipboard, tiktokURL)
			Luna:Notification({
				Title = "TikTok",
				Content = opened and "Abriendo TikTok..." or "Link copiado!  @_m.a.r.t.i.n_2",
				Icon = "84157643184125",
				ImageSource = "Custom",
				Duration = 4
			})
		end
	})
	InjectSocialIcon(
		"TikTok",
		Color3.fromRGB(18, 18, 18),
		"rbxassetid://84157643184125",
		Color3.fromRGB(255, 255, 255)
	)

	Tabs.Info:CreateSection("BladeX")
	Tabs.Info:CreateParagraph({
		Title = "BladeX",
		Text = "Obtén la key en el discord:"
	})

	-- ═══ REGISTRAR ITEMS PARA FAVORITOS ═══
	_registerFavItem({ name = "Auto Farm",      description = "Ataca automáticamente al enemigo más cercano",         type = "toggle",
		rebuildFn = function(count)
			Tabs.Extra:CreateToggle({ Name = "Auto Farm", Description = "Farm · Usado "..count.." veces", CurrentValue = false,
				Callback = function(v) if v then _trackUse("Auto Farm") end _farmEnabled = v end })
		end })
	_registerFavItem({ name = "Auto Collect",   description = "Recoge items del suelo automáticamente",              type = "toggle",
		rebuildFn = function(count)
			Tabs.Extra:CreateToggle({ Name = "Auto Collect", Description = "Farm · Usado "..count.." veces", CurrentValue = false,
				Callback = function(v) if v then _trackUse("Auto Collect") end _collectEnabled = v end })
		end })
	_registerFavItem({ name = "FPS Boost",      description = "Activa todas las optimizaciones al mismo tiempo",     type = "toggle",
		rebuildFn = function(count)
			Tabs.Extra:CreateToggle({ Name = "FPS Boost", Description = "FPS · Usado "..count.." veces", CurrentValue = false,
				Callback = function(v) if v then _trackUse("FPS Boost") end
					pcall(function() settings().Rendering.QualityLevel = v and 1 or 10 end)
					Lighting.GlobalShadows = v and false or _origLighting.GlobalShadows end })
		end })
	_registerFavItem({ name = "Fullbright",     description = "Máximo brillo, sin oscuridad ni niebla",             type = "toggle",
		rebuildFn = function(count)
			Tabs.Extra:CreateToggle({ Name = "Fullbright", Description = "FPS · Usado "..count.." veces", CurrentValue = false,
				Callback = function(v) if v then _trackUse("Fullbright") end
					Lighting.Brightness = v and 2 or _origLighting.Brightness
					Lighting.GlobalShadows = v and false or _origLighting.GlobalShadows
					Lighting.ClockTime = v and 14 or _origLighting.ClockTime end })
		end })
	_registerFavItem({ name = "Nuke Effects",   description = "Elimina permanentemente partículas y efectos",        type = "button",
		rebuildFn = function(count)
			Tabs.Extra:CreateButton({ Name = "Nuke Effects", Description = "FPS · Usado "..count.." veces",
				Callback = function() _trackUse("Nuke Effects")
					pcall(function() settings().Rendering.QualityLevel = 1 end)
					for _, obj in pairs(workspace:GetDescendants()) do
						if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
							pcall(function() obj:Destroy() end) end end end })
		end })
	_registerFavItem({ name = "Anti AFK",       description = "Evita que Roblox te expulse por inactividad",        type = "toggle",
		rebuildFn = function(count)
			Tabs.Extra:CreateToggle({ Name = "Anti AFK", Description = "Scripts · Usado "..count.." veces", CurrentValue = _cfg.antiAFK,
				Callback = function(v) if v then _trackUse("Anti AFK") end _cfg.antiAFK = v _saveCfg()
					if v then _startAntiAFK() elseif _G.AntiAFK then pcall(function() _G.AntiAFK:Disconnect() end) _G.AntiAFK = nil end end })
		end })
	_registerFavItem({ name = "No Clip",        description = "Atraviesa paredes y objetos del mapa",               type = "toggle",
		rebuildFn = function(count)
			Tabs.Extra:CreateToggle({ Name = "No Clip", Description = "Scripts · Usado "..count.." veces", CurrentValue = _cfg.noClip,
				Callback = function(v) if v then _trackUse("No Clip") end _noClipActive = v _G.NoClip = v _cfg.noClip = v _saveCfg()
					if v then _G.NoClipConn = RunService.Stepped:Connect(function() if _noClipActive then
						for _, p in pairs(Player.Character and Player.Character:GetDescendants() or {}) do
							if p:IsA("BasePart") then p.CanCollide = false end end end end)
					elseif _G.NoClipConn then _G.NoClipConn:Disconnect() _G.NoClipConn = nil end end })
		end })
	_registerFavItem({ name = "Walk Speed",     description = "Velocidad de movimiento del personaje",              type = "slider",
		rebuildFn = function(count)
			Tabs.Extra:CreateSlider({ Name = "Walk Speed", Description = "Scripts · Usado "..count.." veces",
				Range = {5,300}, Increment = 1, CurrentValue = _cfg.walkSpeed,
				Callback = function(v) _trackUse("Walk Speed") _savedWalkSpeed = v _cfg.walkSpeed = v _saveCfg()
					local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
					if hum then hum.WalkSpeed = v end end })
		end })
	_registerFavItem({ name = "Jump Power",     description = "Potencia de salto",                                  type = "slider",
		rebuildFn = function(count)
			Tabs.Extra:CreateSlider({ Name = "Jump Power", Description = "Scripts · Usado "..count.." veces",
				Range = {0,500}, Increment = 5, CurrentValue = _cfg.jumpPower,
				Callback = function(v) _trackUse("Jump Power") _savedJumpPower = v _cfg.jumpPower = v _saveCfg()
					local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
					if hum then hum.JumpPower = v end end })
		end })
	_registerFavItem({ name = "Remove Textures", description = "Elimina texturas, decals y partículas del mapa",   type = "toggle",
		rebuildFn = function(count)
			Tabs.Extra:CreateToggle({ Name = "Remove Textures", Description = "FPS · Usado "..count.." veces", CurrentValue = false,
				Callback = function(v) if v then _trackUse("Remove Textures") end
					for _, obj in pairs(workspace:GetDescendants()) do
						if obj:IsA("Decal") or obj:IsA("Texture") then obj.Transparency = v and 1 or 0 end
						if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then obj.Enabled = not v end end end })
		end })

	-- Construir Favoritos con los datos de uso guardados
	_buildFavoritos()

end)()
return Luna
