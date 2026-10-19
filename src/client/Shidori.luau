--!strict
-- Shidori no cliente: entrada (tecla Z, botão Y do controle, botão na tela), pose do próprio
-- boneco, investida e o botão com a recarga. Quem decide se vale, gasta estamina, conta a
-- recarga e dá dano é o servidor (src/server/Shidori.luau); aqui só se pede e se mostra.
--
-- Pose: camada "shidori" de Pose.luau (chaves em Shared/ShidoriMoves). A pose do próprio boneco
-- vai aos outros pelo espelho de poses, então cada cliente só anima o seu. Os efeitos
-- (ShidoriFx) rodam em todos os clientes, para todos que usarem.
-- O botão "Shidori" é filho direto do HUD: o editor do HUD (celular) move, aumenta e apaga.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local ShidoriMoves = require(ReplicatedStorage.Shared.ShidoriMoves)
local Fx = require(script.Parent.Fx)
local Hud = require(script.Parent.Hud)
local Move = require(script.Parent.Move)
local Pose = require(script.Parent.Pose)
local ShidoriFx = require(script.Parent.ShidoriFx)
local Ui = require(script.Parent.Ui)

local S = Config.Shidori
local player = Players.LocalPlayer

local Shidori = {}

local remote: RemoteEvent? = nil
local castStart: number? = nil -- os.clock() do início da ativação do próprio jogador
local frozenT: number? = nil -- capturas: pose parada neste tempo
local lastRequest = 0
local stats = { requests = 0, casts = 0, stops = 0, impacts = 0, refused = {} :: { string } }

local function unlocked(): boolean
	local level = player:GetAttribute("Stat_shidori")
	return type(level) == "number" and level >= 1
end

local function cooldownLeft(): number
	local ready = player:GetAttribute("ShidoriReady")
	return if type(ready) == "number" then math.max(0, ready - workspace:GetServerTimeNow()) else 0
end

-- Pede ao servidor (as checagens daqui só evitam pedidos inúteis; o servidor confere tudo).
local function request()
	local now = os.clock()
	if now - lastRequest < 0.25 or not remote then
		return
	end
	if not unlocked() then
		Fx.toast("Unlock SHIDORI in the SKILL TREE!", Color3.fromRGB(120, 215, 255))
		return
	end
	if castStart or cooldownLeft() > 0.05 then
		return
	end
	local stamina = player:GetAttribute("Stamina")
	if type(stamina) == "number" and stamina + 1e-6 < S.cost then
		Fx.toast("Not enough stamina!", Color3.fromRGB(120, 160, 220))
		return
	end
	lastRequest = now
	stats.requests += 1
	remote:FireServer("cast")
end
Shidori.request = request

local function character(): (Model?, Humanoid?, BasePart?)
	local model = player.Character
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	local root = model and model:FindFirstChild("HumanoidRootPart")
	if model and humanoid and root and root:IsA("BasePart") then
		return model, humanoid, root
	end
	return nil, nil, nil
end

local lunge: Attachment? = nil
local function endLunge()
	if lunge then
		lunge:Destroy()
		lunge = nil
	end
end

local function finishLocal()
	endLunge()
	castStart = nil
	Pose.weight("shidori", 0)
	Move.speedScale = 1
	local _, humanoid = character()
	if humanoid then
		humanoid.AutoRotate = true
	end
end

-- Pose e investida do próprio boneco, quadro a quadro.
local facing: Vector3? = nil
local function stepLocal()
	if not castStart then
		return
	end
	local _, humanoid, root = character()
	if not humanoid or not root or humanoid.Health <= 0 then
		finishLocal()
		return
	end
	if frozenT then
		castStart = os.clock() - frozenT
	end
	local t = os.clock() - castStart
	if t >= S.recover then
		finishLocal()
		return
	end
	Pose.define("shidori", ShidoriMoves.sample(t))
	Pose.weight("shidori", ShidoriMoves.weight(t), true)
	-- vira para a mira no preparo (a investida vai para lá)
	if facing then
		local look = root.CFrame.LookVector
		local want = facing
		local blended = look:Lerp(want, math.min(1, 0.25)).Unit
		root.CFrame = CFrame.lookAt(root.Position, root.Position + Vector3.new(blended.X, 0, blended.Z))
	end
	if frozenT then
		endLunge()
		Move.speedScale = 0
		return
	end
	if t < S.lungeTime[1] then
		Move.speedScale = S.moveScale
	elseif t <= S.lungeTime[2] then
		-- investida: velocidade no plano do chão por restrição (o Humanoid freia quem só mexe na
		-- velocidade da peça; visto no teste de 18/10: andava 1,4 stud em vez de ~8)
		Move.speedScale = 0
		if not lunge then
			local attachment = Instance.new("Attachment")
			attachment.Name = "ShidoriLunge"
			attachment.Parent = root
			local push = Instance.new("LinearVelocity")
			push.Attachment0 = attachment
			push.RelativeTo = Enum.ActuatorRelativeTo.World
			push.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
			push.PrimaryTangentAxis = Vector3.xAxis
			push.SecondaryTangentAxis = Vector3.zAxis
			push.MaxForce = 1e6
			push.Parent = attachment
			lunge = attachment
		end
		local push = (lunge :: Attachment):FindFirstChildOfClass("LinearVelocity")
		if push then
			local forward = root.CFrame.LookVector * S.lunge
			push.PlaneVelocity = Vector2.new(forward.X, forward.Z)
		end
	else
		endLunge()
		Move.speedScale = 0.3
	end
end

-- Mira: o chefe mais perto (até 30 studs) ou, sem chefe, para onde a câmera olha.
local AIM_RANGE = 30
local fixedAim: Vector3? = nil -- testes e capturas: mira fixa
local function aimFrom(position: Vector3): Vector3?
	if fixedAim then
		return fixedAim
	end
	local best: Vector3? = nil
	local bestDistance = AIM_RANGE
	for _, folder in workspace:GetChildren() do
		if folder:IsA("Folder") and string.match(folder.Name, "^BossRoom") then
			local boss = folder:FindFirstChild("Boss")
			if boss and boss:IsA("Model") then
				local at = boss:GetPivot().Position
				local flat = Vector3.new(at.X - position.X, 0, at.Z - position.Z)
				if flat.Magnitude < bestDistance and flat.Magnitude > 1e-3 then
					bestDistance = flat.Magnitude
					best = flat.Unit
				end
			end
		end
	end
	if best then
		return best
	end
	local camera = workspace.CurrentCamera
	local look = if camera then camera.CFrame.LookVector else Vector3.new(0, 0, -1)
	local flat = Vector3.new(look.X, 0, look.Z)
	return if flat.Magnitude > 1e-3 then flat.Unit else nil
end

local function begin(caster: Player, serverTime: number)
	local lag = math.clamp(workspace:GetServerTimeNow() - serverTime, 0, 0.5)
	ShidoriFx.begin(caster, lag)
	if caster ~= player then
		return
	end
	stats.casts += 1
	castStart = os.clock() - lag
	local _, humanoid, root = character()
	if humanoid then
		humanoid.AutoRotate = false
	end
	facing = if root then aimFrom(root.Position) else nil
end

local function stop(caster: Player)
	ShidoriFx.stop(caster)
	if caster == player then
		stats.stops += 1
		finishLocal()
	end
end

-- Botão redondo com o raio, a tecla e a recarga (no celular é o botão de usar).
local function buildButton()
	local gui = Hud.gui()
	local holder = Ui.frame(gui, "Shidori", UDim2.fromOffset(78, 78), UDim2.new(1, -186, 1, -122), nil, Vector2.new(1, 1))
	Ui.autoScale(holder)
	local button = Instance.new("TextButton")
	button.Name = "Button"
	button.Size = UDim2.fromScale(1, 1)
	button.BackgroundColor3 = Color3.fromRGB(20, 40, 90)
	button.BackgroundTransparency = 0.1
	button.Text = ""
	button.AutoButtonColor = false
	Ui.corner(button, 39)
	local border = Ui.border(button, 3, Color3.fromRGB(120, 215, 255))
	Ui.juice(button, holder)
	button.Parent = holder
	Ui.text(button, { name = "Icon", text = "⚡", size = UDim2.fromScale(1, 0.7), textSize = 34, stroke = 2 })
	local caption = Ui.text(button, { name = "Caption", text = "SHIDORI", size = UDim2.new(1, 0, 0, 16), position = UDim2.new(0, 0, 1, -22), textSize = 12, stroke = 2 })
	local key = Ui.text(holder, { name = "Key", text = "Z", size = UDim2.fromOffset(24, 24), position = UDim2.fromOffset(-2, -2), textSize = 16, stroke = 2, z = 4 })
	local shade = Ui.frame(button, "Cooldown", UDim2.fromScale(1, 0), UDim2.fromScale(0, 1), Color3.new(0, 0, 0), Vector2.new(0, 1))
	shade.BackgroundTransparency = 0.45
	shade.ZIndex = 3
	Ui.corner(shade, 39)
	local timer = Ui.text(button, { name = "Timer", text = "", size = UDim2.fromScale(1, 1), textSize = 26, stroke = 3, z = 5 })
	button.Activated:Connect(request)

	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	key.Visible = not touch
	RunService.Heartbeat:Connect(function()
		holder.Visible = unlocked()
		if not holder.Visible then
			return
		end
		local left = cooldownLeft()
		local stamina = player:GetAttribute("Stamina")
		local enough = type(stamina) ~= "number" or stamina + 1e-6 >= S.cost
		shade.Size = UDim2.fromScale(1, math.clamp(left / S.cooldown, 0, 1))
		timer.Text = if left > 0.05 then string.format("%.1f", left) else ""
		caption.Visible = left <= 0.05
		border.Color = if left > 0.05 or not enough then Color3.fromRGB(70, 90, 130) else Color3.fromRGB(120, 215, 255)
		button.BackgroundColor3 = if castStart then Color3.fromRGB(60, 120, 220) else Color3.fromRGB(20, 40, 90)
	end)
end

-- Para os testes (TestUi "shidori"): estado e ações simuladas.
function Shidori.test(arg: any): any
	local action = if type(arg) == "table" then arg.action else nil
	if action == "press" then
		request()
		return true
	elseif action == "freeze" then
		-- pose e efeitos parados no tempo arg.t (sem pedir ao servidor); t = nil solta
		frozenT = if type(arg.t) == "number" then arg.t else nil
		if frozenT and not castStart then
			castStart = os.clock() - frozenT
			ShidoriFx.begin(player, frozenT)
			local _, humanoid = character()
			if humanoid then
				humanoid.AutoRotate = false
			end
		end
		ShidoriFx.freeze(player, frozenT)
		return true
	elseif action == "tweak" then
		return ShidoriMoves.tweak(arg.key, arg.fields)
	elseif action == "aim" then
		fixedAim = if typeof(arg.dir) == "Vector3" then Vector3.new(arg.dir.X, 0, arg.dir.Z).Unit else nil
		return true
	end
	local model = player.Character
	local hand = model and model:FindFirstChild("LeftHand")
	local root = model and model:FindFirstChild("HumanoidRootPart")
	return {
		casting = castStart ~= nil,
		t = if castStart then os.clock() - castStart else 0,
		weight = Pose.current("shidori"),
		stats = stats,
		state = player:GetAttribute("ShidoriState"),
		cooldown = cooldownLeft(),
		stamina = player:GetAttribute("Stamina"),
		hand = if hand and root and hand:IsA("BasePart") and root:IsA("BasePart") then root.CFrame:PointToObjectSpace(hand.Position) else nil,
		fx = ShidoriFx.debug(),
		button = Hud.gui():FindFirstChild("Shidori") ~= nil,
		staminaText = Hud.staminaText(),
		anchored = root ~= nil and root:IsA("BasePart") and root.Anchored,
	}
end

function Shidori.start()
	Pose.define("shidori", ShidoriMoves.sample(0), false, 14)
	task.spawn(function()
		local found = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Shidori", 30)
		if found and found:IsA("RemoteEvent") then
			remote = found
			found.OnClientEvent:Connect(function(kind: string, a: any, b: any)
				if kind == "cast" and typeof(a) == "Instance" and a:IsA("Player") and type(b) == "number" then
					begin(a, b)
				elseif kind == "stop" and typeof(a) == "Instance" and a:IsA("Player") then
					stop(a)
				elseif kind == "impact" and typeof(a) == "Instance" and a:IsA("Player") and typeof(b) == "Vector3" then
					stats.impacts += 1
					ShidoriFx.impact(a, b)
				elseif kind == "refused" and type(a) == "string" then
					table.insert(stats.refused, a)
					if a == "stamina" then
						Fx.toast("Not enough stamina!", Color3.fromRGB(120, 160, 220))
					end
				end
			end)
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == S.key or input.KeyCode == S.gamepad then
			request()
		end
	end)
	RunService.RenderStepped:Connect(stepLocal)
	player.CharacterAdded:Connect(function()
		finishLocal()
	end)
	buildButton()
end

return Shidori
