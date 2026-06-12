local Player = require("player")
local Enemy = require("enemy")
local EnemyBullet = require("enemy_bullet")
local PlayerProjectile = require("player_projectile")
local Effect = require("effect")
local EffectModels = require("data.effects")
local ModelResolver = require("model_resolver")
local Levels = require("levels")


local screenWidth = 800
local screenHeight = 500

local player
local levels
local level

local playerProjectiles = {}
local enemies = {}
local enemyBullets = {}
local effects = {}

local enemySpawnTimer = 0
local score = 0
local gameOver = false
local gameFinished = false

------Обект конца уровня. Игрок коснувшись его закончит уровень
local levelVictory = false
local levelVictoryTimer = 0
local levelVictoryDuration = 1

local restartButton = {
    x = 260,
    y = 340,
    w = 280,
    h = 60
}

--настройки игрока
local basePlayerConfig = {
    noturn = true,
--    alvaysRun = false, -- уже не нужно, настраиваивается в самом уровне
    doublejump = true,
    facing = 1
}

local function rectsOverlap(a, b)
    return a.x < b.x + b.w
        and b.x < a.x + a.w
        and a.y < b.y + b.h
        and b.y < a.y + a.h
end

-----дамаг эффекта (если есть) по радиусу
local function circleOverlapsRect(circle, rect)
    local closestX = math.max(rect.x, math.min(circle.x, rect.x + rect.w))
    local closestY = math.max(rect.y, math.min(circle.y, rect.y + rect.h))

    local dx = circle.x - closestX
    local dy = circle.y - closestY

    return dx * dx + dy * dy <= circle.r * circle.r
end

------эффекта
local function createEffect(effectConfig)
    if type(effectConfig) == "string" then
        effectConfig = {
            model = effectConfig
        }
    end

    local resolvedConfig = effectConfig

    if effectConfig.model then
        resolvedConfig = ModelResolver.resolve(
            effectConfig,
            EffectModels,
            "effect"
        )
    end

    return Effect:new(resolvedConfig)
end

local function addEffect(effectConfig)
    table.insert(effects, createEffect(effectConfig))
end

---функция эффекта попадания projectile
local function addProjectileImpactEffect(projectile)
    if not projectile.impactEffect then
        return
    end

    local effectConfig = projectile.impactEffect

    if type(effectConfig) == "string" then
        effectConfig = {
            model = effectConfig
        }
    else
        local copy = {}

        for key, value in pairs(effectConfig) do
            copy[key] = value
        end

        effectConfig = copy
    end

    effectConfig.x = projectile.x + projectile.w / 2 + projectile.impactOffsetX
    effectConfig.y = projectile.y + projectile.h / 2 + projectile.impactOffsetY

    addEffect(effectConfig)
end



----дамаг эффекта если есть
local function resolveEffectDamage(effect)
    if not effect:canApplyDamage() then
        return
    end

    local damageCircle = effect:getDamageCircle()

    if effect.damagePlayer
        and player
        and not player.dead
        and player:canTakeDamage()
        and circleOverlapsRect(damageCircle, player:getHitbox())
    then
        player:takeDamage(effect.damage)
    end

    if effect.damageEnemies then
        for _, enemy in ipairs(enemies) do
			if projectile:canDamageTarget("enemy")
				and enemy:isAlive()
				and rectsOverlap(projectile:getHitbox(), enemy:getHitbox())
			then
                if enemy:takeDamage(effect.damage) then
                    score = score + enemy.score
                end
            end
        end
    end

    effect:markDamageApplied()
end


--проверка удара projectile о землю
local function enemyBulletHitGround(bullet)
    if not bullet.collideGround then
        return false
    end

    return bullet.y + bullet.h >= level.groundTop
end

--проверка удара projectile о возвышенность
local function enemyBulletHitSolidPlatform(bullet)
    if not bullet.collidePlatforms then
        return false
    end

    local bulletHitbox = bullet:getHitbox()

    for _, platform in ipairs(level.platforms or {}) do
        if platform.solid
            and rectsOverlap(bulletHitbox, platform:getHitbox())
        then
            return true
        end
    end

    return false
end

---эффект при ударе пули игрока о возвышенность
local function removePlayerProjectilesBlockedByPlatforms()
    for projectileIndex = #playerProjectiles, 1, -1 do
        local projectile = playerProjectiles[projectileIndex]
        local projectileHitbox = projectile:getHitbox()

        for _, platform in ipairs(level.platforms or {}) do
            if platform.solid
                and rectsOverlap(projectileHitbox, platform:getHitbox())
            then
                addProjectileImpactEffect(projectile)
                table.remove(playerProjectiles, projectileIndex)
                break
            end
        end
    end
end

----Рисуем жизни игрока
local function drawPlayerHealthBar(player, x, y)
    local barX = x + 90
    local barY = y
    local barW = 160
    local barH = 18

    local healthRatio = 0

    if player.maxHealth > 0 then
        healthRatio = player.health / player.maxHealth
    end

    healthRatio = math.max(0, math.min(healthRatio, 1))

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Здоровье:", x, y + 1)

    -- Фон шкалы
    love.graphics.setColor(0.12, 0.12, 0.12, 0.9)
    love.graphics.rectangle("fill", barX, barY, barW, barH, 4, 4)

    -- Заполненная часть
    love.graphics.setColor(0.15, 0.85, 0.25)
    love.graphics.rectangle("fill", barX, barY, barW * healthRatio, barH, 4, 4)

    -- Рамка
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", barX, barY, barW, barH, 4, 4)

    -- Цифры поверх шкалы
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(
        tostring(player.health) .. "/" .. tostring(player.maxHealth),
        barX,
        barY + 2,
        barW,
        "center"
    )
end


-----------HUD-шкала прогресса до появления EndLevel
local function drawLevelEndProgress(level, x, y)
    if not level:shouldShowLevelEndProgress() then
        return
    end

    local barX = x + 90
    local barY = y
    local barW = 180
    local barH = 18

    local progress = level:getLevelEndProgress()
    local remaining = math.ceil(level:getLevelEndTimeRemaining())

    local text = tostring(remaining) .. "с"

    if level:isLevelEndVisibleToPlayer() then
        text = "Выход появился!"
        progress = 1
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("До выхода:", x, y + 1)

    -- Фон шкалы
    love.graphics.setColor(0.12, 0.12, 0.12, 0.9)
    love.graphics.rectangle("fill", barX, barY, barW, barH, 4, 4)

    -- Заполненная часть
    love.graphics.setColor(0.2, 0.55, 1.0)
    love.graphics.rectangle("fill", barX, barY, barW * progress, barH, 4, 4)

    -- Рамка
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", barX, barY, barW, barH, 4, 4)

    -- Текст внутри шкалы
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(text, barX, barY + 2, barW, "center")
end
------------------------------


--функцию создания конфига игрока
local function createPlayerConfigForLevel()
    return {
        noturn = basePlayerConfig.noturn,
        doublejump = basePlayerConfig.doublejump,
        facing = basePlayerConfig.facing,

        alvaysRun = level:isAlwaysRun()
    }
end

local function switchToLevel(nextLevel)
    level = nextLevel
	
--создания игрока Таких места два: в switchToLevel() и в resetGame().
--    player = Player:new(120, level.groundTop - 56, playerConfig) --OLD
	player = Player:new(120, level.groundTop - 56, createPlayerConfigForLevel())
	
    playerProjectiles = {} --очищаем камни которые швыряет игрок
    enemies = {} --очищаем врагов
	enemyBullets = {} --очищаем пули врага
	effects = {} --очищаем эффекты
	
    enemySpawnTimer = 0
end

local function resetGame()
    levels = Levels:new()
    level = levels:restart()


--создания игрока Таких места два: в switchToLevel() и в resetGame().
--    player = Player:new(120, level.groundTop - 56, playerConfig) --OLD
	player = Player:new(120, level.groundTop - 56, createPlayerConfigForLevel())

    playerProjectiles = {} --очищаем камни которые швыряет игрок
    enemies = {} --очищаем врагов
	enemyBullets = {} --очищаем пули врага
	effects = {} --очищаем эффекты

    enemySpawnTimer = 0
    score = 0
    gameOver = false
    gameFinished = false
	
-----Обьект конец уровня(который если игрок коснется то победа), обнуляем его параметры	
	levelVictory = false
	levelVictoryTimer = 0	
end


----Функция обьекта конца уровня (если игрок его коснется то победа)	
local function startLevelVictory()
    levelVictory = true
    levelVictoryTimer = levelVictoryDuration
    level:triggerLevelEnd()
end	


--local function spawnEnemy()
 --   local enemyConfig = level:getNextEnemyConfig()

 --   if not enemyConfig then
 --       return
--    end

--    table.insert(enemies, Enemy:new(enemyConfig, screenWidth + 20, level.groundTop))
--end

function love.load()
--    love.window.setTitle("Stone Thrower Arcade")
--    love.window.setMode(screenWidth, screenHeight)
    love.graphics.setDefaultFilter("nearest", "nearest")
    math.randomseed(os.time())

    resetGame()
end




function love.update(dt)
    if gameOver or gameFinished then
        player:update(dt)
        return
    end

---Логика проверки обьекта конца уровня (если игрок коснется этот обьект то победа)	
	if levelVictory then
			levelVictoryTimer = levelVictoryTimer - dt

			if levelVictoryTimer <= 0 then
				levelVictory = false

				local nextLevel = levels:goNext()

				if nextLevel then
					switchToLevel(nextLevel)
				else
					gameFinished = true
				end
			end

			return
		end	

    if player.dead then
        player:update(dt)

        if player:isDeathAnimationFinished() then
            gameOver = true
        end

        return
    end

	level:update(dt, player)

----обьект спавна врагов
	for _, spawnRequest in ipairs(level:consumeEnemySpawnRequests()) do
		table.insert(
			enemies,
			Enemy:new(
				spawnRequest.config,
				spawnRequest.x or screenWidth + 20,
				level.groundTop
			)
		)
	end

-------цикл обновления эффекта - дым, взрыв, искры, части тела врагов и т.д.
	for i = #effects, 1, -1 do
		local effect = effects[i]

		effect:update(dt, level, rectsOverlap)
		resolveEffectDamage(effect)

		for _, effectRequest in ipairs(effect:consumeEffectSpawnRequests()) do
			addEffect(effectRequest)
		end

		if effect:isRemovable() then
			table.remove(effects, i)
		end
	end

-----Позиция игрока
	local previousPlayerX = player.x
	local previousPlayerY = player.y

	player:update(dt)

	level:resolvePlayerPlatforms(player, previousPlayerX, previousPlayerY)
	
----обновим визуальное состояние
	player:updateVisualState()

---создание проджектайла игрока (камней которыми он стреляет)
	if player:consumeShotRequest() then
		table.insert(playerProjectiles, PlayerProjectile:fromPlayer(player, "Stone"))
	end

----обновление камней которые бросает игрок
	for i = #playerProjectiles, 1, -1 do
		local projectile = playerProjectiles[i]
		projectile:update(dt)
---удаление камней которые бросает игрок
		if projectile:isRemovable(screenWidth) then
			table.remove(playerProjectiles, i)
		end
	end

---удаляем пули и камни, которые врезались в возвышенность	
--level:removeProjectilesBlockedByPlatforms(playerProjectiles, rectsOverlap)--старое
	removePlayerProjectilesBlockedByPlatforms()

---Цикл врагов и эффектов
	for i = #enemies, 1, -1 do
		local enemy = enemies[i]
		enemy:update(dt, player)

		local shotRequest = enemy:consumeShotRequest()

		if shotRequest then
			table.insert(enemyBullets, EnemyBullet:new(shotRequest))
		end

		for _, effectRequest in ipairs(enemy:consumeEffectSpawnRequests()) do
			addEffect(effectRequest)
		end

		if enemy:isRemovable() then
			table.remove(enemies, i)
		end
	end

level:resolveEnemyPlatforms(enemies, rectsOverlap)

-----Обновление вражеских пуль проверка их удара об землю и возвышенность
	for i = #enemyBullets, 1, -1 do
		local bullet = enemyBullets[i]
		bullet:update(dt)

		if enemyBulletHitGround(bullet)
			or enemyBulletHitSolidPlatform(bullet)
		then
			addProjectileImpactEffect(bullet)
			table.remove(enemyBullets, i)
---удаление пуль врагов			
		elseif bullet:isRemovable() then
			table.remove(enemyBullets, i)
		end
	end
-----------
-----пули врага не могут прострелить возвышенность
	level:removeProjectilesBlockedByPlatforms(enemyBullets, rectsOverlap)


----столкновеник с врагами
for enemyIndex = #enemies, 1, -1 do
    local enemy = enemies[enemyIndex]
    local enemyHitbox = enemy:getHitbox()

    for projectileIndex = #playerProjectiles, 1, -1 do
        local projectile = playerProjectiles[projectileIndex]

------Блок столкновения playerProjectiles с врагами
		if enemy:isAlive()
			and rectsOverlap(enemyHitbox, projectile:getHitbox())
		then
			addProjectileImpactEffect(projectile)

			if enemy:takeDamage(projectile.damage or 1) then
				score = score + enemy.score
			end

			table.remove(playerProjectiles, projectileIndex)
			break
		end
    end
end
----Столкновение игрока с врагами
    local playerHitbox = player:getHitbox()

    for _, enemy in ipairs(enemies) do
        if enemy:canDamagePlayer()
            and player:canTakeDamage()
            and rectsOverlap(playerHitbox, enemy:getHitbox())
        then
            player:takeDamage(enemy.damage)
            enemy:onTouchPlayer()
            break
        end
    end
	
	
---обработка столкновений с ямами, шипами, лавой и т.д.
level:resolvePlayerHazards(player, rectsOverlap)
level:resolveEnemyHazards(enemies, rectsOverlap)

----обработка подбора аптечки
level:resolvePlayerHealthPickups(player, rectsOverlap)	

---------------столкновение вражеских пуль с игроком
local playerHitboxForBullets = player:getHitbox()

for i = #enemyBullets, 1, -1 do
    local bullet = enemyBullets[i]

	if bullet:canDamageTarget("player")
		and player:canTakeDamage()
		and rectsOverlap(playerHitboxForBullets, bullet:getHitbox())
	then
		addProjectileImpactEffect(bullet)
		player:takeDamage(bullet.damage)
		table.remove(enemyBullets, i)
		break
	end
end	
	
	

-------------Проверка на обьект конца уровня (если его коснуться то победа)	
	if level:checkPlayerReachedEnd(player, rectsOverlap) then
        startLevelVictory()
        return
    end	
end


function love.draw()
    level:drawBackground(screenWidth, screenHeight)
    level:drawGround(screenWidth)
	
	---рисуем декор задний	за всеми обьетками поэтому кусок кода поставили сюда
	level:drawDecor("back")
	
	level:drawPlatforms()
	level:drawHazards()
	level:drawHealthPickups()	
	level:drawLevelEnd()

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("A/D или стрелки — ходьба | Space — прыжок | J/K/L Ctrl — бросок", 20, 20)
    love.graphics.print("Счёт: " .. score, 20, 44)
--    love.graphics.print("Жизни: " .. player.health .. "/" .. player.maxHealth, 20, 68)
	drawPlayerHealthBar(player, 20, 68)
----HUD шкала сколько осталось до EndLevel
	drawLevelEndProgress(level, 20, 92)

	
--Это просто для проверки. Смотрел существвует ли обьект или нет	
--	love.graphics.print("hasLevelEnd: " .. tostring(level:hasLevelEnd()), 20, 92)
--	love.graphics.print("hazards: " .. tostring(#level.hazards), 20, 116)

---отрисовка камней которые швыряет игрок
	for _, projectile in ipairs(playerProjectiles) do
		projectile:draw()
	end
----отрисовка эффектов	
	for _, effect in ipairs(effects) do
		effect:draw()
	end	
---отрисовка врагов
    for _, enemy in ipairs(enemies) do
        enemy:draw()
    end
---отрисовка вражеских пуль
	for _, bullet in ipairs(enemyBullets) do
		bullet:draw()
	end	

    player:draw()
	
-----Рисуем декор впереди (перед игроком и всеми обеькатим) поэтому вставили код здесь	
	level:drawDecor("front")
	
--рисуем то что перед уровнем (кусты например или туман)
	level:drawFront(screenWidth, screenHeight)
	
------Окно экрана победы после прикосновения к обьетку - Конец уровня (если игрок коснулся такого обьекта то уровнеь заканчивается)	
	if levelVictory then
        level:drawVictory(screenWidth, screenHeight)
        return
    end	

    if gameOver then
        love.graphics.setColor(0, 0, 0, 0.65)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Вы проиграли", 0, 240, screenWidth, "center")

        love.graphics.setColor(0.2, 0.55, 0.9)
        love.graphics.rectangle("fill", restartButton.x, restartButton.y, restartButton.w, restartButton.h, 10, 10)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Начать заново", restartButton.x, restartButton.y + 20, restartButton.w, "center")
    elseif gameFinished then
        love.graphics.setColor(0, 0, 0, 0.65)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Все уровни пройдены!", 0, 240, screenWidth, "center")

        love.graphics.setColor(0.2, 0.55, 0.9)
        love.graphics.rectangle("fill", restartButton.x, restartButton.y, restartButton.w, restartButton.h, 10, 10)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Начать заново", restartButton.x, restartButton.y + 20, restartButton.w, "center")
    end
end

function love.keypressed(key)
    if (gameOver or gameFinished) and key == "return" then
        resetGame()
        return
    end

	if key == "space" or key == "up" then
		player:jump()
	end

    if key == "j" or key == "k" or key == "lctrl" or key == "rctrl" then
        player:attack()
    end
end

function love.mousepressed(x, y, button)
    if button ~= 1 or not (gameOver or gameFinished) then
        return
    end

    local insideButton =
        x >= restartButton.x and x <= restartButton.x + restartButton.w
        and y >= restartButton.y and y <= restartButton.y + restartButton.h

    if insideButton then
        resetGame()
    end
	

	
end