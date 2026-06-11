return {
type = "goblin",
---sprite_folder = "assets/enemies/goblin",
w = 40,
h = 52,
					
----настройка веро€тности по€влени€ монстра дл€ generate режима
spawnChance = 30,					
					
-----смещение картики (что бы в paint не ровн€ть)
offsetX = 0,
offsetY = -24,					
	

attackEventFrame = 3,					
health = 2,
showHealthBar = false,
					
speed = 170,
damage = 1,
score = 2,
taunt = false,
					
DissaperWheOutOfScreen = 100,
color = {0.8, 0.35, 0.2}



   animations = {
        fly = {
            loop = true,
            frameDuration = 0.08,
            frames = {
                "assets/enemies/goblin/walk_1.png",
                "assets/enemies/goblin/walk_2.png"
            }
        },

        attack = {
            loop = false,
            frameDuration = 0.08,
            frames = {
                "assets/enemies/goblin/attack_1.png",
                "assets/enemies/goblin/attack_2.png",
                "assets/enemies/goblin/attack_3.png",
                "assets/enemies/goblin/attack_4.png"
            },
            events = {
                {
                    frame = 2,
                    action = "sound",
                    sound = "assets/sounds/sfx/drop.wav"
                },
                {
                    frame = 2,
                    action = "MeleeProjectile"
                }
            }
        },

        death = {
            loop = false,
            holdLastFrame = true,
            frameDuration = 0.1,

            -- ¬ажно: событие на 1 кадре должно сработать сразу при старте death.
            fireFirstFrameEvents = true,

            frames = {
                "assets/enemies/goblinr/death_1.png",
                "assets/enemies/goblin/death_2.png",
                "assets/enemies/goblin/death_3.png"
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
					--gravity = 0	 --можно не писать так как уже указанов эффекте дл€ Explosion	
				}
			}
        }		
    }


}