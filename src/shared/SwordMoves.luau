--!strict
-- Combo M1 da espada do Asta: os golpes, quadro a quadro, usados pelos dois lados.
--  * cliente (src/client/SwordCombat.luau): pose do corpo + onde a espada tem que estar; os braços
--    vão até o cabo por IK (as duas mãos na empunhadura).
--  * servidor (src/server/SwordCombat.luau): o mesmo quadro diz onde a lâmina passa, e é por ela
--    que o acerto é conferido (o cliente nunca diz se acertou).
--
-- Cada chave: t (s desde o início do golpe), ease (como chega nela), corpo em graus e a espada no
-- espaço do UpperTorso: p = ponto da pegada (mão direita, logo abaixo da guarda) em relação ao meio
-- dos ombros, em studs do rig de referência (escala pelo comprimento do braço); d = para onde a
-- ponta aponta. O gume (largura da lâmina) é calculado: ele lidera o golpe (eixo médio de giro
-- da lâmina nas chaves do corte). Corpo: root = { descida, x, y, z } na junta do quadril;
-- tronco/cabeça +X inclina para trás, +Y gira para a esquerda; pernas +X para a frente.
-- Tornozelos e pescoço são automáticos (pé no chão, olhar para a frente).
--
-- Janelas (s): hit = lâmina valendo dano; trail = rastro aceso; chain = clique que já encadeia o
-- próximo golpe (antes disso o clique fica guardado e sai no começo da janela); impact = golpe
-- que bate no chão. Dano e demais números de balanceamento: Config.Sword.

local SwordMoves = {}

export type Pose = { joints: { [string]: CFrame }, hold: CFrame }
export type Key = { t: number, ease: string, pose: Pose }
export type Move = {
	name: string,
	duration: number,
	hit: { number },
	trail: { number },
	chain: { number }?,
	impact: number?,
	keys: { Key },
}
export type Rig = {
	joints: { [string]: { c0: CFrame, c1: CFrame } },
	scale: number,
}

local REF_REACH = 1.34 -- ombro → cotovelo → punho do rig R15 em que as chaves foram feitas
SwordMoves.BODY = { "Root", "Waist", "Neck", "RightHip", "LeftHip", "RightKnee", "LeftKnee", "RightAnkle", "LeftAnkle" }
SwordMoves.ARM_JOINTS = { "RightShoulder", "RightElbow", "RightWrist", "LeftShoulder", "LeftElbow", "LeftWrist" }
-- onde a mão esquerda fica no cabo: abaixo da direita, na direção do pomo
SwordMoves.LEFT_ON_GRIP = 0.42

local function rad(v: { number }?): CFrame
	if not v then
		return CFrame.identity
	end
	return CFrame.Angles(math.rad(v[1] or 0), math.rad(v[2] or 0), math.rad(v[3] or 0))
end

type Raw = {
	t: number,
	ease: string?,
	root: { number }?,
	waist: { number }?,
	rHip: { number }?,
	lHip: { number }?,
	rKnee: number?,
	lKnee: number?,
	p: Vector3,
	d: Vector3,
	strike: boolean?, -- chave que entra no cálculo do eixo do corte
}

-- guarda com as duas mãos: lâmina à frente, ponta um pouco para cima
local READY: Raw = {
	t = 0,
	root = { 0.15, 0, 0, 0 },
	waist = { -4, 8, 0 },
	rHip = { -6, 0, 6 },
	lHip = { 12, 0, -6 },
	rKnee = -18,
	lKnee = -16,
	p = Vector3.new(0.12, -0.85, -0.8),
	d = Vector3.new(0.1, 0.45, -0.89),
}

local function body(raw: Raw): { [string]: CFrame }
	local root = raw.root or READY.root :: { number }
	local waist = raw.waist or READY.waist :: { number }
	local rHip = raw.rHip or READY.rHip :: { number }
	local lHip = raw.lHip or READY.lHip :: { number }
	local rKnee = raw.rKnee or READY.rKnee :: number
	local lKnee = raw.lKnee or READY.lKnee :: number
	local rx, rz = root[2] or 0, root[4] or 0
	return {
		Root = CFrame.new(0, -(root[1] or 0), 0) * rad({ rx, root[3] or 0, rz }),
		Waist = rad(waist),
		-- a cabeça devolve parte do giro e da inclinação: o olhar fica no alvo
		Neck = rad({ -(waist[1] + rx) * 0.6, -((waist[2] or 0) + (root[3] or 0)) * 0.55, -(waist[3] or 0) * 0.5 }),
		RightHip = rad(rHip),
		LeftHip = rad(lHip),
		RightKnee = rad({ rKnee, 0, 0 }),
		LeftKnee = rad({ lKnee, 0, 0 }),
		-- pé chato no chão: desfaz a inclinação do quadril, da coxa e do joelho
		RightAnkle = rad({ -(rx + rHip[1] + rKnee), 0, -(rz + (rHip[3] or 0)) }),
		LeftAnkle = rad({ -(rx + lHip[1] + lKnee), 0, -(rz + (lHip[3] or 0)) }),
	}
end

local function holdFrame(p: Vector3, d: Vector3, axis: Vector3): CFrame
	local y = d.Unit
	local edge = axis:Cross(y)
	if edge.Magnitude < 1e-3 then
		edge = Vector3.xAxis:Cross(y)
	end
	local x = edge.Unit
	return CFrame.fromMatrix(p, x, y, x:Cross(y))
end

local function compile(name: string, spec: { [string]: any }, raws: { Raw }): Move
	-- eixo do corte: soma dos giros entre chaves seguidas marcadas como strike
	local axis = Vector3.zero
	for i = 1, #raws - 1 do
		if raws[i].strike and raws[i + 1].strike then
			axis += raws[i].d.Unit:Cross(raws[i + 1].d.Unit)
		end
	end
	axis = if axis.Magnitude > 1e-3 then axis.Unit else Vector3.xAxis
	local keys: { Key } = {}
	for _, raw in raws do
		table.insert(keys, { t = raw.t, ease = raw.ease or "inout", pose = { joints = body(raw), hold = holdFrame(raw.p, raw.d, axis) } })
	end
	local last = keys[#keys]
	return {
		name = name,
		duration = last.t,
		hit = spec.hit,
		trail = spec.trail,
		chain = spec.chain,
		impact = spec.impact,
		keys = keys,
	}
end

-- 1) Corte diagonal descendo da direita para a esquerda: arma por cima do ombro direito, pausa
--    pesada no alto, desce acelerando por cima e na frente, termina baixa à esquerda com o peso na
--    perna esquerda.
local SLASH = compile("Slash", { hit = { 0.33, 0.44 }, trail = { 0.3, 0.47 }, chain = { 0.42, 0.98 } }, {
	READY,
	{ t = 0.2, ease = "inout", root = { 0.1, 4, -10, 0 }, waist = { 6, -34, 0 }, rHip = { -6, 0, 9 }, rKnee = -26, lHip = { 12, 0, -6 }, lKnee = -10,
		p = Vector3.new(0.55, 0.2, -0.25), d = Vector3.new(0.45, 0.55, 0.7) },
	{ t = 0.28, ease = "out", root = { 0.12, 5, -12, 0 }, waist = { 8, -40, 0 }, rHip = { -6, 0, 9 }, rKnee = -30, lHip = { 12, 0, -6 }, lKnee = -10,
		p = Vector3.new(0.6, 0.3, -0.2), d = Vector3.new(0.42, 0.62, 0.66), strike = true },
	{ t = 0.335, ease = "in", root = { 0.18, 0, -4, 0 }, waist = { 0, -12, 0 }, rHip = { -4, 0, 9 }, rKnee = -22, lHip = { 16, 0, -6 }, lKnee = -18,
		p = Vector3.new(0.35, 0.0, -0.85), d = Vector3.new(0.1, 0.9, -0.42), strike = true },
	{ t = 0.38, ease = "linear", root = { 0.3, -6, 4, 0 }, waist = { -12, 14, 0 }, rHip = { -10, 0, 10 }, rKnee = -18, lHip = { 24, 0, -8 }, lKnee = -34,
		p = Vector3.new(-0.05, -0.6, -1.0), d = Vector3.new(-0.35, -0.25, -0.9), strike = true },
	{ t = 0.45, ease = "out", root = { 0.4, -10, 10, 0 }, waist = { -18, 34, 0 }, rHip = { -16, 0, 10 }, rKnee = -20, lHip = { 28, 0, -8 }, lKnee = -44,
		p = Vector3.new(-0.5, -0.95, -0.6), d = Vector3.new(-0.8, -0.5, -0.3), strike = true },
	{ t = 0.78, ease = "inout", root = { 0.3, -6, 8, 0 }, waist = { -10, 26, 0 }, rHip = { -12, 0, 9 }, rKnee = -18, lHip = { 22, 0, -8 }, lKnee = -34,
		p = Vector3.new(-0.35, -0.9, -0.75), d = Vector3.new(-0.55, -0.3, -0.78) },
})

-- 2) Varredura horizontal da esquerda para a direita, na altura da cintura: puxa a lâmina para
--    trás pela esquerda girando o tronco, segura, e gira o corpo inteiro levando a espada até a
--    direita; termina com ela subindo para o ombro (preparo do golpe final).
local SWEEP = compile("Sweep", { hit = { 0.3, 0.43 }, trail = { 0.28, 0.46 }, chain = { 0.44, 1.0 } }, {
	READY,
	{ t = 0.18, ease = "inout", root = { 0.25, -4, 12, 0 }, waist = { -4, 45, 0 }, rHip = { -10, 0, 12 }, rKnee = -16, lHip = { 6, 0, -12 }, lKnee = -26,
		p = Vector3.new(-0.6, -0.55, -0.35), d = Vector3.new(-0.75, 0.08, 0.65) },
	{ t = 0.26, ease = "out", root = { 0.27, -4, 14, 0 }, waist = { -4, 50, 0 }, rHip = { -10, 0, 12 }, rKnee = -16, lHip = { 6, 0, -12 }, lKnee = -28,
		p = Vector3.new(-0.62, -0.5, -0.3), d = Vector3.new(-0.78, 0.1, 0.6), strike = true },
	{ t = 0.31, ease = "in", root = { 0.3, -6, 8, 0 }, waist = { -6, 22, 0 }, rHip = { 0, 0, 12 }, rKnee = -22, lHip = { 2, 0, -12 }, lKnee = -22,
		p = Vector3.new(-0.45, -0.55, -0.95), d = Vector3.new(-0.75, 0.0, -0.65), strike = true },
	{ t = 0.355, ease = "linear", root = { 0.35, -8, 0, 0 }, waist = { -8, -8, 0 }, rHip = { 10, 0, 12 }, rKnee = -30, lHip = { -6, 0, -12 }, lKnee = -18,
		p = Vector3.new(0.1, -0.55, -1.1), d = Vector3.new(0.15, -0.02, -0.99), strike = true },
	{ t = 0.4, ease = "linear", root = { 0.35, -8, -8, 0 }, waist = { -8, -34, 0 }, rHip = { 16, 0, 12 }, rKnee = -34, lHip = { -12, 0, -12 }, lKnee = -16,
		p = Vector3.new(0.6, -0.5, -0.75), d = Vector3.new(0.85, 0.0, -0.5), strike = true },
	{ t = 0.48, ease = "out", root = { 0.35, -6, -14, 0 }, waist = { -6, -50, 0 }, rHip = { 20, 0, 10 }, rKnee = -36, lHip = { -15, 0, -10 }, lKnee = -16,
		p = Vector3.new(0.75, -0.4, -0.2), d = Vector3.new(0.8, 0.1, 0.55), strike = true },
	{ t = 0.8, ease = "inout", root = { 0.2, 0, -8, 0 }, waist = { 2, -30, 0 }, rHip = { 6, 0, 10 }, rKnee = -24, lHip = { -4, 0, -10 }, lKnee = -14,
		p = Vector3.new(0.6, -0.15, -0.35), d = Vector3.new(0.6, 0.55, 0.55) },
})

-- 3) Golpe final de cima para baixo: ergue a espada acima da cabeça (inclinando para trás para
--    aguentar o peso), segura no alto, e desce com o corpo todo até a lâmina bater no chão à frente;
--    fica cravado um instante e levanta devagar.
local SLAM = compile("Slam", { hit = { 0.46, 0.58 }, trail = { 0.42, 0.56 }, impact = 0.52 }, {
	READY,
	{ t = 0.22, ease = "inout", root = { 0.05, 6, 0, 0 }, waist = { 10, -6, 0 }, rHip = { -4, 0, 10 }, rKnee = -12, lHip = { 10, 0, -10 }, lKnee = -12,
		p = Vector3.new(0.15, 0.55, 0.0), d = Vector3.new(0.1, 0.6, 0.79) },
	{ t = 0.36, ease = "out", root = { 0.0, 8, 0, 0 }, waist = { 16, -4, 0 }, rHip = { -4, 0, 10 }, rKnee = -8, lHip = { 10, 0, -10 }, lKnee = -8,
		p = Vector3.new(0.1, 0.75, 0.15), d = Vector3.new(0.05, 0.25, 0.97), strike = true },
	{ t = 0.43, ease = "in", root = { 0.15, 0, 0, 0 }, waist = { 4, -2, 0 }, rHip = { 0, 0, 10 }, rKnee = -20, lHip = { 18, 0, -10 }, lKnee = -24,
		p = Vector3.new(0.05, 0.55, -0.55), d = Vector3.new(0.02, 0.97, -0.25), strike = true },
	{ t = 0.48, ease = "linear", root = { 0.38, -8, 0, 0 }, waist = { -15, 0, 0 }, rHip = { -6, 0, 12 }, rKnee = -40, lHip = { 30, 0, -10 }, lKnee = -50,
		p = Vector3.new(0.0, -0.3, -1.05), d = Vector3.new(0.0, 0.1, -1.0), strike = true },
	{ t = 0.52, ease = "out", root = { 0.6, -8, 0, 0 }, waist = { -18, 0, 0 }, rHip = { -10, 0, 12 }, rKnee = -55, lHip = { 38, 0, -10 }, lKnee = -66,
		p = Vector3.new(0.0, -0.75, -0.95), d = Vector3.new(0.0, 0.24, -0.97), strike = true },
	{ t = 0.7, ease = "out", root = { 0.65, -9, 0, 0 }, waist = { -20, 0, 0 }, rHip = { -10, 0, 12 }, rKnee = -58, lHip = { 40, 0, -10 }, lKnee = -70,
		p = Vector3.new(0.0, -0.8, -0.95), d = Vector3.new(0.0, 0.2, -0.98) },
	{ t = 1.15, ease = "inout", root = { 0.18, 0, 0, 0 }, waist = { -5, 6, 0 }, rHip = { -6, 0, 6 }, rKnee = -18, lHip = { 12, 0, -6 }, lKnee = -16,
		p = Vector3.new(0.15, -0.85, -0.75), d = Vector3.new(0.15, 0.3, -0.94) },
})

SwordMoves.COMBO = { SLASH, SWEEP, SLAM }

local function ease(kind: string, x: number): number
	if kind == "in" then
		return x * x * x
	elseif kind == "out" then
		return 1 - (1 - x) ^ 3
	elseif kind == "linear" then
		return x
	end
	return x * x * (3 - 2 * x)
end

function SwordMoves.lerp(a: Pose, b: Pose, alpha: number): Pose
	local joints = {}
	for name, cf in a.joints do
		joints[name] = cf:Lerp(b.joints[name] or cf, alpha)
	end
	return { joints = joints, hold = a.hold:Lerp(b.hold, alpha) }
end

-- Pose do golpe no tempo t. from: pose de onde o golpe parte (o fim do anterior, num combo);
-- sem from, parte da primeira chave.
function SwordMoves.sample(move: Move, t: number, from: Pose?): Pose
	local keys = move.keys
	if t <= 0 then
		return from or keys[1].pose
	end
	for i = 2, #keys do
		local key = keys[i]
		if t <= key.t then
			local prev = keys[i - 1]
			local a = if i == 2 and from then from else prev.pose
			local x = (t - prev.t) / math.max(key.t - prev.t, 1e-3)
			return SwordMoves.lerp(a, key.pose, ease(key.ease, x))
		end
	end
	return keys[#keys].pose
end

---------------------------------------------------------------------------------------------------
-- Rig: as juntas do boneco (Motor6D ou AnimationConstraint dos avatares novos). Parte1 =
-- Parte0 * c0 * Transform * c1⁻¹. Lido do boneco real: cada avatar tem medidas próprias.

local function jointOf(instance: Instance): { c0: CFrame, c1: CFrame }?
	if instance:IsA("Motor6D") then
		return { c0 = instance.C0, c1 = instance.C1 }
	elseif instance:IsA("AnimationConstraint") then
		local a0, a1 = instance.Attachment0, instance.Attachment1
		if a0 and a1 then
			return { c0 = a0.CFrame, c1 = a1.CFrame }
		end
	end
	return nil
end

function SwordMoves.rig(character: Model): Rig?
	local joints = {}
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("Motor6D") or descendant:IsA("AnimationConstraint") then
			local joint = jointOf(descendant)
			if joint then
				joints[descendant.Name] = joint
			end
		end
	end
	for _, name in { "Root", "Waist", "RightShoulder", "LeftShoulder", "RightElbow", "LeftElbow", "RightWrist", "LeftWrist" } do
		if not joints[name] then
			return nil -- R6 ou rig sem as juntas do R15
		end
	end
	local shoulder, elbow = joints.RightShoulder, joints.RightElbow
	local reach = (elbow.c0.Position - shoulder.c1.Position).Magnitude + (joints.RightWrist.c0.Position - elbow.c1.Position).Magnitude
	return { joints = joints, scale = reach / REF_REACH }
end

-- UpperTorso no espaço do HumanoidRootPart para a pose do golpe.
function SwordMoves.chest(rig: Rig, pose: Pose): CFrame
	local j = rig.joints
	local root = pose.joints.Root
	root = CFrame.new(root.Position * rig.scale) * root.Rotation
	return j.Root.c0 * root * j.Root.c1:Inverse() * j.Waist.c0 * pose.joints.Waist * j.Waist.c1:Inverse()
end

-- Ponto de pegada da espada (o attachment Hold, +Y = ponta) no espaço do HumanoidRootPart.
function SwordMoves.hold(rig: Rig, pose: Pose): CFrame
	local j = rig.joints
	local mid = (j.RightShoulder.c0.Position + j.LeftShoulder.c0.Position) / 2
	local hold = pose.hold
	return SwordMoves.chest(rig, pose) * CFrame.new(mid + hold.Position * rig.scale) * hold.Rotation
end

-- Ponta da lâmina no espaço do ponto de pegada (Hold) da espada equipada (já com a escala).
function SwordMoves.tip(sword: Model): Vector3?
	local handle = sword.PrimaryPart
	local hold = handle and handle:FindFirstChild("Hold")
	if not hold or not hold:IsA("Attachment") then
		return nil
	end
	for _, descendant in sword:GetDescendants() do
		if descendant.Name == "BladeTip" and descendant:IsA("Attachment") then
			return hold.WorldCFrame:PointToObjectSpace(descendant.WorldPosition)
		end
	end
	return nil
end

-- Altura do chão no espaço do HumanoidRootPart (boneco em pé no chão plano).
function SwordMoves.floor(character: Model): number?
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid then
		return nil
	end
	return -(root.Size.Y / 2 + humanoid.HipHeight)
end

-- Trava do chão: se a ponta (tip, no espaço do Hold) ficaria abaixo de floor + margin, gira a
-- espada para cima em volta da pegada, só o necessário. Tudo no espaço do HumanoidRootPart.
function SwordMoves.aboveFloor(hold: CFrame, tip: Vector3, floor: number, margin: number): CFrame
	local reach = hold:VectorToWorldSpace(tip)
	local length = reach.Magnitude
	local lowest = floor + margin
	if length < 1e-3 or hold.Position.Y + reach.Y >= lowest then
		return hold
	end
	local dir = reach / length
	local axis = dir:Cross(Vector3.yAxis)
	if axis.Magnitude < 1e-3 then
		axis = Vector3.xAxis
	end
	local now = math.asin(math.clamp(dir.Y, -1, 1))
	local want = math.asin(math.clamp((lowest - hold.Position.Y) / length, -1, 1))
	return CFrame.new(hold.Position) * CFrame.fromAxisAngle(axis.Unit, want - now) * hold.Rotation
end

function SwordMoves.window(range: { number }?, t: number): boolean
	return range ~= nil and t >= range[1] and t <= range[2]
end

return SwordMoves
