-- ============================================
-- 🎮 COMPLETE RESOURCE MANAGER - تحكم كامل
-- للهاتف: loadstring(game:HttpGet(""))()
-- ============================================

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

print("🎮 COMPLETE RESOURCE MANAGER LOADING...")

-- قاعدة بيانات شاملة لكل الموارد
local RESOURCES = {
    CURRENCY = {},      -- عملات، ذهب، نقاط
    TOOLS = {},         -- أدوات وأسلحة
    ITEMS = {},         -- عناصر مختلفة
    MATERIALS = {},     -- مواد خام
    CONSUMABLES = {},   -- مشروبات، طعام
    UPGRADES = {},      -- ترقيات
    KEYS = {},          -- مفاتيح
    GEMS = {},          -- أحجار كريمة
    COLLECTIBLES = {},  -- مقتنيات
    SPECIAL = {}        -- أشياء خاصة
}

-- مسح شامل لكل الموارد في اللعبة
function SCAN_EVERY_RESOURCE()
    print("🔍 Scanning EVERY resource in the map...")
    
    -- إعادة تهيئة
    for category, _ in pairs(RESOURCES) do
        RESOURCES[category] = {}
    end
    
    local foundCount = 0
    
    -- 1. مسح workspace للعثور على كل الأشياء
    for _, obj in pairs(workspace:GetDescendants()) do
        -- تصنيف الأشياء حسب الاسم والنوع
        local nameLower = obj.Name:lower()
        local className = obj.ClassName
        
        -- العملات (Coins, Gold, Cash, etc.)
        if (nameLower:find("coin") or nameLower:find("gold") or nameLower:find("cash") or 
            nameLower:find("money") or nameLower:find("gem") or nameLower:find("point")) and
            not obj:IsA("Model") then
            
            local value = 1
            if obj:IsA("IntValue") or obj:IsA("NumberValue") then
                value = obj.Value
            end
            
            table.insert(RESOURCES.CURRENCY, {
                Name = obj.Name,
                Type = className,
                Value = value,
                Object = obj,
                Path = obj:GetFullName(),
                CanIncrease = true
            })
            foundCount = foundCount + 1
            
        -- الأدوات (Tools, Weapons)
        elseif obj:IsA("Tool") or nameLower:find("sword") or nameLower:find("gun") or 
               nameLower:find("weapon") or nameLower:find("tool") then
            
            table.insert(RESOURCES.TOOLS, {
                Name = obj.Name,
                Type = className,
                Object = obj,
                Path = obj:GetFullName(),
                CanIncrease = true
            })
            foundCount = foundCount + 1
            
        -- المواد (Materials, Resources)
        elseif nameLower:find("wood") or nameLower:find("stone") or nameLower:find("iron") or
               nameLower:find("metal") or nameLower:find("crystal") or nameLower:find("ore") then
            
            local value = 1
            if obj:IsA("IntValue") then
                value = obj.Value
            end
            
            table.insert(RESOURCES.MATERIALS, {
                Name = obj.Name,
                Type = className,
                Value = value,
                Object = obj,
                Path = obj:GetFullName(),
                CanIncrease = true
            })
            foundCount = foundCount + 1
            
        -- العناصر الأخرى (Items)
        elseif obj:IsA("Part") and (obj:FindFirstChildOfClass("ClickDetector") or 
               obj:FindFirstChildOfClass("ProximityPrompt")) then
            
            table.insert(RESOURCES.ITEMS, {
                Name = obj.Name,
                Type = className,
                Object = obj,
                Path = obj:GetFullName(),
                CanIncrease = false
            })
            foundCount = foundCount + 1
        end
    end
    
    -- 2. مسح ReplicatedStorage
    if game:FindFirstChild("ReplicatedStorage") then
        for _, obj in pairs(game.ReplicatedStorage:GetDescendants()) do
            local nameLower = obj.Name:lower()
            
            if obj:IsA("NumberValue") or obj:IsA("IntValue") or obj:IsA("StringValue") then
                if nameLower:find("coin") or nameLower:find("gold") or nameLower:find("cash") then
                    table.insert(RESOURCES.CURRENCY, {
                        Name = obj.Name,
                        Type = obj.ClassName,
                        Value = obj.Value or 1,
                        Object = obj,
                        Path = obj:GetFullName(),
                        CanIncrease = true
                    })
                    foundCount = foundCount + 1
                end
            end
        end
    end
    
    -- 3. مسح Backpack للاعب
    if localPlayer:FindFirstChild("Backpack") then
        for _, tool in pairs(localPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(RESOURCES.TOOLS, {
                    Name = tool.Name,
                    Type = "Tool",
                    Object = tool,
                    Path = tool:GetFullName(),
                    CanIncrease = true
                })
                foundCount = foundCount + 1
            end
        end
    end
    
    -- 4. مسح PlayerGui للعملات
    if localPlayer:FindFirstChild("PlayerGui") then
        for _, gui in pairs(localPlayer.PlayerGui:GetDescendants()) do
            if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Text then
                local text = gui.Text:lower()
                if text:find("coin") or text:find("gold") or text:find("cash") or 
                   text:find("%d+") then
                    
                    local value = tonumber(string.match(gui.Text, "%d+")) or 1
                    table.insert(RESOURCES.CURRENCY, {
                        Name = gui.Name,
                        Type = gui.ClassName,
                        Value = value,
                        Object = gui,
                        Path = gui:GetFullName(),
                        CanIncrease = true
                    })
                    foundCount = foundCount + 1
                end
            end
        end
    end
    
    -- 5. مسح leaderstats
    if localPlayer:FindFirstChild("leaderstats") then
        for _, stat in pairs(localPlayer.leaderstats:GetChildren()) do
            if tonumber(stat.Value) then
                table.insert(RESOURCES.CURRENCY, {
                    Name = stat.Name,
                    Type = stat.ClassName,
                    Value = stat.Value,
                    Object = stat,
                    Path = stat:GetFullName(),
                    CanIncrease = true
                })
                foundCount = foundCount + 1
            end
        end
    end
    
    print("✅ Found " .. foundCount .. " total resources across all categories")
    
    -- طباعة الإحصائيات
    for category, items in pairs(RESOURCES) do
        if #items > 0 then
            print("   📁 " .. category .. ": " .. #items)
        end
    end
    
    return RESOURCES
end

-- زيادة مورد معين
function INCREASE_RESOURCE(category, index, amount)
    amount = tonumber(amount) or 1
    local resource = RESOURCES[category][index]
    
    if not resource then
        return false, "Resource not found"
    end
    
    if not resource.CanIncrease then
        return false, "Resource cannot be increased"
    end
    
    local success = false
    local message = ""
    
    if resource.Object then
        -- محاولة التعديل المباشر
        if resource.Object:IsA("IntValue") or resource.Object:IsA("NumberValue") then
            resource.Object.Value = resource.Object.Value + amount
            resource.Value = resource.Value + amount
            success = true
            message = "Increased " .. resource.Name .. " by " .. amount
            
        -- إذا كان Tool، نعمل نسخ منه
        elseif resource.Object:IsA("Tool") then
            for i = 1, amount do
                local clone = resource.Object:Clone()
                clone.Parent = localPlayer.Backpack or workspace
            end
            success = true
            message = "Duplicated " .. resource.Name .. " " .. amount .. " times"
            
        -- محاولة طرق أخرى
        else
            success = false
            message = "Cannot modify this type of object"
        end
    else
        success = false
        message = "Object not accessible"
    end
    
    return success, message
end

-- واجهة الهاتف الكاملة
function CREATE_COMPLETE_MOBILE_UI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "CompleteResourceManager"
    gui.ResetOnSpawn = false
    gui.Parent = localPlayer:WaitForChild("PlayerGui")
    
    -- الإطار الرئيسي القابل للسحب
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainPanel"
    mainFrame.Size = UDim2.new(0.95, 0, 0.9, 0)
    mainFrame.Position = UDim2.new(0.025, 0, 0.05, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = gui
    
    -- شريط العنوان للسحب
    local titleBar = Instance.new("TextButton")
    titleBar.Name = "TitleBar"
    titleBar.Text = "🎮 COMPLETE RESOURCE MANAGER - Drag to move"
    titleBar.Size = UDim2.new(1, 0, 0.07, 0)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    titleBar.TextColor3 = Color3.new(1, 1, 1)
    titleBar.Font = Enum.Font.GothamBlack
    titleBar.TextSize = 14
    titleBar.TextScaled = true
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    -- زر المسح
    local scanButton = Instance.new("TextButton")
    scanButton.Text = "🔍 SCAN ALL RESOURCES"
    scanButton.Size = UDim2.new(0.48, 0, 0.06, 0)
    scanButton.Position = UDim2.new(0.01, 0, 0.08, 0)
    scanButton.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
    scanButton.TextColor3 = Color3.new(1, 1, 1)
    scanButton.Font = Enum.Font.GothamBold
    scanButton.TextSize = 12
    scanButton.TextScaled = true
    scanButton.Parent = mainFrame
    
    -- زر نسخ كل الأكواد
    local copyAllButton = Instance.new("TextButton")
    copyAllButton.Text = "📋 COPY ALL CODES"
    copyAllButton.Size = UDim2.new(0.48, 0, 0.06, 0)
    copyAllButton.Position = UDim2.new(0.51, 0, 0.08, 0)
    copyAllButton.BackgroundColor3 = Color3.fromRGB(150, 0, 150)
    copyAllButton.TextColor3 = Color3.new(1, 1, 1)
    copyAllButton.Font = Enum.Font.GothamBold
    copyAllButton.TextSize = 12
    copyAllButton.TextScaled = true
    copyAllButton.Parent = mainFrame
    
    -- تبويبات الفئات
    local tabButtons = {}
    local tabs = {"CURRENCY", "TOOLS", "ITEMS", "MATERIALS", "SPECIAL"}
    local tabColors = {
        CURRENCY = Color3.fromRGB(255, 215, 0),
        TOOLS = Color3.fromRGB(200, 50, 50),
        ITEMS = Color3.fromRGB(0, 150, 200),
        MATERIALS = Color3.fromRGB(0, 150, 0),
        SPECIAL = Color3.fromRGB(150, 0, 150)
    }
    
    for i, tabName in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "Tab_" .. tabName
        tabBtn.Text = tabName
        tabBtn.Size = UDim2.new(0.19, 0, 0.05, 0)
        tabBtn.Position = UDim2.new(0.01 + ((i-1) * 0.20), 0, 0.15, 0)
        tabBtn.BackgroundColor3 = tabColors[tabName]
        tabBtn.TextColor3 = Color3.new(1, 1, 1)
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.TextSize = 10
        tabBtn.TextScaled = true
        tabBtn.Parent = mainFrame
        tabButtons[tabName] = tabBtn
    end
    
    -- منطقة عرض الموارد
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(0.98, 0, 0.75, 0)
    contentFrame.Position = UDim2.new(0.01, 0, 0.21, 0)
    contentFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    contentFrame.BackgroundTransparency = 0.1
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 8
    contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
    contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentFrame.Parent = mainFrame
    
    -- زر الإغلاق
    local closeButton = Instance.new("TextButton")
    closeButton.Text = "✕"
    closeButton.Size = UDim2.new(0.08, 0, 0.07, 0)
    closeButton.Position = UDim2.new(0.92, 0, 0, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.Font = Enum.Font.GothamBlack
    closeButton.TextSize = 16
    closeButton.Parent = mainFrame
    
    -- المتغيرات
    local currentTab = "CURRENCY"
    local resourceFrames = {}
    
    -- وظيفة جعل الإطار قابل للسحب
    local dragging = false
    local dragStart, frameStart
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            frameStart = mainFrame.Position
            
            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    connection:Disconnect()
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                frameStart.X.Scale, 
                frameStart.X.Offset + delta.X,
                frameStart.Y.Scale,
                frameStart.Y.Offset + delta.Y
            )
        end
    end)
    
    -- وظيفة عرض الموارد حسب الفئة
    function DISPLAY_RESOURCES(category)
        currentTab = category
        contentFrame:ClearAllChildren()
        resourceFrames = {}
        
        local resources = RESOURCES[category]
        if not resources or #resources == 0 then
            local noItems = Instance.new("TextLabel")
            noItems.Text = "No resources found in this category.\nPress SCAN button first."
            noItems.Size = UDim2.new(0.9, 0, 0.2, 0)
            noItems.Position = UDim2.new(0.05, 0, 0.4, 0)
            noItems.BackgroundTransparency = 1
            noItems.TextColor3 = Color3.new(1, 1, 0)
            noItems.Font = Enum.Font.GothamBold
            noItems.TextSize = 14
            noItems.TextWrapped = true
            noItems.TextXAlignment = Enum.TextXAlignment.Center
            noItems.Parent = contentFrame
            return
        end
        
        local yOffset = 0
        for index, resource in ipairs(resources) do
            -- إطار لكل مورد
            local resourceFrame = Instance.new("Frame")
            resourceFrame.Name = "Resource_" .. index
            resourceFrame.Size = UDim2.new(0.96, 0, 0, 80)
            resourceFrame.Position = UDim2.new(0.02, 0, 0, yOffset)
            resourceFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
            resourceFrame.BackgroundTransparency = 0.2
            resourceFrame.BorderSizePixel = 0
            resourceFrame.Parent = contentFrame
            
            -- اسم المورد
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Text = "📌 " .. resource.Name
            nameLabel.Size = UDim2.new(0.6, 0, 0.3, 0)
            nameLabel.Position = UDim2.new(0.02, 0, 0.05, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.TextColor3 = Color3.new(1, 1, 1)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 12
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Parent = resourceFrame
            
            -- نوع المورد
            local typeLabel = Instance.new("TextLabel")
            typeLabel.Text = "Type: " .. resource.Type
            typeLabel.Size = UDim2.new(0.6, 0, 0.2, 0)
            typeLabel.Position = UDim2.new(0.02, 0, 0.35, 0)
            typeLabel.BackgroundTransparency = 1
            typeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            typeLabel.Font = Enum.Font.Gotham
            typeLabel.TextSize = 10
            typeLabel.TextXAlignment = Enum.TextXAlignment.Left
            typeLabel.Parent = resourceFrame
            
            -- القيمة الحالية (إذا موجودة)
            if resource.Value then
                local valueLabel = Instance.new("TextLabel")
                valueLabel.Text = "Value: " .. tostring(resource.Value)
                valueLabel.Size = UDim2.new(0.6, 0, 0.2, 0)
                valueLabel.Position = UDim2.new(0.02, 0, 0.55, 0)
                valueLabel.BackgroundTransparency = 1
                valueLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                valueLabel.Font = Enum.Font.GothamBold
                valueLabel.TextSize = 11
                valueLabel.TextXAlignment = Enum.TextXAlignment.Left
                valueLabel.Parent = resourceFrame
            end
            
            -- حقل إدخال الكمية
            local amountBox = Instance.new("TextBox")
            amountBox.Name = "AmountBox"
            amountBox.PlaceholderText = "Amount"
            amountBox.Text = "100"
            amountBox.Size = UDim2.new(0.3, 0, 0.35, 0)
            amountBox.Position = UDim2.new(0.63, 0, 0.3, 0)
            amountBox.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
            amountBox.TextColor3 = Color3.new(1, 1, 1)
            amountBox.Font = Enum.Font.Gotham
            amountBox.TextSize = 12
            amountBox.ClearTextOnFocus = false
            amountBox.Parent = resourceFrame
            
            -- زر الزيادة
            local increaseButton = Instance.new("TextButton")
            increaseButton.Text = "➕ ADD"
            increaseButton.Size = UDim2.new(0.25, 0, 0.35, 0)
            increaseButton.Position = UDim2.new(0.68, 0, 0.3, 0)
            increaseButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
            increaseButton.TextColor3 = Color3.new(1, 1, 1)
            increaseButton.Font = Enum.Font.GothamBold
            increaseButton.TextSize = 11
            increaseButton.Parent = resourceFrame
            
            -- زر نسخ الكود
            local copyButton = Instance.new("TextButton")
            copyButton.Text = "📋"
            copyButton.Size = UDim2.new(0.1, 0, 0.35, 0)
            copyButton.Position = UDim2.new(0.94, 0, 0.3, 0)
            copyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
            copyButton.TextColor3 = Color3.new(1, 1, 1)
            copyButton.Font = Enum.Font.GothamBold
            copyButton.TextSize = 14
            copyButton.Parent = resourceFrame
            
            -- أحداث الأزرار
            increaseButton.MouseButton1Click:Connect(function()
                local amount = tonumber(amountBox.Text) or 100
                local success, msg = INCREASE_RESOURCE(category, index, amount)
                
                -- إظهار رسالة التأكيد
                local notification = Instance.new("TextLabel")
                notification.Text = msg
                notification.Size = UDim2.new(0.9, 0, 0.2, 0)
                notification.Position = UDim2.new(0.05, 0, 0.7, 0)
                notification.BackgroundColor3 = success and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(100, 0, 0)
                notification.TextColor3 = Color3.new(1, 1, 1)
                notification.Font = Enum.Font.GothamBold
                notification.TextSize = 10
                notification.TextWrapped = true
                notification.Parent = resourceFrame
                
                task.wait(2)
                notification:Destroy()
                
                -- تحديث القيمة إذا كانت قابلة للتحديث
                if success and resource.Value and resource.Object and resource.Object:IsA("IntValue") then
                    valueLabel.Text = "Value: " .. tostring(resource.Object.Value)
                end
            end)
            
            copyButton.MouseButton1Click:Connect(function()
                -- إنشاء نص للنسخ
                local copyText = string.format(
                    "Resource: %s\nType: %s\nPath: %s\nCurrent Value: %s\nCommand: INCREASE_RESOURCE('%s', %d, %s)",
                    resource.Name,
                    resource.Type,
                    resource.Path,
                    tostring(resource.Value or "N/A"),
                    category,
                    index,
                    amountBox.Text
                )
                
                -- نسخ إلى الحافظة
                pcall(function()
                    setclipboard(copyText)
                end)
                
                -- إشعار
                copyButton.Text = "✓"
                task.wait(1)
                copyButton.Text = "📋"
            end)
            
            yOffset = yOffset + 85
            table.insert(resourceFrames, resourceFrame)
        end
    end
    
    -- أحداث تبويبات الفئات
    for tabName, tabBtn in pairs(tabButtons) do
        tabBtn.MouseButton1Click:Connect(function()
            -- إعادة تلوين كل الأزرار
            for name, btn in pairs(tabButtons) do
                btn.BackgroundColor3 = tabColors[name]
            end
            
            -- تلوين الزر النشط
            tabBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            tabBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            
            DISPLAY_RESOURCES(tabName)
        end)
    end
    
    -- حدث مسح الموارد
    scanButton.MouseButton1Click:Connect(function()
        scanButton.Text = "⏳ SCANNING..."
        scanButton.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
        
        task.spawn(function()
            SCAN_EVERY_RESOURCE()
            DISPLAY_RESOURCES(currentTab)
            
            scanButton.Text = "🔍 RESCAN"
            scanButton.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
        end)
    end)
    
    -- حدث نسخ كل الأكواد
    copyAllButton.MouseButton1Click:Connect(function()
        local allText = "🎮 COMPLETE RESOURCE CODES\n"
        allText = allText .. "Game: " .. game.Name .. "\n"
        allText = allText .. "Date: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
        allText = allText .. string.rep("=", 50) .. "\n\n"
        
        for category, resources in pairs(RESOURCES) do
            if #resources > 0 then
                allText = allText .. "\n📁 " .. category .. " (" .. #resources .. "):\n"
                allText = allText .. string.rep("-", 40) .. "\n"
                
                for i, resource in ipairs(resources) do
                    allText = allText .. string.format(
                        "%d. %s (%s)\n   Path: %s\n   Value: %s\n   Command: INCREASE_RESOURCE('%s', %d, AMOUNT)\n\n",
                        i, resource.Name, resource.Type, resource.Path,
                        tostring(resource.Value or "N/A"), category, i
                    )
                end
            end
        end
        
        -- عرض للنصوص الطويلة
        local copyGui = Instance.new("ScreenGui")
        copyGui.Parent = localPlayer.PlayerGui
        
        local copyFrame = Instance.new("Frame")
        copyFrame.Size = UDim2.new(0.9, 0, 0.8, 0)
        copyFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
        copyFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
        copyFrame.Parent = copyGui
        
        local copyBox = Instance.new("TextBox")
        copyBox.Text = allText
        copyBox.Size = UDim2.new(0.95, 0, 0.85, 0)
        copyBox.Position = UDim2.new(0.025, 0, 0.05, 0)
        copyBox.MultiLine = true
        copyBox.TextWrapped = false
        copyBox.ClearTextOnFocus = false
        copyBox.BackgroundTransparency = 1
        copyBox.TextColor3 = Color3.new(0, 1, 0)
        copyBox.Font = Enum.Font.Code
        copyBox.TextSize = 11
        copyBox.TextXAlignment = Enum.TextXAlignment.Left
        copyBox.TextYAlignment = Enum.TextYAlignment.Top
        copyBox.Parent = copyFrame
        
        -- تحديد النص للنسخ
        copyBox:CaptureFocus()
        copyBox.SelectionStart = 1
        copyBox.CursorPosition = #allText
        
        local closeCopy = Instance.new("TextButton")
        closeCopy.Text = "✓ TEXT SELECTED - COPY NOW"
        closeCopy.Size = UDim2.new(0.9, 0, 0.08, 0)
        closeCopy.Position = UDim2.new(0.05, 0, 0.9, 0)
        closeCopy.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        closeCopy.TextColor3 = Color3.new(1, 1, 1)
        closeCopy.Font = Enum.Font.GothamBold
        closeCopy.Parent = copyFrame
        
        closeCopy.MouseButton1Click:Connect(function()
            copyGui:Destroy()
        end)
    end)
    
    -- حدث الإغلاق
    closeButton.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
    
    -- المسح التلقائي الأولي
    task.spawn(function()
        wait(2)
        SCAN_EVERY_RESOURCE()
        DISPLAY_RESOURCES("CURRENCY")
        
        -- تفعيل أول تبويب
        tabButtons["CURRENCY"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        tabButtons["CURRENCY"].TextColor3 = Color3.fromRGB(0, 0, 0)
    end)
    
    return gui
end

-- ============================================
-- 🚀 التشغيل الفوري
-- ============================================

CREATE_COMPLETE_MOBILE_UI()

print("\n" .. string.rep("🎮", 70))
print("🎮 COMPLETE RESOURCE MANAGER LOADED!")
print("📱 Mobile Touch Interface Ready")
print("✨ Features:")
print("   • Scan ALL resources in the map")
print("   • Categorized display (Currency, Tools, Items, Materials, etc.)")
print("   • Individual amount input for each resource")
print("   • One-click increase buttons")
print("   • Copy codes for each resource")
print("   • Copy all codes button")
print("   • Draggable interface for mobile")
print(string.rep("🎮", 70))

print("\n📝 Usage Instructions:")
print("   1. Press SCAN ALL RESOURCES button")
print("   2. Select a category tab (Currency, Tools, etc.)")
print("   3. Enter amount in the textbox next to each resource")
print("   4. Press ADD button to increase that resource")
print("   5. Use 📋 button to copy individual resource code")
print("   6. Use COPY ALL CODES for all resources at once")
