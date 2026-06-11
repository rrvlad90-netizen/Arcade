local AnimationSet = require("animation_set")

local Effect = {}
Effect.__index = Effect


local function fileExists(path)
    return path and love.filesystem.getInfo(path) ~= nil
end

local function playSoundFile(path)
    if not fileExists(path) then
        return
    end

    local sound = love.audio.newSource(path, "static")
    sound:play()
end


local function copyTable(source)
    local result = {}

    for key, value in pairs(source or {}) do
        result[key] = value
    end

    return result
end

local function createAnimationConfig(config)
    if config.animations then
        return {
            w = config.w,
            h = config.h,
            color = config.color,
            defaultState = config.defaultState or "idle",
            animations = config.animations
        }
    end

    local frames = config.frames

    if not frames and config.image then
        frames = {
            {
                image = config.image
            }
        }
    end

    return {
        w = config.w,
        h = config.h,
        color = config.color,
        defaultState = "idle",
        animations = {
            idle = {
                loop = config.loop == true,
                holdLastFrame = config.holdLastFrame == true,
                frameDuration = config.frameDuration or 0.08,
                frames = frames or {}
            }
        }
    }
end

function Effect:new(config)
    config = config or {}

    local effect = setmetatable({}, Effect)

    effect.x = config.x or 0
    effect.y = config.y or 0
    effect.w = config.w or config.width or 32
    effect.h = config.h or config.height or 32

    -- Горизонтальное смещение.
    -- Положительное значение летит вправо, отрицательное — влево.
    effect.vx = config.vx
        or config.speedX
        or config.speed_x
        or 0

    -- Вертикальная скорость.
    effect.vy = config.vy
        or config.speedY
        or config.speed_y
        or 0

    -- Гравитация.
    -- Если 0 или nil — эффект не падает.
    effect.gravity = config.gravity or 0

    -- Проверять ли удар о землю.
    effect.collideGround = config.collideGround ~= false
        and config.collide_ground ~= false

    -- Проверять ли удар о solid-платформы/возвышенности.
    effect.collidePlatforms = config.collidePlatforms ~= false
        and config.collide_platforms ~= false

    -- Удалять ли эффект после удара.
    effect.removeOnImpact = config.removeOnImpact ~= false
        and config.remove_on_impact ~= false

    -- Какой эффект создать при ударе.
    effect.impactEffect = config.impactEffect
        or config.impact_effect

    effect.impactOffsetX = config.impactOffsetX
        or config.impact_offset_x
        or 0

    effect.impactOffsetY = config.impactOffsetY
        or config.impact_offset_y
        or 0

    -- Если указано, эффект удалится через это время.
    effect.lifeTime = config.lifeTime
        or config.life_time

    effect.age = 0

    -- Если true/nil, одноразовая анимация удалит эффект после завершения.
    effect.removeWhenAnimationFinished = config.removeWhenAnimationFinished

    if effect.removeWhenAnimationFinished == nil then
        effect.removeWhenAnimationFinished = true
    end

    effect.dead = false
    effect.effectSpawnRequests = {}

    effect.color = config.color or {0.8, 0.8, 0.8}
-----прозрачность эффекта	
	effect.alpha = config.alpha

	if effect.alpha == nil then
		effect.alpha = 1
	end	
	
------звук эффекта
	effect.sound = config.sound
		or config.soundPath
		or config.sound_path

	if effect.sound then
		playSoundFile(effect.sound)
	end
-----

    effect.animationSet = AnimationSet:new(createAnimationConfig({
        w = effect.w,
        h = effect.h,
        color = effect.color,

        image = config.image,
        frames = config.frames,
        animations = config.animations,

        loop = config.loop,
        holdLastFrame = config.holdLastFrame,
        frameDuration = config.frameDuration,
        defaultState = config.defaultState
    }))

    return effect
end

function Effect:getHitbox()
    return {
        x = self.x,
        y = self.y,
        w = self.w,
        h = self.h
    }
end

function Effect:createImpactEffect()
    if not self.impactEffect then
        return
    end

    local request = copyTable(self.impactEffect)

    request.x = self.x + self.impactOffsetX
    request.y = self.y + self.impactOffsetY

    table.insert(self.effectSpawnRequests, request)
end

function Effect:onImpact()
    self:createImpactEffect()

    if self.removeOnImpact then
        self.dead = true
    end
end

function Effect:resolveGroundCollision(level)
    if not self.collideGround or not level then
        return false
    end

    if self.y + self.h >= level.groundTop then
        self.y = level.groundTop - self.h
        self.vy = 0
        self:onImpact()
        return true
    end

    return false
end

function Effect:resolvePlatformCollision(level, rectsOverlap)
    if not self.collidePlatforms or not level or not rectsOverlap then
        return false
    end

    local hitbox = self:getHitbox()

    for _, platform in ipairs(level.platforms or {}) do
        if platform.solid
            and rectsOverlap(hitbox, platform:getHitbox())
        then
            self.y = platform.walkY - self.h
            self.vy = 0
            self:onImpact()
            return true
        end
    end

    return false
end

function Effect:update(dt, level, rectsOverlap)
    if self.dead then
        return
    end

    self.age = self.age + dt

    if self.lifeTime and self.age >= self.lifeTime then
        self.dead = true
        return
    end

    self.x = self.x + self.vx * dt

    if self.gravity ~= 0 then
        self.vy = self.vy + self.gravity * dt
    end

    self.y = self.y + self.vy * dt

    if self:resolveGroundCollision(level) then
        return
    end

    if self:resolvePlatformCollision(level, rectsOverlap) then
        return
    end

    if self.animationSet then
        self.animationSet:update(dt)

        if self.removeWhenAnimationFinished
            and self.animationSet:isCurrentFinished()
        then
            self.dead = true
        end
    end
end

function Effect:consumeEffectSpawnRequests()
    local requests = self.effectSpawnRequests
    self.effectSpawnRequests = {}

    return requests
end

function Effect:isRemovable()
    return self.dead
end

function Effect:draw()
if self.animationSet then
    self.animationSet:draw(
        self.x,
        self.y,
        0,
        1,
        1,
        0,
        0,
        self.alpha --прозрачность
    )

    return
end

----В мокапе учитываем прозрачность тоже
	love.graphics.setColor(
		self.color[1],
		self.color[2],
		self.color[3],
		self.alpha
	)

	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

    love.graphics.setColor(1, 1, 1)
end

return Effect