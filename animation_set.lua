local Animation = require("animation")

local AnimationSet = {}
AnimationSet.__index = AnimationSet

local function copyAnimationConfig(config)
    local copy = {}

    for key, value in pairs(config or {}) do
        copy[key] = value
    end

    return copy
end

function AnimationSet:new(config)
    config = config or {}

    local set = setmetatable({}, AnimationSet)

    set.animations = {}
    set.currentState = nil
    set.defaultState = config.defaultState
    set.pendingEvents = {}

    -- Общие fallback-настройки.
    -- Они передаются в каждую Animation, если в самой анимации
    -- не указаны свои w/h/color.
    set.w = config.w or 48
    set.h = config.h or 48
    set.color = config.color or {1, 0, 1}

    for state, animationConfig in pairs(config.animations or {}) do
        local preparedConfig = copyAnimationConfig(animationConfig)

        preparedConfig.name = preparedConfig.name or state
        preparedConfig.w = preparedConfig.w or set.w
        preparedConfig.h = preparedConfig.h or set.h
        preparedConfig.color = preparedConfig.color or set.color

        set.animations[state] = Animation:new(preparedConfig)

        if not set.defaultState then
            set.defaultState = state
        end
    end

    -- Если анимаций вообще не передали, создаём fallback idle.
    if not set.defaultState then
        set.defaultState = "idle"

        set.animations.idle = Animation:new({
            name = "idle",
            loop = true,
            w = set.w,
            h = set.h,
            color = set.color,
            frames = {}
        })
    end

    set:setState(set.defaultState, true)

    return set
end

function AnimationSet:hasState(state)
    return self.animations[state] ~= nil
end

function AnimationSet:getCurrentState()
    return self.currentState
end

function AnimationSet:getCurrentAnimation()
    return self.animations[self.currentState]
end

function AnimationSet:getAnimation(state)
    return self.animations[state]
end

function AnimationSet:getFallbackState(state)
    if self.animations[state] then
        return state
    end

    if self.animations[self.defaultState] then
        return self.defaultState
    end

    for existingState, _ in pairs(self.animations) do
        return existingState
    end

    return nil
end

function AnimationSet:addPendingEvents(events)
    for _, event in ipairs(events or {}) do
        table.insert(self.pendingEvents, event)
    end
end

function AnimationSet:consumeEvents()
    local events = self.pendingEvents
    self.pendingEvents = {}

    return events
end

-- Переключает состояние анимации.
-- force = true принудительно перезапускает даже ту же самую анимацию.
function AnimationSet:setState(state, force)
    local nextState = self:getFallbackState(state)

    if not nextState then
        return
    end

    if self.currentState == nextState and not force then
        return
    end

    self.currentState = nextState

    local animation = self:getCurrentAnimation()
    animation:reset()

    -- Если у первого кадра есть events, они попадут сюда.
    self:addPendingEvents(animation:consumeEvents())
end

function AnimationSet:resetCurrent()
    local animation = self:getCurrentAnimation()

    if not animation then
        return
    end

    animation:reset()
    self:addPendingEvents(animation:consumeEvents())
end

function AnimationSet:isCurrentFinished()
    local animation = self:getCurrentAnimation()

    if not animation then
        return true
    end

    return animation:isFinished()
end

function AnimationSet:getCurrentFrameIndex()
    local animation = self:getCurrentAnimation()

    if not animation then
        return 1
    end

    return animation:getCurrentFrameIndex()
end

function AnimationSet:update(dt)
    local animation = self:getCurrentAnimation()

    if animation then
        self:addPendingEvents(animation:update(dt))
    end

    return self:consumeEvents()
end

function AnimationSet:draw(x, y, rotation, scaleX, scaleY, offsetX, offsetY, alpha)
    local animation = self:getCurrentAnimation()

    if not animation then
        return
    end

    animation:draw(x, y, rotation, scaleX, scaleY, offsetX, offsetY, alpha)
end

return AnimationSet