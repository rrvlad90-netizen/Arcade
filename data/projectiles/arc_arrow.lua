return {
    w = 32,
    h = 8,

    damage = 1,

    image = "assets/projectiles/arrow.png",

    -- Начальная вертикальная скорость.
    -- Отрицательное значение означает вверх.
    vy = -260,

    -- Чем больше gravity, тем быстрее стрела начнёт падать.
    gravity = 700,

    rotateToVelocity = true,

    -- Если стрела упадёт в землю/возвышенность — исчезнет с эффектом.
    collideGround = true,
    collidePlatforms = true,
	
--Настройка дуги:  более пологая дуга.
--vy = -180,
--gravity = 600

--	Настройка дуги:  будет высокий навес и быстрое падение.
--vy = -360,
--gravity = 900

--bulletSpeed = 160 ---стрела летит ближе.
--bulletSpeed = 320 ---стрела летит дальше.	

    impactEffect = {
        model = "Explosion"
    },

    impactOffsetX = -32,
    impactOffsetY = -32,

    color = {0.75, 0.45, 0.18}
}