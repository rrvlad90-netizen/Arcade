return {
    w = 64,
    h = 64,
	
	alpha = 0.15, -- прозрачность 
	
	sound = "assets/sounds/sfx/hit2.wav", --  создаётся и сразу проигрывает звук
		
    gravity = 0,

    removeWhenAnimationFinished = true,

    animations = {
        idle = {
            loop = false,
            frameDuration = 11.07,
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