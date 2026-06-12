return {
    w = 80,
    h = 100,

    layer = "back",

    x = 400,
    y = 330,

    speed = 120,

    alpha = 1,

    sound = "assets/sounds/sfx/fire.wav",
    soundLoop = true,

    animations = {
        idle = {
            loop = true,
            frameDuration = 0.12,
            frames = {
                "assets/decors/fire/fire_1.png",
                "assets/decors/fire/fire_2.png",
                "assets/decors/fire/fire_1.png",
                "assets/decors/fire/fire_2.png"
            }
        }
    },

    color = {1.0, 0.45, 0.1}
}