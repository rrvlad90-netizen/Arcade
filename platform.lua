local Platform = {}
Platform.__index = Platform

local function fileExists(path)
    return path and love.filesystem.getInfo(path) ~= nil
end

function Platform:new(config)
    local platform = setmetatable({}, Platform)

    -- Позиция платформы
    platform.x = config.x or 0
    platform.y = config.y or 0

    -- Размер физической платформы
    platform.w = config.w or config.width or 128
    platform.h = config.h or config.height or 24
	
	
-- solid = true означает, что через платформу нельзя пройти.
    -- false/nil — обычная платформа, на неё можно запрыгнуть сверху,
    -- но сбоку она не блокирует игрока.
    platform.solid = config.solid == true	

    -- Линия, по которой может ходить игрок.
    -- Обычно совпадает с верхом платформы.
	platform.walkOffsetY = config.walkOffsetY
		or config.walk_offset_y
		or 0

	platform.walkY = config.walkY
		or config.platformWalkY
		or platform.y + platform.walkOffsetY

    -- Визуальная координата Y, откуда рисуется картинка платформы.
    -- Можно сделать ниже/выше walkY для красивой настройки.
	platform.visualOffsetY = config.visualOffsetY
		or config.visual_offset_y
		or 0

	platform.visualY = config.visualY
		or config.platformVisualY
		or platform.y + platform.visualOffsetY

    -- Визуальная высота платформы.
    -- Нужна, чтобы растягивать картинку по Y.
    platform.visualHeight = config.visualHeight
        or config.platformVisualHeight
        or platform.h

    -- Скорость движения платформы.
    -- Положительное число: справа налево.
    -- Отрицательное число: слева направо.
    -- 0: платформа стоит на месте.
    platform.scrollSpeed = config.PlatformScrollSpeed
        or config.platformScrollSpeed
        or 0

-- Если DissaperWheOutOfScreen не 0, платформа удаляется, когда вышла за экран.
    -- Значение — запас в пикселях за границей экрана.
    -- По умолчанию 100.
    platform.DissaperWheOutOfScreen = config.DissaperWheOutOfScreen
        or config.disappearWhenOutOfScreen
        or 100

    -- Смещение за последний кадр.
    -- Потом пригодится, если захотим, чтобы платформа тащила игрока.
    platform.deltaX = 0

    -- Картинка платформы.
    -- Если картинки нет, рисуем мокап.
    platform.imagePath = config.image
    platform.image = nil

    if fileExists(platform.imagePath) then
        platform.image = love.graphics.newImage(platform.imagePath)
    end

    platform.color = config.color or {0.35, 0.3, 0.25}

    return platform
end

function Platform:update(dt)
    self.deltaX = -self.scrollSpeed * dt
    self.x = self.x + self.deltaX
end

function Platform:getHitbox()
    return {
        x = self.x,
        y = self.y,
        w = self.w,
        h = self.h
    }
end

function Platform:overlapsX(rect)
    return rect.x < self.x + self.w
        and rect.x + rect.w > self.x
end

function Platform:canLandPlayer(player, previousPlayerY)
    local playerHitbox = player:getHitbox()

    local previousFeetY = previousPlayerY + player.h
    local currentFeetY = player.y + player.h

    return player.vy >= 0
        and self:overlapsX(playerHitbox)
        and previousFeetY <= self.walkY
        and currentFeetY >= self.walkY
end

function Platform:landPlayer(player)
    player.y = self.walkY - player.h
    player.x = player.x + self.deltaX
    player.vy = 0
    player.onPlatform = true

    if player.jumpCount ~= nil then
        player.jumpCount = 0
    end
end




function Platform:resolvePlayerCollision(player, previousPlayerX, previousPlayerY)
    local playerHitbox = player:getHitbox()
    local platformHitbox = self:getHitbox()

    local isOverlapping =
        playerHitbox.x < platformHitbox.x + platformHitbox.w
        and platformHitbox.x < playerHitbox.x + playerHitbox.w
        and playerHitbox.y < platformHitbox.y + platformHitbox.h
        and platformHitbox.y < playerHitbox.y + playerHitbox.h

    if not isOverlapping then
        return false
    end

    local previousHitbox = {
        x = previousPlayerX + 8,
        y = previousPlayerY + 8,
        w = player.w - 16,
        h = player.h - 8
    }

    local previousFeetY = previousPlayerY + player.h
    local currentFeetY = player.y + player.h

    -- Приземление сверху.
    if player.vy >= 0
        and previousFeetY <= self.walkY
        and currentFeetY >= self.walkY
        and self:overlapsX(playerHitbox)
    then
        self:landPlayer(player)
        return true
    end

    -- Обычная платформа не блокирует сбоку.
    if not self.solid then
        return false
    end

    -- Ударились головой снизу.
    if player.vy < 0
        and previousHitbox.y >= platformHitbox.y + platformHitbox.h
    then
        player.y = platformHitbox.y + platformHitbox.h - 8
        player.vy = 0
        return true
    end

    local hitboxOffsetX = playerHitbox.x - player.x

    -- Упёрлись в левую сторону возвышенности.
    if previousHitbox.x + previousHitbox.w <= platformHitbox.x then
        player.x = platformHitbox.x - hitboxOffsetX - playerHitbox.w
        player.vx = 0
        return true
    end

    -- Упёрлись в правую сторону возвышенности.
    if previousHitbox.x >= platformHitbox.x + platformHitbox.w then
        player.x = platformHitbox.x + platformHitbox.w - hitboxOffsetX
        player.vx = 0
        return true
    end

    -- Fallback: если игрок уже оказался внутри solid-платформы,
    -- выталкиваем его в ближайшую сторону.
    local overlapFromLeft = playerHitbox.x + playerHitbox.w - platformHitbox.x
    local overlapFromRight = platformHitbox.x + platformHitbox.w - playerHitbox.x

    if overlapFromLeft < overlapFromRight then
        player.x = platformHitbox.x - hitboxOffsetX - playerHitbox.w
    else
        player.x = platformHitbox.x + platformHitbox.w - hitboxOffsetX
    end

    player.vx = 0
    return true
end




function Platform:draw()
    if self.image then
        love.graphics.setColor(1, 1, 1)

        love.graphics.draw(
            self.image,
            self.x,
            self.visualY,
            0,
            self.w / self.image:getWidth(),
            self.visualHeight / self.image:getHeight()
        )
    else
        love.graphics.setColor(self.color)
        love.graphics.rectangle(
            "fill",
            self.x,
            self.visualY,
            self.w,
            self.visualHeight,
            4,
            4
        )

        love.graphics.setColor(0.18, 0.14, 0.12)
        love.graphics.rectangle(
            "line",
            self.x,
            self.visualY,
            self.w,
            self.visualHeight,
            4,
            4
        )
    end

    -- Временная линия walkY, чтобы удобно было настраивать платформу.
    love.graphics.setColor(1, 1, 1, 0.25)
    love.graphics.line(self.x, self.walkY, self.x + self.w, self.walkY)

    love.graphics.setColor(1, 1, 1)
end


function Platform:isOffscreen()
    if self.DissaperWheOutOfScreen == 0 then
        return false
    end

    local screenWidth = love.graphics.getWidth()
    local margin = self.DissaperWheOutOfScreen

    return self.x + self.w < -margin
        or self.x > screenWidth + margin
end

function Platform:isRemovable()
    return self:isOffscreen()
end

return Platform