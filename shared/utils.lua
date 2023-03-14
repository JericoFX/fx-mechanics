---Log all the params to a simple string table
---@param ... any | table
function log(...)
    local args = type(...) == "table" and ... or { ... }
    print(json.encode(args, { indent = true }))
end

---Handle a stateBag Options
---@param bagName string
---@param cb function
---@return number | function | nil
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
    return
end

---Set a state bag to a specific entity
---@param entity number | string The target vehicle
---@param bagName string Name of the bag
---@param value any Parameter to send
---@param replicated boolean if is gonna be replicated to the server
---@return boolean
function SetBagValue(entity, bagName, value, replicated)
    local id = NetworkGetNetworkIdFromEntity(entity --[[@as number]])
    --print(entity, bagName, value, replicated)
    --print(debug.traceback(bagName, 1))
    local data = Entity(NetToVeh(id)).state:set(bagName, value, replicated)
    return data ~= nil
end

---Get the Value of a specific entity
---@param entity string | number
---@param bagKey string
---@return any
function GetBagValue(entity, bagKey)
    local id = NetworkGetNetworkIdFromEntity(entity --[[@as number]])
    local vehicle = NetToVeh(id)
    local bag = GetStateBagValue(("entity:%s"):format(id), bagKey)
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

---Return vehicle basic damage
---@param entity string | number
function GetVehicleDamages(entity)
    CreateThread(function()
        local window, wheels = {}, {}
        for i = 0, 7 do
            if not IsVehicleWindowIntact(entity --[[@as number]], i) then
                window[i] = true
            end
        end
        for i = 0, GetVehicleNumberOfWheels(entity --[[@as number]]) - 1 do
            local burst, notBurst = IsVehicleTyreBurst(entity --[[@as number]], i, true),
                IsVehicleTyreBurst(entity --[[@as number]], i, false)
            if burst or notBurst then
                wheels[i] = burst and burst or notBurst
            end
        end
        log(wheels)
        return {
            oil = GetVehicleOilLevel(entity --[[@as number]]),
            petrol = GetVehiclePetrolTankHealth(entity --[[@as number]]),
            fuel = GetVehicleFuelLevel(entity --[[@as number]]),
            body = GetVehicleBodyHealth(entity --[[@as number]]),
        }
    end)
end
