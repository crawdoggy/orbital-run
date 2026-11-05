local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local statusRemote = ReplicatedStorage:WaitForChild("OrbitalRunStatus")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OrbitalRunHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "StatusPanel"
panel.AnchorPoint = Vector2.new(0, 0)
panel.Position = UDim2.fromOffset(24, 24)
panel.Size = UDim2.fromOffset(310, 106)
panel.BackgroundColor3 = Color3.fromRGB(10, 18, 32)
panel.BackgroundTransparency = 0.12
panel.BorderSizePixel = 0
panel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(49, 224, 219)
stroke.Thickness = 1.5
stroke.Transparency = 0.15
stroke.Parent = panel

local function makeLabel(name, text, position, size, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = text
	label.TextColor3 = color
	label.TextSize = textSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = panel
	return label
end

makeLabel(
	"Title",
	"ORBITAL RUN  //  STATION 7",
	UDim2.fromOffset(16, 11),
	UDim2.new(1, -32, 0, 25),
	15,
	Color3.fromRGB(226, 242, 255)
).Font = Enum.Font.GothamBold

local checkpointLabel = makeLabel(
	"Checkpoint",
	"Checkpoint: Launch Bay",
	UDim2.fromOffset(16, 44),
	UDim2.new(1, -32, 0, 22),
	14,
	Color3.fromRGB(117, 235, 222)
)

local winsLabel = makeLabel(
	"Wins",
	"Wins: 0",
	UDim2.fromOffset(16, 72),
	UDim2.new(1, -32, 0, 20),
	13,
	Color3.fromRGB(255, 208, 112)
)

local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 34)
toast.Size = UDim2.new(0.8, 0, 0, 44)
toast.BackgroundColor3 = Color3.fromRGB(10, 18, 32)
toast.BackgroundTransparency = 1
toast.BorderSizePixel = 0
toast.Font = Enum.Font.GothamBold
toast.TextColor3 = Color3.fromRGB(255, 255, 255)
toast.TextSize = 17
toast.TextTransparency = 1
toast.Visible = false
toast.Parent = screenGui

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 10)
toastCorner.Parent = toast

local toastStroke = Instance.new("UIStroke")
toastStroke.Color = Color3.fromRGB(49, 224, 219)
toastStroke.Transparency = 1
toastStroke.Parent = toast

local toastSerial = 0
local function showToast(message)
	toastSerial += 1
	local serial = toastSerial
	toast.Text = message
	toast.Visible = true
	TweenService:Create(toast, TweenInfo.new(0.2), {
		BackgroundTransparency = 0.12,
		TextTransparency = 0,
	}):Play()
	TweenService:Create(toastStroke, TweenInfo.new(0.2), { Transparency = 0.15 }):Play()
	task.delay(3, function()
		if serial ~= toastSerial then
			return
		end
		local fade = TweenService:Create(toast, TweenInfo.new(0.35), {
			BackgroundTransparency = 1,
			TextTransparency = 1,
		})
		TweenService:Create(toastStroke, TweenInfo.new(0.35), { Transparency = 1 }):Play()
		fade:Play()
		fade.Completed:Wait()
		if serial == toastSerial then
			toast.Visible = false
		end
	end)
end

local function updateCheckpoint()
	checkpointLabel.Text = "Checkpoint: " .. (player:GetAttribute("CheckpointName") or "Launch Bay")
end

local function updateWins()
	local leaderstats = player:FindFirstChild("leaderstats")
	local wins = leaderstats and leaderstats:FindFirstChild("Wins")
	winsLabel.Text = "Wins: " .. tostring(wins and wins.Value or 0)
end

local function bindLeaderstats(leaderstats)
	local function bindWins(wins)
		wins.Changed:Connect(updateWins)
		updateWins()
	end

	local wins = leaderstats:FindFirstChild("Wins")
	if wins then
		bindWins(wins)
	end
	leaderstats.ChildAdded:Connect(function(child)
		if child.Name == "Wins" then
			bindWins(child)
		end
	end)
end

player:GetAttributeChangedSignal("CheckpointName"):Connect(updateCheckpoint)
player.ChildAdded:Connect(function(child)
	if child.Name == "leaderstats" then
		bindLeaderstats(child)
	end
end)

local leaderstats = player:FindFirstChild("leaderstats")
if leaderstats then
	bindLeaderstats(leaderstats)
end
updateCheckpoint()
updateWins()

statusRemote.OnClientEvent:Connect(showToast)
