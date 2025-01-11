-- Admin Script for Roblox

-- Admin Permissions
local admins = {"Player1", "Player2"} -- Buraya adminlerin isimlerini ekleyin

-- Functions
local function isAdmin(player)
    return table.find(admins, player.Name) ~= nil
end

-- Noclip
local noclipEnabled = false
local function toggleNoclip()
    noclipEnabled = not noclipEnabled
    if noclipEnabled then
        game:GetService("RunService").Stepped:Connect(function()
            for _, part in ipairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end
end

-- Infinite Jump
local infiniteJumpEnabled = false
local function toggleInfiniteJump()
    infiniteJumpEnabled = not infiniteJumpEnabled
    game:GetService("UserInputService").JumpRequest:Connect(function()
        if infiniteJumpEnabled then
            game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
        end
    end)
end

-- Kill Aura
local killAuraEnabled = false
local killAuraRadius = 10
local function toggleKillAura(radius)
    killAuraEnabled = not killAuraEnabled
    killAuraRadius = tonumber(radius) or 10
    while killAuraEnabled do
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
                local distance = (player.Character.HumanoidRootPart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).magnitude
                if distance <= killAuraRadius then
                    player.Character.Humanoid.Health = 0
                end
            end
        end
        wait(0.1)
    end
end

-- Speed
local function setSpeed(speed)
    local humanoid = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = tonumber(speed) or 16
    end
end

-- ESP
local espEnabled = false
local function toggleESP()
    espEnabled = not espEnabled
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            if espEnabled then
                local billboard = Instance.new("BillboardGui", player.Character.Head)
                billboard.Name = "ESP"
                billboard.Size = UDim2.new(1, 0, 1, 0)
                billboard.AlwaysOnTop = true

                local textLabel = Instance.new("TextLabel", billboard)
                textLabel.Size = UDim2.new(1, 0, 1, 0)
                textLabel.BackgroundTransparency = 1
                textLabel.Text = player.Name
                textLabel.TextColor3 = Color3.new(1, 0, 0)
            else
                if player.Character.Head:FindFirstChild("ESP") then
                    player.Character.Head.ESP:Destroy()
                end
            end
        end
    end
end

-- Jump Power
local function setJumpPower(power)
    local humanoid = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.JumpPower = tonumber(power) or 50
    end
end

-- Chat Commands
game.Players.LocalPlayer.Chatted:Connect(function(message)
    local args = string.split(message, " ")
    local command = args[1]

    if command == "!noclip" and isAdmin(game.Players.LocalPlayer) then
        toggleNoclip()
    elseif command == "!ijump" and isAdmin(game.Players.LocalPlayer) then
        toggleInfiniteJump()
    elseif command == "!kaura" and isAdmin(game.Players.LocalPlayer) then
        toggleKillAura(args[2])
    elseif command == "!sspeed" and isAdmin(game.Players.LocalPlayer) then
        setSpeed(args[2])
    elseif command == "!esp" and isAdmin(game.Players.LocalPlayer) then
        toggleESP()
    elseif command == "!sjump" and isAdmin(game.Players.LocalPlayer) then
        setJumpPower(args[2])
    end
end)
