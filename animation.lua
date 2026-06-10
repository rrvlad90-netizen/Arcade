local Animation = {}
Animation.__index = Animation

local function fileExists(path)
    return path and love.filesystem.getInfo(path) ~= nil
end

-- Мокап-кадр на случай, если настоящей картинки нет.
-- Это нужно, чтобы игра не падала при отсутствующих ассетах.
local function makeFallbackFrame(w, h, color)
    local canvas = love.graphics.newCanvas(w, h)

    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)

    love.graphics.setColor(color or {1, 0, 1})
    love.graphics.rectangle("fill", 0, 0, w, h, 4, 4)

    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.rectangle("line", 0, 0, w, h, 4, 4)
    love.graphics.line(0, 0, w, h)
    love.graphics.line(w, 0, 0, h)

    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)

    return canvas
end

-- Нормализуем описание кадра.
-- Поддерживаются варианты:
--
-- frames = {
--     "assets/enemy/walk_1.png",
--     "assets/enemy/walk_2.png"
-- }
--
-- или:
--
-- frames = {
--     { image = "assets/enemy/walk_1.png", duration = 0.08 },
--     { image = "assets/enemy/walk_2.png", duration = 0.12 }
-- }
local function normalizeFrame(frameConfig, defaultDuration, fallbackW, fallbackH, fallbackColor)
    local imagePath = nil
    local duration = defaultDuration

    if type(frameConfig) == "string" then
        imagePath = frameConfig
    elseif type(frameConfig) == "table" then
        imagePath = frameConfig.image
            or frameConfig.path
            or frameConfig[1]

        duration = frameConfig.duration
            or frameConfig.delay
            or defaultDuration
    end

    local image = nil

    if fileExists(imagePath) then
        image = love.graphics.newImage(imagePath)
    else
        image = makeFallbackFrame(fallbackW, fallbackH, fallbackColor)
    end

    return {
        image = image,
        imagePath = imagePath,
        duration = duration
    }
end

-- Группируем events по номеру кадра.
-- События задаются так:
--
-- events = {
--     { frame = 3, action = "projectile", projectile = "stone" },
--     { frame = 3, action = "sound", sound = "assets/sfx/shot.wav" }
-- }
--
-- Номер frame — 1-based, как удобно читать человеку.
local function buildEventsByFrame(events)
    local eventsByFrame = {}

    for _, event in ipairs(events or {}) do
        local frame = event.frame or 1

        eventsByFrame[frame] = eventsByFrame[frame] or {}
        table.insert(eventsByFrame[frame], event)
    end

    return eventsByFrame
end

function Animation:new(config)
    config = config or {}

    local animation = setmetatable({}, Animation)

    animation.name = config.name or "animation"

    -- Если loop = true, после последнего кадра анимация начнётся заново.
    -- Если loop = false, анимация завершится.
    animation.loop = config.loop == true

    -- Если holdLastFrame = true, non-loop анимация останется на последнем кадре.
    -- Это удобно для death-анимации.
    animation.holdLastFrame = config.holdLastFrame == true

    -- Общая длительность кадра.
    -- Может быть переопределена у конкретного кадра через duration/delay.
    animation.defaultFrameDuration = config.frameDuration
        or config.duration
        or config.delay
        or 0.1

    -- Размер fallback-кадра, если картинки нет.
    animation.fallbackW = config.fallbackW or config.w or 48
    animation.fallbackH = config.fallbackH or config.h or 48
    animation.fallbackColor = config.fallbackColor or config.color or {1, 0, 1}

    animation.frames = {}

    for _, frameConfig in ipairs(config.frames or {}) do
        table.insert(
            animation.frames,
            normalizeFrame(
                frameConfig,
                animation.defaultFrameDuration,
                animation.fallbackW,
                animation.fallbackH,
                animation.fallbackColor
            )
        )
    end

    -- Если frames пустой, создаём один мокап-кадр.
    -- Так игра не упадёт даже при неправильном конфиге.
    if #animation.frames == 0 then
        table.insert(animation.frames, {
            image = makeFallbackFrame(
                animation.fallbackW,
                animation.fallbackH,
                animation.fallbackColor
            ),
            imagePath = nil,
            duration = animation.defaultFrameDuration
        })
    end

    animation.eventsByFrame = buildEventsByFrame(config.events)

    animation.frame = 1
    animation.frameTimer = 0
    animation.finished = false

    -- Очередь событий, которые сработали на текущем update.
    -- Владелец анимации забирает их и решает, что делать.
    animation.pendingEvents = {}

    -- Если нужно, чтобы события первого кадра сработали сразу при старте.
    -- Для attack-анимаций обычно полезно.
    animation.fireFirstFrameEvents = config.fireFirstFrameEvents == true

    if animation.fireFirstFrameEvents then
        animation:queueFrameEvents(animation.frame)
    end

    return animation
end

function Animation:reset()
    self.frame = 1
    self.frameTimer = 0
    self.finished = false
    self.pendingEvents = {}

    if self.fireFirstFrameEvents then
        self:queueFrameEvents(self.frame)
    end
end

function Animation:isFinished()
    return self.finished
end

function Animation:getFrameCount()
    return #self.frames
end

function Animation:getCurrentFrameIndex()
    return self.frame
end

function Animation:getCurrentFrame()
    return self.frames[self.frame]
end

function Animation:getCurrentImage()
    return self.frames[self.frame].image
end

function Animation:getCurrentFrameDuration()
    return self.frames[self.frame].duration
        or self.defaultFrameDuration
end

function Animation:queueFrameEvents(frameIndex)
    local events = self.eventsByFrame[frameIndex]

    if not events then
        return
    end

    for _, event in ipairs(events) do
        table.insert(self.pendingEvents, event)
    end
end

function Animation:consumeEvents()
    local events = self.pendingEvents
    self.pendingEvents = {}

    return events
end

function Animation:advanceFrame()
    if self.finished then
        return
    end

    self.frame = self.frame + 1

    if self.frame <= #self.frames then
        self:queueFrameEvents(self.frame)
        return
    end

    if self.loop then
        self.frame = 1
        self:queueFrameEvents(self.frame)
        return
    end

    self.finished = true

    if self.holdLastFrame then
        self.frame = #self.frames
    else
        self.frame = #self.frames
    end
end

-- Обновляет анимацию.
-- Возвращает список событий, которые сработали на кадрах.
--
-- Пример:
-- local events = animation:update(dt)
-- for _, event in ipairs(events) do
--     if event.action == "projectile" then ...
-- end
function Animation:update(dt)
    if self.finished then
        return self:consumeEvents()
    end

    self.frameTimer = self.frameTimer + dt

    while self.frameTimer >= self:getCurrentFrameDuration() do
        self.frameTimer = self.frameTimer - self:getCurrentFrameDuration()
        self:advanceFrame()

        if self.finished then
            break
        end
    end

    return self:consumeEvents()
end

function Animation:draw(x, y, rotation, scaleX, scaleY, offsetX, offsetY)
    local image = self:getCurrentImage()

    rotation = rotation or 0
    scaleX = scaleX or 1
    scaleY = scaleY or 1
    offsetX = offsetX or 0
    offsetY = offsetY or 0

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(
        image,
        x,
        y,
        rotation,
        scaleX,
        scaleY,
        offsetX,
        offsetY
    )
end

return Animation