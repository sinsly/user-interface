local Console = {}

local TweenService = game:GetService("TweenService")
local CoreGUI = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local function pretty_date(date)
    return string.format("%04d-%02d-%02d %02d:%02d", date.year, date.month, date.day, date.hour, date.min)
end

function Console:Window(consoledebugger)
    local Title = tostring(consoledebugger.Title or "Console")
    local GuiPosition = consoledebugger.Position or UDim2.new(0.5, -300, 0.5, -250)
    local DragSpeed = consoledebugger.DragSpeed or 8
    local autoDeleteLogs = false

    local oldGui = CoreGUI:FindFirstChild("Console")
    if oldGui then oldGui:Destroy() end

    local ConsoleGui = Instance.new("ScreenGui")
    ConsoleGui.Name = "Console"
    ConsoleGui.Parent = CoreGUI
    ConsoleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local background = Instance.new("Frame")
    background.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    background.BorderSizePixel = 0
    background.Position = GuiPosition
    background.Size = UDim2.new(0, 600, 0, 500)
    background.AnchorPoint = Vector2.new(0.5, 0.5)
    background.Parent = ConsoleGui

    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 6)
    uicorner.Parent = background

    local uistroke = Instance.new("UIStroke")
    uistroke.Color = Color3.fromRGB(40, 40, 40)
    uistroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uistroke.Parent = background

    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    topBar.BorderSizePixel = 0
    topBar.Size = UDim2.new(1, 0, 0, 40)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.Parent = background

    local topBarCorner = Instance.new("UICorner")
    topBarCorner.CornerRadius = UDim.new(0, 6)
    topBarCorner.Parent = topBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = Title
    titleLabel.Font = Enum.Font.GothamSemibold
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(0, 300, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = topBar

    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(0, 180, 0, 24)
    toggleFrame.Position = UDim2.new(0, 310, 0, 8)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(58, 58, 58)
    toggleFrame.BorderSizePixel = 0
    toggleFrame.Parent = topBar

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 12)
    toggleCorner.Parent = toggleFrame

    local toggleInner = Instance.new("Frame")
    toggleInner.Size = UDim2.new(0, 16, 0, 16)
    toggleInner.Position = UDim2.new(0, 4, 0, 4)
    toggleInner.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    toggleInner.BorderSizePixel = 0
    toggleInner.Parent = toggleFrame

    local toggleInnerCorner = Instance.new("UICorner")
    toggleInnerCorner.CornerRadius = UDim.new(0, 12)
    toggleInnerCorner.Parent = toggleInner

    local toggleLabel = Instance.new("TextLabel")
    toggleLabel.Text = "AutoDelete 30s"
    toggleLabel.Font = Enum.Font.GothamSemibold
    toggleLabel.TextSize = 14
    toggleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    toggleLabel.BackgroundTransparency = 1
    toggleLabel.Size = UDim2.new(0, 120, 1, 0)
    toggleLabel.Position = UDim2.new(0, 26, 0, 0)
    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    toggleLabel.Parent = toggleFrame

    toggleFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            autoDeleteLogs = not autoDeleteLogs
            toggleInner.BackgroundColor3 = autoDeleteLogs and Color3.fromRGB(83, 230, 50) or Color3.fromRGB(40, 40, 40)
        end
    end)

    local keybindLabel = Instance.new("TextLabel")
    keybindLabel.Text = "[Toggle: RightShift]"
    keybindLabel.Font = Enum.Font.Gotham
    keybindLabel.TextSize = 14
    keybindLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    keybindLabel.BackgroundTransparency = 1
    keybindLabel.Size = UDim2.new(0, 150, 1, 0)
    keybindLabel.Position = UDim2.new(1, -160, 0, 0)
    keybindLabel.TextXAlignment = Enum.TextXAlignment.Right
    keybindLabel.Parent = topBar

    local ConsoleContainer = Instance.new("ScrollingFrame")
    ConsoleContainer.Active = true
    ConsoleContainer.BackgroundTransparency = 1
    ConsoleContainer.BorderSizePixel = 0
    ConsoleContainer.Position = UDim2.new(0, 10, 0, 50)
    ConsoleContainer.Size = UDim2.new(1, -20, 1, -60)
    ConsoleContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    ConsoleContainer.ScrollBarThickness = 6
    ConsoleContainer.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 50)
    ConsoleContainer.Parent = background

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 6)
    listLayout.Parent = ConsoleContainer

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ConsoleContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)

    local dragging, dragStart, startPos, lastMousePos, lastGoalPos
    local function Lerp(a, b, t) return a + (b - a) * t end

    local function Update(dt)
        if not startPos then return end
        if not dragging and lastGoalPos then
            background.Position = UDim2.new(startPos.X.Scale, Lerp(background.Position.X.Offset, lastGoalPos.X.Offset, dt * DragSpeed),
                                             startPos.Y.Scale, Lerp(background.Position.Y.Offset, lastGoalPos.Y.Offset, dt * DragSpeed))
            return
        end
        local delta = (lastMousePos - UserInputService:GetMouseLocation())
        local xGoal = (startPos.X.Offset - delta.X)
        local yGoal = (startPos.Y.Offset - delta.Y)
        lastGoalPos = UDim2.new(startPos.X.Scale, xGoal, startPos.Y.Scale, yGoal)
        background.Position = UDim2.new(startPos.X.Scale, Lerp(background.Position.X.Offset, xGoal, dt * DragSpeed),
                                         startPos.Y.Scale, Lerp(background.Position.Y.Offset, yGoal, dt * DragSpeed))
    end
    RunService.Heartbeat:Connect(Update)

    background.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startPos = background.Position
            lastMousePos = UserInputService:GetMouseLocation()
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    background.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.RightShift then
            ConsoleGui.Enabled = not ConsoleGui.Enabled
        end
    end)

    local ConsoleLog = {}
    function ConsoleLog:Prompt(promptdebugger)
        local text = tostring(promptdebugger.Title or "Nil")
        local type_ = string.lower(tostring(promptdebugger.Type or "default"))
        local time = pretty_date(os.date("*t", os.time()))
        local finalText = "["..time.."] "..text

        if type_ == "success" then finalText = "{Success} : "..finalText
        elseif type_ == "fail" then finalText = "{Error} : "..finalText
        elseif type_ == "warning" then finalText = "{Warning} : "..finalText
        elseif type_ == "notification" or type_ == "nofitication" then finalText = "{Notification} : "..finalText end

        local label = Instance.new("TextLabel")
        label.Text = finalText
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.TextColor3 = (type_ == "success" and Color3.fromRGB(83, 230, 50)) or
                           (type_ == "fail" and Color3.fromRGB(255, 84, 84)) or
                           (type_ == "warning" and Color3.fromRGB(202, 156, 107)) or
                           (type_ == "notification" and Color3.fromRGB(121, 130, 255)) or
                           Color3.fromRGB(220, 220, 220)
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -10, 0, 24)
        label.AutomaticSize = Enum.AutomaticSize.Y
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = ConsoleContainer

        TweenService:Create(label, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { TextTransparency = 0 }):Play()
        task.wait(0.03)
        ConsoleContainer.CanvasPosition = Vector2.new(0, ConsoleContainer.CanvasSize.Y.Offset)

        if autoDeleteLogs then
            task.delay(30, function()
                if label and label.Parent then
                    local tween = TweenService:Create(label, TweenInfo.new(0.5), { TextTransparency = 1 })
                    tween:Play()
                    tween.Completed:Wait()
                    label:Destroy()
                end
            end)
        end
    end

    return ConsoleLog
end

return Console
