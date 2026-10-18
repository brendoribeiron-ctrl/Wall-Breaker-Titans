-- Utilitário de captura dos efeitos da espada.
--   node tools/bridge.cjs run server src/server/tests/sword_show.luau 30000 setup [aura] [poder]
--     leva para a sala de testes, dá e equipa a espada, põe a aura e trava a mira
--   node tools/bridge.cjs run server src/server/tests/sword_show.luau 20000 combo [segundos]
--     segura o botão (padrão 1 s: o combo inteiro)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local hook = game:GetService("ServerStorage"):WaitForChild("TestHook", 5)
local player = Players:GetPlayers()[1]
local args = HttpService:JSONDecode(script.Parent:GetAttribute("Args") or "[]")
local function ui(arg: any): any
	return hook:Invoke("ui", player, { command = "swordCombat", arg = arg })
end

if args[1] == "setup" then
	if player:GetAttribute("Sword") ~= true then
		hook:Invoke("devArea", player, true)
		task.wait(1.5)
		hook:Invoke("sword", player, { text = "/sword" })
		hook:Invoke("sword", player, { text = "toggle" })
		task.wait(0.8)
	end
	local aura = args[2]
	player:SetAttribute("Aura", if aura and aura ~= "none" then aura else nil)
	player:SetAttribute("Power", tonumber(args[3]) or 800)
	ui({ action = "lockAim", on = true })
	return "pronto"
end

ui({ action = "hold", on = true })
task.wait(tonumber(args[2]) or 1)
ui({ action = "hold", on = false })
return "ok"
