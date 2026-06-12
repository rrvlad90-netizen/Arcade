return {
type = "shooter",
---sprite_folder = "assets/enemies/goblin",
w = 40,
h = 52,

----настройка веро€тности по€влени€ монстра дл€ generate режима
spawnChance = 30,
health = 2,
showHealthBar = false,

-----смещение картики (что бы в paint не ровн€ть)
offsetX = 0,
offsetY = -24,

movementMode = "keepDistance",

canShoot = true,
shootRange = 200,  --200!!!
shootChance = 1,
shootCooldown = 1.2,
shootStartDelay = 0,

bulletModel = "ArcArrow",
bulletSpeed = 240,

preferredDistance = 100,  ----100!!!
tooCloseDistance = 50,  ---50!!!!

MoveDirection = 0,
stopInAttackRange = true,

alpha = 0.5, -- прозрачность

MoveDirection = 0,

---можно без них, это логика для режима сражений	
--отдана комманда актору - стоять
--	command = "hold",
--отдана комманда актору - бежать	
	--command = "retreat",
	--commandRetreatSpeed = 220
--отдана комманда актору - вперед (обычный режим)	
	command = "advance",

--flipImage = true, --если неправильно нарисовал спрайт то его развернем
speed = 170,
damage = 1,
score = 2,
taunt = false,

DissaperWheOutOfScreen = 100,
color = {0.8, 0.35, 0.2},

   animations = {
		  idle = {
			loop = true,
			frameDuration = 0.12,
			frames = {
				"assets/enemies/shooter/walk_1.png",
				"assets/enemies/shooter/walk_1.png"
			}
		}, 
        walk = {
            loop = true,
            frameDuration = 0.08,
            frames = {
                "assets/enemies/shooter/walk_1.png",
                "assets/enemies/shooter/walk_2.png"
            }
        },
		turn = {  --≈сли turn не укажешь то будет разворачиватьс€ мгновенно без анимации.
			loop = false,
			holdLastFrame = true,
			frameDuration = 0.08,
			frames = {
				"assets/enemies/shooter/walk_1.png",
				"assets/enemies/shooter/walk_1.png"
			}
		},
        attack = {
            loop = false,
            frameDuration = 0.08,
            frames = {
                "assets/enemies/shooter/walk_2.png",
                "assets/enemies/shooter/walk_2.png"
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

            -- ¬ажно: событие на 1 кадре должно сработать сразу при старте death.
            fireFirstFrameEvents = true,

            frames = {
                "assets/enemies/shooter/death_1.png",
                "assets/enemies/shooter/death_2.png",
                "assets/enemies/shooter/death_3.png"
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