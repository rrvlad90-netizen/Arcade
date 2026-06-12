return {
    w = 14,
    h = 14,

    damage = 1,

    -- Этот флаг скажет enemy.lua:
    -- "лети прямо в сторону центра цели".
    aimAtTarget = true,

    speed = 260,

    gravity = 0,

    rotateToVelocity = true,

    alpha = 1,

    damageTargets = {
        player = true,
        npc = true
    },

    impactEffect = {
        model = "Explosion"
    },

    impactOffsetX = -32,
    impactOffsetY = -32,

    color = {0.45, 0.85, 1.0}
}