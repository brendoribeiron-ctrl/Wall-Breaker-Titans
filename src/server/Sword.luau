--!strict
-- Espada de antimagia do Asta (a Exterminadora de Demônios), modelada em
-- tools/blender/asta_sword.py. Só dev: /sword põe a espada no inventário (slot 1 da hotbar,
-- src/client/Sword.luau) e /sword off tira. O slot equipa e guarda pelo remote SwordToggle,
-- que só funciona para quem tem a espada (atributo SwordOwned, escrito só aqui). O único jeito
-- de ganhar a espada é o comando, conferido no servidor pelo UserId (Admin.isAdmin); não existe
-- em loja nem sorteio. Fica só nesta sessão (não vai para o perfil) e volta à mão depois de morrer.
--
-- Golpes (combo M1): src/server/SwordCombat.luau. A lâmina traz os Attachments "BladeBase",
-- "BladeMid" e "BladeTip" (rastro, brilho, ponto de impacto).
-- A pose de segurar é do cliente (src/client/Sword.luau), que olha o filho NAME do boneco.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TextChatService = game:GetService("TextChatService")

local Config = require(ReplicatedStorage.Shared.Config)
local Models = require(script.Parent.Models)
local Textures = require(ReplicatedStorage.Shared.Textures)

local Sword = {}

Sword.NAME = "AntiMagicSword"

-- O nome de cada peça começa pelo tipo ("Blade_asta_sword").
local STYLE: { [string]: Models.Style } = {
	-- a cor vem da textura asta_blade; Metal com textura escura vira uma barra preta
	Blade = { color = Color3.fromRGB(42, 46, 58), material = Enum.Material.SmoothPlastic },
	Guard = { color = Color3.fromRGB(74, 66, 50), material = Enum.Material.Metal },
	Grip = { color = Color3.fromRGB(46, 30, 22), material = Enum.Material.Leather },
}

-- Onde fica o ponto de pegada do modelo (a origem, logo abaixo da guarda), em relação à mão.
-- No modelo: +Y = ponta, +X = largura, Z = espessura. Pose de guarda (ver Sword do cliente):
-- braço à frente, lâmina apontando para a frente e um pouco para cima, como espada (não faca).
-- dir = para onde a ponta aponta, up = onde fica o "cima" do mundo, os dois no espaço da mão
-- já na pose de guarda. A face larga fica de lado e o gume para baixo.
local function holdFrame(offset: Vector3, dir: Vector3, up: Vector3): CFrame
	local y = dir.Unit
	local z = y:Cross(up).Unit
	return CFrame.fromMatrix(offset, y:Cross(z), y, z)
end
-- Pose HOLD do cliente: braço relaxado (mão ~22° para a frente). Lâmina saindo do quadril para a
-- frente e um pouco para fora, quase na horizontal (referência do dono). Se a pose do cliente
-- mudar, medir de novo (mão em relação ao HumanoidRootPart).
local GRIP_R15 = holdFrame(Vector3.new(0, -0.1, 0), Vector3.new(0.38, -0.455, -0.805), Vector3.new(0, 0.927, -0.375))
-- R6 não tem a pose (braço caído): lâmina para a frente e para cima a partir da mão
local GRIP_R6 = holdFrame(Vector3.new(0, -0.9, 0), Vector3.new(0, 0.57, -0.82), Vector3.yAxis)

local template: Model? = nil

-- Carrega e prepara o modelo uma vez: peças soltas (não ancoradas, sem massa, sem colisão)
-- presas no cabo, marcadores da lâmina viram Attachments.
local function build(): Model?
	local model = Models.load("asta_sword", STYLE)
	if not model then
		return nil
	end
	local pivot = model:GetPivot()
	local grip: BasePart? = nil
	local blade: BasePart? = nil
	local marks: { [string]: Vector3 } = {}
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end
		local kind = string.match(part.Name, "^(%a+)_") or ""
		if kind == "Tip" or kind == "Base" then
			marks[kind] = part.Position
			part:Destroy()
			continue
		end
		part.Anchored = false
		part.Massless = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = true
		if kind == "Grip" then
			grip = part
		elseif kind == "Blade" then
			blade = part
		end
	end
	if not grip or not blade or not marks.Tip or not marks.Base then
		warn("[Sword] modelo veio sem cabo, lâmina ou marcadores")
		model:Destroy()
		return nil
	end
	if blade:IsA("MeshPart") then
		blade.TextureID = Textures.asta_blade or ""
	end
	grip.Name = "Handle"
	model.PrimaryPart = grip
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part ~= grip then
			-- Weld com C0 fixo: WeldConstraint recaptura a distância quando o cabo é movido
			-- fora do Workspace, e a lâmina ficava para trás
			local weld = Instance.new("Weld")
			weld.Part0 = grip
			weld.Part1 = part
			weld.C0 = grip.CFrame:ToObjectSpace(part.CFrame)
			weld.Parent = part
		end
	end
	-- pontos da lâmina para os VFX futuros (orientados como o modelo: +Y = ponta)
	local rotation = pivot.Rotation
	for name, position in { BladeBase = marks.Base, BladeMid = marks.Base:Lerp(marks.Tip, 0.55), BladeTip = marks.Tip } do
		local attachment = Instance.new("Attachment")
		attachment.Name = name
		attachment.CFrame = blade.CFrame:ToObjectSpace(CFrame.new(position) * rotation)
		attachment.Parent = blade
	end
	-- ponto de pegada guardado no cabo: é por ele que a solda acha a mão
	local hold = Instance.new("Attachment")
	hold.Name = "Hold"
	hold.CFrame = grip.CFrame:ToObjectSpace(pivot)
	hold.Parent = grip
	model.Name = Sword.NAME
	return model
end

local function getTemplate(): Model?
	if not template then
		template = build()
		if template then
			template.Parent = ServerStorage
		end
	end
	return template
end

function Sword.isEquipped(player: Player): boolean
	local character = player.Character
	return character ~= nil and character:FindFirstChild(Sword.NAME) ~= nil
end

local function attach(character: Model): boolean
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	local base = getTemplate()
	if not humanoid or not hand or not hand:IsA("BasePart") or not base then
		return false
	end
	local old = character:FindFirstChild(Sword.NAME)
	if old then
		old:Destroy()
	end
	local sword = base:Clone()
	-- avatar maior ou menor: a espada acompanha a altura do corpo
	local height = humanoid:FindFirstChild("BodyHeightScale")
	local body = if height and height:IsA("NumberValue") and humanoid.RigType == Enum.HumanoidRigType.R15 then height.Value else 1
	local scale = body * Config.Sword.size -- Config.Sword.size: espada maior que o modelo
	if math.abs(scale - 1) > 0.01 then
		sword:ScaleTo(scale)
	end
	local handle = sword.PrimaryPart :: BasePart
	local hold = handle:FindFirstChild("Hold") :: Attachment
	local grip = if hand.Name == "RightHand" then GRIP_R15 else GRIP_R6
	handle.CFrame = hand.CFrame * grip * hold.CFrame:Inverse()
	local weld = Instance.new("Weld")
	weld.Name = "SwordGrip"
	weld.Part0 = hand
	weld.Part1 = handle
	weld.C0 = grip
	weld.C1 = hold.CFrame
	weld.Parent = handle
	sword.Parent = character
	return true
end

-- Inventário: quem tem a espada (atributo SwordOwned, só o servidor escreve) vê o slot dela na
-- hotbar e recebe uma cópia do modelo em PlayerGui para o ícone (PlayerGui só replica para o dono).
local function setIcon(player: Player, on: boolean)
	local gui = player:FindFirstChildOfClass("PlayerGui")
	if not gui then
		return
	end
	local old = gui:FindFirstChild("SwordIcon")
	if old then
		old:Destroy()
	end
	local base = on and getTemplate()
	if base then
		-- dentro de um ScreenGui que não reinicia: solto no PlayerGui ele some ao renascer
		local holder = Instance.new("ScreenGui")
		holder.Name = "SwordIcon"
		holder.Enabled = false
		holder.ResetOnSpawn = false
		base:Clone().Parent = holder
		holder.Parent = gui
	end
end

function Sword.owns(player: Player): boolean
	return player:GetAttribute("SwordOwned") == true
end

function Sword.equip(player: Player): boolean
	local character = player.Character
	if not Sword.owns(player) or not character or not attach(character) then
		return false
	end
	player:SetAttribute("Sword", true)
	return true
end

function Sword.unequip(player: Player)
	player:SetAttribute("Sword", nil)
	local character = player.Character
	local sword = character and character:FindFirstChild(Sword.NAME)
	if sword then
		sword:Destroy()
	end
end

function Sword.give(player: Player): boolean
	if not getTemplate() then
		return false
	end
	player:SetAttribute("SwordOwned", true)
	setIcon(player, true)
	return true
end

function Sword.take(player: Player)
	Sword.unequip(player)
	player:SetAttribute("SwordOwned", nil)
	setIcon(player, false)
end

-- Pedido do slot da hotbar: equipa ou guarda. Só vale para quem tem a espada no inventário
-- (que só um dev dá); para os outros o pedido não faz nada.
function Sword.toggle(player: Player): boolean
	if not Sword.owns(player) then
		return false
	end
	if Sword.isEquipped(player) then
		Sword.unequip(player)
		return true
	end
	return Sword.equip(player)
end

-- O comando /sword. admin = resultado do Admin.isAdmin, conferido por quem chama (nunca vem
-- do cliente). Devolve o aviso para o jogador, ou nil para quem não é dev (nada acontece).
--   /sword       põe a espada no inventário (slot 1 da hotbar)
--   /sword off   tira do inventário (e da mão)
function Sword.command(player: Player, text: string, admin: boolean): string?
	if not admin then
		return nil
	end
	if string.lower(string.match(text, "^%S+%s+(%a+)") or "") == "off" then
		Sword.take(player)
		return "Anti-magic sword removed from your inventory."
	end
	if Sword.owns(player) then
		return "The sword is already in your inventory: press 1 or click its slot. /sword off removes it."
	end
	if Sword.give(player) then
		return "ANTI-MAGIC SWORD added to your inventory! Press 1 or click its slot to equip."
	end
	return "The sword could not load. Try again in a moment."
end

-- isAdmin: quem pode usar o comando (Admin.isAdmin). toast: aviso na tela de quem digitou.
function Sword.start(isAdmin: (Player) -> boolean, toast: (Player, string) -> ())
	task.spawn(getTemplate) -- baixa o modelo já na abertura do servidor

	local function watch(player: Player)
		player.CharacterAdded:Connect(function(character)
			if player:GetAttribute("Sword") ~= true or not Sword.owns(player) then
				return
			end
			-- só põe na mão depois que o corpo (e a mão direita) chegou
			character:WaitForChild("RightHand", 5)
			if player:GetAttribute("Sword") == true and character.Parent then
				attach(character)
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end

	-- SwordToggle: C->S clique no slot da espada (ou tecla 1). Sem argumentos.
	local remote = Instance.new("RemoteEvent")
	remote.Name = "SwordToggle"
	remote.Parent = ReplicatedStorage:WaitForChild("Remotes")
	local last: { [Player]: number } = {}
	remote.OnServerEvent:Connect(function(player)
		local now = os.clock()
		if now - (last[player] or 0) < 0.25 then
			return
		end
		last[player] = now
		Sword.toggle(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		last[player] = nil
	end)

	local command = Instance.new("TextChatCommand")
	command.Name = "Sword"
	command.PrimaryAlias = "/sword"
	command.AutocompleteVisible = false
	command.Triggered:Connect(function(source, text)
		local player = Players:GetPlayerByUserId(source.UserId)
		if not player then
			return
		end
		local message = Sword.command(player, text, isAdmin(player))
		if message then
			toast(player, message) -- quem não é dev não recebe nada (nem aviso de que o comando existe)
		end
	end)
	command.Parent = TextChatService
end

return Sword
