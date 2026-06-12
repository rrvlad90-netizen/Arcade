---обертка, логика вынесена в projectile.lua
local Projectile = require("projectile")
local ModelResolver = require("model_resolver")
local PlayerProjectileModels = require("data.player_projectiles")

local PlayerProjectile = {}
PlayerProjectile.__index = PlayerProjectile
setmetatable(PlayerProjectile, {__index = Projectile})

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
    config = config or {}

    -- По умолчанию projectile игрока дамажит врагов.
    if not config.damageTargets
        and not config.damage_targets
        and config.damageEnemy == nil
        and config.damageEnemies == nil
        and config.damage_enemy == nil
        and config.damage_enemies == nil
    then
        config.damageTargets = {
            enemy = true
        }
    end

    local projectile = Projectile:new(config)

    return setmetatable(projectile, PlayerProjectile)
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

return PlayerProjectile