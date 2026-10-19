-- Skills LUCK e DEFENSE, Poder pelo dano no golem e as abas do INDEX por mundo.
--   node tools/bridge.cjs run server src/server/tests/progression.luau 120000
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Anims = require(ReplicatedStorage.Shared.GolemAnims)
local hook = game:GetService("ServerStorage"):WaitForChild("TestHook", 5)
assert(hook, "TestHook ausente")
local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
local character = player.Character or player.CharacterAdded:Wait()
character:WaitForChild("HumanoidRootPart")
task.wait(1)

local BOSS = Config.Boss
local S = BOSS.scale
local passed = {}
local function check(name: string, ok: boolean, detail: string?)
	assert(ok, "FALHOU: " .. name .. " (" .. tostring(detail) .. ")")
	table.insert(passed, name)
end
local function state()
	return hook:Invoke("state", player)
end
local function ui(command: string?, arg: any?): any
	return hook:Invoke("ui", player, { command = command or "state", arg = arg })
end
local function boss(action: string, arg: any?): any
	return hook:Invoke("boss", player, { action = action, arg = arg, world = 1 })
end
local function humanoid(): Humanoid
	return (player.Character :: Model):WaitForChild("Humanoid") :: Humanoid
end

hook:Invoke("runFinish", player)
hook:Invoke("set", player, { power = 0, money = 0, bagLevel = 1, stats = {}, boosts = {}, rebirths = 0 })
task.wait(0.2)

-- compra das skills novas: cobra, sobe o nível, replica e respeita o teto do mundo 1
for _, name in { "luck", "defense", "health" } do
	check(name .. " existe na ordem da árvore", table.find(Config.StatOrder, name) ~= nil, name)
	check(name .. " sem dinheiro recusa", hook:Invoke("buyStat", player, name) == false, "dinheiro 0")
	hook:Invoke("set", player, { money = Config.statCost(name, 0) })
	check(name .. " compra", hook:Invoke("buyStat", player, name) == true and state().stats[name] == 1 and state().money == 0, tostring(state().stats[name]))
	check(name .. " replica", player:GetAttribute("Stat_" .. name) == 1, tostring(player:GetAttribute("Stat_" .. name)))
	local cap = Config.statCap(name, 0)
	hook:Invoke("set", player, { money = 1e12, stats = { [name] = cap } })
	check(name .. " para no teto do mundo 1", hook:Invoke("buyStat", player, name) == false and state().stats[name] == cap, tostring(state().stats[name]))
	hook:Invoke("set", player, { rebirths = Config.Worlds[2].rebirths, stats = { [name] = Config.Stats[name].max } })
	check(name .. " no máximo recusa", hook:Invoke("buyStat", player, name) == false, "máximo")
	hook:Invoke("set", player, { rebirths = 0, money = 0, stats = {} })
end

-- sorte: sem nada = 1; skill multiplica a poção; teto
check("sorte sem nada é 1", hook:Invoke("luck", player) == 1, tostring(hook:Invoke("luck", player)))
hook:Invoke("set", player, { stats = { luck = 4 } })
local four = hook:Invoke("luck", player)
check("skill LUCK soma por nível", math.abs(four - Config.luckFromStat(4)) < 1e-9 and four > 1, tostring(four))
local potionEnd = workspace:GetServerTimeNow() + 120
hook:Invoke("set", player, { stats = { luck = Config.Stats.luck.max }, boosts = { luck = potionEnd } })
local full = hook:Invoke("luck", player)
local expected = math.min(Config.PotionById.luck.multiplier * Config.luckFromStat(Config.Stats.luck.max), Config.Roll.maxLuck)
check("poção x skill, dentro do teto", math.abs(full - expected) < 1e-9 and full <= Config.Roll.maxLuck, `{full} {expected}`)
hook:Invoke("set", player, { stats = {}, boosts = {} })

-- defesa: fórmula com teto e dano mínimo
check("defesa 0 não muda o dano", Config.defendedDamage(42, 0) == 42, tostring(Config.defendedDamage(42, 0)))
check("defesa corta por nível", Config.defendedDamage(100, 5) == math.floor(100 * (1 - 5 * Config.Stats.defense.perLevel) + 0.5), tostring(Config.defendedDamage(100, 5)))
check("defesa tem teto", Config.defenseReduction(1000) == Config.Defense.maxReduction, tostring(Config.defenseReduction(1000)))
check("golpe sempre tira o mínimo", Config.defendedDamage(1, Config.Stats.defense.max) >= Config.Defense.minDamage, "mínimo")

-- vida: skill HEALTH sobe o MaxHealth, soma a diferença sem curar além e o HUD mostra o número
local h = humanoid()
task.wait(0.3)
check("sem skill a vida é a base", h.MaxHealth == Config.Health.base and h.Health == Config.Health.base, `{h.Health}/{h.MaxHealth}`)
check("HUD mostra a vida com número", ui("health") == `❤ {Config.Health.base} / {Config.Health.base}`, ui("health"))
h.Health = 50
hook:Invoke("set", player, { stats = { health = 3 } })
task.wait(0.3)
local max3 = Config.maxHealth(3)
check("HEALTH 3 aumenta a vida máxima", h.MaxHealth == max3 and max3 > Config.Health.base, tostring(h.MaxHealth))
-- folga de 3 para a regeneração do Roblox (1% da vida máxima por segundo)
local want = 50 + max3 - Config.Health.base
check("subir de nível soma só a diferença", h.Health >= want and h.Health <= want + 3, `{h.Health} esperado {want}`)
task.wait(0.4)
check("HUD acompanha a vida máxima", string.find(ui("health"), `/ {max3}`, 1, true) ~= nil, ui("health"))
hook:Invoke("set", player, { rebirths = Config.Worlds[2].rebirths, stats = { health = Config.Stats.health.max } })
task.wait(0.3)
check("HEALTH no máximo passa de 100", h.MaxHealth == Config.maxHealth(Config.Stats.health.max) and h.MaxHealth > 100, tostring(h.MaxHealth))
player:LoadCharacter()
task.wait(1.5)
local reborn = humanoid()
check("ao renascer volta com a vida máxima cheia", reborn.MaxHealth == Config.maxHealth(Config.Stats.health.max) and reborn.Health == reborn.MaxHealth, `{reborn.Health}/{reborn.MaxHealth}`)
hook:Invoke("set", player, { rebirths = 0, stats = {} })
task.wait(0.3)
check("voltar o nível baixa a vida máxima", reborn.MaxHealth == Config.Health.base and reborn.Health <= reborn.MaxHealth, `{reborn.Health}/{reborn.MaxHealth}`)
hook:Invoke("runFinish", player)

-- INDEX: uma aba por mundo, sem repetir personagem
local seen, total = {}, 0
for _, world in Config.Worlds do
	for _, info in Config.IndexByWorld[world.id] do
		assert(not seen[info.id], "repetido no índice: " .. info.id)
		seen[info.id] = true
		total += 1
		assert((info.world or 1) == world.id, "fora do mundo: " .. info.id)
	end
end
check("índice: 18 por mundo, sem repetidos", #Config.IndexByWorld[1] == #Config.Characters and #Config.IndexByWorld[2] == #Config.Characters and total == #Config.Characters * #Config.Worlds, tostring(total))
local magmaId = Config.Characters[1].id .. Config.Worlds[2].suffix
hook:Invoke("set", player, { index = { [Config.Characters[1].id] = true, [magmaId] = true }, levels = { [magmaId] = 3 } })
task.wait(0.3)
local indexAttr = string.split(player:GetAttribute("Index"), ",")
check("atributo Index leva os dois mundos", #indexAttr == 2 and table.find(indexAttr, magmaId) ~= nil, player:GetAttribute("Index"))
check("atributo Levels leva o de magma", string.find(player:GetAttribute("Levels") or "", magmaId .. ":3", 1, true) ~= nil, tostring(player:GetAttribute("Levels")))
if ui().open ~= "" then
	ui("toggle", ui().open)
	task.wait(0.1)
end
ui("indexTab", 1)
ui("toggle", "Index")
task.wait(0.3)
local s1 = ui()
check("aba BLACK CLOVER: 1 de 18", s1.open == "Index" and s1.indexWorld == 1 and s1.indexCards == 18 and s1.indexFound == 1 and s1.indexCount == "1/18 FOUND", `{s1.indexFound}/{s1.indexCards} {s1.indexCount}`)
check("a aba aberta montou os cartões dela", s1.indexBuilt >= 18, tostring(s1.indexBuilt)) -- a do vulcão só monta quando abre
check("trocar de aba", ui("indexTab", 2) == 2, "aba 2")
task.wait(0.3)
local s2 = ui()
check("aba VOLCANO: 1 de 18", s2.indexWorld == 2 and s2.indexCards == 18 and s2.indexFound == 1 and s2.indexCount == "1/18 FOUND" and s2.indexBuilt == 36, `{s2.indexFound}/{s2.indexCards} {s2.indexCount} {s2.indexBuilt}`)
ui("indexTab", 1)
ui("toggle", "Index")
hook:Invoke("set", player, { index = {}, levels = {} })

-- Poder pelo dano no golem e defesa no golpe de verdade
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
check("desafio acorda", boss("challenge") == true, "acordou")
task.wait(Anims.clips.Wake.length + 0.6)
check("barra do chefe mostra a pena", string.find(ui("golem").pity, `0/{Config.Boss.pity}`, 1, true) ~= nil, ui("golem").pity)

local center = Config.BossRoom.center + Config.Worlds[1].offset
local function put(offset: Vector3)
	local at = (boss("state").cframe * CFrame.new(offset)).Position
	local char = player.Character :: Model
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart
	root.AssemblyLinearVelocity = Vector3.zero
	char:PivotTo(CFrame.new(Vector3.new(at.X, center.Y + 3, at.Z)))
end
boss("place", { position = center, yaw = math.pi, rest = 30 })
task.wait(0.3)
put(Vector3.new(0, 0, -(BOSS.radius * S + 4)))
task.wait(0.3)

-- ganho esperado antes do soco (a 1ª aura chega sozinha com o Poder e multiplica os seguintes)
local function expected(damage: number): number
	local p = state()
	local aura = Config.AuraById[p.aura]
	local multiplier = if aura and p.power >= aura.power then aura.multiplier else 1
	return math.floor(Config.Bag.levels[p.bagLevel].power * damage * BOSS.powerPerDamage * multiplier)
end
local want = expected(1)
local before = state().power
local d1 = boss("punch", false) -- vida tirada por um soco cheio (cresce com o Poder: CombatBalance)
local gain1 = state().power - before
check("soco válido dá Poder", d1 >= 1 and gain1 == want and want > 0, `{d1} +{gain1} (esperado {want})`)
before = state().power
check("soco antes do ritmo não conta nem dá Poder", boss("punch", false) == 0 and state().power == before, tostring(state().power - before))
task.wait(BOSS.hitCooldown + 0.05)
want = expected(2)
local d2 = boss("punch", true)
check("crítico (dano 2) dá o dobro", d2 == d1 * 2 and state().power - before == want, `+{state().power - before} (esperado {want})`)
put(Vector3.new(0, 0, -(BOSS.hitRange * S + 6)))
task.wait(BOSS.hitCooldown + 0.05)
before = state().power
check("de longe não conta nem dá Poder", boss("punch", false) == 0 and state().power == before, "longe")
put(Vector3.new(0, 0, -(BOSS.radius * S + 4)))
-- último soco: com a vida de um soco cheio, o crítico só vale um soco
boss("hp", d1)
task.wait(BOSS.hitCooldown + 0.05)
before = state().power
want = expected(1)
local last = boss("punch", true)
check("o último soco vale só a vida que restava", last == d1 and state().power - before == want, `{last} +{state().power - before} (esperado {want})`)
check("golem morto: soco não dá Poder", (function()
	task.wait(BOSS.hitCooldown + 0.05)
	local b = state().power
	return boss("punch", false) == 0 and state().power == b
end)(), "morto")
task.wait(Anims.clips.Death.events.crumble + 2.2)
local best = Config.bestCharacter(Config.Worlds[1])
local firstWin = state().bossWins["1"] or 0
check("a vitória conta para a pena", firstWin == 1 or (firstWin == 0 and state().index[best] == true), tostring(firstWin))
check("atributo BossWins replica", string.find(player:GetAttribute("BossWins") or "", "1:" .. firstWin, 1, true) ~= nil, tostring(player:GetAttribute("BossWins")))

-- pena: a 30ª vitória garante o melhor personagem do mundo e zera o contador
hook:Invoke("set", player, { bossWins = { ["1"] = Config.Boss.pity - 2 }, inventory = {} })
local r1 = hook:Invoke("bossReward", player)
check("vitória 29 não é a pena", r1[3] == false and (state().bossWins["1"] == Config.Boss.pity - 1 or r1[1] == best), `{r1[1]} {state().bossWins["1"]}`)
hook:Invoke("set", player, { bossWins = { ["1"] = Config.Boss.pity - 1 } })
local r2 = hook:Invoke("bossReward", player)
check("vitória 30 garante o melhor do mundo", r2[1] == best and r2[3] == true and state().bossWins["1"] == 0, `{r2[1]} {state().bossWins["1"]}`)
check("melhor do mundo 1 é o Mítico de maior renda", Config.CharacterById[best].rarity == #Config.Rarities and best == "abyss_titan", best)
check("no vulcão a pena dá a versão de magma", Config.bestCharacter(Config.Worlds[2]) == best .. Config.Worlds[2].suffix, Config.bestCharacter(Config.Worlds[2]))

-- sorte da vitória: do Raro para cima sai mais que no sorteio comum da última parede
local N = 1000
local rareVictory = 0
for _ = 1, N do
	hook:Invoke("set", player, { bossWins = {}, inventory = {} })
	local id = hook:Invoke("bossReward", player)[1]
	if Config.CharacterById[id].rarity >= Config.Roll.luckFrom then
		rareVictory += 1
	end
end
local last = walls[#walls]
local tierBase = last.luck
for _, wall in walls do
	if wall.tier == last.tier then
		tierBase = math.min(tierBase, wall.luck)
	end
end
local wallBoost = (last.luck / tierBase) ^ Config.Roll.wallLuckPower
local rareWeight, commonWeight = 0, 0
for rarity, weight in Config.Roll.odds[last.tier] do
	if rarity >= Config.Roll.luckFrom then
		rareWeight += weight
	else
		commonWeight += weight
	end
end
local function share(boost: number): number
	return rareWeight * boost / (commonWeight + rareWeight * boost)
end
local plainRare = share(wallBoost)
local victoryRare = share(wallBoost * Config.Boss.victoryLuck)
local boosted = rareVictory / N
check("vitória puxa mais Raro+ que o sorteio comum", boosted > (plainRare + victoryRare) / 2 and boosted < victoryRare + 0.07, `{boosted} (comum {plainRare}, esperado {victoryRare})`)
hook:Invoke("set", player, { bossWins = {}, inventory = {} })

-- defesa no golpe real: o mesmo esmagamento com DEFENSE no máximo tira menos
boss("reset")
task.wait(0.5)
boss("pending", true)
boss("challenge")
task.wait(Anims.clips.Wake.length + 0.6)
local A = BOSS.attacks
local function slam(): number
	boss("place", { position = center, yaw = math.pi, rest = 30 })
	task.wait(0.2)
	local h = humanoid()
	h.Health = h.MaxHealth
	put(Vector3.new(0, 0, -A.Slam.ahead - 2))
	local lowest = h.Health
	local watching = h.HealthChanged:Connect(function(health)
		lowest = math.min(lowest, health)
	end)
	local start = h.Health
	boss("attack", "Slam")
	task.wait(Anims.clips.Slam.events.impact + 1.7)
	boss("rest", 30)
	watching:Disconnect()
	return start - lowest
end
hook:Invoke("set", player, { stats = {} })
local plain = slam()
hook:Invoke("set", player, { stats = { defense = Config.Stats.defense.max } })
local defended = slam()
local rage = boss("state").rage
local raw = A.Slam.damage * (if rage then BOSS.rageDamage else 1)
check("sem defesa, dano cheio", math.abs(plain - raw) <= 1, `{plain} vs {raw}`)
check("com defesa, dano reduzido uma vez", math.abs(defended - Config.defendedDamage(raw, Config.Stats.defense.max)) <= 1 and defended < plain, `{defended} vs {Config.defendedDamage(raw, Config.Stats.defense.max)}`)
humanoid().Health = humanoid().MaxHealth

hook:Invoke("leaveRoom", player)
hook:Invoke("set", player, { power = 0, money = 0, stats = {}, boosts = {} })
return `{#passed} verificações OK: ` .. table.concat(passed, "; ")
