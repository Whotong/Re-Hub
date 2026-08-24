--!strict
-- Re: Hub — Main Loader
-- RULE: All files must be linked via loadstring(game:HttpGet(...)).
--       No inlined code. Every dependency is fetched at runtime from BASE_URL.
-- Detects game, loads library, builds built-in tabs, injects game-specific tab

local HttpGet = game.HttpGet
-- Two-repo separation: library lives in DataBase, hub files in Re-Hub.
local LIB_URL = "https://raw.githubusercontent.com/Whotong/DataBase/main/Library/ReHubLib.lua"
local REPO_URL = "https://raw.githubusercontent.com/Whotong/Re-Hub/main/"

-- ═══════════════════════════════════════════
-- WAIT FOR GAME LOAD
-- ═══════════════════════════════════════════
repeat task.wait() until game:IsLoaded()

-- ═══════════════════════════════════════════
-- LOAD GUI LIBRARY
-- ═══════════════════════════════════════════
local Library = loadstring(HttpGet(game, LIB_URL))()

-- ═══════════════════════════════════════════
-- CREATE WINDOW
-- ═══════════════════════════════════════════
local Window = Library:Start({
	Name = "Re: Hub",
	Color = Color3.fromRGB(0, 230, 118),
	SaveFolder = "Re-Hub",
	CloseCallBack = function()
		-- Cleanup on close
	end
})

-- ═══════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════
-- HOME TAB
-- ═══════════════════════════════════════════
local HomeTab = Window:MakeTab("Home") do
	local Info = HomeTab:Section({ Title = "Information" })

	Info:Paragraph({
		Title = "Welcome to Re: Hub",
		Content = "The script hub is loaded. Select a game tab to begin."
	})

	Info:Seperator("Status")

	local PlayerCount = Info:Paragraph({
		Title = "Players",
		Content = "Loading..."
	})
	task.spawn(function()
		while task.wait(3) do
			local count = #Players:GetPlayers()
			PlayerCount:Set({ Title = "Players", Content = tostring(count) .. " online" })
		end
	end)

	local ServerTime = Info:Paragraph({
		Title = "Server Time",
		Content = ""
	})
	task.spawn(function()
		while task.wait(2) do
			ServerTime:Set({ Title = "Server Time", Content = tostring(Lighting.TimeOfDay) })
		end
	end)

	Info:Seperator("Links")

	local Discord = ""
	Info:Button({
		Title = "Discord",
		Content = "Click to copy invite link",
		Callback = function()
			if setclipboard then
				setclipboard(Discord)
				Library:Notify({ Title = "Re: Hub", Content = "Discord link copied!", Delay = 3 })
			end
		end
	})

	Info:Button({
		Title = "GitHub",
		Content = "Click to copy repo link",
		Callback = function()
			if setclipboard then
				setclipboard("https://github.com/Whotong/Re-Hub")
				Library:Notify({ Title = "Re: Hub", Content = "GitHub link copied!", Delay = 3 })
			end
		end
	})

	Info:Seperator("Keybind")

	local keybindPara = Info:Paragraph({
		Title = "Toggle UI: " .. Window:GetToggleKey().Name,
		Content = "Press this key to show or hide the hub"
	})

	Info:Button({
		Title = "Change Keybind",
		Content = "Press any key within 5 seconds",
		Callback = function()
			Library:Notify({ Title = "Re: Hub", Content = "Press any key to set the toggle key...", Delay = 5 })
			Window:CaptureNextKey(function(key)
				if key then
					Window:SetToggleKey(key)
					keybindPara:Set({ Title = "Toggle UI: " .. key.Name, Content = "Press this key to show or hide the hub" })
					Library:Notify({ Title = "Re: Hub", Content = "Toggle key set to " .. key.Name, Delay = 3 })
				else
					Library:Notify({ Title = "Re: Hub", Content = "Keybind capture timed out", Delay = 3 })
				end
			end)
		end
	})
end

-- ═══════════════════════════════════════════
-- SETTINGS TAB
-- ═══════════════════════════════════════════
local SettingsTab = Window:MakeTab("Settings") do
	local General = SettingsTab:Section({ Title = "General" })

	General:Toggle({
		Title = "Notifications",
		Content = "Show load and event notifications",
		Default = true,
		Callback = function(v) end,
		Flag = "ReHub/Notifications"
	})

	local antiIdleConn = nil
	General:Toggle({
		Title = "Anti-Idle",
		Content = "Prevent automatic kick on idle",
		Default = false,
		Callback = function(v)
			if v and not antiIdleConn then
				antiIdleConn = LocalPlayer.Idled:Connect(function()
					local VirtualUser = game:GetService("VirtualUser")
					VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
					task.wait(1)
					VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
				end)
			elseif not v and antiIdleConn then
				antiIdleConn:Disconnect()
				antiIdleConn = nil
			end
		end,
		Flag = "ReHub/AntiIdle"
	})

	local Visuals = SettingsTab:Section({ Title = "Visuals" })

	Visuals:Dropdown({
		Title = "Theme Accent",
		Options = Library:GetThemeNames(),
		Default = { "Violet" },
		Callback = function(v)
			if type(v) == "string" then
				Library:SetTheme(v)
			end
		end
	})

	Visuals:Slider({
		Title = "UI Transparency",
		Min = 0,
		Max = 100,
		Increment = 5,
		Default = 0,
		Callback = function(v)
			Library:SetTransparency(v)
		end
	})

	local Advanced = SettingsTab:Section({ Title = "Advanced" })

	Advanced:Button({
		Title = "Destroy UI",
		Content = "Completely remove Re: Hub",
		Callback = function()
			Library:CloseUI()
		end
	})

	Advanced:Button({
		Title = "Rejoin Server",
		Content = "Reconnect to current server",
		Callback = function()
			game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
		end
	})
end

-- ═══════════════════════════════════════════
-- GAME DETECTION & INJECTION
-- ═══════════════════════════════════════════
local Games = loadstring(HttpGet(game, REPO_URL .. "gamelist.lua"))()
local gameEntry = Games[game.GameId]

if gameEntry then
	if typeof(gameEntry) == "string" then
		-- Repo-relative path — prepend REPO_URL, fetch and execute, passing Window
		local gameScript = loadstring(HttpGet(game, REPO_URL .. gameEntry))
		if gameScript then
			gameScript(Window)
		end
	elseif typeof(gameEntry) == "function" then
		-- Inline function
		gameEntry(Window)
	end
	-- gameEntry == true means supported but no script yet (silent)
end

return Library
