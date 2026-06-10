return {
type = "shooter",
sprite_folder = "assets/enemies/shooter",
w = 42,
h = 52,

----настройка вероятности появления монстра для generate режима
spawnChance = 15,

-----смещение картики (что бы в paint не ровнять)
offsetX = 0,
offsetY = -24,	


attackEventFrame = 3,					
speed = 90,
damage = 1,
score = 3,

canShoot = true,
shootChance = 0.4,
shootCooldown = 1.5,
shootRange = 500,

bulletModel = "FlyingShooterBullet",

taunt = false,
DissaperWheOutOfScreen = 100,

color = {0.9, 0.25, 0.2}
}