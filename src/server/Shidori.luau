--!strict
-- Shidori no servidor (cliente: src/client/Shidori.luau e ShidoriFx.luau; números em
-- Config.Shidori). O cliente só pede "cast"; o servidor:
--  * confere desbloqueio (nó da árvore), vida, montaria, golpe de espada e o estado da habilidade;
--  * gasta a estamina (Stamina.spend, uma vez) e começa a recarga no mesmo instante;
--  * avisa todos os clientes ("cast", jogador, hora do servidor) para a pose e os efeitos;
--  * na janela de dano calcula onde a palma está (HumanoidRootPart que o servidor conhece +
--    ShidoriMoves.palm) e testa os alvos; cada alvo leva no máximo um acerto por ativação, com
--    o dano do soco M1 × Config.Shidori.damage (Boss.handHit → deal()).
--
-- Máquina de estados (atributo "ShidoriState" no jogador, para o HUD e os testes):
--   Ready → Activating (preparo e acúmulo) → Active (explosão e investida) → Recovering → Cooldown
--   → Ready. "ShidoriReady" = hora do servidor (workspace:GetServerTimeNow) em que libera.
-- Morte, troca de boneco ou montar no meio: corta para Cooldown (a estamina já foi gasta) e manda
-- "stop" aos clientes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local ShidoriMoves = require(ReplicatedStorage.Shared.ShidoriMoves)
local Boss = require(script.Parent.Boss)
local PlayerData = require(script.Parent.PlayerData)
local Stamina = require(script.Parent.Stamina)
local SwordCombat = require(script.Parent.SwordCombat)

local S = Config.Shidori

local Shidori = {}

type Cast = { id: number, start: number, character: Model }
type Target = (player: Player, point: Vector3) -> (number, Vector3?)

local casts: { [Player]: Cast } = {}
local readyAt: { [Player]: number } = {}
local nextId = 0
local remote: RemoteEvent

local TARGETS: { [string]: Target } = {
	golem = function(player, point)
		return Boss.handHit(player, point, S.damage, S.reach)
	end,
}

-- testes: cada acerto (alvo e dano) e cada pedido recusado (motivo)
local log: { { kind: string, target: string?, damage: number?, reason: string? } } = {}

local function setState(player: Player, state: string)
	player:SetAttribute("ShidoriState", state)
end

local function unlocked(player: Player): boolean
	local profile = PlayerData.get(player)
	return profile ~= nil and (profile.stats.shidori or 0) >= 1
end

-- Motivo para recusar (nil = pode).
local function refusal(player: Player): string?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return "dead"
	elseif not unlocked(player) then
		return "locked"
	elseif casts[player] then
		return "busy"
	elseif os.clock() < (readyAt[player] or 0) then
		return "cooldown"
	elseif player:GetAttribute("Riding") == true then
		return "riding"
	elseif SwordCombat.busy(player) then
		return "sword"
	elseif Stamina.get(player) + 1e-6 < S.cost then
		return "stamina"
	end
	return nil
end

local function finish(player: Player, cast: Cast, interrupted: boolean)
	if casts[player] ~= cast then
		return
	end
	casts[player] = nil
	if interrupted then
		remote:FireAllClients("stop", player)
	end
	local left = (readyAt[player] or 0) - os.clock()
	if left > 0 then
		setState(player, "Cooldown")
		task.delay(left, function()
			if not casts[player] and os.clock() >= (readyAt[player] or 0) and player.Parent then
				setState(player, "Ready")
			end
		end)
	else
		setState(player, "Ready")
	end
end

local function alive(player: Player, cast: Cast): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return casts[player] == cast and character == cast.character and humanoid ~= nil and humanoid.Health > 0 and player:GetAttribute("Riding") ~= true
end

local function run(player: Player, cast: Cast)
	local done: { [string]: boolean } = {}
	local character = cast.character
	local root = character:FindFirstChild("HumanoidRootPart")
	local scale = if root and root:IsA("BasePart") then root.Size.Y / 2 else 1
	local phase = "Activating"
	while true do
		if not alive(player, cast) then
			finish(player, cast, true)
			return
		end
		local t = os.clock() - cast.start
		local want = if t < S.charge then "Activating" elseif t < S.hit[2] then "Active" else "Recovering"
		if want ~= phase then
			phase = want
			setState(player, phase)
		end
		if t >= S.hit[1] and t <= S.hit[2] + S.tolerance and root and root:IsA("BasePart") then
			local point = root.CFrame * ShidoriMoves.palm(scale)
			for name, target in TARGETS do
				if not done[name] then
					local damage, at = target(player, point)
					if damage > 0 then
						done[name] = true
						table.insert(log, { kind = "hit", target = name, damage = damage })
						remote:FireAllClients("impact", player, at or point)
					end
				end
			end
		end
		if t >= math.max(S.recover, S.hit[2] + S.tolerance) then
			finish(player, cast, false)
			return
		end
		RunService.Heartbeat:Wait()
	end
end

-- Pedido de ativação. Devolve se valeu.
function Shidori.cast(player: Player): boolean
	local reason = refusal(player)
	if reason then
		table.insert(log, { kind = "refused", reason = reason })
		if reason == "stamina" or reason == "locked" then
			remote:FireClient(player, "refused", reason)
		end
		return false
	end
	-- a conta da estamina é a última checagem e não pausa: dois pedidos juntos não passam os dois
	if not Stamina.spend(player, S.cost) then
		table.insert(log, { kind = "refused", reason = "stamina" })
		return false
	end
	local now = os.clock()
	nextId += 1
	local cast = { id = nextId, start = now, character = player.Character :: Model }
	casts[player] = cast
	readyAt[player] = now + S.cooldown
	player:SetAttribute("ShidoriReady", workspace:GetServerTimeNow() + S.cooldown)
	setState(player, "Activating")
	table.insert(log, { kind = "cast" })
	remote:FireAllClients("cast", player, workspace:GetServerTimeNow())
	task.spawn(run, player, cast)
	return true
end

function Shidori.debug(player: Player): { [string]: any }
	return {
		log = log,
		state = player:GetAttribute("ShidoriState"),
		cooldownLeft = math.max(0, (readyAt[player] or 0) - os.clock()),
		stamina = Stamina.get(player),
	}
end

function Shidori.clearLog()
	table.clear(log)
end

-- Testes: zera a recarga.
function Shidori.resetCooldown(player: Player)
	readyAt[player] = nil
	player:SetAttribute("ShidoriReady", 0)
	if not casts[player] then
		setState(player, "Ready")
	end
end

function Shidori.start()
	-- Shidori: C->S ("cast"); S->C ("cast", jogador, hora), ("stop", jogador),
	-- ("impact", jogador, ponto) e, só para quem pediu, ("refused", motivo)
	remote = Instance.new("RemoteEvent")
	remote.Name = "Shidori"
	remote.Parent = ReplicatedStorage:WaitForChild("Remotes")
	remote.OnServerEvent:Connect(function(player, kind)
		if kind == "cast" then
			Shidori.cast(player)
		end
	end)
	local function watch(player: Player)
		setState(player, "Ready")
		player:SetAttribute("ShidoriReady", 0)
		player.CharacterAdded:Connect(function()
			local cast = casts[player]
			if cast then
				finish(player, cast, true)
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		casts[player] = nil
		readyAt[player] = nil
	end)
end

return Shidori
