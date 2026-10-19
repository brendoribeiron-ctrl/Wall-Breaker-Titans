--!strict
-- Efeitos da espada do Asta, em todos os clientes (efeito criado no cliente não replica).
-- O VISUAL mora nos modelos de ReplicatedStorage.SwordVFX (ParticleEmitter, Beam, Trail, luz),
-- editáveis no Studio; sem a pasta no place, valem os padrões de Shared/SwordVfx.luau. Este
-- arquivo só clona os modelos, decide onde cada peça vai e quando aparece. Regras de edição
-- (atributos Count, UseAuraColor, Life1..3, Alpha, Radius...) no topo de SwordVfx.luau.
--
--  * aura na espada (Blade), enquanto a espada está na mão e há aura: casca ForceField, brilho,
--    fios de energia correndo pela lâmina, labaredas, fumaça, brasas, orbes, raios e luz. Peças
--    com UseAuraColor pegam a cor da aura equipada; a força da aura escala Rate e brilho.
--  * golpe (Swing + Swipe): rastros presos na lâmina, faíscas da ponta e a meia-lua (Beams em
--    curva pelo caminho que a ponta faz, que nascem com a lâmina e se desfazem da cauda para a
--    cabeça), pó de magia e flash.
--  * impacto (Hit) no alvo e golpe final no chão (Ground).
-- Os modelos são lidos a cada golpe: mexer em ReplicatedStorage.SwordVFX durante o Play já vale
-- no próximo golpe (a aura da lâmina, ao equipar de novo).

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local SwordMoves = require(ReplicatedStorage.Shared.SwordMoves)
local SwordVfx = require(ReplicatedStorage.Shared.SwordVfx)
local Aura = require(script.Parent.Aura)
local Fx = require(script.Parent.Fx)

local NAME = "AntiMagicSword"
local WHITE = Color3.new(1, 1, 1)
local ANTI = Color3.fromRGB(14, 10, 20) -- preto da antimagia
local PALE = Color3.fromRGB(225, 228, 240) -- sem aura: o branco da antimagia
local localPlayer = Players.LocalPlayer
local rng = Random.new()

local SwordFx = {}

type Glowing = { emitter: ParticleEmitter, rate: number, boost: number, aura: boolean }
type Flow = { beam: Beam, speed: number, aura: boolean, core: boolean }
type Bolt = { beam: Beam, a: Attachment, b: Attachment, offAt: number, color: ColorSequence, emission: number, chance: number }

type Coat = {
	player: Player,
	sword: Model,
	blade: BasePart,
	scale: number,
	shell: BasePart?,
	shellAlpha: number,
	glow: Beam,
	glowAura: boolean,
	flows: { Flow },
	bolts: { Bolt },
	nextBolt: number,
	emitters: { [string]: Glowing },
	sparks: ParticleEmitter, -- chuva de faíscas da ponta, só no golpe
	sparkRate: number,
	light: PointLight,
	lightBase: number,
	lightAura: boolean,
	trails: { [string]: Trail },
	looks: { [string]: NumberSequence },
	lives: { [string]: { number } },
	tip: Attachment,
	mid: Attachment,
	base: Attachment,
	dir: Vector3,
	width: number,
	token: number,
	reveal: number,
	boost: number,
}

local coats: { [Model]: Coat } = {}
local litCount = 0 -- quantas vezes um rastro acendeu (testes)
local swipes = { calls = 0, points = 0, made = 0 } -- meias-luas (testes)

local function colors(...: Color3): ColorSequence
	local list = { ... }
	if #list == 1 then
		return ColorSequence.new(list[1])
	end
	local keys = {}
	for i, c in list do
		table.insert(keys, ColorSequenceKeypoint.new((i - 1) / (#list - 1), c))
	end
	return ColorSequence.new(keys)
end

-- Cor de uma ColorSequence no ponto t (0..1).
local function colorAt(sequence: ColorSequence, t: number): Color3
	local keys = sequence.Keypoints
	for i = 1, #keys - 1 do
		local a, b = keys[i], keys[i + 1]
		if t <= b.Time then
			local span = b.Time - a.Time
			return a.Value:Lerp(b.Value, if span > 0 then (t - a.Time) / span else 0)
		end
	end
	return keys[#keys].Value
end

local function scaleSeq(sequence: NumberSequence, k: number): NumberSequence
	local keys = {}
	for _, key in sequence.Keypoints do
		table.insert(keys, NumberSequenceKeypoint.new(key.Time, key.Value * k, key.Envelope * k))
	end
	return NumberSequence.new(keys)
end

local function attachment(parent: Instance, name: string, cframe: CFrame): Attachment
	local a = Instance.new("Attachment")
	a.Name = name
	a.CFrame = cframe
	a.Parent = parent
	return a
end

local function attr(instance: Instance?, key: string, default: any): any
	if not instance then
		return default
	end
	local value = instance:GetAttribute(key)
	if value == nil then
		return default
	end
	return value
end

local function find(parent: Instance?, name: string, class: string): any
	local child = parent and parent:FindFirstChild(name)
	return if child and child:IsA(class) then child else nil
end

-- Copia um emissor do modelo, com Size (e Speed) × k.
local function cloneEmitter(template: ParticleEmitter, parent: Instance, k: number, speed: boolean): ParticleEmitter
	local e = template:Clone()
	e.Size = scaleSeq(template.Size, k)
	if speed then
		e.Speed = NumberRange.new(template.Speed.Min * k, template.Speed.Max * k)
	end
	e.Parent = parent
	return e
end

local folder: Instance = workspace.Terrain

-- Solta uma leva de cada emissor do modelo (Attachment com ParticleEmitters, atributo Count /
-- HeavyCount) num ponto do mundo; tudo some sozinho.
local function emitFrom(template: Instance?, cframe: CFrame, k: number, heavy: boolean?)
	if not template then
		return
	end
	local a = attachment(folder, "SwordBurst", cframe)
	local longest = 0.2
	for _, child in template:GetChildren() do
		if child:IsA("ParticleEmitter") then
			local count = if heavy then attr(child, "HeavyCount", attr(child, "Count", 1)) else attr(child, "Count", 1)
			if count > 0 then
				local e = cloneEmitter(child, a, k, true)
				e.Enabled = false
				e:Emit(math.floor(count + 0.5))
				longest = math.max(longest, child.Lifetime.Max)
			end
		end
	end
	Debris:AddItem(a, longest + 0.3)
end

-- Força e cores da aura do dono da espada. Sem aura: 0 e o branco/preto da antimagia.
local function look(player: Player): (number, Color3, Color3, Color3)
	local info = Aura.infoOf(player)
	if not info then
		return 0, PALE, WHITE, ANTI
	end
	local color = Aura.colorOf(player)
	local accent = if info.accent then info.accent else color:Lerp(WHITE, 0.55)
	local second = if info.second then info.second else color:Lerp(ANTI, 0.35)
	return Aura.strengthOf(player), color, accent, second
end

local function paint(c: Coat)
	local k, color, accent, second = look(c.player)
	local on = k > 0
	local boost = c.boost
	if c.shell then
		c.shell.Color = color
		c.shell.Transparency = if on then math.clamp(c.shellAlpha - 0.1 * k - 0.2 * boost, 0, 1) else 1
	end
	c.glow.Enabled = on
	if c.glowAura then
		c.glow.Color = colors(color, accent)
	end
	for _, flow in c.flows do
		flow.beam.Enabled = on
		if flow.aura then
			flow.beam.Color = if flow.core then colors(color, second) else colors(accent, color)
		end
		flow.beam.TextureSpeed = flow.speed * (1 + 1.5 * boost)
	end
	for name, g in c.emitters do
		g.emitter.Enabled = on
		g.emitter.Rate = g.rate * (0.3 + 0.7 * k) * (1 + g.boost * boost)
		if g.aura then
			g.emitter.Color = if name == "Flames" then colors(color, second) else colors(accent, color)
		end
	end
	c.light.Enabled = on or boost > 0
	if c.lightAura then
		c.light.Color = color
	end
	c.light.Brightness = c.lightBase * (0.4 + 0.6 * k) * (1 + 1.5 * boost)
end

local function bladeOf(sword: Model): (BasePart?, Attachment?, Attachment?, Attachment?)
	for _, descendant in sword:GetDescendants() do
		if descendant.Name == "BladeTip" and descendant:IsA("Attachment") then
			local blade = descendant.Parent
			local base = blade and blade:FindFirstChild("BladeBase")
			local mid = blade and blade:FindFirstChild("BladeMid")
			if blade and blade:IsA("BasePart") and base and base:IsA("Attachment") and mid and mid:IsA("Attachment") then
				return blade, base, mid, descendant
			end
		end
	end
	return nil, nil, nil, nil
end

local function coat(player: Player, sword: Model)
	if coats[sword] then
		return
	end
	local blade, base, mid, tip
	for _ = 1, 40 do
		blade, base, mid, tip = bladeOf(sword)
		if blade or not sword.Parent then
			break
		end
		task.wait(0.1)
	end
	if not blade or not base or not mid or not tip or coats[sword] then
		return
	end
	local templates = SwordVfx.get()
	local B = templates:FindFirstChild("Blade")
	local S = templates:FindFirstChild("Swing")

	local axis = tip.Position - base.Position
	local dir = axis.Unit
	local scale = axis.Magnitude / 4.1 -- lâmina do modelo: 4,1 studs
	-- largura da lâmina: a maior medida da peça que não é o comprimento
	local size = blade.Size
	local along = blade.CFrame:VectorToObjectSpace(blade.CFrame:VectorToWorldSpace(dir))
	local width = if math.abs(along.X) > 0.7 then math.max(size.Y, size.Z) elseif math.abs(along.Y) > 0.7 then math.max(size.X, size.Z) else math.max(size.X, size.Y)
	width = math.min(width, 1.2 * scale)

	-- casca de energia: a própria malha, um pouco maior, em ForceField (preserva a silhueta)
	local shell: BasePart? = nil
	if blade:IsA("MeshPart") and attr(B, "ShellEnabled", true) then
		local copy = blade:Clone()
		copy:ClearAllChildren()
		copy.Name = "AuraShell"
		copy.TextureID = ""
		copy.Material = Enum.Material.ForceField
		copy.Size = blade.Size * attr(B, "ShellScale", 1.12)
		copy.CastShadow = false
		copy.Massless = true
		copy.CanCollide = false
		copy.CanQuery = false
		copy.CanTouch = false
		copy.CFrame = blade.CFrame
		local weld = Instance.new("Weld")
		weld.Part0 = blade
		weld.Part1 = copy
		weld.Parent = copy
		copy.Parent = sword
		shell = copy
	end

	local rot = tip.CFrame.Rotation
	local from = attachment(blade, "FxBase", CFrame.new(base.Position + dir * 0.35 * scale) * rot)
	local edge = attachment(blade, "FxEdge", CFrame.new(tip.Position - dir * 0.9 * scale) * rot)
	local out = attachment(blade, "FxOut", CFrame.new(tip.Position + dir * 0.9 * scale) * rot)
	local tipIn = attachment(blade, "FxTipIn", CFrame.new(tip.Position - dir * 0.3 * scale) * rot)
	local inner = attachment(blade, "FxInner", CFrame.new(base.Position:Lerp(tip.Position, 0.45)) * rot)

	local glowTemplate = find(B, "Glow", "Beam") :: Beam?
	local glow = if glowTemplate then glowTemplate:Clone() else Instance.new("Beam")
	glow.Attachment0 = base
	glow.Attachment1 = tip
	glow.Width0 = width * attr(glowTemplate, "Width0", 1.9)
	glow.Width1 = width * attr(glowTemplate, "Width1", 0.8)
	glow.Parent = blade

	-- fios de energia correndo da guarda para a ponta pelas duas bordas da lâmina (o contorno do
	-- Haki) e um véu fraco no meio
	local flows: { Flow } = {}
	local side = rot.XVector * width * 0.5
	local tipOut = tip.Position + dir * 0.35 * scale
	for i, spec in { { "FlowEdge", side }, { "FlowEdge", -side }, { "FlowCore", Vector3.zero } } do
		local template = find(B, spec[1] :: string, "Beam") :: Beam?
		if template then
			local offset = spec[2] :: Vector3
			local a0 = attachment(blade, "FlowA" .. i, CFrame.new(base.Position + offset) * rot)
			local a1 = attachment(blade, "FlowB" .. i, CFrame.new(tipOut + offset * 0.15) * rot)
			local flow = template:Clone()
			flow.Name = "Flow" .. i
			flow.Attachment0 = a0
			flow.Attachment1 = a1
			flow.TextureLength = attr(template, "Length", 3) * scale
			flow.Width0 = attr(template, "Width", 0.7) * width
			flow.Width1 = attr(template, "Width", 0.7) * width * 0.45
			flow.Parent = blade
			table.insert(flows, { beam = flow, speed = template.TextureSpeed, aura = attr(template, "UseAuraColor", true), core = i == 3 })
		end
	end

	-- raios estalando na lâmina (ligados por instantes em pontos sorteados)
	local bolts: { Bolt } = {}
	local boltTemplate = find(B, "Bolt", "Beam") :: Beam?
	if boltTemplate then
		for i = 1, attr(boltTemplate, "Count", 2) do
			local a = attachment(blade, "BoltA" .. i, CFrame.new(base.Position))
			local b = attachment(blade, "BoltB" .. i, CFrame.new(tip.Position))
			local beam = boltTemplate:Clone()
			beam.Name = "Bolt" .. i
			beam.Attachment0 = a
			beam.Attachment1 = b
			beam.Width0 = attr(boltTemplate, "Width", 0.8) * scale
			beam.Width1 = beam.Width0
			beam.Enabled = false
			beam.Parent = blade
			local chance = if attr(boltTemplate, "UseAuraColor", true) then attr(boltTemplate, "AuraChance", 0.45) else 0
			table.insert(bolts, { beam = beam, a = a, b = b, offAt = 0, color = boltTemplate.Color, emission = boltTemplate.LightEmission, chance = chance })
		end
	end

	-- labaredas, fumaça, brasas, orbes (e qualquer outro emissor posto na pasta Blade)
	local holder = shell or blade
	local emitters: { [string]: Glowing } = {}
	if B then
		for _, child in B:GetChildren() do
			if child:IsA("ParticleEmitter") then
				local e = cloneEmitter(child, holder, scale, false)
				e.Enabled = false
				emitters[child.Name] = { emitter = e, rate = child.Rate, boost = attr(child, "BoostRate", 1), aura = attr(child, "UseAuraColor", false) }
			end
		end
	end

	-- chuva de faíscas da ponta durante o corte
	local sparkTemplate = find(S, "TipSparks", "ParticleEmitter") :: ParticleEmitter?
	local sparks = if sparkTemplate then cloneEmitter(sparkTemplate, tip, scale, false) else Instance.new("ParticleEmitter")
	sparks.Enabled = false
	sparks.Parent = tip

	local lightTemplate = find(B, "Light", "PointLight") :: PointLight?
	local light = if lightTemplate then lightTemplate:Clone() else Instance.new("PointLight")
	light.Range = (if lightTemplate then lightTemplate.Range else 8) * scale
	light.Parent = mid

	-- rastros do golpe: sempre ligados (um Trail ligado só na hora do golpe não chega a aparecer,
	-- visto em 17/10); quem mostra e esconde é a transparência
	local ends: { [string]: { Attachment } } = {
		SwingAura = { inner, out },
		SwingCore = { edge, tip },
		SwingEdge = { tipIn, out },
		SwingDark = { from, edge },
	}
	local trails: { [string]: Trail } = {}
	local looks: { [string]: NumberSequence } = {}
	local lives: { [string]: { number } } = {}
	if S then
		for _, child in S:GetChildren() do
			local pair = ends[child.Name]
			if child:IsA("Trail") and pair then
				local t = child:Clone()
				t.Attachment0 = pair[1]
				t.Attachment1 = pair[2]
				t.Enabled = true
				looks[child.Name] = child.Transparency
				lives[child.Name] = { attr(child, "Life1", 0), attr(child, "Life2", 0), attr(child, "Life3", 0) }
				t.Transparency = NumberSequence.new(1)
				t.Parent = blade
				trails[child.Name] = t
			end
		end
	end

	local c: Coat = {
		player = player,
		sword = sword,
		blade = blade,
		scale = scale,
		shell = shell,
		shellAlpha = attr(B, "ShellTransparency", 0.7),
		glow = glow,
		glowAura = attr(glowTemplate, "UseAuraColor", true),
		flows = flows,
		bolts = bolts,
		nextBolt = 0,
		emitters = emitters,
		sparks = sparks,
		sparkRate = if sparkTemplate then sparkTemplate.Rate else 32,
		light = light,
		lightBase = if lightTemplate then lightTemplate.Brightness else 1.3,
		lightAura = attr(lightTemplate, "UseAuraColor", true),
		trails = trails,
		looks = looks,
		lives = lives,
		tip = tip,
		mid = mid,
		base = base,
		dir = dir,
		width = width,
		token = 0,
		reveal = 0,
		boost = 0,
	}
	coats[sword] = c
	paint(c)
	sword.AncestryChanged:Connect(function()
		if not sword:IsDescendantOf(workspace) then
			coats[sword] = nil
		end
	end)
end

local function coatOf(player: Player): Coat?
	local character = player.Character
	local sword = character and character:FindFirstChild(NAME)
	return if sword and sword:IsA("Model") then coats[sword] else nil
end

-- Raios: de tempos em tempos um estalo curto entre dois pontos da lâmina (mais com aura forte e
-- no golpe). Um laço só para todas as espadas.
local function crackle(c: Coat, now: number)
	local k = look(c.player)
	for _, bolt in c.bolts do
		if bolt.beam.Enabled and now >= bolt.offAt then
			bolt.beam.Enabled = false
		end
	end
	if k <= 0 or now < c.nextBolt or #c.bolts == 0 then
		return
	end
	c.nextBolt = now + rng:NextNumber(0.25, 0.8) / (0.6 + k + 1.5 * c.boost)
	local bolt = c.bolts[rng:NextInteger(1, #c.bolts)]
	local base, tip = c.base.Position, c.tip.Position
	local side = c.tip.CFrame.RightVector * c.width * 0.55
	local t0 = rng:NextNumber(0, 0.7)
	local t1 = math.min(t0 + rng:NextNumber(0.2, 0.45), 1.05)
	bolt.a.Position = base:Lerp(tip, t0) + side * rng:NextNumber(-1, 1)
	bolt.b.Position = base:Lerp(tip, t1) + side * rng:NextNumber(-1, 1)
	local _, _, accent = look(c.player)
	local lit = rng:NextNumber() < bolt.chance
	bolt.beam.Color = if lit then colors(accent) else bolt.color
	bolt.beam.LightEmission = if lit then bolt.emission else 0
	bolt.beam.TextureSpeed = rng:NextNumber(-3, 3)
	bolt.beam.Enabled = true
	bolt.offAt = now + rng:NextNumber(0.05, 0.11)
end

---------------------------------------------------------------------------------------------------
-- Meia-lua do corte: cópias dos Beams de SwordVFX.Swipe em curva (Bezier cúbica) passando pelo
-- caminho que a ponta fez.

-- Curva entre dois pontos com as tangentes dadas (arco circular aproximado por Bezier).
local function arcBeam(template: Beam, p0: Vector3, t0: Vector3, p1: Vector3, t1: Vector3, normal: Vector3, keep: number): (Beam, Attachment, Attachment)
	local chord = (p1 - p0).Magnitude
	local theta = math.acos(math.clamp(t0:Dot(t1), -1, 1))
	local handle = if theta < 0.05 then chord / 3 else (4 / 3) * math.tan(theta / 4) * chord / (2 * math.sin(theta / 2))
	-- eixo Y = direção radial no plano do golpe: num Beam sem FaceCamera a largura segue esse eixo,
	-- e dois trechos vizinhos dividem o mesmo attachment, então a fita emenda sem dentes
	local function frame(p: Vector3, t: Vector3): CFrame
		local side = normal:Cross(t)
		side = if side.Magnitude > 1e-3 then side.Unit else Vector3.yAxis
		return CFrame.fromMatrix(p, t, side)
	end
	local a0 = attachment(folder, "SwipeA", frame(p0, t0))
	local a1 = attachment(folder, "SwipeB", frame(p1, t1))
	local beam = template:Clone()
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.CurveSize0 = handle
	beam.CurveSize1 = handle
	-- a curva vem das tangentes (eixo X dos attachments); com FaceCamera desligado a fita fica de
	-- quina para a câmera em vários ângulos e some
	beam.Parent = a0
	Debris:AddItem(a0, keep)
	Debris:AddItem(a1, keep)
	return beam, a0, a1
end

-- Caminho da lâmina na janela do rastro, calculado pela própria animação (SwordMoves): mesma pose,
-- mesmo rig, mesma trava do chão que o golpe usa. Não depende da taxa de quadros nem da rede.
local function pathOf(c: Coat, move: SwordMoves.Move): { { tip: Vector3, mid: Vector3 } }?
	local character = c.player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local rig = character and SwordMoves.rig(character)
	local tipLocal = SwordMoves.tip(c.sword)
	local floor = character and SwordMoves.floor(character)
	if not root or not root:IsA("BasePart") or not rig or not tipLocal or not floor then
		return nil
	end
	local path = {}
	local from, to = move.trail[1], move.trail[2]
	-- poucas amostras de propósito: o Chaikin abaixo arredonda os cantos na escala do espaçamento
	for i = 0, 10 do
		local t = from + (to - from) * i / 10
		local hold = SwordMoves.aboveFloor(SwordMoves.hold(rig, SwordMoves.sample(move, t)), tipLocal, floor, Config.Sword.floorMargin)
		local world = root.CFrame * hold
		table.insert(path, { tip = world * tipLocal, mid = world * (tipLocal * 0.3) })
	end
	-- a animação interpola as poses em linha reta, então a ponta faz um polígono: cortar os
	-- cantos (Chaikin) deixa a meia-lua redonda, sem quinas
	for _ = 1, 4 do
		local smooth = { path[1] }
		for i = 1, #path - 1 do
			local a, b = path[i], path[i + 1]
			table.insert(smooth, { tip = a.tip:Lerp(b.tip, 0.25), mid = a.mid:Lerp(b.mid, 0.25) })
			table.insert(smooth, { tip = a.tip:Lerp(b.tip, 0.75), mid = a.mid:Lerp(b.mid, 0.75) })
		end
		table.insert(smooth, path[#path])
		path = smooth
	end
	return path
end

-- Meia-lua do corte, no jeito do tutorial "sword swipes": fita entre a ponta e perto do cabo (o
-- caminho do golpe), que nasce junto com a lâmina (a cabeça anda pelo arco na janela do rastro),
-- estrias rolando por cima, cauda que se dissolve e, no fim, tudo se desfaz da cauda para a cabeça
-- abrindo um pouco para fora.
local function swipe(c: Coat, index: number, hold: number?)
	local move = SwordMoves.COMBO[index]
	local heavy = index == #SwordMoves.COMBO
	local path = if move and c.sword.Parent then pathOf(c, move) else nil
	swipes.calls += 1
	swipes.points = if path then #path else -1
	local W = SwordVfx.get():FindFirstChild("Swipe")
	if not move or not path or #path < 4 or not W then
		return
	end
	local n = #path
	local segments = math.clamp(math.floor(attr(W, "Segments", 8)), 2, 16)
	local picks = {}
	for k = 0, segments do
		table.insert(picks, path[1 + math.floor((n - 1) * k / segments + 0.5)])
	end
	local count = #picks
	local center = Vector3.zero
	for _, p in picks do
		center += p.mid / count
	end
	local half = math.ceil(count / 2)
	local normal = (picks[half].tip - picks[1].tip):Cross(picks[count].tip - picks[half].tip)
	normal = if normal.Magnitude > 1e-3 then normal.Unit else Vector3.yAxis
	local span = (picks[1].tip - picks[1].mid).Magnitude
	local wide = attr(W, "Width", 1)
	local tail = math.max(attr(W, "TailLength", 0.65), 0.05)
	local reveal = if hold then 0.05 else math.max(move.trail[2] - move.trail[1], 0.08)
	local life = hold or (if heavy then attr(W, "LifeHeavy", 0.4) else attr(W, "LifeSlash", 0.3))
	local spread = if heavy then attr(W, "GrowHeavy", 0.22) else attr(W, "GrowSlash", 0.14)
	local keep = reveal + life + 0.2
	type Entry = { beam: Beam, alpha: number, from: number, to: number, a0: Attachment, a1: Attachment, p0: Vector3, p1: Vector3 }
	local entries: { Entry } = {}
	for _, template in W:GetChildren() do
		if not template:IsA("Beam") or (attr(template, "HeavyOnly", false) and not heavy) then
			continue
		end
		local radius = attr(template, "Radius", 0.8)
		local width = (if heavy then attr(template, "HeavyWidth", attr(template, "Width", 1)) else attr(template, "Width", 1)) * wide
		local scroll = attr(template, "Scroll", 0)
		local function point(i: number): Vector3
			local p = picks[math.clamp(i, 1, count)]
			return p.mid:Lerp(p.tip, radius)
		end
		local function tangent(i: number): Vector3
			local d = point(i + 1) - point(i - 1)
			return if d.Magnitude > 1e-4 then d.Unit else Vector3.xAxis
		end
		for k = 1, count - 1 do
			local beam, a0, a1 = arcBeam(template, point(k), tangent(k), point(k + 1), tangent(k + 1), normal, keep)
			local from, to = (k - 1) / (count - 1), k / (count - 1)
			-- Color do modelo: cauda (0) → cabeça (1), repartida pelos trechos
			beam.Color = colors(colorAt(template.Color, from), colorAt(template.Color, to))
			-- afina para a cauda
			beam.Width0 = span * width * (0.2 + 0.8 * from ^ 0.6)
			beam.Width1 = span * width * (0.2 + 0.8 * to ^ 0.6)
			beam.Transparency = NumberSequence.new(1)
			if scroll ~= 0 then
				-- um período da textura por trecho: todos começam na mesma fase e rolam juntos,
				-- então as estrias emendam de um trecho para o outro
				beam.TextureMode = Enum.TextureMode.Wrap
				beam.TextureLength = math.max((point(k + 1) - point(k)).Magnitude, 0.1)
				beam.TextureSpeed = -scroll * 2.2
			end
			table.insert(entries, { beam = beam, alpha = attr(template, "Alpha", 0), from = from, to = to, a0 = a0, a1 = a1, p0 = a0.Position, p1 = a1.Position })
		end
	end
	swipes.made += 1
	local dust = W:FindFirstChild("Dust")
	local flash = W:FindFirstChild("Flash")
	local dusted = 0
	local flashed = false
	local start = os.clock()
	local connection: RBXScriptConnection? = nil
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - start
		local h = math.clamp(elapsed / reveal, 0, 1)
		h = 1 - (1 - h) * (1 - h) -- a cabeça corre na frente e freia no fim, como a lâmina
		local f = math.clamp((elapsed - reveal) / life, 0, 1)
		if f >= 1 or not c.sword.Parent and elapsed > reveal then
			for _, entry in entries do
				entry.beam.Enabled = false
			end
			if connection then
				connection:Disconnect()
			end
			return
		end
		-- pó de magia por onde a cabeça já passou
		while dusted < count and (dusted / (count - 1)) <= h do
			dusted += 1
			if dusted > 1 then
				emitFrom(dust, CFrame.new(picks[dusted].mid:Lerp(picks[dusted].tip, 0.9)), c.scale, heavy)
			end
		end
		if not flashed and h >= 1 then
			flashed = true
			local grow = if heavy then attr(flash, "HeavySize", 1.45) else 1
			emitFrom(flash, CFrame.new(picks[count].tip), c.scale * grow, heavy)
		end
		-- transparência ao longo do arco: nada à frente da cabeça, cauda dissolvendo atrás dela e,
		-- depois da janela, sumindo da cauda para a cabeça
		local function alphaAt(x: number, base: number): number
			local behind = math.max(h - x, 0)
			local a = base + math.clamp(behind / tail, 0, 1) ^ 1.2 * 0.9 + f * f * 1.1 + f * behind * 1.6
			local ahead = math.clamp((x - h) / 0.05, 0, 1)
			return math.clamp(a + ahead * (1 - a), 0, 1)
		end
		local grow = 1 + spread * (1 - (1 - f) * (1 - f))
		for _, entry in entries do
			local keys = {}
			for j = 0, 5 do
				local u = j / 5
				table.insert(keys, NumberSequenceKeypoint.new(u, alphaAt(entry.from + (entry.to - entry.from) * u, entry.alpha)))
			end
			entry.beam.Transparency = NumberSequence.new(keys)
			entry.a0.Position = center + (entry.p0 - center) * grow
			entry.a1.Position = center + (entry.p1 - center) * grow
		end
	end)
end

-- Faíscas em raio, flash, anel e orbes (SwordVFX.Hit.Burst), virados para `normal`.
local function blast(at: Vector3, normal: Vector3, size: number)
	local hit = SwordVfx.get():FindFirstChild("Hit")
	emitFrom(hit and hit:FindFirstChild("Burst"), CFrame.lookAt(at, at + normal), size)
end

-- Golpe começou (delay = atraso para quem vê o golpe de outro jogador: a pose chega pela rede).
function SwordFx.swing(player: Player, index: number, delay: number?)
	local c = coatOf(player)
	local move = SwordMoves.COMBO[index]
	if not c or not move then
		return
	end
	c.token += 1
	local token = c.token
	local lag = delay or 0
	local trails = c.trails
	local longest = 0
	for name in trails do
		longest = math.max(longest, c.lives[name][index] or 0)
	end
	-- o golpe anterior pode ter sido cortado pelo encadeamento: o rastro dele some no preparo
	local before = c.reveal
	task.delay(0.2 + lag, function()
		if c.reveal == before then
			for _, t in trails do
				t.Transparency = NumberSequence.new(1)
			end
		end
	end)
	task.delay(move.trail[1] + lag, function()
		if c.token ~= token then
			return
		end
		c.reveal += 1
		for name, t in trails do
			local life = c.lives[name][index] or 0
			if life > 0 then
				t.Lifetime = life
				t.Transparency = c.looks[name]
			else
				t.Transparency = NumberSequence.new(1)
			end
		end
		litCount += 1
		c.boost = 1
		c.sparks.Rate = c.sparkRate * c.scale
		c.sparks.Enabled = c.sparkRate > 0
		paint(c)
	end)
	-- a meia-lua nasce com a lâmina: a cabeça dela anda pelo arco durante a janela do rastro
	task.delay(move.trail[1] + lag, swipe, c, index)
	task.delay(move.trail[2] + lag, function()
		if c.token ~= token then
			return
		end
		-- o rastro já feito some sozinho; depois disso a trilha volta a ficar invisível
		local reveal = c.reveal
		task.delay(longest, function()
			if c.reveal == reveal then
				for _, t in trails do
					t.Transparency = NumberSequence.new(1)
				end
			end
		end)
		c.sparks.Enabled = false
		c.boost = 0
		paint(c)
	end)
	if move.impact then
		task.delay(move.impact + lag, SwordFx.ground, player, c, token)
	end
end

-- Golpe final batendo no chão (SwordVFX.Ground).
function SwordFx.ground(player: Player, c: Coat, token: number)
	if c.token ~= token or not c.sword.Parent then
		return
	end
	local G = SwordVfx.get():FindFirstChild("Ground")
	if not G then
		return
	end
	local tip = c.tip.WorldPosition
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = {}
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(tip + Vector3.new(0, 3, 0), Vector3.new(0, -9, 0), params)
	if not hit then
		return
	end
	local spot = hit.Position + Vector3.new(0, 0.15, 0)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local forward = if root and root:IsA("BasePart") then root.CFrame.LookVector * Vector3.new(1, 0, 1) else Vector3.zAxis
	forward = if forward.Magnitude > 0.1 then forward.Unit else Vector3.zAxis
	local s = c.scale * attr(G, "Size", 1)

	-- anéis, rachadura e coluna (virados para cima); faíscas rasteiras (deitadas, para a frente)
	emitFrom(G:FindFirstChild("Up"), CFrame.lookAt(spot, spot + Vector3.yAxis), s)
	emitFrom(G:FindFirstChild("Flat"), CFrame.lookAt(spot, spot + forward), s)
	-- flash e orbes
	blast(spot + Vector3.new(0, 1, 0), Vector3.yAxis, attr(G, "BlastSize", 0.7) * s)
	local debris = math.floor(attr(G, "Debris", 8) + 0.5)
	if debris > 0 then
		Fx.cubes(spot + Vector3.new(0, 0.4, 0), attr(G, "DebrisColor", Color3.fromRGB(92, 84, 78)), debris, 20, Vector3.new(0, 22, 0) + forward * 8, 0.6, Enum.Material.Slate)
	end
	-- raios correndo pelo chão, alternando os dois modelos
	local light = find(G, "BoltLight", "Beam") :: Beam?
	local dark = find(G, "BoltDark", "Beam") :: Beam?
	for i = 1, math.floor(attr(G, "Bolts", 4)) do
		local template = if i % 2 == 0 then light else dark
		if template then
			local angle = rng:NextNumber(0, math.pi * 2)
			local reach = rng:NextNumber(attr(template, "ReachMin", 4), attr(template, "ReachMax", 8)) * s
			local a0 = attachment(folder, "SlamBolt", CFrame.new(spot))
			local a1 = attachment(folder, "SlamBolt", CFrame.new(spot + Vector3.new(math.cos(angle) * reach, 0.2, math.sin(angle) * reach)))
			local beam = template:Clone()
			beam.Attachment0 = a0
			beam.Attachment1 = a1
			beam.Width0 = template.Width0 * s
			beam.Width1 = template.Width1 * s
			beam.Parent = a0
			Debris:AddItem(a0, rng:NextNumber(0.1, 0.2))
			Debris:AddItem(a1, 0.25)
		end
	end
	if player == localPlayer then
		Fx.shake(attr(G, "Shake", 0.45))
		if attr(G, "ScreenFlash", true) then
			Fx.flash(attr(G, "ScreenFlashColor", Color3.fromRGB(118, 36, 255)), 0.12, 0.25)
		end
	end
end

-- Lâmina acertou um alvo (ponto calculado pelo servidor). SwordVFX.Hit.
function SwordFx.impact(player: Player, index: number, at: Vector3)
	local H = SwordVfx.get():FindFirstChild("Hit")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local dir = if root and root:IsA("BasePart") then (at - root.Position) * Vector3.new(1, 0, 1) else Vector3.zAxis
	dir = if dir.Magnitude > 0.1 then dir.Unit else Vector3.zAxis
	local heavy = index == #SwordMoves.COMBO
	local function pick(key: string, default: number): number
		return if heavy then attr(H, "Heavy" .. key, attr(H, key, default)) else attr(H, key, default)
	end
	blast(at, -dir, attr(H, "Size", 1) * (if heavy then attr(H, "HeavySize", 1.3) else 1))
	local star = math.floor(pick("Star", 8))
	if star > 0 then
		Fx.star(at, -dir, attr(H, "StarColor", WHITE), star, 3, 0.18)
	end
	local debris = math.floor(pick("Debris", 4) + 0.5)
	if debris > 0 then
		Fx.cubes(at, attr(H, "DebrisColor", Color3.fromRGB(118, 36, 255)), debris, 18, -dir * 16 + Vector3.new(0, 10, 0), 0.4)
	end
	if player == localPlayer then
		Fx.shake(pick("Shake", 0.15))
	end
end

-- Golpe parado no meio (espada guardada, morte): apaga os rastros.
function SwordFx.stop(player: Player)
	local c = coatOf(player)
	if c then
		c.token += 1
		c.reveal += 1
		for _, t in c.trails do
			t.Transparency = NumberSequence.new(1)
		end
		c.sparks.Enabled = false
		c.boost = 0
		paint(c)
	end
end

-- Testes/capturas: meia-lua do golpe index parada por hold segundos.
function SwordFx.testSwipe(index: number, hold: number)
	local c = coatOf(localPlayer)
	if c then
		swipe(c, index, hold)
	end
end

function SwordFx.debug(player: Player?): { [string]: any }
	local c = coatOf(player or localPlayer)
	if not c then
		return { coated = false }
	end
	local lit = {}
	for name, t in c.trails do
		lit[name] = t.Transparency.Keypoints[1].Value < 1
	end
	local flames = c.emitters.Flames
	return {
		coated = true,
		lit = litCount,
		swipes = swipes,
		shell = c.shell ~= nil and c.shell.Transparency < 1,
		shellColor = if c.shell then c.shell.Color else nil,
		flames = flames ~= nil and flames.emitter.Enabled,
		flameRate = if flames then flames.emitter.Rate else 0,
		flameColor = if flames then flames.emitter.Color.Keypoints[1].Value else nil,
		glow = c.glow.Enabled,
		flow = c.flows[1] ~= nil and c.flows[1].beam.Enabled,
		light = c.light.Enabled,
		trails = lit,
		color = Aura.colorOf(c.player),
		templates = SwordVfx.get():GetFullName(),
	}
end

local function watch(player: Player)
	local function onCharacter(character: Model)
		local function check(child: Instance)
			if child.Name == NAME and child:IsA("Model") then
				task.spawn(coat, player, child)
			end
		end
		character.ChildAdded:Connect(check)
		for _, child in character:GetChildren() do
			check(child)
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		onCharacter(player.Character)
	end
	-- trocar a aura (ou o Poder mudar a força dela) repinta a espada na hora
	local function refresh()
		local c = coatOf(player)
		if c then
			paint(c)
		end
	end
	player:GetAttributeChangedSignal("Aura"):Connect(refresh)
	player:GetAttributeChangedSignal("Power"):Connect(refresh)
end

function SwordFx.start()
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for _, c in coats do
			crackle(c, now)
		end
	end)
	task.spawn(function()
		local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SwordCombat", 30)
		if not remote or not remote:IsA("RemoteEvent") then
			return
		end
		remote.OnClientEvent:Connect(function(kind: string, player: Player, index: number, at: Vector3?)
			if typeof(player) ~= "Instance" or not player:IsA("Player") then
				return
			end
			if kind == "swing" and player ~= localPlayer then
				-- a pose do outro chega pelo espelho de poses, ~0,1 s depois
				SwordFx.swing(player, index, 0.1)
			elseif kind == "impact" and typeof(at) == "Vector3" then
				SwordFx.impact(player, index, at)
				if SwordFx.onImpact and player == localPlayer then
					SwordFx.onImpact(index)
				end
			end
		end)
	end)
end

-- Ligado pelo SwordCombat: acerto do próprio jogador (trava o golpe um instante).
SwordFx.onImpact = nil :: ((number) -> ())?

return SwordFx
