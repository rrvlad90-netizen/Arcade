return {

---Ещё важный момент: для события на frame = 1 нужно:
---fireFirstFrameEvents = true
---Иначе звук на первом кадре не сработает при входе в анимацию.

    type = "bat_bomber",
    flying = true,

    w = 70,
    h = 70,
    y = 150,

    offsetY = -44,

    speed = 90,
    health = 2,
    damage = 1,
    score = 4,

    canDropProjectile = true,
    dropChance = 0.55,
    dropCooldown = 1.4,
    dropRangeX = 90,

    dropProjectileModel = "BatBomberDrop",

    flipImage = true,

    animations = {
        fly = {
            loop = true,
            frameDuration = 0.08,
            frames = {
                "assets/enemies/bat_bomber/fly_1.png",
                "assets/enemies/bat_bomber/fly_2.png",
                "assets/enemies/bat_bomber/fly_3.png",
                "assets/enemies/bat_bomber/fly_4.png"
            }
        },

        attack = {
            loop = false,
            frameDuration = 0.08,
            frames = {
                "assets/enemies/bat_bomber/attack_1.png",
                "assets/enemies/bat_bomber/attack_2.png",
                "assets/enemies/bat_bomber/attack_3.png",
                "assets/enemies/bat_bomber/attack_4.png"
            },
            events = {
                {
                    frame = 3,
                    action = "sound",
                    sound = "assets/sounds/sfx/drop.wav"
                },
                {
                    frame = 3,
                    action = "emitPendingProjectile"
                }
            }
        },

        death = {
            loop = false,
            holdLastFrame = true,
            frameDuration = 0.1,

            -- Важно: событие на 1 кадре должно сработать сразу при старте death.
            fireFirstFrameEvents = true,

            frames = {
                "assets/enemies/bat_bomber/death_1.png",
                "assets/enemies/bat_bomber/death_2.png",
                "assets/enemies/bat_bomber/death_3.png"
            },
            events = {
                {
                    frame = 1,
                    action = "sound",
                    sound = "assets/sounds/sfx/hit2.wav"
                }
            }
        }
    }
}