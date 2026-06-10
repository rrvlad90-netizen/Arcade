local EnemyBullet = {}
EnemyBullet.__index = EnemyBullet

local function fileExists(path)
    return path and love.filesystem.getInfo(path) ~= nil
end

function EnemyBullet:new(config)
    local bullet = setmetatable({}, EnemyBullet)

    bullet.x = config.x or 0
    bullet.y = config.y or 0
    bullet.w = config.w or 12
    bullet.h = config.h or 12

	bullet.vx = config.vx or -220   --снаряд летит по прямой
	bullet.vy = config.vy or 0   ---снаряд падает с неба
	bullet.damage = config.damage or 1

    bullet.imagePath = config.image
    bullet.image = nil

    if fileExists(bullet.imagePath) then
        bullet.image = love.graphics.newImage(bullet.imagePath)
    end

    bullet.color = config.color or {1.0, 0.25, 0.2}

    return bullet
end

function EnemyBullet:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

function EnemyBullet:isOffscreen()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    return self.x + self.w < -100
        or self.x > screenWidth + 100
        or self.y + self.h < -100
        or self.y > screenHeight + 100
end

function EnemyBullet:getHitbox()
    return {
        x = self.x,
        y = self.y,
        w = self.w,
        h = self.h
    }
end

function EnemyBullet:draw()
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

    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x + self.w / 2, self.y + self.h / 2, self.w / 2)

    love.graphics.setColor(0.25, 0.05, 0.04)
    love.graphics.circle("line", self.x + self.w / 2, self.y + self.h / 2, self.w / 2)
end

return EnemyBullet