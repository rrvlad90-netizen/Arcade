---обертка, логика вынесена в projectile.lua
local Projectile = require("projectile")

local EnemyBullet = {}
EnemyBullet.__index = EnemyBullet
setmetatable(EnemyBullet, {__index = Projectile})

function EnemyBullet:new(config)
    config = config or {}

    -- По умолчанию вражеский projectile дамажит игрока.
    if not config.damageTargets
        and not config.damage_targets
        and config.damagePlayer == nil
        and config.damage_player == nil
    then
        config.damageTargets = {
            player = true
        }
    end

    local bullet = Projectile:new(config)

    return setmetatable(bullet, EnemyBullet)
end

return EnemyBullet