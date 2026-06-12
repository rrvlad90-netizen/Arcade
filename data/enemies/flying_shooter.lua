return {
    type = "flying_shooter",
    sprite_folder = "assets/enemies/flying_shooter",

    flying = true,
    y = 150,

    w = 44,
    h = 36,

    speed = 80,
    damage = 1,
    score = 4,

    health = 2,

    canShoot = true,
    shootChance = 0.5,
    shootCooldown = 1.4,
    shootRange = 520,

    -- Projectile по€витс€ на attack_3.png
    attackEventFrame = 3,

    bulletModel = "EnemyFireball",

    -- ≈сли flyAmplitude = 0, летит ровно без покачивани€.
    flyAmplitude = 10,
    flyFrequency = 3,

    color = {0.8, 0.35, 1.0}
}