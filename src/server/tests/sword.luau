-- /sword: espada de antimagia do Asta, só para dev (src/server/Sword.luau). /sword põe no
-- inventário (slot 9 da hotbar), o slot equipa e guarda, /sword off tira do inventário.
--   node tools/bridge.cjs run server src/server/tests/sword.luau 60000
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local hook = game:GetService("ServerStorage"):WaitForChild("TestHook", 5)
local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
local NAME = "AntiMagicSword"

local passed = {}
local function check(name, condition, detail)
	assert(condition, `FALHOU: {name} ({detail})`)
	table.insert(passed, name)
end
local function sword(text: string, admin: boolean?): any
	return hook:Invoke("sword", player, { text = text, admin = admin })
end
local function held(): Model?
	local character = player.Character
	return character and character:FindFirstChild(NAME) :: Model?
end
local function icon(): Instance?
	return player.PlayerGui:FindFirstChild("SwordIcon")
end

local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart") :: BasePart
local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
sword("/sword off")
local massBefore = root.AssemblyMass

-- quem não é dev: nada acontece, nem aviso; o slot não equipa sem ter a espada
check("não-dev não recebe nada", sword("/sword", false) == nil and player:GetAttribute("SwordOwned") == nil and icon() == nil, "")
check("slot sem a espada não equipa", sword("toggle") == false and held() == nil, "")
check("modelo fora do ReplicatedStorage", ReplicatedStorage:FindFirstChild(NAME, true) == nil, "")
check("remote do slot existe", ReplicatedStorage.Remotes:FindFirstChild("SwordToggle") ~= nil, "")

-- dev: vai para o inventário, não para a mão
local message = sword("/sword")
check("dev recebe no inventário", player:GetAttribute("SwordOwned") == true and string.find(message or "", "inventory") ~= nil, tostring(message))
check("ícone só no PlayerGui do dono", icon() ~= nil, "")
check("não vai direto para a mão", held() == nil, "")
check("de novo avisa que já tem", string.find(sword("/sword") or "", "already") ~= nil, "")

-- slot: equipa
check("slot equipa", sword("toggle") == true and held() ~= nil and player:GetAttribute("Sword") == true, "")
local m = held() :: Model
local handle = m.PrimaryPart :: BasePart
local weld = handle:FindFirstChild("SwordGrip") :: Weld
check("soldada na mão direita", weld ~= nil and weld.Part0 == character:FindFirstChild("RightHand"), "")
local loose = 0
for _, part in m:GetDescendants() do
	if part:IsA("BasePart") and (part.Anchored or part.CanCollide or part.CanTouch or part.CanQuery or not part.Massless) then
		loose += 1
	end
end
check("sem física nas peças", loose == 0, `{loose} peças`)
task.wait(0.5)
check("não pesa no boneco", math.abs(root.AssemblyMass - massBefore) < 0.01, `{massBefore} -> {root.AssemblyMass}`)
local blade = m:FindFirstChild("Blade_asta_sword", true) :: MeshPart
check("lâmina com textura", blade ~= nil and blade.TextureID ~= "", "")
local tip = blade and blade:FindFirstChild("BladeTip") :: Attachment
check("pontos para VFX", tip ~= nil and blade:FindFirstChild("BladeBase") ~= nil and blade:FindFirstChild("BladeMid") ~= nil, "")
local length = (tip.WorldPosition - handle.Position).Magnitude
local size = require(ReplicatedStorage.Shared.Config).Sword.size
check("tamanho de espadão", length > 3.5 * size and length < 6 * size, string.format("%.2f", length))
check("a velocidade não muda", humanoid.WalkSpeed > 0, "")

-- volta à mão depois de morrer
player:LoadCharacter()
character = player.Character or player.CharacterAdded:Wait()
character:WaitForChild("RightHand", 5)
task.wait(1)
check("volta depois de renascer", held() ~= nil and icon() ~= nil, "")

-- slot de novo guarda (continua no inventário)
check("slot guarda", sword("toggle") == true and held() == nil and player:GetAttribute("SwordOwned") == true, "")
-- /sword off tira do inventário e da mão
sword("toggle")
sword("/sword off")
check("/sword off tira tudo", held() == nil and player:GetAttribute("SwordOwned") == nil and icon() == nil, "")

return `{#passed} ok: ` .. table.concat(passed, " | ") .. string.format(" | comprimento %.2f", length)
