local QBCore = exports["qb-core"]:GetCoreObject()


local function GetMechanicsToBuy()

end


lib.callback.register(Shared.Events.turnEntity, function(source, veh)
    local _veh = type(veh) == "number" and veh or tonumber(veh)

    local entity = NetworkGetEntityFromNetworkId(_veh)
    -- local netId = Entity(entity).state
    -- netId.jackUP = true
    print(veh, NetworkGetNetworkIdFromEntity(entity))
    return NetworkGetNetworkIdFromEntity(entity)
end)
