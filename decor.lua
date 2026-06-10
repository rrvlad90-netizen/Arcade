local Decor = {}
Decor.__index = Decor

local function fileExists(path)
    return path and love.filesystem.getInfo(path) ~= nil
end

function Decor:new(config)
    local decor = setmetatable({}, Decor)

    decor.x = config.x or 0
    decor.y = config.y or 0
    decor.w = config.w or config.width or 64
    decor.h = config.h or config.height or 64

    -- layer = "back"  Ч за объектами
    -- layer = "front" Ч перед объектами
    decor.layer = config.layer
        or config.drawLayer
        or "back"

    if config.front == true then
        decor.layer = "front"
    end

    -- ѕоложительна¤ скорость двигает декор справа налево.
    -- 0 Ч стоит на месте.
    decor.scrollSpeed = config.speed
        or config.DecorScrollSpeed
        or config.decorScrollSpeed
        or 0

    decor.DissaperWheOutOfScreen = config.DissaperWheOutOfScreen
        or config.disappearWhenOutOfScreen
        or 100

    decor.imagePath = config.image
    decor.image = nil

    if fileExists(decor.imagePath) then
        decor.image = love.graphics.newImage(decor.imagePath)
    end

    decor.color = config.color or {0.45, 0.45, 0.45}

    return decor
end

function Decor:update(dt)
    self.x = self.x - self.scrollSpeed * dt
end

function Decor:isOffscreen()
    if self.DissaperWheOutOfScreen == 0 then
        return false
    end

    local screenWidth = love.graphics.getWidth()
    local margin = self.DissaperWheOutOfScreen

    return self.x + self.w < -margin
        or self.x > screenWidth + margin
end

function Decor:isRemovable()
    return self:isOffscreen()
end

function Decor:draw()
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

    -- ћокап декора
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 6, 6)

    love.graphics.setColor(1, 1, 1, 0.35)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h, 6, 6)

    love.graphics.setColor(1, 1, 1)
end

return Decor