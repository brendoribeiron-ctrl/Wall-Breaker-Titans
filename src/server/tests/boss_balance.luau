-- Balanceamento dos chefes: fórmulas (teóricas), simulação de críticos e luta medida no jogo.
--   node tools/bridge.cjs run server src/server/tests/boss_balance.luau 300000
-- Num Play próprio. Leva ~3 min: luta 50K (~60 s), 75K (~40 s) e 100K (~20 s) em tempo real.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Anims = require(ReplicatedStorage.Shared.GolemAnims)
local Balance = require(ReplicatedStorage.Shared.CombatBalance)
local hook = game:GetService("ServerStorage"):WaitForChild("TestHook", 5)
assert(hook, "TestHook ausente")
local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
local character = player.Character or player.CharacterAdded:Wait()
character:WaitForChild("HumanoidRootPart")
task.wait(1)

local C = Config.Combat
local BOSS = Config.Boss
local S = BOSS.scale
local passed = {}
local function check(name: string, ok: boolean, detail: string?)
	assert(ok, "FALHOU: " .. name .. " (" .. tostring(detail) .. ")")
	table.insert(passed, name)
end
local function near(a: number, b: number, tolerance: number): boolean
	return math.abs(a - b) <= tolerance
end
local function state()
	return hook:Invoke("state", player)
end
local function boss(action: string, arg: any?): any
	return hook:Invoke("boss", player, { action = action, arg = arg, world = 1 })
end

---------------------------------------------------------------------------------------------------
-- 1. Fórmulas (teórico)

check("10 chefes configurados", #Config.Bosses >= 10, tostring(#Config.Bosses))
for i = 1, #Config.Bosses do
	local def = Config.Bosses[i]
	check(`chefe {i}: id confere com a posição`, def.id == i, tostring(def.id))
	if i > 1 then
		local ratio = def.minPower / Config.Bosses[i - 1].minPower
		check(`chefe {i}: Poder mínimo é 1,5x o anterior`, near(ratio, 1.5, 0.001), tostring(ratio))
	end
end
check("chefe 1 pede 50.000", Config.Bosses[1].minPower == 50_000, tostring(Config.Bosses[1].minPower))
check("chefe 10 pede ~1.922.168", near(Config.Bosses[10].minPower, 1_922_168, 2), tostring(Config.Bosses[10].minPower))
check("id fora da lista usa o último", Balance.boss(99).id == #Config.Bosses, "fallback")

print("== Tabela teórica (socos 4/s, crítico 4% | 20%) ==")
print("chefe | Poder mín | vida | dano/soco 50%,100%,150%,200% do mín | TTK 100% 4% | TTK 200% 4% | TTK 100% 20%")
for i = 1, #Config.Bosses do
	local def = Config.Bosses[i]
	local min = def.minPower
	print(
		`{i} | {min} | {Balance.bossHp(i)} | {Balance.punchDamage(min * 0.5, i)},{Balance.punchDamage(min, i)},{Balance.punchDamage(min * 1.5, i)},{Balance.punchDamage(min * 2, i)}`
			.. ` | {string.format("%.1f", Balance.expectedTtk(min, i))}s | {string.format("%.1f", Balance.expectedTtk(min * 2, i))}s | {string.format("%.1f", Balance.expectedTtk(min, i, 0.2))}s`
	)
end

local ttk50 = Balance.expectedTtk(50_000, 1)
local ttk75 = Balance.expectedTtk(75_000, 1)
local ttk100 = Balance.expectedTtk(100_000, 1)
check("50K: ~60 s", near(ttk50, 60, 0.6), tostring(ttk50))
check("75K: ~40 s", near(ttk75, 40, 0.4), tostring(ttk75))
check("100K: ~20 s", near(ttk100, 20, 0.2), tostring(ttk100))
check("mais Poder nunca alonga a luta", ttk50 > ttk75 and ttk75 > ttk100, `{ttk50} {ttk75} {ttk100}`)
check("a vida do chefe 1 vem do ttk configurado", Balance.bossHp(1) == math.floor(C.baseDamage * C.hitsPerSecond * (1 + C.critChance * (C.critMultiplier - 1)) * Config.Bosses[1].ttk + 0.5), tostring(Balance.bossHp(1)))
check("curva é contínua nos pontos", near(Balance.damageMultiplier(50_000, 1), 1, 1e-9) and near(Balance.damageMultiplier(75_000, 1), 1.5, 1e-9) and near(Balance.damageMultiplier(100_000, 1), 3, 1e-9), "pontos")
check("Poder 0 ainda tira vida", Balance.punchDamage(0, 1) >= 1, tostring(Balance.punchDamage(0, 1)))
check("abaixo do mínimo o dano cai", Balance.punchDamage(25_000, 1) < Balance.punchDamage(50_000, 1), tostring(Balance.punchDamage(25_000, 1)))
check("muito acima respeita o teto", Balance.damageMultiplier(1e9, 1) == C.maxMult, tostring(Balance.damageMultiplier(1e9, 1)))
for i = 1, #Config.Bosses do
	local min = Config.Bosses[i].minPower
	check(`chefe {i}: TTK ~{Config.Bosses[i].ttk} s no Poder mínimo`, near(Balance.expectedTtk(min, i), Config.Bosses[i].ttk, Config.Bosses[i].ttk * 0.01), tostring(Balance.expectedTtk(min, i)))
	check(`chefe {i}: entrada pelo Poder mínimo`, Balance.canEnter(min, i) and not Balance.canEnter(min - 1, i), "entrada")
end
check("crítico de 20% (skill no máximo) encurta a luta", Balance.expectedTtk(50_000, 1, 0.2) < ttk50, tostring(Balance.expectedTtk(50_000, 1, 0.2)))
check("chance máxima de crítico é 20%", near(Config.Crit.baseChance + Config.Stats.critChance.max * Config.Stats.critChance.perLevel, 0.2, 1e-9), "20%")

-- Simulado: 2000 lutas por faixa, socos a 4/s, crítico sorteado (4% e 20%)
local rng = Random.new(1234)
local function simulate(power: number, chance: number): number
	local unit = Balance.punchDamage(power, 1)
	local total = 0
	local runs = 2000
	for _ = 1, runs do
		local hp, hits = Balance.bossHp(1), 0
		while hp > 0 do
			hp -= if rng:NextNumber() < chance then unit * C.critMultiplier else unit
			hits += 1
		end
		total += hits / C.hitsPerSecond
	end
	return total / runs
end
print("== Simulado (2000 lutas, 4 socos/s) ==")
for _, power in { 50_000, 75_000, 100_000 } do
	local a, b = simulate(power, 0.04), simulate(power, 0.20)
	print(`{power}: crítico 4% = {string.format("%.1f", a)}s | 20% = {string.format("%.1f", b)}s | teórico {string.format("%.1f", Balance.expectedTtk(power, 1))}s | {string.format("%.1f", Balance.expectedTtk(power, 1, 0.2))}s`)
	check(`simulado ${power} 4% bate com a teoria`, near(a, Balance.expectedTtk(power, 1), Balance.expectedTtk(power, 1) * 0.04), tostring(a))
	check(`simulado ${power} 20% bate com a teoria`, near(b, Balance.expectedTtk(power, 1, 0.2), Balance.expectedTtk(power, 1, 0.2) * 0.04), tostring(b))
end

---------------------------------------------------------------------------------------------------
-- 2. No jogo: entrar na sala do golem (mundo 1 = chefe 1)

hook:Invoke("runFinish", player)
hook:Invoke("set", player, { power = 0, money = 0, bagLevel = 1, stats = {}, boosts = {}, rebirths = 0, aura = "" })
hook:Invoke("reset", player)
task.wait(0.5)
local walls = Config.Worlds[1].walls
hook:Invoke("set", player, { power = walls[#walls].power * 2, bagLevel = 1, aura = "", stats = {}, boosts = {}, bossWins = {} })
hook:Invoke("goZone", player, "resetCooldown")
task.wait(0.3)
hook:Invoke("runStart", player)
hook:Invoke("runRelease", player, 1)
hook:Invoke("runFinish", player)
task.wait(Config.BossRoom.introTime + 1.5)
check("está na sala do golem", player:GetAttribute("Room") == 1, tostring(player:GetAttribute("Room")))

local center = Config.BossRoom.center + Config.Worlds[1].offset
local function put(offset: Vector3)
	local at = (boss("state").cframe * CFrame.new(offset)).Position
	local char = player.Character :: Model
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart
	root.AssemblyLinearVelocity = Vector3.zero
	char:PivotTo(CFrame.new(Vector3.new(at.X, center.Y + 3, at.Z)))
end

-- Entrada: com a regra ligada, só entra quem tem o Poder mínimo; desligada, qualquer um
boss("enforce", true)
hook:Invoke("set", player, { power = Balance.boss(1).minPower - 1 })
boss("reset")
boss("pending", true)
task.wait(0.3)
local refused = boss("challenge")
check("entrada: 49.999 de Poder é recusado", refused == false and boss("state").state == "sleep", `{refused} {boss("state").state} poder={state().power}`)
hook:Invoke("set", player, { power = Balance.boss(1).minPower })
check("entrada: 50.000 de Poder acorda o chefe", boss("challenge") == true, "acordou")
task.wait(Anims.clips.Wake.length + 0.6)
boss("reset")
boss("enforce", false)
boss("pending", true)
hook:Invoke("set", player, { power = 0 })
check("regra desligada: sem Poder ainda desafia", boss("challenge") == true, "acordou")
task.wait(Anims.clips.Wake.length + 0.6)
boss("reset")

-- Luta medida: socos segurando o botão (intervalo de 0,25 s), sem crítico, para cada faixa de Poder
print("== Medido (socos a cada 0,25 s, sem crítico) ==")
local results = {}
for _, power in { 50_000, 75_000, 100_000 } do
	boss("pending", true)
	hook:Invoke("set", player, { power = power, stats = {}, aura = "" })
	check(`{power}: desafio acorda`, boss("challenge") == true, "acordou")
	task.wait(Anims.clips.Wake.length + 0.6)
	-- golem parado e cansado (sem golpes) e o jogador ao alcance do soco; confere antes de medir
	for _ = 1, 6 do
		boss("place", { position = center, yaw = math.pi, rest = 400 })
		boss("rest", 400)
		task.wait(0.3)
		put(Vector3.new(0, 0, -(BOSS.radius * S + 4)))
		task.wait(0.3)
		local now = boss("state")
		local rootNow = (player.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
		local away = Vector3.new(rootNow.Position.X - now.position.X, 0, rootNow.Position.Z - now.position.Z).Magnitude
		if now.state == "idle" and away < BOSS.hitRange * S - 5 then
			break
		end
	end

	local unit = Balance.punchDamage(power, 1)
	local maxHp = boss("state").maxHp
	check(`{power}: vida do chefe`, maxHp == Balance.bossHp(1), `{maxHp} esperado {Balance.bossHp(1)}`)
	-- o servidor recusa soco antes de 0,22 s
	task.wait(1)
	local hpBefore = boss("state").hp
	local first = 0
	for _ = 1, 6 do -- tenta de novo se um soco avulso do cliente ocupou o ritmo de 0,22 s
		first = boss("punch", false)
		if first > 0 then
			break
		end
		task.wait(0.3)
	end
	local tooSoon = boss("punch", false)
	local dbg = boss("state")
	local rootNow = (player.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
	local away = Vector3.new(rootNow.Position.X - dbg.position.X, 0, rootNow.Position.Z - dbg.position.Z).Magnitude
	check(`{power}: dano do 1º soco`, first == unit, `{first} esperado {unit}; golem {dbg.state} hp {dbg.hp}; distância {away} (máx {BOSS.hitRange * S}); sala {player:GetAttribute("RoomKey")}`)
	check(`{power}: soco antes de 0,22 s é recusado`, tooSoon == 0, tostring(tooSoon))
	-- Mede só os socos aceitos; tira da conta a vida que outro soco (do cliente real, se houver) tirou.
	local startClock = os.clock() - 0.25
	local accepted, others, strayHp = 1, 0, 0
	local hpLast = boss("state").hp
	task.wait(0.25)
	while hpLast > unit * C.critMultiplier do
		local dealt = boss("punch", false)
		if dealt > 0 then
			accepted += 1
			if dealt ~= unit then
				others += 1
			end
		end
		local hpNow = boss("state").hp
		strayHp += math.max(0, hpLast - hpNow - dealt)
		hpLast = hpNow
		task.wait(Config.Bag.holdInterval)
	end
	local elapsed = os.clock() - startClock + 1 / C.hitsPerSecond -- + o último soco
	-- tempo teórico para tirar a vida que os socos aceitos tiraram (sem crítico, 4 socos/s)
	local theory = (hpBefore - strayHp) / (C.hitsPerSecond * unit)
	results[power] = elapsed
	print(`{power}: {accepted} socos aceitos | medido ~{string.format("%.1f", elapsed)}s | teórico (sem crítico) {string.format("%.1f", theory)}s | unidade {unit} | vida tirada por outros socos {strayHp}`)
	check(`{power}: dano por soco fixo durante a luta`, others == 0, `{others} socos com dano diferente`)
	check(`{power}: tempo medido perto do teórico`, elapsed >= theory * 0.95 and elapsed <= theory * 1.2, `{elapsed} vs {theory}`)
	boss("reset")
	task.wait(0.3)
end
check("medido: mais Poder, luta mais curta", results[50_000] > results[75_000] and results[75_000] > results[100_000], "ordem")

hook:Invoke("set", player, { power = 0, stats = {}, aura = "" })
boss("reset")
print(`boss_balance: {#passed} checagens ok`)
for _, name in passed do
	print("  ok:", name)
end
return #passed
