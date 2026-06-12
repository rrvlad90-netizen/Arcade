return {
    w = 60,
    h = 60,

    image = "assets/enemies/goblin/death_1.png",

    -- directionMultiplier сам развернёт vx в нужную сторону.
	vx = 280,
	vy = -650,
	gravity = 1100,

    collideGround = true,
    collidePlatforms = true,

    removeOnImpact = true,

    impactEffect = {
        model = "Explosion"
    },

    impactOffsetX = -20,
    impactOffsetY = -20,

    removeWhenAnimationFinished = false,

    color = {0.45, 0.45, 0.45}
}