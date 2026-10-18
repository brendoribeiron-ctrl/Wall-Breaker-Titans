-- Põe os modelos dos efeitos da espada (Shared/SwordVfx.luau) em ReplicatedStorage.SwordVFX, para
-- o dono editar no Studio (Propriedades e Atributos). Rodado no modo de edição:
--   node tools/bridge.cjs run edit tools/vfx/sword_vfx.luau          cria se não existir
--   node tools/bridge.cjs run edit tools/vfx/sword_vfx_reset.luau    refaz com os padrões (APAGA as edições)
-- Depois, SALVAR o place: a pasta vive no place, não no Git (o Rojo não mexe nela).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SwordVfx = require(ReplicatedStorage.Shared.SwordVfx)

local old = ReplicatedStorage:FindFirstChild(SwordVfx.NAME)
if old then
	return "já existe: " .. old:GetFullName() .. " (sword_vfx_reset.luau refaz com os padrões)"
end
local built = SwordVfx.build()
built.Parent = ReplicatedStorage
return "criado: " .. built:GetFullName() .. " (" .. #built:GetDescendants() .. " objetos)"
