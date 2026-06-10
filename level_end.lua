local LevelEnd = {}
LevelEnd.__index = LevelEnd

local function fileExists(path)
    return path and love.filesystem.getInfo(path) ~= nil
end

local function loadSounds(paths)
    local sounds = {}

    for _, path in ipairs(paths or {}) do
        if fileExists(path) then
            table.insert(sounds, love.audio.newSource(path, "static"))
        end
    end

    return sounds
end

local function playRandomSound(sounds)
    if #sounds == 0 then
        return
    end

    local sound = sounds[math.random(1, #sounds)]
    sound:stop()
    sound:play()
end

function LevelEnd:new(config)
    local levelEnd = setmetatable({}, LevelEnd)

    -- Позиция и размер объекта конца уровня
    levelEnd.x = config.x or 760
    levelEnd.y = config.y or 380
    levelEnd.w = config.w or config.width or 48
    levelEnd.h = config.h or config.height or 80

    -- Через сколько секунд объект появится
    levelEnd.appearAfter = config.appearAfter
        or config.appear_after
        or 0

    -- Скорость движения к игроку.
    -- Если 0, объект стоит на месте.
    levelEnd.speed = config.speed or 0

    -- Таймер жизни объекта
    levelEnd.elapsed = 0

    -- Активен ли объект сейчас
    levelEnd.active = false

    -- Был ли уже использован объект
    levelEnd.triggered = false

    -- Картинка самого объекта на уровне
    levelEnd.imagePath = config.image
    levelEnd.image = nil

    if fileExists(levelEnd.imagePath) then
        levelEnd.image = love.graphics.newImage(levelEnd.imagePath)
    end

    -- Картинка победы на весь экран
    levelEnd.victoryImagePath = config.victoryImage
        or config.victory_image

    levelEnd.victoryImage = nil

    if fileExists(levelEnd.victoryImagePath) then
        levelEnd.victoryImage = love.graphics.newImage(levelEnd.victoryImagePath)
    end

    -- Звуки победы
    levelEnd.victorySounds = loadSounds(config.victorySounds or {
        "assets/sfx/victory.wav"
    })

    levelEnd.color = config.color or {1.0, 0.85, 0.2}

    return levelEnd
end

function LevelEnd:update(dt, player)
    if self.triggered then
        return
    end

    self.elapsed = self.elapsed + dt

    if not self.active and self.elapsed >= self.appearAfter then
        self.active = true
    end

    if not self.active then
        return
    end

    if self.speed == 0 or not player then
        return
    end

    -- Движение к игроку по X
    local playerCenterX = player.x + player.w / 2
    local selfCenterX = self.x + self.w / 2

    if playerCenterX < selfCenterX then
        self.x = self.x - self.speed * dt
    elseif playerCenterX > selfCenterX then
        self.x = self.x + self.speed * dt
    end
end

function LevelEnd:getHitbox()
    return {
        x = self.x,
        y = self.y,
        w = self.w,
        h = self.h
    }
end

function LevelEnd:canTrigger()
    return self.active and not self.triggered
end

function LevelEnd:trigger()
    if self.triggered then
        return
    end

    self.triggered = true
    playRandomSound(self.victorySounds)
end

function LevelEnd:draw()
    if not self.active or self.triggered then
        return
    end

    if self.image then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(
            self.image,
            self.x,
            self.y,
            0,
            self.w / self.image:getWidth(),
            self.h / self.image:getHeight()
        )

        return
    end

    -- Мокап объекта конца уровня
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 8, 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("EXIT", self.x, self.y + self.h / 2 - 6, self.w, "center")
end

function LevelEnd:drawVictory(screenWidth, screenHeight)
    if self.victoryImage then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(
            self.victoryImage,
            0,
            0,
            0,
            screenWidth / self.victoryImage:getWidth(),
            screenHeight / self.victoryImage:getHeight()
        )
    else
        love.graphics.setColor(0.05, 0.08, 0.12)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

        love.graphics.setColor(0.15, 0.45, 0.95)
        love.graphics.rectangle("fill", 100, 90, screenWidth - 200, screenHeight - 180, 18, 18)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Победа!", 0, screenHeight / 2 - 16, screenWidth, "center")
end


-----методы HUD-шкалы прогресса до появления EndLevel
function LevelEnd:getAppearProgress()
    if self.appearAfter <= 0 then
        return 1
    end

    local progress = self.elapsed / self.appearAfter

    return math.max(0, math.min(progress, 1))
end

function LevelEnd:getAppearTimeRemaining()
    if self.appearAfter <= 0 then
        return 0
    end

    return math.max(0, self.appearAfter - self.elapsed)
end

function LevelEnd:shouldShowProgress()
    return not self.triggered
        and self.appearAfter > 0
end

function LevelEnd:isVisibleToPlayer()
    return self.active and not self.triggered
end
--------



return LevelEnd