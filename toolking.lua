-- سكريبت: الطيران العلوي (Y = 125) + أولوية الأبعد + سرعة 600
local player = game.Players.LocalPlayer
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")

-- 1. الجزر المستهدفة (مرتبة من الأبعد إلى الأقرب)
local targetIslands = {
    { name = "Celestial", pos = Vector3.new(4164.5, 10.0, 0.0), distance = 4164.5 },
    { name = "Secret3", pos = Vector3.new(3853.0, 10.0, 0.0), distance = 3853.0 },
    { name = "Secret2", pos = Vector3.new(3490.0, 10.0, 0.0), distance = 3490.0 },
    { name = "Secret1", pos = Vector3.new(3135.0, 10.0, 0.0), distance = 3135.0 }
}

-- 2. البحث عن Blarant (الأبعد أولاً)
local function findBestBlarant()
    for _, island in ipairs(targetIslands) do
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Part") and not obj.Anchored and not obj.CanCollide then
                if (obj.Position - island.pos).Magnitude < 150 then
                    return obj, island.name
                end
            end
        end
    end
    return nil, nil
end

-- 3. الصعود/النزول العمودي
local function changeHeight(targetY, speed, onComplete)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local startY = hrp.Position.Y
    local distance = math.abs(targetY - startY)
    local duration = math.min(distance / speed, 2)
    
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = tweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(hrp.Position.X, targetY, hrp.Position.Z)})
    tween:Play()
    if onComplete then
        tween.Completed:Connect(onComplete)
    end
    return tween
end

-- 4. الطيران الأفقي
local function flyHorizontal(targetPos, speed, onComplete)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local target = Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)
    local distance = (target - hrp.Position).Magnitude
    local duration = math.min(distance / speed, 5)
    
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = tweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(target)})
    tween:Play()
    if onComplete then
        tween.Completed:Connect(onComplete)
    end
    return tween
end

-- 5. واجهة التحكم
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SkyFlyerPro"
screenGui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 140)
frame.Position = UDim2.new(0.5, -140, 0.7, 0)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.5
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(0, 200, 255)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local startButton = Instance.new("TextButton")
startButton.Size = UDim2.new(0, 100, 0, 40)
startButton.Position = UDim2.new(0.05, 0, 0.2, 0)
startButton.Text = "▶ تشغيل"
startButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
startButton.TextColor3 = Color3.fromRGB(0, 0, 0)
startButton.Font = Enum.Font.GothamBold
startButton.TextSize = 12
startButton.Parent = frame

local stopButton = Instance.new("TextButton")
stopButton.Size = UDim2.new(0, 100, 0, 40)
stopButton.Position = UDim2.new(0.55, 0, 0.2, 0)
stopButton.Text = "⏹ إيقاف (عودة)"
stopButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopButton.Font = Enum.Font.GothamBold
stopButton.TextSize = 12
stopButton.Parent = frame

local speedUp = Instance.new("TextButton")
speedUp.Size = UDim2.new(0, 40, 0, 40)
speedUp.Position = UDim2.new(0.05, 0, 0.65, 0)
speedUp.Text = "+"
speedUp.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
speedUp.TextColor3 = Color3.fromRGB(255, 255, 255)
speedUp.Font = Enum.Font.GothamBold
speedUp.TextSize = 18
speedUp.Parent = frame

local speedDown = Instance.new("TextButton")
speedDown.Size = UDim2.new(0, 40, 0, 40)
speedDown.Position = UDim2.new(0.25, 0, 0.65, 0)
speedDown.Text = "-"
speedDown.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
speedDown.TextColor3 = Color3.fromRGB(255, 255, 255)
speedDown.Font = Enum.Font.GothamBold
speedDown.TextSize = 18
speedDown.Parent = frame

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0, 80, 0, 30)
speedLabel.Position = UDim2.new(0.6, 0, 0.7, 0)
speedLabel.Text = "سرعة: 600"
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
speedLabel.TextSize = 12
speedLabel.Font = Enum.Font.GothamBold
speedLabel.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 260, 0, 20)
statusLabel.Position = UDim2.new(0.5, -130, 0, 5)
statusLabel.Text = "✈️ طيران علوي (Y = 125) + أولوية الأبعد"
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
statusLabel.TextSize = 10
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = frame

-- 6. منطق التشغيل
local currentSpeed = 600  -- ✅ سرعة ابتدائية 600
local active = false
local startPos = nil
local currentTween = nil

speedLabel.Text = "سرعة: " .. currentSpeed

speedUp.MouseButton1Click:Connect(function()
    currentSpeed = currentSpeed + 100
    speedLabel.Text = "سرعة: " .. currentSpeed
end)

speedDown.MouseButton1Click:Connect(function()
    currentSpeed = math.max(100, currentSpeed - 100)
    speedLabel.Text = "سرعة: " .. currentSpeed
end)

-- تشغيل (ذهاب)
startButton.MouseButton1Click:Connect(function()
    if active then return end
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    startPos = hrp.Position
    local blarant, islandName = findBestBlarant()
    if not blarant then
        statusLabel.Text = "❌ لا يوجد Blarant"
        return
    end
    
    active = true
    statusLabel.Text = "📈 الصعود إلى Y = 125 (هدف: " .. islandName .. ")..."
    
    changeHeight(125, currentSpeed, function()  -- ✅ Y = 125
        if not active then return end
        statusLabel.Text = "✈️ الطيران إلى " .. islandName .. "..."
        
        flyHorizontal(blarant.Position, currentSpeed, function()
            if not active then return end
            statusLabel.Text = "🪂 النزول إلى Blarant..."
            
            changeHeight(blarant.Position.Y + 3, currentSpeed, function()
                if active then
                    statusLabel.Text = "✅ وصلت داخل Blarant (" .. islandName .. ")"
                end
            end)
        end)
    end)
end)

-- إيقاف (عودة)
stopButton.MouseButton1Click:Connect(function()
    if not active then return end
    active = false
    
    if currentTween then currentTween:Cancel() end
    
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not startPos then
        statusLabel.Text = "⚠️ لا يمكن العودة"
        return
    end
    
    statusLabel.Text = "📈 الصعود إلى Y = 125..."
    
    changeHeight(125, currentSpeed, function()  -- ✅ Y = 125
        statusLabel.Text = "✈️ الطيران إلى نقطة البداية..."
        
        flyHorizontal(startPos, currentSpeed, function()
            statusLabel.Text = "🪂 النزول إلى نقطة البداية..."
            
            changeHeight(startPos.Y, currentSpeed, function()
                statusLabel.Text = "🏁 تم العودة"
            end)
        end)
    end)
end)

print("✅ السكريبت المتطور يعمل - الأولوية للأبعد (Celestial أولاً) + Y = 125 + سرعة 600")
