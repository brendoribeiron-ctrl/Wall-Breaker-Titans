--!strict
-- Poses do Shidori, quadro a quadro (cliente: src/client/Shidori.luau aplica pela camada de Pose,
-- que já espelha a pose para os outros jogadores). Tempos das fases: Config.Shidori.
--
-- Leitura das referências (shots/shidori/ref, 18/10): agacha com a mão esquerda baixa e para trás,
-- quase no chão, a direita segurando o pulso esquerdo; a energia cresce ali; explode em luz; o
-- corpo avança e a palma esquerda vai à frente; volta devagar.
--
-- Ângulos em graus nas juntas R15 (Transform do Motor6D/AnimationConstraint):
--  * Root = { descida em studs, x, y, z }; Waist/Neck: +X inclina para trás, +Y gira para a esquerda;
--  * ombros: +X leva o braço para a frente/cima; +Z leva o braço para a direita do boneco
--    (no esquerdo = para dentro, no direito = para fora); cotovelo: +X dobra; quadril: +X perna à
--    frente; joelho: negativo dobra. Tornozelos são calculados (pé chato no chão).

local Config = require(script.Parent.Config)

local ShidoriMoves = {}

type Raw = {
	t: number,
	ease: string?,
	root: { number }?,
	waist: { number }?,
	neck: { number }?,
	lShoulder: { number }?,
	lElbow: { number }?,
	lWrist: { number }?,
	rShoulder: { number }?,
	rElbow: { number }?,
	rWrist: { number }?,
	rHip: { number }?,
	lHip: { number }?,
	rKnee: number?,
	lKnee: number?,
}

export type Key = { t: number, ease: string, joints: { [string]: CFrame } }

local S = Config.Shidori

local function rad(v: { number }?): CFrame
	if not v then
		return CFrame.identity
	end
	return CFrame.Angles(math.rad(v[1] or 0), math.rad(v[2] or 0), math.rad(v[3] or 0))
end

local function joints(raw: Raw): { [string]: CFrame }
	local root = raw.root or { 0, 0, 0, 0 }
	local rHip = raw.rHip or { 0, 0, 0 }
	local lHip = raw.lHip or { 0, 0, 0 }
	local rKnee = raw.rKnee or 0
	local lKnee = raw.lKnee or 0
	local rx, rz = root[2] or 0, root[4] or 0
	return {
		Root = CFrame.new(0, -(root[1] or 0), 0) * rad({ rx, root[3] or 0, rz }),
		Waist = rad(raw.waist),
		Neck = rad(raw.neck),
		LeftShoulder = rad(raw.lShoulder),
		LeftElbow = rad(raw.lElbow),
		LeftWrist = rad(raw.lWrist),
		RightShoulder = rad(raw.rShoulder),
		RightElbow = rad(raw.rElbow),
		RightWrist = rad(raw.rWrist),
		RightHip = rad(rHip),
		LeftHip = rad(lHip),
		RightKnee = rad({ rKnee, 0, 0 }),
		LeftKnee = rad({ lKnee, 0, 0 }),
		RightAnkle = rad({ -(rx + rHip[1] + rKnee), 0, -(rz + (rHip[3] or 0)) }),
		LeftAnkle = rad({ -(rx + lHip[1] + lKnee), 0, -(rz + (lHip[3] or 0)) }),
	}
end

local NEUTRAL: Raw = { t = 0 }

-- Calibrado no avatar do Studio (AnimationConstraint, 18/10): inclinar o tronco para a frente
-- joga o braço pendurado para trás, então o ombro quase não gira para trás; a descida do Root
-- precisa de joelho bem dobrado, senão o pé entra no chão.
-- preparo: o peso desce, o ombro esquerdo recua e o braço começa a descer para trás
local PREP: Raw = {
	t = S.prep,
	ease = "out",
	root = { 0.45, 0, 0, 0 },
	waist = { -20, 14, 0 },
	neck = { 14, -10, 0 },
	lShoulder = { 14, 0, -14 },
	lElbow = { 12, 0, 0 },
	lWrist = { -15, 0, 0 },
	rShoulder = { 22, 0, -20 },
	rElbow = { 60, 0, 0 },
	rHip = { 34, 0, 6 },
	lHip = { -6, 0, -6 },
	rKnee = -60,
	lKnee = -40,
}

-- acúmulo: agachado e virado, mão esquerda aberta lá embaixo e atrás, a direita segura o pulso
local CHARGE: Raw = {
	t = S.charge,
	ease = "inout",
	root = { 0.95, 0, 0, 0 },
	waist = { -38, 22, 0 },
	neck = { 26, -16, 0 },
	lShoulder = { 30, 0, -20 },
	lElbow = { 8, 0, 0 },
	lWrist = { -35, 0, 0 },
	rShoulder = { 35, 0, -28 },
	rElbow = { 95, 0, 0 },
	rHip = { 62, 0, 8 },
	lHip = { -8, 0, -8 },
	rKnee = -112,
	lKnee = -78,
}

-- explosão: o corpo ainda carregado sobe um pouco, a mão vem para o lado do quadril (mira)
local BURST: Raw = {
	t = S.burst,
	ease = "out",
	root = { 0.85, 0, 0, 0 },
	waist = { -34, 18, 0 },
	neck = { 24, -14, 0 },
	lShoulder = { 42, 0, -22 },
	lElbow = { 14, 0, 0 },
	lWrist = { -40, 0, 0 },
	rShoulder = { 25, 0, -18 },
	rElbow = { 70, 0, 0 },
	rHip = { 58, 0, 8 },
	lHip = { -8, 0, -8 },
	rKnee = -104,
	lKnee = -72,
}

-- investida: o tronco gira e leva o ombro esquerdo à frente, palma esquerda esticada, braço
-- direito para trás equilibrando; perna esquerda à frente
local STRIKE: Raw = {
	t = S.strike,
	ease = "out",
	root = { 0.55, 0, 0, 0 },
	waist = { -18, -28, 0 },
	neck = { 12, 22, 0 },
	lShoulder = { 88, 0, 6 },
	lElbow = { 4, 0, 0 },
	lWrist = { -62, 0, 0 },
	rShoulder = { -42, 0, 22 },
	rElbow = { 34, 0, 0 },
	rHip = { -30, 0, 4 },
	lHip = { 42, 0, -4 },
	rKnee = -22,
	lKnee = -40,
}

-- segura um instante com o braço esticado (a energia ainda presa na mão)
local HOLD: Raw = table.clone(STRIKE)
HOLD.t = S.hit[2]
HOLD.ease = "linear"
HOLD.root = { 0.6, 0, 0, 0 }
HOLD.lShoulder = { 84, 0, 4 }

local RECOVER: Raw = { t = S.recover, ease = "inout" }

local RAWS = { NEUTRAL, PREP, CHARGE, BURST, STRIKE, HOLD, RECOVER }
local NAMES = { neutral = NEUTRAL, prep = PREP, charge = CHARGE, burst = BURST, strike = STRIKE, hold = HOLD, recover = RECOVER }

local KEYS: { Key } = {}
local function compile()
	table.clear(KEYS)
	for _, raw in RAWS do
		table.insert(KEYS, { t = raw.t, ease = raw.ease or "linear", joints = joints(raw) })
	end
end
compile()
ShidoriMoves.KEYS = KEYS

-- Ajuste ao vivo (capturas no Studio): troca campos de uma chave e recompila. Não salva.
function ShidoriMoves.tweak(name: string, fields: { [string]: any }): boolean
	local raw = NAMES[name]
	if not raw then
		return false
	end
	for key, value in fields do
		(raw :: any)[key] = value
	end
	compile()
	return true
end
ShidoriMoves.DURATION = S.recover

local function ease(kind: string, x: number): number
	if kind == "out" then
		return 1 - (1 - x) ^ 3
	elseif kind == "in" then
		return x ^ 3
	elseif kind == "inout" then
		return if x < 0.5 then 4 * x ^ 3 else 1 - (-2 * x + 2) ^ 3 / 2
	end
	return x
end

-- Juntas no tempo t (sempre as mesmas chaves; fora da faixa, a primeira ou a última).
function ShidoriMoves.sample(t: number): { [string]: CFrame }
	if t <= KEYS[1].t then
		return KEYS[1].joints
	end
	for i = 2, #KEYS do
		local b = KEYS[i]
		if t <= b.t then
			local a = KEYS[i - 1]
			local alpha = ease(b.ease, (t - a.t) / math.max(b.t - a.t, 1e-3))
			local out = {}
			for name, cf in a.joints do
				out[name] = cf:Lerp(b.joints[name], alpha)
			end
			return out
		end
	end
	return KEYS[#KEYS].joints
end

-- Peso da camada no tempo t: entra no preparo e sai no fim da recuperação.
function ShidoriMoves.weight(t: number): number
	if t < S.prep then
		return math.clamp(t / S.prep, 0, 1)
	elseif t > S.recover - 0.25 then
		return math.clamp((S.recover - t) / 0.25, 0, 1)
	end
	return 1
end

-- Onde a palma conta para o dano, no espaço do HumanoidRootPart (servidor), por altura do avatar.
function ShidoriMoves.palm(scale: number): Vector3
	return Vector3.new(-0.4, 0.4, -2.8) * scale
end

return ShidoriMoves
