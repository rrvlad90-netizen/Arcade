local ModelResolver = {}

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

function ModelResolver.resolve(config, registry, kind)
    if not config or not config.model then
        return config
    end

    local modelConfig = registry[config.model]

    if not modelConfig then
        error("Unknown " .. tostring(kind or "model") .. " model: " .. tostring(config.model))
    end

    local resolvedConfig = mergeModelConfig(modelConfig, config)
    resolvedConfig.model = config.model

    return resolvedConfig
end

function ModelResolver.resolveList(configs, registry, kind)
    local result = {}

    for _, config in ipairs(configs or {}) do
        table.insert(result, ModelResolver.resolve(config, registry, kind))
    end

    return result
end

function ModelResolver.createObjects(configs, registry, class, kind)
    local result = {}

    for _, config in ipairs(configs or {}) do
        table.insert(
            result,
            class:new(ModelResolver.resolve(config, registry, kind))
        )
    end

    return result
end

return ModelResolver