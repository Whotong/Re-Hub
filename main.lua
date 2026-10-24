--!strict
-- Re: Hub — Mist. Release snapshots are immutable; see docs/design/mist.md.
-- Optional dependency injection is for the offline harness, never saved flags.
local Bootstrap = ...
if type(Bootstrap) ~= "table" then Bootstrap = {} end
local RELEASE = {
	DataBase = "aacf81db8c5abecde7f81406cf9adb17aea47bc1",
	Hub = "46147d3888b520f9ca9c89faae6d0d570232bda5",
}
local LIB_URL = "https://raw.githubusercontent.com/Whotong/DataBase/" .. RELEASE.DataBase .. "/Library/ReHubLib.lua"
local LIST_URL = "https://raw.githubusercontent.com/Whotong/Re-Hub/" .. RELEASE.Hub .. "/gamelist.lua"

local Experiences = {
	[10759337137] = { Title = "Last Stop [Beta]", Shortcuts = { "AutoGrab", "esp/esp-items", "recon-dashboard/refresh-counts" } },
	[10563114921] = { Title = "Steal an Egg", Shortcuts = { "AutoCollect", "AutoHatch", "AutoClaim" } },
}
-- Supply real public URLs here when available. Empty links are omitted.
local Links = { Discord = "", Website = "" }

local function pinned(url: string): boolean
	local commit = url:match("^https://raw%.githubusercontent%.com/[^/]+/[^/]+/([%x]+)/")
	return commit ~= nil and #commit == 40
end
local function run(url: string): (boolean, any)
	if not pinned(url) then return false, "remote URL must contain a full commit hash" end
	local ok, src = pcall(function() return game:HttpGet(url) end)
	if not ok or type(src) ~= "string" or src == "" then return false, "fetch failed: " .. tostring(src) end
	local fn, err = loadstring(src, "@" .. url)
	if not fn then return false, err end
	return pcall(fn)
end

if not game:IsLoaded() then game.Loaded:Wait() end
local okList, Games = true, Bootstrap.Games
if Games == nil then okList, Games = run(LIST_URL) end
if not okList or type(Games) ~= "table" then return end
local entry = Games[game.GameId]
if type(entry) ~= "string" and entry ~= true then return end -- repository requires silent unsupported exit

local okLib, Library = true, Bootstrap.Library
if Library == nil then okLib, Library = run(LIB_URL) end
if not okLib or type(Library) ~= "table" or Library.Version ~= "3.0.0-mist" then
	warn("Re: Hub: Mist library unavailable at " .. LIB_URL .. ". Publish the Mist sources and refresh release pins (docs/design/mist.md).")
	return
end
local env = {}
if type(getgenv) == "function" then
	local ok, value = pcall(getgenv)
	if ok and type(value) == "table" then env = value end
end
if type(env.ReHub) == "table" and type(env.ReHub.Unload) == "function" then
	local ok, err = pcall(env.ReHub.Unload)
	if not ok then warn("Re: Hub previous unload: " .. tostring(err)) end
end
-- Migrate the older instance's guard without creating another executor global.
if type(env.ReHubShutdown) == "function" then
	local ok, err = pcall(env.ReHubShutdown)
	if not ok then warn("Re: Hub legacy unload: " .. tostring(err)) end
	env.ReHubShutdown = nil
end
local metadata = Experiences[game.GameId] or { Title = "Supported experience", Shortcuts = {} }
local okWindow, Window = pcall(function()
	return Library:Start({ Name = "Re: Hub", SaveFolder = "Re-Hub",
		ExperienceName = metadata.Title, Status = "Loading available controls…", Discord = Links.Discord, Website = Links.Website })
end)
if not okWindow then warn("Re: Hub could not create the interface: " .. tostring(Window)) return end
local hub = { Window = Window, Version = Library.Version }
hub.Unload = function() Window:Unload() end
env.ReHub = hub
Window._environment, Window._hubState = env, hub

local Tabs = { Main = Window:MakeTab("Main"), Automation = Window:MakeTab("Automation"), Misc = Window:MakeTab("Misc") }
local okGame, module = true, Bootstrap.GameModule
if module == nil and type(entry) == "string" then okGame, module = run(entry) end
if entry == true and module == nil then
	Window:SetReady("Supported · no module published")
elseif not okGame or type(module) ~= "function" then
	local message = "Game module failed: " .. tostring(entry) .. " · " .. tostring(module)
	warn(message)
	Window:SetReady("Module unavailable · see Diagnostics")
	Window:ReportError("Loader", message)
else
	local ok, err = pcall(module, Window, Tabs)
	if Window._closed then return Library end
	if ok then
		-- A module can report a known prerequisite/lobby state during injection.
		if not Window._readyText then Window:SetReady(#Window._actionOrder > 0 and "Controls ready · default off" or "No actions available in this place") end
	else
		Window:StopAll()
		Window:SetReady("Module error · see Diagnostics")
		Window:ReportError("Loader", err)
	end
end
Window:Finalize(metadata.Shortcuts)
return Library
