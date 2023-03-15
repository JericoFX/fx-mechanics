local _STATE_BAGS_ = {}

---Log all the params to a simple string table
---@param ... any | table
function log(...)
    local args = type(...) == "table" and ... or { ... }
    print(json.encode(args, { indent = true }))
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

---Handle a stateBag Options
---@param bagName string
---@param cb function
---@return number | function | nil
--https://github.com/BerkieBb/pma-sirensync/blob/a2abb8343d13a6e11c239854c973e6e8f9a7cb47/client/utils.ts#LL7C99-L7C100
function HandleStateBag(bagName, cb)
    Citizen.CreateThreadNow(function()
        local p = promise.new()
        local status, err = pcall(function()
            return AddStateBagChangeHandler(bagName, nil, function(bagNameEvent, _, value, _unused, _replicated)
                local entity = GetEntityFromStateBagName(bagNameEvent)
                if entity == 0 then return end
                local timeout = GetGameTimer() + 1500
                local network = NetToVeh(VehToNet(entity))
                local owner = NetworkGetEntityOwner(network) == cache.ped
                while not NetworkDoesEntityExistWithNetworkId(VehToNet(entity)) do
                    Wait(0)
                    print("Founded")
                    if timeout < GetGameTimer() then
                        print("No Entity Found")
                        p:reject()
                        break
                    end
                end

                if not owner and _replicated or owner and not _replicated then
                    p:reject()
                    return
                end
                return cb(network, value)
            end)
        end)
        if not status then
            p:reject(false)
            return print(err)
        end
    end)
    return
end

---Return vehicle basic damage
---@param entity string | number
---@return {oil: number,petrol:number,fuel:number,body:number,wheels:table,windows:table}
function GetVehicleDamages(entity)
    local windows, wheels = {}, {}

    for i = 0, 7 do
        local damaged = IsVehicleWindowIntact(entity --[[@as number]], i) -- False means the vehicle has the window i broken.
        windows[i] = damaged
    end

    for i = 0, GetVehicleNumberOfWheels(entity --[[@as number]]) - 1 do
        local burst, notBurst = IsVehicleTyreBurst(entity --[[@as number]], i, true),
            IsVehicleTyreBurst(entity --[[@as number]], i, false)
        if burst or notBurst then
            wheels[i] = burst and burst or notBurst
        end
    end

    return {
        oil = GetVehicleOilLevel(entity --[[@as number]]),
        petrol = GetVehiclePetrolTankHealth(entity --[[@as number]]),
        fuel = Config.FuelResource.use and exports[Config.FuelResource.use]:GetFuel(entity) or
            GetVehicleFuelLevel(entity --[[@as number]]),
        body = GetVehicleBodyHealth(entity --[[@as number]]),
        engine = GetVehicleEngineHealth(entity --[[@as number]]),
        wheels = wheels,
        windows = windows
    }
end
