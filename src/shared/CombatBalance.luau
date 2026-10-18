--!strict
-- Fórmulas do combate contra chefes: dano por soco, vida do chefe, DPS e TTK esperados.
-- Tudo vem de Config.Combat (fórmulas) e Config.Bosses (um chefe por linha); nada aqui é
-- específico de um chefe, então chefes novos só pedem uma linha no Config.
-- O servidor aplica o dano (Boss.luau); este módulo só calcula, e os testes usam as mesmas contas.

local Config = require(script.Parent.Config)

local CombatBalance = {}

export type BossDef = {
	id: number,
	name: string,
	minPower: number,
	ttk: number,
	hpScale: number?,
	curve: { { number } }?,
}

-- Config do chefe; um id além da lista usa o último (nunca devolve nil).
function CombatBalance.boss(id: number): BossDef
	return Config.Bosses[id] or Config.Bosses[#Config.Bosses]
end

-- Multiplicador do dano para um Poder, em relação ao Poder mínimo do chefe.
function CombatBalance.damageMultiplier(power: number, bossId: number): number
	local C = Config.Combat
	local def = CombatBalance.boss(bossId)
	local curve = def.curve or C.curve
	local ratio = math.max(power, 0) / def.minPower
	local first = curve[1]
	if ratio <= first[1] then
		return math.max(first[2] * ratio / first[1], C.minMult)
	end
	for i = 2, #curve do
		local a, b = curve[i - 1], curve[i]
		if ratio <= b[1] then
			return a[2] + (b[2] - a[2]) * (ratio - a[1]) / (b[1] - a[1])
		end
	end
	local a, b = curve[#curve - 1], curve[#curve]
	local slope = if a then (b[2] - a[2]) / (b[1] - a[1]) else 0
	return math.min(b[2] + slope * (ratio - b[1]), C.maxMult)
end

-- Vida tirada por um soco normal (inteira, no mínimo 1). O crítico multiplica por critMultiplier.
function CombatBalance.punchDamage(power: number, bossId: number): number
	local raw = Config.Combat.baseDamage * CombatBalance.damageMultiplier(power, bossId)
	return math.max(1, math.floor(raw + 1e-6))
end

-- Dano médio por soco com uma chance de crítico.
function CombatBalance.averageDamage(power: number, bossId: number, critChance: number): number
	local damage = CombatBalance.punchDamage(power, bossId)
	return damage * (1 + critChance * (Config.Combat.critMultiplier - 1))
end

-- Vida do chefe por jogador na luta: o que o ritmo de referência tira em `ttk` segundos com o
-- Poder mínimo. hpScale deixa um chefe mais ou menos resistente sem mexer na fórmula.
function CombatBalance.bossHp(bossId: number): number
	local C = Config.Combat
	local def = CombatBalance.boss(bossId)
	local perSecond = C.baseDamage * C.hitsPerSecond * (1 + C.critChance * (C.critMultiplier - 1))
	return math.max(1, math.floor(perSecond * def.ttk * (def.hpScale or 1) + 0.5))
end

-- DPS esperado: socos/s x dano médio. hitsPerSecond e critChance são opcionais (valores de referência).
function CombatBalance.expectedDps(power: number, bossId: number, critChance: number?, hitsPerSecond: number?): number
	local C = Config.Combat
	return (hitsPerSecond or C.hitsPerSecond) * CombatBalance.averageDamage(power, bossId, critChance or C.critChance)
end

-- Tempo esperado para vencer (segundos), contando só o ritmo dos socos (sem animações, esquivas
-- ou pausas do jogador).
function CombatBalance.expectedTtk(power: number, bossId: number, critChance: number?, hitsPerSecond: number?): number
	return CombatBalance.bossHp(bossId) / CombatBalance.expectedDps(power, bossId, critChance, hitsPerSecond)
end

function CombatBalance.canEnter(power: number, bossId: number): boolean
	return power >= CombatBalance.boss(bossId).minPower
end

return CombatBalance
