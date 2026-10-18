-- Boneco de trabalho para animar os golpes da espada no Eclipse Animator, sem precisar de Play:
-- clona o Workspace.AnimRigs.RestRig (R15 com AnimationConstraint, ancorado) para
-- Workspace.AnimRigs.SwordRig e prende nele a espada do Asta, do mesmo jeito que o /sword faz
-- (src/server/Sword.luau: mesmo modelo, mesma escala Config.Sword.size, mesma pegada na mão direita).
-- Rodado no modo de edição:
--   node tools/bridge.cjs run edit tools/anim/sword_rig.luau
-- Roda de novo para refazer (apaga o SwordRig antigo: o KeyframeSequence salvo nele vai junto, então
-- exporte antes). O servidor apaga workspace.AnimRigs ao iniciar o Play; o place do Studio precisa
-- ser salvo para o boneco ficar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local Textures = require(ReplicatedStorage.Shared.Textures)
local Models = require(ServerScriptService.Server.Models)

local STYLE = {
	Blade = { color = Color3.fromRGB(42, 46, 58), material = Enum.Material.SmoothPlastic },
	Guard = { color = Color3.fromRGB(74, 66, 50), material = Enum.Material.Metal },
	Grip = { color = Color3.fromRGB(46, 30, 22), material = Enum.Material.Leather },
}

-- Mesma pegada de Sword.luau (GRIP_R15)
local function holdFrame(offset: Vector3, dir: Vector3, up: Vector3): CFrame
	local y = dir.Unit
	local z = y:Cross(up).Unit
	return CFrame.fromMatrix(offset, y:Cross(z), y, z)
end
local GRIP_R15 = holdFrame(Vector3.new(0, -0.1, 0), Vector3.new(0.38, -0.455, -0.805), Vector3.new(0, 0.927, -0.375))

local rigs = workspace:FindFirstChild("AnimRigs")
local source = rigs and rigs:FindFirstChild("RestRig")
if not rigs or not source then
	error("Workspace.AnimRigs.RestRig não existe neste place")
end

local old = rigs:FindFirstChild("SwordRig")
if old then
	old:Destroy()
end
local rig = source:Clone()
rig.Name = "SwordRig"
-- ao lado do RestRig, para os dois não se sobreporem
rig:PivotTo(source:GetPivot() * CFrame.new(8, 0, 0))
rig.Parent = rigs

-- limpa animações antigas copiadas do RestRig
local saves = rig:FindFirstChild("AnimSaves")
if saves then
	saves:ClearAllChildren()
end

local model = Models.load("asta_sword", STYLE)
if not model then
	error("modelo da espada não carregou (InsertService:LoadAsset)")
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
	part.Locked = false -- travada, o clique no Studio não seleciona a espada
	if kind == "Grip" then
		grip = part
	elseif kind == "Blade" then
		blade = part
	end
end
if not grip or not blade or not marks.Tip or not marks.Base then
	error("modelo da espada veio sem cabo, lâmina ou marcadores")
end
if blade:IsA("MeshPart") then
	blade.TextureID = Textures.asta_blade or ""
end
grip.Name = "Handle"
model.PrimaryPart = grip
for _, part in model:GetDescendants() do
	if part:IsA("BasePart") and part ~= grip then
		local weld = Instance.new("Weld")
		weld.Part0 = grip
		weld.Part1 = part
		weld.C0 = grip.CFrame:ToObjectSpace(part.CFrame)
		weld.Parent = part
	end
end
local hold = Instance.new("Attachment")
hold.Name = "Hold"
hold.CFrame = grip.CFrame:ToObjectSpace(pivot)
hold.Parent = grip
model.Name = "AntiMagicSword"
model:ScaleTo(Config.Sword.size)

local hand = rig:FindFirstChild("RightHand") :: BasePart
local handle = model.PrimaryPart :: BasePart
local hook = handle:FindFirstChild("Hold") :: Attachment
handle.CFrame = hand.CFrame * GRIP_R15 * hook.CFrame:Inverse()
-- Motor6D (não Weld): o animador mostra como junta e dá para mexer a espada na mão
local weld = Instance.new("Motor6D")
weld.Name = "SwordGrip"
weld.Part0 = hand
weld.Part1 = handle
weld.C0 = GRIP_R15
weld.C1 = hook.CFrame
weld.Parent = handle
model.Parent = rig

return "SwordRig pronto em " .. rig:GetFullName()
