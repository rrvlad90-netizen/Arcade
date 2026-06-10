return {
type = "jumper",
sprite_folder = "assets/enemies/jumper",
w = 42,
h = 48,

----настройка вероятности появления монстра для generate режима
spawnChance = 10,

speed = 120,
damage = 1,
score = 3,

attackEventFrame = 3,

canJumpAttack = true,
jumpChance = 0.3,
jumpAttackRange = 220,
jumpCooldown = 2.0,

jumpSpeedX = 260,
jumpPower = -360,

jumpRetreatSteps = 20,
jumpRetreatStepSize = 6,

taunt = false,
DissaperWheOutOfScreen = 100,

color = {0.3, 0.65, 1.0}
}