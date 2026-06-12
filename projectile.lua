local AnimationSet = require("animation_set")

local Projectile = {}
Projectile.__index = Projectile

local function fileExists(path)
    return path and love.filesystem.getInfo(path) ~= nil
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

local function buildDamageTargets(config)
    local targets = {}

    local damageTargets = config.damageTargets
        or config.damage_targets

    if type(damageTargets) == "string" then
        targets[damageTargets] = true
    elseif type(damageTargets) == "table" then
        for key, value in pairs(damageTargets) do
            if type(key) == "number" then
                targets[value] = true
            elseif value == true then
                targets[key] = true
            end
        end
    end

    if config.damagePlayer == true or config.damage_player == true then
        targets.player = true
    end

    if config.damageEnemy == true
        or config.damageEnemies == true
        or config.damage_enemy == true
        or config.damage_enemies == true
    then
        targets.enemy = true
    end

    if config.damageNpc == true
        or config.damageNPC == true
        or config.damage_npc == true
    then
        targets.npc = true
    end

    return targets
end

function Projectile:new(config)
    config = config or {}

    local projectile = setmetatable({}, Projectile)

    projectile.x = config.x or 0
    projectile.y = config.y or 0
    projectile.w = config.w or config.width or 12
    projectile.h = config.h or config.height or 12

    projectile.vx = config.vx or config.speedX or config.speed_x or config.speed or 0
    projectile.vy = config.vy or config.speedY or config.speed_y or 0

    projectile.gravity = config.gravity
        or config.projectileGravity
        or config.projectile_gravity
        or 0

    projectile.rotateToVelocity = config.rotateToVelocity == true
        or config.rotate_to_velocity == true

    projectile.rotation = config.rotation or 0

    projectile.damage = config.damage or 1
    projectile.damageTargets = buildDamageTargets(config)

    projectile.impactEffect = config.impactEffect
        or config.impact_effect

    projectile.impactOffsetX = config.impactOffsetX
        or config.impact_offset_x
        or 0

    projectile.impactOffsetY = config.impactOffsetY
        or config.impact_offset_y
        or 0

    projectile.collideGround = config.collideGround == true
        or config.collide_ground == true

    projectile.collidePlatforms = config.collidePlatforms == true
        or config.collide_platforms == true

    projectile.imagePath = config.image
    projectile.image = nil

    if fileExists(projectile.imagePath) then
        projectile.image = love.graphics.newImage(projectile.imagePath)
    end

    projectile.color = config.color or {1.0, 0.25, 0.2}
    projectile.outlineColor = config.outlineColor
        or config.outline_color
        or {0.25, 0.05, 0.04}

    projectile.alpha = config.alpha

    if projectile.alpha == nil then
        projectile.alpha = 1
    end

    projectile.animationSet = nil

    if config.animations or config.frames then
        projectile.animationSet = AnimationSet:new(createAnimationConfig({
            w = projectile.w,
            h = projectile.h,
            color = projectile.color,

            image = config.image,
            frames = config.frames,
            animations = config.animations,

            loop = config.loop,
            holdLastFrame = config.holdLastFrame,
            frameDuration = config.frameDuration,
            defaultState = config.defaultState
        }))
    end

    projectile.dissapearbytime = config.dissapearbytime
        or config.disappearByTime
        or config.disappear_by_time
        or 0

    projectile.removeWhenAnimationFinished = config.removeWhenAnimationFinished == true
        or config.remove_when_animation_finished == true

    projectile.age = 0
    projectile.dead = false

    return projectile
end

function Projectile:canDamageTarget(targetType)
    return self.damage > 0
        and self.damageTargets
        and self.damageTargets[targetType] == true
end

function Projectile:update(dt)
    if self.dead then
        return
    end

    self.age = self.age + dt

    self.vy = self.vy + self.gravity * dt

    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    if self.animationSet then
        self.animationSet:update(dt)

        if self.removeWhenAnimationFinished
            and self.animationSet:isCurrentFinished()
        then
            self.dead = true
        end
    end

    if self.rotateToVelocity
        and (self.vx ~= 0 or self.vy ~= 0)
    then
        local atan2 = math.atan2 or math.atan
        self.rotation = atan2(self.vy, self.vx)
    end

    if self.dissapearbytime > 0
        and self.age >= self.dissapearbytime
    then
        self.dead = true
    end
end

function Projectile:isOffscreen(screenWidth, screenHeight)
    screenWidth = screenWidth or love.graphics.getWidth()
    screenHeight = screenHeight or love.graphics.getHeight()

    return self.x + self.w < -100
        or self.x > screenWidth + 100
        or self.y + self.h < -100
        or self.y > screenHeight + 100
end

function Projectile:isRemovable(screenWidth, screenHeight)
    return self.dead or self:isOffscreen(screenWidth, screenHeight)
end

function Projectile:getHitbox()
    return {
        x = self.x,
        y = self.y,
        w = self.w,
        h = self.h
    }
end

function Projectile:drawAnimation()
    if not self.animationSet then
        return false
    end

    local animation = self.animationSet:getCurrentAnimation()
    local image = nil

    if animation then
        image = animation:getCurrentImage()
    end

    if not image then
        return false
    end

    local scaleX = self.w / image:getWidth()
    local scaleY = self.h / image:getHeight()

    if self.rotateToVelocity then
        self.animationSet:draw(
            self.x + self.w / 2,
            self.y + self.h / 2,
            self.rotation,
            scaleX,
            scaleY,
            image:getWidth() / 2,
            image:getHeight() / 2,
            self.alpha
        )
    else
        self.animationSet:draw(
            self.x,
            self.y,
            0,
            scaleX,
            scaleY,
            0,
            0,
            self.alpha
        )
    end

    return true
end

function Projectile:drawImage()
    if not self.image then
        return false
    end

    love.graphics.setColor(1, 1, 1, self.alpha)

    local scaleX = self.w / self.image:getWidth()
    local scaleY = self.h / self.image:getHeight()

    if self.rotateToVelocity then
        love.graphics.draw(
            self.image,
            self.x + self.w / 2,
            self.y + self.h / 2,
            self.rotation,
            scaleX,
            scaleY,
            self.image:getWidth() / 2,
            self.image:getHeight() / 2
        )
    else
        love.graphics.draw(
            self.image,
            self.x,
            self.y,
            0,
            scaleX,
            scaleY
        )
    end

    love.graphics.setColor(1, 1, 1)

    return true
end

function Projectile:drawMockup()
    love.graphics.setColor(
        self.color[1],
        self.color[2],
        self.color[3],
        self.alpha
    )

    love.graphics.circle(
        "fill",
        self.x + self.w / 2,
        self.y + self.h / 2,
        math.min(self.w, self.h) / 2
    )

    love.graphics.setColor(
        self.outlineColor[1],
        self.outlineColor[2],
        self.outlineColor[3],
        self.alpha
    )

    love.graphics.circle(
        "line",
        self.x + self.w / 2,
        self.y + self.h / 2,
        math.min(self.w, self.h) / 2
    )

    love.graphics.setColor(1, 1, 1)
end

function Projectile:draw()
    if self:drawAnimation() then
        return
    end

    if self:drawImage() then
        return
    end

    self:drawMockup()
end

return Projectile