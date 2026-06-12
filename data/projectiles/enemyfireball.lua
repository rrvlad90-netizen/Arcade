return {
    w = 18,
    h = 18,

    damage = 1,
	
	damageTargets = {
        player = true,
        npc = true
    },
	
    alpha = 0.45,

    animations = {
        idle = {
            loop = true,
            frameDuration = 0.06,
            frames = {
                "assets/projectiles/magic_1.png",
                "assets/projectiles/magic_2.png",
                "assets/projectiles/magic_1.png"
            }
        }
    },

    color = {0.4, 0.7, 1.0}
}
