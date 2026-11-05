local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local FLOOR_Y = 10
local COURSE_FOLDER_NAME = "OrbitalRunCourse"
local REMOTE_NAME = "OrbitalRunStatus"

local courseFolder = Workspace:FindFirstChild(COURSE_FOLDER_NAME)
if courseFolder then
	courseFolder:Destroy()
end
courseFolder = Instance.new("Folder")
courseFolder.Name = COURSE_FOLDER_NAME
courseFolder.Parent = Workspace

local statusRemote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if not statusRemote then
	statusRemote = Instance.new("RemoteEvent")
	statusRemote.Name = REMOTE_NAME
	statusRemote.Parent = ReplicatedStorage
end

local colors = {
	deck = Color3.fromRGB(28, 43, 67),
	trim = Color3.fromRGB(62, 96, 130),
	checkpoint = Color3.fromRGB(49, 224, 219),
	hazard = Color3.fromRGB(255, 66, 83),
	gold = Color3.fromRGB(255, 198, 71),
}

local function makePart(name, size, position, color, material, canCollide, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.Metal
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = canCollide ~= false
	part.Parent = parent or courseFolder
	return part
end

local function makePlatform(name, x, z, sizeX, sizeZ, y)
	local platform = makePart(
		name,
		Vector3.new(sizeX, 2, sizeZ),
		Vector3.new(x, y or FLOOR_Y, z or 0),
		colors.deck,
		Enum.Material.Metal
	)
	local trim = makePart(
		name .. " Trim",
		Vector3.new(sizeX, 0.35, 0.35),
		Vector3.new(x, (y or FLOOR_Y) + 1.15, (z or 0) - sizeZ / 2 + 0.5),
		colors.trim,
		Enum.Material.Neon,
		false
	)
	trim.CanTouch = false
	return platform
end

local function makeCheckpoint(index, name, x)
	local platform = makePlatform(name .. " Platform", x, 0, 20, 20)
	local pad = makePart(
		name,
		Vector3.new(8, 0.35, 8),
		Vector3.new(x, FLOOR_Y + 1.18, 0),
		colors.checkpoint,
		Enum.Material.Neon,
		false
	)
	pad:SetAttribute("CheckpointIndex", index)
	return platform, pad
end

local spawn = Instance.new("SpawnLocation")
spawn.Name = "Orbital Run Start"
spawn.Size = Vector3.new(52, 2, 28)
spawn.Position = Vector3.new(0, FLOOR_Y, 0)
spawn.Anchored = true
spawn.Neutral = true
spawn.AllowTeamChangeOnTouch = false
spawn.Duration = 0
spawn.Material = Enum.Material.Metal
spawn.Color = colors.deck
spawn.Parent = courseFolder

for index, x in ipairs({ 38, 49, 60, 71, 82 }) do
	local z = if index % 2 == 0 then 5 else -5
	makePlatform("Launch Step " .. index, x, z, 9, 9)
end

makeCheckpoint(1, "Checkpoint 1 - Airlock", 98)

makePlatform("Crossing Approach", 119, 0, 30, 18)
makePlatform("Sweep Hazard Deck", 154, 0, 30, 18)
local sweep = makePart(
	"Red Sweep Hazard",
	Vector3.new(3, 2.5, 6),
	Vector3.new(154, FLOOR_Y + 2.25, -6),
	colors.hazard,
	Enum.Material.Neon,
	false
)
makePlatform("Crossing Exit", 181, 0, 28, 18)
makeCheckpoint(2, "Checkpoint 2 - Reactor", 210)

local beamZ = { -4, 4, -4, 4, -4, 4 }
local beamX = { 231, 249, 267, 285, 303, 321 }
for index, x in ipairs(beamX) do
	makePlatform("Balance Beam " .. index, x, beamZ[index], 20, 4)
end
makeCheckpoint(3, "Checkpoint 3 - Comms", 342)

makePlatform("Platform Bay Entry", 360, 0, 28, 20)
for index, x in ipairs({ 383, 407, 431, 455 }) do
	local platform = makePlatform("Drifting Platform " .. index, x, 0, 15, 13)
	local offset = if index % 2 == 0 then -5 else 5
	local tween = TweenService:Create(
		platform,
		TweenInfo.new(2.4 + index * 0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Position = platform.Position + Vector3.new(0, 0, offset) }
	)
	tween:Play()
end
makeCheckpoint(4, "Checkpoint 4 - Docking Ring", 475)

makePlatform("Laser Corridor", 500, 0, 48, 22)
local laser = makePart(
	"Moving Laser",
	Vector3.new(3, 2.5, 7),
	Vector3.new(490, FLOOR_Y + 2.2, -7),
	colors.hazard,
	Enum.Material.Neon,
	false
)
local laserTween = TweenService:Create(
	laser,
	TweenInfo.new(1.7, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true),
	{ Position = Vector3.new(510, FLOOR_Y + 2.2, 7) }
)
laserTween:Play()

for index, x in ipairs({ 540, 556, 572 }) do
	makePlatform("Final Jump " .. index, x, if index == 2 then 4 else 0, 14, 11)
end
makeCheckpoint(5, "Checkpoint 5 - Station Approach", 524)
makePlatform("Station 7 Finish Deck", 598, 0, 38, 26)
local finish = makePart(
	"Station 7 Finish Beacon",
	Vector3.new(10, 8, 10),
	Vector3.new(598, FLOOR_Y + 5, 0),
	colors.gold,
	Enum.Material.Neon,
	false
)

local voidReset = makePart(
	"Void Reset",
	Vector3.new(1400, 2, 500),
	Vector3.new(285, -25, 0),
	Color3.new(1, 1, 1),
	Enum.Material.SmoothPlastic,
	false
)
voidReset.Transparency = 1
voidReset.CanTouch = true
Workspace.FallenPartsDestroyHeight = -100

local checkpointCFrames = {
	[0] = spawn.CFrame + Vector3.new(0, 5, 0),
	[1] = CFrame.new(98, FLOOR_Y + 5, 0),
	[2] = CFrame.new(210, FLOOR_Y + 5, 0),
	[3] = CFrame.new(342, FLOOR_Y + 5, 0),
	[4] = CFrame.new(475, FLOOR_Y + 5, 0),
	[5] = CFrame.new(524, FLOOR_Y + 5, 0),
}
local checkpointNames = {
	[0] = "Launch Bay",
	[1] = "Airlock",
	[2] = "Reactor",
	[3] = "Comms",
	[4] = "Docking Ring",
	[5] = "Station Approach",
}
local finishDebounce = {}

local function playerFromHit(hit)
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil, nil
	end
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return player, humanoid
end

local function resetOnTouch(hit)
	local _, humanoid = playerFromHit(hit)
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = 0
	end
end

for _, hazard in ipairs({ sweep, laser, voidReset }) do
	hazard.Touched:Connect(resetOnTouch)
end

local function attachCheckpoint(pad)
	pad.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if not player then
			return
		end
		local index = pad:GetAttribute("CheckpointIndex")
		if type(index) ~= "number" or index <= (player:GetAttribute("CheckpointIndex") or 0) then
			return
		end
		player:SetAttribute("CheckpointIndex", index)
		player:SetAttribute("CheckpointName", checkpointNames[index])
		statusRemote:FireClient(player, "Checkpoint reached: " .. checkpointNames[index])
	end)
end

for _, item in ipairs(courseFolder:GetChildren()) do
	if item:GetAttribute("CheckpointIndex") then
		attachCheckpoint(item)
	end
end

local function setupPlayer(player)
	player:SetAttribute("CheckpointIndex", 0)
	player:SetAttribute("CheckpointName", checkpointNames[0])

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Value = 0
	wins.Parent = leaderstats

	player.CharacterAdded:Connect(function(character)
		local rootPart = character:WaitForChild("HumanoidRootPart", 10)
		if not rootPart then
			return
		end
		local checkpointIndex = player:GetAttribute("CheckpointIndex") or 0
		character:PivotTo(checkpointCFrames[checkpointIndex] or checkpointCFrames[0])
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end
Players.PlayerRemoving:Connect(function(player)
	finishDebounce[player.UserId] = nil
end)

finish.Touched:Connect(function(hit)
	local player = playerFromHit(hit)
	if not player or finishDebounce[player.UserId] then
		return
	end
	finishDebounce[player.UserId] = true
	local leaderstats = player:FindFirstChild("leaderstats")
	local wins = leaderstats and leaderstats:FindFirstChild("Wins")
	if wins then
		wins.Value += 1
	end
	statusRemote:FireClient(player, "Station 7 reached! Run complete.")
	task.delay(4, function()
		finishDebounce[player.UserId] = nil
	end)
end)
