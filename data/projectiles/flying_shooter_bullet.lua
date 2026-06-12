----У этой пули не включаем collideGround, поэтому она не будет взрываться от земли.
return {
    w = 12,
    h = 12,

    speed = 260,
    damage = 1,

	damageTargets = {
        player = true,
        npc = true
    },

    image = "assets/enemies/flying_shooter/bullet.png",

    impactEffect = {
        model = "Explosion"
    },

    impactOffsetX = -32,
    impactOffsetY = -32,

    color = {1.0, 0.25, 0.2}
}