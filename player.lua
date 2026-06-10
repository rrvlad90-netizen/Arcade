local Player = {}
Player.__index = Player

-- Проверка, существует ли файл в проекте Love2D
local function fileExists(path)
    return love.filesystem.getInfo(path) ~= nil
end

-- Создаём мокап-кадр, если настоящего спрайта нет
local function makeMockFrame(state, index)
    local colors = {
        idle = {0.25, 0.65, 1.0},
        walk = {0.25, 1.0, 0.45},
		attack = {1.0, 0.78, 0.2},
		run_attack = {1.0, 0.55, 0.15},  --- if alwaysRun = true
		jump = {0.7, 0.45, 1.0},
        pain = {1.0, 0.35, 0.35},
        death = {0.9, 0.15, 0.18}
    }

    local canvas = love.graphics.newCanvas(48, 56)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)

    local color = colors[state] or {1, 1, 1}

    love.graphics.setColor(color)
    love.graphics.rectangle("fill", 10, 8, 28, 40, 4, 4)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 17, 16, 5, 5)
    love.graphics.rectangle("fill", 28, 16, 5, 5)

    love.graphics.setColor(0.05, 0.06, 0.08)
    love.graphics.rectangle("fill", 18 + index % 3, 38, 14, 4)

if state == "attack" or state == "run_attack" then
        love.graphics.setColor(0.55, 0.48, 0.38)
        love.graphics.circle("fill", 41, 26, 5)
    elseif state == "jump" then
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.arc("line", "open", 24, 54, 14, math.pi, math.pi * 2)
    elseif state == "pain" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("!", 21, 2)
    elseif state == "death" then
        love.graphics.setColor(0.05, 0.06, 0.08)
        love.graphics.line(17, 17, 22, 22)
        love.graphics.line(22, 17, 17, 22)
        love.graphics.line(28, 17, 33, 22)
        love.graphics.line(33, 17, 28, 22)
    end

    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)

    return canvas
end

-- Загружаем 5 кадров анимации игрока
local function loadAnimation(state)
    local frames = {}

    for i = 1, 5 do
        local path = "assets/player/" .. state .. "_" .. i .. ".png"

        if fileExists(path) then
            frames[i] = love.graphics.newImage(path)
        else
            frames[i] = makeMockFrame(state, i)
        end
    end

    return frames
end

-- Загружаем набор звуков
local function loadSounds(paths)
    local sounds = {}

    for _, path in ipairs(paths) do
        if fileExists(path) then
            table.insert(sounds, love.audio.newSource(path, "static"))
        end
    end

    return sounds
end

-- Проигрываем случайный звук из списка
local function playRandomSound(sounds)
    if #sounds == 0 then
        return
    end

    local sound = sounds[math.random(1, #sounds)]
    sound:stop()
    sound:play()
end

-- Создание игрока
-- config.noturn = true — игрок не разворачивается при движении назад
-- config.doublejump = true — игрок может один раз прыгнуть в воздухе
function Player:new(x, y, config)
    config = config or {}

    local player = setmetatable({}, Player)

    -- Позиция и размеры игрока
    player.x = x
    player.y = y
    player.w = 48
    player.h = 56

    -- Физика движения
    player.vx = 0
    player.vy = 0
    player.speed = 210
    player.jumpPower = -430
    player.gravity = 1050
    player.groundY = y

    -- Настройки поведения
player.noturn = config.noturn == true

-- alvaysRun/alwaysRun нужен для runner-уровней.
-- Если true, игрок не играет idle-анимацию, а всегда выглядит бегущим.
player.alvaysRun = config.alvaysRun == true
    or config.alwaysRun == true

player.doublejump = config.doublejump == true
player.jumpCount = 0
	
-- doublejump true, если игрок стоит на платформе
	player.onPlatform = false	

    -- Здоровье игрока
    player.maxHealth = 3
    player.health = 3

    -- Направление взгляда: 1 — вправо, -1 — влево
    player.facing = config.facing or 1

    -- Текущая анимация
    player.state = "idle"
    player.frame = 1
    player.frameTimer = 0
    player.frameDuration = 0.09

    -- Атака и стрельба
    player.attackTimer = 0
    player.attackDuration = 0.35
    player.shotRequested = false
    player.shotCooldown = 0
    player.shotCooldownDuration = 0.22

    -- Состояния боли и смерти
    player.hurt = false
    player.dead = false
    player.deathFinished = false

    -- Все анимации игрока
	player.animations = {
		idle = loadAnimation("idle"),
		walk = loadAnimation("walk"),
		attack = loadAnimation("attack"),

		-- Атака во время постоянного бега.
		-- Файлы: assets/player/run_attack_1.png ... run_attack_5.png
		run_attack = loadAnimation("run_attack"),

		jump = loadAnimation("jump"),
		pain = loadAnimation("pain"),
		death = loadAnimation("death")
	}

    -- Звуки игрока
    player.sounds = {
        throw = loadSounds({
            "assets/sfx/throw1.wav",
            "assets/sfx/throw2.wav"
        }),
        jump = loadSounds({
            "assets/sfx/jump1.wav",
            "assets/sfx/jump2.wav"
        }),
        death = loadSounds({
            "assets/sfx/death1.wav",
            "assets/sfx/death2.wav"
        })
    }

    return player
end

-- Меняем состояние анимации
function Player:setState(state)
    if self.state == state then
        return
    end

    self.state = state
    self.frame = 1
    self.frameTimer = 0
end

-- Проверяем, стоит ли игрок на земле
function Player:isOnGround()
    return self.y >= self.groundY or self.onPlatform
end

-- Проверяем, можно ли сейчас получить урон
function Player:canTakeDamage()
    return not self.dead and not self.hurt
end

---лечение
function Player:heal(amount)
    if self.dead then
        return false
    end

    if self.health >= self.maxHealth then
        return false
    end

    amount = amount or 1

    self.health = math.min(self.maxHealth, self.health + amount)

    return true
end

-- Проверяем, закончилась ли анимация смерти
function Player:isDeathAnimationFinished()
    return self.deathFinished
end

-- Получение урона от врага
function Player:takeDamage(amount)
    if not self:canTakeDamage() then
        return false
    end

    self.health = math.max(0, self.health - amount)

    if self.health <= 0 then
        self:die()
        return true
    end

    self.hurt = true
    self.attackTimer = 0
    self.shotRequested = false
    self:setState("pain")

    return false
end




-----обновляем визуал игрока, что бы корректно на платформах и земле отображался
function Player:updateVisualState()
    local move = 0

    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        move = move - 1
    end

    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        move = move + 1
    end

    if self.hurt then
        self:setState("pain")
    elseif not self:isOnGround() then
        self:setState("jump")
    elseif self.attackTimer > 0 then
        if self.alvaysRun then
            self:setState("run_attack")
        else
            self:setState("attack")
        end
    elseif move ~= 0 or self.alvaysRun then
        self:setState("walk")
    else
        self:setState("idle")
    end
end


-- Основное обновление игрока каждый кадр
function Player:update(dt)
    if self.dead then
        self:setState("death")
        self:updateAnimation(dt)
        return
    end

    -- Каждый кадр сначала считаем, что игрок не на платформе.
    -- Если он реально стоит на платформе, Level снова выставит onPlatform = true.
    self.onPlatform = false
	
    local move = 0

    -- Движение влево
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        move = move - 1
    end

    -- Движение вправо
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        move = move + 1
    end

    self.vx = move * self.speed

    -- Если noturn выключен, игрок разворачивается по направлению движения
    -- Если noturn включен, игрок может идти назад, но смотреть будет туда же
    if move ~= 0 and not self.noturn then
        self.facing = move
    end

    -- Горизонтальное движение
    self.x = self.x + self.vx * dt
    self.x = math.max(10, math.min(self.x, 742))

    -- Гравитация
    self.vy = self.vy + self.gravity * dt
    self.y = self.y + self.vy * dt

    -- Приземление
    if self.y > self.groundY then
        self.y = self.groundY
        self.vy = 0
        self.jumpCount = 0
    end

    -- Таймеры атаки
    self.attackTimer = math.max(0, self.attackTimer - dt)
    self.shotCooldown = math.max(0, self.shotCooldown - dt)

    -- Выбор текущей анимации
	self:updateVisualState()
	--обновим анимацию
    self:updateAnimation(dt)
end

-- Обновление кадров текущей анимации
function Player:updateAnimation(dt)
    self.frameTimer = self.frameTimer + dt

    if self.frameTimer < self.frameDuration then
        return
    end

    self.frameTimer = self.frameTimer - self.frameDuration
    self.frame = self.frame + 1

    if self.frame <= 5 then
        return
    end

    if self.state == "death" then
        self.frame = 5
        self.deathFinished = true
    elseif self.state == "pain" then
        self.hurt = false
        self.frame = 1
        self:setState("idle")
    else
        self.frame = 1
    end
end

-- Прыжок
function Player:jump()
    if self.dead then
        return
    end

    -- Обычный прыжок с земли
    if self:isOnGround() then
        self.vy = self.jumpPower
        self.jumpCount = 1
        playRandomSound(self.sounds.jump)

        if not self.hurt then
            self:setState("jump")
        end

        return
    end

    -- Двойной прыжок в воздухе
    if self.doublejump then
        if self.jumpCount == 0 then
            self.jumpCount = 1
        end

        if self.jumpCount < 2 then
            self.vy = self.jumpPower
            self.jumpCount = self.jumpCount + 1
            playRandomSound(self.sounds.jump)

            if not self.hurt then
                self:setState("jump")
            end
        end
    end
end

-- Атака камнем
function Player:attack()
    if self.dead or self.hurt or self.shotCooldown > 0 then
        return
    end

    self.attackTimer = self.attackDuration
    self.shotCooldown = self.shotCooldownDuration
    self.shotRequested = true

	playRandomSound(self.sounds.throw)

-- if alwaysRun = true
	if self.alvaysRun then
		self:setState("run_attack")
	else
		self:setState("attack")
	end
end

-- Main.lua забирает этот флаг и создаёт камень
function Player:consumeShotRequest()
    if not self.shotRequested then
        return false
    end

    self.shotRequested = false
    return true
end

-- Смерть игрока
function Player:die()
    if self.dead then
        return
    end

    self.dead = true
    self.hurt = false
    self.vx = 0
    self.vy = 0
    self.frame = 1
    self.frameTimer = 0
    self.deathFinished = false

    playRandomSound(self.sounds.death)
    self:setState("death")
end

-- Хитбокс игрока для столкновений
function Player:getHitbox()
    return {
        x = self.x + 8,
        y = self.y + 8,
        w = self.w - 16,
        h = self.h - 8
    }
end

-- Отрисовка игрока
function Player:draw()
    local image = self.animations[self.state][self.frame]
    local scaleX = self.facing
    local drawX = self.x

    if self.facing == -1 then
        drawX = self.x + self.w
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(image, drawX, self.y, 0, scaleX, 1)
end

return Player