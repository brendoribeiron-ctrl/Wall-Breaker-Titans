-- Utilitário de captura do Shidori.
--   node tools/bridge.cjs run server src/server/tests/shidori_show.luau 30000 setup [ângulo]
--     leva para a sala de testes, desbloqueia, enche a estamina, mira fixa e câmera de lado
--     (ângulo em graus em volta do boneco: 0 = de frente, 90 = lado esquerdo, 180 = de costas)
--   node tools/bridge.cjs run server src/server/tests/shidori_show.luau 20000 cast
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local hook = game:GetService("ServerStorage"):WaitForChild("TestHook", 5)
local player = Players:GetPlayers()[1]
local args = HttpService:JSONDecode(script.Parent:GetAttribute("Args") or "[]")

local function shidori(action: string, amount: number?): any
	return hook:Invoke("shidori", player, { action = action, amount = amount })
end

if args[1] == "setup" then
	hook:Invoke("leaveRoom", player)
	hook:Invoke("devArea", player, true)
	task.wait(1.5)
	if player:GetAttribute("Sword") == true then
		hook:Invoke("sword", player, { text = "toggle" })
	end
	hook:Invoke("set", player, { stats = { shidori = 1 } })
	task.wait(0.3)
	local root = player.Character.HumanoidRootPart :: BasePart
	local forward = Vector3.new(0, 0, -1)
	player.Character:PivotTo(CFrame.lookAt(root.Position, root.Position + forward))
	hook:Invoke("ui", player, { command = "shidori", arg = { action = "aim", dir = forward } })
	local angle = math.rad(tonumber(args[2]) or -55)
	-- câmera presa olhando o boneco de um ângulo (de frente = 0, negativo = lado esquerdo dele)
	local center = root.Position + forward * 1.5 + Vector3.new(0, -0.3, 0)
	local offset = Vector3.new(math.sin(angle), 0, -math.cos(angle)) * (tonumber(args[3]) or 10) + Vector3.new(0, 1.2, 0)
	hook:Invoke("ui", player, { command = "camera", arg = { from = center + offset, to = center, seconds = 600 } })
	shidori("resetCooldown")
	shidori("stamina", 100)
	return "pronto"
elseif args[1] == "freeze" then
	return hook:Invoke("ui", player, { command = "shidori", arg = { action = "freeze", t = tonumber(args[2]) } })
elseif args[1] == "cast" then
	shidori("resetCooldown")
	shidori("stamina", 100)
	return shidori("cast")
end
return "args: setup | cast"
