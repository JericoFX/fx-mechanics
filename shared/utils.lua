Utils = {}

---Log all the params to a simple string table
---@param ... any | table
function log(...)
    local args = type(...) == "table" and ... or { ... }
    print(json.encode(args, { indent = true }))
end

---Handle a stateBag Options
---@param bagName string
---@param cb function
---@return number | function
function HandleStateBag(bagName, cb)
    Citizen.CreateThreadNow(function()
        local p = promise.new()
        return AddStateBagChangeHandler(bagName, nil, function(bagNameEvent, _, value, _unused, _replicated)
            local entity = GetEntityFromStateBagName(bagNameEvent)
            if entity == 0 then return end
            local network = NetToVeh(VehToNet(entity))
            local status, err = pcall(function()
                p:resolve(value)
            end)
            if not status then
                p:reject(false)
                return print(err)
            end
            return cb(network, value)
        end)
    end)
end

---Set the value to a specific entity
---@param entity number | string
---@param bagName string
---@param value any
---@param replicated boolean
---@return boolean
function SetBagValue(entity, bagName, value, replicated)
    local id = NetworkGetNetworkIdFromEntity(entity)
    print(entity, bagName, value, replicated)
    local data = Entity(NetToVeh(id)).state:set(bagName, value, replicated)
    return data ~= nil
end

---Get the Value of a specific entity
---@param entity string | number
---@param bagKey string
---@return any
function GetBagValue(entity, bagKey)
    local id = NetworkGetNetworkIdFromEntity(entity)
    local vehicle = NetToVeh(id)
    print(vehicle, id)
    local bag = GetStateBagValue(("entity:%s"):format(id), bagKey)
    print(bag)
    return bag ~= nil
end

function DurationLerp(vehicle, duration, type)
    local start = GetGameTimer()
    local elapsed = 0.0

    local getRotation = GetEntityCoords(vehicle)
    while elapsed < duration do
        Wait(0)
        elapsed = elapsed + GetGameTimer() - start
        start = GetGameTimer()
        if type == "up" then
            local value = lerp(GetEntityCoords(vehicle).z, GetEntityCoords(vehicle).z + 0.0015,
                elapsed / duration)
            SetEntityCoordsNoOffset(vehicle, getRotation.x, getRotation.y, value
            , true, false, true)
        else
            local value = lerp(GetEntityCoords(vehicle).z, GetEntityCoords(vehicle).z - 0.0015,
                elapsed / duration)
            SetEntityCoordsNoOffset(vehicle, getRotation.x, getRotation.y, value
            , true, false, true)
        end
    end
end
