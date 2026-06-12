return {
    w = 64,
    h = 64,

    alpha = 0.35,
    sound = "assets/sounds/sfx/hit2.wav",

    damage = 1,
    damageRadius = 70,

    -- По умолчанию true, можно не писать.
    damagePlayer = true,

    -- Если нужно, чтобы взрыв дамажил врагов.
    damageEnemies = false,

    gravity = 0,
    removeWhenAnimationFinished = true,

    animations = {
        idle = {
            loop = false,
            frameDuration = 0.18,
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


--Если хочешь эффект, который дамажит только врагов, например магический взрыв игрока:
--damage = 1,
--damageRadius = 80,
--damagePlayer = false,
--damageEnemies = true,

--Если хочешь просто визуальный эффект без урона:
--damage = 0 или вообще не указывать damage.