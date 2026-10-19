-- Refaz ReplicatedStorage.SwordVFX com os padrões de Shared/SwordVfx.luau. APAGA as edições feitas
-- no Studio. Modo de edição: node tools/bridge.cjs run edit tools/vfx/sword_vfx_reset.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SwordVfx = require(ReplicatedStorage.Shared.SwordVfx)

local old = ReplicatedStorage:FindFirstChild(SwordVfx.NAME)
if old then
	old:Destroy()
end
local built = SwordVfx.build()
built.Parent = ReplicatedStorage
return "refeito: " .. built:GetFullName() .. " (" .. #built:GetDescendants() .. " objetos)"
