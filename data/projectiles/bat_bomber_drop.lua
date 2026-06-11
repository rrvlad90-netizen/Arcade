return {
    w = 12,
    h = 16,

    vx = 0,
    vy = 280,

    damage = 1,

    image = "assets/enemies/bat_bomber/drop.png",

    collideGround = true,
    collidePlatforms = true,

    impactEffect = {
        model = "Explosion"
    },

    -- Смещаем explosion так, чтобы он появился вокруг центра бомбы.
    impactOffsetX = -32,
    impactOffsetY = -32,

    color = {1.0, 0.25, 0.2}
}