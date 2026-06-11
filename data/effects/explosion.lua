return {
    w = 64,
    h = 64,
	
	alpha = 0.55, -- прозрачность 
	
	sound = "assets/sounds/sfx/hit2.wav", --  создаётся и сразу проигрывает звук
		
    gravity = 0,

----Для взрыва надо отключить столкновения.
	collideGround = false,
	collidePlatforms = false,
	removeOnImpact = false,

    removeWhenAnimationFinished = true,

    animations = {
        idle = {
            loop = false,
            frameDuration = 0.65,
            frames = {
                "assets/effects/explosion_1.png",
                "assets/effects/explosion_2.png",
                "assets/effects/explosion_3.png",
                "assets/effects/explosion_4.png"
            }
        }
    },

    color = {1.0, 0.45, 0.1}
}