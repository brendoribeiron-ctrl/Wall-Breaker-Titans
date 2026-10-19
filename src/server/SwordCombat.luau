--!strict
-- Combo M1 da espada do Asta no servidor (o cliente é src/client/SwordCombat.luau; os golpes,
-- src/shared/SwordMoves.luau). O cliente só avisa "comecei o golpe N"; o servidor:
--  * confere se pode (espada na mão, vivo, a pé, ritmo do combo) e decide ele mesmo qual golpe é;
--  * durante a janela de dano do golpe, calcula a cada quadro onde a lâmina está (pose do golpe
--    + rig do boneco + posição do HumanoidRootPart que o servidor conhece) e testa os alvos;
--  * cada alvo leva no máximo um acerto por golpe; o dano é do servidor (Config.Sword.damage).
-- Os outros clientes recebem "swing" para desenhar os efeitos; todos recebem "impact".
--
-- Alvos: lista TARGETS (hoje o golem, via Boss.bladeHit). Inimigos novos entram como mais uma
-- função nela. Golpes especiais futuros podem reaproveitar startSwing com outra lista de golpes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local SwordMoves = require(ReplicatedStorage.Shared.SwordMoves)
local Boss = require(script.Parent.Boss)
local Sword = require(script.Parent.Sword)

local SWORD = Config.Sword
local COMBO = SwordMoves.COMBO

local SwordCombat = {}

type Swing = { id: number, index: number, start: number }
type Target = (player: Player, points: { Vector3 }, multiplier: number) -> (number, Vector3?)

local swings: { [Player]: Swing } = {}
local nextId = 0
local remote: RemoteEvent

-- cada alvo devolve o dano e o ponto atingido (0 se a lâmina não passou nele)
local TARGETS: { [string]: Target } = {
	golem = function(player, points, multiplier)
		return Boss.bladeHit(player, points, multiplier, SWORD.bodyMargin)
	end,
}

-- Para os testes: quantos acertos e quanto dano cada golpe deu.
local log: { { index: number, target: string, damage: number } } = {}

local function canSwing(player: Player): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0 and Sword.isEquipped(player) and player:GetAttribute("Riding") ~= true
end

-- Qual golpe vale agora (nil = cedo demais). Encadeia se estiver dentro da janela do anterior.
local function nextIndex(previous: Swing?, now: number): number?
	if not previous then
		return 1
	end
	local move = COMBO[previous.index]
	local elapsed = now - previous.start
	local tol = SWORD.tolerance
	local chain = move.chain
	if chain and elapsed >= chain[1] - tol and elapsed <= chain[2] + tol then
		return previous.index + 1
	end
	local rest = if chain then move.duration else move.duration + SWORD.finisherRest
	if elapsed >= rest - tol then
		return 1
	end
	return nil
end

-- Pontos da lâmina no mundo para a pose do golpe no tempo t.
local function bladePoints(character: Model, rig: SwordMoves.Rig, move: SwordMoves.Move, t: number, tip: Vector3): { Vector3 }?
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end
	local floor = SwordMoves.floor(character) or -3
	local hold = root.CFrame * SwordMoves.aboveFloor(SwordMoves.hold(rig, SwordMoves.sample(move, t)), tip, floor, SWORD.floorMargin)
	local points = {}
	for _, f in { 0.3, 0.55, 0.8, 1 } do
		table.insert(points, hold * (tip * f))
	end
	return points
end

local function tipOf(character: Model): Vector3?
	local sword = character:FindFirstChild(Sword.NAME)
	return if sword and sword:IsA("Model") then SwordMoves.tip(sword) else nil
end

local function runHits(player: Player, swing: Swing)
	local character = player.Character
	if not character then
		return
	end
	local rig = SwordMoves.rig(character)
	local tip = tipOf(character)
	if not rig or not tip then
		return
	end
	local move = COMBO[swing.index]
	local multiplier = SWORD.damage[swing.index] or 1
	local done: { [string]: boolean } = {}
	while true do
		local current = swings[player]
		if current ~= swing or player.Character ~= character or not canSwing(player) then
			return
		end
		local t = os.clock() - swing.start
		if t > move.hit[2] then
			return
		end
		if t >= move.hit[1] then
			local points = bladePoints(character, rig, move, t, tip)
			if points then
				for name, target in TARGETS do
					if not done[name] then
						local damage, at = target(player, points, multiplier)
						if damage > 0 then
							done[name] = true
							table.insert(log, { index = swing.index, target = name, damage = damage })
							remote:FireAllClients("impact", player, swing.index, at)
						end
					end
				end
			end
		end
		RunService.Heartbeat:Wait()
	end
end

-- Começa um golpe pedido pelo cliente. Devolve o golpe que valeu (nil = recusado).
function SwordCombat.swing(player: Player, wanted: number?): number?
	if not canSwing(player) then
		return nil
	end
	local now = os.clock()
	local index = nextIndex(swings[player], now)
	if not index then
		return nil
	end
	-- o cliente pede o golpe que ele está tocando; se discordar, vale o do servidor
	nextId += 1
	local swing = { id = nextId, index = index, start = now }
	swings[player] = swing
	task.spawn(runHits, player, swing)
	for _, other in Players:GetPlayers() do
		if other ~= player then
			remote:FireClient(other, "swing", player, index)
		end
	end
	return index
end

-- Golpe da espada em andamento (outras habilidades esperam ele acabar).
function SwordCombat.busy(player: Player): boolean
	local swing = swings[player]
	return swing ~= nil and os.clock() - swing.start < COMBO[swing.index].duration
end

function SwordCombat.debug(): { [string]: any }
	return { log = log }
end

function SwordCombat.clearLog()
	table.clear(log)
end

function SwordCombat.reset(player: Player)
	swings[player] = nil
end

function SwordCombat.start()
	-- SwordCombat: C->S ("swing", golpe); S->C ("swing", jogador, golpe) e ("impact", jogador, golpe, ponto)
	remote = Instance.new("RemoteEvent")
	remote.Name = "SwordCombat"
	remote.Parent = ReplicatedStorage:WaitForChild("Remotes")
	remote.OnServerEvent:Connect(function(player, kind, index)
		if kind == "swing" then
			SwordCombat.swing(player, if type(index) == "number" then index else nil)
		end
	end)
	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			swings[player] = nil
		end)
		player:GetAttributeChangedSignal("Sword"):Connect(function()
			swings[player] = nil
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		swings[player] = nil
	end)
end

return SwordCombat
