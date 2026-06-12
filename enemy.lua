local AnimationSet = require("animation_set")
local ProjectileModels = require("data.projectiles")
local Targeting = require("targeting")

local Enemy = {}
Enemy.__index = Enemy

-- Проверяем, существует ли файл внутри проекта Love2D
-- если файла нет, игра использует мокапы/пропускает звук
local function fileExists(path)
    return path and love.filesystem.getInfo(path) ~= nil
end

-- Загружаем набор звуков.
-- paths — массив путей.
local function loadSounds(paths)
    local sounds = {}

    for _, path in ipairs(paths or {}) do
        if fileExists(path) then
            table.insert(sounds, love.audio.newSource(path, "static"))
        end
    end

    return sounds
end

-- Проигрываем случайный звук из списка.
-- Используется для смерти и taunt-звуков.
local function playRandomSound(sounds)
    if #sounds == 0 then
        return
    end

    local sound = sounds[math.random(1, #sounds)]
    sound:stop()
    sound:play()
end

--Проигрываем звук
local function playSoundFile(path)
    if not fileExists(path) then
        return
    end

    local sound = love.audio.newSource(path, "static")
    sound:play()
end

-- Простое поверхностное копирование таблицы.
-- Нужно для projectile-запросов:
-- pendingAttackProjectile хранит подготовленный снаряд,
-- а когда animation event срабатывает, мы копируем его в shotRequest.
--
-- Почему копируем, а не передаём ту же таблицу:
-- чтобы случайно не изменить pendingAttackProjectile после передачи в main.lua.
local function copyTable(source)
    local result = {}

    for key, value in pairs(source or {}) do
        result[key] = value
    end

    return result
end


------Работа с проджектайлами
local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local result = {}

    for key, childValue in pairs(value) do
        result[key] = deepCopy(childValue)
    end

    return result
end

local function mergeModelConfig(modelConfig, overrideConfig)
    local result = deepCopy(modelConfig)

    for key, value in pairs(overrideConfig or {}) do
        if key ~= "model" then
            result[key] = deepCopy(value)
        end
    end

    return result
end

local function resolveProjectileConfig(projectileConfig)
    if not projectileConfig then
        return nil
    end

    if type(projectileConfig) == "string" then
        local modelConfig = ProjectileModels[projectileConfig]

        if not modelConfig then
            error("Unknown projectile model: " .. tostring(projectileConfig))
        end

        return deepCopy(modelConfig)
    end

    if type(projectileConfig) == "table" and projectileConfig.model then
        local modelConfig = ProjectileModels[projectileConfig.model]

        if not modelConfig then
            error("Unknown projectile model: " .. tostring(projectileConfig.model))
        end

        return mergeModelConfig(modelConfig, projectileConfig)
    end

    if type(projectileConfig) == "table" then
        return deepCopy(projectileConfig)
    end

    return nil
end
-----------------




-- Возвращает цвет fallback-мокапа для конкретного состояния.
-- Используется новой системой Animation/AnimationSet,
-- если настоящей картинки нет.
--
-- baseColor — основной цвет врага из конфига.
-- Для некоторых состояний цвет переопределяется,
-- чтобы даже мокапом было видно: враг летит, атакует, умер и т.д.
local function getStateFallbackColor(state, baseColor)
    local stateColors = {
        walk = baseColor,
        fly = {0.45, 0.9, 1.0},
        attack = {1.0, 0.45, 0.25},
        jump = {0.45, 0.75, 1.0},
        retreat = {0.95, 0.75, 0.25},
        taunt = {0.85, 0.25, 1.0},
		turn = {0.6, 0.6, 1.0},		
        death = {0.45, 0.45, 0.45}
    }

    return stateColors[state] or baseColor
end

-- Собирает список кадров старого формата:
--
-- sprite_folder/state_1.png
-- sprite_folder/state_2.png
-- ...
--
-- Например:
-- assets/enemies/goblin/walk_1.png
-- assets/enemies/goblin/walk_2.png
--
-- Возвращает список не картинок, а описаний:
-- { image = path }
--
-- Сами картинки загружает уже animation.lua.
-- Если файла нет, animation.lua нарисует fallback-мокап.
local function buildFrameList(config, state, frameCount)
    local frames = {}
    local folder = config.sprite_folder

    for i = 1, frameCount do
        local path = nil

        if folder then
            path = folder .. "/" .. state .. "_" .. i .. ".png"
        end

        table.insert(frames, {
            image = path
        })
    end

    return frames
end

-- Создаёт конфиг анимаций для старого формата врагов.
--
-- Это слой совместимости:
-- старые враги всё ещё могут иметь только:
--
-- sprite_folder = "assets/enemies/goblin"
--
-- и файлы:
--
-- walk_1.png ... walk_5.png
-- attack_1.png ... attack_5.png
-- death_1.png ... death_5.png
--
-- Но внутри они уже будут работать через новую систему AnimationSet.
local function buildLegacyAnimationConfigs(config, enemy)
    -- Если у врага уже есть новый формат animations,
    -- ничего не строим автоматически, а используем его напрямую.
    --
    -- Это нужно для будущих моделей:
    --
    -- animations = {
    --     walk = {...},
    --     attack = {...}
    -- }
    if config.animations then
        return config.animations
    end

    -- Сколько кадров ожидаем в старом формате.
    -- По умолчанию 5, как было раньше.
    local frameCount = config.frameCount or 5

    -- Общая длительность кадра для большинства анимаций.
    local defaultFrameDuration = config.frameDuration or enemy.frameDuration or 0.1

    -- На каком кадре attack-анимации создаётся projectile.
    --
    -- Например:
    -- attackEventFrame = 3
    --
    -- значит:
    -- enemy переходит в attack,
    -- проигрывает attack_1, attack_2,
    -- и на attack_3 создаёт пулю/бомбу.
    --
    -- По умолчанию 1, чтобы поведение было максимально похоже
    -- на старое: атака началась — projectile появился сразу.
    local attackEventFrame = config.attackEventFrame
        or config.projectileFrame
        or config.shootFrame
        or 1

    -- Длительность одного кадра атаки.
    --
    -- Раньше длительность атаки задавалась attackDuration.
    -- Теперь attackDuration распределяется по кадрам attack-анимации.
    local attackFrameDuration = config.attackFrameDuration
        or enemy.attackDuration / frameCount

    return {
        -- Наземное движение.
        walk = {
            loop = true,
            frameDuration = defaultFrameDuration,
            color = getStateFallbackColor("walk", enemy.color),
            frames = buildFrameList(config, "walk", frameCount)
        },

        -- Полёт.
        -- Используется для flying-врагов.
        fly = {
            loop = true,
            frameDuration = defaultFrameDuration,
            color = getStateFallbackColor("fly", enemy.color),
            frames = buildFrameList(config, "fly", frameCount)
        },

        -- Атака.
        -- Теперь projectile создаётся не в tryShoot()/tryDropProjectile напрямую,
        -- а по событию на конкретном кадре.
        attack = {
            loop = false,
            holdLastFrame = false,
            frameDuration = attackFrameDuration,
            color = getStateFallbackColor("attack", enemy.color),
            frames = buildFrameList(config, "attack", frameCount),

            -- Если projectile должен появиться на первом кадре,
            -- событие нужно сгенерировать сразу при запуске анимации.
            fireFirstFrameEvents = attackEventFrame == 1,

            events = {
                {
                    frame = attackEventFrame,
                    action = "emitPendingProjectile"
                }
            }
        },

        -- Прыжок jumper-врага.
        jump = {
            loop = true,
            frameDuration = defaultFrameDuration,
            color = getStateFallbackColor("jump", enemy.color),
            frames = buildFrameList(config, "jump", frameCount)
        },

        -- Отход назад после касания игрока или после прыжковой атаки.
        retreat = {
            loop = true,
            frameDuration = defaultFrameDuration,
            color = getStateFallbackColor("retreat", enemy.color),
            frames = buildFrameList(config, "retreat", frameCount)
        },

        -- Короткая taunt-анимация после retreat.
        taunt = {
            loop = true,
            frameDuration = defaultFrameDuration,
            color = getStateFallbackColor("taunt", enemy.color),
            frames = buildFrameList(config, "taunt", frameCount)
        },

        -- Смерть.
        -- holdLastFrame = true означает, что после завершения
        -- враг останется на последнем кадре, пока main.lua его не удалит.
        death = {
            loop = false,
            holdLastFrame = true,
            frameDuration = defaultFrameDuration,
            color = getStateFallbackColor("death", enemy.color),
            frames = buildFrameList(config, "death", frameCount)
        }
    }
end

function Enemy:new(config, x, groundTop)
    local enemy = setmetatable({}, Enemy)

    -- Тип и базовая физическая позиция врага.
    -- x приходит из main.lua при спавне.
    -- y зависит от того, летающий враг или наземный.
    enemy.type = config.type or "enemy"
    enemy.x = x
    enemy.w = config.w or 38
    enemy.h = config.h or 48
		
-- Тип существа:
    -- enemy  — враг
    -- npc    — союзник/нейтрал
    -- player — игрок, но игрок обычно создаётся в player.lua
    enemy.entityType = config.entityType
        or config.entity_type
        or "enemy"	
		
			
--- враг по умолчанию ненавидит игрока и npc, а npc по умолчанию ненавидит врагов		
	local defaultHates = {
			player = true,
			npc = true
		}

		if enemy.entityType == "npc" then
			defaultHates = {
				enemy = true
			}
		end

		enemy.hates = Targeting.buildTargetSet(
			config.hates
				or config.hostileTo
				or config.hostile_to
				or config.attackTargets
				or config.attack_targets,
			defaultHates
		)		
		
		
-- NPC может следовать за игроком, если сейчас нет боевой цели.
    enemy.followPlayer = config.followPlayer == true
        or config.follow_player == true

    enemy.followDistance = config.followDistance
        or config.follow_distance
        or 90

    enemy.followSpeed = config.followSpeed
        or config.follow_speed
        or enemy.speed		
		
-- Направление движения и атаки.
    -- -1: всегда влево.
    --  1: всегда вправо.
    --  0: идти и атаковать в сторону игрока.
    enemy.MoveDirection = config.MoveDirection
        or config.moveDirection
        or config.move_direction
        or -1

    if enemy.MoveDirection ~= -1
        and enemy.MoveDirection ~= 0
        and enemy.MoveDirection ~= 1
    then
        enemy.MoveDirection = -1
    end

    -- Текущая сторона, куда смотрит враг.
    -- Для MoveDirection = 0 она будет меняться по игроку.
    enemy.facingDirection = enemy.MoveDirection

    if enemy.facingDirection == 0 then
        enemy.facingDirection = -1
    end

    enemy.pendingFacingDirection = nil	

    -- flying/canFly = true включает летающее поведение.
    -- Такой враг не стоит на groundTop и не зависит от гравитации.
    enemy.flying = config.flying == true
        or config.canFly == true
        or config.type == "flying"

    if enemy.flying then
        local flyHeight = config.flyHeight
            or config.fly_height
            or 120

-- Для летающего врага можно задать: y напрямую; spawnY/spawn_y; или flyHeight — высоту над землёй.
        enemy.y = config.y
            or config.spawnY
            or config.spawn_y
            or (groundTop - enemy.h - flyHeight)
    else
        enemy.y = groundTop - enemy.h
    end

    -- Параметры полёта.baseY — центральная высота.flyAmplitude — амплитуда покачивания. flyFrequency — частота покачивания.
    enemy.baseY = enemy.y
    enemy.flyTimer = 0
    enemy.flyAmplitude = config.flyAmplitude
        or config.fly_amplitude
        or 0

    enemy.flyFrequency = config.flyFrequency
        or config.fly_frequency
        or 2

    -- Основные боевые параметры.
    enemy.speed = config.speed or 140
    enemy.damage = config.damage or 1
    enemy.score = config.score or 1
    enemy.color = config.color or {0.75, 0.16, 0.18}


-- Прозрачность врага.
    -- 1 — полностью видимый.
    -- 0.5 — полупрозрачный.
    -- 0 — невидимый.
    enemy.alpha = config.alpha

    if enemy.alpha == nil then
        enemy.alpha = 1
    end

    -- HP врага.
    enemy.maxHealth = config.health
        or config.hp
        or config.maxHealth
        or 1

    enemy.health = enemy.maxHealth

    -- Показывать ли HP-bar.
    -- Если явно не указано, показываем только у врагов с HP больше 1.
    enemy.showHealthBar = config.showHealthBar

    if enemy.showHealthBar == nil then
        enemy.showHealthBar = enemy.maxHealth > 1
    end

    -- Смещение картинки относительно hitbox.
    -- Hitbox остаётся на enemy.x/enemy.y.
    enemy.offsetX = config.offsetX
        or config.spriteOffsetX
        or config.drawOffsetX
        or 0

    enemy.offsetY = config.offsetY
        or config.spriteOffsetY
        or config.drawOffsetY
        or 0
		
-- Если true, спрайт врага рисуется зеркально по горизонтали.
-- Hitbox и физика не меняются.
	enemy.flipImage = config.flipImage == true
		or config.flip == true
		or config.mirror == true		
		

    -- Shooter-поведение.
    enemy.canShoot = config.canShoot == true
    enemy.shootChance = config.shootChance or 0.4
    enemy.shootCooldown = config.shootCooldown or 1.5
    enemy.shootTimer = config.shootStartDelay or 0.6
    enemy.shootRange = config.shootRange or 500

    -- Параметры обычной горизонтальной пули.
    enemy.bulletSpeed = config.bulletSpeed or 220
    enemy.bulletDamage = config.bulletDamage or 1
    enemy.bulletImage = config.bulletImage
    enemy.bulletW = config.bulletW or 12
    enemy.bulletH = config.bulletH or 12
	
	-------Данные проджектайлов
	enemy.bulletProjectile = resolveProjectileConfig(
		config.bulletProjectile
			or config.bulletModel
			or config.projectileModel
	)	

    -- Drop-projectile для летающих врагов.
	enemy.canDropProjectile = config.canDropProjectile == true
		or config.canDrop == true
		or config.dropProjectile == true
		or config.dropProjectileModel ~= nil
		or config.dropProjectileConfig ~= nil

    enemy.dropChance = config.dropChance or 0.45
    enemy.dropCooldown = config.dropCooldown or 1.6
    enemy.dropTimer = config.dropStartDelay or 0.8

    enemy.dropRangeX = config.dropRangeX
        or config.drop_range_x
        or 90

    enemy.dropSpeed = config.dropSpeed or 260
    enemy.dropDamage = config.dropDamage or 1
    enemy.dropImage = config.dropImage
    enemy.dropW = config.dropW or 12
    enemy.dropH = config.dropH or 16
	
----прпметры сбрасываемого проджетайла	
	enemy.dropProjectileConfig = resolveProjectileConfig(
		config.dropProjectileConfig
			or config.dropProjectileModel
	)	

    -- shotRequest забирает main.lua и создаёт EnemyBullet.
    enemy.shotRequest = nil
	enemy.effectSpawnRequests = {}

    -- pendingAttackProjectile — подготовленный projectile. Появляется когда attack-анимация дойдёт до нужного кадра.
    enemy.pendingAttackProjectile = nil


-- Melee-атака.
    -- Это отдельная логика ближнего боя.
    -- Враг может одновременно уметь стрелять и бить вблизи.
    enemy.canMeleeAttack = config.canMeleeAttack == true
        or config.canMelee == true

    enemy.meleeRange = config.meleeRange
        or config.melee_range
        or 70

    enemy.meleeChance = config.meleeChance
        or config.melee_chance
        or 1

    enemy.meleeCooldown = config.meleeCooldown
        or config.melee_cooldown
        or 0.7

    enemy.meleeTimer = config.meleeStartDelay
        or config.melee_start_delay
        or 0

    enemy.meleeProjectile = resolveProjectileConfig(
        config.meleeProjectile
            or config.meleeProjectileModel
            or config.melee_projectile
            or config.melee_projectile_model
    )

    -- Смещение hitbox melee-удара.
    -- Обычно лучше задавать прямо в модели projectile через spawnOffsetX/Y.
    enemy.meleeOffsetX = config.meleeOffsetX
        or config.melee_offset_x
        or 0

    enemy.meleeOffsetY = config.meleeOffsetY
        or config.melee_offset_y
        or 0

-- Если true, после melee-удара враг отходит назад.
    enemy.retreatAfterMelee = config.retreatAfterMelee == true
        or config.retreat_after_melee == true

    enemy.meleeRetreatDistance = config.meleeRetreatDistance
        or config.melee_retreat_distance
        or enemy.retreatDistance
        or 70
-----------

    -- Jumper-поведение.
    enemy.canJumpAttack = config.canJumpAttack == true
    enemy.jumpChance = config.jumpChance or 0.3
    enemy.jumpAttackRange = config.jumpAttackRange or 220
    enemy.jumpCooldown = config.jumpCooldown or 2.0
    enemy.jumpTimer = config.jumpStartDelay or 0.8

    enemy.jumpSpeedX = config.jumpSpeedX or 260
    enemy.jumpPower = config.jumpPower or -360
    enemy.gravity = config.gravity or 900
    enemy.vy = 0
    enemy.groundY = groundTop
    enemy.jumpDirection = -1
    enemy.jumpHitPlayer = false

    -- Отступление после прыжка.
    enemy.jumpRetreatSteps = config.jumpRetreatSteps or 20
    enemy.jumpRetreatStepSize = config.jumpRetreatStepSize or 6
    enemy.jumpRetreatDistance = config.jumpRetreatDistance
        or enemy.jumpRetreatSteps * enemy.jumpRetreatStepSize

    enemy.retreatThenTaunt = false

    -- attackDuration теперь используется только для legacy attack-анимации.
    -- Сама атака завершается не по таймеру, а когда закончилась attack-анимация.
    enemy.attackTimer = 0
    enemy.attackDuration = config.attackDuration or 0.35

    enemy.taunt = config.taunt == true

    -- Удаление за экраном.
    enemy.DissaperWheOutOfScreen = config.DissaperWheOutOfScreen
        or config.disappearWhenOutOfScreen
        or 100

    -- Начальное состояние.
    enemy.state = enemy.flying and "fly" or "walk"
    enemy.frameDuration = config.frameDuration or 0.1

    enemy.dead = false
    enemy.deathFinished = false
    enemy.scoreGiven = false

    -- Retreat после касания игрока.
    enemy.retreatDistance = config.retreat_distance or 70
    enemy.defaultRetreatDistance = enemy.retreatDistance
    enemy.retreatSpeed = config.retreat_speed or 160
    enemy.retreatMoved = 0

    -- Taunt после retreat.
    enemy.tauntDuration = config.taunt_duration or 0.5
    enemy.tauntTimer = 0

    -- Звуки врага.
    enemy.sounds = {
        taunt = loadSounds(config.taunt_sounds or {
            "assets/sfx/enemy_taunt1.wav",
            "assets/sfx/enemy_taunt2.wav"
        }),
        death = loadSounds(config.death_sounds or {
            "assets/sfx/enemy_death1.wav",
            "assets/sfx/enemy_death2.wav"
        })
    }

    -- Новый AnimationSet.
    -- buildLegacyAnimationConfigs сохраняет поддержку старого формата:
    -- sprite_folder/state_1.png ... state_5.png
    enemy.animationSet = AnimationSet:new({
        defaultState = enemy.state,
        w = enemy.w,
        h = enemy.h,
        color = enemy.color,
        animations = buildLegacyAnimationConfigs(config, enemy)
    })

    return enemy
end

-- Меняет состояние врага и синхронно переключает анимацию.
function Enemy:setState(state)
    if self.state == state then
        return
    end

    self.state = state

    if self.animationSet then
        self.animationSet:setState(state)
    end
end

function Enemy:isAlive()
    return not self.dead
end


-- Направление от врага к игроку.
function Enemy:getDirectionToPlayer(player)
    if not player then
        return self.facingDirection or -1
    end

    local enemyCenterX = self.x + self.w / 2
    local playerCenterX = player.x + player.w / 2

    if playerCenterX < enemyCenterX then
        return -1
    end

    return 1
end

----функция выбора цели
function Enemy:selectTarget(player, targetGroups)
    local target = Targeting.findNearestTarget(self, targetGroups)

    if target then
        return target
    end

    if self.hates
        and self.hates.player
        and Targeting.isAlive(player)
    then
        return player
    end

    return nil
end


--функция следования NPC за игроком
function Enemy:tryFollowPlayer(dt, player)
    if not self.followPlayer or not player then
        return false
    end

    local enemyCenterX = self.x + self.w / 2
    local playerCenterX = player.x + player.w / 2
    local distanceX = math.abs(enemyCenterX - playerCenterX)

    if distanceX <= self.followDistance then
        return false
    end

    local direction = -1

    if playerCenterX > enemyCenterX then
        direction = 1
    end

    if self.MoveDirection == 0 then
        if self:turnToDirection(direction) then
            return true
        end
    end

    self.facingDirection = direction
    self.x = self.x + direction * self.followSpeed * dt

    return true
end

-- Куда враг должен идти.
function Enemy:getMoveDirection(player)
    if self.MoveDirection == -1 or self.MoveDirection == 1 then
        return self.MoveDirection
    end

    return self:getDirectionToPlayer(player)
end

-- Куда враг должен атаковать.
function Enemy:getAttackDirection(player)
    if self.MoveDirection == -1 or self.MoveDirection == 1 then
        return self.MoveDirection
    end

    return self.facingDirection or self:getDirectionToPlayer(player)
end

-- Находится ли игрок с той стороны, куда враг может атаковать.
function Enemy:isPlayerInAttackDirection(player)
    if not player then
        return false
    end

    local direction = self:getAttackDirection(player)
    local enemyCenterX = self.x + self.w / 2
    local playerCenterX = player.x + player.w / 2

    if direction < 0 then
        return playerCenterX <= enemyCenterX
    end

    return playerCenterX >= enemyCenterX
end

---функции поворота
function Enemy:turnToDirection(direction)
    if direction == 0 or direction == self.facingDirection then
        return false
    end

    -- Если turn-анимации нет, просто мгновенно зеркалим врага.
    if not self.animationSet or not self.animationSet:hasState("turn") then
        self.facingDirection = direction
        return false
    end

    self.pendingFacingDirection = direction
    self:setState("turn")

    return true
end

function Enemy:tryTurnToPlayer(player)
    if self.MoveDirection ~= 0 then
        return false
    end

    if not player then
        return false
    end

    local direction = self:getDirectionToPlayer(player)

    return self:turnToDirection(direction)
end

-- Возвращает базовое движение врага:
-- наземный враг возвращается в walk,
-- летающий — в fly.
function Enemy:getMoveState()
    if self.flying then
        return "fly"
    end

    return "walk"
end

-- Может ли враг сейчас нанести контактный урон игроку.
function Enemy:canDamagePlayer()
    return not self.dead
        and (
            self.state == "walk"
            or self.state == "fly"
            or (self.state == "jump" and not self.jumpHitPlayer)
        )
end

-- Реакция врага на касание игрока.
function Enemy:onTouchPlayer()
    if self.dead then
        return
    end

    -- Jumper не должен зависать в воздухе после удара.
    -- Поэтому в jump-состоянии он просто помечает, что уже задел игрока,
    -- и продолжает падать до земли.
    if self.state == "jump" then
        self.jumpHitPlayer = true
        return
    end

    self.retreatMoved = 0
    self.retreatThenTaunt = self.taunt
    self:setState("retreat")
end

-- Получение урона.
-- Возвращает true, если именно этот удар убил врага.
function Enemy:takeDamage(amount)
    if self.dead then
        return false
    end

    amount = amount or 1

    self.health = math.max(0, self.health - amount)

    if self.health <= 0 then
        return self:die()
    end

    return false
end

-- Запуск death-состояния.
function Enemy:die()
    if self.dead then
        return false
    end

    self.dead = true
    self.deathFinished = false
    self.pendingAttackProjectile = nil
    self:setState("death")
    playRandomSound(self.sounds.death)

    return true
end

-- Дистанция до игрока по X.
function Enemy:getDistanceToPlayer(player)
    local enemyCenterX = self.x + self.w / 2
    local playerCenterX = player.x + player.w / 2

    return math.abs(enemyCenterX - playerCenterX)
end


-- Расстояние между краями hitbox по X.
-- Для melee это лучше, чем расстояние между центрами.
function Enemy:getEdgeDistanceToPlayer(player)
    if not player then
        return math.huge
    end

    local enemyLeft = self.x
    local enemyRight = self.x + self.w

    local playerLeft = player.x
    local playerRight = player.x + player.w

    if enemyRight < playerLeft then
        return playerLeft - enemyRight
    end

    if playerRight < enemyLeft then
        return enemyLeft - playerRight
    end

    return 0
end
--если игрок в зоне удара
function Enemy:isPlayerInMeleeRange(player)
    if not self.canMeleeAttack or not player then
        return false
    end

    if not self:isPlayerInAttackDirection(player) then
        return false
    end

    return self:getEdgeDistanceToPlayer(player) <= self.meleeRange
end

-- Направление к игроку:
-- -1 значит игрок слева,
--  1 значит игрок справа.
function Enemy:getDirectionToPlayer(player)
    if not player then
        return -1
    end

    local enemyCenterX = self.x + self.w / 2
    local playerCenterX = player.x + player.w / 2

    if playerCenterX > enemyCenterX then
        return 1
    end

    return -1
end


-- Попытка начать melee-атаку.
function Enemy:tryMeleeAttack(player, dt)
    if not self.canMeleeAttack or not player then
        return false
    end

    if not self.meleeProjectile then
        return false
    end

    if self.state ~= "walk" and self.state ~= "fly" then
        return false
    end

    if not self:isPlayerInMeleeRange(player) then
        return false
    end

    self.meleeTimer = self.meleeTimer - dt

    if self.meleeTimer > 0 then
        return false
    end

    self.meleeTimer = self.meleeCooldown

    if math.random() > self.meleeChance then
        return false
    end

    local direction = self:getAttackDirection(player)

    -- ВАЖНО:
    -- Копируем всю модель projectile целиком.
    -- Так сохраняются damageTargets, impactEffect, alpha, animation и т.д.
    local projectile = copyTable(self.meleeProjectile)

    local projectileW = projectile.w or projectile.width or 40
    local projectileH = projectile.h or projectile.height or self.h

    local spawnOffsetX = projectile.spawnOffsetX
        or projectile.spawn_offset_x
        or self.meleeOffsetX
        or 0

    local spawnOffsetY = projectile.spawnOffsetY
        or projectile.spawn_offset_y
        or self.meleeOffsetY
        or 0

    projectile.w = projectileW
    projectile.h = projectileH

    if direction < 0 then
        projectile.x = self.x - projectileW - spawnOffsetX
    else
        projectile.x = self.x + self.w + spawnOffsetX
    end

    projectile.y = self.y + self.h / 2 - projectileH / 2 + spawnOffsetY

    projectile.vx = projectile.vx or 0
    projectile.vy = projectile.vy or 0
    projectile.damage = projectile.damage or self.damage

    self.pendingAttackProjectile = projectile
    self:setState("attack")

    return true
end

-- Попытка начать shooter-атаку.
-- Projectile не создаётся сразу.
-- Здесь только подготавливается pendingAttackProjectile,
-- а фактическое создание произойдёт на кадре attack-анимации.
function Enemy:tryShoot(player, dt)
    if not self.canShoot or not player then
        return false
    end

    if self.state ~= "walk" and self.state ~= "fly" then
        return false
    end
	
	---в какую сторону стрелять	
	if not self:isPlayerInAttackDirection(player) then
        return false
    end

    if self:getDistanceToPlayer(player) > self.shootRange then
        return false
    end

    self.shootTimer = self.shootTimer - dt

    if self.shootTimer > 0 then
        return false
    end

    self.shootTimer = self.shootCooldown

    if math.random() > self.shootChance then
        return false
    end
---напрвление выстрела
	local direction = self:getAttackDirection(player)
	
----проджектайлы
	local projectile = self.bulletProjectile or {}

	local projectileSpeed = projectile.speed
		or projectile.bulletSpeed
		or self.bulletSpeed

	local projectileVx = projectile.vx

	if projectileVx == nil then
		projectileVx = projectileSpeed * direction
	end

	local projectileW = projectile.w or self.bulletW
	local projectileH = projectile.h or self.bulletH

	self.pendingAttackProjectile = copyTable(projectile)

	self.pendingAttackProjectile.x = self.x + self.w / 2 - projectileW / 2
	self.pendingAttackProjectile.y = self.y + self.h / 2 - projectileH / 2
	self.pendingAttackProjectile.w = projectileW
	self.pendingAttackProjectile.h = projectileH

	self.pendingAttackProjectile.vx = projectileVx
	self.pendingAttackProjectile.vy = projectile.vy or 0

	self.pendingAttackProjectile.damage = projectile.damage or self.bulletDamage
	self.pendingAttackProjectile.image = projectile.image or self.bulletImage
	self.pendingAttackProjectile.color = projectile.color

    self:setState("attack")

    return true
end

-- Попытка сбросить projectile летающим врагом.
-- Работает аналогично tryShoot:
-- projectile подготавливается сейчас,
-- а появляется на нужном кадре attack-анимации.
function Enemy:tryDropProjectile(player, dt)
    if not self.flying or not self.canDropProjectile or not player then
        return false
    end

    if self.state ~= "fly" then
        return false
    end

    local enemyCenterX = self.x + self.w / 2
    local playerCenterX = player.x + player.w / 2
    local distanceX = math.abs(enemyCenterX - playerCenterX)

    if distanceX > self.dropRangeX then
        return false
    end

    if player.y <= self.y then
        return false
    end

    self.dropTimer = self.dropTimer - dt

    if self.dropTimer > 0 then
        return false
    end

    self.dropTimer = self.dropCooldown

    if math.random() > self.dropChance then
        return false
    end
---проджектайл
	local projectile = self.dropProjectileConfig or {}

	local projectileW = projectile.w or self.dropW
	local projectileH = projectile.h or self.dropH

	self.pendingAttackProjectile = copyTable(projectile)

	self.pendingAttackProjectile.x = self.x + self.w / 2 - projectileW / 2
	self.pendingAttackProjectile.y = self.y + self.h
	self.pendingAttackProjectile.w = projectileW
	self.pendingAttackProjectile.h = projectileH

	self.pendingAttackProjectile.vx = projectile.vx or 0
	self.pendingAttackProjectile.vy = projectile.vy
		or projectile.speed
		or projectile.dropSpeed
		or self.dropSpeed

	self.pendingAttackProjectile.damage = projectile.damage or self.dropDamage
	self.pendingAttackProjectile.image = projectile.image or self.dropImage
	self.pendingAttackProjectile.color = projectile.color

    self:setState("attack")

    return true
end

-- main.lua забирает shotRequest и создаёт EnemyBullet.
function Enemy:consumeShotRequest()
    local shotRequest = self.shotRequest
    self.shotRequest = nil

    return shotRequest
end

------функции эффектов
function Enemy:spawnEffect(event)
    local effectConfig = copyTable(event)

    effectConfig.action = nil
    effectConfig.frame = nil

    effectConfig.x = self.x + (event.offsetX or event.offset_x or 0)
    effectConfig.y = self.y + (event.offsetY or event.offset_y or 0)

    table.insert(self.effectSpawnRequests, effectConfig)
end

function Enemy:consumeEffectSpawnRequests()
    local requests = self.effectSpawnRequests
    self.effectSpawnRequests = {}

    return requests
end
-------
-- Создаёт shotRequest из заранее подготовленного pendingAttackProjectile.
-- Обычно вызывается animation event-ом emitPendingProjectile.
function Enemy:emitPendingProjectile()
    if not self.pendingAttackProjectile then
        return
    end

    self.shotRequest = copyTable(self.pendingAttackProjectile)
    self.pendingAttackProjectile = nil
end

-- Обработка одного animation event. тут и звуки и эффекты
function Enemy:handleAnimationEvent(event)
    if event.action == "emitPendingProjectile" then
        self:emitPendingProjectile()
        return
    end

    if event.action == "sound" and event.sound then
        playSoundFile(event.sound)
        return
    end
	
	if event.action == "spawnEffect" then
        self:spawnEffect(event)
        return
    end	

    -- Прямое создание projectile из animation config.
    -- Это пригодится для будущего OpenBOR-стиля:
    --
    -- events = {
    --     { frame = 3, action = "projectile", offsetX = 40, offsetY = 20 }
    -- }
    if event.action == "projectile" then
        local direction = event.direction or -1

        if event.towardsPlayer and self.lastPlayer then
            direction = self:getDirectionToPlayer(self.lastPlayer)
        end

        self.shotRequest = {
            x = self.x + (event.offsetX or self.w / 2),
            y = self.y + (event.offsetY or self.h / 2),
            w = event.w or self.bulletW,
            h = event.h or self.bulletH,
            vx = event.vx or ((event.speed or self.bulletSpeed) * direction),
            vy = event.vy or 0,
            damage = event.damage or self.bulletDamage,
            image = event.image or self.bulletImage
        }

        return
    end
end

-- Обработка списка animation events за кадр.
function Enemy:handleAnimationEvents(events)
    for _, event in ipairs(events or {}) do
        self:handleAnimationEvent(event)
    end
end

-- Попытка начать прыжковую атаку.
function Enemy:tryJumpAttack(player, dt)
    if self.flying then
        return false
    end

    if not self.canJumpAttack or not player then
        return false
    end

    if self.state ~= "walk" then
        return false
    end

    if self:getDistanceToPlayer(player) > self.jumpAttackRange then
        return false
    end

    self.jumpTimer = self.jumpTimer - dt

    if self.jumpTimer > 0 then
        return false
    end

    self.jumpTimer = self.jumpCooldown

    if math.random() > self.jumpChance then
        return false
    end

    local direction = self:getAttackDirection(player)

    self.jumpDirection = direction
    self.jumpHitPlayer = false

    self.vy = self.jumpPower
    self:setState("jump")

    return true
end

-- Основная state machine врага.
function Enemy:update(dt, player, targetGroups)
    local target = self:selectTarget(player, targetGroups)

    self.lastPlayer = player
    self.currentTarget = target

    self.previousX = self.x
    self.previousY = self.y

    if self.dead then
        self:updateAnimation(dt)
        return
    end
---CЛЕДОВАНИЕ ЗА ИГРОКОМ	
-- если есть цель — атакуем/идём к цели
-- если цели нет, но это npc-follow — идём к игроку
	if not target and self:tryFollowPlayer(dt, player) then
            self:updateAnimation(dt)
            return
        end

    -- Лёгкое покачивание flying-врагов.
    if self.flying then
        self.flyTimer = self.flyTimer + dt

        if self.flyAmplitude > 0 then
            self.y = self.baseY + math.sin(self.flyTimer * self.flyFrequency) * self.flyAmplitude
        end
    end

    -- attack теперь завершается концом attack-анимации,
    -- а не отдельным attackTimer.
	if self.state == "attack" then
			self:updateAnimation(dt)

			if self.animationSet:isCurrentFinished() then
				self.pendingAttackProjectile = nil

				if self.retreatAfterMelee then
					self.retreatMoved = 0
					self.retreatDistance = self.meleeRetreatDistance
					self.retreatThenTaunt = false
					self:setState("retreat")
				else
					self:setState(self:getMoveState())
				end
			end

			return
		end
		
--------поворот		
		if self.state == "turn" then
				self:updateAnimation(dt)

				if self.animationSet:isCurrentFinished() then
					if self.pendingFacingDirection then
						self.facingDirection = self.pendingFacingDirection
						self.pendingFacingDirection = nil
					end

					self:setState(self:getMoveState())
				end

				return
			end		

    -- Физика jumper-врага.
    if self.state == "jump" then
        self.x = self.x + self.jumpDirection * self.jumpSpeedX * dt
        self.vy = self.vy + self.gravity * dt
        self.y = self.y + self.vy * dt

        if self.y >= self.groundY - self.h then
            self.y = self.groundY - self.h
            self.vy = 0
            self.jumpHitPlayer = false

            self.retreatMoved = 0
            self.retreatDistance = self.jumpRetreatDistance
            self.retreatThenTaunt = false
            self:setState("retreat")
        end

        self:updateAnimation(dt)
        return
    end

--если нужно разворачиваемся
-- Основное движение walk/fly.
    if self.state == "walk" or self.state == "fly" then
        -- Если MoveDirection = 0 и игрок с другой стороны,
        -- сначала проигрываем turn-анимацию.
        if self:tryTurnToPlayer(target) then
            self:updateAnimation(dt)
            return
        end
        if self:tryJumpAttack(target, dt) then
            self:updateAnimation(dt)
            return
        end

		if self:tryMeleeAttack(target, dt) then
            self:updateAnimation(dt)
            return
        end

        -- Если враг уже в melee-дистанции, он ждёт cooldown удара
        -- и не проходит сквозь игрока.
        if self:isPlayerInMeleeRange(target) then
            self:updateAnimation(dt)
            return
        end

        if self:tryDropProjectile(target, dt) then
            self:updateAnimation(dt)
            return
        end

        if self:tryShoot(target, dt) then
            self:updateAnimation(dt)
            return
        end

        if self.state == "walk" or self.state == "fly" then
            local moveDirection = self:getMoveDirection(target)

			self.facingDirection = moveDirection
			self.x = self.x + moveDirection * self.speed * dt
        end

    -- Отход назад.
    elseif self.state == "retreat" then
			local move = self.retreatSpeed * dt

			self.x = self.x - self.facingDirection * move
			self.retreatMoved = self.retreatMoved + move

        if self.retreatMoved >= self.retreatDistance then
            self.retreatDistance = self.defaultRetreatDistance or self.retreatDistance

            if self.retreatThenTaunt then
                self.tauntTimer = self.tauntDuration
                self:setState("taunt")
                playRandomSound(self.sounds.taunt)
            else
                self:setState(self:getMoveState())
            end
        end

    -- Taunt после retreat.
    elseif self.state == "taunt" then
        self.tauntTimer = self.tauntTimer - dt

        if self.tauntTimer <= 0 then
            self:setState(self:getMoveState())
        end
    end

    self:updateAnimation(dt)
end

-- Обновляет текущую анимацию и обрабатывает её events.
function Enemy:updateAnimation(dt)
    if not self.animationSet then
        return
    end

    local events = self.animationSet:update(dt)
    self:handleAnimationEvents(events)

    if self.state == "death"
        and self.animationSet:isCurrentFinished()
    then
        self.deathFinished = true
    end
end

-- Ушёл ли враг за экран.
function Enemy:isOffscreen()
    if self.DissaperWheOutOfScreen == 0 then
        return false
    end

    local screenWidth = love.graphics.getWidth()
    local margin = self.DissaperWheOutOfScreen

    return self.x + self.w < -margin
        or self.x > screenWidth + margin
end

function Enemy:isRemovable()
    return self:isOffscreen() or self.deathFinished
end

-- Физический hitbox.
function Enemy:getHitbox()
    return {
        x = self.x,
        y = self.y,
        w = self.w,
        h = self.h
    }
end

-- Отрисовка врага и HP-bar (если есть).
function Enemy:draw()
	if self.animationSet then
		local drawX = self.x + self.offsetX
		local drawY = self.y + self.offsetY

		local shouldFlipImage = self.flipImage == true

		if self.facingDirection == 1 then
			shouldFlipImage = not shouldFlipImage
		end

		if shouldFlipImage then
			local animation = self.animationSet:getCurrentAnimation()
			local image = nil

			if animation then
				image = animation:getCurrentImage()
			end

			if image then
				drawX = drawX + image:getWidth()
			end

			self.animationSet:draw(
				drawX,
				drawY,
				0,
				-1,
				1,
				0,
				0,
				self.alpha
			)
		else
			self.animationSet:draw(
				drawX,
				drawY,
				0,
				1,
				1,
				0,
				0,
				self.alpha
			)
		end
	end

    if not self.dead and self.showHealthBar then
        local healthRatio = self.health / self.maxHealth
        local barWidth = self.w
        local barHeight = 4
        local barX = self.x
        local barY = self.y - 8

        love.graphics.setColor(0.08, 0.08, 0.08, 0.85)
        love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)

        love.graphics.setColor(0.2, 0.9, 0.25)
        love.graphics.rectangle("fill", barX, barY, barWidth * healthRatio, barHeight)

        love.graphics.setColor(1, 1, 1)
    end
end

return Enemy