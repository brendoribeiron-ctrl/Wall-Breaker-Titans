--!strict
-- Espada de antimagia do Asta no cliente (o servidor é src/server/Sword.luau):
--  * slot 1 da hotbar, à esquerda dos personagens (que passam para 2 a 9, ver Hud): aparece para
--    quem tem a espada (atributo SwordOwned); clique ou tecla 1 pede ao servidor para equipar ou guardar.
--  * pose enquanto a espada está na mão: braço relaxado ao lado do corpo, lâmina saindo do quadril
--    para a frente e um pouco para fora, quase na horizontal. Fica por cima da caminhada e da corrida
--    (camada definida depois de Move) e por baixo da montaria e do soco (definidos depois).
--    A pose replica para os outros pelo espelho de poses de Pose.luau.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Pose = require(script.Parent.Pose)
local Ui = require(script.Parent.Ui)

local NAME = "AntiMagicSword"
local P = Config.Palette
local player = Players.LocalPlayer

-- braço relaxado ao lado do corpo, só um pouco à frente e aberto; a lâmina sai da mão na
-- altura do quadril, quase na horizontal (pedido do dono, com imagem de referência)
local HOLD = {
	RightShoulder = Pose.deg(10, 0, 6),
	RightElbow = Pose.deg(14, 0, 0),
	RightWrist = Pose.deg(0, 0, 0),
}

local Sword = {}

local function startPose()
	Pose.define("sword", HOLD, false, 12)
	local function watch(character: Model)
		local function refresh()
			Pose.weight("sword", if character:FindFirstChild(NAME) then 1 else 0)
		end
		character.ChildAdded:Connect(refresh)
		character.ChildRemoved:Connect(refresh)
		refresh()
	end
	player.CharacterAdded:Connect(watch)
	if player.Character then
		watch(player.Character)
	end
end

-- Ícone do slot: a cópia do modelo que o servidor põe em PlayerGui (só para quem tem a espada),
-- deitada na diagonal.
local function renderIcon(viewport: ViewportFrame, source: Model)
	viewport:ClearAllChildren()
	local model = source:Clone()
	model:PivotTo(CFrame.Angles(0, 0, math.rad(-45)))
	model.Parent = viewport
	local center, size = model:GetBoundingBox()
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	local distance = math.max(size.X, size.Y) / (2 * math.tan(math.rad(15))) * 1.05
	camera.CFrame = CFrame.lookAt(center.Position + Vector3.new(0, 0, distance), center.Position)
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	viewport.LightDirection = Vector3.new(0.4, -1, -0.8)
	viewport.Ambient = Color3.fromRGB(190, 190, 205)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
end

local function startSlot()
	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SwordToggle", 30) :: RemoteEvent?
	local gui = player:WaitForChild("PlayerGui")
	-- a hotbar é montada pelo Hud; o slot entra no mesmo bloco, antes do primeiro
	local hotbar: GuiObject? = nil
	for _ = 1, 60 do
		local found = gui:FindFirstChild("Hotbar", true)
		if found and found:IsA("GuiObject") then
			hotbar = found
			break
		end
		task.wait(0.5)
	end
	if not remote or not hotbar then
		return
	end
	local size, gap = 64, 6
	local frame = Ui.frame(hotbar, "SwordSlot", UDim2.fromOffset(size, size), UDim2.fromOffset(gap / 2 - (size + gap), 64), Color3.fromRGB(40, 16, 52))
	frame.BackgroundTransparency = 0.05
	frame.Visible = false
	Ui.corner(frame, 10)
	local border = Ui.border(frame, 3)
	local scale = Instance.new("UIScale")
	scale.Parent = frame
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Model"
	viewport.BackgroundTransparency = 1
	viewport.Size = UDim2.fromScale(1, 0.82)
	viewport.Parent = frame
	Ui.text(frame, { name = "Number", text = "1", size = UDim2.fromOffset(16, 16), position = UDim2.fromOffset(4, 2), textSize = 14, stroke = 2, z = 3 })
	local label = Ui.text(frame, { name = "Name", text = "SWORD", size = UDim2.new(1, -4, 0, 20), position = UDim2.new(0, 2, 1, -21), stroke = 2, z = 3 })
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 12
	limit.Parent = label
	local hit = Ui.hit(frame, "Hit")
	Ui.juice(hit, frame)
	hit.Activated:Connect(function()
		remote:FireServer()
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.One and frame.Visible then
			remote:FireServer()
		end
	end)

	local function refresh()
		local owned = player:GetAttribute("SwordOwned") == true
		frame.Visible = owned
		local holder = gui:FindFirstChild("SwordIcon")
		local icon = holder and holder:FindFirstChildWhichIsA("Model")
		if owned and icon and #viewport:GetChildren() == 0 then
			renderIcon(viewport, icon)
		elseif not owned then
			viewport:ClearAllChildren()
		end
		local active = owned and player:GetAttribute("Sword") == true
		border.Color = if active then Ui.white else P.outline
		border.Thickness = if active then 4 else 3
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = if active then 1.12 else 1 }):Play()
	end
	player:GetAttributeChangedSignal("SwordOwned"):Connect(refresh)
	player:GetAttributeChangedSignal("Sword"):Connect(refresh)
	gui.ChildAdded:Connect(function(child)
		if child.Name == "SwordIcon" then
			child:WaitForChild(NAME, 5) -- o modelo chega junto do ScreenGui que o leva
			viewport:ClearAllChildren()
			refresh()
		end
	end)
	refresh()
end

function Sword.start()
	startPose()
	task.spawn(startSlot)
end

return Sword
