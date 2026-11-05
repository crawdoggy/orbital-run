local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local FLOOR_Y = 10
local COURSE_FOLDER_NAME = "OrbitalRunCourse"
local REMOTE_NAME = "OrbitalRunStatus"
local FINAL_CHECKPOINT = 5
local RESPAWN_SECONDS = 1
local RETURN_TO_START_DELAY = 2.5
local DRIFT_END_PAUSE = 0.5

-- Obby deaths are frequent; the default 5-second respawn feels sluggish.
Players.RespawnTime = RESPAWN_SECONDS

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
	return platform, trim
end

local function makeCheckpoint(index, name, x)
	local platform = makePlatform(name .. " Platform", x, 0, 20, 20)
	-- The pad spans the platform's full width so a run can't skip it by walking around the edge.
	local pad = makePart(
		name,
		Vector3.new(8, 0.35, 19.6),
		Vector3.new(x, FLOOR_Y + 1.18, 0),
		colors.checkpoint,
		Enum.Material.Neon,
		false
	)
	pad:SetAttribute("CheckpointIndex", index)
	return platform, pad
end

-- Moving platforms are physics-driven (PrismaticConstraint servo) rather than tweened while
-- anchored: a tweened anchored part slides out from under characters instead of carrying them,
-- and its movement replicates to clients in visible steps.
local function makeDriftingPlatform(index, x, offset, travelTime)
	local platform, trim = makePlatform("Drifting Platform " .. index, x, 0, 15, 13)
	local slideAxis = CFrame.fromMatrix(Vector3.zero, Vector3.zAxis, Vector3.yAxis)

	local anchor = makePart(
		platform.Name .. " Track",
		Vector3.new(1, 1, 1),
		platform.Position,
		colors.deck,
		Enum.Material.Metal,
		false
	)
	anchor.Transparency = 1
	anchor.CanTouch = false
	anchor.CanQuery = false

	local trackAttachment = Instance.new("Attachment")
	trackAttachment.CFrame = slideAxis
	trackAttachment.Parent = anchor
	local platformAttachment = Instance.new("Attachment")
	platformAttachment.CFrame = slideAxis
	platformAttachment.Parent = platform

	trim.Anchored = false
	trim.Massless = true
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = platform
	weld.Part1 = trim
	weld.Parent = platform

	local slider = Instance.new("PrismaticConstraint")
	slider.Attachment0 = trackAttachment
	slider.Attachment1 = platformAttachment
	slider.ActuatorType = Enum.ActuatorType.Servo
	slider.ServoMaxForce = 1e8
	slider.Speed = math.abs(offset) / travelTime
	slider.TargetPosition = 0
	slider.Parent = platform

	platform.Anchored = false
	platform:SetNetworkOwner(nil)

	task.spawn(function()
		local atOffset = false
		while slider.Parent do
			atOffset = not atOffset
			slider.TargetPosition = if atOffset then offset else 0
			task.wait(travelTime + DRIFT_END_PAUSE)
		end
	end)
	return platform
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

-- Adjacent decks butt edge to edge instead of overlapping; overlapping top faces flicker (z-fighting).
makePlatform("Crossing Approach", 121, 0, 26, 18)
makePlatform("Sweep Hazard Deck", 154, 0, 30, 18)
local sweep = makePart(
	"Red Sweep Hazard",
	Vector3.new(3, 2.5, 6),
	Vector3.new(154, FLOOR_Y + 2.25, -6),
	colors.hazard,
	Enum.Material.Neon,
	false
)
local sweepTween = TweenService:Create(
	sweep,
	TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Position = Vector3.new(154, FLOOR_Y + 2.25, 6) }
)
sweepTween:Play()
makePlatform("Crossing Exit", 182, 0, 26, 18)
makeCheckpoint(2, "Checkpoint 2 - Reactor", 210)

local beamZ = { -4, 4, -4, 4, -4, 4 }
local beamX = { 231, 249, 267, 285, 303, 321 }
for index, x in ipairs(beamX) do
	makePlatform("Balance Beam " .. index, x, beamZ[index], 20, 4)
end
makeCheckpoint(3, "Checkpoint 3 - Comms", 342)

makePlatform("Platform Bay Entry", 363, 0, 22, 20)
for index, x in ipairs({ 383, 407, 431, 455 }) do
	local offset = if index % 2 == 0 then -5 else 5
	makeDriftingPlatform(index, x, offset, 2.4 + index * 0.15)
end
makeCheckpoint(4, "Checkpoint 4 - Docking Ring", 475)

makePlatform("Laser Corridor", 499.5, 0, 29, 22)
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

for index, x in ipairs({ 541, 556, 572 }) do
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

local function setCheckpoint(player, index)
	player:SetAttribute("CheckpointIndex", index)
	player:SetAttribute("CheckpointName", checkpointNames[index])
end

finish.Touched:Connect(function(hit)
	local player, humanoid = playerFromHit(hit)
	if not player or not humanoid or humanoid.Health <= 0 or finishDebounce[player.UserId] then
		return
	end
	finishDebounce[player.UserId] = true

	-- A win only counts after the last checkpoint, and it starts a fresh run, so standing
	-- in the beacon can't farm wins.
	if (player:GetAttribute("CheckpointIndex") or 0) < FINAL_CHECKPOINT then
		statusRemote:FireClient(player, "Missed a checkpoint. Touch every cyan pad to finish.")
		task.delay(3, function()
			finishDebounce[player.UserId] = nil
		end)
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local wins = leaderstats and leaderstats:FindFirstChild("Wins")
	if wins then
		wins.Value += 1
	end
	setCheckpoint(player, 0)
	statusRemote:FireClient(player, "Station 7 reached! Run complete. Returning to Launch Bay...")

	local character = humanoid.Parent
	task.delay(RETURN_TO_START_DELAY, function()
		finishDebounce[player.UserId] = nil
		if player.Parent and player.Character == character and humanoid.Health > 0 then
			character:PivotTo(checkpointCFrames[0])
		end
	end)
end)
