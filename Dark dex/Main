local selection
local nodes = {}

local oldgame = game
local game = workspace.Parent

cloneref = cloneref or function(ref)
	if not getreg then return ref end
	
	local InstanceList
	
	local a = Instance.new("Part")
	for _, c in pairs(getreg()) do
		if type(c) == "table" and #c then
			if rawget(c, "__mode") == "kvs" then
				for d, e in pairs(c) do
					if e == a then
						InstanceList = c
						break
					end
				end
			end
		end
	end
	local f = {}
	function f.invalidate(g)
		if not InstanceList then
			return
		end
		for b, c in pairs(InstanceList) do
			if c == g then
				InstanceList[b] = nil
				return g
			end
		end
	end
	return f.invalidate
end

local BASE_URL = "https://raw.githubusercontent.com/TU_USUARIO/TU_REPO/main/modules/"
local ModuleNames = {"Console","Explorer","Lib","ModelViewer","Properties","SaveInstance","ScriptViewer"}
local ModuleCacheTTL = 24 * 60 * 60 -- 24h

local function fetchModuleSource(name)
	local cachePath = "dex/modules/" .. name .. ".lua"
	local metaPath = cachePath .. ".meta"

	if env.isfile and env.readfile and env.isfile(cachePath) and env.isfile(metaPath) then
		local okMeta, savedAt = pcall(function() return tonumber(env.readfile(metaPath)) end)
		if okMeta and savedAt and (os.time() - savedAt) < ModuleCacheTTL then
			local okRead, cached = pcall(env.readfile, cachePath)
			if okRead and cached and cached ~= "" then
				return cached
			end
		end
	end

	local ok, result = pcall(function()
		return game:HttpGet(BASE_URL .. name .. ".lua")
	end)

	if ok and result and result ~= "" then
		if env.writefile and env.isfolder and env.makefolder then
			if not env.isfolder("dex/modules") then pcall(env.makefolder, "dex/modules") end
			pcall(env.writefile, cachePath, result)
			pcall(env.writefile, metaPath, tostring(os.time()))
		end
		return result
	end

	warn("[BLADEX] no se pudo descargar el módulo '" .. name .. "': " .. tostring(result))

	if env.isfile and env.readfile and env.isfile(cachePath) then
		local okCache, cached = pcall(env.readfile, cachePath)
		if okCache and cached and cached ~= "" then
			warn("[BLADEX] usando copia en cache (posiblemente vieja) de '" .. name .. "'")
			return cached
		end
	end

	return nil
end

local EmbeddedModules = {}

for _, name in ipairs(ModuleNames) do
	local source = fetchModuleSource(name)
	if source then
		local chunk, compileErr = loadstring(source, "=" .. name)
		if chunk then
			local ok, moduleFn = pcall(chunk)
			if ok and type(moduleFn) == "function" then
				EmbeddedModules[name] = moduleFn
			else
				warn("[BLADEX] el módulo '" .. name .. "' no devolvió una función válida: " .. tostring(moduleFn))
			end
		else
			warn("[BLADEX] error de sintaxis descargando '" .. name .. "': " .. tostring(compileErr))
		end
	else
		warn("[BLADEX] módulo '" .. name .. "' no disponible — esa parte de Dark Dex no va a funcionar")
	end
end
-- inject virutal env cuz why not
if game:GetService("RunService"):IsStudio() then
	if script:FindFirstChild("Modules"):FindFirstChild("VirtualFS") then
		for namefunc, func in require(script.Modules.VirtualFS) do
			getfenv()[namefunc] = func
			--print("Inserting "..namefunc)
		end
	end
end

local oldgame = oldgame or game

cloneref = cloneref or function(ref)
	if not getreg then return ref end
	
	local InstanceList
	
	local a = Instance.new("Part")
	for _, c in pairs(getreg()) do
		if type(c) == "table" and #c then
			if rawget(c, "__mode") == "kvs" then
				for d, e in pairs(c) do
					if e == a then
						InstanceList = c
						break
					end
				end
			end
		end
	end
	local f = {}
	function f.invalidate(g)
		if not InstanceList then
			return
		end
		for b, c in pairs(InstanceList) do
			if c == g then
				InstanceList[b] = nil
				return g
			end
		end
	end
	return f.invalidate
end

local isFsSupported = readfile and writefile and isfile and isfolder and listfiles and delfile and delfolder

-- Main vars
local Main, Explorer, Properties, ScriptViewer, Console, SaveInstance, ModelViewer--[[, SecretServicePanel]], DefaultSettings, Notebook, Serializer, Lib local ggv = getgenv or nil
local API, RMD

-- Default Settings
DefaultSettings = (function()
	local rgb = Color3.fromRGB	
	
	return {
		Explorer = {
			_Recurse = true,
			Sorting = true,
			TeleportToOffset = Vector3.new(0,0,0),
			ClickToRename = true,
			AutoUpdateSearch = true,
			AutoUpdateMode = 0, -- 0 Default, 1 no tree update, 2 no descendant events, 3 frozen
			PartSelectionBox = true,
			GuiSelectionBox = true,
			CopyPathUseGetChildren = true
		},
		Properties = {
			_Recurse = true,
			MaxConflictCheck = 50,
			ShowDeprecated = true,
			ShowHidden = false,
			ClearOnFocus = false,
			LoadstringInput = true,
			NumberRounding = 3,
			ShowAttributes = true,
			MaxAttributes = 50,
			ScaleType = 0 -- 0 Full Name Shown, 1 Equal Halves
		},
		Theme = {
			_Recurse = true,
			Main1 = rgb(30,30,36),
			Main2 = rgb(22,22,28),
			Outline1 = rgb(38,38,46), -- Mainly frames
			Outline2 = rgb(56,56,66), -- Mainly button
			Outline3 = rgb(24,24,30), -- Mainly textbox
			TextBox = rgb(30,30,38),
			Menu = rgb(26,26,32),
			ListSelection = rgb(10,132,255),
			Button = rgb(42,42,52),
			ButtonHover = rgb(58,60,72),
			ButtonPress = rgb(30,30,38),
			Highlight = rgb(74,78,92),
			Text = rgb(236,236,240),
			PlaceholderText = rgb(120,124,136),
			Important = rgb(255,80,86),
			ExplorerIconMap = "",
			MiscIconMap = "",
			Syntax = {
				Text = rgb(204,204,204),
				Background = rgb(36,36,36),
				Selection = rgb(255,255,255),
				SelectionBack = rgb(11,90,175),
				Operator = rgb(204,204,204),
				Number = rgb(255,198,0),
				String = rgb(173,241,149),
				Comment = rgb(102,102,102),
				Keyword = rgb(248,109,124),
				Error = rgb(255,0,0),
				FindBackground = rgb(141,118,0),
				MatchingWord = rgb(85,85,85),
				BuiltIn = rgb(132,214,247),
				CurrentLine = rgb(45,50,65),
				LocalMethod = rgb(253,251,172),
				LocalProperty = rgb(97,161,241),
				Nil = rgb(255,198,0),
				Bool = rgb(255,198,0),
				Function = rgb(248,109,124),
				Local = rgb(248,109,124),
				Self = rgb(248,109,124),
				FunctionName = rgb(253,251,172),
				Bracket = rgb(204,204,204)
			},
		},
		Window = {
			TitleOnMiddle = false,
			Transparency = 0
		},
		RemoteBlockWriteAttribute = false, -- writes attribute to remote instance if remote is blocked/unblocked
		AI = {
			_Recurse = true,
			ApiKey = "",
			Model = "gemini-3.6-flash",
			ThinkingLevel = "high",
			MaxOutputTokens = 32768,
			MaxIterations = 12,
		},
		ClassIcon = "NewDark",
		-- What available icons:
		-- > Vanilla3
		-- > Old
		-- > NewDark
	}
end)()

-- Vars
local Settings = DefaultSettings or {}
local Apps = {}
local env = {}

local service = setmetatable({},{__index = function(self,name)
	local serv = cloneref(game:GetService(name))
	self[name] = serv
	return serv
end})
local plr = service.Players.LocalPlayer or service.Players.PlayerAdded:wait()

local create = function(data)
	local insts = {}
	for i,v in pairs(data) do insts[v[1]] = Instance.new(v[2]) end

	for _,v in pairs(data) do
		for prop,val in pairs(v[3]) do
			if type(val) == "table" then
				insts[v[1]][prop] = insts[val[1]]
			else
				insts[v[1]][prop] = val
			end
		end
	end

	return insts[1]
end

local createSimple = function(class,props)
	local inst = Instance.new(class)
	for i,v in next,props do
		inst[i] = v
	end
	return inst
end

Main = (function()
	local Main = {}

	Main.ModuleList = {"Explorer","Properties","ScriptViewer","Console","SaveInstance","ModelViewer"}
	Main.Elevated = false
	Main.AllowDraggableOnMobile = true
	Main.MissingEnv = {}
	Main.Version = "2.0"
	Main.Mouse = plr:GetMouse()
	Main.AppControls = {}
	Main.Apps = Apps
	Main.MenuApps = {}
	Main.GitRepoName = "unknown"

	Main.DisplayOrders = {
		SideWindow = 8,
		Window = 10,
		Menu = 100000,
		Core = 101000
	}
	
	--[[Main.LoadAdonisBypass = function()
		-- skidded off reddit :pensive:
		local getinfo = getinfo or debug.getinfo
		local DEBUG = false
		local Hooked = {}

		local Detected, Kill

		setthreadidentity(2)

		for i, v in getgc(true) do
			if typeof(v) == "table" then
				local DetectFunc = rawget(v, "Detected")
				local KillFunc = rawget(v, "Kill")

				if typeof(DetectFunc) == "function" and not Detected then
					Detected = DetectFunc

					local Old; Old = hookfunction(Detected, function(Action, Info, NoCrash)
						if Action ~= "_" then
							if DEBUG then
								warn(`Adonis AntiCheat flagged\nMethod: {Action}\nInfo: {Info}`)
							end
						end

						return true
					end)

					table.insert(Hooked, Detected)
				end

				if rawget(v, "Variables") and rawget(v, "Process") and typeof(KillFunc) == "function" and not Kill then
					Kill = KillFunc
					local Old; Old = hookfunction(Kill, function(Info)
						if DEBUG then
							warn(`Adonis AntiCheat tried to kill (fallback): {Info}`)
						end
					end)

					table.insert(Hooked, Kill)
				end
			end
		end

		local Old; Old = hookfunction(getrenv().debug.info, newcclosure(function(...)
			local LevelOrFunc, Info = ...

			if Detected and LevelOrFunc == Detected then
				if DEBUG then
					warn(`Adonis AntiCheat sanity check detected and broken`)
				end

				return coroutine.yield(coroutine.running())
			end

			return Old(...)
		end))
		-- setthreadidentity(9)
		setthreadidentity(7)
	end
	
	Main.LoadGCBypass = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/secretisadev/Babyhamsta_Backup/refs/heads/main/Universal/Bypasses.lua", true))()
	end]]
	
	Main.GetRandomString = function()
		local output = ""
		for i = 2, 25 do
			output = output .. string.char(math.random(1,250))
		end
		
		return output
	end
	
	Main.SecureGui = function(gui)
		--warn("Secured: "..gui.Name)
		gui.Name = Main.GetRandomString()
		-- service already using cloneref
		if gethui then
			gui.Parent = gethui()
		elseif syn and syn.protect_gui then
			syn.protect_gui(gui)
			gui.Parent = service.CoreGui
		elseif protect_gui then
			protect_gui(gui)
			gui.Parent = service.CoreGui
		elseif protectgui then
			protectgui(gui)
			gui.Parent = service.CoreGui
		else
			if Main.Elevated then
				gui.Parent = service.CoreGui
			else
				gui.Parent = service.Players.LocalPlayer:WaitForChild("PlayerGui")
			end
		end
	end

	Main.GetInitDeps = function()
		return {
			Main = Main,
			Lib = Lib,
			Apps = Apps,
			Settings = Settings,

			API = API,
			RMD = RMD,
			env = env,
			service = service,
			plr = plr,
			create = create,
			createSimple = createSimple
		}
	end

	Main.Error = function(str)
		if rconsoleprint then
			rconsoleprint("DEX ERROR: "..tostring(str).."\n")
			wait(9e9)
		else
			error(str)
		end
	end

	Main.LoadModule = function(name)
		if Main.Elevated then -- If you don't have filesystem api then ur outta luck tbh
			local control

			if EmbeddedModules then -- Offline Modules
				control = EmbeddedModules[name]()

				-- TODO: Remove when open source
				if gethsfuncs then
					control = _G.moduleData
				end

				if not control then Main.Error("Missing Embedded Module: "..name) end
			elseif _G.DebugLoadModel then -- Load Debug Model File
				local model = Main.DebugModel
				if not model then model = oldgame:GetObjects(getsynasset("AfterModules.rbxm"))[1] end

				control = loadstring(model.Modules[name].Source)()
				print("Locally Loaded Module",name,control)
			else
				-- Get hash data
				local hashs = Main.ModuleHashData
				if not hashs then
					local s,hashDataStr = pcall(oldgame.HttpGet, game, "https://api.github.com/repos/"..Main.GitRepoName.."/ModuleHashs.dat")
					if not s then Main.Error("Failed to get module hashs") end

					local s,hashData = pcall(service.HttpService.JSONDecode,service.HttpService,hashDataStr)
					if not s then Main.Error("Failed to decode module hash JSON") end

					hashs = hashData
					Main.ModuleHashData = hashs
				end

				-- Check if local copy exists with matching hashs
				local hashfunc = (syn and syn.crypt.hash) or function() return "" end
				local filePath = "dex/ModuleCache/"..name..".lua"
				local s,moduleStr = pcall(env.readfile,filePath)

				if s and hashfunc(moduleStr) == hashs[name] then
					control = loadstring(moduleStr)()
				else
					-- Download and cache
					local s,moduleStr = pcall(oldgame.HttpGet, game, "https://api.github.com/repos/"..Main.GitRepoName.."/Modules/"..name..".lua")
					if not s then Main.Error("Failed to get external module data of "..name) end

					env.writefile(filePath,moduleStr)
					control = loadstring(moduleStr)()
				end
			end

			Main.AppControls[name] = control
			control.InitDeps(Main.GetInitDeps())

			local moduleData = control.Main()
			Apps[name] = moduleData
			return moduleData
		else
			local module = script:WaitForChild("Modules"):WaitForChild(name,2)
			if not module then Main.Error("CANNOT FIND MODULE "..name) end

			local control = require(module)
			Main.AppControls[name] = control
			control.InitDeps(Main.GetInitDeps())

			local moduleData = control.Main()
			Apps[name] = moduleData
			return moduleData
		end
	end

	Main.LoadModules = function()
		for i,v in pairs(Main.ModuleList) do
			local s,e = pcall(Main.LoadModule,v)
			if not s then
				Main.Error("FAILED LOADING " .. v .. " CAUSE " .. e)
			end
		end

		-- Init Major Apps and define them in modules
		Explorer = Apps.Explorer
		Properties = Apps.Properties
		ScriptViewer = Apps.ScriptViewer
		Console = Apps.Console
		SaveInstance = Apps.SaveInstance
		ModelViewer = Apps.ModelViewer
		Notebook = Apps.Notebook
		
		--SecretServicePanel = Apps.SecretServicePanel
		local appTable = {
			Explorer = Explorer,
			Properties = Properties,
			ScriptViewer = ScriptViewer,
			Console = Console,
			SaveInstance = SaveInstance,
			ModelViewer = ModelViewer,
			Notebook = Notebook,
			
			--SecretServicePanel = SecretServicePanel,
		}

		Main.AppControls.Lib.InitAfterMain(appTable)
		for i,v in pairs(Main.ModuleList) do
			local control = Main.AppControls[v]
			if control then
				control.InitAfterMain(appTable)
			end
		end
	end

	Main.InitEnv = function()
		setmetatable(env,{__newindex = function(self,name,func)
			if not func then Main.MissingEnv[#Main.MissingEnv+1] = name return end
			rawset(self,name,func)
		end})

		env.isonmobile = game:GetService("UserInputService").TouchEnabled
		
		env.loadstring = (pcall(loadstring,"local a = 1") and loadstring) or (game:GetService("RunService"):IsStudio() and script.Modules:FindFirstChild("Loadstring") and require(script.Modules:FindFirstChild("Loadstring")))

		-- file
		env.isfile = isfile
		env.isfolder = isfolder
		env.readfile = readfile
		env.writefile = writefile
		env.appendfile = appendfile
		env.makefolder = makefolder
		env.listfiles = listfiles
		env.loadfile = loadfile
		env.saveinstance = saveinstance or (function()
			--warn("No built-in saveinstance exists, using SynSaveInstance and wrapper...")
			if game:GetService("RunService"):IsStudio() then return function() error("Cannot run in Roblox Studio!") end end
			local Params = {
				RepoURL = "https://raw.githubusercontent.com/luau/SynSaveInstance/main/",
				SSI = "saveinstance",
			}
			local synsaveinstance = loadstring(oldgame:HttpGet(Params.RepoURL .. Params.SSI .. ".luau", true), Params.SSI)()
		
			local function wrappedsaveinstance(obj, filepath, options)
				options["FilePath"] = filepath
				--options["ReadMe"] = false
				options["Object"] = obj
				return synsaveinstance(options)
			end
			
			getgenv().saveinstance = wrappedsaveinstance
			return wrappedsaveinstance
		end)()
		
		env.parsefile = function(name)
			return tostring(name):gsub("[*\\?:<>|]+", ""):sub(1, 175)
		end

		-- debug
		env.getupvalues = debug.getupvalues or getupvalues or getupvals
		env.getconstants = debug.getconstants or getconstants or getconsts
		env.islclosure = islclosure or is_l_closure
		env.checkcaller = checkcaller
		env.getreg = getreg
		env.getgc = getgc
		
		-- hooks
		env.hookfunction = hookfunction
		env.hookmetamethod = hookmetamethod

		-- other
		env.getscriptbytecode = getscriptbytecode
		env.setfflag = setfflag
		env.protectgui = protect_gui or (syn and syn.protect_gui)
		env.gethui = gethui
		env.setclipboard = setclipboard
		env.getnilinstances = getnilinstances or get_nil_instances
		env.getloadedmodules = getloadedmodules
		
		env.isViableDecompileScript = function(obj)
			if obj:IsA("ModuleScript") then
				return true
			elseif obj:IsA("LocalScript") and (obj.RunContext == Enum.RunContext.Client or obj.RunContext == Enum.RunContext.Legacy) then
				return true
			elseif obj:IsA("Script") and obj.RunContext == Enum.RunContext.Client then
				return true
			end
			return false
		end
		env.request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
		
		env.decompile = decompile or (function()
			-- by lovrewe
			--warn("No built-in decompiler exists, using Konstant decompiler...")
			--assert(getscriptbytecode, "Exploit not supported.")
			
			if not env.getscriptbytecode then --[[warn('Konstant decompiler is not supported. "getscriptbytecode" is missing.')]] return end

			local API = "http://api.plusgiant5.com"

			local last_call = 0

			local request = env.request

			local function call(konstantType, scriptPath)
				local success, bytecode = pcall(env.getscriptbytecode, scriptPath)

				if (not success) then
					return `-- Failed to get script bytecode, error:\n\n--[[\n{bytecode}\n--]]`
				end

				local time_elapsed = os.clock() - last_call
				if time_elapsed <= .5 then
					task.wait(.5 - time_elapsed)
				end

				local httpResult = request({
					Url = API .. konstantType,
					Body = bytecode,
					Method = "POST",
					Headers = {
						["Content-Type"] = "text/plain"
					}
				})

				last_call = os.clock()

				if (httpResult.StatusCode ~= 200) then
					return `-- Error occurred while requesting Konstant API, error:\n\n--[[\n{httpResult.Body}\n--]]`
				else
					return httpResult.Body
				end
			end

			local function decompile(scriptPath)
				return call("/konstant/decompile", scriptPath)
			end

			getgenv().decompile = decompile
			
			env.decompile = decompile
			return decompile
		end)()

		if identifyexecutor then
			Main.Executor = identifyexecutor()
		end

		Main.GuiHolder = Main.Elevated and service.CoreGui or plr:FindFirstChildOfClass("PlayerGui")

		setmetatable(env,nil)
	end

	Main.IncompatibleTest = function()
		--[[local function incompatibleMessage(reason, tolerated)
			local msg = Instance.new("ScreenGui")
			msg.IgnoreGuiInset = true
			local t = Instance.new("TextLabel",msg)
			t.BackgroundColor3 = Color3.fromRGB(50,50,50)
			t.Position = UDim2.new(0,0,0,0)
			t.Size = UDim2.new(1,0,1,0)
			t.TextColor3 = Color3.new(1,1,1)
			t.TextWrapped = true
			t.TextScaled = true
			t.Text = "\n\n\n\n\n\n\n\nHello Skidsploit user,\nZinnia, Perfectus and the Secret Service does not approve of Dex being used on your skidsploit.\nPlease consider getting something better.\n\nIncompatible Reason: "..reason.."\n\n\n\n\n\n\n\n"
			
			-- This sound wont work!!!
			local sound = Instance.new("Sound",msg)
			sound.SoundId = "rbxassetid://175964948"
			sound.Volume = 1
			sound.Looped = true
			sound.Playing = true
			
			if not tolerated then
				Lib.ShowGui(msg)
				
				if os and os.execute then pcall(os.execute,'explorer "https://weao.xyz"') end
				if pcall(game.GetService, game,"MessageBusService") and game:GetService("MessageBusService").Publish then pcall(game:GetService("MessageBusService").Publish, game:GetService("MessageBusService"), game:GetService("MessageBusService"):GetMessageId("Linking", "openURLRequest"), {url = 'explorer "https://weao.xyz"'}) end
			else
				warn(msg)
			end			
		end
		
																																													local yummy, evilList = "\105\100\101\110\116\105\102\121\101\120\101\99\117\116\111\114", { "\120\101\110\111", "\115\111\108\97\114\97", "\119\97\118\101" }
																																													if ggv and ggv()[yummy] then local wow = ggv()[yummy] if table.find(evilList, string.lower(wow)) then incompatibleMessage("\83\72\73\84\84\89\32\69\88\69\67\85\84\79\82") end end
																																													
		local t = {}
		t[1] = t
		local x = unpack(t) or incompatibleMessage("WRAPPER FAILED TO CYCLIC #1")
		if x[1] ~= t then incompatibleMessage("WRAPPER FAILED TO CYCLIC #2") end
		
		if game ~= workspace.Parent then
			incompatibleMessage("WRAPPER NO CACHE (game ≠ workspace.Parent)", true)
			game = workspace.Parent
		end
		
		if Main.Elevated and not loadstring("for i = 1,1 do continue end") then incompatibleMessage("CAN'T CONTINUE OR NO LOADSTRING")end
		
		local obj = newproxy(true)
		local mt = getmetatable(obj)
		mt.__index = function() incompatibleMessage("CAN'T NAMECALL (__index triggered instead of __namecall)") end
		mt.__namecall = function() end
		obj:No()
		
		local fEnv = setmetatable({zin = 5},{__index = getfenv()})
		local caller = function(f) f() end
		setfenv(caller,fEnv)
		caller(function() if not getfenv(2).zin then incompatibleMessage("RERU WILL BE FILING A LAWSUIT AGAINST YOU SOON") end end)
		
		local second = false
		coroutine.wrap(function() local start = tick() wait(5) if tick() - start < 0.1 or not second then incompatibleMessage("SKIDDED YIELDING") end end)()
		second = true]]
	end
	
	local function serialize(val)
		if typeof(val) == "Color3" then
			local serializedColor = {}
			serializedColor.R = val.R
			serializedColor.G = val.G
			serializedColor.B = val.B
			return serializedColor
		else
			return val
		end
	end
	
	local function deserialize(val)
		if typeof(val) == "table" then
			if val.R and val.G and val.B then
				return Color3.new(val.R, val.G, val.B)
			else
				return val
			end
		else
			return val
		end
	end
	
	Main.ExportSettings = function()
		local rawData = Settings or DefaultSettings

		local function recur(tbl)
			local newTbl = {}
			for i, v in pairs(tbl) do
				if typeof(v) == "table" then
					newTbl[i] = recur(v)
				else
					newTbl[i] = serialize(v)
				end
			end
			return newTbl
		end

		-- serialize color3 sebelum encode
		local serializedData = recur(rawData)

		local s, json = pcall(service.HttpService.JSONEncode, service.HttpService, serializedData)
		if s and json then
			return json
		end
	end


	--warn(Main.ExportSettings())

	Main.SaveSettings = function()
		if not env.writefile then return false end
		local json = Main.ExportSettings()
		if not json then return false end
		local ok, err = pcall(env.writefile, "DexSettings.json", json)
		return ok, err
	end

	Main.LoadSettings = function()
		local s, data = pcall(env.readfile or error, "DexSettings.json")
		if s and data and data ~= "" then
			local s, decoded = pcall(service.HttpService.JSONDecode, service.HttpService, data)
			if s and decoded then

				local function recur(tbl)
					local newTbl = {}
					for i, v in pairs(tbl) do
						if typeof(v) == "table" then
							newTbl[i] = deserialize(recur(v))
						else
							newTbl[i] = deserialize(v)
						end
					end
					return newTbl
				end

				local deserializedData = recur(decoded)
				for k, v in pairs(deserializedData) do
					Settings[k] = v
				end

			else
				warn("failed to decode settings json")
			end
		else
			Main.ResetSettings()
		end
	end

	
	

	Main.ResetSettings = function()
		local function recur(t,res)
			for set,val in pairs(t) do
				if type(val) == "table" and val._Recurse then
					if type(res[set]) ~= "table" then
						res[set] = {}
					end
					recur(val,res[set])
				else
					res[set] = val
				end
			end
			return res
		end
		recur(DefaultSettings,Settings)
	end

	Main.FetchAPI = function(callbackiflong, callbackiftoolong, XD)
		local downloaded = false
		local api,rawAPI
		if Main.Elevated then
			if Main.LocalDepsUpToDate() then
				local localAPI = Lib.ReadFile("dex/rbx_api.dat")
				if localAPI then 
					rawAPI = localAPI
				else
					Main.DepsVersionData[1] = ""
				end
			end
			task.spawn(function()
				task.wait(10)
				if not downloaded and callbackiflong then callbackiflong() end

				task.wait(20) -- 30
				if not downloaded and callbackiftoolong then callbackiftoolong() end

				task.wait(30) -- 60
				if not downloaded and XD then XD() end
			end)
			-- lmfao async makes it work to load big file
			rawAPI = rawAPI or game:HttpGet("https://raw.githubusercontent.com/CloneTrooper1019/Roblox-Client-Tracker/roblox/API-Dump.json")
		else
			if script:FindFirstChild("API") then
				rawAPI = require(script.API)
			else
				error("NO API EXISTS")
			end
		end
		downloaded = true
		
		Main.RawAPI = rawAPI
		api = service.HttpService:JSONDecode(rawAPI)

		local classes,enums = {},{}
		local categoryOrder,seenCategories = {},{}

		local function insertAbove(t,item,aboveItem)
			local findPos = table.find(t,item)
			if not findPos then return end
			table.remove(t,findPos)

			local pos = table.find(t,aboveItem)
			if not pos then return end
			table.insert(t,pos,item)
		end

		for _,class in pairs(api.Classes) do
			local newClass = {}
			newClass.Name = class.Name
			newClass.Superclass = class.Superclass
			newClass.Properties = {}
			newClass.Functions = {}
			newClass.Events = {}
			newClass.Callbacks = {}
			newClass.Tags = {}

			if class.Tags then for c,tag in pairs(class.Tags) do newClass.Tags[tag] = true end end
			for __,member in pairs(class.Members) do
				local newMember = {}
				newMember.Name = member.Name
				newMember.Class = class.Name
				newMember.Security = member.Security
				newMember.Tags ={}
				if member.Tags then for c,tag in pairs(member.Tags) do newMember.Tags[tag] = true end end

				local mType = member.MemberType
				if mType == "Property" then
					local propCategory = member.Category or "Other"
					propCategory = propCategory:match("^%s*(.-)%s*$")
					if not seenCategories[propCategory] then
						categoryOrder[#categoryOrder+1] = propCategory
						seenCategories[propCategory] = true
					end
					newMember.ValueType = member.ValueType
					newMember.Category = propCategory
					newMember.Serialization = member.Serialization
					table.insert(newClass.Properties,newMember)
				elseif mType == "Function" then
					newMember.Parameters = {}
					newMember.ReturnType = member.ReturnType.Name
					for c,param in pairs(member.Parameters) do
						table.insert(newMember.Parameters,{Name = param.Name, Type = param.Type.Name})
					end
					table.insert(newClass.Functions,newMember)
				elseif mType == "Event" then
					newMember.Parameters = {}
					for c,param in pairs(member.Parameters) do
						table.insert(newMember.Parameters,{Name = param.Name, Type = param.Type.Name})
					end
					table.insert(newClass.Events,newMember)
				end
			end

			classes[class.Name] = newClass
		end

		for _,class in pairs(classes) do
			class.Superclass = classes[class.Superclass]
		end

		for _,enum in pairs(api.Enums) do
			local newEnum = {}
			newEnum.Name = enum.Name
			newEnum.Items = {}
			newEnum.Tags = {}

			if enum.Tags then for c,tag in pairs(enum.Tags) do newEnum.Tags[tag] = true end end
			for __,item in pairs(enum.Items) do
				local newItem = {}
				newItem.Name = item.Name
				newItem.Value = item.Value
				table.insert(newEnum.Items,newItem)
			end

			enums[enum.Name] = newEnum
		end

		local function getMember(class,member)
			if not classes[class] or not classes[class][member] then return end
			local result = {}

			local currentClass = classes[class]
			while currentClass do
				for _,entry in pairs(currentClass[member]) do
					result[#result+1] = entry
				end
				currentClass = currentClass.Superclass
			end

			table.sort(result,function(a,b) return a.Name < b.Name end)
			return result
		end

		insertAbove(categoryOrder,"Behavior","Tuning")
		insertAbove(categoryOrder,"Appearance","Data")
		insertAbove(categoryOrder,"Attachments","Axes")
		insertAbove(categoryOrder,"Cylinder","Slider")
		insertAbove(categoryOrder,"Localization","Jump Settings")
		insertAbove(categoryOrder,"Surface","Motion")
		insertAbove(categoryOrder,"Surface Inputs","Surface")
		insertAbove(categoryOrder,"Part","Surface Inputs")
		insertAbove(categoryOrder,"Assembly","Surface Inputs")
		insertAbove(categoryOrder,"Character","Controls")
		categoryOrder[#categoryOrder+1] = "Unscriptable"
		categoryOrder[#categoryOrder+1] = "Attributes"

		local categoryOrderMap = {}
		for i = 1,#categoryOrder do
			categoryOrderMap[categoryOrder[i]] = i
		end

		return {
			Classes = classes,
			Enums = enums,
			CategoryOrder = categoryOrderMap,
			GetMember = getMember
		}
	end

	Main.FetchRMD = function()
		local rawXML
		if Main.Elevated then
			if Main.LocalDepsUpToDate() then
				local localRMD = Lib.ReadFile("dex/rbx_rmd.dat")
				if localRMD then 
					rawXML = localRMD
				else
					Main.DepsVersionData[1] = ""
				end
			end
			rawXML = rawXML or game:HttpGet("https://raw.githubusercontent.com/CloneTrooper1019/Roblox-Client-Tracker/roblox/ReflectionMetadata.xml")
		else
			if script:FindFirstChild("RMD") then
				rawXML = require(script.RMD)
			else
				error("NO RMD EXISTS")
			end
		end
		Main.RawRMD = rawXML
		local parsed = Lib.ParseXML(rawXML)
		local classList = parsed.children[1].children[1].children
		local enumList = parsed.children[1].children[2].children
		local propertyOrders = {}

		local classes,enums = {},{}
		for _,class in pairs(classList) do
			local className = ""
			for _,child in pairs(class.children) do
				if child.tag == "Properties" then
					local data = {Properties = {}, Functions = {}}
					local props = child.children
					for _,prop in pairs(props) do
						local name = prop.attrs.name
						name = name:sub(1,1):upper()..name:sub(2)
						data[name] = prop.children[1].text
					end
					className = data.Name
					classes[className] = data
				elseif child.attrs.class == "ReflectionMetadataProperties" then
					local members = child.children
					for _,member in pairs(members) do
						if member.attrs.class == "ReflectionMetadataMember" then
							local data = {}
							if member.children[1].tag == "Properties" then
								local props = member.children[1].children
								for _,prop in pairs(props) do
									if prop.attrs then
										local name = prop.attrs.name
										name = name:sub(1,1):upper()..name:sub(2)
										data[name] = prop.children[1].text
									end
								end
								if data.PropertyOrder then
									local orders = propertyOrders[className]
									if not orders then orders = {} propertyOrders[className] = orders end
									orders[data.Name] = tonumber(data.PropertyOrder)
								end
								classes[className].Properties[data.Name] = data
							end
						end
					end
				elseif child.attrs.class == "ReflectionMetadataFunctions" then
					local members = child.children
					for _,member in pairs(members) do
						if member.attrs.class == "ReflectionMetadataMember" then
							local data = {}
							if member.children[1].tag == "Properties" then
								local props = member.children[1].children
								for _,prop in pairs(props) do
									if prop.attrs then
										local name = prop.attrs.name
										name = name:sub(1,1):upper()..name:sub(2)
										data[name] = prop.children[1].text
									end
								end
								classes[className].Functions[data.Name] = data
							end
						end
					end
				end
			end
		end

		for _,enum in pairs(enumList) do
			local enumName = ""
			for _,child in pairs(enum.children) do
				if child.tag == "Properties" then
					local data = {Items = {}}
					local props = child.children
					for _,prop in pairs(props) do
						local name = prop.attrs.name
						name = name:sub(1,1):upper()..name:sub(2)
						data[name] = prop.children[1].text
					end
					enumName = data.Name
					enums[enumName] = data
				elseif child.attrs.class == "ReflectionMetadataEnumItem" then
					local data = {}
					if child.children[1].tag == "Properties" then
						local props = child.children[1].children
						for _,prop in pairs(props) do
							local name = prop.attrs.name
							name = name:sub(1,1):upper()..name:sub(2)
							data[name] = prop.children[1].text
						end
						enums[enumName].Items[data.Name] = data
					end
				end
			end
		end

		return {Classes = classes, Enums = enums, PropertyOrders = propertyOrders}
	end

	Main.ShowGui = Main.SecureGui

	Main.CreateIntro = function(initStatus) -- TODO: Must theme and show errors
		local gui = create({
			{1,"ScreenGui",{Name="Intro",}},
			{2,"Frame",{Active=true,BackgroundColor3=Color3.fromRGB(22,22,28),BorderSizePixel=0,Name="Main",Parent={1},Position=UDim2.new(0.5,-175,0.5,-100),Size=UDim2.new(0,350,0,200),}},
			{100,"UICorner",{CornerRadius=UDim.new(0,14),Parent={2},}},
			{101,"UIStroke",{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Color=Color3.fromRGB(50,50,62),Thickness=1,Transparency=0.4,Parent={2},}},
			{3,"Frame",{BackgroundColor3=Color3.fromRGB(30,30,36),BorderSizePixel=0,ClipsDescendants=true,Name="Holder",Parent={2},Size=UDim2.new(1,0,1,0),}},
			{102,"UICorner",{CornerRadius=UDim.new(0,14),Parent={3},}},
			{4,"UIGradient",{Parent={3},Rotation=30,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0),}),}},
			{5,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=Enum.Font.GothamBlack,Name="Title",Parent={3},Position=UDim2.new(0,-190,0,20),Size=UDim2.new(0,140,0,48),Text="Dex",TextColor3=Color3.fromRGB(236,236,240),TextSize=44,TextTransparency=1,TextXAlignment=0,}},
			{6,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=Enum.Font.GothamMedium,Name="Desc",Parent={3},Position=UDim2.new(0,-230,0,66),Size=UDim2.new(0,220,0,22),Text="Ultimate Debugging Suite",TextColor3=Color3.fromRGB(200,200,210),TextSize=16,TextTransparency=1,TextXAlignment=0,}},
			{7,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=Enum.Font.GothamMedium,Name="StatusText",Parent={3},Position=UDim2.new(0,20,0,110),Size=UDim2.new(0,220,0,20),Text="Fetching API",TextColor3=Color3.fromRGB(200,200,210),TextSize=13,TextTransparency=1,TextXAlignment=0,}},
			{8,"Frame",{BackgroundColor3=Color3.fromRGB(46,46,58),BorderSizePixel=0,Name="ProgressBar",Parent={3},Position=UDim2.new(0,110,0,148),Size=UDim2.new(0,0,0,4),}},
			{103,"UICorner",{CornerRadius=UDim.new(1,0),Parent={8},}},
			{9,"Frame",{BackgroundColor3=Color3.fromRGB(10,132,255),BorderSizePixel=0,Name="Bar",Parent={8},Size=UDim2.new(0,0,1,0),}},
			{104,"UICorner",{CornerRadius=UDim.new(1,0),Parent={9},}},
			{10,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image="rbxassetid://2764171053",ImageColor3=Color3.fromRGB(30,30,36),ImageTransparency=1,Parent={8},ScaleType=1,Size=UDim2.new(1,0,1,0),SliceCenter=Rect.new(2,2,254,254),}},
			{11,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=Enum.Font.Gotham,Name="Creator",Parent={2},Position=UDim2.new(1,-130,1,-24),Size=UDim2.new(0,120,0,18),Text="Developed by Perfectus.",TextColor3=Color3.fromRGB(180,180,190),TextSize=12,TextXAlignment=1,}},
			{12,"UIGradient",{Parent={11},Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0),}),}},
			{13,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=Enum.Font.GothamBold,Name="Version",Parent={2},Position=UDim2.new(1,-130,1,-42),Size=UDim2.new(0,120,0,18),Text=Main.Version,TextColor3=Color3.fromRGB(200,200,210),TextSize=13,TextXAlignment=1,}},
			{14,"UIGradient",{Parent={13},Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0),}),}},
			{15,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Image="rbxassetid://1427967925",Name="Outlines",Parent={2},Position=UDim2.new(0,-5,0,-5),ScaleType=1,Size=UDim2.new(1,10,1,10),SliceCenter=Rect.new(6,6,25,25),TileSize=UDim2.new(0,20,0,20),ImageTransparency=1,}},
			{16,"UIGradient",{Parent={15},Rotation=-30,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0),}),}},
			{17,"UIGradient",{Parent={2},Rotation=-30,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0),}),}},
			{18,"UIDragDetector", {Parent={2}}}
		})
		Main.ShowGui(gui)
		local backGradient = gui.Main.UIGradient
		local outlinesGradient = gui.Main.Outlines.UIGradient
		local holderGradient = gui.Main.Holder.UIGradient
		local titleText = gui.Main.Holder.Title
		local descText = gui.Main.Holder.Desc
		local versionText = gui.Main.Version
		local versionGradient = versionText.UIGradient
		local creatorText = gui.Main.Creator
		local creatorGradient = creatorText.UIGradient
		local statusText = gui.Main.Holder.StatusText
		local progressBar = gui.Main.Holder.ProgressBar
		local tweenS = service.TweenService

		local renderStepped = service.RunService.RenderStepped
		local signalWait = renderStepped.wait
		local fastwait = function(s)
			if not s then return signalWait(renderStepped) end
			local start = tick()
			while tick() - start < s do signalWait(renderStepped) end
		end

		statusText.Text = initStatus

		local function tweenNumber(n,ti,func)
			local tweenVal = Instance.new("IntValue")
			tweenVal.Value = 0
			tweenVal.Changed:Connect(func)
			local tween = tweenS:Create(tweenVal,ti,{Value = n})
			tween:Play()
			tween.Completed:Connect(function()
				tweenVal:Destroy()
			end)
		end

		local ti = TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
		tweenNumber(100,ti,function(val)
			val = val/200
			local start = NumberSequenceKeypoint.new(0,0)
			local a1 = NumberSequenceKeypoint.new(val,0)
			local a2 = NumberSequenceKeypoint.new(math.min(0.5,val+math.min(0.05,val)),1)
			if a1.Time == a2.Time then a2 = a1 end
			local b1 = NumberSequenceKeypoint.new(1-val,0)
			local b2 = NumberSequenceKeypoint.new(math.max(0.5,1-val-math.min(0.05,val)),1)
			if b1.Time == b2.Time then b2 = b1 end
			local goal = NumberSequenceKeypoint.new(1,0)
			backGradient.Transparency = NumberSequence.new({start,a1,a2,b2,b1,goal})
			outlinesGradient.Transparency = NumberSequence.new({start,a1,a2,b2,b1,goal})
		end)

		fastwait(0.4)

		tweenNumber(100,ti,function(val)
			val = val/166.66
			local start = NumberSequenceKeypoint.new(0,0)
			local a1 = NumberSequenceKeypoint.new(val,0)
			local a2 = NumberSequenceKeypoint.new(val+0.01,1)
			local goal = NumberSequenceKeypoint.new(1,1)
			holderGradient.Transparency = NumberSequence.new({start,a1,a2,goal})
		end)

		tweenS:Create(titleText,ti,{Position = UDim2.new(0,20,0,20), TextTransparency = 0}):Play()
		tweenS:Create(descText,ti,{Position = UDim2.new(0,20,0,66), TextTransparency = 0}):Play()

		local function rightTextTransparency(obj)
			tweenNumber(100,ti,function(val)
				val = val/100
				local a1 = NumberSequenceKeypoint.new(1-val,0)
				local a2 = NumberSequenceKeypoint.new(math.max(0,1-val-0.01),1)
				if a1.Time == a2.Time then a2 = a1 end
				local start = NumberSequenceKeypoint.new(0,a1 == a2 and 0 or 1)
				local goal = NumberSequenceKeypoint.new(1,0)
				obj.Transparency = NumberSequence.new({start,a2,a1,goal})
			end)
		end
		rightTextTransparency(versionGradient)
		rightTextTransparency(creatorGradient)

		fastwait(0.9)

		local progressTI = TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)

		tweenS:Create(statusText,progressTI,{Position = UDim2.new(0,20,0,124), TextTransparency = 0}):Play()
		tweenS:Create(progressBar,progressTI,{Position = UDim2.new(0,60,0,148), Size = UDim2.new(0,100,0,4)}):Play()

		fastwait(0.25)

		local function setProgress(text,n)
			statusText.Text = text
			tweenS:Create(progressBar.Bar,progressTI,{Size = UDim2.new(n,0,1,0)}):Play()
		end

		local function close()
			tweenS:Create(titleText,progressTI,{TextTransparency = 1}):Play()
			tweenS:Create(descText,progressTI,{TextTransparency = 1}):Play()
			tweenS:Create(versionText,progressTI,{TextTransparency = 1}):Play()
			tweenS:Create(creatorText,progressTI,{TextTransparency = 1}):Play()
			tweenS:Create(statusText,progressTI,{TextTransparency = 1}):Play()
			tweenS:Create(progressBar,progressTI,{BackgroundTransparency = 1}):Play()
			tweenS:Create(progressBar.Bar,progressTI,{BackgroundTransparency = 1}):Play()
			tweenS:Create(progressBar.ImageLabel,progressTI,{ImageTransparency = 1}):Play()

			tweenNumber(100,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.In),function(val)
				val = val/250
				local start = NumberSequenceKeypoint.new(0,0)
				local a1 = NumberSequenceKeypoint.new(0.6+val,0)
				local a2 = NumberSequenceKeypoint.new(math.min(1,0.601+val),1)
				if a1.Time == a2.Time then a2 = a1 end
				local goal = NumberSequenceKeypoint.new(1,a1 == a2 and 0 or 1)
				holderGradient.Transparency = NumberSequence.new({start,a1,a2,goal})
			end)

			fastwait(0.5)
			gui.Main.BackgroundTransparency = 1
			outlinesGradient.Rotation = 30

			tweenNumber(100,ti,function(val)
				val = val/100
				local start = NumberSequenceKeypoint.new(0,1)
				local a1 = NumberSequenceKeypoint.new(val,1)
				local a2 = NumberSequenceKeypoint.new(math.min(1,val+math.min(0.05,val)),0)
				if a1.Time == a2.Time then a2 = a1 end
				local goal = NumberSequenceKeypoint.new(1,a1 == a2 and 1 or 0)
				outlinesGradient.Transparency = NumberSequence.new({start,a1,a2,goal})
				holderGradient.Transparency = NumberSequence.new({start,a1,a2,goal})
			end)

			fastwait(0.45)
			gui:Destroy()
		end

		return {SetProgress = setProgress, Close = close, Object = gui}
	end

	Main.CreateApp = function(data)
		if Main.MenuApps[data.Name] then return end -- TODO: Handle conflict
		local control = {}

		local app = Main.AppTemplate:Clone()

		local iconIndex = data.Icon
		if data.IconMap and iconIndex then
			if type(iconIndex) == "number" then
				data.IconMap:Display(app.Main.Icon,iconIndex)
			elseif type(iconIndex) == "string" then
				data.IconMap:DisplayByKey(app.Main.Icon,iconIndex)
			end
		elseif type(iconIndex) == "string" then
			app.Main.Icon.Image = iconIndex
		else
			app.Main.Icon.Image = ""
		end

		local appTweenInfo = TweenInfo.new(0.18,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)

		local function updateState()
			local targetTrans = data.Open and 0 or (Lib.CheckMouseInGui(app.Main) and 0 or 1)
			local targetColor = data.Open and Settings.Theme.ButtonHover or Settings.Theme.Button
			service.TweenService:Create(app.Main,appTweenInfo,{BackgroundTransparency = targetTrans, BackgroundColor3 = targetColor}):Play()
		end

		local function enable(silent)
			if data.Open then return end
			data.Open = true
			updateState()
			if not silent then
				if data.Window then data.Window:Show() end
				if data.OnClick then data.OnClick(data.Open) end
			end
		end

		local function disable(silent)
			if not data.Open then return end
			data.Open = false
			updateState()
			if not silent then
				if data.Window then data.Window:Hide() end
				if data.OnClick then data.OnClick(data.Open) end
			end
		end

		updateState()

		local ySize = service.TextService:GetTextSize(data.Name,14,Enum.Font.SourceSans,Vector2.new(62,999999)).Y
		app.Main.Size = UDim2.new(1,0,0,math.clamp(46+ySize,60,74))
		app.Main.AppName.Text = data.Name

		app.Main.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				service.TweenService:Create(app.Main,appTweenInfo,{BackgroundTransparency = 0, BackgroundColor3 = Settings.Theme.ButtonHover}):Play()
			end
		end)


		app.Main.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local targetTrans = data.Open and 0 or 1
				local targetColor = data.Open and Settings.Theme.ButtonHover or Settings.Theme.Button
				service.TweenService:Create(app.Main,appTweenInfo,{BackgroundTransparency = targetTrans, BackgroundColor3 = targetColor}):Play()
			end
		end)

		app.Main.MouseButton1Click:Connect(function()
			if data.Open then disable() else enable() end
		end)

		local window = data.Window
		if window then
			window.OnActivate:Connect(function() enable(true) end)
			window.OnDeactivate:Connect(function() disable(true) end)
		end

		app.Visible = true
		app.Parent = Main.AppsContainer
		Main.AppsFrame.CanvasSize = UDim2.new(0,0,0,Main.AppsContainerGrid.AbsoluteCellCount.Y*82 + 8)

		control.Enable = enable
		control.Disable = disable
		Main.MenuApps[data.Name] = control
		return control
	end

	Main.SetMainGuiOpen = function(val)
		Main.MainGuiOpen = val

		Main.MainGui.OpenButton.Text = val and "Close" or "Dex"
		if val then Main.MainGui.OpenButton.MainFrame.Visible = true end
		Main.MainGui.OpenButton.MainFrame:TweenSize(
			val and UDim2.new(0,260,0,220) or UDim2.new(0,0,0,0),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quart,
			0.28,
			true
		)

		if Main.MainGuiMouseEvent then Main.MainGuiMouseEvent:Disconnect() end

		if not val then
			local startTime = tick()
			Main.MainGuiCloseTime = startTime
			coroutine.wrap(function()
				Lib.FastWait(0.28)
				if not Main.MainGuiOpen and startTime == Main.MainGuiCloseTime then Main.MainGui.OpenButton.MainFrame.Visible = false end
			end)()
		else
			Main.MainGuiMouseEvent = service.UserInputService.InputBegan:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not Lib.CheckMouseInGui(Main.MainGui.OpenButton) and not Lib.CheckMouseInGui(Main.MainGui.OpenButton.MainFrame) then

					Main.SetMainGuiOpen(false)
				end
			end)
		end
	end

	Main.AI = (function()
		local AI = {}
		local httpService = service.HttpService
		AI.History = {}
		AI.Running = false
		AI.MessageBubbles = {}
		AI.ChatMessages = nil
		AI.InputBox = nil
		AI.SendButton = nil
		AI.StatusLabel = nil
		AI.Window = nil
		AI.ModelDropdown = nil
		AI.ApiKeyBox = nil
		AI.SessionCancelled = false

		local ThemeText = Color3.fromRGB(236,236,240)
		local ThemeSubtle = Color3.fromRGB(170,170,180)
		local ThemeAccent = Color3.fromRGB(10,132,255)
		local ThemeUserBg = Color3.fromRGB(10,132,255)
		local ThemeBotBg = Color3.fromRGB(36,36,44)
		local ThemeToolBg = Color3.fromRGB(28,28,36)
		local ThemeBg = Color3.fromRGB(22,22,28)
		local ThemeInputBg = Color3.fromRGB(32,32,40)

		local Models = {
			{Id = "gemini-3.6-flash", Label = "Gemini 3.6 Flash (High Thinking)"},
			{Id = "gemini-3.5-flash-lite", Label = "Gemini 3.5 Flash Lite (Fast)"},
		}

		local function getPath(inst)
			if not inst then return "nil" end
			local parts = {}
			local cur = inst
			local safety = 0
			while cur and cur ~= game and safety < 40 do
				table.insert(parts, 1, cur.Name)
				cur = cur.Parent
				safety = safety + 1
			end
			if cur == game then
				return "game." .. table.concat(parts, ".")
			end
			return table.concat(parts, ".")
		end

		local function resolvePath(path)
			if not path or path == "" then return nil, "empty path" end
			if path == "game" then return game, nil end
			local start = 1
			local cur = game
			if path:sub(1,5) == "game." then
				start = 6
			elseif path:sub(1,10) == "workspace." then
				cur = workspace
				start = 11
			elseif path == "workspace" then
				return workspace, nil
			end
			local trimmed = path:sub(start)
			for seg in string.gmatch(trimmed, "([^%.]+)") do
				local ok, next = pcall(function() return cur:FindFirstChild(seg) end)
				if not ok or not next then
					if cur == game then
						local ok2, srv = pcall(function() return game:GetService(seg) end)
						if ok2 and srv then
							cur = srv
						else
							return nil, "could not find '" .. seg .. "' under " .. tostring(cur)
						end
					else
						return nil, "could not find '" .. seg .. "' under " .. tostring(cur)
					end
				else
					cur = next
				end
			end
			return cur, nil
		end

		local function safeSerialize(val)
			local t = typeof(val)
			if t == "Instance" then return getPath(val) end
			if t == "CFrame" then
				local x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22 = val:GetComponents()
				return string.format("CFrame(%.3f, %.3f, %.3f | rot: %.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f)",
					x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22)
			end
			if t == "Vector3" then return string.format("Vector3(%.3f, %.3f, %.3f)", val.X, val.Y, val.Z) end
			if t == "Vector2" then return string.format("Vector2(%.3f, %.3f)", val.X, val.Y) end
			if t == "Color3" then return string.format("Color3(%.3f, %.3f, %.3f)", val.R, val.G, val.B) end
			if t == "UDim2" then return string.format("UDim2(%.3f,%d,%.3f,%d)", val.X.Scale, val.X.Offset, val.Y.Scale, val.Y.Offset) end
			if t == "UDim" then return string.format("UDim(%.3f,%d)", val.Scale, val.Offset) end
			if t == "EnumItem" then return "Enum." .. tostring(val.EnumType) .. "." .. val.Name end
			if t == "boolean" or t == "number" or t == "string" then return val end
			if t == "table" then return val end
			return tostring(val)
		end

		local tools = {}

		tools.list_children = {
			description = "List the direct children of an instance at the given path. Returns names, class names, and whether each child has its own children. Use this to explore the workspace tree progressively.",
			parameters = {
				type = "object",
				properties = {
					path = {type = "string", description = "Instance path like 'game.Workspace' or 'game.Players.PlayerName'."},
					limit = {type = "integer", description = "Maximum children to return (default 100)."}
				},
				required = {"path"}
			},
			run = function(args)
				local inst, err = resolvePath(args.path)
				if err then return {error = err} end
				local limit = args.limit or 100
				local children = inst:GetChildren()
				local result = {path = getPath(inst), class = inst.ClassName, count = #children, children = {}}
				for i = 1, math.min(#children, limit) do
					local c = children[i]
					table.insert(result.children, {
						name = c.Name,
						class = c.ClassName,
						has_children = #c:GetChildren() > 0,
						path = getPath(c),
					})
				end
				if #children > limit then result.truncated = true end
				return result
			end
		}

		tools.get_properties = {
			description = "Get all readable properties of an instance at the given path. Handles CFrame, Vector3, Color3 etc. by returning serialized strings.",
			parameters = {
				type = "object",
				properties = {
					path = {type = "string"},
					property_names = {type = "array", items = {type = "string"}, description = "Optional filter for specific property names."}
				},
				required = {"path"}
			},
			run = function(args)
				local inst, err = resolvePath(args.path)
				if err then return {error = err} end
				local filter
				if args.property_names then filter = {} for _,n in ipairs(args.property_names) do filter[n] = true end end
				local result = {path = getPath(inst), class = inst.ClassName, properties = {}}
				local common = {"Name","ClassName","Parent","Archivable","Position","Size","CFrame","Anchored","CanCollide","Transparency","Color","Material","BrickColor","Orientation","Rotation","Velocity","Reflectance","CastShadow","Massless","Locked","Value","Text","TextColor3","BackgroundColor3","Visible","Enabled","Disabled","Source","Playing","SoundId","Volume","TimePosition","IsPlaying","AutoRotate","MaxForce","MaxTorque","Torque","Force","Attachment0","Attachment1"}
				for _, name in ipairs(common) do
					if not filter or filter[name] then
						local ok, val = pcall(function() return inst[name] end)
						if ok and val ~= nil then result.properties[name] = safeSerialize(val) end
					end
				end
				if filter then
					for k, _ in pairs(filter) do
						if result.properties[k] == nil then
							local ok, val = pcall(function() return inst[k] end)
							if ok and val ~= nil then result.properties[k] = safeSerialize(val) end
						end
					end
				end
				return result
			end
		}

		tools.get_attributes = {
			description = "Get all attributes of an instance.",
			parameters = {
				type = "object",
				properties = {path = {type = "string"}},
				required = {"path"}
			},
			run = function(args)
				local inst, err = resolvePath(args.path)
				if err then return {error = err} end
				local attrs = inst:GetAttributes()
				local result = {path = getPath(inst), attributes = {}}
				for k, v in pairs(attrs) do result.attributes[k] = safeSerialize(v) end
				return result
			end
		}

		tools.get_cframe = {
			description = "Get CFrame components (position + rotation) of a BasePart or Model. Also returns bounding box for models.",
			parameters = {
				type = "object",
				properties = {path = {type = "string"}},
				required = {"path"}
			},
			run = function(args)
				local inst, err = resolvePath(args.path)
				if err then return {error = err} end
				if inst:IsA("BasePart") then
					return {path = getPath(inst), cframe = safeSerialize(inst.CFrame), position = safeSerialize(inst.Position), size = safeSerialize(inst.Size)}
				elseif inst:IsA("Model") then
					local ok, pivot = pcall(function() return inst:GetPivot() end)
					local ok2, cf, sz = pcall(function() return inst:GetBoundingBox() end)
					return {
						path = getPath(inst),
						pivot = ok and safeSerialize(pivot) or nil,
						bounding_box_cf = ok2 and safeSerialize(cf) or nil,
						bounding_box_size = ok2 and safeSerialize(sz) or nil,
					}
				end
				return {error = "instance is neither BasePart nor Model"}
			end
		}

		tools.get_script_source = {
			description = "Get the source code of a LuaSourceContainer (LocalScript/ModuleScript/Script) via decompile if source isn't directly readable.",
			parameters = {
				type = "object",
				properties = {path = {type = "string"}},
				required = {"path"}
			},
			run = function(args)
				local inst, err = resolvePath(args.path)
				if err then return {error = err} end
				if not inst:IsA("LuaSourceContainer") then return {error = "not a script"} end
				local src
				local ok, s = pcall(function() return inst.Source end)
				if ok and s and s ~= "" then src = s end
				if not src and env.decompile then
					local ok2, out = pcall(env.decompile, inst)
					if ok2 then src = out end
				end
				if not src then return {error = "could not read source (decompiler unavailable)"} end
				if #src > 40000 then src = src:sub(1, 40000) .. "\n-- [truncated at 40k chars]" end
				return {path = getPath(inst), class = inst.ClassName, source = src}
			end
		}

		tools.open_script_in_notepad = {
			description = "Open a script's source in the Notepad app for the user to inspect.",
			parameters = {
				type = "object",
				properties = {path = {type = "string"}},
				required = {"path"}
			},
			run = function(args)
				local inst, err = resolvePath(args.path)
				if err then return {error = err} end
				if not inst:IsA("LuaSourceContainer") then return {error = "not a script"} end
				if ScriptViewer and ScriptViewer.ViewScript then
					pcall(ScriptViewer.ViewScript, inst)
					return {opened = true, path = getPath(inst)}
				end
				return {error = "notepad unavailable"}
			end
		}

		tools.copy_path = {
			description = "Copy the full path of an instance to the user's clipboard.",
			parameters = {
				type = "object",
				properties = {path = {type = "string"}},
				required = {"path"}
			},
			run = function(args)
				local inst, err = resolvePath(args.path)
				if err then return {error = err} end
				local p = getPath(inst)
				if env.setclipboard then pcall(env.setclipboard, p) end
				return {copied = p}
			end
		}

		tools.search = {
			description = "Search the entire DataModel for instances whose Name matches the query (case-insensitive substring). Returns up to `limit` results.",
			parameters = {
				type = "object",
				properties = {
					query = {type = "string"},
					class_filter = {type = "string", description = "Optional class name to filter results."},
					limit = {type = "integer"}
				},
				required = {"query"}
			},
			run = function(args)
				local q = string.lower(args.query or "")
				local limit = args.limit or 30
				local out = {}
				local function scan(root)
					if #out >= limit then return end
					for _, c in ipairs(root:GetChildren()) do
						if #out >= limit then return end
						if string.find(string.lower(c.Name), q, 1, true) then
							if not args.class_filter or c.ClassName == args.class_filter then
								table.insert(out, {name = c.Name, class = c.ClassName, path = getPath(c)})
							end
						end
						pcall(scan, c)
					end
				end
				scan(game)
				return {query = args.query, results = out, count = #out}
			end
		}

		tools.get_selected = {
			description = "Get the currently selected instances in the Dark Dex Explorer (what the user has clicked on).",
			run = function()
				if not selection or not selection.List then return {selected = {}, count = 0} end
				local out = {selected = {}}
				for _, node in ipairs(selection.List) do
					if node.Obj then
						table.insert(out.selected, {name = node.Obj.Name, class = node.Obj.ClassName, path = getPath(node.Obj)})
					end
				end
				out.count = #out.selected
				return out
			end
		}

		tools.select_instance = {
			description = "Select an instance in the Dark Dex Explorer (highlights the row and reveals it in the tree).",
			parameters = {
				type = "object",
				properties = {path = {type = "string"}},
				required = {"path"}
			},
			run = function(args)
				local inst, err = resolvePath(args.path)
				if err then return {error = err} end
				if selection and nodes and nodes[inst] and Explorer and Explorer.ViewNode then
					selection:Set(nodes[inst])
					pcall(Explorer.ViewNode, nodes[inst])
					return {selected = getPath(inst)}
				end
				return {error = "explorer not ready or instance not in tree"}
			end
		}

		tools.get_game_info = {
			description = "Get metadata about the currently running Roblox place: PlaceId, GameId (universe id), JobId (server id), place name, description, creator, current player count, workspace stats.",
			run = function()
				local info = {}
				info.place_id = game.PlaceId
				info.game_id = game.GameId
				local okJob, job = pcall(function() return game.JobId end)
				info.job_id = okJob and job or nil
				local okPlaceVersion, pv = pcall(function() return game.PlaceVersion end)
				info.place_version = okPlaceVersion and pv or nil
				local okPlayers, players = pcall(function() return service.Players:GetPlayers() end)
				if okPlayers then
					info.player_count = #players
					info.players = {}
					for _, p in ipairs(players) do
						table.insert(info.players, {name = p.Name, display_name = p.DisplayName, user_id = p.UserId})
					end
				end
				local okMp, product = pcall(function()
					return service.MarketplaceService:GetProductInfo(game.PlaceId)
				end)
				if okMp and product then
					info.name = product.Name
					info.description = product.Description
					info.creator = product.Creator and product.Creator.Name or nil
					info.creator_id = product.Creator and product.Creator.Id or nil
					info.creator_type = product.Creator and product.Creator.CreatorType or nil
					info.price = product.PriceInRobux
					info.icon_image_id = product.IconImageAssetId
				end
				local okWs, wsCount = pcall(function() return #workspace:GetChildren() end)
				if okWs then info.workspace_child_count = wsCount end
				local okWs2, wsDescCount = pcall(function() return #workspace:GetDescendants() end)
				if okWs2 then info.workspace_descendant_count = wsDescCount end
				return info
			end
		}

		tools.get_local_player = {
			description = "Get information about the local player: name, display name, user id, team, and character path if spawned.",
			run = function()
				local out = {}
				if not plr then return {error = "local player unavailable"} end
				out.name = plr.Name
				out.display_name = plr.DisplayName
				out.user_id = plr.UserId
				out.membership_type = tostring(plr.MembershipType)
				local okTeam, team = pcall(function() return plr.Team end)
				out.team = okTeam and team and team.Name or nil
				if plr.Character then
					out.character_path = getPath(plr.Character)
					local hum = plr.Character:FindFirstChildWhichIsA("Humanoid")
					if hum then
						out.health = hum.Health
						out.max_health = hum.MaxHealth
						out.walk_speed = hum.WalkSpeed
						out.jump_power = hum.JumpPower
					end
					local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
					if hrp then out.position = safeSerialize(hrp.Position) end
				end
				return out
			end
		}

		AI.Tools = tools

		local function buildToolDeclarations()
			local decls = {}
			for name, tool in pairs(tools) do
				local decl = {name = name, description = tool.description}
				local params = tool.parameters
				if params and params.properties and next(params.properties) ~= nil then
					decl.parameters = params
				end
				table.insert(decls, decl)
			end
			return {{function_declarations = decls}}
		end

		local SystemPrompt = [[You are Dex Copilot, an AI assistant embedded inside Dark Dex — an in-game Roblox debugging/exploration tool similar to Roblox Studio's Explorer/Properties/Console. The user runs Dark Dex to inspect the currently running Roblox place at runtime.

You have tools to explore the DataModel (workspace, services, players, GUIs, scripts, etc.) and to query game metadata. Prefer calling tools over guessing. Chain tool calls when you need more information — the user does not have to confirm each call. When you are done gathering context, produce a concise, well-formatted response.

Available tools include:
- list_children, get_properties, get_attributes, get_cframe: inspect instances progressively
- search: name-based DataModel search
- get_script_source, open_script_in_notepad: read or reveal script code
- copy_path, select_instance, get_selected: interact with the Dark Dex Explorer selection
- get_game_info: PlaceId, GameId, place name/description, creator, player list, workspace stats
- get_local_player: local player details (character path, health, walk speed, position)

Guidelines:
- Do NOT try to dump the entire tree with a single call. Use list_children progressively from `game`, expanding into services the user is asking about.
- When the user asks for properties, prefer get_properties with property_names filter to keep responses small.
- For scripts, use get_script_source. If the source is likely large, tell the user and offer to open it in Notepad via open_script_in_notepad.
- Use get_selected first when the user says "this" or "selected" without specifying a path.
- When copying a path, also print it in your reply.
- Reply in the same language as the user (Turkish or English). Keep responses tight; don't repeat tool results verbatim, summarize them.
- Your responses are rendered with markdown: **bold**, *italic*, `inline code`, and fenced ```code blocks``` all work. Use them to make output readable but don't over-format.]]

		local function callGemini(model, contents, apiKey)
			local url = "https://generativelanguage.googleapis.com/v1beta/models/" .. model .. ":generateContent?key=" .. apiKey
			local body = {
				contents = contents,
				systemInstruction = {parts = {{text = SystemPrompt}}},
				tools = buildToolDeclarations(),
				generationConfig = {
					maxOutputTokens = Settings.AI.MaxOutputTokens or 32768,
					temperature = 0.4,
					thinkingConfig = {thinkingBudget = Settings.AI.ThinkingLevel == "high" and -1 or 0},
				},
			}
			local jsonBody = httpService:JSONEncode(body)
			if not env.request then
				return nil, "executor does not expose an HTTP request function"
			end
			local ok, resp = pcall(env.request, {
				Url = url,
				Method = "POST",
				Headers = {["Content-Type"] = "application/json"},
				Body = jsonBody,
			})
			if not ok then return nil, "request failed: " .. tostring(resp) end
			if resp.StatusCode and resp.StatusCode >= 400 then
				return nil, "HTTP " .. tostring(resp.StatusCode) .. ": " .. tostring(resp.Body):sub(1,400)
			end
			local decodeOk, decoded = pcall(function() return httpService:JSONDecode(resp.Body) end)
			if not decodeOk then return nil, "invalid JSON response" end
			if decoded.error then return nil, "API error: " .. tostring(decoded.error.message or "unknown") end
			return decoded
		end

		local function xmlEscape(s)
			s = s:gsub("&","&amp;")
			s = s:gsub("<","&lt;")
			s = s:gsub(">","&gt;")
			return s
		end

		local function markdownToRich(text)
			if not text then return "" end
			text = tostring(text)
			-- Extract code blocks first with placeholders to protect them from other substitutions
			local codeBlocks = {}
			text = text:gsub("```(%w*)\n?(.-)```", function(_, code)
				local idx = #codeBlocks + 1
				codeBlocks[idx] = code
				return "\0BLOCK" .. idx .. "\0"
			end)
			local inlineCodes = {}
			text = text:gsub("`([^`\n]+)`", function(code)
				local idx = #inlineCodes + 1
				inlineCodes[idx] = code
				return "\0INLINE" .. idx .. "\0"
			end)
			-- Escape XML in the remaining prose
			text = xmlEscape(text)
			-- Bold: **text**
			text = text:gsub("%*%*(.-)%*%*", "<b>%1</b>")
			-- Italic: *text* (single) — but avoid matching leftover ** already handled
			text = text:gsub("%*([^%*\n]+)%*", "<i>%1</i>")
			-- Headings-ish: ##, ###  → just bold + slightly larger
			text = text:gsub("###%s(.-)\n", "<b>%1</b>\n")
			text = text:gsub("##%s(.-)\n", "<b>%1</b>\n")
			-- Restore inline codes
			text = text:gsub("\0INLINE(%d+)\0", function(idx)
				local raw = inlineCodes[tonumber(idx)] or ""
				return '<font face="RobotoMono" color="rgb(220,220,230)">' .. xmlEscape(raw) .. '</font>'
			end)
			-- Restore code blocks
			text = text:gsub("\0BLOCK(%d+)\0", function(idx)
				local raw = codeBlocks[tonumber(idx)] or ""
				return '<font face="RobotoMono" color="rgb(220,220,230)">' .. xmlEscape(raw) .. '</font>'
			end)
			return text
		end

		local function addBubble(kind, text)
			if not AI.ChatMessages then return end
			local frame = Instance.new("Frame")
			frame.BackgroundTransparency = 1
			frame.Size = UDim2.new(1,-16,0,0)
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.LayoutOrder = #AI.MessageBubbles + 1
			frame.Parent = AI.ChatMessages

			local pad = Instance.new("UIPadding", frame)
			pad.PaddingTop = UDim.new(0,4)
			pad.PaddingBottom = UDim.new(0,4)

			local bubble = Instance.new("Frame")
			bubble.BorderSizePixel = 0
			bubble.AutomaticSize = Enum.AutomaticSize.Y
			bubble.Size = UDim2.new(0.9,0,0,0)
			bubble.Parent = frame

			local corner = Instance.new("UICorner", bubble)
			corner.CornerRadius = UDim.new(0,10)

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.Gotham
			label.TextSize = 14
			label.TextWrapped = true
			label.RichText = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextYAlignment = Enum.TextYAlignment.Top
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.Size = UDim2.new(1,-16,0,0)
			label.Position = UDim2.new(0,8,0,6)
			if kind == "bot" then
				label.Text = markdownToRich(text or "")
			else
				label.Text = xmlEscape(text or "")
			end
			label.TextColor3 = ThemeText
			label.Parent = bubble

			local bLabelPad = Instance.new("UIPadding", label)
			bLabelPad.PaddingBottom = UDim.new(0,6)

			if kind == "user" then
				bubble.BackgroundColor3 = ThemeUserBg
				bubble.AnchorPoint = Vector2.new(1,0)
				bubble.Position = UDim2.new(1,0,0,0)
				label.TextColor3 = Color3.new(1,1,1)
			elseif kind == "tool" then
				bubble.BackgroundColor3 = ThemeToolBg
				bubble.Size = UDim2.new(1,0,0,0)
				label.Font = Enum.Font.Code
				label.TextSize = 12
				label.TextColor3 = ThemeSubtle
			else
				bubble.BackgroundColor3 = ThemeBotBg
				bubble.Size = UDim2.new(0.95,0,0,0)
			end

			table.insert(AI.MessageBubbles, {frame = frame, label = label, kind = kind})
			task.spawn(function()
				task.wait()
				if AI.ChatMessages then
					AI.ChatMessages.CanvasPosition = Vector2.new(0, AI.ChatMessages.AbsoluteCanvasSize.Y)
				end
			end)
			return label
		end

		local function setStatus(text)
			if AI.StatusLabel then AI.StatusLabel.Text = text or "" end
		end

		function AI.RunAgentLoop(userMessage)
			if AI.Running then return end
			AI.Running = true
			AI.SessionCancelled = false
			setStatus("Thinking...")

			local apiKey = Settings.AI.ApiKey
			if not apiKey or apiKey == "" then
				addBubble("bot", "⚠ Please set your Gemini API key in the settings panel (top of the AI window).")
				AI.Running = false
				setStatus("")
				return
			end

			local model = Settings.AI.Model or "gemini-3.6-flash"

			table.insert(AI.History, {role = "user", parts = {{text = userMessage}}})

			local iterations = 0
			local maxIter = Settings.AI.MaxIterations or 12
			while iterations < maxIter and not AI.SessionCancelled do
				iterations = iterations + 1
				local decoded, err = callGemini(model, AI.History, apiKey)
				if not decoded then
					addBubble("bot", "⚠ " .. tostring(err))
					break
				end
				local cand = decoded.candidates and decoded.candidates[1]
				if not cand or not cand.content or not cand.content.parts then
					addBubble("bot", "⚠ Empty response from Gemini.")
					break
				end
				local parts = cand.content.parts
				local functionCalls = {}
				local textOut = {}
				for _, part in ipairs(parts) do
					if part.functionCall then
						table.insert(functionCalls, part.functionCall)
					elseif part.text then
						table.insert(textOut, part.text)
					end
				end
				table.insert(AI.History, {role = "model", parts = parts})

				for _, p in ipairs(parts) do
					if p.functionCall and p.functionCall.args and next(p.functionCall.args) == nil then
						p.functionCall.args = nil
					end
				end

				if #textOut > 0 then
					addBubble("bot", table.concat(textOut, "\n"))
				end

				if #functionCalls == 0 then break end

				local respParts = {}
				for _, fc in ipairs(functionCalls) do
					local tool = tools[fc.name]
					addBubble("tool", "› " .. fc.name .. "(" .. httpService:JSONEncode(fc.args or {}):sub(1,200) .. ")")
					setStatus("Calling tool: " .. fc.name)
					local result
					if not tool then
						result = {error = "unknown tool: " .. tostring(fc.name)}
					else
						local ok, out = pcall(tool.run, fc.args or {})
						if ok then result = out else result = {error = tostring(out)} end
					end
					table.insert(respParts, {functionResponse = {name = fc.name, response = {content = result}}})
				end
				table.insert(AI.History, {role = "user", parts = respParts})
				setStatus("Thinking...")
			end

			if iterations >= maxIter and not AI.SessionCancelled then
				addBubble("bot", "⚠ Reached max iterations (" .. maxIter .. "). Ask me to continue if you want more.")
			end

			AI.Running = false
			setStatus("")
		end

		function AI.Send()
			if AI.Running then return end
			if not AI.InputBox then return end
			local text = AI.InputBox.Text
			if not text or text == "" then return end
			AI.InputBox.Text = ""
			addBubble("user", text)
			task.spawn(AI.RunAgentLoop, text)
		end

		function AI.Clear()
			AI.History = {}
			if AI.ChatMessages then
				for _, child in ipairs(AI.ChatMessages:GetChildren()) do
					if child:IsA("Frame") then child:Destroy() end
				end
			end
			AI.MessageBubbles = {}
		end

		function AI.Init()
			local window = Lib.Window.new()
			window:SetTitle("AI Copilot")
			window:Resize(420, 520)
			AI.Window = window

			local content = window.GuiElems.Content
			content.BackgroundColor3 = ThemeBg

			-- Settings bar (model dropdown + api key)
			local settingsBar = Instance.new("Frame")
			settingsBar.BackgroundColor3 = Color3.fromRGB(26,26,32)
			settingsBar.BorderSizePixel = 0
			settingsBar.Size = UDim2.new(1,0,0,58)
			settingsBar.Parent = content

			local modelLabel = Instance.new("TextLabel", settingsBar)
			modelLabel.BackgroundTransparency = 1
			modelLabel.Font = Enum.Font.GothamMedium
			modelLabel.TextSize = 11
			modelLabel.TextColor3 = ThemeSubtle
			modelLabel.TextXAlignment = Enum.TextXAlignment.Left
			modelLabel.Position = UDim2.new(0,10,0,4)
			modelLabel.Size = UDim2.new(0,60,0,12)
			modelLabel.Text = "MODEL"

			local modelButton = Instance.new("TextButton", settingsBar)
			modelButton.BackgroundColor3 = ThemeInputBg
			modelButton.BorderSizePixel = 0
			modelButton.Font = Enum.Font.Gotham
			modelButton.TextSize = 12
			modelButton.TextColor3 = ThemeText
			modelButton.TextXAlignment = Enum.TextXAlignment.Left
			modelButton.Position = UDim2.new(0,10,0,16)
			modelButton.Size = UDim2.new(0.5,-14,0,20)
			modelButton.AutoButtonColor = false
			local mbCorner = Instance.new("UICorner", modelButton)
			mbCorner.CornerRadius = UDim.new(0,6)
			local mbPad = Instance.new("UIPadding", modelButton)
			mbPad.PaddingLeft = UDim.new(0,8)
			mbPad.PaddingRight = UDim.new(0,8)
			AI.ModelDropdown = modelButton

			local function refreshModelLabel()
				local id = Settings.AI.Model
				for _, m in ipairs(Models) do if m.Id == id then modelButton.Text = m.Label return end end
				modelButton.Text = id
			end
			refreshModelLabel()

			modelButton.MouseButton1Click:Connect(function()
				local idx = 1
				for i, m in ipairs(Models) do if m.Id == Settings.AI.Model then idx = i break end end
				local next = Models[(idx % #Models) + 1]
				Settings.AI.Model = next.Id
				refreshModelLabel()
				if Main.SaveSettings then pcall(Main.SaveSettings) end
			end)

			local keyLabel = Instance.new("TextLabel", settingsBar)
			keyLabel.BackgroundTransparency = 1
			keyLabel.Font = Enum.Font.GothamMedium
			keyLabel.TextSize = 11
			keyLabel.TextColor3 = ThemeSubtle
			keyLabel.TextXAlignment = Enum.TextXAlignment.Left
			keyLabel.Position = UDim2.new(0.5,4,0,4)
			keyLabel.Size = UDim2.new(0.5,-14,0,12)
			keyLabel.Text = "API KEY"

			local keyBox = Instance.new("TextBox", settingsBar)
			keyBox.BackgroundColor3 = ThemeInputBg
			keyBox.BorderSizePixel = 0
			keyBox.Font = Enum.Font.Code
			keyBox.TextSize = 12
			keyBox.TextColor3 = ThemeText
			keyBox.PlaceholderText = "Paste Gemini API key…"
			keyBox.PlaceholderColor3 = Color3.fromRGB(100,100,110)
			keyBox.TextXAlignment = Enum.TextXAlignment.Left
			keyBox.ClearTextOnFocus = false
			keyBox.Position = UDim2.new(0.5,4,0,16)
			keyBox.Size = UDim2.new(0.5,-14,0,20)
			keyBox.Text = Settings.AI.ApiKey or ""
			local kbCorner = Instance.new("UICorner", keyBox)
			kbCorner.CornerRadius = UDim.new(0,6)
			local kbPad = Instance.new("UIPadding", keyBox)
			kbPad.PaddingLeft = UDim.new(0,8)
			kbPad.PaddingRight = UDim.new(0,8)
			AI.ApiKeyBox = keyBox
			AI._SaveToken = 0
			keyBox:GetPropertyChangedSignal("Text"):Connect(function()
				Settings.AI.ApiKey = keyBox.Text
				AI._SaveToken = AI._SaveToken + 1
				local myToken = AI._SaveToken
				task.delay(0.75, function()
					if myToken == AI._SaveToken and Main.SaveSettings then pcall(Main.SaveSettings) end
				end)
			end)

			-- Clear + status
			local clearBtn = Instance.new("TextButton", settingsBar)
			clearBtn.BackgroundColor3 = ThemeInputBg
			clearBtn.BorderSizePixel = 0
			clearBtn.Font = Enum.Font.GothamMedium
			clearBtn.TextSize = 11
			clearBtn.TextColor3 = ThemeSubtle
			clearBtn.Position = UDim2.new(0,10,0,40)
			clearBtn.Size = UDim2.new(0,70,0,14)
			clearBtn.AutoButtonColor = false
			clearBtn.Text = "Clear chat"
			local cbCorner = Instance.new("UICorner", clearBtn)
			cbCorner.CornerRadius = UDim.new(0,4)
			clearBtn.MouseButton1Click:Connect(AI.Clear)

			local statusLabel = Instance.new("TextLabel", settingsBar)
			statusLabel.BackgroundTransparency = 1
			statusLabel.Font = Enum.Font.Gotham
			statusLabel.TextSize = 11
			statusLabel.TextColor3 = ThemeAccent
			statusLabel.TextXAlignment = Enum.TextXAlignment.Right
			statusLabel.Position = UDim2.new(0.5,4,0,40)
			statusLabel.Size = UDim2.new(0.5,-14,0,14)
			statusLabel.Text = ""
			AI.StatusLabel = statusLabel

			-- Chat area
			local chatFrame = Instance.new("ScrollingFrame")
			chatFrame.BackgroundTransparency = 1
			chatFrame.BorderSizePixel = 0
			chatFrame.Position = UDim2.new(0,0,0,60)
			chatFrame.Size = UDim2.new(1,0,1,-108)
			chatFrame.CanvasSize = UDim2.new(0,0,0,0)
			chatFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
			chatFrame.ScrollBarThickness = 4
			chatFrame.ScrollBarImageColor3 = Color3.fromRGB(80,80,90)
			chatFrame.Parent = content
			local layout = Instance.new("UIListLayout", chatFrame)
			layout.Padding = UDim.new(0,6)
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			local chatPad = Instance.new("UIPadding", chatFrame)
			chatPad.PaddingLeft = UDim.new(0,8)
			chatPad.PaddingRight = UDim.new(0,8)
			chatPad.PaddingTop = UDim.new(0,8)
			chatPad.PaddingBottom = UDim.new(0,8)
			AI.ChatMessages = chatFrame

			-- Input area
			local inputBar = Instance.new("Frame")
			inputBar.BackgroundColor3 = Color3.fromRGB(26,26,32)
			inputBar.BorderSizePixel = 0
			inputBar.Position = UDim2.new(0,0,1,-48)
			inputBar.Size = UDim2.new(1,0,0,48)
			inputBar.Parent = content

			local inputBox = Instance.new("TextBox", inputBar)
			inputBox.BackgroundColor3 = ThemeInputBg
			inputBox.BorderSizePixel = 0
			inputBox.Font = Enum.Font.Gotham
			inputBox.TextSize = 14
			inputBox.TextColor3 = ThemeText
			inputBox.PlaceholderText = "Ask about the workspace, scripts, properties…"
			inputBox.PlaceholderColor3 = Color3.fromRGB(110,110,120)
			inputBox.TextXAlignment = Enum.TextXAlignment.Left
			inputBox.TextYAlignment = Enum.TextYAlignment.Center
			inputBox.ClearTextOnFocus = false
			inputBox.MultiLine = false
			inputBox.Position = UDim2.new(0,10,0,10)
			inputBox.Size = UDim2.new(1,-90,0,28)
			inputBox.Text = ""
			local ibCorner = Instance.new("UICorner", inputBox)
			ibCorner.CornerRadius = UDim.new(0,8)
			local ibPad = Instance.new("UIPadding", inputBox)
			ibPad.PaddingLeft = UDim.new(0,10)
			ibPad.PaddingRight = UDim.new(0,10)
			AI.InputBox = inputBox

			local sendBtn = Instance.new("TextButton", inputBar)
			sendBtn.BackgroundColor3 = ThemeAccent
			sendBtn.BorderSizePixel = 0
			sendBtn.Font = Enum.Font.GothamBold
			sendBtn.TextSize = 13
			sendBtn.TextColor3 = Color3.new(1,1,1)
			sendBtn.Text = "Send"
			sendBtn.AutoButtonColor = false
			sendBtn.Position = UDim2.new(1,-74,0,10)
			sendBtn.Size = UDim2.new(0,64,0,28)
			local sbCorner = Instance.new("UICorner", sendBtn)
			sbCorner.CornerRadius = UDim.new(0,8)
			sendBtn.MouseButton1Click:Connect(AI.Send)
			AI.SendButton = sendBtn

			inputBox.FocusLost:Connect(function(enterPressed)
				if enterPressed then AI.Send() end
			end)

			addBubble("bot", "Hi — I'm your Dex Copilot. Set your Gemini API key above (once) and ask me anything about this game's DataModel. I can list children, inspect properties, read scripts, get CFrames, and more.")
		end

		return AI
	end)()

	Main.CreateMainGui = function()
		local gui = create({
			{1,"ScreenGui",{IgnoreGuiInset=true,Name="MainMenu",}},
			{2,"TextButton",{AnchorPoint=Vector2.new(0.5,0),AutoButtonColor=false,BackgroundColor3=Color3.fromRGB(14,14,20),BorderSizePixel=0,Font=Enum.Font.GothamBold,Name="OpenButton",Parent={1},Position=UDim2.new(0.5,0,0,8),Size=UDim2.new(0,120,0,32),Text="Dex",TextColor3=Color3.fromRGB(236,236,240),TextSize=14,TextTransparency=0,}},
			{3,"UICorner",{CornerRadius=UDim.new(1,0),Parent={2},}},
			{101,"UIStroke",{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Color=Color3.fromRGB(54,54,66),Thickness=1,Transparency=0.35,Parent={2},}},
			{4,"Frame",{AnchorPoint=Vector2.new(0.5,0),BackgroundColor3=Color3.fromRGB(22,22,28),ClipsDescendants=true,Name="MainFrame",Parent={2},Position=UDim2.new(0.5,0,1,6),Size=UDim2.new(0,260,0,220),}},
			{5,"UICorner",{CornerRadius=UDim.new(0,14),Parent={4},}},
			{104,"UIStroke",{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Color=Color3.fromRGB(50,50,62),Thickness=1,Transparency=0.4,Parent={4},}},
			{6,"Frame",{BackgroundColor3=Color3.fromRGB(28,28,36),BorderSizePixel=0,Name="BottomFrame",Parent={4},Position=UDim2.new(0,0,1,-28),Size=UDim2.new(1,0,0,28),}},
			{7,"UICorner",{CornerRadius=UDim.new(0,14),Parent={6},}},
			{8,"Frame",{BackgroundColor3=Color3.fromRGB(28,28,36),BorderSizePixel=0,Name="CoverFrame",Parent={6},Size=UDim2.new(1,0,0,8),}},
			{9,"Frame",{BackgroundColor3=Color3.fromRGB(46,46,56),BorderSizePixel=0,Name="Line",Parent={8},Position=UDim2.new(0,10,0,-1),Size=UDim2.new(1,-20,0,1),}},
			{10,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Settings",Parent={6},Position=UDim2.new(1,-54,0,2),Size=UDim2.new(0,24,0,24),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,}},
			{11,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image="rbxassetid://6578871732",ImageColor3=Color3.fromRGB(236,236,240),ImageTransparency=0.2,Name="Icon",Parent={10},Position=UDim2.new(0,4,0,4),Size=UDim2.new(0,16,0,16),}},
			{12,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Information",Parent={6},Position=UDim2.new(1,-28,0,2),Size=UDim2.new(0,24,0,24),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,}},
			{13,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image="rbxassetid://6578933307",ImageColor3=Color3.fromRGB(236,236,240),ImageTransparency=0.2,Name="Icon",Parent={12},Position=UDim2.new(0,4,0,4),Size=UDim2.new(0,16,0,16),}},
			{14,"ScrollingFrame",{Active=true,AnchorPoint=Vector2.new(0.5,0),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderColor3=Color3.fromRGB(28,28,36),BorderSizePixel=0,Name="AppsFrame",Parent={4},Position=UDim2.new(0.5,0,0,0),ScrollBarImageColor3=Color3.fromRGB(90,90,104),ScrollBarThickness=3,Size=UDim2.new(0,258,1,-30),}},
			{15,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Container",Parent={14},Position=UDim2.new(0,10,0,10),Size=UDim2.new(1,-20,0,2),}},
			{16,"UIGridLayout",{CellSize=UDim2.new(0,72,0,80),CellPadding=UDim2.new(0,6,0,6),Parent={15},SortOrder=2,}},
			{17,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="App",Parent={1},Size=UDim2.new(0,100,0,100),Visible=false,}},
			{18,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.fromRGB(38,38,48),BorderSizePixel=0,Font=Enum.Font.Gotham,Name="Main",Parent={17},Size=UDim2.new(1,0,0,60),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,BackgroundTransparency=1,}},
			{105,"UICorner",{CornerRadius=UDim.new(0,10),Parent={18},}},
			{19,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image="rbxassetid://6579106223",ImageRectSize=Vector2.new(32,32),Name="Icon",Parent={18},Position=UDim2.new(0.5,-16,0,6),ScaleType=4,Size=UDim2.new(0,32,0,32),}},
			{20,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=Enum.Font.Gotham,Name="AppName",Parent={18},Position=UDim2.new(0,2,0,42),Size=UDim2.new(1,-4,1,-44),Text="Explorer",TextColor3=Color3.fromRGB(230,230,236),TextSize=12,TextTransparency=0.05,TextTruncate=1,TextWrapped=true,TextYAlignment=0,}},
		})
		Main.MainGui = gui
		Main.AppsFrame = gui.OpenButton.MainFrame.AppsFrame
		Main.AppsContainer = Main.AppsFrame.Container
		Main.AppsContainerGrid = Main.AppsContainer.UIGridLayout
		Main.AppTemplate = gui.App
		Main.MainGuiOpen = false

		local openButton = gui.OpenButton
		openButton.BackgroundTransparency = 0
		openButton.MainFrame.Size = UDim2.new(0,0,0,0)
		openButton.MainFrame.Visible = false

		local pillIdleSize = UDim2.new(0,120,0,32)
		local pillHoverSize = UDim2.new(0,128,0,34)
		local pillIdleColor = Color3.fromRGB(14,14,20)
		local pillHoverColor = Color3.fromRGB(26,26,34)
		local pillTweenInfo = TweenInfo.new(0.22,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)

		openButton.MouseButton1Click:Connect(function()
			Main.SetMainGuiOpen(not Main.MainGuiOpen)
		end)

		openButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				service.TweenService:Create(openButton,pillTweenInfo,{Size = pillHoverSize, BackgroundColor3 = pillHoverColor}):Play()
			end
		end)

		openButton.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				service.TweenService:Create(openButton,pillTweenInfo,{Size = pillIdleSize, BackgroundColor3 = pillIdleColor}):Play()
			end
		end)
		
		local infoDexIntro, isInfoCD
		
		openButton.MainFrame.BottomFrame.Settings.Visible = false -- hide it for now
		
		openButton.MainFrame.BottomFrame.Information.MouseButton1Click:Connect(function()
			local duration = 1
			local Infos = {
				"Contributors >>",
				"Toon (IY Dex and PRs)",
				"Moon (Dex)",
				"Cazan (3D Preview)",
			}
			
			if isInfoCD then return end
			isInfoCD = true
			if not infoDexIntro then
				infoDexIntro = Main.CreateIntro("Running")
				
				coroutine.wrap(function()
					while infoDexIntro do
						for i,text in Infos do
							if not infoDexIntro then break end
							infoDexIntro.SetProgress(text,(1 / #Infos) * i)
							task.wait(duration)
						end
					end
				end)()
				
				Lib.FastWait(1.5)
				isInfoCD = false
			else
				coroutine.wrap(function()
					infoDexIntro.Close()
					infoDexIntro = nil
					
					Lib.FastWait(1.5)
					isInfoCD = false
				end)()
			end
		end)

		-- Create Main Apps
		Main.CreateApp({Name = "Explorer", IconMap = Main.LargeIcons, Icon = "Explorer", Open = true, Window = Explorer.Window})

		Main.CreateApp({Name = "Properties", IconMap = Main.LargeIcons, Icon = "Properties", Open = true, Window = Properties.Window})

		local cptsOnMouseClick = nil
		Main.CreateApp({Name = "Click part to select", IconMap = Main.LargeIcons, Icon = 6, OnClick = function(callback)
			if callback then
				local mouse = Main.Mouse
				cptsOnMouseClick = mouse.Button1Down:Connect(function()
					pcall(function()
						local object = mouse.Target
						if nodes[object] then
							selection:Set(nodes[object])
							Explorer.ViewNode(nodes[object])
						end
					end)
				end)
			else if cptsOnMouseClick ~= nil then cptsOnMouseClick:Disconnect() cptsOnMouseClick = nil end end
		end})

		Main.CreateApp({Name = "Notepad", IconMap = Main.LargeIcons, Icon = "Script_Viewer", Window = ScriptViewer.Window})
		
		Main.CreateApp({Name = "Console", IconMap = Main.LargeIcons, Icon = "Output", Window = Console.Window})
		
		Main.CreateApp({Name = "Save Instance", IconMap = Main.LargeIcons, Icon = "Watcher", Window = SaveInstance.Window})
		
		Main.CreateApp({Name = "3D Viewer", IconMap = Explorer.LegacyClassIcons, Icon = 54, Window = ModelViewer.Window})

		Main.AI.Init()
		Main.CreateApp({Name = "AI Copilot", IconMap = Main.LargeIcons, Icon = "Script_Viewer", Window = Main.AI.Window})

		--Main.CreateApp({Name = "Secret Service Panel", IconMap = Main.LargeIcons, Icon = "Output", Window = SecretServicePanel.Window})


		Lib.ShowGui(gui)
	end

	Main.SetupFilesystem = function()
		if not env.writefile or not env.makefolder then return end

		local writefile,makefolder = env.writefile,env.makefolder

		makefolder("dex")
		makefolder("dex/assets")
		makefolder("dex/saved")
		makefolder("dex/plugins")
		makefolder("dex/ModuleCache")
	end

	Main.LocalDepsUpToDate = function()
		return Main.DepsVersionData and Main.ClientVersion == Main.DepsVersionData[1]
	end

	Main.Init = function()
		Main.Elevated = pcall(function() local a = game:GetService("CoreGui"):GetFullName() end)
		
		if writefile and isfile and not isfile("DexSettings.json") then
			writefile("DexSettings.json", Main.ExportSettings())
		end
		
		Main.InitEnv()
		Main.LoadSettings()
		
		Main.SetupFilesystem()

		-- Load Lib
		local intro = Main.CreateIntro("Initializing Library")
		Lib = Main.LoadModule("Lib")
		Lib.FastWait()

		-- Init other stuff
		Main.IncompatibleTest()

		-- Init icons
		Main.MiscIcons = Lib.IconMap.new("rbxassetid://6511490623",256,256,16,16)
		Main.MiscIcons:SetDict({
			Reference = 0,             Cut = 1,                         Cut_Disabled = 2,      Copy = 3,               Copy_Disabled = 4,    Paste = 5,                Paste_Disabled = 6,
			Delete = 7,                Delete_Disabled = 8,             Group = 9,             Group_Disabled = 10,    Ungroup = 11,         Ungroup_Disabled = 12,    TeleportTo = 13,
			Rename = 14,               JumpToParent = 15,               ExploreData = 16,      Save = 17,              CallFunction = 18,    CallRemote = 19,          Undo = 20,
			Undo_Disabled = 21,        Redo = 22,                       Redo_Disabled = 23,    Expand_Over = 24,       Expand = 25,          Collapse_Over = 26,       Collapse = 27,
			SelectChildren = 28,       SelectChildren_Disabled = 29,    InsertObject = 30,     ViewScript = 31,        AddStar = 32,         RemoveStar = 33,          Script_Disabled = 34,
			LocalScript_Disabled = 35, Play = 36,                       Pause = 37,            Rename_Disabled = 38,   Empty = 1000
		})
		Main.LargeIcons = Lib.IconMap.new("rbxassetid://6579106223",256,256,32,32)
		Main.LargeIcons:SetDict({
			Explorer = 0, Properties = 1, Script_Viewer = 2, Watcher = 3, Output = 4
		})
		
		--[[ Loading bypasses
		intro.SetProgress("Loading Adonis Bypass",0.1)
		pcall(Main.LoadAdonisBypass)
		
		intro.SetProgress("Loading GC Bypass",0.2)
		pcall(Main.LoadGCBypass)]]

		-- Fetch version if needed
		intro.SetProgress("Fetching Roblox Version",0.3)
		if Main.Elevated then
			local fileVer = Lib.ReadFile("dex/deps_version.dat")
			Main.ClientVersion = Version()
			if fileVer then
				Main.DepsVersionData = string.split(fileVer,"\n")
				if Main.LocalDepsUpToDate() then
					Main.RobloxVersion = Main.DepsVersionData[2]
				end
			end
			
			Main.RobloxVersion = Main.RobloxVersion or oldgame:HttpGet("https://clientsettings.roblox.com/v2/client-version/WindowsStudio64/channel/LIVE"):match("(version%-[%w]+)")
		end

		-- Fetch external deps
		intro.SetProgress("Fetching API",0.35)
		API = Main.FetchAPI(
			function()
				intro.SetProgress("Fetching API, Please Wait.",0.4)
			end,
			function()
				intro.SetProgress("Fetching API, Please Wait Due To Huge API File To Download.",0.45)
			end,
			function()
				intro.SetProgress("Fetching API, LOL STILL DOWNlOADING? bad wifi xD",0.475)
			end
		)
		Lib.FastWait()
		intro.SetProgress("Fetching RMD",0.5)
		RMD = Main.FetchRMD()
		Lib.FastWait()

		-- Save external deps locally if needed
		if Main.Elevated and env.writefile and not Main.LocalDepsUpToDate() then
			env.writefile("dex/deps_version.dat",tostring(Main.ClientVersion) .. "\n" .. tostring(Main.RobloxVersion))
			env.writefile("dex/rbx_api.dat",Main.RawAPI)
			env.writefile("dex/rbx_rmd.dat",Main.RawRMD)
		end

		-- Load other modules
		intro.SetProgress("Loading Modules",0.75)
		Main.AppControls.Lib.InitDeps(Main.GetInitDeps()) -- Missing deps now available
		Main.LoadModules()
		Lib.FastWait()

		-- Init other modules
		intro.SetProgress("Initializing Modules",0.9)
		Explorer.Init()
		Properties.Init()
		ScriptViewer.Init()
		Console.Init()
		SaveInstance.Init()
		ModelViewer.Init()
		
		--SecretServicePanel.Init()
		
		Lib.FastWait()

		-- Done
		intro.SetProgress("Complete",1)
		coroutine.wrap(function()
			Lib.FastWait(1.25)
			intro.Close()
		end)()

		-- Init window system, create main menu, show explorer and properties
		Lib.Window.Init()
		Main.CreateMainGui()
		Explorer.Window:Show({Align = "right", Pos = 1, Size = 0.5, Silent = true})
		Properties.Window:Show({Align = "right", Pos = 2, Size = 0.5, Silent = true})
		
		Lib.DeferFunc(function() Lib.Window.ToggleSide("right") end)
	end

	return Main
end)()

-- Start
Main.Init()
