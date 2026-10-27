-- ============================================================
-- HOHA'S MM2 SCRIPT v6.6 (MOBILE SUPPORT + ARCEUSX TRADE SCAM)
-- ============================================================

local function logError(sourceName, err)
    local msg = string.format("[HOHA | ERR | %s]: %s", tostring(sourceName), tostring(err))
    pcall(function() game:GetService("TestService"):Message(msg) end)
    warn(msg)
    if rconsoleerr then rconsoleerr(msg .. "\n") end
end

local function safeExecute(func, name, ...)
    local ok, res = pcall(func, ...)
    if not ok then logError(name or "Main", res) return nil end
    return res
end

safeExecute(function()
local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local HttpService      = game:GetService("HttpService")
local SoundService     = game:GetService("SoundService")
local LocalPlayer      = Players.LocalPlayer

-- Eski GUI'leri temizle
for _, n in ipairs({"HohaMM2Hub","HohaLoadingGui","HohaKeySystem","HohaNotification","HohaRadarGui", "HohaToggleGui"}) do
    if CoreGui:FindFirstChild(n) then CoreGui[n]:Destroy() end
    if Lighting:FindFirstChild("HohaBlur") then Lighting.HohaBlur:Destroy() end
end

-- ============================================================
-- CORE STATE & CONFIG
-- ============================================================
getgenv().HohaScriptCore = {
    Version     = "6.6",
    State = {
        ESP_Enabled=false, MurdererESP=false, SheriffESP=false, InnocentESP=false,
        GunESP=false, NameESP=false, WalkSpeed=false, JumpPower=false, Fly=false,
        NoClip=false, InfJump=false, AntiFling=false, GodBright=false, FPSBoost=false,
        AttachPlayer=false, KillAura=false, AutoCoin=false, TouchFling=false,
        HitboxExpander=false, SilentAim=false, Freecam=false, Radar=false,
        ScammerESP=false, TradeScammer=false
    },
    Config = {
        WalkSpeedValue=32, JumpPowerValue=70, FlySpeedValue=50, FovValue=70,
        HitboxSize=8, SelectedTarget="", SelectedEmote="Floss", FarmSpeed=22,
        WebhookURL="", AutoExecScript="print('Hoha Auto-Exec Running!')",
        ScammerList={}, FakeTradeItem="Chroma Darkbringer"
    },
    Threads={}
}
local Core = getgenv().HohaScriptCore

local OriginalMaterials = {}
local OriginalLighting  = {
    GlobalShadows = Lighting.GlobalShadows,
    Brightness    = Lighting.Brightness,
    ClockTime     = Lighting.ClockTime
}

-- ============================================================
-- THEME & SOUNDS
-- ============================================================
local Theme = {
    Background   = Color3.fromRGB(10, 10, 14),
    Sidebar      = Color3.fromRGB(15, 15, 22),
    Card         = Color3.fromRGB(22, 22, 30),
    CardHover    = Color3.fromRGB(32, 32, 45),
    Accent       = Color3.fromRGB(0, 255, 255),
    AccentGlow   = Color3.fromRGB(100, 255, 255),
    Text         = Color3.fromRGB(255, 255, 255),
    SubText      = Color3.fromRGB(150, 150, 170),
    Success      = Color3.fromRGB(0, 255, 128),
    Danger       = Color3.fromRGB(255, 50, 50),
    Murderer     = Color3.fromRGB(255, 50, 50),
    Sheriff      = Color3.fromRGB(50, 150, 255),
    Innocent     = Color3.fromRGB(50, 255, 100),
    Scammer      = Color3.fromRGB(255, 165, 0)
}

local Sounds = {
    Hover = "rbxassetid://6869583954",
    Click = "rbxassetid://6869584011",
    Open  = "rbxassetid://6869583477"
}

local function PlaySound(id, vol)
    local s = Instance.new("Sound", SoundService)
    s.SoundId = id
    s.Volume = vol or 0.5
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

-- ============================================================
-- HELPERS
-- ============================================================
local function getRole(plr)
    if not plr or not plr.Character then return "Innocent" end
    local char = plr.Character
    local bp = plr:FindFirstChild("Backpack")
    if Core.Config.ScammerList[plr.Name] then return "Scammer" end
    if char:FindFirstChild("Knife") or (bp and bp:FindFirstChild("Knife")) then return "Murderer" end
    if char:FindFirstChild("Gun")  or (bp and bp:FindFirstChild("Gun"))  then return "Sheriff"  end
    return "Innocent"
end

local function TeleportToCFrame(cf)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = cf end
end

local function GrabGun()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name == "GunDrop" or (obj:IsA("Model") and obj:FindFirstChild("Handle")) then
            local cf = obj:IsA("Model") and obj:GetPivot() or (obj:IsA("BasePart") and obj.CFrame)
            if cf then
                TeleportToCFrame(cf + Vector3.new(0, 2, 0))
                SendNotification("Gun", "Teleported to gun!", 2.5)
                return
            end
        end
    end
    SendNotification("Error", "No dropped gun found.", 2.5)
end

local function FlingTarget(name)
    local tp = Players:FindFirstChild(name)
    if not tp or not tp.Character or not tp.Character:FindFirstChild("HumanoidRootPart") then
        SendNotification("Error", "Invalid target!", 2.5) return
    end
    task.spawn(function()
        local myChar = LocalPlayer.Character
        local myHrp  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local tHrp   = tp.Character.HumanoidRootPart
        if not myHrp or not tHrp then return end
        local oldCF = myHrp.CFrame
        local bav = Instance.new("BodyAngularVelocity", myHrp)
        bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bav.AngularVelocity = Vector3.new(0, 99999, 0)
        local bv = Instance.new("BodyVelocity", myHrp)
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.zero
        for _ = 1, 40 do
            if not tHrp.Parent then break end
            myHrp.CFrame = tHrp.CFrame * CFrame.new(math.random(-1, 1), 0, math.random(-1, 1))
            myHrp.AssemblyLinearVelocity = Vector3.new(99999, 99999, 99999)
            task.wait(0.02)
        end
        bav:Destroy(); bv:Destroy()
        myHrp.CFrame = oldCF
        SendNotification("Fling", name .. " flung!", 2.5)
    end)
end

local function SendWebhook(status, total)
    local url = Core.Config.WebhookURL
    if not url or url == "" then return end
    local data = {
        embeds = {{
            title = "💰 Hoha MM2 — Farm Log",
            description = string.format("Player: **%s**\nStatus: **%s**\nCoins: **%d**", LocalPlayer.Name, status, total),
            color = 3447003,
            footer = {text = "Hoha's MM2 Script v6.6"},
            timestamp = DateTime.now():ToIsoDate()
        }}
    }
    pcall(function()
        local req = syn and syn.request or http_request or request
        if req then req({Url=url, Method="POST", Headers={["Content-Type"]="application/json"}, Body=HttpService:JSONEncode(data)}) end
    end)
end

-- ============================================================
-- TRADE SCAMMER LOGIC (ARCEUSX SAFE HOOK)
-- ============================================================
local isHooked = false
local function SetupTradeScammer()
    if isHooked then return end
    isHooked = true
    
    local success = pcall(function()
        if hookmetamethod then
            local oldNameCall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                local args = table.pack(...)
                
                if Core.State.TradeScammer and (method == "FireServer" or method == "InvokeServer") then
                    local remoteName = string.lower(self.Name)
                    if string.find(remoteName, "trade") or string.find(remoteName, "inventory") or string.find(remoteName, "item") or string.find(remoteName, "offer") then
                        for i = 1, args.n do
                            local arg = args[i]
                            if type(arg) == "table" then
                                for k, v in pairs(arg) do
                                    if type(v) == "string" and (v == "Knife" or string.find(v, "Seer") or string.find(v, "Chroma") or string.find(v, "Gun") or string.find(v, "Bat")) then
                                        arg[k] = Core.Config.FakeTradeItem
                                    end
                                end
                            elseif type(arg) == "string" then
                                if arg == "Knife" or string.find(arg, "Seer") or string.find(arg, "Chroma") or string.find(arg, "Gun") or string.find(arg, "Bat") then
                                    args[i] = Core.Config.FakeTradeItem
                                end
                            end
                        end
                    end
                end
                return oldNameCall(self, table.unpack(args, 1, args.n))
            end)
        elseif getrawmetatable then
            local mt = getrawmetatable(game)
            local oldNameCall = mt.__namecall
            setreadonly(mt, false)
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                local args = table.pack(...)
                
                if Core.State.TradeScammer and (method == "FireServer" or method == "InvokeServer") then
                    local remoteName = string.lower(self.Name)
                    if string.find(remoteName, "trade") or string.find(remoteName, "inventory") or string.find(remoteName, "item") or string.find(remoteName, "offer") then
                        for i = 1, args.n do
                            local arg = args[i]
                            if type(arg) == "table" then
                                for k, v in pairs(arg) do
                                    if type(v) == "string" and (v == "Knife" or string.find(v, "Seer") or string.find(v, "Chroma") or string.find(v, "Gun") or string.find(v, "Bat")) then
                                        arg[k] = Core.Config.FakeTradeItem
                                    end
                                end
                            elseif type(arg) == "string" then
                                if arg == "Knife" or string.find(arg, "Seer") or string.find(arg, "Chroma") or string.find(arg, "Gun") or string.find(arg, "Bat") then
                                    args[i] = Core.Config.FakeTradeItem
                                end
                            end
                        end
                    end
                end
                return oldNameCall(self, table.unpack(args, 1, args.n))
            end)
            setreadonly(mt, true)
        else
            error("Bu executor hook fonksiyonlarini desteklemiyor.")
        end
    end)
    
    if success then
        SendNotification("Trade Scammer", "Hook applied. Fake item: " .. Core.Config.FakeTradeItem, 5)
    else
        SendNotification("Trade Scammer", "Hook basarisiz, ArceusX desteklemiyor.", 5)
    end
end

local function ToggleTradeScammer(state)
    if state then
        SetupTradeScammer()
    else
        SendNotification("Trade Scammer", "Trade Scam disabled.", 3)
    end
end

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
local NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "HohaNotification"
NotifGui.ResetOnSpawn = false
NotifGui.Parent = CoreGui

local NotifContainer = Instance.new("Frame")
NotifContainer.Size = UDim2.new(0, 300, 1, -20)
NotifContainer.Position = UDim2.new(1, -320, 0, 10)
NotifContainer.BackgroundTransparency = 1
NotifContainer.Parent = NotifGui

local NotifLayout = Instance.new("UIListLayout")
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifLayout.Padding = UDim.new(0, 10)
NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifLayout.Parent = NotifContainer

local function SendNotification(title, message, duration)
    duration = duration or 3.5
    safeExecute(function()
        local Toast = Instance.new("Frame")
        Toast.Size = UDim2.new(1, 0, 0, 65)
        Toast.BackgroundColor3 = Theme.Card
        Toast.BorderSizePixel = 0
        Toast.Parent = NotifContainer
        Instance.new("UICorner", Toast).CornerRadius = UDim.new(0, 8)

        local Stroke = Instance.new("UIStroke")
        Stroke.Color = Theme.Accent
        Stroke.Thickness = 1.5
        Stroke.Transparency = 0.3
        Stroke.Parent = Toast

        local TitleLbl = Instance.new("TextLabel")
        TitleLbl.Size = UDim2.new(1, -20, 0, 25)
        TitleLbl.Position = UDim2.new(0, 12, 0, 8)
        TitleLbl.BackgroundTransparency = 1
        TitleLbl.Font = Enum.Font.GothamBold
        TitleLbl.TextSize = 13
        TitleLbl.TextColor3 = Theme.AccentGlow
        TitleLbl.Text = title
        TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
        TitleLbl.Parent = Toast

        local MsgLbl = Instance.new("TextLabel")
        MsgLbl.Size = UDim2.new(1, -20, 0, 20)
        MsgLbl.Position = UDim2.new(0, 12, 0, 30)
        MsgLbl.BackgroundTransparency = 1
        MsgLbl.Font = Enum.Font.GothamMedium
        MsgLbl.TextSize = 11
        MsgLbl.TextColor3 = Theme.SubText
        MsgLbl.Text = message
        MsgLbl.TextXAlignment = Enum.TextXAlignment.Left
        MsgLbl.Parent = Toast

        Toast.Position = UDim2.new(1, 320, 0, 0)
        TweenService:Create(Toast, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()

        task.delay(duration, function()
            if Toast and Toast.Parent then
                local t = TweenService:Create(Toast, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(1, 320, 0, 0)})
                t:Play()
                t.Completed:Once(function() if Toast then Toast:Destroy() end end)
            end
        end)
    end, "SendNotification")
end

-- ============================================================
-- LOGIC FUNCTIONS
-- ============================================================
local ToggleFly, ToggleTouchFling, ToggleHitbox, ToggleAutoCoin
local ToggleKillAura, ToggleESP, ToggleAttach, ToggleSilentAim
local ToggleFreecam, ToggleRadar
local BuildMainGUI, ShowKeyGUI

local function ToggleFPSBoost(state)
    if state then
        Lighting.GlobalShadows = false
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                OriginalMaterials[obj] = {Material=obj.Material, Transparency=obj.Transparency}
                obj.Material = Enum.Material.SmoothPlastic
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                OriginalMaterials[obj] = {Transparency=obj.Transparency}
                obj.Transparency = 1
            end
        end
    else
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        for obj, props in pairs(OriginalMaterials) do
            if obj and obj.Parent then
                if obj:IsA("BasePart") then
                    obj.Material = props.Material
                    obj.Transparency = props.Transparency
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj.Transparency = props.Transparency
                end
            end
        end
        OriginalMaterials = {}
    end
end

function ToggleRadar(enabled)
    if enabled then
        local RadarGui = Instance.new("ScreenGui")
        RadarGui.Name = "HohaRadarGui"
        RadarGui.ResetOnSpawn = false
        RadarGui.Parent = CoreGui

        local RadarFrame = Instance.new("Frame")
        RadarFrame.Size = UDim2.new(0, 160, 0, 160)
        RadarFrame.Position = UDim2.new(0, 15, 0, 60)
        RadarFrame.BackgroundColor3 = Theme.Sidebar
        RadarFrame.BackgroundTransparency = 0.3
        RadarFrame.BorderSizePixel = 0
        RadarFrame.Parent = RadarGui
        Instance.new("UICorner", RadarFrame).CornerRadius = UDim.new(1, 0)

        local RadarStroke = Instance.new("UIStroke")
        RadarStroke.Color = Theme.Accent
        RadarStroke.Thickness = 1.5
        RadarStroke.Parent = RadarFrame

        local CenterDot = Instance.new("Frame")
        CenterDot.Size = UDim2.new(0, 6, 0, 6)
        CenterDot.Position = UDim2.new(0.5, -3, 0.5, -3)
        CenterDot.BackgroundColor3 = Theme.Text
        CenterDot.Parent = RadarFrame
        Instance.new("UICorner", CenterDot).CornerRadius = UDim.new(1, 0)

        local dots = {}
        Core.Threads.Radar = RunService.RenderStepped:Connect(function()
            if not Core.State.Radar then return end
            local myChar = LocalPlayer.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHrp then return end

            for _, d in pairs(dots) do if d and d.Parent then d:Destroy() end end
            dots = {}

            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local offset = plr.Character.HumanoidRootPart.Position - myHrp.Position
                    if offset.Magnitude < 150 then
                        local dot = Instance.new("Frame")
                        dot.Size = UDim2.new(0, 6, 0, 6)
                        local role = getRole(plr)
                        dot.BackgroundColor3 = (role == "Murderer") and Theme.Murderer or (role == "Sheriff") and Theme.Sheriff or (role == "Scammer") and Theme.Scammer or Theme.Innocent
                        dot.Parent = RadarFrame
                        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
                        dot.Position = UDim2.new(0.5, offset.X / 150 * 70 - 3, 0.5, offset.Z / 150 * 70 - 3)
                        table.insert(dots, dot)
                    end
                end
            end
        end)
    else
        if Core.Threads.Radar then Core.Threads.Radar:Disconnect(); Core.Threads.Radar = nil end
        if CoreGui:FindFirstChild("HohaRadarGui") then CoreGui.HohaRadarGui:Destroy() end
    end
end

local camPart
function ToggleFreecam(enabled)
    local cam = Workspace.CurrentCamera
    if enabled then
        camPart = Instance.new("Part")
        camPart.Anchored = true
        camPart.Transparency = 1
        camPart.CanCollide = false
        camPart.CFrame = cam.CFrame
        camPart.Parent = Workspace
        cam.CameraType = Enum.CameraType.Scriptable

        Core.Threads.Freecam = RunService.RenderStepped:Connect(function(dt)
            if not Core.State.Freecam then return end
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Vector3.new(0, 0, -1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move += Vector3.new(0, 0, 1)  end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move += Vector3.new(-1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Vector3.new(1, 0, 0)  end
            camPart.CFrame = camPart.CFrame + cam.CFrame:VectorToWorldSpace(move) * 50 * dt
            cam.CFrame = camPart.CFrame
        end)
    else
        if Core.Threads.Freecam then Core.Threads.Freecam:Disconnect(); Core.Threads.Freecam = nil end
        if camPart then camPart:Destroy(); camPart = nil end
        cam.CameraType = Enum.CameraType.Custom
    end
end

local bodyVel, bodyGyro
function ToggleFly(enabled)
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if enabled then
        if bodyVel  then bodyVel:Destroy()  end
        if bodyGyro then bodyGyro:Destroy() end

        bodyVel = Instance.new("BodyVelocity")
        bodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVel.Parent = hrp

        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bodyGyro.Parent = hrp

        Core.Threads.Fly = RunService.RenderStepped:Connect(function()
            if not Core.State.Fly or not hrp then return end
            local cam = Workspace.CurrentCamera
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector  end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector  end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
            bodyVel.Velocity = dir * (Core.Config.FlySpeedValue or 50)
            bodyGyro.CFrame  = cam.CFrame
        end)
    else
        if Core.Threads.Fly then Core.Threads.Fly:Disconnect(); Core.Threads.Fly = nil end
        if bodyVel  then bodyVel:Destroy();  bodyVel  = nil end
        if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
    end
end

local touchFlingConn = nil
function ToggleTouchFling(enabled)
    if enabled then
        local function hookChar(char)
            local hrp = char:WaitForChild("HumanoidRootPart", 5)
            if not hrp then return end
            hrp.Massless = true
            hrp.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0, 0, 0, 0)

            if touchFlingConn then touchFlingConn:Disconnect() end
            touchFlingConn = hrp.Touched:Connect(function(hit)
                if not Core.State.TouchFling then return end
                local tc = hit:FindFirstAncestorOfClass("Model")
                if not tc then return end
                local tp = Players:GetPlayerFromCharacter(tc)
                if not tp or tp == LocalPlayer then return end
                local tHrp = tc:FindFirstChild("HumanoidRootPart")
                if not tHrp then return end
                tHrp.AssemblyLinearVelocity  = Vector3.new(0, 500000, 0)
                tHrp.AssemblyAngularVelocity = Vector3.new(99999, 99999, 99999)
            end)
        end

        if LocalPlayer.Character then hookChar(LocalPlayer.Character) end
        Core.Threads.TouchFlingRespawn = LocalPlayer.CharacterAdded:Connect(hookChar)
    else
        if touchFlingConn then touchFlingConn:Disconnect(); touchFlingConn = nil end
        if Core.Threads.TouchFlingRespawn then
            Core.Threads.TouchFlingRespawn:Disconnect()
            Core.Threads.TouchFlingRespawn = nil
        end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Massless = false
            hrp.AssemblyLinearVelocity  = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

function ToggleHitbox(enabled)
    if enabled then
        Core.Threads.Hitbox = RunService.RenderStepped:Connect(function()
            if not Core.State.HitboxExpander then return end
            local sz = tonumber(Core.Config.HitboxSize) or 8
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = p.Character.HumanoidRootPart
                    hrp.Size = Vector3.new(sz, sz, sz)
                    hrp.Transparency = 0.7
                    hrp.BrickColor = BrickColor.new("Really red")
                    hrp.Material = Enum.Material.Neon
                    hrp.CanCollide = false
                end
            end
        end)
    else
        if Core.Threads.Hitbox then Core.Threads.Hitbox:Disconnect(); Core.Threads.Hitbox = nil end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = p.Character.HumanoidRootPart
                hrp.Size = Vector3.new(2, 2, 1)
                hrp.Transparency = 1
            end
        end
    end
end

local collectedCoins = 0
function ToggleAutoCoin(enabled)
    if enabled then
        collectedCoins = 0
        SendWebhook("Auto-Farm Started 🚀", collectedCoins)

        Core.Threads.AutoCoin = task.spawn(function()
            while Core.State.AutoCoin do
                local coinContainer = Workspace:FindFirstChild("CoinContainer", true)
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if coinContainer and hrp then
                    for _, coin in ipairs(coinContainer:GetChildren()) do
                        if not Core.State.AutoCoin then return end
                        local part = coin:IsA("BasePart") and coin or coin:FindFirstChildWhichIsA("BasePart")
                        if part and part.Parent then
                            local targetPos = Vector3.new(part.Position.X, hrp.Position.Y, part.Position.Z)
                            local dist = (hrp.Position - targetPos).Magnitude
                            local speed = math.clamp(Core.Config.FarmSpeed or 22, 20, 25)
                            local tTime = dist / speed

                            local tween = TweenService:Create(hrp, TweenInfo.new(tTime, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)})
                            local done = false
                            local conn = tween.Completed:Once(function() done = true end)
                            tween:Play()

                            while not done and Core.State.AutoCoin do task.wait(0.02) end
                            if not Core.State.AutoCoin then tween:Cancel(); conn:Disconnect(); return end

                            collectedCoins += 1
                            if collectedCoins % 15 == 0 then SendWebhook("Farm in progress...", collectedCoins) end
                            task.wait(0.05)
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    else
        Core.State.AutoCoin = false
        if Core.Threads.AutoCoin then pcall(function() task.cancel(Core.Threads.AutoCoin) end); Core.Threads.AutoCoin = nil end
        SendWebhook("Auto-Farm Stopped 🛑", collectedCoins)
    end
end

function ToggleKillAura(enabled)
    if enabled then
        Core.Threads.KillAura = task.spawn(function()
            while Core.State.KillAura do
                local char = LocalPlayer.Character
                local bp   = LocalPlayer:FindFirstChild("Backpack")
                local knife = char and (char:FindFirstChild("Knife") or (bp and bp:FindFirstChild("Knife")))
                if knife and char and char:FindFirstChild("HumanoidRootPart") then
                    if knife.Parent == bp then knife.Parent = char end
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            local dist = (p.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude
                            if dist <= 14 then knife:Activate() end
                        end
                    end
                end
                task.wait(0.1)
            end
        end)
    else
        if Core.Threads.KillAura then task.cancel(Core.Threads.KillAura); Core.Threads.KillAura = nil end
    end
end

function ToggleAttach(enabled)
    if enabled then
        Core.Threads.Attach = RunService.RenderStepped:Connect(function()
            if not Core.State.AttachPlayer then return end
            local tp = Players:FindFirstChild(Core.Config.SelectedTarget)
            if tp and tp.Character and tp.Character:FindFirstChild("HumanoidRootPart") then
                local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myHrp then myHrp.CFrame = tp.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2) end
            end
        end)
    else
        if Core.Threads.Attach then Core.Threads.Attach:Disconnect(); Core.Threads.Attach = nil end
    end
end

function ToggleSilentAim(enabled)
    if enabled then
        Core.Threads.SilentAim = RunService.RenderStepped:Connect(function()
            if not Core.State.SilentAim then return end
            local gun = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Gun")
            if not gun then return end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and getRole(p) == "Murderer" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    Workspace.CurrentCamera.CFrame = CFrame.new(Workspace.CurrentCamera.CFrame.Position, p.Character.HumanoidRootPart.Position)
                    break
                end
            end
        end)
    else
        if Core.Threads.SilentAim then Core.Threads.SilentAim:Disconnect(); Core.Threads.SilentAim = nil end
    end
end

local activeESP = {}
local function clearESP(key)
    if not activeESP[key] then return end
    pcall(function()
        if type(activeESP[key]) == "table" then
            for _, v in pairs(activeESP[key]) do pcall(function() v:Destroy() end) end
        else
            activeESP[key]:Destroy()
        end
    end)
    activeESP[key] = nil
end
local function clearAllESP() for k in pairs(activeESP) do clearESP(k) end end

function ToggleESP(enabled)
    if enabled then
        if Core.Threads.ESP then task.cancel(Core.Threads.ESP) end
        Core.Threads.ESP = task.spawn(function()
            while Core.State.ESP_Enabled do
                local myChar = LocalPlayer.Character
                local myHrp  = myChar and myChar:FindFirstChild("HumanoidRootPart")
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer then
                        local char = plr.Character
                        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                        local head = char and char:FindFirstChild("Head")
                        local key  = "PLR_" .. plr.UserId
                        if char and hrp and head then
                            local role = getRole(plr)
                            local show = (Core.State.MurdererESP and role=="Murderer") 
                                      or (Core.State.SheriffESP and role=="Sheriff") 
                                      or (Core.State.InnocentESP and role=="Innocent")
                                      or (Core.State.ScammerESP and role=="Scammer")
                            
                            if show then
                                local col = role=="Murderer" and Theme.Murderer 
                                         or role=="Sheriff" and Theme.Sheriff 
                                         or role=="Scammer" and Theme.Scammer
                                         or Theme.Innocent
                                
                                if not activeESP[key] or not activeESP[key].Highlight or not activeESP[key].Highlight.Parent then
                                    clearESP(key)
                                    local hl = Instance.new("Highlight")
                                    hl.FillTransparency = 0.45
                                    hl.OutlineColor = Color3.new(1, 1, 1)
                                    hl.Adornee = char
                                    hl.Parent = char
                                    activeESP[key] = {Highlight=hl}
                                end
                                activeESP[key].Highlight.FillColor = col

                                if Core.State.NameESP and myHrp then
                                    if not activeESP[key].Billboard or not activeESP[key].Billboard.Parent then
                                        local bb = Instance.new("BillboardGui")
                                        bb.Adornee = head
                                        bb.Size = UDim2.new(0, 110, 0, 32)
                                        bb.StudsOffset = Vector3.new(0, 2.8, 0)
                                        bb.AlwaysOnTop = true
                                        local txt = Instance.new("TextLabel")
                                        txt.Size = UDim2.new(1, 0, 1, 0)
                                        txt.BackgroundTransparency = 1
                                        txt.Font = Enum.Font.GothamBold
                                        txt.TextSize = 11
                                        txt.TextStrokeTransparency = 0
                                        txt.Parent = bb
                                        bb.Parent = head
                                        activeESP[key].Billboard = bb
                                        activeESP[key].TextLabel  = txt
                                    end
                                    local dist = math.floor((hrp.Position - myHrp.Position).Magnitude)
                                    activeESP[key].TextLabel.TextColor3 = col
                                    activeESP[key].TextLabel.Text = string.format("%s\n[%dm]", plr.Name, dist)
                                elseif activeESP[key].Billboard then
                                    activeESP[key].Billboard:Destroy()
                                    activeESP[key].Billboard = nil
                                end
                            else
                                clearESP(key)
                            end
                        else
                            clearESP(key)
                        end
                    end
                end

                if Core.State.GunESP then
                    for _, item in ipairs(Workspace:GetChildren()) do
                        if item.Name=="GunDrop" or item.Name=="Gun" then
                            local key = "GUN_" .. item:GetDebugId()
                            if not activeESP[key] or not activeESP[key].Parent then
                                local hl = Instance.new("Highlight")
                                hl.FillColor   = Color3.fromRGB(250, 204, 21)
                                hl.OutlineColor= Color3.fromRGB(255, 255, 255)
                                hl.Adornee = item
                                hl.Parent  = item
                                activeESP[key] = hl
                            end
                        end
                    end
                end
                task.wait(0.3)
            end
        end)
    else
        if Core.Threads.ESP then task.cancel(Core.Threads.ESP); Core.Threads.ESP = nil end
        clearAllESP()
    end
end

-- ============================================================
-- DYNAMIC UI FRAMEWORK (MOBILE FIX)
-- ============================================================
local ScreenGui, MainFrame, FloatToggle

function BuildMainGUI()
    PlaySound(Sounds.Open, 0.6)
    
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "HohaMM2Hub"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui

    -- MOBILE FLOAT TOGGLE (Küçültme Butonu)
    FloatToggle = Instance.new("TextButton")
    FloatToggle.Size = UDim2.new(0, 60, 0, 60) -- Mobilde basması kolay olsun diye büyük
    FloatToggle.Position = UDim2.new(0, 20, 0.5, -30)
    FloatToggle.BackgroundColor3 = Theme.Card
    FloatToggle.Text = "H"
    FloatToggle.Font = Enum.Font.GothamBold
    FloatToggle.TextSize = 24
    FloatToggle.TextColor3 = Theme.Accent
    FloatToggle.AutoButtonColor = false
    FloatToggle.Parent = ScreenGui
    Instance.new("UICorner", FloatToggle).CornerRadius = UDim.new(1, 0)
    
    local FloatStroke = Instance.new("UIStroke")
    FloatStroke.Color = Theme.Accent
    FloatStroke.Thickness = 2
    FloatStroke.Parent = FloatToggle

    -- Mobil Sürükleme Mantığı
    local floatDrag, fDragStart, fStartPos
    FloatToggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            floatDrag = true; fDragStart = input.Position; fStartPos = FloatToggle.Position
        end
    end)
    FloatToggle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            floatDrag = false 
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if floatDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - fDragStart
            FloatToggle.Position = UDim2.new(fStartPos.X.Scale, fStartPos.X.Offset + d.X, fStartPos.Y.Scale, fStartPos.Y.Offset + d.Y)
        end
    end)

    -- Ana Pencere (Mobil için daha küçük boyutlar)
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -160) -- Mobilde ekrana sığması için
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Theme.Accent
    MainStroke.Thickness = 1.5
    MainStroke.Transparency = 0.4
    MainStroke.Parent = MainFrame

    TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 500, 0, 320)}):Play()

    local function ToggleMenu()
        PlaySound(Sounds.Click, 0.4)
        if MainFrame.Visible then
            local t = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
            t:Play()
            t.Completed:Once(function() MainFrame.Visible = false end)
        else
            MainFrame.Visible = true
            TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 500, 0, 320)}):Play()
        end
    end

    FloatToggle.MouseButton1Click:Connect(ToggleMenu)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            ToggleMenu()
        end
    end)

    local HideBtn = Instance.new("TextButton")
    HideBtn.Size = UDim2.new(0, 40, 0, 40) -- Mobil için daha büyük
    HideBtn.Position = UDim2.new(1, -50, 0.5, -20)
    HideBtn.BackgroundColor3 = Theme.Card
    HideBtn.Text = "X"
    HideBtn.Font = Enum.Font.GothamBold
    HideBtn.TextSize = 16
    HideBtn.TextColor3 = Theme.Text
    HideBtn.Parent = MainFrame
    Instance.new("UICorner", HideBtn).CornerRadius = UDim.new(0, 6)
    HideBtn.MouseButton1Click:Connect(ToggleMenu)

    local dragging, dragStart, startPos
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 50)
    Header.BackgroundColor3 = Theme.Sidebar
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame
    
    -- Header Sürükleme (Mobil uyumlu)
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            dragging = true; dragStart = input.Position; startPos = MainFrame.Position 
        end
    end)
    Header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            dragging = false 
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    
    HideBtn.Parent = Header
    HideBtn.Position = UDim2.new(1, -50, 0.5, -20)

    local HeaderGradient = Instance.new("UIGradient")
    HeaderGradient.Color = ColorSequence.new(Theme.Accent, Theme.Background)
    HeaderGradient.Rotation = 45
    HeaderGradient.Transparency = NumberSequence.new(0.9, 1)
    HeaderGradient.Parent = Header
    
    task.spawn(function()
        while HeaderGradient.Parent do
            TweenService:Create(HeaderGradient, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rotation = HeaderGradient.Rotation + 360}):Play()
            task.wait(3)
        end
    end)

    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.Size = UDim2.new(0, 300, 1, 0)
    TitleLbl.Position = UDim2.new(0, 20, 0, 0)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.TextSize = 15
    TitleLbl.TextColor3 = Theme.Text
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.Text = "HOHA'S MM2 | V6.6 MOBILE"
    TitleLbl.Parent = Header

    -- Sidebar (Mobil için daraltıldı)
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 140, 1, -50)
    Sidebar.Position = UDim2.new(0, 0, 0, 50)
    Sidebar.BackgroundColor3 = Theme.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local SelectionFrame = Instance.new("Frame")
    SelectionFrame.Size = UDim2.new(0, 4, 0, 36)
    SelectionFrame.Position = UDim2.new(0, 0, 0, 15)
    SelectionFrame.BackgroundColor3 = Theme.Accent
    SelectionFrame.Parent = Sidebar
    Instance.new("UICorner", SelectionFrame).CornerRadius = UDim.new(1, 0)

    local UIList = Instance.new("UIListLayout")
    UIList.Padding = UDim.new(0, 6)
    UIList.SortOrder = Enum.SortOrder.LayoutOrder
    UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIList.Parent = Sidebar

    local UIPad = Instance.new("UIPadding")
    UIPad.PaddingTop = UDim.new(0, 15)
    UIPad.Parent = Sidebar

    -- Content (Sağ taraf)
    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, -140, 1, -50)
    Content.Position = UDim2.new(0, 140, 0, 50)
    Content.BackgroundTransparency = 1
    Content.Parent = MainFrame

    local Tabs, Pages = {}, {}
    local ActiveTabBtn = nil
    local layoutCount = 0

    local function nextOrder()
        layoutCount = layoutCount + 1
        return layoutCount
    end

    local function CreateTab(id, text)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, -10, 0, 36)
        TabBtn.BackgroundColor3 = Theme.Background
        TabBtn.BackgroundTransparency = 1
        TabBtn.Font = Enum.Font.GothamMedium
        TabBtn.TextSize = 11 -- Mobilde yazılar biraz daha küçük
        TabBtn.TextColor3 = Theme.SubText
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        TabBtn.Text = "  " .. text
        TabBtn.AutoButtonColor = false
        TabBtn.Parent = Sidebar
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)

        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.Visible = false
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = Theme.Accent
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.Parent = Content

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Parent = Page

        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
        end)

        local PagePad = Instance.new("UIPadding")
        PagePad.PaddingTop = UDim.new(0, 10)
        PagePad.PaddingLeft = UDim.new(0, 10)
        PagePad.PaddingRight = UDim.new(0, 10)
        PagePad.Parent = Page

        TabBtn.MouseButton1Click:Connect(function()
            PlaySound(Sounds.Click, 0.4)
            for tid, p in pairs(Pages) do
                p.Visible = false
                Tabs[tid].TextColor3 = Theme.SubText
                Tabs[tid].BackgroundTransparency = 1
            end
            Page.Visible = true
            TabBtn.TextColor3 = Theme.Text
            TabBtn.BackgroundTransparency = 0
            TabBtn.BackgroundColor3 = Theme.Card
            
            TweenService:Create(SelectionFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, TabBtn.AbsolutePosition.Y - Sidebar.AbsolutePosition.Y)
            }):Play()
            ActiveTabBtn = TabBtn
        end)

        TabBtn.MouseEnter:Connect(function()
            if TabBtn ~= ActiveTabBtn then
                PlaySound(Sounds.Hover, 0.2)
                TweenService:Create(TabBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.5, BackgroundColor3 = Theme.CardHover}):Play()
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if TabBtn ~= ActiveTabBtn then
                TweenService:Create(TabBtn, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
            end
        end)

        Tabs[id] = TabBtn
        Pages[id] = Page
        return Page
    end

    local function AddToggle(page, text, stateKey, callback)
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 45)
        Card.BackgroundColor3 = Theme.Card
        Card.LayoutOrder = nextOrder()
        Card.Parent = page
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 8)

        local Stroke = Instance.new("UIStroke")
        Stroke.Color = Theme.Accent
        Stroke.Thickness = 1
        Stroke.Transparency = 1
        Stroke.Parent = Card

        Card.MouseEnter:Connect(function()
            TweenService:Create(Card, TweenInfo.new(0.2), {BackgroundColor3 = Theme.CardHover}):Play()
            TweenService:Create(Stroke, TweenInfo.new(0.2), {Transparency = 0.5}):Play()
        end)
        Card.MouseLeave:Connect(function()
            TweenService:Create(Card, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Card}):Play()
            TweenService:Create(Stroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
        end)

        local Lbl = Instance.new("TextLabel")
        Lbl.Size = UDim2.new(1, -70, 1, 0)
        Lbl.Position = UDim2.new(0, 10, 0, 0)
        Lbl.BackgroundTransparency = 1
        Lbl.Font = Enum.Font.GothamMedium
        Lbl.TextSize = 12
        Lbl.TextColor3 = Theme.Text
        Lbl.Text = text
        Lbl.TextXAlignment = Enum.TextXAlignment.Left
        Lbl.Parent = Card

        local Pill = Instance.new("TextButton")
        Pill.Size = UDim2.new(0, 44, 0, 24)
        Pill.Position = UDim2.new(1, -54, 0.5, -12)
        Pill.BackgroundColor3 = Core.State[stateKey] and Theme.Success or Theme.Sidebar
        Pill.Text = ""
        Pill.AutoButtonColor = false
        Pill.Parent = Card
        Instance.new("UICorner", Pill).CornerRadius = UDim.new(1, 0)

        local Knob = Instance.new("Frame")
        Knob.Size = UDim2.new(0, 18, 0, 18)
        Knob.Position = Core.State[stateKey] and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        Knob.BackgroundColor3 = Theme.Text
        Knob.Parent = Pill
        Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

        Pill.MouseButton1Click:Connect(function()
            PlaySound(Sounds.Click, 0.4)
            Core.State[stateKey] = not Core.State[stateKey]
            local isOn = Core.State[stateKey]
            TweenService:Create(Pill, TweenInfo.new(0.3, Enum.EasingStyle.Back), {BackgroundColor3 = isOn and Theme.Success or Theme.Sidebar}):Play()
            TweenService:Create(Knob, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = isOn and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)}):Play()
            if callback then callback(isOn) end
        end)
    end

    local function AddButton(page, text, callback)
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(1, 0, 0, 40)
        Btn.BackgroundColor3 = Theme.Accent
        Btn.Font = Enum.Font.GothamBold
        Btn.TextSize = 12
        Btn.TextColor3 = Theme.Background
        Btn.AutoButtonColor = false
        Btn.Text = text
        Btn.LayoutOrder = nextOrder()
        Btn.Parent = page
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)

        Btn.MouseEnter:Connect(function()
            PlaySound(Sounds.Hover, 0.2)
            TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.AccentGlow}):Play()
        end)
        Btn.MouseLeave:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Accent}):Play()
        end)
        Btn.MouseButton1Click:Connect(function()
            PlaySound(Sounds.Click, 0.4)
            TweenService:Create(Btn, TweenInfo.new(0.08), {BackgroundColor3 = Theme.Sidebar}):Play()
            task.delay(0.12, function() TweenService:Create(Btn, TweenInfo.new(0.12), {BackgroundColor3 = Theme.Accent}):Play() end)
            callback()
        end)
    end

    local function AddInput(page, text, configKey, default, callback)
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 45)
        Card.BackgroundColor3 = Theme.Card
        Card.LayoutOrder = nextOrder()
        Card.Parent = page
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 8)

        local Lbl = Instance.new("TextLabel")
        Lbl.Size = UDim2.new(0.6, 0, 1, 0)
        Lbl.Position = UDim2.new(0, 10, 0, 0)
        Lbl.BackgroundTransparency = 1
        Lbl.Font = Enum.Font.GothamMedium
        Lbl.TextSize = 12
        Lbl.TextColor3 = Theme.SubText
        Lbl.Text = text
        Lbl.TextXAlignment = Enum.TextXAlignment.Left
        Lbl.Parent = Card

        local Box = Instance.new("TextBox")
        Box.Size = UDim2.new(0, 60, 0, 28)
        Box.Position = UDim2.new(1, -70, 0.5, -14)
        Box.BackgroundColor3 = Theme.Sidebar
        Box.Font = Enum.Font.GothamBold
        Box.TextSize = 12
        Box.TextColor3 = Theme.AccentGlow
        Box.Text = tostring(Core.Config[configKey] or default)
        Box.Parent = Card
        Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)
        
        local BoxStroke = Instance.new("UIStroke")
        BoxStroke.Color = Theme.Accent
        BoxStroke.Thickness = 1
        BoxStroke.Transparency = 0.7
        BoxStroke.Parent = Box

        Box.Focused:Connect(function() TweenService:Create(BoxStroke, TweenInfo.new(0.15), {Transparency = 0.2}):Play() end)
        Box.FocusLost:Connect(function()
            TweenService:Create(BoxStroke, TweenInfo.new(0.15), {Transparency = 0.7}):Play()
            local v = tonumber(Box.Text)
            if v then Core.Config[configKey] = v; if callback then callback(v) end
            else Box.Text = tostring(Core.Config[configKey]) end
        end)
    end

    local function AddStringInput(page, text, configKey, placeholder, callback)
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 45)
        Card.BackgroundColor3 = Theme.Card
        Card.LayoutOrder = nextOrder()
        Card.Parent = page
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 8)

        local Lbl = Instance.new("TextLabel")
        Lbl.Size = UDim2.new(0.4, 0, 1, 0)
        Lbl.Position = UDim2.new(0, 10, 0, 0)
        Lbl.BackgroundTransparency = 1
        Lbl.Font = Enum.Font.GothamMedium
        Lbl.TextSize = 12
        Lbl.TextColor3 = Theme.SubText
        Lbl.Text = text
        Lbl.TextXAlignment = Enum.TextXAlignment.Left
        Lbl.Parent = Card

        local Box = Instance.new("TextBox")
        Box.Size = UDim2.new(0, 150, 0, 28)
        Box.Position = UDim2.new(1, -160, 0.5, -14)
        Box.BackgroundColor3 = Theme.Sidebar
        Box.Font = Enum.Font.GothamSemibold
        Box.TextSize = 10
        Box.TextColor3 = Theme.AccentGlow
        Box.PlaceholderText = placeholder
        Box.PlaceholderColor3 = Theme.SubText
        Box.Text = tostring(Core.Config[configKey] or "")
        Box.Parent = Card
        Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)

        Box.FocusLost:Connect(function()
            Core.Config[configKey] = Box.Text
            if callback then callback(Box.Text) end
        end)
    end

    local function AddDropdown(page, text, options, configKey)
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 45)
        Card.BackgroundColor3 = Theme.Card
        Card.LayoutOrder = nextOrder()
        Card.Parent = page
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 8)

        local Lbl = Instance.new("TextLabel")
        Lbl.Size = UDim2.new(0, 120, 1, 0)
        Lbl.Position = UDim2.new(0, 10, 0, 0)
        Lbl.BackgroundTransparency = 1
        Lbl.Font = Enum.Font.GothamMedium
        Lbl.TextSize = 12
        Lbl.TextColor3 = Theme.Text
        Lbl.Text = text
        Lbl.TextXAlignment = Enum.TextXAlignment.Left
        Lbl.Parent = Card

        local Sel = Instance.new("TextButton")
        Sel.Size = UDim2.new(0, 130, 0, 28)
        Sel.Position = UDim2.new(1, -140, 0.5, -14)
        Sel.BackgroundColor3 = Theme.Sidebar
        Sel.Font = Enum.Font.GothamSemibold
        Sel.TextSize = 10
        Sel.TextColor3 = Theme.AccentGlow
        Sel.AutoButtonColor = false
        Sel.Parent = Card
        Instance.new("UICorner", Sel).CornerRadius = UDim.new(0, 6)

        local idx = 1
        for i, v in ipairs(options) do if v == Core.Config[configKey] then idx = i break end end
        Sel.Text = (options[idx] or "Select...") .. " ▸"

        Sel.MouseButton1Click:Connect(function()
            PlaySound(Sounds.Click, 0.4)
            if #options == 0 then return end
            idx = idx % #options + 1
            Core.Config[configKey] = options[idx]
            Sel.Text = options[idx] .. " ▸"
        end)

        return function(newOpts)
            options = newOpts
            if #options > 0 then
                idx = math.clamp(idx, 1, #options)
                Core.Config[configKey] = options[idx]
                Sel.Text = options[idx] .. " ▸"
            end
        end
    end

    local function AddSectionLabel(page, text)
        local Lbl = Instance.new("TextLabel")
        Lbl.Size = UDim2.new(1, 0, 0, 20)
        Lbl.BackgroundTransparency = 1
        Lbl.Font = Enum.Font.GothamBold
        Lbl.TextSize = 11
        Lbl.TextColor3 = Theme.AccentGlow
        Lbl.TextXAlignment = Enum.TextXAlignment.Left
        Lbl.Text = string.upper(text)
        Lbl.LayoutOrder = nextOrder()
        Lbl.Parent = page
    end

    -- ============================================================
    -- PAGES & FEATURES
    -- ============================================================
    local PageESP      = CreateTab("ESP",      "ESP Visuals")
    local PagePlayer   = CreateTab("Player",   "Player Mods")
    local PageTroll    = CreateTab("Troll",    "Troll & Combat")
    local PageFarm     = CreateTab("Farm",     "Auto-Farm")
    local PageTeleport = CreateTab("Teleport", "Teleports")
    local PageWorld    = CreateTab("World",    "World & Camera")
    local PageSettings = CreateTab("Settings", "Settings")
    local PageExecutor = CreateTab("Executor", "Script Executor")

    -- ESP
    AddSectionLabel(PageESP, "Master Control")
    AddToggle(PageESP, "Enable Master ESP", "ESP_Enabled", function(v) ToggleESP(v) end)
    AddSectionLabel(PageESP, "Role Filters")
    AddToggle(PageESP, "Murderer ESP", "MurdererESP")
    AddToggle(PageESP, "Sheriff ESP", "SheriffESP")
    AddToggle(PageESP, "Innocent ESP", "InnocentESP")
    AddToggle(PageESP, "Scammer ESP", "ScammerESP")
    AddSectionLabel(PageESP, "Extras")
    AddToggle(PageESP, "Dropped Gun ESP", "GunESP")
    AddToggle(PageESP, "Name & Dist Tags", "NameESP")

    -- Player
    AddSectionLabel(PagePlayer, "Movement")
    AddToggle(PagePlayer, "Custom WalkSpeed", "WalkSpeed", function(v) if not v and LocalPlayer.Character then LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16 end end)
    AddInput(PagePlayer, "WalkSpeed Value", "WalkSpeedValue", 32)
    AddToggle(PagePlayer, "Custom JumpPower", "JumpPower", function(v) if not v and LocalPlayer.Character then LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = 50 end end)
    AddInput(PagePlayer, "JumpPower Value", "JumpPowerValue", 70)
    AddSectionLabel(PagePlayer, "Flight")
    AddToggle(PagePlayer, "Enable Fly", "Fly", function(v) ToggleFly(v) end)
    AddInput(PagePlayer, "Fly Speed", "FlySpeedValue", 50)
    AddSectionLabel(PagePlayer, "Misc")
    AddToggle(PagePlayer, "Noclip", "NoClip")
    AddToggle(PagePlayer, "Infinite Jump", "InfJump")
    AddToggle(PagePlayer, "Anti-Fling", "AntiFling")

    -- Troll
    local function getPlayers()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(list, p.Name) end end
        if #list == 0 then table.insert(list, "No Players") end
        return list
    end
    AddSectionLabel(PageTroll, "Target")
    local updateTarget = AddDropdown(PageTroll, "Select Target", getPlayers(), "SelectedTarget")
    Players.PlayerAdded:Connect(function() updateTarget(getPlayers()) end)
    Players.PlayerRemoving:Connect(function() updateTarget(getPlayers()) end)
    AddButton(PageTroll, "Refresh List", function() updateTarget(getPlayers()) end)

    AddSectionLabel(PageTroll, "Actions")
    AddButton(PageTroll, "Fling Target", function() FlingTarget(Core.Config.SelectedTarget) end)
    AddToggle(PageTroll, "Attach to Target", "AttachPlayer", function(v) ToggleAttach(v) end)
    AddToggle(PageTroll, "Touch Fling", "TouchFling", function(v) ToggleTouchFling(v) end)
    
    -- Trade Scammer
    AddSectionLabel(PageTroll, "Trade Scammer")
    AddDropdown(PageTroll, "Fake Item", {"Chroma Darkbringer", "Corrupt", "Chroma Lightbringer", "Elderwood Scythe", "Batwing"}, "FakeTradeItem")
    AddToggle(PageTroll, "Enable Trade Scam", "TradeScammer", function(v) ToggleTradeScammer(v) end)

    AddSectionLabel(PageTroll, "Combat")
    AddToggle(PageTroll, "Kill Aura", "KillAura", function(v) ToggleKillAura(v) end)
    AddToggle(PageTroll, "Silent Aim", "SilentAim", function(v) ToggleSilentAim(v) end)
    AddToggle(PageTroll, "Hitbox Expander", "HitboxExpander", function(v) ToggleHitbox(v) end)
    AddInput(PageTroll, "Hitbox Size", "HitboxSize", 8)

    AddSectionLabel(PageTroll, "Emotes")
    AddDropdown(PageTroll, "Select Emote", {"Floss", "Zen", "Dab", "Sit", "Hero"}, "SelectedEmote")
    AddButton(PageTroll, "Play Emote", function()
        pcall(function()
            if ReplicatedStorage:FindFirstChild("PlayEmote") then ReplicatedStorage.PlayEmote:FireServer(Core.Config.SelectedEmote) end
        end)
    end)

    -- Farm
    AddSectionLabel(PageFarm, "Coin Farming")
    AddToggle(PageFarm, "Enable Auto-Farm", "AutoCoin", function(v) ToggleAutoCoin(v) end)
    AddInput(PageFarm, "Farm Speed", "FarmSpeed", 22)
    AddSectionLabel(PageFarm, "Webhook")
    AddStringInput(PageFarm, "Webhook URL", "WebhookURL", "https://discord...")

    -- Teleport
    AddSectionLabel(PageTeleport, "Quick Actions")
    AddButton(PageTeleport, "Grab Dropped Gun", GrabGun)
    AddButton(PageTeleport, "TP to Murderer", function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and getRole(p) == "Murderer" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                TeleportToCFrame(p.Character.HumanoidRootPart.CFrame) break
            end
        end
    end)
    AddButton(PageTeleport, "TP to Sheriff", function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and getRole(p) == "Sheriff" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                TeleportToCFrame(p.Character.HumanoidRootPart.CFrame) break
            end
        end
    end)

    -- World
    AddSectionLabel(PageWorld, "Lighting")
    AddToggle(PageWorld, "Fullbright", "GodBright", function(v)
        Lighting.Brightness = v and 3 or OriginalLighting.Brightness
        Lighting.ClockTime  = v and 12 or OriginalLighting.ClockTime
    end)
    AddToggle(PageWorld, "FPS Boost", "FPSBoost", function(v) ToggleFPSBoost(v) end)
    AddInput(PageWorld, "Camera FOV", "FovValue", 70, function(val) Workspace.CurrentCamera.FieldOfView = val end)
    AddSectionLabel(PageWorld, "Camera")
    AddToggle(PageWorld, "Freecam", "Freecam", function(v) ToggleFreecam(v) end)
    AddToggle(PageWorld, "Radar", "Radar", function(v) ToggleRadar(v) end)

    -- Settings
    AddSectionLabel(PageSettings, "Auto-Execute")
    AddStringInput(PageSettings, "Auto-Script", "AutoExecScript", "print('Loaded')")
    AddButton(PageSettings, "Run Script", function()
        local f, e = loadstring(Core.Config.AutoExecScript)
        if f then task.spawn(f); SendNotification("Auto-Script", "Executed!", 2.5) else SendNotification("Error", tostring(e), 3) end
    end)

    -- Executor
    AddSectionLabel(PageExecutor, "Custom Script")
    local ExecWrap = Instance.new("Frame")
    ExecWrap.Size = UDim2.new(1, 0, 0, 250) -- Mobilde yer kaplamaması için boyut düşürüldü
    ExecWrap.BackgroundColor3 = Theme.Card
    ExecWrap.LayoutOrder = nextOrder()
    ExecWrap.Parent = PageExecutor
    Instance.new("UICorner", ExecWrap).CornerRadius = UDim.new(0, 8)
    
    local ExecStroke = Instance.new("UIStroke")
    ExecStroke.Color = Theme.Accent
    ExecStroke.Thickness = 1
    ExecStroke.Transparency = 0.6
    ExecStroke.Parent = ExecWrap

    local ExecBox = Instance.new("TextBox")
    ExecBox.Size = UDim2.new(1, -20, 1, -20) 
    ExecBox.Position = UDim2.new(0, 10, 0, 10)
    ExecBox.BackgroundTransparency = 1
    ExecBox.Font = Enum.Font.Code
    ExecBox.TextSize = 13
    ExecBox.TextColor3 = Theme.Text
    ExecBox.PlaceholderText = "-- Hoha Executor\nprint('Hello!')"
    ExecBox.PlaceholderColor3 = Theme.SubText
    ExecBox.MultiLine = true
    ExecBox.ClearTextOnFocus = false
    ExecBox.TextXAlignment = Enum.TextXAlignment.Left
    ExecBox.TextYAlignment = Enum.TextYAlignment.Top
    ExecBox.Parent = ExecWrap

    AddButton(PageExecutor, "Execute Script", function()
        local f, e = loadstring(ExecBox.Text)
        if f then task.spawn(f); SendNotification("Executor", "Executed!", 2.5) else SendNotification("Error", tostring(e), 3) end
    end)
    AddButton(PageExecutor, "Clear", function() ExecBox.Text = "" end)

    Tabs["ESP"].TextColor3 = Theme.Text
    Tabs["ESP"].BackgroundTransparency = 0
    Tabs["ESP"].BackgroundColor3 = Theme.Card
    Pages["ESP"].Visible = true
    SelectionFrame.Position = UDim2.new(0, 0, 0, 15)

    SendNotification("System", "Mobile Loaded! Tap 'H' to toggle.", 4)
end

-- ============================================================
-- KEY SYSTEM & LOADING (Mobil İçin Düzenlendi)
-- ============================================================
function ShowKeyGUI()
    local KeyGui = Instance.new("ScreenGui")
    KeyGui.Name = "HohaKeySystem"
    KeyGui.ResetOnSpawn = false
    KeyGui.Parent = CoreGui

    local KeyFrame = Instance.new("Frame")
    KeyFrame.Size = UDim2.new(0, 300, 0, 200)
    KeyFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
    KeyFrame.BackgroundColor3 = Theme.Background
    KeyFrame.BorderSizePixel = 0
    KeyFrame.Parent = KeyGui
    Instance.new("UICorner", KeyFrame).CornerRadius = UDim.new(0, 14)

    local KS = Instance.new("UIStroke")
    KS.Color = Theme.Accent
    KS.Thickness = 1.6
    KS.Parent = KeyFrame

    local KeyTitle = Instance.new("TextLabel")
    KeyTitle.Size = UDim2.new(1, 0, 0, 36)
    KeyTitle.Position = UDim2.new(0, 0, 0, 14)
    KeyTitle.BackgroundTransparency = 1
    KeyTitle.Font = Enum.Font.GothamBold
    KeyTitle.TextSize = 16
    KeyTitle.TextColor3 = Theme.Text
    KeyTitle.Text = "🔑 Hoha's Key"
    KeyTitle.Parent = KeyFrame

    local KeyInput = Instance.new("TextBox")
    KeyInput.Size = UDim2.new(0.88, 0, 0, 36)
    KeyInput.Position = UDim2.new(0.06, 0, 0, 62)
    KeyInput.BackgroundColor3 = Theme.Sidebar
    KeyInput.Font = Enum.Font.GothamSemibold
    KeyInput.TextSize = 12
    KeyInput.TextColor3 = Theme.Text
    KeyInput.PlaceholderText = "Paste your key..."
    KeyInput.PlaceholderColor3 = Theme.SubText
    KeyInput.Text = "Get Key: https://key-sys.lovable.app/get/74598e3db6"
    KeyInput.ClearTextOnFocus = false
    KeyInput.Parent = KeyFrame
    Instance.new("UICorner", KeyInput).CornerRadius = UDim.new(0, 8)
    
    local KIS = Instance.new("UIStroke")
    KIS.Color = Theme.Accent
    KIS.Thickness = 1
    KIS.Transparency = 0.6
    KIS.Parent = KeyInput

    local StatusLbl = Instance.new("TextLabel")
    StatusLbl.Size = UDim2.new(1, 0, 0, 18)
    StatusLbl.Position = UDim2.new(0, 0, 0, 104)
    StatusLbl.BackgroundTransparency = 1
    StatusLbl.Font = Enum.Font.GothamMedium
    StatusLbl.TextSize = 11
    StatusLbl.TextColor3 = Theme.SubText
    StatusLbl.Parent = KeyFrame

    local VerifyBtn = Instance.new("TextButton")
    VerifyBtn.Size = UDim2.new(0.88, 0, 0, 36)
    VerifyBtn.Position = UDim2.new(0.06, 0, 0, 126)
    VerifyBtn.BackgroundColor3 = Theme.Accent
    VerifyBtn.Font = Enum.Font.GothamBold
    VerifyBtn.TextSize = 12
    VerifyBtn.TextColor3 = Theme.Text
    VerifyBtn.Text = "Verify Key"
    VerifyBtn.AutoButtonColor = false
    VerifyBtn.Parent = KeyFrame
    Instance.new("UICorner", VerifyBtn).CornerRadius = UDim.new(0, 8)

    local isVerifying = false

    VerifyBtn.MouseButton1Click:Connect(function()
        if isVerifying then return end
        local key = KeyInput.Text:gsub("%s+", "")
        if key == "" then
            StatusLbl.TextColor3 = Theme.Danger
            StatusLbl.Text = "Please enter a valid key."
            return
        end
        isVerifying = true
        StatusLbl.TextColor3 = Theme.SubText
        StatusLbl.Text = "Verifying..."
        TweenService:Create(VerifyBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.CardHover}):Play()

        task.spawn(function()
            local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
            local url = "https://key-sys.lovable.app/api/public/verify?project=74598e3db6&key=" .. HttpService:UrlEncode(key) .. "&hwid=" .. HttpService:UrlEncode(hwid)

            local ok, res = pcall(function() return game:HttpGet(url) end)
            if not ok then
                StatusLbl.TextColor3 = Theme.Danger
                StatusLbl.Text = "Server unreachable."
                TweenService:Create(VerifyBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Accent}):Play()
                isVerifying = false
                return
            end

            local jok, data = pcall(function() return HttpService:JSONDecode(res) end)
            if not jok then
                StatusLbl.TextColor3 = Theme.Danger
                StatusLbl.Text = "Bad response."
                TweenService:Create(VerifyBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Accent}):Play()
                isVerifying = false
                return
            end

            if data.status == "valid" then
                StatusLbl.TextColor3 = Theme.Success
                StatusLbl.Text = "Key verified! Loading..."
                TweenService:Create(VerifyBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Success}):Play()
                task.wait(0.9)
                if KeyGui and KeyGui.Parent then KeyGui:Destroy() end
                BuildMainGUI()
            else
                StatusLbl.TextColor3 = Theme.Danger
                StatusLbl.Text = "Key rejected: " .. tostring(data.status)
                TweenService:Create(VerifyBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Accent}):Play()
                isVerifying = false
            end
        end)
    end)
end

local LoadGui = Instance.new("ScreenGui")
LoadGui.Name = "HohaLoadingGui"
LoadGui.ResetOnSpawn = false
LoadGui.Parent = CoreGui

local LoadFrame = Instance.new("Frame")
LoadFrame.Size = UDim2.new(0, 280, 0, 130)
LoadFrame.Position = UDim2.new(0.5, -140, 0.5, -65)
LoadFrame.BackgroundColor3 = Theme.Background
LoadFrame.BorderSizePixel = 0
LoadFrame.Parent = LoadGui
Instance.new("UICorner", LoadFrame).CornerRadius = UDim.new(0, 14)

local LFS = Instance.new("UIStroke")
LFS.Color = Theme.Accent
LFS.Thickness = 2
LFS.Parent = LoadFrame

local LoadTitle = Instance.new("TextLabel")
LoadTitle.Size = UDim2.new(1, 0, 0, 42)
LoadTitle.Position = UDim2.new(0, 0, 0, 16)
LoadTitle.BackgroundTransparency = 1
LoadTitle.Font = Enum.Font.GothamBold
LoadTitle.TextSize = 16
LoadTitle.TextColor3 = Theme.Accent
LoadTitle.Text = "Hoha MM2 Mobile"
LoadTitle.Parent = LoadFrame

local BarBg = Instance.new("Frame")
BarBg.Size = UDim2.new(0.85, 0, 0, 6)
BarBg.Position = UDim2.new(0.075, 0, 0, 72)
BarBg.BackgroundColor3 = Theme.Card
BarBg.Parent = LoadFrame
Instance.new("UICorner", BarBg).CornerRadius = UDim.new(1, 0)

local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Theme.Accent
BarFill.Parent = BarBg
Instance.new("UICorner", BarFill).CornerRadius = UDim.new(1, 0)

local LoadStatus = Instance.new("TextLabel")
LoadStatus.Size = UDim2.new(1, 0, 0, 22)
LoadStatus.Position = UDim2.new(0, 0, 0, 90)
LoadStatus.BackgroundTransparency = 1
LoadStatus.Font = Enum.Font.Code
LoadStatus.TextSize = 12
LoadStatus.TextColor3 = Theme.SubText
LoadStatus.Text = ""
LoadStatus.Parent = LoadFrame

local function TypeWrite(label, text, speed)
    for i = 1, #text do
        label.Text = string.sub(text, 1, i)
        task.wait(speed or 0.03)
    end
end

task.spawn(function()
    TypeWrite(LoadStatus, "MOBILE SYNC...")
    TweenService:Create(BarFill, TweenInfo.new(0.5), {Size = UDim2.new(0.5, 0, 1, 0)}):Play()
    task.wait(0.6)
    TypeWrite(LoadStatus, "LOADING...")
    TweenService:Create(BarFill, TweenInfo.new(0.5), {Size = UDim2.new(1, 0, 1, 0)}):Play()
    task.wait(0.5)
    LoadGui:Destroy()
    ShowKeyGUI()
end)

RunService.Stepped:Connect(function()
    local myChar = LocalPlayer.Character
    if not myChar then return end

    if Core.State.NoClip then
        for _, part in ipairs(myChar:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    if Core.State.AntiFling then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _, part in ipairs(p.Character:GetChildren()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end
    end

    local hum = myChar:FindFirstChildOfClass("Humanoid")
    if hum then
        if Core.State.WalkSpeed then hum.WalkSpeed = tonumber(Core.Config.WalkSpeedValue) or 16 end
        if Core.State.JumpPower then hum.JumpPower = tonumber(Core.Config.JumpPowerValue) or 50; hum.UseJumpPower = true end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if Core.State.InfJump then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

end, "HohaScriptWrapper")
