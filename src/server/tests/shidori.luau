-- Shidori (src/server/Shidori.luau, Stamina.luau; cliente Shidori.luau, ShidoriFx.luau).
--   node tools/bridge.cjs run server src/server/tests/shidori.luau 120000
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local CombatBalance = require(ReplicatedStorage.Shared.CombatBalance)
local hook = game:GetService("ServerStorage"):WaitForChild("TestHook", 5)
local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
local S = Config.Shidori

local passed = {}
local function check(name, condition, detail)
	assert(condition, `FALHOU: {name} ({detail})`)
	table.insert(passed, name)
end
local function client(arg: any): any
	return hook:Invoke("ui", player, { command = "shidori", arg = arg })
end
local function server(action: string, amount: number?): any
	return hook:Invoke("shidori", player, { action = action, amount = amount })
end
local function boss(action: string, arg: any?): any
	return hook:Invoke("boss", player, { action = action, arg = arg })
end
local function json(v: any): string
	return HttpService:JSONEncode(v)
end
local function lastRefusal(): string?
	local log = server("debug").log
	for i = #log, 1, -1 do
		if log[i].kind == "refused" then
			return log[i].reason
		end
	end
	return nil
end
local function waitDone(limit: number)
	local t0 = os.clock()
	while (client("state").casting or player:GetAttribute("ShidoriState") ~= "Cooldown") and os.clock() - t0 < limit do
		task.wait(0.05)
	end
end

local character = player.Character or player.CharacterAdded:Wait()
character:WaitForChild("HumanoidRootPart")
hook:Invoke("leaveRoom", player)
if player:GetAttribute("Sword") == true then
	hook:Invoke("sword", player, { text = "toggle" })
end
task.wait(0.3)
hook:Invoke("set", player, { stats = { shidori = 0 }, money = 0 })
task.wait(0.2)
server("resetCooldown")
server("stamina", 100)
server("clear")

-- 1) bloqueado até comprar o nó da árvore
check("bloqueado sem o nó", server("cast") == false and lastRefusal() == "locked", lastRefusal())
check("sem dinheiro não compra", hook:Invoke("buyStat", player, "shidori") == false, "")
hook:Invoke("set", player, { money = Config.statCost("shidori", 0) })
check("compra o nó", hook:Invoke("buyStat", player, "shidori") == true, "")
task.wait(0.3)
check("atributo do nó", player:GetAttribute("Stat_shidori") == 1, player:GetAttribute("Stat_shidori"))
check("nó só tem 1 nível", hook:Invoke("buyStat", player, "shidori") == false, "")
check("estamina cheia", player:GetAttribute("Stamina") == 100 and player:GetAttribute("StaminaMax") == 100, player:GetAttribute("Stamina"))
check("estado Ready", player:GetAttribute("ShidoriState") == "Ready", player:GetAttribute("ShidoriState"))

-- 2) ativação pelo cliente (o mesmo caminho da tecla Z e do botão)
client({ action = "press" })
task.wait(0.15)
local s = client("state")
check("ativou", s.casting and player:GetAttribute("ShidoriState") == "Activating", json(s))
check("gastou 50 de estamina", math.abs(player:GetAttribute("Stamina") - 50) < 0.6, player:GetAttribute("Stamina"))
check("recarga de 7 s", math.abs(server("debug").cooldownLeft - (S.cooldown - 0.15)) < 0.2, server("debug").cooldownLeft)
check("efeitos na mão", s.fx[player.Name] ~= nil, json(s.fx))
check("botão no HUD", s.button == true, "")
-- 3) pedido repetido durante a ativação e na recarga: recusado, sem gastar de novo
check("recusa durante a ativação", server("cast") == false and lastRefusal() == "busy", lastRefusal())
task.wait(S.burst - 0.15 + 0.05)
s = client("state")
check("estado Active na explosão", player:GetAttribute("ShidoriState") == "Active", player:GetAttribute("ShidoriState"))
check("pose com peso cheio", s.weight > 0.95, s.weight)
-- a mão esquerda: no acúmulo ficou baixa; na investida, à frente do corpo
task.wait(S.strike - S.burst + 0.03)
s = client("state")
check("palma à frente na investida", s.hand and s.hand.Z < -1.2, json(s.hand))
waitDone(3)
check("estado Cooldown depois", player:GetAttribute("ShidoriState") == "Cooldown", player:GetAttribute("ShidoriState"))
s = client("state")
check("pose sai no fim", not s.casting, json(s))
check("efeitos limpos", next(s.fx) == nil, json(s.fx))
check("recusa na recarga", server("cast") == false and lastRefusal() == "cooldown", lastRefusal())
check("estamina não foi gasta de novo", player:GetAttribute("Stamina") >= 49.4, player:GetAttribute("Stamina"))

-- 4) estamina: recusa abaixo de 50 e regenera
server("resetCooldown")
server("stamina", 30)
check("recusa com 30 de estamina", server("cast") == false and lastRefusal() == "stamina", lastRefusal())
task.wait(S.cooldown * 0 + Config.Stamina.regenDelay + 1.1)
local regen = player:GetAttribute("Stamina")
check("estamina regenera", regen > 30 + Config.Stamina.regenPerSecond * 0.7, regen)

-- 5) dois pedidos no mesmo instante: um só vale
server("resetCooldown")
server("stamina", 100)
server("clear")
local a = server("cast")
local b = server("cast")
check("pedidos duplicados: um vale", a == true and b == false, `{a} {b}`)
check("gastou uma vez só", math.abs(player:GetAttribute("Stamina") - 50) < 0.6, player:GetAttribute("Stamina"))
waitDone(3)

-- 6) dano no golem: 1,6 x o dano do soco, com o Poder da luta; um acerto por ativação
hook:Invoke("spawnCommand", player, "/spawn")
task.wait(2)
-- a cinemática de entrada prende o boneco no cliente; espera soltar
local t1 = os.clock()
while client("state").anchored and os.clock() - t1 < 20 do
	task.wait(0.25)
end
task.wait(0.5)
boss("rest", 60)
local root = player.Character.HumanoidRootPart :: BasePart
local function face(distance: number)
	local g = boss("state").position :: Vector3
	local away = Vector3.new(root.Position.X - g.X, 0, root.Position.Z - g.Z)
	away = if away.Magnitude > 1 then away.Unit else Vector3.xAxis
	local spot = Vector3.new(g.X, root.Position.Y, g.Z) + away * distance
	player.Character:PivotTo(CFrame.lookAt(spot, Vector3.new(g.X, spot.Y, g.Z)))
end
local radius = Config.Boss.radius * Config.Boss.scale
face(radius + 8)
task.wait(0.5)
server("resetCooldown")
server("stamina", 100)
server("clear")
local hp0 = boss("state").hp
local before = root.Position
check("ativa perto do golem", server("cast") == true, lastRefusal())
waitDone(3)
local moved = Vector3.new(root.Position.X - before.X, 0, root.Position.Z - before.Z).Magnitude
check("investida anda", moved > 4, moved)
local hits = {}
for _, entry in server("debug").log do
	if entry.kind == "hit" then
		table.insert(hits, entry)
	end
end
local hp1 = boss("state").hp
local profile = hook:Invoke("state", player)
local unit = CombatBalance.punchDamage(profile.power, 1)
local full = math.max(1, math.floor(unit * S.damage + 1e-6))
check("um acerto por ativação", #hits == 1, json(hits))
check("dano = 1,6 x soco (ou crítico)", hits[1] and (hits[1].damage == full or hits[1].damage == full * Config.Combat.critMultiplier or hits[1].damage == hp0), `{hits[1] and hits[1].damage} unit={unit} full={full}`)
check("dano = vida tirada", hp0 - hp1 == (hits[1] and hits[1].damage or -1), `{hp0} {hp1}`)
-- longe: a investida não alcança
face(radius + 30)
task.wait(0.4)
server("resetCooldown")
server("clear")
server("cast")
waitDone(3)
local far = 0
for _, entry in server("debug").log do
	if entry.kind == "hit" then
		far += 1
	end
end
check("longe não acerta", far == 0, far)

-- 7) renascer no meio corta tudo
server("resetCooldown")
server("stamina", 100)
server("cast")
task.wait(0.4)
local respawned = false
local conn = player.CharacterAdded:Once(function()
	respawned = true
end)
player:LoadCharacter()
local t0 = os.clock()
while not respawned and os.clock() - t0 < 8 do
	task.wait(0.1)
end
conn:Disconnect()
task.wait(1.5)
s = client("state")
check("renascer corta a pose", not s.casting, json(s))
check("renascer limpa os efeitos", next(s.fx) == nil, json(s.fx))
check("renascer: estado Cooldown ou Ready", player:GetAttribute("ShidoriState") == "Cooldown" or player:GetAttribute("ShidoriState") == "Ready", player:GetAttribute("ShidoriState"))

boss("reset")
hook:Invoke("leaveRoom", player)
return `{#passed} ok: ` .. table.concat(passed, ", ")
