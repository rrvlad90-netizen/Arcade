local AnimationSet = require("animation_set")

local Decor = {}
Decor.__index = Decor

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
                frameDuration = config.frameDuration or 0.12,
                frames = frames or {}
            }
        }
    }
end

function Decor:new(config)
    config = config or {}

    local decor = setmetatable({}, Decor)

    decor.x = config.x or 0
    decor.y = config.y or 0
    decor.w = config.w or config.width or 64
    decor.h = config.h or config.height or 64

    -- layer = "back"  — за объектами
    -- layer = "front" — перед объектами
    decor.layer = config.layer
        or config.drawLayer
        or "back"

    if config.front == true then
        decor.layer = "front"
    end

    -- Положительная скорость двигает декор справа налево.
    -- 0 — стоит на месте.
    decor.scrollSpeed = config.speed
        or config.DecorScrollSpeed
        or config.decorScrollSpeed
        or 0

    decor.DissaperWheOutOfScreen = config.DissaperWheOutOfScreen
        or config.disappearWhenOutOfScreen
        or 100

    decor.color = config.color or {0.45, 0.45, 0.45}

    decor.alpha = config.alpha

    if decor.alpha == nil then
        decor.alpha = 1
    end

    -- Если есть animations/frames — используем новую систему анимаций.
    decor.animationSet = nil

    if config.animations or config.frames then
        decor.animationSet = AnimationSet:new(createAnimationConfig({
            w = decor.w,
            h = decor.h,
            color = decor.color,

            image = config.image,
            frames = config.frames,
            animations = config.animations,

            loop = config.loop,
            holdLastFrame = config.holdLastFrame,
            frameDuration = config.frameDuration,
            defaultState = config.defaultState
        }))
    end

    -- Старый режим: одна статичная картинка.
    -- Используется, если animations/frames не указаны.
    decor.imagePath = config.image
    decor.image = nil

    if not decor.animationSet and fileExists(decor.imagePath) then
        decor.image = love.graphics.newImage(decor.imagePath)
    end

    -- Опциональный звук декора.
    -- soundLoop = true — зацикленный звук, например костёр/водопад.
    decor.soundPath = config.sound
        or config.soundPath
        or config.sound_path

    decor.soundLoop = config.soundLoop == true
        or config.loopSound == true
        or config.sound_loop == true

    decor.sound = nil

    if fileExists(decor.soundPath) then
        decor.sound = love.audio.newSource(decor.soundPath, "static")
        decor.sound:setLooping(decor.soundLoop)
        decor.sound:play()
    end

    return decor
end

function Decor:start()
    if not self.sound then
        return
    end

    self.sound:stop()
    self.sound:play()
end

function Decor:stop()
    if self.sound then
        self.sound:stop()
    end
end

function Decor:destroy()
    self:stop()
end

function Decor:update(dt)
    self.x = self.x - self.scrollSpeed * dt

    if self.animationSet then
        self.animationSet:update(dt)
    end
end

function Decor:isOffscreen()
    if self.DissaperWheOutOfScreen == 0 then
        return false
    end

    local screenWidth = love.graphics.getWidth()
    local margin = self.DissaperWheOutOfScreen

    return self.x + self.w < -margin
        or self.x > screenWidth + margin
end

function Decor:isRemovable()
    return self:isOffscreen()
end

function Decor:draw()
    if self.animationSet then
        self.animationSet:draw(
            self.x,
            self.y,
            0,
            1,
            1,
            0,
            0,
            self.alpha
        )

        return
    end

    if self.image then
        love.graphics.setColor(1, 1, 1, self.alpha)
        love.graphics.draw(
            self.image,
            self.x,
            self.y,
            0,
            self.w / self.image:getWidth(),
            self.h / self.image:getHeight()
        )

        love.graphics.setColor(1, 1, 1)
        return
    end

    -- Мокап декора
    love.graphics.setColor(
        self.color[1],
        self.color[2],
        self.color[3],
        self.alpha
    )

    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 6, 6)

    love.graphics.setColor(1, 1, 1, 0.35 * self.alpha)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h, 6, 6)

    love.graphics.setColor(1, 1, 1)
end

return Decor