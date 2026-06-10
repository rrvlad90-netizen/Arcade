local Hazard = {}
Hazard.__index = Hazard

local function fileExists(path)
    return path and love.filesystem.getInfo(path) ~= nil
end

function Hazard:new(config)
    local hazard = setmetatable({}, Hazard)

    -- Позиция опасной зоны
    hazard.x = config.x or 0
    hazard.y = config.y or 0

    -- Ширина и высота области поражения
    hazard.damageWidth = config.damageWidth
        or config.damage_width
        or config.w
        or config.width
        or 100

    hazard.damageHeight = config.damageHeight
        or config.damage_height
        or config.h
        or config.height
        or 40

    -- Визуальная ширина/высота.
    -- По умолчанию совпадает с областью поражения.
    hazard.visualWidth = config.visualWidth
        or config.visual_width
        or hazard.damageWidth

    hazard.visualHeight = config.visualHeight
        or config.visual_height
        or hazard.damageHeight

    -- Урон игроку
    hazard.damage = config.damage or 1

    -- Если true, hazard также убивает/дамажит врагов
    hazard.damageEnemy = config.damageEnemy == true

    -- Скорость движения hazard.
    -- Положительное число: справа налево.
    -- Отрицательное число: слева направо.
    -- 0: стоит на месте.
    hazard.scrollSpeed = config.HazardScrollSpeed
        or config.hazardScrollSpeed
        or 0

    -- Если не 0, hazard удаляется после выхода за экран
    hazard.DissaperWheOutOfScreen = config.DissaperWheOutOfScreen
        or config.disappearWhenOutOfScreen
        or 100

    -- Картинка hazard
    hazard.imagePath = config.image
    hazard.image = nil
    hazard.quad = nil

    if fileExists(hazard.imagePath) then
        hazard.image = love.graphics.newImage(hazard.imagePath)

        local cropWidth = math.min(hazard.damageWidth, hazard.image:getWidth())
        local cropHeight = math.min(hazard.damageHeight, hazard.image:getHeight())

        -- Картинка обрезается по ширине поражения
        hazard.quad = love.graphics.newQuad(
            0,
            0,
            cropWidth,
            cropHeight,
            hazard.image:getWidth(),
            hazard.image:getHeight()
        )
    end

    hazard.color = config.color or {0.65, 0.05, 0.05}

    return hazard
end

function Hazard:update(dt)
    self.x = self.x - self.scrollSpeed * dt
end

function Hazard:getHitbox()
    return {
        x = self.x,
        y = self.y,
        w = self.damageWidth,
        h = self.damageHeight
    }
end

function Hazard:isOffscreen()
    if self.DissaperWheOutOfScreen == 0 then
        return false
    end

    local screenWidth = love.graphics.getWidth()
    local margin = self.DissaperWheOutOfScreen

    return self.x + self.damageWidth < -margin
        or self.x > screenWidth + margin
end

function Hazard:isRemovable()
    return self:isOffscreen()
end

function Hazard:draw()
    if self.image and self.quad then
        local _, _, quadWidth, quadHeight = self.quad:getViewport()

        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(
            self.image,
            self.quad,
            self.x,
            self.y,
            0,
            self.visualWidth / quadWidth,
            self.visualHeight / quadHeight
        )

        return
    end

    -- Мокап опасной зоны
    love.graphics.setColor(self.color)
    love.graphics.rectangle(
        "fill",
        self.x,
        self.y,
        self.visualWidth,
        self.visualHeight
    )

    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle(
        "line",
        self.x,
        self.y,
        self.damageWidth,
        self.damageHeight
    )

    love.graphics.setColor(1, 1, 1)
end

return Hazard