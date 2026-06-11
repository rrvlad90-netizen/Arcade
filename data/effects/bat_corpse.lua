return {
    w = 70,
    h = 70,

	loop = true,--чтобы труп не удалялся по завершению анимации, а жил до удара об землю нужно true
	removeWhenAnimationFinished = false, -- а здесь false

    image = "assets/enemies/bat_bomber/death_1.png",

    -- Летит чуть влево.
    vx = 80,

    -- Падает вниз.
    vy = 0,
    gravity = 900,

    collideGround = true,
    collidePlatforms = true,

    removeOnImpact = true,

    impactEffect = {
        model = "Explosion"
    },

    impactOffsetX = 10,
    impactOffsetY = 20,

    color = {0.45, 0.45, 0.45}
}