--!strict
-- Combo M1 da espada do Asta no cliente (servidor: src/server/SwordCombat.luau; golpes:
-- src/shared/SwordMoves.luau; efeitos: SwordFx.luau).
--
-- Entrada: botão esquerdo (toque, R2 no controle) com a espada na mão. Segurar encadeia sozinho.
-- Estado: um golpe por vez; clique antes da janela de encadear fica guardado (um só) e sai no
-- começo dela; depois do último golpe, uma pausa curta (Config.Sword.finisherRest) e o combo
-- recomeça. Guardar a espada, morrer ou renascer cancela tudo e devolve o controle.
--
-- Pose: depois de todas as camadas de Pose.luau (gancho Pose.after), o corpo segue as chaves do
-- golpe e os dois braços vão por IK até o cabo: a mão direita leva a espada (presa nela) até onde
-- o golpe manda, a esquerda segura o cabo abaixo dela. A pose final replica para os outros pelo
-- espelho de poses (Pose.luau).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local SwordMoves = require(ReplicatedStorage.Shared.SwordMoves)
local Bag = require(script.Parent.Bag)
local Move = require(script.Parent.Move)
local Pose = require(script.Parent.Pose)
local Super = require(script.Parent.Super)
local SwordFx = require(script.Parent.SwordFx)
local Windows = require(script.Parent.Windows)

local NAME = "AntiMagicSword"
local SWORD = Config.Sword
local COMBO = SwordMoves.COMBO
local player = Players.LocalPlayer

local SwordCombat = {}

type Swing = { index: number, t: number, from: SwordMoves.Pose?, buffered: boolean }

local swing: Swing? = nil
local lastPose: SwordMoves.Pose? = nil -- última pose tocada (a volta para a pose de segurar parte dela)
local weight = 0
local restUntil = 0
local hitstopUntil = 0
local holding = false
local facing: number? = nil -- yaw para onde o corpo vira no preparo
local remote: RemoteEvent? = nil
local rig: SwordMoves.Rig? = nil
local rigOf: Model? = nil
local stats = { swings = 0, started = {} :: { number }, rightError = 0, leftError = 0, minTip = math.huge }

local function character(): (Model?, Humanoid?, BasePart?)
	local model = player.Character
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	local root = model and model:FindFirstChild("HumanoidRootPart")
	if model and humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
		return model, humanoid, root
	end
	return nil, nil, nil
end

local function gripWeld(model: Model): Weld?
	local sword = model:FindFirstChild(NAME)
	local handle = sword and (sword :: Model).PrimaryPart
	local weld = handle and handle:FindFirstChild("SwordGrip")
	return if weld and weld:IsA("Weld") then weld else nil
end

local function canAttack(): boolean
	local model = character()
	return model ~= nil
		and model:FindFirstChild(NAME) ~= nil
		and player:GetAttribute("Riding") ~= true
		and not Windows.current()
		and not Super.isBusy()
end

local function release(humanoid: Humanoid?)
	swing = nil
	facing = nil
	Move.speedScale = 1
	if humanoid then
		humanoid.AutoRotate = true
	end
end

-- Corta o golpe na hora (espada guardada, morte, renascer): nada fica preso.
local function cancel()
	local _, humanoid = character()
	release(humanoid or (player.Character and player.Character:FindFirstChildOfClass("Humanoid")))
	weight = 0
	lastPose = nil
	hitstopUntil = 0
	SwordFx.stop(player)
end

local aimLock: number? = nil -- testes/capturas: yaw fixo em vez da câmera

local function aimYaw(root: BasePart): number?
	if aimLock then
		return aimLock
	end
	-- perto do golem, vira para ele; senão, para onde a câmera olha
	local target = if Bag.target then Bag.target() else nil
	local dir: Vector3
	if target then
		dir = target - root.Position
	else
		dir = workspace.CurrentCamera.CFrame.LookVector
	end
	dir = Vector3.new(dir.X, 0, dir.Z)
	if dir.Magnitude < 0.05 then
		return nil
	end
	return math.atan2(-dir.X, -dir.Z)
end

local function start(index: number)
	local _, humanoid, root = character()
	if not humanoid or not root then
		return
	end
	local from: SwordMoves.Pose? = nil
	local current = swing
	if current then
		from = SwordMoves.sample(COMBO[current.index], current.t, current.from)
	elseif weight > 0 and lastPose then
		from = lastPose -- ainda voltando do golpe anterior: parte de onde está
	end
	swing = { index = index, t = 0, from = from, buffered = false }
	facing = aimYaw(root)
	humanoid.AutoRotate = false
	Move.speedScale = SWORD.moveScale
	stats.swings += 1
	table.insert(stats.started, index)
	if remote then
		remote:FireServer("swing", index)
	end
	SwordFx.swing(player, index)
end

-- Clique (ou botão segurado): começa, encadeia ou guarda o próximo golpe.
local function request()
	if not canAttack() then
		return
	end
	local current = swing
	if current then
		local move = COMBO[current.index]
		local chain = move.chain
		if chain and current.index < #COMBO and current.t >= chain[1] and current.t <= chain[2] then
			start(current.index + 1)
		else
			current.buffered = true
		end
	elseif os.clock() >= restUntil then
		start(1)
	end
end

local function update(dt: number)
	local current = swing
	if not current then
		if holding and os.clock() >= restUntil and canAttack() then
			start(1)
		end
		return
	end
	local _, humanoid, root = character()
	if not humanoid or not root or not canAttack() then
		cancel()
		return
	end
	if os.clock() >= hitstopUntil then
		current.t += dt
	end
	local move = COMBO[current.index]
	local t = current.t
	-- vira o corpo para o alvo durante o preparo (o golpe sai na direção certa)
	if facing and t < move.hit[1] then
		local _, yaw = root.CFrame:ToOrientation()
		local diff = math.atan2(math.sin(facing - yaw), math.cos(facing - yaw))
		local step = diff * (1 - math.exp(-SWORD.turnSpeed * dt))
		root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yaw + step, 0)
	end
	local chain = move.chain
	if (current.buffered or holding) and chain and current.index < #COMBO and t >= chain[1] then
		start(current.index + 1)
		return
	end
	local finish = if chain then chain[2] else move.duration
	if t >= finish then
		lastPose = SwordMoves.sample(move, t, current.from)
		restUntil = os.clock() + (if current.index == #COMBO then SWORD.finisherRest else 0)
		release(humanoid)
		if current.buffered and current.index < #COMBO then
			-- não deveria sobrar clique guardado aqui, mas se sobrar o combo recomeça
			restUntil = 0
		end
	end
end

---------------------------------------------------------------------------------------------------
-- IK de dois ossos (ombro e cotovelo; o punho só gira) para um braço, tudo no espaço do
-- HumanoidRootPart. Devolve as três rotações das juntas.

local function basis(primary: Vector3, secondary: Vector3): CFrame
	local y = primary.Unit
	local x = secondary - y * y:Dot(secondary)
	if x.Magnitude < 1e-4 then
		x = y:Cross(Vector3.zAxis)
		if x.Magnitude < 1e-4 then
			x = y:Cross(Vector3.xAxis)
		end
	end
	x = x.Unit
	return CFrame.fromMatrix(Vector3.zero, x, y, x:Cross(y))
end

local function solveArm(r: SwordMoves.Rig, side: string, chest: CFrame, hand: CFrame, pole: Vector3): (CFrame, CFrame, CFrame)
	local j = r.joints
	local sh, el, wr = j[side .. "Shoulder"], j[side .. "Elbow"], j[side .. "Wrist"]
	local shoulder = chest * sh.c0
	local upper = sh.c1:Inverse() * el.c0
	local lower = el.c1:Inverse() * wr.c0
	local target = shoulder:PointToObjectSpace(hand * wr.c1.Position)
	local function wristAt(bend: number): Vector3
		return (upper * CFrame.Angles(bend, 0, 0)) * lower.Position
	end
	local longest, shortest = wristAt(0).Magnitude * 0.999, wristAt(2.6).Magnitude
	local want = math.clamp(target.Magnitude, shortest, longest)
	local lo, hi = 0, 2.6
	for _ = 1, 16 do
		local mid = (lo + hi) / 2
		if wristAt(mid).Magnitude > want then
			lo = mid
		else
			hi = mid
		end
	end
	local bend = (lo + hi) / 2
	local reach = wristAt(bend)
	local poleLocal = shoulder:VectorToObjectSpace(chest:VectorToWorldSpace(pole))
	local turn = basis(target, poleLocal) * basis(reach, upper.Position):Inverse()
	local elbow = CFrame.Angles(bend, 0, 0)
	local wristFrame = shoulder * turn * upper * elbow * lower
	local wrist = (wristFrame:Inverse() * hand * wr.c1).Rotation
	return turn, elbow, wrist
end

local function blend(motor: any, target: CFrame, w: number)
	if motor and motor.Parent then
		motor.Transform = if w >= 1 then target else motor.Transform:Lerp(target, w)
	end
end

-- Ponta da lâmina no espaço do Hold, guardada por espada (muda se a espada for trocada).
local tipCache: { sword: Instance?, tip: Vector3? } = { sword = nil, tip = nil }
local function tipFor(model: Model): Vector3?
	local sword = model:FindFirstChild(NAME)
	if sword ~= tipCache.sword then
		tipCache.sword = sword
		tipCache.tip = if sword and sword:IsA("Model") then SwordMoves.tip(sword) else nil
	end
	return tipCache.tip
end

-- Gancho do Pose: aplica o golpe por cima de todas as camadas.
local function apply(dt: number, motors: { [string]: any }): boolean
	update(dt)
	local current = swing
	weight += ((if current then 1 else 0) - weight) * (1 - math.exp(-(if current then 22 else 9) * dt))
	if not current and weight < 0.01 then
		weight = 0
		return false
	end
	local model, _, root = character()
	if not model or not root then
		return false
	end
	if rigOf ~= model then
		rig = SwordMoves.rig(model)
		rigOf = model
	end
	local r = rig
	local weld = gripWeld(model)
	if not r or not weld then
		return false
	end
	local pose = if current then SwordMoves.sample(COMBO[current.index], current.t, current.from) else lastPose
	if not pose then
		return false
	end
	if current then
		lastPose = pose
	end
	local w = weight
	for _, name in SwordMoves.BODY do
		local target = pose.joints[name]
		if name == "Root" then
			target = CFrame.new(target.Position * r.scale) * target.Rotation
		end
		blend(motors[name], target, w)
	end
	-- espada onde o golpe manda; a mão direita vai até ela, a esquerda segura o cabo mais abaixo
	local chest = SwordMoves.chest(r, pose)
	local hold = SwordMoves.hold(r, pose)
	-- espada grande: a ponta não atravessa o chão (a mesma trava do servidor)
	local tip, floor = tipFor(model), SwordMoves.floor(model)
	if tip and floor then
		hold = SwordMoves.aboveFloor(hold, tip, floor, SWORD.floorMargin)
		-- testes: altura real da ponta acima do chão (quadro anterior)
		local holdAt = (weld.Part1 :: BasePart):FindFirstChild("Hold")
		if current and holdAt and holdAt:IsA("Attachment") then
			stats.minTip = math.min(stats.minTip, root.CFrame:PointToObjectSpace(holdAt.WorldCFrame * tip).Y - floor)
		end
	end
	local right = hold * weld.C0:Inverse()
	local leftPoint = hold * Vector3.new(0, -SwordMoves.LEFT_ON_GRIP * r.scale, 0)
	local left = CFrame.new(leftPoint - right.Rotation * weld.C0.Position) * right.Rotation
	-- cotovelos para baixo e para fora; com a espada no alto, para fora e para a frente
	local high = math.clamp((pose.hold.Position.Y + 0.3) / 0.9, 0, 1)
	local poleR = Vector3.new(0.6, -1 + high * 0.9, 0.35 - high * 0.8)
	local poleL = Vector3.new(-poleR.X, poleR.Y, poleR.Z)
	local rs, re, rw = solveArm(r, "Right", chest, right, poleR)
	local ls, le, lw = solveArm(r, "Left", chest, left, poleL)
	blend(motors.RightShoulder, rs, w)
	blend(motors.RightElbow, re, w)
	blend(motors.RightWrist, rw, w)
	blend(motors.LeftShoulder, ls, w)
	blend(motors.LeftElbow, le, w)
	blend(motors.LeftWrist, lw, w)
	return true
end

-- Para os testes do servidor (TestUi "swordCombat"): estado, clique simulado e erro das mãos.
function SwordCombat.test(arg: any): any
	local action = if type(arg) == "table" then arg.action else arg
	if action == "click" then
		request()
	elseif action == "lockAim" then
		local _, _, root = character()
		if arg.on and root then
			local _, yaw = root.CFrame:ToOrientation()
			aimLock = yaw
		else
			aimLock = nil
		end
	elseif action == "swipe" then
		SwordFx.testSwipe(arg.index or 1, arg.hold or 3)
	elseif action == "spam" then
		for _ = 1, arg.n do
			request()
		end
	elseif action == "hold" then
		holding = arg.on == true
	elseif action == "reset" then
		cancel()
		restUntil = 0
		stats.swings = 0
		stats.minTip = math.huge
		table.clear(stats.started)
	elseif action == "aim" then
		-- erro (studs) entre onde a pose manda a espada e onde ela está, e entre a mão esquerda e o cabo
		local model, _, root = character()
		local current = swing
		local r = rig
		local weld = model and gripWeld(model)
		if not model or not root or not current or not r or not weld then
			return nil
		end
		local pose = SwordMoves.sample(COMBO[current.index], current.t, current.from)
		local tipLocal = tipFor(model) or Vector3.new(0, 4.35, 0)
		local want = root.CFrame * SwordMoves.aboveFloor(SwordMoves.hold(r, pose), tipLocal, SwordMoves.floor(model) or -3, SWORD.floorMargin)
		local handle = weld.Part1 :: BasePart
		local hold = handle:FindFirstChild("Hold") :: Attachment
		local leftHand = model:FindFirstChild("LeftHand") :: BasePart
		local leftWant = hold.WorldCFrame * Vector3.new(0, -SwordMoves.LEFT_ON_GRIP * r.scale, 0)
		local leftGrip = leftHand.CFrame * weld.C0.Position
		local tip = hold.WorldCFrame * tipLocal -- onde a ponta está de verdade
		return {
			index = current.index,
			t = current.t,
			weight = weight,
			right = (hold.WorldPosition - want.Position).Magnitude,
			left = (leftGrip - leftWant).Magnitude,
			tipHeight = tip.Y - (root.Position.Y - root.Size.Y / 2 - (model:FindFirstChildOfClass("Humanoid") :: Humanoid).HipHeight),
			blade = root.CFrame:VectorToObjectSpace(want.UpVector),
		}
	end
	local current = swing
	return {
		swinging = current ~= nil,
		index = if current then current.index else 0,
		t = if current then current.t else 0,
		weight = weight,
		swings = stats.swings,
		minTip = stats.minTip,
		started = table.clone(stats.started),
		speedScale = Move.speedScale,
		autoRotate = (function()
			local _, humanoid = character()
			return humanoid ~= nil and humanoid.AutoRotate
		end)(),
		fx = SwordFx.debug(),
	}
end

local function isAttackInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
		or input.KeyCode == Enum.KeyCode.ButtonR2
end

function SwordCombat.start()
	SwordFx.start()
	task.spawn(function()
		local found = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SwordCombat", 30)
		if found and found:IsA("RemoteEvent") then
			remote = found
		end
	end)
	-- com a espada na mão o clique é golpe: o soco (saco e golem) fica de fora
	Bag.blocked = function()
		local model = player.Character
		return model ~= nil and model:FindFirstChild(NAME) ~= nil
	end
	SwordFx.onImpact = function()
		hitstopUntil = os.clock() + SWORD.hitstop
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and isAttackInput(input) then
			holding = true
			request()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if isAttackInput(input) then
			holding = false
		end
	end)

	local function watch(model: Model)
		cancel()
		rig = nil
		rigOf = nil
		model.ChildRemoved:Connect(function(child)
			if child.Name == NAME then
				cancel()
			end
		end)
		local humanoid = model:WaitForChild("Humanoid", 10)
		if humanoid and humanoid:IsA("Humanoid") then
			humanoid.Died:Connect(cancel)
		end
	end
	player.CharacterAdded:Connect(watch)
	if player.Character then
		task.spawn(watch, player.Character)
	end
	Pose.after(apply)
end

return SwordCombat
