--!strict
-- Efeitos do Shidori (VFX e SFX), em todos os clientes, presos na mão esquerda de quem usou.
-- Tempos das fases: Config.Shidori (os mesmos da pose e do servidor). Reaproveita o que deu certo
-- na espada (src/client/SwordFx.luau): texturas próprias (glow, bolt, spark, ring_glow,
-- band_core_x), raios como Beams entre dois attachments trocados a cada estalo, Brightness acima
-- do Threshold do Bloom (2) só no que é pequeno, e tudo some sozinho (Debris + limpeza explícita).
--
-- Camadas (de dentro para fora): núcleo branco quente (estoura no Bloom), esfera azul
-- translúcida, raios curtos estalando em volta da mão (mais e mais longos conforme carrega),
-- faíscas, luz pulsando; na explosão: flash, risco horizontal (lens flare) e raios longos; na
-- investida: rastro na mão; no acerto: flash, anel, faíscas e raios no ponto; no fim: os raios
-- ficam raros e somem, a luz apaga e sobra fumacinha.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Textures = require(ReplicatedStorage.Shared.Textures)
local Fx = require(script.Parent.Fx)

local S = Config.Shidori

local ShidoriFx = {}

local HOT = Color3.fromRGB(236, 250, 255)
local CYAN = Color3.fromRGB(120, 215, 255)
local BLUE = Color3.fromRGB(46, 120, 255)

-- Sons da loja do Roblox (Pro Sound Effects, licenciados para qualquer experiência).
local SOUNDS = {
	crackle = "rbxassetid://9114249288", -- Electricity Static 18
	charge = "rbxassetid://9114246318", -- Electricity Static 1 (estalos seguidos, em laço)
	burst = "rbxassetid://9114246605", -- Electricity Static 7
	whoosh = "rbxassetid://9125517981", -- Electric Whoosh Bys
}

local function seq(points: { { number } }): NumberSequence
	local keys = {}
	for _, p in points do
		table.insert(keys, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(keys)
end

local function colors(...: Color3): ColorSequence
	local list = { ... }
	local keys = {}
	for i, c in list do
		table.insert(keys, ColorSequenceKeypoint.new((i - 1) / math.max(#list - 1, 1), c))
	end
	if #list == 1 then
		return ColorSequence.new(list[1])
	end
	return ColorSequence.new(keys)
end

local function emitter(parent: Instance, texture: string?, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Texture = texture or ""
	e.Enabled = false
	e.Rate = 0
	e.LightInfluence = 0
	for key, value in props do
		(e :: any)[key] = value
	end
	e.Parent = parent
	return e
end

local function sound(parent: Instance, id: string, volume: number, pitch: number?, looped: boolean?): Sound
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.PlaybackSpeed = pitch or 1
	s.Looped = looped == true
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 12
	s.RollOffMaxDistance = 90
	s.Parent = parent
	return s
end

local function playOnce(parent: Instance, id: string, volume: number, pitch: number?)
	local s = sound(parent, id, volume, pitch)
	s:Play()
	Debris:AddItem(s, 4)
end

-- Mão esquerda e o ponto da palma (um pouco abaixo do centro da mão).
local function handOf(character: Model): (BasePart?, CFrame)
	local hand = character:FindFirstChild("LeftHand")
	if hand and hand:IsA("BasePart") then
		return hand, CFrame.new(0, -hand.Size.Y * 0.35, 0)
	end
	local arm = character:FindFirstChild("Left Arm") -- R6
	if arm and arm:IsA("BasePart") then
		return arm, CFrame.new(0, -arm.Size.Y * 0.55, 0)
	end
	return nil, CFrame.identity
end

type Bolt = { beam: Beam, a0: Attachment, a1: Attachment, offAt: number }
type Cast = {
	player: Player,
	start: number,
	folder: Folder,
	core: Attachment,
	coreGlow: ParticleEmitter,
	shell: ParticleEmitter,
	sparks: ParticleEmitter,
	motes: ParticleEmitter,
	light: PointLight,
	trail: Trail,
	bolts: { Bolt },
	loop: Sound,
	flare: { beam: Beam, a0: Attachment, a1: Attachment }?,
	fired: { [string]: boolean },
	nextBolt: number,
	ending: number?, -- os.clock() em que começou a sumir (parada antes da hora)
	frozen: number?, -- capturas: tempo parado
	connection: RBXScriptConnection?,
}

local casts: { [Player]: Cast } = {}
local rng = Random.new()

local function randomDir(): Vector3
	local v = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1))
	return if v.Magnitude > 1e-3 then v.Unit else Vector3.yAxis
end

local function newBolt(folder: Folder): Bolt
	local a0 = Instance.new("Attachment")
	local a1 = Instance.new("Attachment")
	a0.Parent = workspace.Terrain
	a1.Parent = workspace.Terrain
	local beam = Instance.new("Beam")
	beam.Texture = Textures.bolt or ""
	beam.TextureMode = Enum.TextureMode.Stretch
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Brightness = 3
	beam.Segments = 1
	beam.Color = colors(HOT, CYAN)
	beam.Transparency = NumberSequence.new(1)
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Parent = folder
	return { beam = beam, a0 = a0, a1 = a1, offAt = 0 }
end

-- Liga um raio do ponto `from` até um ponto a `reach` studs numa direção ao acaso, curvado.
local function strike(bolt: Bolt, from: Vector3, reach: number, width: number, life: number, now: number, bias: Vector3?)
	local dir = randomDir()
	if bias then
		dir = (dir + bias).Unit
	end
	local to = from + dir * reach * rng:NextNumber(0.55, 1)
	-- o eixo X dos attachments é a tangente da curva do Beam: inclinar os dois para o mesmo lado
	-- (arco) ou para lados contrários (S) entorta o raio
	local side = randomDir():Cross(dir)
	side = if side.Magnitude > 1e-3 then side.Unit else Vector3.xAxis
	local bend = rng:NextNumber(0.4, 1.1)
	local axis0 = (dir + side * bend).Unit
	local axis1 = (dir + side * bend * (if rng:NextNumber() < 0.5 then 1 else -1)).Unit
	local turn = CFrame.Angles(0, math.rad(90), 0)
	bolt.a0.WorldCFrame = CFrame.lookAt(from, from + axis0) * turn
	bolt.a1.WorldCFrame = CFrame.lookAt(to, to + axis1) * turn
	local length = (to - from).Magnitude
	bolt.beam.CurveSize0 = length * 0.3
	bolt.beam.CurveSize1 = length * 0.3
	bolt.beam.Width0 = width
	bolt.beam.Width1 = width * 0.35
	bolt.beam.Transparency = seq({ { 0, 0 }, { 0.7, 0.15 }, { 1, 0.9 } })
	local roll = rng:NextNumber()
	bolt.beam.Color = if roll < 0.25 then colors(HOT, HOT) elseif roll < 0.6 then colors(HOT, CYAN, BLUE) else colors(CYAN, BLUE, BLUE)
	bolt.offAt = now + life
end

local function build(player: Player, character: Model, start: number): Cast?
	local hand, offset = handOf(character)
	if not hand then
		return nil
	end
	local folder = Instance.new("Folder")
	folder.Name = "Shidori_" .. player.Name
	folder.Parent = Fx.folder
	local core = Instance.new("Attachment")
	core.Name = "ShidoriCore"
	core.CFrame = offset
	core.Parent = hand

	local coreGlow = emitter(core, Textures.glow, {
		LockedToPart = true,
		LightEmission = 1,
		Brightness = 2.2,
		Color = colors(HOT),
		Lifetime = NumberRange.new(0.08, 0.14),
		Speed = NumberRange.new(0),
		Size = seq({ { 0, 1.2 }, { 1, 0.9 } }),
		Transparency = seq({ { 0, 0.1 }, { 1, 0.6 } }),
		ZOffset = 1,
		Rate = 60,
	})
	local shell = emitter(core, Textures.glow, {
		LockedToPart = true,
		LightEmission = 0.6,
		Brightness = 1.2,
		Color = colors(BLUE, CYAN),
		Lifetime = NumberRange.new(0.12, 0.22),
		Speed = NumberRange.new(0),
		Rotation = NumberRange.new(0, 360),
		Size = seq({ { 0, 2.6 }, { 1, 3.4 } }),
		Transparency = seq({ { 0, 0.7 }, { 1, 1 } }),
		Rate = 40,
	})
	local sparks = emitter(core, Textures.spark, {
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		LightEmission = 1,
		Brightness = 2.2,
		Color = colors(HOT, CYAN),
		Lifetime = NumberRange.new(0.08, 0.2),
		Speed = NumberRange.new(14, 30),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 6,
		Squash = NumberSequence.new(1.8),
		Size = seq({ { 0, 0.35 }, { 1, 0 } }),
		Rate = 0,
	})
	local motes = emitter(core, Textures.glow, {
		LightEmission = 1,
		Brightness = 1.6,
		Color = colors(CYAN, BLUE),
		Lifetime = NumberRange.new(0.25, 0.5),
		Speed = NumberRange.new(1, 4),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 3,
		Acceleration = Vector3.new(0, 2, 0),
		Size = seq({ { 0, 0.3 }, { 1, 0 } }),
		Rate = 0,
	})
	local light = Instance.new("PointLight")
	light.Color = CYAN
	light.Range = 0
	light.Brightness = 0
	light.Shadows = false
	light.Parent = core

	-- rastro da mão na investida (a palma e um ponto do punho)
	local back = Instance.new("Attachment")
	back.CFrame = offset * CFrame.new(0, hand.Size.Y * 0.7, 0)
	back.Parent = hand
	local trail = Instance.new("Trail")
	trail.Attachment0 = core
	trail.Attachment1 = back
	trail.FaceCamera = true
	trail.LightEmission = 1
	trail.LightInfluence = 0
	trail.Brightness = 1.6
	trail.Lifetime = 0.22
	trail.MinLength = 0.05
	trail.WidthScale = seq({ { 0, 1 }, { 1, 0.2 } })
	trail.Color = colors(HOT, CYAN, BLUE)
	trail.Transparency = seq({ { 0, 0.1 }, { 1, 1 } })
	trail.Enabled = false
	trail.Parent = hand

	local bolts = {}
	for _ = 1, 16 do
		table.insert(bolts, newBolt(folder))
	end
	local loop = sound(core, SOUNDS.charge, 0, 0.8, true)

	return {
		player = player,
		start = start,
		folder = folder,
		core = core,
		coreGlow = coreGlow,
		shell = shell,
		sparks = sparks,
		motes = motes,
		light = light,
		trail = trail,
		bolts = bolts,
		loop = loop,
		flare = nil,
		fired = {},
		nextBolt = 0,
		ending = nil,
		connection = nil,
		_back = back,
	} :: any
end

local function cleanup(c: Cast)
	if c.connection then
		c.connection:Disconnect()
		c.connection = nil
	end
	for _, bolt in c.bolts do
		bolt.a0:Destroy()
		bolt.a1:Destroy()
	end
	if c.flare then
		c.flare.a0:Destroy()
		c.flare.a1:Destroy()
	end
	c.loop:Stop()
	-- partículas já soltas terminam sozinhas: o attachment some depois
	for _, e in { c.coreGlow, c.shell, c.sparks, c.motes } do
		e.Enabled = false
	end
	c.trail.Enabled = false
	Debris:AddItem(c.core, 0.6)
	Debris:AddItem((c :: any)._back, 0.6)
	Debris:AddItem(c.trail, 0.6)
	Debris:AddItem(c.folder, 0.6)
	if casts[c.player] == c then
		casts[c.player] = nil
	end
end

-- Risco horizontal de luz na explosão (lens flare), sempre de lado para a câmera.
local function flare(c: Cast, now: number)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local a0 = Instance.new("Attachment")
	local a1 = Instance.new("Attachment")
	a0.Parent = workspace.Terrain
	a1.Parent = workspace.Terrain
	local beam = Instance.new("Beam")
	beam.Texture = Textures.band_core_x or ""
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Brightness = 3
	beam.Color = colors(CYAN, HOT, CYAN)
	beam.Transparency = seq({ { 0, 1 }, { 0.3, 0.2 }, { 0.5, 0 }, { 0.7, 0.2 }, { 1, 1 } })
	beam.Width0 = 0.5
	beam.Width1 = 0.5
	beam.Segments = 2
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Parent = c.folder
	c.flare = { beam = beam, a0 = a0, a1 = a1 }
	Debris:AddItem(a0, 0.5)
	Debris:AddItem(a1, 0.5)
	local begin = now
	task.spawn(function()
		while a0.Parent do
			local k = (os.clock() - begin) / 0.32
			if k >= 1 then
				beam.Enabled = false
				break
			end
			local right = camera.CFrame.RightVector
			local at = c.core.WorldPosition
			local half = 3 + 16 * (1 - (1 - k) ^ 3)
			a0.WorldPosition = at - right * half
			a1.WorldPosition = at + right * half
			beam.Width0 = 0.6 * (1 - k)
			beam.Width1 = beam.Width0
			RunService.RenderStepped:Wait()
		end
	end)
end

-- Uma vez por fase, no tempo t (s desde o início da ativação).
local function cue(c: Cast, name: string, t: number, at: number): boolean
	if c.fired[name] or t < at then
		return false
	end
	c.fired[name] = true
	return true
end

local function step(c: Cast)
	local now = os.clock()
	if c.frozen then
		c.start = now - c.frozen
	end
	local t = now - c.start
	local hand = c.core.Parent
	if not hand or not hand:IsDescendantOf(workspace) then
		cleanup(c)
		return
	end
	local at = c.core.WorldPosition

	-- força da energia 0..1 por fase (o fim começa quando a pose volta)
	local power
	if t < S.prep then
		power = 0.08 * t / S.prep
	elseif t < S.charge then
		local k = (t - S.prep) / (S.charge - S.prep)
		power = 0.08 + 0.62 * k * k
	elseif t < S.hit[2] then
		power = 1
	else
		power = math.max(0, 1 - (t - S.hit[2]) / (S.recover - S.hit[2]))
	end
	if c.ending then
		power *= math.max(0, 1 - (now - c.ending) / 0.3)
	end
	local flicker = 0.75 + 0.25 * math.sin(now * 53) * math.sin(now * 31)

	-- som
	if cue(c, "crackle", t, 0.02) then
		playOnce(c.core, SOUNDS.crackle, 0.35, 1.25)
	end
	if cue(c, "loop", t, S.prep) then
		c.loop:Play()
	end
	c.loop.Volume = 0.9 * power
	c.loop.PlaybackSpeed = 0.75 + 0.45 * math.min(power, 1) + (if t > S.burst and t < S.hit[2] then 0.15 else 0)

	-- núcleo, esfera, faíscas e luz
	c.coreGlow.Enabled = power > 0.03
	c.shell.Enabled = power > 0.25
	local size = 0.25 + 0.45 * power
	c.coreGlow.Size = seq({ { 0, size * flicker }, { 1, size * 0.8 } })
	c.shell.Size = seq({ { 0, 0.9 + 1.4 * power }, { 1, 1.2 + 1.8 * power } })
	c.sparks.Rate = 110 * power
	c.sparks.Enabled = power > 0.15
	c.motes.Rate = 20 * power
	c.motes.Enabled = power > 0.1
	c.light.Range = 6 + 16 * power
	c.light.Brightness = (1.5 + 5 * power) * flicker

	-- explosão de luz
	if cue(c, "burst", t, S.burst) then
		playOnce(c.core, SOUNDS.burst, 1.1, 0.95)
		c.sparks:Emit(40)
		Fx.shake(0.12)
		flare(c, now)
		for i = 1, #c.bolts do
			strike(c.bolts[i], at, 7, 0.9, 0.12, now)
		end
		c.nextBolt = now + 0.1
	end
	-- investida: rastro e assobio
	if cue(c, "lunge", t, S.lungeTime[1]) then
		playOnce(c.core, SOUNDS.whoosh, 0.8, 1.1)
		c.trail.Enabled = true
	end
	if t > S.hit[2] + 0.1 then
		c.trail.Enabled = false
	end
	if cue(c, "fade", t, S.hit[2]) then
		playOnce(c.core, SOUNDS.crackle, 0.4, 0.7)
	end

	-- raios: estalam em volta da mão; ficam mais longos, grossos e frequentes com a carga
	for _, bolt in c.bolts do
		if bolt.offAt > 0 and now >= bolt.offAt then
			bolt.offAt = 0
			bolt.beam.Transparency = NumberSequence.new(1)
		end
	end
	if power > 0.05 and now >= c.nextBolt then
		local count = 2 + math.floor(power * 4)
		for _ = 1, count do
			for _, bolt in c.bolts do
				if bolt.offAt == 0 then
					local reach = 1.2 + 4 * power
					strike(bolt, at, reach, 0.3 + 0.6 * power, rng:NextNumber(0.05, 0.1), now)
					break
				end
			end
		end
		-- no acúmulo a mão fica perto do chão: um raio de vez em quando desce e corre pelo chão
		if t > S.prep and t < S.burst and rng:NextNumber() < 0.35 then
			for _, bolt in c.bolts do
				if bolt.offAt == 0 then
					strike(bolt, at, 2.5 + 2 * power, 0.35, 0.08, now, Vector3.new(0, -1.4, 0))
					break
				end
			end
		end
		c.nextBolt = now + (0.09 - 0.05 * power)
	end

	if t >= S.recover + 0.05 or (c.ending and now - c.ending > 0.32) then
		cleanup(c)
	end
end

-- Começa os efeitos de uma ativação. lag = s que já passaram desde o início (rede).
function ShidoriFx.begin(player: Player, lag: number)
	local old = casts[player]
	if old then
		cleanup(old)
	end
	local character = player.Character
	if not character then
		return
	end
	local c = build(player, character, os.clock() - math.max(lag, 0))
	if not c then
		return
	end
	casts[player] = c
	c.connection = RunService.RenderStepped:Connect(function()
		step(c)
	end)
end

-- Corta no meio (morte, troca de boneco, montaria): tudo some em 0,3 s.
function ShidoriFx.stop(player: Player)
	local c = casts[player]
	if c and not c.ending then
		c.ending = os.clock()
	end
end

-- Acerto confirmado pelo servidor no ponto `at`.
function ShidoriFx.impact(player: Player, at: Vector3)
	local c = casts[player]
	local holder = Instance.new("Attachment")
	holder.WorldPosition = at
	holder.Parent = workspace.Terrain
	Debris:AddItem(holder, 2)
	playOnce(holder, SOUNDS.burst, 1.2, 0.7)
	playOnce(holder, SOUNDS.crackle, 0.7, 1.4)
	local flash = emitter(holder, Textures.glow, {
		LightEmission = 1,
		Brightness = 3,
		Color = colors(HOT, CYAN),
		Lifetime = NumberRange.new(0.12),
		Speed = NumberRange.new(0),
		Size = seq({ { 0, 6 }, { 1, 2 } }),
		Transparency = seq({ { 0, 0.1 }, { 1, 1 } }),
		ZOffset = 2,
	})
	local ring = emitter(holder, Textures.ring_glow, {
		LightEmission = 1,
		Brightness = 1.6,
		Color = colors(HOT, CYAN, BLUE),
		Lifetime = NumberRange.new(0.32),
		Speed = NumberRange.new(0),
		Size = seq({ { 0, 1.5 }, { 1, 14 } }),
		Transparency = seq({ { 0, 0.1 }, { 1, 1 } }),
	})
	local sparks = emitter(holder, Textures.spark, {
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		LightEmission = 1,
		Brightness = 2.4,
		Color = colors(HOT, CYAN),
		Lifetime = NumberRange.new(0.15, 0.35),
		Speed = NumberRange.new(30, 65),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 7,
		Squash = NumberSequence.new(1.8),
		Size = seq({ { 0, 0.9 }, { 1, 0 } }),
	})
	flash:Emit(1)
	ring:Emit(1)
	sparks:Emit(36)
	Fx.shake(0.35)
	if player == Players.LocalPlayer then
		Fx.flash(CYAN, 0.18, 0.12)
	end
	-- raios saindo do ponto do acerto
	local now = os.clock()
	if c then
		for _, bolt in c.bolts do
			strike(bolt, at, 9, 1, 0.1, now)
		end
	end
	local light = Instance.new("PointLight")
	light.Color = CYAN
	light.Range = 22
	light.Brightness = 6
	light.Shadows = false
	light.Parent = holder
	TweenService:Create(light, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0 }):Play()
end

-- Capturas: para os efeitos do jogador no tempo t (nil solta e deixa terminar).
function ShidoriFx.freeze(player: Player, t: number?)
	local c = casts[player]
	if c then
		c.frozen = t
		if t then
			-- os sons de cada fase tocariam uma vez só; numa pose parada ficam mudos
			c.loop.Volume = 0
		end
	end
end

-- Para os testes: quem está com efeito ativo e quantas peças existem.
function ShidoriFx.debug(): { [string]: any }
	local out = {}
	for player, c in casts do
		out[player.Name] = { t = os.clock() - c.start, parts = #c.folder:GetDescendants(), ending = c.ending ~= nil }
	end
	return out
end

return ShidoriFx
