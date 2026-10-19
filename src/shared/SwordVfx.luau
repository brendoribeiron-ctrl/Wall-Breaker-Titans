--!strict
-- Modelos dos efeitos da espada do Asta, para editar no Studio: ParticleEmitter, Beam, Trail e
-- PointLight de verdade dentro de ReplicatedStorage.SwordVFX. O cliente (src/client/SwordFx.luau)
-- só CLONA daqui; o que o código decide é onde cada peça vai (geometria da lâmina, caminho do golpe)
-- e quando ela aparece. Cor, textura, brilho, tamanho, tempo de vida, velocidade, quantidade etc.
-- vêm das propriedades dos modelos e dos atributos (aba Atributos nas Propriedades).
--
-- Criar a pasta no place para editar (modo de edição, uma vez; depois salvar o place):
--   node tools/bridge.cjs run edit tools/vfx/sword_vfx.luau          (não mexe se já existir)
--   node tools/bridge.cjs run edit tools/vfx/sword_vfx_reset.luau    (refaz com os padrões)
-- Sem a pasta no place, o jogo usa SwordVfx.build() (estes padrões).
--
-- Regras para quem edita:
--  * Tamanhos e velocidades estão na escala 1 (espada de 4,1 studs); o jogo multiplica pela
--    escala da espada e pelo atributo Size das pastas.
--  * ParticleEmitter de golpe solta uma leva: atributo Count (e HeavyCount no golpe final).
--  * Atributo UseAuraColor = true: a cor vem da aura equipada (desmarque para usar a Color do modelo).
--  * Beams da meia-lua: Color vai da cauda (0) para a cabeça (1); Transparency é do código (a cauda
--    dissolvendo); a transparência mínima é o atributo Alpha.
--  * Trails do golpe: Transparency é a cara do rastro aceso; Life1/Life2/Life3 = quanto dura em
--    cada golpe do combo (0 = desligado nesse golpe).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Textures = require(script.Parent.Textures)

local SwordVfx = {}

SwordVfx.NAME = "SwordVFX"

local WHITE = Color3.new(1, 1, 1)
local ANTI = Color3.fromRGB(14, 10, 20)
local VOID = Color3.fromRGB(26, 4, 46)
local VIOLET = Color3.fromRGB(118, 36, 255)
local MAGENTA = Color3.fromRGB(196, 70, 255)
local LILAC = Color3.fromRGB(232, 200, 255)
-- rastros do golpe (18/10, quarta versão): cores vivas e núcleo quente. Céu claro + camada aditiva
-- (LightEmission alto) = branco: halo e corpo misturam por transparência (emissão baixa) e só o
-- núcleo e o fio da borda são aditivos. Brightness > 2 passa do Threshold do Bloom e estoura.
local VIVID = Color3.fromRGB(150, 60, 255)
local PINK = Color3.fromRGB(240, 90, 255)
local HOT = Color3.fromRGB(255, 220, 255)

local function seq(points: { { number } }): NumberSequence
	local keys = {}
	for _, point in points do
		table.insert(keys, NumberSequenceKeypoint.new(point[1], point[2]))
	end
	return NumberSequence.new(keys)
end

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

local function attrs(instance: Instance, values: { [string]: any }?)
	if values then
		for key, value in values do
			instance:SetAttribute(key, value)
		end
	end
end

local function folder(parent: Instance, name: string, values: { [string]: any }?): Folder
	local f = Instance.new("Folder")
	f.Name = name
	attrs(f, values)
	f.Parent = parent
	return f
end

local function attachment(parent: Instance, name: string, values: { [string]: any }?): Attachment
	local a = Instance.new("Attachment")
	a.Name = name
	attrs(a, values)
	a.Parent = parent
	return a
end

-- Emissor com os padrões do jogo; props sobrescreve, values vira atributos.
local function emitter(parent: Instance, name: string, texture: string?, props: { [string]: any }, values: { [string]: any }?): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Texture = texture or ""
	e.LockedToPart = false
	e.Enabled = false
	e.Rate = 0
	if texture == Textures.spark then
		e.Squash = NumberSequence.new(1.6) -- faísca fina e comprida
		e.Rotation = NumberRange.new(0)
		e.RotSpeed = NumberRange.new(0)
	else
		e.Rotation = NumberRange.new(-20, 20)
		e.RotSpeed = NumberRange.new(-30, 30)
	end
	for key, value in props do
		(e :: any)[key] = value
	end
	attrs(e, values)
	e.Parent = parent
	return e
end

local function beam(parent: Instance, name: string, props: { [string]: any }, values: { [string]: any }?): Beam
	local b = Instance.new("Beam")
	b.Name = name
	for key, value in props do
		(b :: any)[key] = value
	end
	attrs(b, values)
	b.Parent = parent
	return b
end

local function trail(parent: Instance, name: string, props: { [string]: any }, values: { [string]: any }?): Trail
	local t = Instance.new("Trail")
	t.Name = name
	t.TextureMode = Enum.TextureMode.Stretch
	t.MinLength = 0.03
	t.FaceCamera = false
	for key, value in props do
		(t :: any)[key] = value
	end
	attrs(t, values)
	t.Parent = parent
	return t
end

-- Monta a pasta com os padrões (não põe em lugar nenhum).
function SwordVfx.build(): Folder
	local root = Instance.new("Folder")
	root.Name = SwordVfx.NAME

	-------------------------------------------------------------------------------------------
	-- Aura na lâmina, enquanto a espada está na mão e há aura equipada. Rate e Brightness são
	-- os da aura mais forte; aura fraca usa menos (o código multiplica).
	local blade = folder(root, "Blade", {
		ShellEnabled = true, -- casca ForceField da malha da lâmina
		ShellScale = 1.12,
		ShellTransparency = 0.7,
	})
	beam(blade, "Glow", {
		Texture = Textures.glow or "",
		FaceCamera = true,
		LightEmission = 0.6,
		Segments = 4,
		Color = colors(VIOLET, LILAC),
		Transparency = seq({ { 0, 0.7 }, { 1, 0.96 } }),
	}, { UseAuraColor = true, Width0 = 1.9, Width1 = 0.8 })
	beam(blade, "FlowEdge", {
		Texture = Textures.blade_flow or "",
		TextureMode = Enum.TextureMode.Wrap,
		FaceCamera = true,
		LightEmission = 1,
		ZOffset = 0.4,
		Segments = 6,
		TextureSpeed = 1.8,
		Color = colors(LILAC, VIOLET),
		Transparency = seq({ { 0, 1 }, { 0.1, 0.05 }, { 0.85, 0.1 }, { 1, 1 } }),
	}, { UseAuraColor = true, Width = 0.68, Length = 2.6 })
	beam(blade, "FlowCore", {
		Texture = Textures.blade_flow or "",
		TextureMode = Enum.TextureMode.Wrap,
		FaceCamera = true,
		LightEmission = 0.4,
		ZOffset = -0.1,
		Segments = 6,
		TextureSpeed = 0.8,
		Color = colors(VIOLET, MAGENTA),
		Transparency = seq({ { 0, 1 }, { 0.1, 0.7 }, { 0.85, 0.8 }, { 1, 1 } }),
	}, { UseAuraColor = true, Width = 1, Length = 3.6 })
	beam(blade, "Bolt", {
		Texture = Textures.bolt or "",
		TextureMode = Enum.TextureMode.Stretch,
		FaceCamera = true,
		LightEmission = 0.8,
		Segments = 1,
		Color = colors(ANTI),
		Transparency = NumberSequence.new(0.1),
	}, { UseAuraColor = true, Width = 0.8, Count = 2, AuraChance = 0.45 })
	local flipbook = { FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot }
	local flames = emitter(blade, "Flames", Textures.flame, {
		Shape = Enum.ParticleEmitterShape.Box,
		LightEmission = 0.3,
		Brightness = 1.4,
		Lifetime = NumberRange.new(0.35, 0.6),
		Speed = NumberRange.new(0.5, 1.4),
		Acceleration = Vector3.new(0, 7, 0),
		Size = seq({ { 0, 0.55 }, { 1, 0.15 } }),
		Transparency = seq({ { 0, 0.1 }, { 0.8, 0.3 }, { 1, 1 } }),
		ZOffset = 0.3,
		Rate = 14,
		Color = colors(VIOLET, MAGENTA),
	}, { UseAuraColor = true, BoostRate = 2 })
	flames.FlipbookLayout = flipbook.FlipbookLayout
	flames.FlipbookMode = flipbook.FlipbookMode
	local smoke = emitter(blade, "Smoke", Textures.flame, {
		Shape = Enum.ParticleEmitterShape.Box,
		LightEmission = 0, -- preto cheio: a antimagia
		Color = colors(ANTI),
		Lifetime = NumberRange.new(0.4, 0.7),
		Speed = NumberRange.new(0.3, 0.9),
		Acceleration = Vector3.new(0, 4, 0),
		Size = seq({ { 0, 0.45 }, { 1, 0.1 } }),
		Transparency = seq({ { 0, 0.25 }, { 1, 1 } }),
		ZOffset = -0.2,
		Rate = 7,
	}, { UseAuraColor = false, BoostRate = 1 })
	smoke.FlipbookLayout = flipbook.FlipbookLayout
	smoke.FlipbookMode = flipbook.FlipbookMode
	emitter(blade, "Embers", Textures.spark, {
		Shape = Enum.ParticleEmitterShape.Box,
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		EmissionDirection = Enum.NormalId.Top,
		LightEmission = 1,
		Lifetime = NumberRange.new(0.35, 0.7),
		Speed = NumberRange.new(2, 5),
		SpreadAngle = Vector2.new(25, 25),
		Acceleration = Vector3.new(0, 6, 0),
		Drag = 1.5,
		Size = seq({ { 0, 0.32 }, { 1, 0 } }),
		Rate = 9,
		Color = colors(LILAC, VIOLET),
	}, { UseAuraColor = true, BoostRate = 2 })
	emitter(blade, "Orbs", Textures.glow, {
		Shape = Enum.ParticleEmitterShape.Box,
		LightEmission = 1,
		Lifetime = NumberRange.new(0.6, 1.1),
		Speed = NumberRange.new(0.4, 1.2),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, 1.5, 0),
		Size = seq({ { 0, 0 }, { 0.2, 0.4 }, { 1, 0 } }),
		Transparency = seq({ { 0, 0.2 }, { 1, 1 } }),
		Rate = 4,
		Color = colors(LILAC, VIOLET),
	}, { UseAuraColor = true, BoostRate = 1 })
	local light = Instance.new("PointLight")
	light.Name = "Light"
	light.Range = 8
	light.Brightness = 1.3
	light.Shadows = false
	light.Color = VIOLET
	attrs(light, { UseAuraColor = true })
	light.Parent = blade

	-------------------------------------------------------------------------------------------
	-- Rastros presos na lâmina durante o golpe + faíscas da ponta.
	local swing = folder(root, "Swing")
	-- textura lisa (sem estrias): o rastro corre inteiro, sem quebrar
	trail(swing, "SwingAura", {
		Texture = Textures.energy_profile or "",
		LightEmission = 0.3,
		Brightness = 1,
		Color = colors(VIVID, PINK),
		Transparency = seq({ { 0, 0.35 }, { 0.45, 0.6 }, { 1, 1 } }),
	}, { Life1 = 0.2, Life2 = 0.28, Life3 = 0.24 })
	trail(swing, "SwingCore", {
		Texture = Textures.energy_core or "",
		LightEmission = 0.4,
		Brightness = 1,
		Color = colors(HOT, PINK),
		Transparency = seq({ { 0, 0.3 }, { 0.35, 0.55 }, { 1, 1 } }),
	}, { Life1 = 0.16, Life2 = 0.22, Life3 = 0.2 })
	trail(swing, "SwingEdge", {
		LightEmission = 0.7,
		Brightness = 1.2,
		Color = colors(HOT, PINK),
		Transparency = seq({ { 0, 0.1 }, { 0.4, 0.55 }, { 1, 1 } }),
	}, { Life1 = 0.22, Life2 = 0.28, Life3 = 0.26 })
	trail(swing, "SwingDark", {
		Texture = Textures.energy_profile or "",
		LightEmission = 0,
		Color = colors(VOID, VIOLET:Lerp(VOID, 0.6)),
		Transparency = seq({ { 0, 0 }, { 0.45, 0.25 }, { 1, 1 } }),
	}, { Life1 = 0, Life2 = 0, Life3 = 0 }) -- o preto apagava o brilho; desligado
	emitter(swing, "TipSparks", Textures.spark, {
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		LightEmission = 0.6,
		Lifetime = NumberRange.new(0.15, 0.32),
		Speed = NumberRange.new(10, 24),
		SpreadAngle = Vector2.new(70, 70),
		Drag = 5,
		Acceleration = Vector3.new(0, -20, 0),
		Size = seq({ { 0, 0.4 }, { 1, 0 } }),
		Brightness = 1.5,
		Color = colors(HOT, PINK, VIVID),
		Rate = 32,
	})

	-------------------------------------------------------------------------------------------
	-- Meia-lua do corte. Cada Beam é uma camada (de baixo para cima pela ZOffset):
	--   Radius 0 = meio da lâmina, 1 = ponta; Width × distância ponta-meio; Alpha = transparência
	--   mínima; Scroll = rolagem das estrias (0 = parada); HeavyOnly = só no golpe final.
	local swipe = folder(root, "Swipe", {
		Segments = 16, -- trechos de Beam no arco (menos = facetado)
		Width = 1, -- largura geral
		TailLength = 0.65, -- maior = cauda mais longa
		LifeSlash = 0.3, -- s para sumir depois do corte (golpes 1 e 2)
		LifeHeavy = 0.4, -- golpe final
		GrowSlash = 0.14, -- quanto abre para fora ao sumir
		GrowHeavy = 0.22,
	})
	-- LightEmission 1 soma as camadas e tudo vira branco: só o núcleo e o fio são aditivos
	local function layer(name: string, texture: string?, color: ColorSequence, brightness: number, emission: number, values: { [string]: any })
		beam(swipe, name, {
			Texture = texture or "",
			Color = color,
			LightEmission = emission,
			Brightness = brightness,
			ZOffset = 1 + (values.Radius :: number) * 0.1,
			-- fita deitada no plano do golpe (a largura segue o attachment): com FaceCamera cada
			-- trecho virava para a câmera do seu jeito e a borda de fora ficava com dentes
			FaceCamera = false,
			Segments = 16,
		}, values)
	end
	-- halo largo e macio, corpo liso de cor viva, núcleo quente e fio de borda (sem estrias: a
	-- fita corre inteira, sem quebrar)
	layer("Glow", Textures.band_glow_x, colors(VIVID, PINK), 1, 0.15, { Radius = 0.8, Width = 1.3, HeavyWidth = 1.7, Alpha = 0.6, Scroll = 0, HeavyOnly = false })
	layer("Body", Textures.band_body_x, colors(VIVID, PINK), 1, 0, { Radius = 0.82, Width = 0.95, Alpha = 0.12, Scroll = 0, HeavyOnly = false })
	layer("Core", Textures.band_core_x, colors(PINK, HOT), 1.2, 0.6, { Radius = 0.93, Width = 0.2, Alpha = 0.25, Scroll = 0, HeavyOnly = false })
	layer("Edge", Textures.band_core_x, colors(PINK, HOT), 1.3, 1, { Radius = 1, Width = 0.1, Alpha = 0.1, Scroll = 0, HeavyOnly = false })
	layer("Echo", Textures.band_glow_x, colors(VIVID, PINK), 1, 0.15, { Radius = 1.18, Width = 0.5, Alpha = 0.55, Scroll = 0, HeavyOnly = true })
	local dust = attachment(swipe, "Dust")
	emitter(dust, "Stars", Textures.star, {
		LightEmission = 1,
		Brightness = 1.2,
		Color = colors(HOT, PINK),
		Lifetime = NumberRange.new(0.35, 0.8),
		Speed = NumberRange.new(1, 4),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 3,
		Acceleration = Vector3.new(0, -3, 0),
		Size = seq({ { 0, 0 }, { 0.15, 0.3 }, { 1, 0 } }),
		RotSpeed = NumberRange.new(-180, 180),
	}, { Count = 2, HeavyCount = 4 })
	emitter(dust, "Orbs", Textures.glow, {
		LightEmission = 1,
		Brightness = 1,
		Color = colors(PINK, VIVID),
		Lifetime = NumberRange.new(0.4, 0.9),
		Speed = NumberRange.new(0.5, 2.5),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 2,
		Acceleration = Vector3.new(0, -2, 0),
		Size = seq({ { 0, 0.3 }, { 1, 0 } }),
		Transparency = seq({ { 0, 0.2 }, { 1, 1 } }),
	}, { Count = 2, HeavyCount = 3 })
	local flash = attachment(swipe, "Flash")
	emitter(flash, "Glow", Textures.glow, {
		LightEmission = 1,
		Brightness = 1,
		Color = colors(PINK),
		Lifetime = NumberRange.new(0.12),
		Speed = NumberRange.new(0),
		Size = seq({ { 0, 1.3 }, { 1, 0.3 } }),
		Transparency = seq({ { 0, 0.2 }, { 1, 1 } }),
		ZOffset = 1.5,
	}, { Count = 1, HeavyCount = 1, HeavySize = 1.45 })

	-------------------------------------------------------------------------------------------
	-- Acerto no alvo (ponto do servidor): faíscas em raio, flash, anel e orbes, virados para quem
	-- bateu. Size e Speed × tamanho do golpe.
	local hit = folder(root, "Hit", {
		Size = 1,
		HeavySize = 1.3,
		Star = 8, -- riscos da estrela (Fx.star)
		HeavyStar = 11,
		StarColor = WHITE:Lerp(LILAC, 0.3),
		Debris = 4, -- cubinhos (Fx.cubes)
		HeavyDebris = 6,
		DebrisColor = VIOLET,
		Shake = 0.15,
		HeavyShake = 0.3,
	})
	local burst = attachment(hit, "Burst")
	emitter(burst, "Sparks", Textures.spark, {
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		LightEmission = 1,
		Color = colors(LILAC, LILAC, MAGENTA),
		Lifetime = NumberRange.new(0.18, 0.34),
		Speed = NumberRange.new(30, 60),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 7,
		Size = seq({ { 0, 1.1 }, { 1, 0 } }),
	}, { Count = 14 })
	emitter(burst, "Flash", Textures.glow, {
		LightEmission = 0.5,
		Color = colors(MAGENTA:Lerp(WHITE, 0.25)),
		Lifetime = NumberRange.new(0.09),
		Speed = NumberRange.new(0),
		Size = seq({ { 0, 3.5 }, { 1, 0.5 } }),
		Transparency = seq({ { 0, 0.15 }, { 1, 1 } }),
		ZOffset = 1,
	}, { Count = 1 })
	emitter(burst, "Ring", Textures.ring_glow, {
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		EmissionDirection = Enum.NormalId.Front,
		LightEmission = 0.8,
		Color = colors(LILAC, MAGENTA),
		Lifetime = NumberRange.new(0.3),
		Speed = NumberRange.new(0.01),
		SpreadAngle = Vector2.new(0, 0),
		Size = seq({ { 0, 1 }, { 1, 13 } }),
		Transparency = seq({ { 0, 0 }, { 1, 1 } }),
	}, { Count = 1 })
	emitter(burst, "Orbs", Textures.glow, {
		LightEmission = 1,
		Color = colors(LILAC, MAGENTA),
		Lifetime = NumberRange.new(0.35, 0.7),
		Speed = NumberRange.new(6, 16),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 4,
		Size = seq({ { 0, 0.7 }, { 1, 0 } }),
	}, { Count = 8 })

	-------------------------------------------------------------------------------------------
	-- Golpe final batendo no chão. Up = virado para cima no ponto do golpe; Flat = deitado,
	-- virado para a frente do jogador. Também solta o Hit.Burst (BlastSize) no ponto.
	local ground = folder(root, "Ground", {
		Size = 1,
		BlastSize = 0.7,
		Debris = 8,
		DebrisColor = Color3.fromRGB(92, 84, 78),
		Bolts = 4,
		Shake = 0.45,
		ScreenFlash = true,
		ScreenFlashColor = VIOLET,
	})
	local up = attachment(ground, "Up")
	local ringProps = {
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		EmissionDirection = Enum.NormalId.Front,
		Speed = NumberRange.new(0.01),
		SpreadAngle = Vector2.new(0, 0),
		Transparency = seq({ { 0, 0 }, { 1, 1 } }),
	}
	local outer = table.clone(ringProps)
	outer.LightEmission = 0.8
	outer.Color = colors(LILAC, VIOLET)
	outer.Lifetime = NumberRange.new(0.42)
	outer.Size = seq({ { 0, 2 }, { 1, 22 } })
	emitter(up, "RingOuter", Textures.ring_glow, outer, { Count = 1 })
	local inner = table.clone(ringProps)
	inner.LightEmission = 0
	inner.Color = colors(VOID)
	inner.Lifetime = NumberRange.new(0.32)
	inner.Size = seq({ { 0, 2 }, { 1, 12 } })
	emitter(up, "RingInner", Textures.ring_glow, inner, { Count = 1 })
	emitter(up, "Crack", Textures.crack, {
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		EmissionDirection = Enum.NormalId.Front,
		LightEmission = 0.6,
		Color = colors(MAGENTA, VIOLET, VOID),
		Lifetime = NumberRange.new(2.2),
		Speed = NumberRange.new(0.01),
		SpreadAngle = Vector2.new(0, 0),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(0),
		Size = seq({ { 0, 7 }, { 0.1, 9 }, { 1, 9 } }),
		Transparency = seq({ { 0, 0 }, { 0.5, 0.25 }, { 1, 1 } }),
	}, { Count = 1 })
	emitter(up, "Column", Textures.spark, {
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		LightEmission = 1,
		Color = colors(LILAC, MAGENTA, VIOLET),
		Lifetime = NumberRange.new(0.25, 0.45),
		Speed = NumberRange.new(28, 48),
		SpreadAngle = Vector2.new(14, 14),
		Drag = 4,
		Size = seq({ { 0, 1 }, { 1, 0 } }),
	}, { Count = 26 })
	local flat = attachment(ground, "Flat")
	emitter(flat, "Sparks", Textures.spark, {
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		LightEmission = 1,
		Color = colors(LILAC, MAGENTA, VIOLET),
		Lifetime = NumberRange.new(0.2, 0.4),
		Speed = NumberRange.new(30, 55),
		SpreadAngle = Vector2.new(180, 8),
		Drag = 6,
		Size = seq({ { 0, 1.2 }, { 1, 0 } }),
	}, { Count = 22 })
	-- raios correndo pelo chão: alterna os dois (Reach = alcance em studs)
	beam(ground, "BoltLight", {
		Texture = Textures.bolt or "",
		FaceCamera = true,
		Width0 = 0.9,
		Width1 = 0.5,
		LightEmission = 0.8,
		Color = colors(LILAC),
	}, { ReachMin = 4, ReachMax = 8 })
	beam(ground, "BoltDark", {
		Texture = Textures.bolt or "",
		FaceCamera = true,
		Width0 = 0.9,
		Width1 = 0.5,
		LightEmission = 0,
		Color = colors(VOID),
	}, { ReachMin = 4, ReachMax = 8 })

	return root
end

-- A pasta do place (editada no Studio) ou, sem ela, os padrões (montados uma vez).
local fallback: Folder? = nil
function SwordVfx.get(): Folder
	local placed = ReplicatedStorage:FindFirstChild(SwordVfx.NAME)
	if placed and placed:IsA("Folder") then
		return placed
	end
	if not fallback then
		fallback = SwordVfx.build()
	end
	return fallback :: Folder
end

return SwordVfx
