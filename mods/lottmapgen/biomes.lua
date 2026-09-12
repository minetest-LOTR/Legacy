-- =========================
-- NODES
-- =========================
local c_air = core.get_content_id("air")
local c_stone = core.get_content_id("default:stone")
local c_dirt = core.get_content_id("default:dirt")
local c_grass = core.get_content_id("default:dirt_with_grass")
local c_water = core.get_content_id("default:water_source")
local c_sand = core.get_content_id("default:sand")
local c_snowblock = core.get_content_id("default:snowblock")
local c_dirtsnow = core.get_content_id("default:dirt_with_snow")
local c_dryshrub = core.get_content_id("default:dry_shrub")

-- =========================
-- LOTR PLANTS
-- =========================
local c_mallos = core.get_content_id("lottplants:mallos")
local c_seregon = core.get_content_id("lottplants:seregon")
local c_bomordor = core.get_content_id("lottplants:brambles_of_mordor")
local c_pilinehtar = core.get_content_id("lottplants:pilinehtar")
local c_melon = core.get_content_id("lottplants:melon_wild")

-- =========================
-- LOTR SURFACE NODES
-- =========================
local c_morstone = core.get_content_id("lottmapgen:mordor_stone")
local c_frozenstone = core.get_content_id("lottmapgen:frozen_stone")
local c_dungrass = core.get_content_id("lottmapgen:dunland_grass")
local c_gondorgrass = core.get_content_id("lottmapgen:gondor_grass")
local c_loriengrass = core.get_content_id("lottmapgen:lorien_grass")
local c_fangorngrass = core.get_content_id("lottmapgen:fangorn_grass")
local c_mirkwoodgrass = core.get_content_id("lottmapgen:mirkwood_grass")
local c_rohangrass = core.get_content_id("lottmapgen:rohan_grass")
local c_shiregrass = core.get_content_id("lottmapgen:shire_grass")
local c_ironhillgrass = core.get_content_id("lottmapgen:ironhill_grass")
local c_ithilgrass = core.get_content_id("lottmapgen:ithilien_grass")
local c_angsnowblock = core.get_content_id("lottmapgen:angsnowblock")

-- =========================
-- DECORATION RARITY
-- =========================
-- Trees
local TREE1 = 30
local TREE2 = 50
local TREE3 = 100
local TREE4 = 200
local TREE5 = 300
local TREE6 = 500
local TREE7 = 750
local TREE8 = 1000
local TREE9 = 2000
local TREE10 = 5000

-- Plants
local PLANT1 = 3
local PLANT2 = 5
local PLANT3 = 10
local PLANT4 = 20
local PLANT5 = 50
local PLANT6 = 100
local PLANT7 = 200
local PLANT8 = 500
local PLANT9 = 750
local PLANT10 = 1000
local PLANT11 = 2000
local PLANT12 = 5000
local PLANT13 = 10000
local PLANT14 = 35000
local PLANT15 = 500000

-- =========================
-- 1 - OCEAN
-- =========================
lottmapgen.biome.register({
    id = 1,
    name = "Ocean",

    top_node = "default:sand",
    filler_node = "default:sand"
})

-- =========================
-- 100 - MISTY MOUNTAINS
-- =========================
lottmapgen.biome.register({
    id = 100,
    name = "Misty Mountains",

    top_node = "lottmapgen:angsnowblock",
    filler_node = "lottmapgen:frozen_stone",

    decorate = function(x, y, z, area, data, p2data, vi)

        if math.random(PLANT3) == 2 then
            data[vi] = c_dryshrub
            p2data[vi] = 42

        elseif math.random(TREE10) == 2 then
            lottmapgen_beechtree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE7) == 3 then
            lottmapgen_pinetree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE8) == 4 then
            lottmapgen_firtree(
                x, y, z,
                area, data
            )

        elseif math.random(PLANT6) == 2 then
            data[vi] = c_seregon
            p2data[vi] = 40

		elseif math.random(PLANT14) == 13 then
			lottmapgen.enqueue_building(
				"Angmar Fort",
				{x = x, y = y, z = z}
			)
		end
    end
})

-- =========================
-- 101 - FORODWAITH
-- =========================
lottmapgen.biome.register({
    id = 101,
    name = "Forodwaith",

    top_node = "default:dirt_with_snow",
    filler_node = "default:dirt",

    decorate = function(x, y, z, area, data, p2data, vi)

        if math.random(TREE10) == 2 then
            lottmapgen_pinetree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE10) == 3 then
            lottmapgen_firtree(
                x, y, z,
                area, data
            )
        end
    end
})

-- =========================
-- 102 - ERIADOR
-- =========================
lottmapgen.biome.register({
    id = 102,
    name = "Eriador",

    top_node = "default:dirt_with_snow",
    filler_node = "default:dirt",

    decorate = function(x, y, z, area, data, p2data, vi)

        if math.random(PLANT3) == 2 then
            data[vi] = c_dryshrub
            p2data[vi] = 42

        elseif math.random(TREE10) == 2 then
            lottmapgen_beechtree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE4) == 3 then
            lottmapgen_pinetree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE3) == 4 then
            lottmapgen_firtree(
                x, y, z,
                area, data
            )
        end
    end
})

-- =========================
-- 103 - SHIRE
-- =========================
lottmapgen.biome.register({
    id = 103,
    name = "Shire",

    top_node = "lottmapgen:shire_grass",
    filler_node = "default:dirt",

    decorate = function(x, y, z, area, data, p2data, vi)

        if math.random(TREE7) == 2 then
            lottmapgen_defaulttree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE7) == 3 then
            lottmapgen_appletree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE7) == 4 then
            lottmapgen_plumtree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE7) == 9 then
            lottmapgen_oaktree(
                x, y, z,
                area, data
            )

        elseif math.random(PLANT7) == 7 then
            lottmapgen_farmingplants(
                data,
                vi,
                p2data
            )

        elseif math.random(PLANT9) == 8 then
            data[vi] = c_melon

		elseif math.random(PLANT14) == 13 then
            lottmapgen.enqueue_building(
                "Hobbit Hole",
                {x = x, y = y, z = z}
            )
        end
    end
})

-- =========================
-- 104 - MIRKWOOD
-- =========================
lottmapgen.biome.register({
    id = 104,
    name = "Mirkwood",

    top_node = "lottmapgen:mirkwood_grass",
    filler_node = "default:dirt",

    decorate = function(x, y, z, area, data, p2data, vi)

        if math.random(TREE2) == 2 then
            lottmapgen_mirktree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE2) == 3 then
            lottmapgen_jungletree2(
                x, y, z,
                area, data
            )

		elseif math.random(PLANT14) == 13 then
            lottmapgen.enqueue_building(
                "Mirkwood House",
                {x = x, y = y, z = z}
            )
        end
    end
})

-- =========================
-- 105 - FANGORN
-- =========================
lottmapgen.biome.register({
    id = 105,
    name = "Fangorn",

    top_node = "lottmapgen:fangorn_grass",
    filler_node = "default:dirt",

    decorate = function(x, y, z, area, data, p2data, vi)

        if math.random(TREE3) == 2 then
            lottmapgen_defaulttree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE4) == 6 then
            lottmapgen_rowantree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE4) == 3 then
            lottmapgen_appletree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE5) == 10 then
            lottmapgen_birchtree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE5) == 4 then
            lottmapgen_plumtree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE7) == 9 then
            lottmapgen_elmtree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE6) == 11 then
            lottmapgen_oaktree(
                x, y, z,
                area, data
            )

        elseif math.random(PLANT4) == 7 then
            lottmapgen_farmingplants(
                data,
                vi,
                p2data
            )

        elseif math.random(PLANT9) == 8 then
            data[vi] = c_melon
        end
    end
})

-- =========================
-- 106 - LORIEN
-- =========================
lottmapgen.biome.register({
    id = 106,
    name = "Lorien",

    top_node = "lottmapgen:lorien_grass",
    filler_node = "default:dirt",

    decorate = function(x, y, z, area, data, p2data, vi)

        if math.random(TREE3) == 2 then
            lottmapgen_mallornsmalltree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE2) == 2 then
            lottmapgen_young_mallorn(
                x, y, z,
                area, data
            )

        elseif math.random(PLANT1) == 2 then
            lottmapgen_lorien_grass(
                data,
                vi,
                p2data
            )

        elseif math.random(TREE5) == 3 then
            lottmapgen_mallorntree(
                x, y, z,
                area, data
            )

        elseif math.random(PLANT4) == 11 then
            lottmapgen_lorienplants(
                data,
                vi,
                p2data
            )

		elseif math.random(PLANT13) == 13 then
            if math.random(1, 2) == 1 then
                lottmapgen.enqueue_building(
                    "Mallorn House",
                    {x = x, y = y, z = z}
                )
            else
                lottmapgen.enqueue_building(
                    "Lorien House",
                    {x = x, y = y, z = z}
                )
            end
        end
    end
})

-- =========================
-- 107 - IRON HILLS
-- =========================
lottmapgen.biome.register({
    id = 107,
    name = "Iron Hills",

    top_node = "lottmapgen:ironhill_grass",
    filler_node = "default:dirt",

    decorate = function(x, y, z, area, data, p2data, vi)

        if math.random(TREE10) == 2 then
            lottmapgen_beechtree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE4) == 3 then
            lottmapgen_pinetree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE6) == 4 then
            lottmapgen_firtree(
                x, y, z,
                area, data
            )
        end
    end
})

-- =========================
-- 108 - WILDERLAND
-- =========================
lottmapgen.biome.register({
    id = 108,
    name = "Wilderland",

    top_node = "default:dirt_with_grass",
    filler_node = "default:dirt",

    decorate = function(x, y, z, area, data, p2data, vi)

        if math.random(TREE5) == 2 then
            lottmapgen_defaulttree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE6) == 3 then
            lottmapgen_pinetree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE7) == 4 then
            lottmapgen_rowantree(
                x, y, z,
                area, data
            )

        elseif math.random(PLANT4) == 7 then
            lottmapgen_grass(
                data,
                vi,
                p2data
            )
        end
    end
})

-- =========================
-- 109 - DUNLAND
-- =========================
lottmapgen.biome.register({
    id = 109,
    name = "Dunland",

    top_node = "lottmapgen:dunland_grass",
    filler_node = "default:dirt",

    decorate = function(x, y, z, area, data, p2data, vi)

        if math.random(TREE5) == 2 then
            lottmapgen_defaulttree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE7) == 3 then
            lottmapgen_appletree(
                x, y, z,
                area, data
            )

        elseif math.random(PLANT3) == 4 then
            lottmapgen_grass(
                data,
                vi,
                p2data
            )
        end
    end
})

-- =========================
-- 110 - ROHAN
-- =========================
lottmapgen.biome.register({
    id = 110,
    name = "Rohan",

    top_node = "lottmapgen:rohan_grass",
    filler_node = "default:dirt",

    decorate = function(x, y, z, area, data, p2data, vi)

        if math.random(TREE7) == 2 then
            lottmapgen_defaulttree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE7) == 3 then
            lottmapgen_appletree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE8) == 4 then
            lottmapgen_plumtree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE10) == 9 then
            lottmapgen_elmtree(
                x, y, z,
                area, data
            )

        elseif math.random(PLANT2) == 5 then
            lottmapgen_grass(
                data,
                vi,
                p2data
            )

        elseif math.random(PLANT8) == 6 then
            lottmapgen_farmingplants(
                data,
                vi,
                p2data
            )

        elseif math.random(PLANT13) == 7 then
            data[vi] = c_melon

        elseif math.random(PLANT6) == 2 then
            data[vi] = c_pilinehtar
            p2data[vi] = 2

		elseif math.random(PLANT14) == 13 then
            lottmapgen.enqueue_building(
                "Rohan Fort",
                {x = x, y = y, z = z}
            )
        end
    end
})

-- =========================
-- 111 - GONDOR
-- =========================
lottmapgen.biome.register({
    id = 111,
    name = "Gondor",

    top_node = "lottmapgen:gondor_grass",
    filler_node = "default:dirt",

    decorate = function(x, y, z, area, data, p2data, vi)

        if math.random(TREE7) == 2 then
            lottmapgen_defaulttree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE8) == 6 then
            lottmapgen_aldertree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE9) == 3 then
            lottmapgen_appletree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE8) == 4 then
            lottmapgen_plumtree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE10) == 9 then
            lottmapgen_elmtree(
                x, y, z,
                area, data
            )

        elseif math.random(PLANT13) == 10 then
            lottmapgen_whitetree(
                x, y, z,
                area, data
            )

        elseif math.random(PLANT3) == 5 then
            lottmapgen_grass(
                data,
                vi,
                p2data
            )

        elseif math.random(PLANT8) == 7 then
            lottmapgen_farmingplants(
                data,
                vi,
                p2data
            )

        elseif math.random(PLANT13) == 8 then
            lottmapgen_farmingrareplants(
                data,
                vi,
                p2data
            )

        elseif math.random(PLANT6) == 2 then
            data[vi] = c_mallos
            p2data[vi] = 42

		elseif math.random(PLANT14) == 13 then
            lottmapgen.enqueue_building(
                "Gondor Fort",
                {x = x, y = y, z = z}
            )
        end
    end
})

-- =========================
-- 112 - ITHILIEN
-- =========================
lottmapgen.biome.register({
    id = 112,
    name = "Ithilien",

    top_node = "lottmapgen:ithilien_grass",
    filler_node = "default:dirt",

    decorate = function(x, y, z, area, data, p2data, vi)

        if math.random(TREE3) == 2 then
            lottmapgen_defaulttree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE6) == 6 then
            lottmapgen_lebethrontree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE3) == 3 then
            lottmapgen_appletree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE5) == 10 then
            lottmapgen_culumaldatree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE5) == 4 then
            lottmapgen_plumtree(
                x, y, z,
                area, data
            )

        elseif math.random(TREE9) == 9 then
            lottmapgen_elmtree(
                x, y, z,
                area, data
            )

        elseif math.random(PLANT8) == 7 then
            lottmapgen_farmingplants(
                data,
                vi,
                p2data
            )

        elseif math.random(PLANT13) == 8 then
            data[vi] = c_melon

        elseif math.random(PLANT5) == 11 then
            lottmapgen_ithildinplants(
                data,
                vi,
                p2data
            )
        end
    end
})

-- =========================
-- 113 - MORDOR
-- =========================
lottmapgen.biome.register({
    id = 113,
    name = "Mordor",

    top_node = "lottmapgen:mordor_stone",
    filler_node = "lottmapgen:mordor_stone",

    decorate = function(x, y, z, area, data, p2data, vi)

        if math.random(TREE10) == 2 then
            lottmapgen_burnedtree(
                x, y, z,
                area, data
            )

        elseif math.random(PLANT4) == 2 then
            data[vi] = c_bomordor
            p2data[vi] = 42

		elseif math.random(PLANT14) == 13 then
            lottmapgen.enqueue_building(
                "Orc Fort",
                {x = x, y = y, z = z}
            )
        end
    end
})