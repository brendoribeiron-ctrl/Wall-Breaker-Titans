-- Coleta de dinheiro na placa: terreno normal, skate, tapete e fora do alcance.
--   node tools/bridge.cjs run server src/server/tests/collect_mounted.luau 60000
-- Precisa do cliente rodando (é ele que sobe o boneco com a montaria).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local hook = ServerStorage:WaitForChild("TestHook", 5)
assert(hook, "TestHook ausente")

local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
task.wait(1)

local passed = {}
local function check(name, condition, detail)
	assert(condition, `FALHOU: {name} ({detail})`)
	table.insert(passed, name)
end

local function state()
	return hook:Invoke("state", player)
end

hook:Invoke("runFinish", player)
local plot = workspace.Plots["Plot" .. hook:Invoke("plot", player)]
local pad = plot.Collect :: BasePart
local top = pad.Position.Y + pad.Size.Y / 2

local function lowest(): number
	local low = math.huge
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			low = math.min(low, part.Position.Y - part.Size.Y / 2)
		end
	end
	return low
end

-- Guarda $amount no pedestal, põe o boneco em `offset` (espaço da placa) e espera a coleta.
-- Devolve quanto entrou no dinheiro.
local function attempt(amount: number, offset: Vector3): number
	hook:Invoke("set", player, { money = 0, stored = { ["1"] = amount } })
	character:PivotTo(pad.CFrame * CFrame.new(offset))
	root.AssemblyLinearVelocity = Vector3.zero
	task.wait(1.2)
	return state().money
end

local function mount(id: string?)
	if id then
		hook:Invoke("set", player, { mounts = { [id] = true }, mount = id })
		if player:GetAttribute("Riding") ~= true then
			hook:Invoke("ride", player)
		end
	elseif player:GetAttribute("Riding") == true then
		hook:Invoke("ride", player)
	end
	task.wait(1.5) -- o cliente sobe o HipHeight
end

-- 1. terreno normal
mount(nil)
local normal = attempt(100, Vector3.new(0, 3, 0))
check("terreno normal coleta", normal == 100, tostring(normal))
local normalRoot = (pad.CFrame:PointToObjectSpace(root.Position)).Y
print("terreno: root a", normalRoot, "da placa; pés em", lowest() - top)

-- 2 e 3. skate e tapete: o boneco fica mais alto e os pés não chegam na placa
for _, info in Config.Mounts do
	mount(info.id)
	local got = attempt(100, Vector3.new(0, 3, 0))
	local height = (pad.CFrame:PointToObjectSpace(root.Position)).Y
	local feet = lowest() - top
	print(info.id, "root a", height, "da placa; pés a", feet, "acima do topo")
	check(info.id .. ": boneco ficou mais alto", height > normalRoot + 1, `{height} vs {normalRoot}`)
	check(info.id .. ": coleta em cima", got == 100, tostring(got))
	-- sem pagar duas vezes: fica parado na placa sem nada guardado
	task.wait(0.6)
	check(info.id .. ": parado na placa não paga de novo", state().money == 100, tostring(state().money))
	-- dinheiro novo guardado enquanto está em cima paga uma vez só
	hook:Invoke("set", player, { stored = { ["1"] = 50 } })
	task.wait(1)
	check(info.id .. ": novo guardado paga uma vez", state().money == 150 and state().stored["1"] == 0, tostring(state().money))
end

-- 4. fora da distância (montado e a pé)
for _, id in { "carpet", "hoverboard", false } do
	mount(id or nil)
	local label = id or "a pé"
	check(label .. ": ao lado da placa não coleta", attempt(100, Vector3.new(pad.Size.X / 2 + 4, 3, 0)) == 0, "coletou ao lado")
	check(label .. ": atrás da placa não coleta", attempt(100, Vector3.new(0, 3, pad.Size.Z / 2 + 6)) == 0, "coletou atrás")
	check(label .. ": longe não coleta", attempt(100, Vector3.new(40, 3, 40)) == 0, "coletou longe")
	check(label .. ": guardado intacto fora do alcance", state().stored["1"] == 100, tostring(state().stored["1"]))
end

mount(nil)
hook:Invoke("set", player, { money = 0, stored = {}, mounts = {}, mount = "" })
print(`collect_mounted: {#passed} checagens ok`)
for _, name in passed do
	print("  ok:", name)
end
return #passed
