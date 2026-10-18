-- Combo M1 da espada (src/client/SwordCombat.luau, src/server/SwordCombat.luau, SwordMoves, SwordFx).
--   node tools/bridge.cjs run server src/server/tests/sword_combat.luau 120000
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local SwordMoves = require(ReplicatedStorage.Shared.SwordMoves)
local hook = game:GetService("ServerStorage"):WaitForChild("TestHook", 5)
local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
local COMBO = SwordMoves.COMBO

local passed = {}
local function check(name, condition, detail)
	assert(condition, `FALHOU: {name} ({detail})`)
	table.insert(passed, name)
end
local function client(arg: any): any
	return hook:Invoke("ui", player, { command = "swordCombat", arg = arg })
end
local function server(action: string, index: number?): any
	return hook:Invoke("swordcombat", player, { action = action, index = index })
end
local function boss(action: string, arg: any?): any
	return hook:Invoke("boss", player, { action = action, arg = arg })
end
local function equip()
	hook:Invoke("sword", player, { text = "/sword" })
	if player:GetAttribute("Sword") ~= true then
		hook:Invoke("sword", player, { text = "toggle" })
	end
	task.wait(0.4)
end
local function waitIdle(limit: number)
	local t0 = os.clock()
	while client("state").swinging and os.clock() - t0 < limit do
		task.wait(0.05)
	end
end

local character = player.Character or player.CharacterAdded:Wait()
character:WaitForChild("HumanoidRootPart")
hook:Invoke("leaveRoom", player)
task.wait(0.3)
equip()
client("reset")

-- 1) um golpe: começa, deixa lento, trava o giro automático, acende o rastro na janela
local lit0 = client("state").fx.lit or 0
client("click")
task.wait(0.05)
local s = client("state")
check("clique começa o golpe 1", s.swinging and s.index == 1, `{s.swinging} {s.index}`)
check("fica lento no golpe", math.abs(s.speedScale - Config.Sword.moveScale) < 1e-3 and s.autoRotate == false, `{s.speedScale} {s.autoRotate}`)
task.wait(COMBO[1].trail[1] + 0.04 - 0.05)
s = client("state")
check("rastro aceso na janela", s.fx.coated and s.fx.lit == lit0 + 1, game:GetService("HttpService"):JSONEncode(s.fx))
-- as duas mãos no cabo (medido na chave final, parada)
task.wait(0.25)
local aim = client({ action = "aim" })
check("espada onde o golpe manda", aim and aim.right < 0.25, aim and aim.right)
check("mão esquerda no cabo", aim and aim.left < 0.35, aim and aim.left)
waitIdle(2)
s = client("state")
check("volta ao controle", not s.swinging and s.speedScale == 1 and s.autoRotate == true, `{s.speedScale} {s.autoRotate}`)
check("um golpe só", s.swings == 1, s.swings)

-- 2) combo: clique guardado sai na janela; 1 → 2 → 3 e para
task.wait(0.3)
client("reset")
client("click")
task.wait(0.15)
client("click") -- cedo: fica guardado
task.wait(COMBO[1].chain[1] + 0.05 - 0.15)
s = client("state")
check("clique guardado encadeia o 2", s.index == 2, s.index)
task.wait(0.1)
client("click")
task.wait(COMBO[2].chain[1] + 0.05)
s = client("state")
check("encadeia o 3", s.index == 3, s.index)
local tips = {}
for _ = 1, 30 do
	local a = client({ action = "aim" })
	if a and a.index == 3 then
		table.insert(tips, a.tipHeight)
	end
	task.wait(0.03)
end
local lowest = math.huge
for _, h in tips do
	lowest = math.min(lowest, h)
end
check("golpe final chega perto do chão", lowest < 1.2 and lowest > -0.15, lowest)
waitIdle(3)
s = client("state")
check("combo 1-2-3 e para", table.concat(s.started, ",") == "1,2,3" and not s.swinging, table.concat(s.started, ","))
check("ponta nunca atravessa o chão", s.minTip > -0.15, s.minTip)

-- 3) cliques sem fim: um golpe por vez
task.wait(0.5)
client("reset")
client({ action = "spam", n = 20 }) -- 20 cliques no mesmo quadro
task.wait(0.1)
s = client("state")
check("spam não duplica", s.swings == 1, s.swings)
waitIdle(3)

-- 4) servidor: ritmo validado
task.wait(1.2)
check("servidor aceita o primeiro", server("swing", 1) == 1, "")
check("servidor recusa cedo demais", server("swing", 2) == nil, "")
task.wait(COMBO[1].chain[1] + 0.02)
check("servidor encadeia na janela", server("swing", 2) == 2, "")
task.wait(1.5)

-- 5) guardar a espada no meio do golpe
client("reset")
client("click")
task.wait(0.2)
hook:Invoke("sword", player, { text = "toggle" })
task.wait(0.15)
s = client("state")
check("guardar cancela o golpe", not s.swinging and s.speedScale == 1 and s.autoRotate == true, `{s.swinging} {s.speedScale}`)
hook:Invoke("sword", player, { text = "toggle" })
task.wait(0.4)

-- 6) aura na espada: segue a aura equipada e troca na hora
local oldAura = player:GetAttribute("Aura")
player:SetAttribute("Aura", "void")
task.wait(0.2)
s = client("state")
check("aura na espada", s.fx.coated and s.fx.flames and s.fx.shell and s.fx.glow, game:GetService("HttpService"):JSONEncode(s.fx))
check("cor da aura void", s.fx.shellColor == Config.AuraById.void.color, tostring(s.fx.shellColor))
player:SetAttribute("Aura", "frost")
task.wait(0.2)
s = client("state")
check("troca de aura repinta", s.fx.shellColor == Config.AuraById.frost.color and s.fx.flameColor == Config.AuraById.frost.color, tostring(s.fx.shellColor))
player:SetAttribute("Aura", nil)
task.wait(0.2)
s = client("state")
check("sem aura, sem casca", s.fx.flames == false and s.fx.shell == false, "")
player:SetAttribute("Aura", oldAura)

-- 7) dano no golem: só pela lâmina, um acerto por golpe
hook:Invoke("spawnCommand", player, "/spawn")
task.wait(4)
boss("rest", 60)
local state = boss("state")
local root = player.Character.HumanoidRootPart :: BasePart
local function face(distance: number)
	local g = boss("state").position :: Vector3
	local away = Vector3.new(root.Position.X - g.X, 0, root.Position.Z - g.Z)
	away = if away.Magnitude > 1 then away.Unit else Vector3.xAxis
	local spot = Vector3.new(g.X, root.Position.Y, g.Z) + away * distance
	player.Character:PivotTo(CFrame.lookAt(spot, Vector3.new(g.X, spot.Y, g.Z)))
end
local radius = Config.Boss.radius * Config.Boss.scale
face(radius + 2.5)
task.wait(0.5)
server("clear")
local hp0 = boss("state").hp
client("reset")
client({ action = "hold", on = true })
task.wait(1.2) -- o golpe 3 já começou; soltar antes do fim (segurando, o combo recomeça)
client({ action = "hold", on = false })
waitIdle(2)
local log = server("debug").log
local hp1 = boss("state").hp
local total, seen = 0, {}
for _, entry in log do
	total += entry.damage
	seen[entry.index] = (seen[entry.index] or 0) + 1
end
check("os 3 golpes acertam o golem", seen[1] == 1 and seen[2] == 1 and seen[3] == 1, game:GetService("HttpService"):JSONEncode(log))
check("dano = vida tirada", hp0 - hp1 == total and total > 0, `{hp0} {hp1} {total}`)
-- longe: a lâmina não alcança
task.wait(0.5)
face(radius + 14)
task.wait(0.4)
server("clear")
client("reset")
client("click")
task.wait(1.2)
check("longe não acerta", #server("debug").log == 0, #server("debug").log)
check("vida não muda de longe", boss("state").hp == hp1, "")
state = state

-- 8) renascer no meio do golpe
client("click")
task.wait(0.2)
local respawned = false
local wait = player.CharacterAdded:Once(function()
	respawned = true
end)
player:LoadCharacter()
local t0 = os.clock()
while not respawned and os.clock() - t0 < 8 do
	task.wait(0.1)
end
wait:Disconnect()
task.wait(1.5)
s = client("state")
check("renascer limpa o golpe", not s.swinging and s.weight == 0 and s.speedScale == 1, `{s.swinging} {s.weight}`)

boss("reset")
hook:Invoke("leaveRoom", player)
return `{#passed} ok: ` .. table.concat(passed, " | ")
