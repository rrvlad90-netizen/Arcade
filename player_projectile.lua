local ModelResolver = require("model_resolver")
local PlayerProjectileModels = require("data.player_projectiles")

local PlayerProjectile = {}
PlayerProjectile.__index = PlayerProjectile

local function fileExists(path)
    return path and love.filesystem.getInfo(path) ~= nil
end


--copy/resolve функции подгружают пули игрока
local function copyTable(source)
    local result = {}

    for key, value in pairs(source or {}) do
        result[key] = value
    end

    return result
end

local function resolveProjectileConfig(config)
    if type(config) == "string" then
        config = {
            model = config
        }
    end

    if config and config.model then
        return ModelResolver.resolve(
            config,
            PlayerProjectileModels,
            "player projectile"
        )
    end

    return copyTable(config or {})
end



function PlayerProjectile:new(config)
    local projectile = setmetatable({}, PlayerProjectile)

    projectile.x = config.x or 0
    projectile.y = config.y or 0
    projectile.w = config.w or 12
    projectile.h = config.h or 12

    projectile.vx = config.vx or config.speed or 420
    projectile.damage = config.damage or 1
	
	projectile.impactEffect = config.impactEffect
    or config.impact_effect

	projectile.impactOffsetX = config.impactOffsetX
    or config.impact_offset_x
    or 0

projectile.impactOffsetY = config.impactOffsetY
    or config.impact_offset_y
    or 0


    projectile.imagePath = config.image
    projectile.image = nil

    if fileExists(projectile.imagePath) then
        projectile.image = love.graphics.newImage(projectile.imagePath)
    end

    projectile.color = config.color or {0.55, 0.48, 0.38}
    projectile.outlineColor = config.outlineColor or {0.25, 0.22, 0.18}

    return projectile
end

function PlayerProjectile:fromPlayer(player, projectileConfig)
    local config = resolveProjectileConfig(projectileConfig or "Stone")

    local speed = config.speed
        or math.abs(config.vx or 420)

    local spawnOffsetX = config.spawnOffsetX
        or config.spawn_offset_x
        or 34

    local spawnOffsetY = config.spawnOffsetY
        or config.spawn_offset_y
        or 22

    config.x = player.x + player.facing * spawnOffsetX
    config.y = player.y + spawnOffsetY
    config.vx = speed * player.facing

    return PlayerProjectile:new(config)
end

function PlayerProjectile:update(dt)
    self.x = self.x + self.vx * dt
end

function PlayerProjectile:isOffscreen(screenWidth)
    screenWidth = screenWidth or love.graphics.getWidth()

    return self.x + self.w < -30
        or self.x > screenWidth + 30
end

function PlayerProjectile:getHitbox()
    return {
        x = self.x,
        y = self.y,
        w = self.w,
        h = self.h
    }
end

function PlayerProjectile:draw()
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
    love.graphics.circle("fill", self.x + self.w / 2, self.y + self.h / 2, 7)

    love.graphics.setColor(self.outlineColor)
    love.graphics.circle("line", self.x + self.w / 2, self.y + self.h / 2, 7)

    love.graphics.setColor(1, 1, 1)
end

return PlayerProjectile