return {
    type = "companion",

    entityType = "npc",

    w = 40,
    h = 52,

    health = 10,
    damage = 1,

    speed = 130,

    followPlayer = true,
    followDistance = 90,
    followSpeed = 150,

    MoveDirection = 0,
    flipImage = true,

    hates = {
        enemy = true
    },
---можно без них, это логика для режима сражений	
--отдана комманда актору - стоять
--	command = "hold",
--отдана комманда актору - бежать	
	--command = "retreat",
	--commandRetreatSpeed = 220
--отдана комманда актору - вперед (обычный режим)	
--	command = "advance",

	movementMode = "chase",
	stopInAttackRange = true, --не продолжать идти на цель, а атаковать его пока не пебедишь

    canMeleeAttack = true,
    meleeRange = 35,
    meleeChance = 1,
    meleeCooldown = 0.7,
    meleeProjectileModel = "CompanionMeleeProjectile",

    retreatAfterMelee = true,
    meleeRetreatDistance = 35,

    color = {0.25, 0.55, 1.0},

    animations = {
		idle = {
			loop = true,
			frameDuration = 0.12,
			frames = {
				"assets/npcs/companion/walk_1.png",
				"assets/npcs/companion/walk_1.png"
			}
		},
        walk = {
            loop = true,
            frameDuration = 0.1,
            frames = {
                "assets/npcs/companion/walk_1.png",
                "assets/npcs/companion/walk_2.png"
            }
        },

        turn = {
            loop = false,
            frameDuration = 0.08,
            frames = {
                "assets/npcs/companion/turn_1.png",
                "assets/npcs/companion/turn_2.png"
            }
        },

        attack = {
            loop = false,
            frameDuration = 0.08,
            frames = {
                "assets/npcs/companion/attack_1.png",
                "assets/npcs/companion/attack_2.png"
            },
            events = {
			    {
                    frame = 2,
                    action = "sound",
                    sound = "assets/sounds/sfx/hittt.wav"
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
            frameDuration = 0.12,
            frames = {
                "assets/npcs/companion/death_1.png",
                "assets/npcs/companion/death_2.png"
            }
        }
    }
}