-- /spawn: leva para a sala do chefe e acorda o golem; /spawn <golpe> força o golpe.
--   node tools/bridge.cjs run server src/server/tests/spawn.luau 60000
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Anims = require(ReplicatedStorage.Shared.GolemAnims)
local Experiment = require(ReplicatedStorage.Shared.GolemExperiment)
local hook = game:GetService("ServerStorage"):WaitForChild("TestHook", 5)
local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()

local passed = {}
local function check(name, condition, detail)
	assert(condition, `FALHOU: {name} ({detail})`)
	table.insert(passed, name)
end
local function spawn(text: string): string
	return hook:Invoke("spawnCommand", player, text)
end
local function state(): any
	return hook:Invoke("boss", player, { action = "state" })
end

hook:Invoke("leaveRoom", player)
task.wait(0.3)
check("golpe sem luta pede /spawn antes", string.find(spawn("/spawn slam"), "first") ~= nil, "")
check("golpe inexistente mostra o uso", string.find(spawn("/spawn dragon"), "Usage") ~= nil, "")
local message = spawn("/spawn")
check("/spawn leva para a sala", player:GetAttribute("RoomKey") ~= nil and player:GetAttribute("Room") ~= nil, message)
check("sem direito ao sorteio", player:GetAttribute("BossReward") ~= true, "")
task.wait(1)
check("o golem acorda", state().state == "wake", tostring(state().state))
check("de novo avisa que já está de pé", string.find(spawn("/spaw"), "already") ~= nil, "")
task.wait(Anims.clips.Wake.length + 0.3)
hook:Invoke("boss", player, { action = "rest", arg = 30 })
check("força o golpe", spawn("/spawn Charge") == "BOSS: CHARGE!", "")
task.wait(0.1)
check("toca o clip do golpe", state().clip == Experiment.clipFor("Charge"), tostring(state().clip))

hook:Invoke("boss", player, { action = "reset" })
hook:Invoke("leaveRoom", player)
return `{#passed} ok: ` .. table.concat(passed, " | ")
