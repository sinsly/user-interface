local Console = {}

local TweenService = game:GetService("TweenService")
local CoreGUI = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Helper function for pretty time
local function pretty_date(date)
    return string.format("%04d-%02d-%02d %02d:%02d", date.year, date.month, date.day, date.hour, date.min)
end

function Console:Window(consoledebugger)
    local Title = tostring(consoledebugger.Title or "Console")
    local GuiPosition = consoledebugger.Position or UDim2.new(0.5, -300, 0.5, -250)
    local DragSpeed = consoledebugger.DragSpeed or 8
    local autoDeleteLogs = true -- toggleable

    -- Remove old console
    local oldGui = CoreGUI:FindFirstChild("Console")
    if oldGui then oldGui:Destroy() end

    -- Main ScreenGui
    local ConsoleGui = Instance.new("ScreenGui")
    ConsoleGui.Name = "Console"
    ConsoleGui.Parent = CoreGUI
    ConsoleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Background
    local background = Instance.new("Frame")
    background.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    background.BorderSizePixel = 0
    background.Position = GuiPosition
    background.Size = UDim2.new(0, 600, 0, 500)
    background.AnchorPoint = Vector2.new(0.5, 0.5)
    background.Parent = ConsoleGui

    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 6)
    uicorner.Parent = background

    local uistroke = Instance.new("UIStroke")
    uistroke.Color = Color3.fromRGB(25, 25, 25)
    uistroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uistroke.Parent = background

    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = Title
    titleLabel.Font = Enum.Font.GothamSemibold
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = background

    -- Log Container
    local ConsoleContainer = Instance.new("ScrollingFrame")
    ConsoleContainer.Active = true
    ConsoleContainer.BackgroundTransparency = 1
    ConsoleContainer.BorderSizePixel = 0
    ConsoleContainer.Position = UDim2.new(0, 10, 0, 40)
    ConsoleContainer.Size = UDim2.new(1, -20, 1, -90)
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

    -- Dragging
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = background.Position
            lastMousePos = UserInputService:GetMouseLocation()
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    background.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    -- Toggle visibility with RightShift
    UserInputService.InputBegan:Connect(function(input, processed)
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.RightShift then
            ConsoleGui.Enabled = not ConsoleGui.Enabled
        end
    end)

    -- Slider toggle for auto-delete logs
    local toggleLabel = Instance.new("TextLabel")
    toggleLabel.Text = "Auto Delete Logs After 30s:"
    toggleLabel.Font = Enum.Font.Gotham
    toggleLabel.TextSize = 14
    toggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    toggleLabel.BackgroundTransparency = 1
    toggleLabel.Position = UDim2.new(0, 10, 1, -40)
    toggleLabel.Size = UDim2.new(0, 200, 0, 20)
    toggleLabel.Parent = background

    local toggleButton = Instance.new("TextButton")
    toggleButton.Text = autoDeleteLogs and "ON" or "OFF"
    toggleButton.Font = Enum.Font.GothamSemibold
    toggleButton.TextSize = 14
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.BackgroundColor3 = autoDeleteLogs and Color3.fromRGB(83, 230, 50) or Color3.fromRGB(150, 50, 50)
    toggleButton.Size = UDim2.new(0, 50, 0, 20)
    toggleButton.Position = UDim2.new(0, 220, 1, -40)
    toggleButton.Parent = background

    toggleButton.MouseButton1Click:Connect(function()
        autoDeleteLogs = not autoDeleteLogs
        toggleButton.Text = autoDeleteLogs and "ON" or "OFF"
        toggleButton.BackgroundColor3 = autoDeleteLogs and Color3.fromRGB(83, 230, 50) or Color3.fromRGB(150, 50, 50)
    end)

    -- Logging
    local ConsoleLog = {}
    function ConsoleLog:Prompt(promptdebugger)
        local text = tostring(promptdebugger.Title or "Nil")
        local type_ = string.lower(tostring(promptdebugger.Type or "default"))
        local time = pretty_date(os.date("*t", os.time()))
        local finalText = "["..time.."] "..text

        if type_ == "success" then
            finalText = "{Success} : "..finalText
        elseif type_ == "fail" then
            finalText = "{Error} : "..finalText
        elseif type_ == "warning" then
            finalText = "{Warning} : "..finalText
        elseif type_ == "notification" or type_ == "nofitication" then
            finalText = "{Notification} : "..finalText
        end

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

        -- Animate entry
        TweenService:Create(label, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { TextTransparency = 0 }):Play()

        -- Auto delete with fade if enabled
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
