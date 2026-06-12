return {
    w = 14,
    h = 14,

    damage = 1,

    -- X задаст enemy.lua через bulletSpeed и направление цели.
    -- Y задаём здесь: положительное значение летит вниз.
    vy = 180,

    gravity = 700,

    rotateToVelocity = true,

    alpha = 1,

    damageTargets = {
        player = true,
        npc = true
    },

--    rotateToVelocity = true,

    -- Если упадёт в землю/возвышенность — исчезнет с эффектом.
    collideGround = true,
    collidePlatforms = true,

    impactEffect = {
        model = "ExplosionDamage"
    },

    impactOffsetX = -32,
    impactOffsetY = -32,

    color = {1.0, 0.35, 0.1}
}