local QBCore = exports["qb-core"]:GetCoreObject()
local playerJob, currentVehicle, zones, currentZone,jackItem = nil, nil, {}, nil,nil
local SetTimeout = Citizen.SetTimeout
local CreateThreadNow = Citizen.CreateThreadNow

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function(player)
	SetTimeout(300,function()
		local job in player
		playerJob = job
	end)


end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(player)
	SetTimeout(300,function()
		local job in player
		playerJob = job
	end)
end)
local function onEnter(self)
	currentZone = self.data.name
end
local function onExit(self)
	currentZone = nil
end

CreateThread(function()
	--Only run for the mechanics

	for k in pairs(Config.Places) do
		local el = Config.Places[k]
		if not zones[el.id] then
			zones[el.id] = {
				mechanicZone = lib.zones.box({
					id = el.id .. el.coords.mechanic_zone.name,
					coords = el.coords.mechanic_zone.coords,
					size = el.coords.mechanic_zone.size,
					rotation = el.coords.mechanic_zone.rotation,
					onEnter = onEnter,
					onExit = onExit,
					data = { name = el.id }
				}),
				bossZone = lib.zones.box({
					id = el.id .. el.coords.boss.name,
					coords = el.coords.boss.coords,
					size = el.coords.boss.size,
					rotation = el.coords.boss.rotation,
					onEnter = onEnter,
					onExit = onExit,
					data = { name = el.id }
				})
			}
		end
	end
end)

local function GetVehicleStateMenu(entity)
	if not entity then return end
	-- lib.registerMenu({
	-- 	id="vehicle_menu_information",
	-- 	title="Mechanic Menu",
	-- 	options={
	-- 		{label = "Health Menu",description="Check the health of the vehicle"}
	-- 	}
	-- })
	local engine,fuel,petrol,oil = GetVehicleEngineHealth()
	lib.registerContext({
		id = ("vehicle_menu_%s"):format(entity),
		title = 'Vehicle Menu',
		options = {
			{
				title = "Engine Health",
				progress = GetVehicleEngineHealth(entity) / 10,

			}
		}
	})
end


RegisterCommand("goUp", function(_, __)
	if not playerJob then playerJob = QBCore.Functions.GetPlayerData().job end
	if not playerJob.name == "mechanic" then return end
	lib.requestModel(Config.ItemsToUse.props.jack)
	lib.requestAnimDict("random@hitch_lift")
	local veh, closeDist = QBCore.Functions.GetClosestVehicle()
	local oil,petrol,fuel,body,wheels,windows in GetVehicleDamages(veh)
	SetBagValue(veh,"Damage",GetVehicleDamages(veh),true) -- let ensure that the damage is shared between everyone
	lib.registerContext({
		id=("vehicle_damage_menu_%s"):format(veh),
		title ="Vehicle Damage Menu",
		options = {
			{
				title = ("Oil Level: %s"):format(oil),
				progress = oil,
				colorScheme = (oil ) > 30 and "lime" or "orange"
			},
			{
				title ="Petrol Tank Health",
				progress = petrol / 10,
				colorScheme = (petrol / 10) > 30 and "lime" or "orange"
			},
			{
				title ="Fuel Level",
				progress = fuel,
				colorScheme = (fuel / 10) > 30 and "lime" or "orange"
			}
		}
	})

	lib.showContext(("vehicle_damage_menu_%s"):format(veh))
 local coords = GetEntityCoords(veh)
jackItem = CreateObject(joaat(Config.ItemsToUse.props.jack),coords.x,coords.y,coords.z - 0.95,false,true,false)
 QBCore.Functions.PlayAnim(Config.Anims.carJack.anim_dict, Config.Anims.carJack.anim_lib, false, -1)
 SetEntityCollision(jackItem, false, false)
	-- if lib.progressBar({
	-- 	duration = 3000,
	-- 	label = "Colocando Gato",
	-- 	useWhileDead = false,
	-- 	canCancel = true,
	-- 	disable = {
	-- 		car = true,
	-- 		move = true,
	-- 		mouse = true
	-- 	}
	-- }) then
	SetBagValue(veh, "jackUP", "up", true)
	-- else
	-- 	ClearPedTasks(cache.ped)
	-- end

 SetTimeout(20000,function()
 	SetBagValue(veh,"jackUP","down",true)
	 end)
end, false)

HandleStateBag("jackUP", function(entity, value)
	local count = 15
	if not entity or entity == 0 then return end
	local coords = GetEntityCoords(entity)
	print(value)
	if value == "up" then
		repeat
			Wait(1000)
			 count -= 1
			 DurationLerp(jackItem,100,"up")
			 DurationLerp(entity,100,"up")
			 FreezeEntityPosition(entity, true)
		until count == 0
		SetBagValue(entity,"isJacked",true,true)
	elseif value == "down" then
		repeat
			Wait(1000)
			DurationLerp(jackItem,100,"down")
			DurationLerp(entity,100,"down")
			  count -= 1
		until count == 0
		SetBagValue(entity,"isJacked",false,true)
		DeleteObject(jackItem)
		jackItem = nil
		FreezeEntityPosition(entity, false)
		ClearPedTasks(cache.ped)
	else
		print "no specific value "
		return
	end
end,false)

HandleStateBag("Damage",function(entity,value)
	if  table.type(value)  == 'empty' then return end
				local _values = value
				SetVehicleOilLevel(entity,_values.oil + 0.5)
				SetVehicleEngineHealth(entity,_values.engine + 0.5)
				SetVehiclePetrolTankHealth(entity,_values.petrol + 0.5)
				if Config.FuelResource then
					exports[Config.FuelResource.use]:SetFuel(entity,_values.fuel)
				end
				SetVehicleFuelLevel(entity,_values.fuel)


end)

-- AddStateBagChangeHandler("Damage", nil, function(bagNameEvent, _, value, _unused, _replicated)
-- 	local entity = GetEntityFromStateBagName(bagNameEvent)
-- 	if entity == 0 then return end
-- 	local network = NetToVeh(VehToNet(entity))
-- 	if  table.type(value)  == 'empty' then return end
-- 			local _values = value
-- 			SetVehicleOilLevel(network,_values.oil + 0.5)
-- 			SetVehicleEngineHealth(network,_values.engine + 0.5)
-- 			SetVehiclePetrolTankHealth(network,_values.petrol + 0.5)
-- 			if Config.FuelResource then
-- 				exports[Config.FuelResource.use]:SetFuel(network,_values.fuel)
-- 			end
-- 			SetVehicleFuelLevel(network,_values.fuel)
-- end)
function lerp(a, b, t)
  return a + (b - a) * t
end
