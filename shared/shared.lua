Config, Shared = {}, {}

Config.Places = {
    bennys_taller = {
        id = "bennys_taller",
        name = "Bennys",
        canBuy = true,
        coords = {
            boss = {
                name = "boss_zone",
                coords = vec3(-207.05, -1341.21, 35.0),
                size = vec3(1.55, 2.25, 2.15),
                rotation = 0.0,
            },
            mechanic_zone = {
                name = "mechanic_zone",
                coords = vec3(-221.98, -1329.74, 31.0),
                size = vec3(10.0, 6.0, 2),
                rotation = 0.0,
            }
        },
        buylocation = vector3(-202.79, -1308.5, 31.29)
    }
}

Config.FuelResource = {
    use = "LegacyFuel" -- if you want to use the natives put this on false
}

Config.Anims = {
    carJack = {
        anim_dict = "anim@amb@business@weed@weed_inspecting_lo_med_hi@",
        anim_lib = "weed_crouch_checkingleaves_idle_02_inspector"
    },
}
Config.ItemsToUse = {
    props = {
        jack = "prop_carjack"
    },
}
Shared.Events = {
    turnEntity = "fx-mechanics::server::TurnEntityOnNetworked"
}
