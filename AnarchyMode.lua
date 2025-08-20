-- Обновлено: стабильное поведение, нанесение урона, пролёт до конца карты, до 4 монстров одновременно
-- Добавлено: взрывы и плавное отключение ламп в комнатах по пути монстров
-- Добавлено: однократная надпись "ANARCHY MODE ACTIVATED!" с шрифтом GothamSemibold
-- Добавлено: спринт с ограничением, тяжёлым дыханием, спринт-баром и лёгким эффектом затемнения экрана
!НЕ ТРОГАЙТЕ СКРИПТ ИЛИ ИНАЧЕ ВСЁ СЛОМАЕТСЯ! ТАКЖЕ НЕ ПЫТАЙТЕСЬ ЕГО УКРАСТЬ!
!DO NOT TOUCH THE SCRIPT OR IT WILL BREAK! DO NOT TRY TO STEAL IT ALSO!

-- Сервисы
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

-- Игрок
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- Комнаты
local CurrentRooms = workspace:WaitForChild("CurrentRooms")
local LatestRoom = ReplicatedStorage:WaitForChild("GameData"):WaitForChild("LatestRoom")

-- Создаём ScreenGui для текста, если его нет
local screenGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("AnarchyGui")
if not screenGui then
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AnarchyGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Спринт-бар UI
local sprintGui = screenGui:FindFirstChild("SprintGui")
if not sprintGui then
    sprintGui = Instance.new("ScreenGui")
    sprintGui.Name = "SprintGui"
    sprintGui.ResetOnSpawn = false
    sprintGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local sprintBarBackground = sprintGui:FindFirstChild("SprintBarBackground")
if not sprintBarBackground then
    sprintBarBackground = Instance.new("Frame")
    sprintBarBackground.Name = "SprintBarBackground"
    sprintBarBackground.Size = UDim2.new(0, 200, 0, 20)
    sprintBarBackground.Position = UDim2.new(1, -220, 1, -60)
    sprintBarBackground.AnchorPoint = Vector2.new(0, 0)
    sprintBarBackground.BackgroundColor3 = Color3.new(0, 0, 0)
    sprintBarBackground.BackgroundTransparency = 0.6
    sprintBarBackground.BorderSizePixel = 0
    sprintBarBackground.Parent = sprintGui
end

local sprintBar = sprintBarBackground:FindFirstChild("SprintBar")
if not sprintBar then
    sprintBar = Instance.new("Frame")
    sprintBar.Name = "SprintBar"
    sprintBar.Size = UDim2.new(1, 0, 1, 0)
    sprintBar.BackgroundColor3 = Color3.fromRGB(0, 255, 127)
    sprintBar.BorderSizePixel = 0
    sprintBar.Parent = sprintBarBackground
end


-- Переменные для спринта
local sprinting = false
local canSprint = true
local sprintDuration = 5 -- секунд спринта
local sprintCooldown = 5 -- секунд отдыха
local sprintTimer = sprintDuration

-- Скорость игрока
local normalWalkSpeed = Humanoid.WalkSpeed
local sprintWalkSpeed = normalWalkSpeed * 1.4

-- Звук тяжёлого дыхания
local breathingSound = nil
local function playBreathing()
    if breathingSound and breathingSound.Parent then return end
    breathingSound = Instance.new("Sound")
    breathingSound.SoundId = "rbxassetid://121537915074324" -- можешь заменить на нужный id
    breathingSound.Volume = 1
    breathingSound.Looped = true
    breathingSound.Parent = workspace.CurrentCamera
    breathingSound:Play()
end
local function stopBreathing()
    if breathingSound then
        breathingSound:Stop()
        breathingSound:Destroy()
        breathingSound = nil
    end
end

-- Обновление UI спринт-бара
local function updateSprintBar()
    local ratio = sprintTimer / sprintDuration
    sprintBar:TweenSize(UDim2.new(ratio, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
    if ratio > 0.5 then
        sprintBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    elseif ratio > 0.2 then
        sprintBar.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
    else
        sprintBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    end
end

-- Обновляем персонажа и нужные объекты при респавне
local function onCharacterAdded(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
    normalWalkSpeed = Humanoid.WalkSpeed
    sprintWalkSpeed = normalWalkSpeed * 1.4
    sprintTimer = sprintDuration
    canSprint = true
    sprinting = false
    Humanoid.WalkSpeed = normalWalkSpeed
    stopBreathing()
    setVignette(false)
    updateSprintBar()
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Обработка нажатия клавиш
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Q and canSprint and sprintTimer > 0 then
        sprinting = true
        Humanoid.WalkSpeed = sprintWalkSpeed
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Q then
        sprinting = false
        Humanoid.WalkSpeed = normalWalkSpeed
    end
end)

-- Цикл обновления спринта
RunService.Heartbeat:Connect(function(deltaTime)
    if sprinting then
        sprintTimer = math.max(sprintTimer - deltaTime, 0)
        if sprintTimer <= 0 then
            sprinting = false
            canSprint = false
            Humanoid.WalkSpeed = normalWalkSpeed
            playBreathing()
            setVignette(true)
        end
    else
        if not canSprint then
            sprintTimer = math.min(sprintTimer + deltaTime, sprintDuration)
            if sprintTimer >= sprintDuration then
                canSprint = true
                stopBreathing()
                setVignette(false)
            end
        else
            if sprintTimer < sprintDuration then
                sprintTimer = math.min(sprintTimer + deltaTime * 0.5, sprintDuration) -- медленное восстановление вне спринта
            end
        end
    end
    updateSprintBar()
end)

-- Далее весь твой оригинальный скрипт — с монстрами, эффектами и т.п.

-- Быстрое реверсирование таблиц
local function reverseTable(t)
    local nt = {}
    for i = #t, 1, -1 do
        table.insert(nt, t[i])
    end
    return nt
end

-- Функция плавного отключения и взрыва ламп в комнате
local function breakLights(room)
    if not room then return end
    for _, obj in pairs(room:GetDescendants()) do
        if (obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight")) and not obj.Parent:FindFirstChild("Shattered") then
            local bulb = obj.Parent
            local flag = Instance.new("BoolValue")
            flag.Name = "Shattered"
            flag.Parent = bulb

            -- Плавное затухание света
            spawn(function()
                local initialBrightness = obj.Brightness
                local steps = 10
                for i = 1, steps do
                    obj.Brightness = initialBrightness * (1 - i / steps)
                    task.wait(0.05)
                end
                obj.Enabled = false
            end)

            -- Звук разбития лампы
            local sound = Instance.new("Sound", bulb)
            sound.SoundId = "rbxassetid://9118823104"
            sound.Volume = 1.8
            sound:Play()
            game:GetService("Debris"):AddItem(sound, 3)
        end
    end
end

-- Монстры с параметрами
local Monsters = {
    Silence = {ModelId = "111827810351864", SoundId = "rbxassetid://9120002134", Behavior = "BackSilentKill", Damage = 100, Speed = 3.0},
    Shocker = {ModelId = "11547803978", SoundId = "rbxassetid://9120002135", Behavior = "LookAway", Damage = 40, Speed = 0.6},
    WH1T3 = {ModelId = "78201954512363", SoundId = "rbxassetid://9120002152", Behavior = "Ambush", Damage = 100, Speed = 0.25},
    Frostbite = {ModelId = "16648442829", SoundId = "rbxassetid://9120002174", Behavior = "FreezeScreen", Damage = 100, Speed = 0.35},
    Void = {ModelId = "1122334455", SoundId = "rbxassetid://9120002163", Behavior = "Drain", Damage = 100, Speed = 0.35},
    Depth = {ModelId = "12453520636", SoundId = "rbxassetid://9120002141", Behavior = "Ambush", Damage = 100, Speed = 0.35},
    EntityX = {ModelId = "1122334466", SoundId = "rbxassetid://9120002195", Behavior = "Ambush", Damage = 100, Speed = 0.3},
    Rebound = {ModelId = "1122334477", SoundId = "rbxassetid://9120002201", Behavior = "Ambush", Damage = 100, Speed = 1.25},
    ["A-60"] = {ModelId = "15972282065", SoundId = "rbxassetid://9120002210", Behavior = "Ambush", Damage = 100, Speed = 0.5},
    ["A-200"] = {ModelId = "16827498693", SoundId = "rbxassetid://9120002220", Behavior = "Ambush", Damage = 100, Speed = 0.55},
    Dread = {ModelId = "12654337720", SoundId = "rbxassetid://9120002230", Behavior = "Ambush", Damage = 100, Speed = 0.45},
    Cease = {ModelId = "11547018893", SoundId = "rbxassetid://9120002240", Behavior = "Ambush", Damage = 100, Speed = 0.95}
}

-- Безопасная загрузка модели
local function loadModel(assetId)
    local success, result = pcall(function()
        return game:GetObjects("rbxassetid://" .. assetId)[1]
    end)
    if success and result and result:IsA("Model") then
        return result
    else
        warn("Ошибка загрузки модели: " .. tostring(assetId))
        return nil
    end
end

-- Проверка, спрятан ли игрок
local function isHiding()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Parent and v.Parent:FindFirstChild("HiddenPlayer") then
            if v.Parent.HiddenPlayer.Value == LocalPlayer.Character then
                return true
            end
        end
    end
    return false
end

-- Скример
local function playScreamer(monster)
    local cam = workspace.CurrentCamera
    local model = loadModel(monster.ModelId)
    if not model then return end
    model.PrimaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not model.PrimaryPart then return end

    model:SetPrimaryPartCFrame(cam.CFrame * CFrame.new(0, 0, -3))
    model.Parent = workspace

    local scream = Instance.new("Sound", cam)
    scream.SoundId = monster.SoundId
    scream.Volume = 3
    scream:Play()

    TweenService:Create(model.PrimaryPart, TweenInfo.new(0.4), {CFrame = cam.CFrame}):Play()
    task.wait(0.5)
    scream:Destroy()
    model:Destroy()
end

-- Мерцание света
local function flickerLight(monsterName)
    if monsterName == "Silence" or monsterName == "EntityX" then return end
    local original = Lighting.Brightness
    for _ = 1, math.random(3, 5) do
        Lighting.Brightness = 0
        task.wait(0.1)
        Lighting.Brightness = original
        task.wait(0.15)
    end
end

-- Урон игроку
local function monitorDamage(model, monster)
    coroutine.wrap(function()
        while model and model.Parent and Character and Character.Parent do
            task.wait(0.1)
            if not HumanoidRootPart or not model.PrimaryPart then break end
            local dist = (HumanoidRootPart.Position - model.PrimaryPart.Position).Magnitude
            if dist < 100 and not isHiding() then
                playScreamer(monster)
                if Character:FindFirstChild("Humanoid") then
                    Character.Humanoid:TakeDamage(monster.Damage)
                else
                    Character:BreakJoints()
                end
            end
        end
    end)()
end

-- Новое поведение Ambush (плавное движение с учётом скорости и взрывами ламп)
local function ambushBehavior(model, monster)
    coroutine.wrap(function()
        if not model or not model.PrimaryPart then return end
        local direction = 1
        local iterations = math.random(2, 6)
        local allRooms = {}

        for _, room in pairs(CurrentRooms:GetChildren()) do
            local num = tonumber(room.Name)
            if num and room:IsA("Model") and room:FindFirstChildWhichIsA("BasePart") then
                table.insert(allRooms, {Index = num, Room = room})
            end
        end
        table.sort(allRooms, function(a, b) return a.Index < b.Index end)
        if #allRooms < 2 then return end

        local sound = Instance.new("Sound", model.PrimaryPart)
        sound.SoundId = monster.SoundId
        sound.Volume = 2
        sound:Play()
        task.wait(2)

        for i = 1, iterations do
            local rooms = (direction == 1) and allRooms or reverseTable(allRooms)
            for _, entry in ipairs(rooms) do
                local part = entry.Room.PrimaryPart or entry.Room:FindFirstChildWhichIsA("BasePart")
                if part and model.PrimaryPart then
                    local goal = {CFrame = part.CFrame + Vector3.new(0, 4, 0)}
                    local tween = TweenService:Create(model.PrimaryPart, TweenInfo.new(monster.Speed, Enum.EasingStyle.Linear), goal)
                    tween:Play()
                    tween.Completed:Wait()

                    -- Лампы взрываются/отключаются в этой комнате
                    breakLights(entry.Room)
                end
            end
            direction = -direction
            task.wait(math.random(1, 3))
        end
        model:Destroy()
    end)()
end

-- Простое движение (плавное) с учётом скорости и взрывами ламп
local function moveMonster(model, monster)
    coroutine.wrap(function()
        for _, room in ipairs(CurrentRooms:GetChildren()) do
            if room and room.PrimaryPart and model and model.PrimaryPart then
                local goal = {CFrame = room.PrimaryPart.CFrame + Vector3.new(0, 4, 0)}
                local tween = TweenService:Create(model.PrimaryPart, TweenInfo.new(monster.Speed, Enum.EasingStyle.Linear), goal)
                tween:Play()
                tween.Completed:Wait()

                -- Лампы взрываются/отключаются в этой комнате
                breakLights(room)
            end
        end
        model:Destroy()
    end)()
end

-- Спавн монстра
local function spawnMonster(name)
    local monster = Monsters[name]
    if not monster then return end

    local offset = math.random(4, 6)
    local spawnRoomNum = math.max(LatestRoom.Value - offset, 1)
    local spawnRoom = CurrentRooms:FindFirstChild(tostring(spawnRoomNum))
    if not spawnRoom then return end

    local basePart = spawnRoom.PrimaryPart or spawnRoom:FindFirstChildWhichIsA("BasePart")
    if not basePart then return end

    local model = loadModel(monster.ModelId)
    if not model then return end

    model.PrimaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not model.PrimaryPart then return end

    model.Name = name
    model:SetPrimaryPartCFrame(basePart.CFrame + Vector3.new(0, 4, 0))
    model.Parent = workspace

    if monster.SoundId then
        local sound = Instance.new("Sound", model.PrimaryPart)
        sound.SoundId = monster.SoundId
        sound.Looped = true
        sound.Volume = 1.5
        sound:Play()
    end

    flickerLight(name)
    monitorDamage(model, monster)

    if monster.Behavior == "Ambush" then
        ambushBehavior(model, monster)
    else
        moveMonster(model, monster)
    end
end

-- Показ однократной надписи ANARCHY MODE ACTIVATED!
local anarchyTextShown = false
local function showAnarchyModeText()
    if anarchyTextShown then return end
    anarchyTextShown = true

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "AnarchyText"
    textLabel.Size = UDim2.new(0.45, 0, 0, 40)
    textLabel.Position = UDim2.new(0.5, 0, 0.8, 0)
    textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "ANARCHY MODE ACTIVATED! BY Tunder8401 (DJ SD - Topic) AND CHAT GPT (version 0.9... probably)"
    textLabel.Font = Enum.Font.GothamSemibold
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextStrokeTransparency = 0.4
    textLabel.TextScaled = true
    textLabel.TextTransparency = 1
    textLabel.Parent = screenGui

    TweenService:Create(textLabel, TweenInfo.new(1), {TextTransparency = 0}):Play()

    task.delay(11, function()
        local tweenOut = TweenService:Create(textLabel, TweenInfo.new(1), {TextTransparency = 1})
        tweenOut:Play()
        tweenOut.Completed:Wait()
        textLabel:Destroy()
    end)
end

-- Показываем надпись один раз, если LatestRoom уже >= 1
if LatestRoom.Value >= 1 then
    showAnarchyModeText()
end

-- Подписываемся на изменение LatestRoom, чтобы показать надпись один раз при достижении >= 1
LatestRoom:GetPropertyChangedSignal("Value"):Connect(function()
    if LatestRoom.Value >= 1 then
        showAnarchyModeText()
    end
end)

-- Главный цикл спавна монстров
while true do
    -- Определяем текущую дверь
    local currentRoom = LatestRoom.Value

    -- Специальный режим для 50-й двери
    if currentRoom == 50 then
        task.wait(120)

        -- Пропуск, если активен Seek
        if workspace:FindFirstChild("SeekMoving") then
            continue
        end

        -- Спавн только одного монстра
        local names = {}
        for name in pairs(Monsters) do table.insert(names, name) end
        spawnMonster(names[math.random(1, #names)])

    -- Нормальный режим для остальных дверей (кроме 99 и 100)
    elseif currentRoom < 99 then
        task.wait(math.random(30, 45))

        if workspace:FindFirstChild("SeekMoving") then
            continue
        end

        local names = {}
        for name in pairs(Monsters) do table.insert(names, name) end
        local count = math.random(2, 4)
        for i = 1, count do
            spawnMonster(names[math.random(1, #names)])
        end
    else
        -- Если дверь 99 или 100 — не спавним никого
        task.wait(5)
    end
end
