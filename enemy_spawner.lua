local ModelResolver = require("model_resolver")
local EnemyModels = require("data.enemies")

local EnemySpawner = {}
EnemySpawner.__index = EnemySpawner

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

local function getWeight(item)
    return item.spawnChance
        or item.spawn_chance
        or item.chance
        or item.weight
        or nil
end

local function pickWeighted(items)
    if #items == 0 then
        return nil
    end

    local hasWeight = false

    for _, item in ipairs(items) do
        if getWeight(item) ~= nil then
            hasWeight = true
            break
        end
    end

    if not hasWeight then
        return items[math.random(1, #items)]
    end

    local totalWeight = 0

    for _, item in ipairs(items) do
        local weight = getWeight(item) or 0

        if weight > 0 then
            totalWeight = totalWeight + weight
        end
    end

    if totalWeight <= 0 then
        return nil
    end

    local roll = math.random() * totalWeight
    local currentWeight = 0

    for _, item in ipairs(items) do
        local weight = getWeight(item) or 0

        if weight > 0 then
            currentWeight = currentWeight + weight

            if roll <= currentWeight then
                return item
            end
        end
    end

    return items[#items]
end

function EnemySpawner:new(config)
    local spawner = setmetatable({}, EnemySpawner)

    spawner.x = config.x or "right"
    spawner.y = config.y

    -- Если x = "right", враг появляется за правой границей экрана.
    spawner.offsetX = config.offsetX or config.offset_x or 20

    spawner.minSpawnDelay = config.minSpawnDelay
        or config.min_spawn_delay
        or 1.0

    spawner.maxSpawnDelay = config.maxSpawnDelay
        or config.max_spawn_delay
        or 1.8

    spawner.startDelay = config.startDelay
        or config.start_delay
        or 0

    -- Если duration nil, spawner работает бесконечно.
    spawner.duration = config.duration

    -- Если spawnLimit nil, лимита по количеству созданных врагов нет.
    spawner.spawnLimit = config.spawnLimit
        or config.spawn_limit

    spawner.elapsed = 0
    spawner.spawnTimer = spawner.startDelay
    spawner.spawnedCount = 0

    spawner.spawnRequests = {}

    spawner.enemies = {}

    for _, enemyConfig in ipairs(config.enemies or {}) do
        table.insert(
            spawner.enemies,
            ModelResolver.resolve(enemyConfig, EnemyModels, "enemy")
        )
    end

    return spawner
end

function EnemySpawner:reset()
    self.elapsed = 0
    self.spawnTimer = self.startDelay
    self.spawnedCount = 0
    self.spawnRequests = {}
end

function EnemySpawner:getSpawnDelay()
    return self.minSpawnDelay
        + math.random() * (self.maxSpawnDelay - self.minSpawnDelay)
end

function EnemySpawner:getSpawnX()
    if self.x == "right" then
        return love.graphics.getWidth() + self.offsetX
    end

    return self.x
end

function EnemySpawner:canSpawn()
    if #self.enemies == 0 then
        return false
    end

    if self.duration and self.elapsed >= self.duration then
        return false
    end

    if self.spawnLimit and self.spawnedCount >= self.spawnLimit then
        return false
    end

    return true
end

function EnemySpawner:createSpawnRequest()
    local enemyConfig = pickWeighted(self.enemies)

    if not enemyConfig then
        return
    end

    local resolvedEnemyConfig = deepCopy(enemyConfig)

    -- Если spawner.y задан, можно переопределить y врага.
    -- Особенно полезно для flying-врагов.
    if self.y ~= nil and self.y ~= "ground" then
        resolvedEnemyConfig.y = self.y
    end

    table.insert(self.spawnRequests, {
        config = resolvedEnemyConfig,
        x = self:getSpawnX()
    })

    self.spawnedCount = self.spawnedCount + 1
end

function EnemySpawner:update(dt)
    self.elapsed = self.elapsed + dt

    if not self:canSpawn() then
        return
    end

    self.spawnTimer = self.spawnTimer - dt

    if self.spawnTimer > 0 then
        return
    end

    self:createSpawnRequest()
    self.spawnTimer = self:getSpawnDelay()
end

function EnemySpawner:consumeSpawnRequests()
    local requests = self.spawnRequests
    self.spawnRequests = {}

    return requests
end

return EnemySpawner