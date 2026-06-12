local Targeting = {}

local function copyTargets(source)
    local result = {}

    for key, value in pairs(source or {}) do
        if type(key) == "number" then
            result[value] = true
        elseif value == true then
            result[key] = true
        end
    end

    return result
end

function Targeting.buildTargetSet(configTargets, defaultTargets)
    if configTargets == nil then
        return copyTargets(defaultTargets)
    end

    if type(configTargets) == "string" then
        return {
            [configTargets] = true
        }
    end

    if type(configTargets) == "table" then
        return copyTargets(configTargets)
    end

    return {}
end

function Targeting.isAlive(target)
    if not target then
        return false
    end

    if target.dead then
        return false
    end

    if target.isAlive then
        return target:isAlive()
    end

    return true
end

function Targeting.getEntityType(target)
    return target.entityType
        or target.entity_type
        or "unknown"
end

function Targeting.canAttack(actor, target)
    if actor == target then
        return false
    end

    if not Targeting.isAlive(target) then
        return false
    end

    local targetType = Targeting.getEntityType(target)

    return actor.hates
        and actor.hates[targetType] == true
end

function Targeting.getCenterX(target)
    return target.x + target.w / 2
end

function Targeting.getCenterY(target)
    return target.y + target.h / 2
end

function Targeting.getDistanceSquared(a, b)
    local dx = Targeting.getCenterX(a) - Targeting.getCenterX(b)
    local dy = Targeting.getCenterY(a) - Targeting.getCenterY(b)

    return dx * dx + dy * dy
end

function Targeting.findNearestTarget(actor, targetGroups)
    local bestTarget = nil
    local bestDistance = nil

    for _, targets in pairs(targetGroups or {}) do
        for _, target in ipairs(targets or {}) do
            if Targeting.canAttack(actor, target) then
                local distance = Targeting.getDistanceSquared(actor, target)

                if not bestDistance or distance < bestDistance then
                    bestDistance = distance
                    bestTarget = target
                end
            end
        end
    end

    return bestTarget
end

return Targeting