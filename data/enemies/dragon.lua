return {
    type = "dragon",
    flying = true,

    w = 70,
    h = 70,
    y = 150,

    offsetY = -44,

    speed = 90,
    health = 2,
    damage = 1,
    score = 4,

	canShoot = true,
	shootRange = 350,
	shootChance = 1,
	shootCooldown = 1.2,
	------для теста
	shootStartDelay = 0,

	bulletModel = "DiagonalDownProjectile",
	bulletSpeed = 220,

    flipImage = true,

	   animations = {
	   
        fly = {
            loop = true,
            frameDuration = 0.08,
            frames = {
                "assets/enemies/dragon/attack_1.png",
                "assets/enemies/dragon/attack_2.png"
            }
        },

        attack = {
            loop = false,
            frameDuration = 0.08,
            frames = {
                "assets/enemies/dragon/attack_1.png",
                "assets/enemies/dragon/attack_2.png"
            },
            events = {
                {
                    frame = 2,
                    action = "sound",
                    sound = "assets/sounds/sfx/drop.wav"
                },
                {
                    frame = 2,
                    action = "emitPendingProjectile"
                }
            }
        },

        death = {
            loop = false,
            holdLastFrame = true,
            frameDuration = 0.1,

            -- Важно: событие на 1 кадре должно сработать сразу при старте death.fireFirstFrameEvents = true
            fireFirstFrameEvents = true,

            frames = {
                "assets/enemies/dragon/attack_1.png",
                "assets/enemies/dragon/attack_2.png"
            },
            events = {
                {
                    frame = 1,
                    action = "sound",
                    sound = "assets/sounds/sfx/hit2.wav"
                },
				{
					frame = 2,
					action = "spawnEffect",
					model = "Explosion",
					offsetX = 0,
					offsetY = -44,
					gravity = 900		
				}
			}
        }
			
    }
}