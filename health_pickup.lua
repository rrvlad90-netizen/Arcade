local HealthPickup = {}
HealthPickup.__index = HealthPickup

local function fileExists(path)
    return path and love.filesystem.getInfo(path) ~= nil
end

function HealthPickup:new(config)
    local pickup = setmetatable({}, HealthPickup)

    pickup.x = config.x or 0
    pickup.y = config.y or 0
    pickup.w = config.w or config.width or 32
    pickup.h = config.h or config.height or 32

    pickup.healAmount = config.healAmount
        or config.heal_amount
        or config.health
        or 1

    -- Если speed = 0, аптечка стоит на месте.
    -- Если speed > 0, аптечка летит/движется к игроку.
    pickup.speed = config.speed or 0

    pickup.appearAfter = config.appearAfter
        or config.appear_after
        or 0

    pickup.elapsed = 0
    pickup.active = pickup.appearAfter <= 0
    pickup.collected = false

    pickup.imagePath = config.image
    pickup.image = nil

    if fileExists(pickup.imagePath) then
        pickup.image = love.graphics.newImage(pickup.imagePath)
    end

    pickup.color = config.color or {0.2, 0.9, 0.35}

    return pickup
end

function HealthPickup:update(dt, player)
    if self.collected then
        return
    end

    if not self.active then
        self.elapsed = self.elapsed + dt

        if self.elapsed >= self.appearAfter then
            self.active = true
        end

        return
    end

    if self.speed <= 0 or not player then
        return
    end

    local selfCenterX = self.x + self.w / 2
    local selfCenterY = self.y + self.h / 2

    local playerCenterX = player.x + player.w / 2
    local playerCenterY = player.y + player.h / 2

    local dx = playerCenterX - selfCenterX
    local dy = playerCenterY - selfCenterY
    local distance = math.sqrt(dx * dx + dy * dy)

    if distance <= 1 then
        return
    end

    self.x = self.x + dx / distance * self.speed * dt
    self.y = self.y + dy / distance * self.speed * dt
end

function HealthPickup:getHitbox()
    return {
        x = self.x,
        y = self.y,
        w = self.w,
        h = self.h
    }
end

function HealthPickup:canCollect()
    return self.active and not self.collected
end

function HealthPickup:collect()
    self.collected = true
end

function HealthPickup:draw()
    if not self.active or self.collected then
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

    -- Мокап аптечки
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 6, 6)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle(
        "fill",
        self.x + self.w * 0.42,
        self.y + self.h * 0.18,
        self.w * 0.16,
        self.h * 0.64
    )

    love.graphics.rectangle(
        "fill",
        self.x + self.w * 0.18,
        self.y + self.h * 0.42,
        self.w * 0.64,
        self.h * 0.16
    )

    love.graphics.setColor(0.05, 0.25, 0.08)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h, 6, 6)

    love.graphics.setColor(1, 1, 1)
end

return HealthPickup