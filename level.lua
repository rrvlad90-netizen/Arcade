local Platform = require("platform")
local Hazard = require("hazard")
local HealthPickup = require("health_pickup")
local Decor = require("decor")
local LevelEnd = require("level_end")
local EnemySpawner = require("enemy_spawner")

local ModelResolver = require("model_resolver")

local EnemyModels = require("data.enemies")
local PickupModels = require("data.pickups")
local DecorModels = require("data.decors")
local HazardModels = require("data.hazards")
local PlatformModels = require("data.platforms")
local LevelEndModels = require("data.level_ends")

local Level = {}
Level.__index = Level

-- Проверяем, существует ли файл в проекте Love2D
local function fileExists(path)
    return path and love.filesystem.getInfo(path) ~= nil
end

-- Безопасно загружаем картинку.
-- Если файла нет, возвращаем nil, а уровень сам нарисует мокап.
local function loadImage(path)
    if fileExists(path) then
        return love.graphics.newImage(path)
    end

    return nil
end

function Level:new(config)
    local level = setmetatable({}, Level)
    -- Музыка уровня
    level.musicPath = config.music
    -- Sky — самый дальний слой фона, например небо
    level.skyPath = config.sky
	-- Background1 — дальний фон, например горы
	level.background1Path = config.background1
	-- Background2 — ближний фон, например ёлки.
	-- config.background оставляем для совместимости со старым кодом.
	level.background2Path = config.background2
		or config.background
	-- Front — передний слой, например кусты.
	-- Он рисуется поверх игрока, врагов, пуль и платформ.
	level.frontPath = config.front
		or config.foreground
    -- Ground — земля, по которой ходит игрок
    level.groundPath = config.ground	
-- Если true, уровень работает как runner.
    -- Игрок не играет idle-анимацию, а всегда выглядит бегущим.
    level.alwaysRun = config.alwaysRun == true
        or config.alvaysRun == true		
-- Платформы уровня.
	level.platforms = ModelResolver.createObjects(
		config.platforms,
		PlatformModels,
		Platform,
		"platform"
	)	
-- Опасные зоны уровня: ямы, шипы, лава и т.д.
	level.hazards = ModelResolver.createObjects(
		config.hazards,
		HazardModels,
		Hazard,
		"hazard"
	)	
-- Аптечки уровня.
	level.healthPickups = ModelResolver.createObjects(
		config.healthPickups or config.health_pickups,
		PickupModels,
		HealthPickup,
		"pickup"
	)	
-- Декор уровня: камни, деревья, кусты, статичные картинки без физики.
	level.decors = ModelResolver.createObjects(
		config.decors or config.decorations,
		DecorModels,
		Decor,
		"decor"
	)	
-- Объект конца уровня.
    -- Если его нет в конфиге уровня, уровень может завершаться старой логикой.
	level.levelEnd = nil

	if config.levelEnd then
		level.levelEnd = LevelEnd:new(
			ModelResolver.resolve(config.levelEnd, LevelEndModels, "levelEnd")
		)
	end
------ Скорость прокрутки sky.
    -- Положительное число: слой едет справа налево.
    -- Отрицательное число: слой едет слева направо.
    -- 0: слой не двигается.
    level.skyScrollSpeed = config.skyScrollSpeed or 0
------- Скорость прокрутки background.
    -- Положительное число: слой едет справа налево.
    -- Отрицательное число: слой едет слева направо.
    -- 0: слой не двигается.
	level.background1ScrollSpeed = config.background1ScrollSpeed
		or config.background1Scrollspeed
		or 0

	level.background2ScrollSpeed = config.background2ScrollSpeed
		or config.background2Scrollspeed
		or config.backgroundScrollSpeed
		or config.backgroundScrollspeed
		or 0

	level.frontScrollSpeed = config.frontScrollSpeed
		or config.foregroundScrollSpeed
		or 0
    -- Если true, sky скроллится сам по себе,
    -- даже если игрок стоит на месте.
    level.skyAutoScroll = config.skyAutoScroll == true
        or config.skydAutoScroll == true
    -- Если true, background скроллится сам по себе,
    -- даже если игрок стоит на месте.
	level.background1AutoScroll = config.background1AutoScroll == true

	level.background2AutoScroll = config.background2AutoScroll == true
		or config.backgroundAutoScroll == true

	level.frontAutoScroll = config.frontAutoScroll == true
		or config.foregroundAutoScroll == true
		
---------- Скорость прокрутки ground.
    -- Положительное число: земля едет справа налево.
    -- Отрицательное число: земля едет слева направо.
    -- 0: земля не двигается.
    level.groundScrollSpeed = config.groundScrollSpeed or 0
    -- Если true, земля скроллится сама,
    -- даже если игрок стоит на месте.
    level.groundAutoScroll = config.groundAutoScroll == true
------- Текущие смещения слоёв фона по X. Эти значения меняются во время игры.
	level.skyOffsetX = 0
	level.background1OffsetX = 0
	level.background2OffsetX = 0
	level.groundOffsetX = 0
	level.frontOffsetX = 0
--Враги, расставленные на уровне.
-- Они создаются не сразу, а когда игрок подошёл к точке ностра ближе чем на 300 пикселей.
	level.enemyPlacements = ModelResolver.resolveList(
		config.enemies or config.enemyPlacements or config.enemy_placements,
		EnemyModels,
		"enemy"
	)

	for _, enemyPlacement in ipairs(level.enemyPlacements) do
		enemyPlacement.spawned = false
	end
----Спавнеры врагов: автоматическая генерация монстров.
	level.enemySpawners = {}

	for _, spawnerConfig in ipairs(config.enemySpawners or config.enemy_spawners or {}) do
		table.insert(level.enemySpawners, EnemySpawner:new(spawnerConfig))
	end

	level.enemySpawnRequests = {}
----- Положение земли.
    -- groundTop — игровая линия земли, на этой высоте стоят игрок и враги.
    level.groundTop = config.ground_top or config.groundTop or 468
    -- groundHeight — старое значение высоты земли.!!!!!Оставляем для совместимости.!!!!!
    level.groundHeight = config.ground_height or config.groundHeight or 32
    -- groundVisualY — где визуально начинается картинка земли/дороги.
    -- Может быть выше groundTop, чтобы игрок стоял не на краю дороги, а внутри неё.
    level.groundVisualY = config.ground_visual_y
        or config.groundVisualY
        or level.groundTop
    -- groundVisualHeight — визуальная высота земли/дороги.
    -- Чем больше значение, тем сильнее картинка растягивается по Y.
    level.groundVisualHeight = config.ground_visual_height
        or config.groundVisualHeight
        or level.groundHeight
	-- duration можно использовать как общее время уровня,
	-- но автоматический спавн теперь настраивается внутри enemySpawners.
	level.duration = config.duration
    level.elapsed = 0
    level.nextEnemyIndex = 1
    -- Загружаем картинки уровня.
    -- Если какой-то картинки нет, вместо неё будет мокап или пустой слой.
    level.skyImage = loadImage(level.skyPath)
	level.background1Image = loadImage(level.background1Path)
	level.background2Image = loadImage(level.background2Path)
	level.frontImage = loadImage(level.frontPath)
    level.groundImage = loadImage(level.groundPath)
    -- Загружаем музыку уровня.
    level.music = nil

    if fileExists(level.musicPath) then
        level.music = love.audio.newSource(level.musicPath, "stream")
        level.music:setLooping(true)
    end

    return level
end

-- Запуск уровня.Сбрасываем состояние уровня, ручной список врагов, спавнеры и запускаем музыку.
function Level:start()
    self.elapsed = 0
    self.nextEnemyIndex = 1
    self.skyOffsetX = 0
    self.background1OffsetX = 0
    self.background2OffsetX = 0
    self.groundOffsetX = 0
    self.frontOffsetX = 0

    if self.music then
        self.music:stop()
        self.music:play()
    end	
-- Сбрасываем все enemySpawners при старте/рестарте уровня.
	for _, spawner in ipairs(self.enemySpawners) do
		spawner:reset()
	end
-- Сбрасываем врагов
	for _, enemyPlacement in ipairs(self.enemyPlacements) do
		enemyPlacement.spawned = false
	end

	self.enemySpawnRequests = {}	
	
end

-- Остановка уровня.
-- Сейчас используется при переходе на следующий уровень.
function Level:stop()
    if self.music then
        self.music:stop()
    end
end
-- Обновление уровня каждый кадр.
-- Здесь обновляется время уровня и автоскролл слоёв фона.
function Level:update(dt, player)
    self.elapsed = self.elapsed + dt
-----обновляем спавнера монстров	
	for _, spawner in ipairs(self.enemySpawners) do
		spawner:update(dt, self, player)

		for _, request in ipairs(spawner:consumeSpawnRequests()) do
			table.insert(self.enemySpawnRequests, request)
		end
	end	
--Вызов функции расстановки монстров	
	self:updateEnemyPlacements(player)	
-- Если skyAutoScroll включён, sky сам двигается.
    -- Положительная скорость двигает картинку справа налево.
    if self.skyAutoScroll then
        self.skyOffsetX = self.skyOffsetX - self.skyScrollSpeed * dt
    end
-- Если backgroundAutoScroll включён, background сам двигается.
    -- Положительная скорость двигает картинку справа налево.
	if self.background1AutoScroll then
		self.background1OffsetX = self.background1OffsetX - self.background1ScrollSpeed * dt
	end

	if self.background2AutoScroll then
		self.background2OffsetX = self.background2OffsetX - self.background2ScrollSpeed * dt
	end

	if self.frontAutoScroll then
		self.frontOffsetX = self.frontOffsetX - self.frontScrollSpeed * dt
	end	
-- Если groundAutoScroll включён, земля сама двигается.
    -- Положительная скорость двигает землю справа налево.
    if self.groundAutoScroll then
        self.groundOffsetX = self.groundOffsetX - self.groundScrollSpeed * dt
    end		
-- Обновляем платформы.
    -- Если у платформы PlatformScrollSpeed не 0, она будет двигаться.
	for i = #self.platforms, 1, -1 do
			local platform = self.platforms[i]
			platform:update(dt)
-- Если DissaperWheOutOfScreen не 0, платформа удаляется, когда вышла за экран.
			if platform:isRemovable() then
				table.remove(self.platforms, i)
			end
		end			
----декор
	for i = #self.decors, 1, -1 do
		local decor = self.decors[i]
		decor:update(dt)

		if decor:isRemovable() then
			table.remove(self.decors, i)
		end
	end			
-- Обновляем объект конца уровня.
    -- Он может появиться по таймеру и двигаться к игроку.
    if self.levelEnd then
        self.levelEnd:update(dt, player)
    end		
--опасные зоны: ямы, шипы, лава и т.д.
	for i = #self.hazards, 1, -1 do
			local hazard = self.hazards[i]
			hazard:update(dt)

			if hazard:isRemovable() then
				table.remove(self.hazards, i)
			end
		end	
---обновляем аптечки		
	for i = #self.healthPickups, 1, -1 do
		local pickup = self.healthPickups[i]
		pickup:update(dt, player)

		if pickup.collected then
			table.remove(self.healthPickups, i)
		end
	end
		
end

---рисовка декора по слоям
function Level:drawDecor(layer)
    for _, decor in ipairs(self.decors) do
        if decor.layer == layer then
            decor:draw()
        end
    end
end

-- Проверяем, есть ли ещё враги в ручном списке уровня.
-- Автоматический спавн теперь живёт отдельно в enemySpawners.
function Level:canSpawnEnemies()
    return self.nextEnemyIndex <= #self.enemies
end

-- Уровень считается завершённым по старой волновой логике:
-- все враги из ручного списка выданы, и на экране больше нет активных врагов.
-- Если на уровне есть levelEnd, main.lua всё равно завершит уровень через него.
function Level:isCompleted(activeEnemyCount)
    return self.nextEnemyIndex > #self.enemies
        and activeEnemyCount == 0
end

-- Рисуем картинку во весь экран без скролла
function Level:drawImageFullscreen(image, screenWidth, screenHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(
        image,
        0,
        0,
        0,
        screenWidth / image:getWidth(),
        screenHeight / image:getHeight()
    )
end

-- Рисуем картинку во весь экран со скроллом.
-- Картинка повторяется по горизонтали, чтобы не было пустых краёв.
function Level:drawScrollableImage(image, offsetX, screenWidth, screenHeight)
    local scaleX = screenWidth / image:getWidth()
    local scaleY = screenHeight / image:getHeight()
    local tileWidth = image:getWidth() * scaleX

    local startX = offsetX % tileWidth

    if startX > 0 then
        startX = startX - tileWidth
    end

    love.graphics.setColor(1, 1, 1)

    local x = startX

    while x < screenWidth do
        love.graphics.draw(image, x, 0, 0, scaleX, scaleY)
        x = x + tileWidth
    end
end


function Level:hasEnemySpawners()
    return #self.enemySpawners > 0
end

------------функцию создания врагов 
--если игрок подошел к точке где должен быть враг на рсстоянии не меньше 300 пикселей
function Level:updateEnemyPlacements(player)
    if not player then
        return
    end

    local playerCenterX = player.x + player.w / 2

    for _, enemyPlacement in ipairs(self.enemyPlacements) do
        if not enemyPlacement.spawned then
            local spawnX = enemyPlacement.x or love.graphics.getWidth() + 20

            local spawnDistance = enemyPlacement.spawnDistance
                or enemyPlacement.spawn_distance
                or 300

            if math.abs(playerCenterX - spawnX) <= spawnDistance then
                enemyPlacement.spawned = true

                table.insert(self.enemySpawnRequests, {
                    config = enemyPlacement,
                    x = spawnX
                })
            end
        end
    end
end



------Если на уровне нет спавнеров и нет LevelEnd то закончим когда кончатся монстры
function Level:isCompleted(activeEnemyCount)
    if self:hasEnemySpawners() then
        return false
    end

    return self.nextEnemyIndex > #self.enemies
        and activeEnemyCount == 0
end

-- Рисуем фон уровня.
-- Порядок важен:
-- 1. sky — самый дальний слой.
-- 2. background — слой перед sky.
function Level:drawBackground(screenWidth, screenHeight)
--рисуем небо
    if self.skyImage then
        self:drawScrollableImage(
            self.skyImage,
            self.skyOffsetX,
            screenWidth,
            screenHeight
        )
    else
        love.graphics.clear(0.02, 0.02, 0.03)
    end

    if self.background1Image then
        self:drawScrollableImage(
            self.background1Image,
            self.background1OffsetX,
            screenWidth,
            screenHeight
        )
    end

    if self.background2Image then
        self:drawScrollableImage(
            self.background2Image,
            self.background2OffsetX,
            screenWidth,
            screenHeight
        )
    end
end

--рисуем то что перед уровнем (кусты например или туман)
function Level:drawFront(screenWidth, screenHeight)
    if self.frontImage then
        self:drawScrollableImage(
            self.frontImage,
            self.frontOffsetX,
            screenWidth,
            screenHeight
        )
    end
end

-- Рисуем землю.
-- Если картинки земли нет, рисуем простой прямоугольник.
function Level:drawGround(screenWidth)
    -- Если есть картинка земли, рисуем её тайлами со скроллом.
    -- По X картинка повторяется, по Y растягивается до groundVisualHeight.
    if self.groundImage then
        love.graphics.setColor(1, 1, 1)

        local tileWidth = self.groundImage:getWidth()
        local scaleY = self.groundVisualHeight / self.groundImage:getHeight()

        local startX = self.groundOffsetX % tileWidth

        if startX > 0 then
            startX = startX - tileWidth
        end

        local x = startX

        while x < screenWidth do
            love.graphics.draw(
                self.groundImage,
                x,
                self.groundVisualY,
                0,
                1,
                scaleY
            )

            x = x + tileWidth
        end

        return
    end

    -- Если картинки земли нет, рисуем мокап дороги.
    -- Мокап тоже учитывает groundVisualY и groundVisualHeight.
    love.graphics.setColor(0.18, 0.22, 0.26)
    love.graphics.rectangle(
        "fill",
        0,
        self.groundVisualY,
        screenWidth,
        self.groundVisualHeight
    )

    -- Полоски на мокапе, чтобы было видно движение земли.
    love.graphics.setColor(0.25, 0.3, 0.35)

    local tileWidth = 64
    local startX = self.groundOffsetX % tileWidth

    if startX > 0 then
        startX = startX - tileWidth
    end

    local x = startX

    while x < screenWidth do
        love.graphics.rectangle("fill", x + 8, self.groundVisualY + 8, 24, 4)
        love.graphics.rectangle("fill", x + 38, self.groundVisualY + 24, 18, 4)

        x = x + tileWidth
    end

    -- Визуальная линия, где реально стоят игрок и враги.
    -- Потом можно убрать, но пока удобно для настройки.
    love.graphics.setColor(1, 1, 1, 0.25)
    love.graphics.line(0, self.groundTop, screenWidth, self.groundTop)

    love.graphics.setColor(1, 1, 1)
end

function Level:drawPlatforms()
    for _, platform in ipairs(self.platforms) do
        platform:draw()
    end
end

------- Опасные зоны уровня: ямы, шипы, лава и т.д.
function Level:drawHazards()
    for _, hazard in ipairs(self.hazards) do
        hazard:draw()
    end
end

function Level:resolvePlayerHazards(player, rectsOverlap)
    if not player:canTakeDamage() then
        return
    end

    local playerHitbox = player:getHitbox()

    for _, hazard in ipairs(self.hazards) do
        if rectsOverlap(playerHitbox, hazard:getHitbox()) then
            player:takeDamage(hazard.damage)
            return
        end
    end
end

function Level:resolveEnemyHazards(enemies, rectsOverlap)
    for _, hazard in ipairs(self.hazards) do
        if hazard.damageEnemy then
            local hazardHitbox = hazard:getHitbox()

            for _, enemy in ipairs(enemies) do
				if enemy:isAlive()
					and not enemy.flying  ---flying-враги не должны умирать от ground hazards
					and rectsOverlap(enemy:getHitbox(), hazardHitbox)
				then
					enemy:die()
				end
            end
        end
    end
end

---------------------------------Платформы
----пуля или камень не пролетают сквозь возвышенность (сквозь платформы прлетает)
function Level:removeProjectilesBlockedByPlatforms(projectiles, rectsOverlap)
    for projectileIndex = #projectiles, 1, -1 do
        local projectile = projectiles[projectileIndex]

        local projectileHitbox = projectile

        if projectile.getHitbox then
            projectileHitbox = projectile:getHitbox()
        end

        for _, platform in ipairs(self.platforms) do
            if platform.solid
                and rectsOverlap(projectileHitbox, platform:getHitbox())
            then
                table.remove(projectiles, projectileIndex)
                break
            end
        end
    end
end

---враги тоже не могут пройти возвышенность
function Level:resolveEnemyPlatforms(enemies, rectsOverlap)
    for _, enemy in ipairs(enemies) do
 --       if enemy:isAlive() then
		  if enemy:isAlive() and not enemy.flying then  --летающие враги могут проходить сквозь возвышенности
            local enemyHitbox = enemy:getHitbox()

            for _, platform in ipairs(self.platforms) do
                if platform.solid then
                    local platformHitbox = platform:getHitbox()

                    if rectsOverlap(enemyHitbox, platformHitbox) then
                        local previousHitbox = {
                            x = enemy.previousX or enemy.x,
                            y = enemy.previousY or enemy.y,
                            w = enemy.w,
                            h = enemy.h
                        }

                        -- Враг упёрся в левую сторону возвышенности.
                        -- Обычно это враг, который шёл справа налево.
                        if previousHitbox.x >= platformHitbox.x + platformHitbox.w then
                            enemy.x = platformHitbox.x + platformHitbox.w
                        end

                        -- Враг упёрся в правую сторону возвышенности.
                        -- Например, когда он отходит назад.
                        if previousHitbox.x + previousHitbox.w <= platformHitbox.x then
                            enemy.x = platformHitbox.x - enemy.w
                        end
                    end
                end
            end
        end
    end
end

function Level:resolvePlayerPlatforms(player, previousPlayerX, previousPlayerY)
    for _, platform in ipairs(self.platforms) do
        if platform:resolvePlayerCollision(player, previousPlayerX, previousPlayerY) then
            return
        end
    end
end

-----------Аптечки
function Level:drawHealthPickups()
    for _, pickup in ipairs(self.healthPickups) do
        pickup:draw()
    end
end

------подбор аптечек
function Level:resolvePlayerHealthPickups(player, rectsOverlap)
    if player.dead then
        return
    end

    local playerHitbox = player:getHitbox()

    for i = #self.healthPickups, 1, -1 do
        local pickup = self.healthPickups[i]

        if pickup:canCollect()
            and rectsOverlap(playerHitbox, pickup:getHitbox())
        then
            if player:heal(pickup.healAmount) then
                pickup:collect()
                table.remove(self.healthPickups, i)
            end

            return
        end
    end
end

function Level:drawLevelEnd()
    if self.levelEnd then
        self.levelEnd:draw()
    end
end

function Level:hasLevelEnd()
    return self.levelEnd ~= nil
end

-----------HUD-шкала прогресса до появления EndLevel

function Level:shouldShowLevelEndProgress()
    return self.levelEnd ~= nil
        and self.levelEnd:shouldShowProgress()
end

function Level:getLevelEndProgress()
    if not self.levelEnd then
        return 0
    end

    return self.levelEnd:getAppearProgress()
end

function Level:getLevelEndTimeRemaining()
    if not self.levelEnd then
        return 0
    end

    return self.levelEnd:getAppearTimeRemaining()
end

function Level:isLevelEndVisibleToPlayer()
    return self.levelEnd ~= nil
        and self.levelEnd:isVisibleToPlayer()
end

----Функции для спавнера врагов
function Level:hasEnemySpawners()
    return #self.enemySpawners > 0
end

function Level:consumeEnemySpawnRequests()
    local requests = self.enemySpawnRequests
    self.enemySpawnRequests = {}

    return requests
end

function Level:checkPlayerReachedEnd(player, rectsOverlap)
    if not self.levelEnd or not self.levelEnd:canTrigger() then
        return false
    end

    return rectsOverlap(player:getHitbox(), self.levelEnd:getHitbox())
end

function Level:triggerLevelEnd()
    if self.levelEnd then
        self.levelEnd:trigger()
    end
end

function Level:drawVictory(screenWidth, screenHeight)
    if self.levelEnd then
        self.levelEnd:drawVictory(screenWidth, screenHeight)
    end
end

---Для раннер уровня
function Level:isAlwaysRun()
    return self.alwaysRun == true
end

return Level