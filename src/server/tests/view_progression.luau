-- Abre o INDEX numa aba ou a árvore de skills, para captura.
--   node tools/bridge.cjs run server src/server/tests/view_progression.luau 30000 index 2   (ou: skills defense)
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local hook = game:GetService("ServerStorage"):WaitForChild("TestHook", 5)
local player = Players:GetPlayers()[1]
local args = HttpService:JSONDecode(script.Parent:GetAttribute("Args") or "[]")
local function ui(command, arg)
	return hook:Invoke("ui", player, { command = command or "state", arg = arg })
end
if ui().open ~= "" then
	ui("toggle", ui().open)
	task.wait(0.3)
end
if args[1] == "index" then
	hook:Invoke("set", player, { index = { rookie_jabber = true, rookie_jabber_magma = true, frost_hook_magma = true } })
	ui("indexTab", tonumber(args[2]))
	ui("toggle", "Index")
elseif args[1] == "skills" then
	hook:Invoke("set", player, { money = 5000, stats = { luck = 2, defense = 1 } })
	ui("toggle", "Skills")
	task.wait(0.5)
	ui("skillsFocus", args[2])
end
task.wait(1)
return ui().open
