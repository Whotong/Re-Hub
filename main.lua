--!strict
-- Re: Hub — Main Loader
-- RULE: All files must be linked via loadstring(game:HttpGet(...)).
--       No inlined code. Every dependency is fetched at runtime from BASE_URL.
-- Detects game, loads library, builds built-in tabs, injects game-specific tab

local HttpGet = game.HttpGet
local BASE_URL = "https://raw.githubusercontent.com/Whotong/Re-Hub/main/"

-- ═══════════════════════════════════════════
-- WAIT FOR GAME LOAD
-- ═══════════════════════════════════════════
repeat task.wait() until game:IsLoaded()

-- ═══════════════════════════════════════════
-- LOAD GUI LIBRARY
-- ═══════════════════════════════════════════
local Library = loadstring(HttpGet(game, BASE_URL .. "DataBase/ReHubLib.lua"))()

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

	General:Toggle({
		Title = "Anti-Idle",
		Content = "Prevent automatic kick on idle",
		Default = true,
		Callback = function(v)
			if v then
				task.spawn(function()
					while v do
						Players.LocalPlayer.Idled:Connect(function()
							local VirtualUser = game:GetService("VirtualUser")
							VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
							task.wait(1)
							VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
						end)
						task.wait(1)
					end
				end)
			end
		end,
		Flag = "ReHub/AntiIdle"
	})

	local Visuals = SettingsTab:Section({ Title = "Visuals" })

	Visuals:Dropdown({
		Title = "Theme Accent",
		Options = { "Green", "Blue", "Red", "Purple", "Orange" },
		Default = { "Green" },
		Callback = function(v)
			local themeColors = {
				Green = Color3.fromRGB(0, 230, 118),
				Blue = Color3.fromRGB(33, 150, 243),
				Red = Color3.fromRGB(244, 67, 54),
				Purple = Color3.fromRGB(156, 39, 176),
				Orange = Color3.fromRGB(255, 152, 0),
			}
			-- Theme change would require library support; placeholder
		end
	})

	Visuals:Slider({
		Title = "UI Transparency",
		Min = 0,
		Max = 100,
		Increment = 5,
		Default = 0,
		Callback = function(v) end
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
local Games = loadstring(HttpGet(game, BASE_URL .. "Re-Hub/gamelist.lua"))()
local gameEntry = Games[game.GameId]

if gameEntry then
	if typeof(gameEntry) == "string" then
		-- Repo-relative path — prepend BASE_URL, fetch and execute, passing Window
		local gameScript = loadstring(HttpGet(game, BASE_URL .. gameEntry))
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
