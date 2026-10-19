-- Painel do balcão de poções: abre vindo de vários lados do caldeirão e confere que o painel não
-- fica dentro do balcão, que a câmera vê o painel sem nada no caminho e que, ao fechar, a câmera
-- volta ao normal.
--   node tools/bridge.cjs run server src/server/tests/potion_panel.luau 120000

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local hook = ServerStorage:WaitForChild("TestHook", 5)
local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart") :: BasePart

local function ui(command, arg)
	return hook:Invoke("ui", player, { command = command, arg = arg })
end

local house = workspace:WaitForChild("Sanctum", 20)
assert(house, "sem a casa")
local shop = house:WaitForChild("PotionShop", 10)
local body = house.Colliders.ShopBody :: BasePart
local center = body.Position

local boxes = {}
for _, part in shop:GetDescendants() do
	if part:IsA("BasePart") then
		table.insert(boxes, part)
	end
end

-- o segmento a-b passa pela peça (caixa sem folga)?
local function crosses(a: Vector3, b: Vector3, part: BasePart): boolean
	local p, q = part.CFrame:PointToObjectSpace(a), part.CFrame:PointToObjectSpace(b)
	local from, delta, half = { p.X, p.Y, p.Z }, { q.X - p.X, q.Y - p.Y, q.Z - p.Z }, { part.Size.X / 2, part.Size.Y / 2, part.Size.Z / 2 }
	local t0, t1 = 0, 1
	for axis = 1, 3 do
		local s, d, h = from[axis], delta[axis], half[axis]
		if math.abs(d) < 1e-6 then
			if math.abs(s) > h then
				return false
			end
		else
			local u, v = (-h - s) / d, (h - s) / d
			if u > v then
				u, v = v, u
			end
			t0, t1 = math.max(t0, u), math.min(t1, v)
			if t0 > t1 then
				return false
			end
		end
	end
	return true
end

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { character }

local floorY = center.Y - body.Size.X / 2 -- o cilindro está de pé: eixo X para cima
local tried, passed, turned = 0, 0, 0
local failures = {}
for i = 0, 15 do
	local angle = i * math.pi / 8
	local direction = Vector3.new(math.sin(angle), 0, math.cos(angle))
	local distance = body.Size.Y / 2 + 2.2
	local spot = Vector3.new(center.X, floorY + 3, center.Z) + direction * distance
	-- só lados por onde dá para chegar (sem parede ou estante entre o caldeirão e o lugar)
	local chest = Vector3.new(center.X, floorY + 3, center.Z) + direction * (body.Size.Y / 2 + 0.2)
	if workspace:Raycast(chest, spot + direction * 1.5 - chest, params) then
		continue
	end
	tried += 1
	character:PivotTo(CFrame.lookAt(spot, Vector3.new(center.X, spot.Y, center.Z)))
	root.AssemblyLinearVelocity = Vector3.zero
	task.wait(0.4)
	local before = root.CFrame.LookVector
	assert(ui("potionShop"), `lado {i}: a loja não abriu`)
	task.wait(1)
	local info = ui("panel")
	local panel = CFrame.new(table.unpack(info.panelFrame))
	local eye = CFrame.new(table.unpack(info.cameraFrame)).Position
	local w, h = info.panelSize[1] / 2, info.panelSize[2] / 2
	local points = { panel.Position }
	for _, c in { Vector2.new(-1, -1), Vector2.new(1, -1), Vector2.new(1, 1), Vector2.new(-1, 1) } do
		table.insert(points, panel:PointToWorldSpace(Vector3.new(c.X * w, c.Y * h, 0)))
	end
	local problems = {}
	if not info.inView then
		table.insert(problems, "painel fora da tela")
	end
	if (eye - panel.Position):Dot(panel.LookVector) <= 0 then
		table.insert(problems, "painel de costas para a câmera")
	end
	for n, point in points do
		for _, part in boxes do
			if crosses(eye, point, part) then
				table.insert(problems, `{part.Name} entre a câmera e o ponto {n}`)
				break
			end
			if n > 1 and crosses(point, points[if n == 5 then 2 else n + 1], part) then
				table.insert(problems, `painel atravessa {part.Name}`)
				break
			end
		end
		local hit = workspace:Raycast(eye, point - eye, params)
		if hit then
			table.insert(problems, `{hit.Instance.Name} tapa o ponto {n}`)
		end
	end
	if info.turned then
		turned += 1
	end
	-- fecha: a câmera volta ao controle normal
	ui("toggle", "Potions")
	task.wait(0.8)
	local closed = ui("panel")
	if closed.holding or closed.cameraType ~= "Custom" then
		table.insert(problems, `não fechou direito (holding={closed.holding}, câmera={closed.cameraType})`)
	end
	local after = root.CFrame.LookVector
	if #problems == 0 then
		passed += 1
	else
		table.insert(failures, `lado {i} ({math.deg(angle)}°): {table.concat(problems, "; ")}`)
	end
	print(`[potion_panel] lado {i}: girou {math.floor(math.deg(math.acos(math.clamp(before:Dot(after), -1, 1))))}°, {#problems} problemas`)
end

assert(tried >= 4, `só {tried} lados alcançáveis`)
assert(#failures == 0, table.concat(failures, "\n"))
-- outra janela aberta pelo HUD continua na frente do boneco, sem girar
ui("toggle", "Index")
task.wait(1)
local index = ui("panel")
ui("toggle", "Index")
task.wait(0.8)
assert(not index.turned and index.holding, "janela do HUD girou o boneco")
return `{passed}/{tried} lados OK ({turned} usaram o giro); janela do HUD sem giro; câmera volta a Custom`
