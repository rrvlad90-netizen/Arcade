local Level = require("level")
local LevelConfigs = require("data.levels")

local Levels = {}
Levels.__index = Levels

function Levels:new()
    local levels = setmetatable({}, Levels)

    levels.items = {}

    for _, levelConfig in ipairs(LevelConfigs) do
        table.insert(levels.items, Level:new(levelConfig))
    end

    levels.currentIndex = 1

    return levels
end

function Levels:getCurrent()
    return self.items[self.currentIndex]
end

function Levels:goNext()
    local current = self:getCurrent()

    if current then
        current:stop()
    end

    self.currentIndex = self.currentIndex + 1

    local nextLevel = self:getCurrent()

    if nextLevel then
        nextLevel:start()
        return nextLevel
    end

    return nil
end

function Levels:restart()
    local current = self:getCurrent()

    if current then
        current:stop()
    end

    self.currentIndex = 1

    current = self:getCurrent()

    if current then
        current:start()
    end

    return current
end

return Levels