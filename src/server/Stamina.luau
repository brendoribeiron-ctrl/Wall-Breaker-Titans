--!strict
-- Estamina do jogador (Config.Stamina). Fica só no servidor e chega ao cliente pelos atributos
-- "Stamina" e "StaminaMax" (a barra do HUD lê daí). Não é salva: cada vida começa cheia.
-- Gastar é uma conta só, sem pausa no meio (Stamina.spend), então dois pedidos no mesmo quadro
-- não gastam o mesmo saldo duas vezes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local CFG = Config.Stamina

local Stamina = {}

type Entry = { value: number, max: number, lastSpend: number }
local entries: { [Player]: Entry } = {}

local function publish(player: Player, entry: Entry)
	-- uma casa decimal basta para a barra e evita mandar mudança a cada quadro
	player:SetAttribute("Stamina", math.floor(entry.value * 10 + 0.5) / 10)
	player:SetAttribute("StaminaMax", entry.max)
end

local function fill(player: Player)
	local entry = { value = CFG.max, max = CFG.max, lastSpend = -math.huge }
	entries[player] = entry
	publish(player, entry)
end

function Stamina.get(player: Player): number
	local entry = entries[player]
	return if entry then entry.value else 0
end

-- Gasta `amount` se houver; devolve se gastou.
function Stamina.spend(player: Player, amount: number): boolean
	local entry = entries[player]
	if not entry or amount < 0 or entry.value + 1e-6 < amount then
		return false
	end
	entry.value -= amount
	entry.lastSpend = os.clock()
	publish(player, entry)
	return true
end

-- Testes: põe um valor exato.
function Stamina.set(player: Player, value: number)
	local entry = entries[player]
	if entry then
		entry.value = math.clamp(value, 0, entry.max)
		entry.lastSpend = os.clock()
		publish(player, entry)
	end
end

function Stamina.start()
	local function watch(player: Player)
		fill(player)
		player.CharacterAdded:Connect(function()
			fill(player)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		entries[player] = nil
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.1 then
			return
		end
		local step = acc
		acc = 0
		local now = os.clock()
		for player, entry in entries do
			if entry.value < entry.max and now - entry.lastSpend >= CFG.regenDelay then
				entry.value = math.min(entry.max, entry.value + CFG.regenPerSecond * step)
				publish(player, entry)
			end
		end
	end)
end

return Stamina
