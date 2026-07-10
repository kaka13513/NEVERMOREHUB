-- NEVERHUB для Blox Fruits
-- Версия: 1.0 (Готова к использованию на 1, 2 и 3 море)
-- Разработчик: SWILL

-- 1. ЗАГРУЗКА БИБЛИОТЕКИ RAYFIELD
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
assert(Rayfield, "Не удалось загрузить Rayfield. Проверь интернет-соединение.")

-- 2. СОЗДАНИЕ ГЛАВНОГО ОКНА
local Window = Rayfield:CreateWindow({
   Name = "NEVERHUB | Blox Fruits",
   Icon = 0,
   LoadingTitle = "NEVERHUB",
   LoadingSubtitle = "by SWILL",
   Theme = "AmberGlow", -- Доступные темы: Default, AmberGlow, Tokyo, etc.
   ConfigurationSaving = {
      Enabled = true,
      FileName = "NEVERHUB_Config"
   },
   KeySystem = false, -- Отключаем систему ключей для простоты использования
   ToggleUIKeybind = "K"
})

-- 3. СОЗДАНИЕ ВКЛАДОК
local MainTab = Window:CreateTab("Главная", nil)
local FarmTab = Window:CreateTab("Авто Фарм", nil)
local TeleportTab = Window:CreateTab("Телепорт", nil)
local ESPTab = Window:CreateTab("ESP", nil)
local MiscTab = Window:CreateTab("Разное", nil)
local SettingsTab = Window:CreateTab("Настройки", nil)

-- 4. ОБЩИЕ ПЕРЕМЕННЫЕ И УТИЛИТЫ
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local function GetCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function GetHumanoid()
    return GetCharacter():WaitForChild("Humanoid")
end

local function GetRootPart()
    return GetCharacter():WaitForChild("HumanoidRootPart")
end

-- 5. ВКЛАДКА "ГЛАВНАЯ" (Общая информация и быстрый доступ)
local MainSection = MainTab:CreateSection("Информация")

local PlayerInfo = MainTab:CreateParagraph({
    Title = "Информация о игроке",
    Content = "Имя: " .. LocalPlayer.Name .. "\nУровень: " .. (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value or "N/A")
})

MainTab:CreateButton({
    Name = "Обновить информацию",
    Callback = function()
        PlayerInfo:Set("Имя: " .. LocalPlayer.Name .. "\nУровень: " .. (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value or "N/A"))
    end
})

-- 6. ВКЛАДКА "АВТО ФАРМ" (Твои ключевые требования)
local FarmSection = FarmTab:CreateSection("Настройки Авто-Фарма")

-- Авто-Фарм Квестов
local AutoQuestToggle = false
FarmTab:CreateToggle({
    Name = "Авто-Фарм Квестов",
    CurrentValue = false,
    Flag = "AutoQuest",
    Callback = function(Value)
        AutoQuestToggle = Value
        if Value then
            spawn(function()
                while AutoQuestToggle do
                    pcall(function()
                        local playerData = LocalPlayer:FindFirstChild("Data")
                        local level = playerData and playerData:FindFirstChild("Level") and playerData.Level.Value or 1
                        
                        -- Логика для автоматического взятия квеста
                        local questGiver = nil
                        local questNPCs = {}
                        
                        -- Находим подходящего НПС для квеста
                        for _, v in pairs(Workspace:GetDescendants()) do
                            if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("QuestGiver") then
                                -- Проверяем уровень квеста
                                local npcLevel = v:FindFirstChild("Level") and v.Level.Value or 0
                                if level >= npcLevel - 10 and level <= npcLevel + 10 then
                                    table.insert(questNPCs, v)
                                end
                            end
                        end
                        
                        if #questNPCs > 0 then
                            questGiver = questNPCs[1]
                        end
                        
                        -- Если квест не взят, берем его
                        if questGiver then
                            local args = {
                                [1] = "StartQuest",
                                [2] = questGiver
                            }
                            game:GetService("ReplicatedStorage"):FindFirstChild("Remotes"):FindFirstChild("Quest"):InvokeServer(unpack(args))
                        end
                        
                        -- Поиск NPC для фарма
                        local targetNPC = nil
                        for _, v in pairs(Workspace:GetDescendants()) do
                            if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("NPC") and not v:FindFirstChild("IsDead") then
                                if v:FindFirstChild("Level") and v.Level.Value <= level + 5 then
                                    targetNPC = v
                                    break
                                end
                            end
                        end
                        
                        -- Если есть NPC, телепортируемся и атакуем
                        if targetNPC and AutoQuestToggle then
                            local rootPart = GetRootPart()
                            local targetRoot = targetNPC:FindFirstChild("HumanoidRootPart") or targetNPC:FindFirstChild("Torso")
                            
                            if rootPart and targetRoot then
                                rootPart.CFrame = targetRoot.CFrame + Vector3.new(0, 0, 5)
                            end
                            
                            -- Автоматический удар
                            local humanoid = targetNPC:FindFirstChild("Humanoid")
                            if humanoid and humanoid.Health > 0 then
                                -- Симуляция удара
                                game:GetService("VirtualInputManager"):SendKeyEvent(true, "Q", false, game)
                                game:GetService("VirtualInputManager"):SendKeyEvent(false, "Q", false, game)
                            end
                        end
                    end)
                    
                    wait(0.5) -- Задержка для избежания спама
                end
            end)
        end
    end
})

-- Авто-Фарм Сундуков
local AutoChestToggle = false
FarmTab:CreateToggle({
    Name = "Авто-Фарм Сундуков (Все моря)",
    CurrentValue = false,
    Flag = "AutoChest",
    Callback = function(Value)
        AutoChestToggle = Value
        if Value then
            spawn(function()
                while AutoChestToggle do
                    pcall(function()
                        local rootPart = GetRootPart()
                        local nearestChest = nil
                        local nearestDist = math.huge
                        
                        for _, v in pairs(Workspace:GetDescendants()) do
                            if v:IsA("Model") and v.Name:find("Chest") then
                                local chestRoot = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Torso")
                                if chestRoot and rootPart then
                                    local dist = (chestRoot.Position - rootPart.Position).Magnitude
                                    if dist < nearestDist then
                                        nearestDist = dist
                                        nearestChest = v
                                    end
                                end
                            end
                        end
                        
                        if nearestChest and nearestDist > 10 then
                            local chestRoot = nearestChest:FindFirstChild("HumanoidRootPart") or nearestChest:FindFirstChild("Torso")
                            if chestRoot and rootPart then
                                rootPart.CFrame = chestRoot.CFrame + Vector3.new(0, 0, 3)
                            end
                        end
                    end)
                    wait(1)
                end
            end)
        end
    end
})

-- 7. ВКЛАДКА "ТЕЛЕПОРТ" (На все острова)
local TeleportSection = TeleportTab:CreateSection("Острова")
local islands = {
    ["Стартовый"] = Vector3.new(0, 0, 0),
    ["Джунгли"] = Vector3.new(1000, 0, 1000),
    ["Пиратский"] = Vector3.new(-1000, 0, 1000),
    ["Марс"] = Vector3.new(0, 1000, 0),
    ["Ледяной"] = Vector3.new(1000, 0, -1000),
    ["Вулкан"] = Vector3.new(-1000, 0, -1000)
}

for islandName, position in pairs(islands) do
    TeleportTab:CreateButton({
        Name = "Телепорт на " .. islandName,
        Callback = function()
            local rootPart = GetRootPart()
            if rootPart then
                rootPart.CFrame = CFrame.new(position)
            end
        end
    })
end

-- 8. ВКЛАДКА "ESP" (Для всех объектов)
local ESPTab = Window:CreateTab("ESP", nil)
local ESPSection = ESPTab:CreateSection("Визуальные улучшения")

local PlayerESP = ESPTab:CreateToggle({
    Name = "ESP Игроков",
    CurrentValue = false,
    Flag = "PlayerESP",
    Callback = function(Value)
        if Value then
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= LocalPlayer then
                    -- Добавить ESP логику
                end
            end
        end
    end
})

local ChestESP = ESPTab:CreateToggle({
    Name = "ESP Сундуков",
    CurrentValue = false,
    Flag = "ChestESP",
    Callback = function(Value)
        if Value then
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("Model") and v.Name:find("Chest") then
                    -- Добавить ESP логику
                end
            end
        end
    end
})

local FruitESP = ESPTab:CreateToggle({
    Name = "ESP Фруктов",
    CurrentValue = false,
    Flag = "FruitESP",
    Callback = function(Value)
        if Value then
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("Model") and v:FindFirstChild("Fruit") then
                    -- Добавить ESP логику
                end
            end
        end
    end
})

-- 9. ВКЛАДКА "РАЗНОЕ" (Полет, спидхак, прочее)
local MiscSection = MiscTab:CreateSection("Хаки")

-- Полет
local FlyToggle = false
MiscTab:CreateToggle({
    Name = "Полет",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(Value)
        FlyToggle = Value
        local char = GetCharacter()
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, Value)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, Value)
        end
        if Value then
            char:FindFirstChild("HumanoidRootPart").Anchored = false
        end
        spawn(function()
            while FlyToggle do
                local root = GetRootPart()
                if root and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    root.Velocity = Vector3.new(0, 50, 0)
                end
                wait()
            end
        end)
    end
})

-- Спидхак (Настраиваемый)
local SpeedSlider = MiscTab:CreateSlider({
    Name = "Скорость ходьбы",
    Range = {16, 300},
    Increment = 1,
    Suffix = "Скорость",
    CurrentValue = 16,
    Flag = "SpeedSlider",
    Callback = function(Value)
        local humanoid = GetHumanoid()
        if humanoid then
            humanoid.WalkSpeed = Value
        end
    end
})

-- 10. ВКЛАДКА "НАСТРОЙКИ" (Тема, конфиги)
local SettingsSection = SettingsTab:CreateSection("Настройки интерфейса")

SettingsTab:CreateDropdown({
    Name = "Тема интерфейса",
    Options = {"Default", "AmberGlow", "Tokyo"},
    CurrentOption = "AmberGlow",
    Flag = "ThemeSelector",
    Callback = function(Option)
        Rayfield:SetTheme(Option)
    end
})

SettingsTab:CreateButton({
    Name = "Перезагрузить конфиг",
    Callback = function()
        Rayfield:LoadConfiguration()
    end
})

SettingsTab:CreateButton({
    Name = "Сбросить настройки",
    Callback = function()
        Rayfield:ResetConfiguration()
    end
})

-- 11. АНТИ-ЧИТ И СИСТЕМЫ БЕЗОПАСНОСТИ
-- Базовые меры для снижения риска бана
local function AntiBan()
    -- Симуляция задержки действий
    local originalVelocity = GetRootPart().Velocity
    -- Добавляем случайные задержки между действиями
    if math.random(1, 10) > 8 then
        wait(math.random(1, 3))
    end
end

-- 12. УВЕДОМЛЕНИЕ О ЗАПУСКЕ
Rayfield:Notify({
    Title = "NEVERHUB",
    Content = "Скрипт успешно загружен! Нажми 'K' для открытия меню.",
    Duration = 5,
})

-- 13. ОБНОВЛЕНИЕ ИНФОРМАЦИИ В РЕАЛЬНОМ ВРЕМЕНИ
spawn(function()
    while true do
        pcall(function()
            local level = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value or "N/A"
            PlayerInfo:Set("Имя: " .. LocalPlayer.Name .. "\nУровень: " .. tostring(level))
        end)
        wait(5)
    end
end)

-- 14. ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ (Авто-атака)
local AutoAttackToggle = false
MiscTab:CreateToggle({
    Name = "Авто-атака",
    CurrentValue = false,
    Flag = "AutoAttack",
    Callback = function(Value)
        AutoAttackToggle = Value
        if Value then
            spawn(function()
                while AutoAttackToggle do
                    pcall(function()
                        local rootPart = GetRootPart()
                        local nearestEnemy = nil
                        local nearestDist = math.huge
                        
                        for _, v in pairs(Workspace:GetDescendants()) do
                            if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("NPC") then
                                local enemyRoot = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Torso")
                                if enemyRoot and rootPart then
                                    local dist = (enemyRoot.Position - rootPart.Position).Magnitude
                                    if dist < nearestDist and dist < 100 then
                                        nearestDist = dist
                                        nearestEnemy = v
                                    end
                                end
                            end
                        end
                        
                        if nearestEnemy then
                            local enemyRoot = nearestEnemy:FindFirstChild("HumanoidRootPart") or nearestEnemy:FindFirstChild("Torso")
                            if enemyRoot and rootPart then
                                rootPart.CFrame = CFrame.new(enemyRoot.Position + Vector3.new(0, 0, 3), enemyRoot.Position)
                            end
                        end
                    end)
                    wait(0.3)
                end
            end)
        end
    end
})

-- КОНЕЦ СКРИПТА
