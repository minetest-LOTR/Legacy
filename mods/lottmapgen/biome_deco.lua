
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
-- SURFACE BY BIOME
-- =========================
function lottmapgen.get_surface_nodes(biome_id)

    -- 1 - Ocean
    if biome_id == 1 then
        return c_sand, c_sand

    -- 100 - Misty Mountains
    elseif biome_id == 100 then
        return c_angsnowblock, c_frozenstone

    -- 101 - Forodwaith
    elseif biome_id == 101 then
        return c_dirtsnow, c_dirt

    -- 102 - Eriador
    elseif biome_id == 102 then
        return c_dirtsnow, c_dirt

    -- 103 - Shire
    elseif biome_id == 103 then
        return c_shiregrass, c_dirt

    -- 104 - Mirkwood
    elseif biome_id == 104 then
        return c_mirkwoodgrass, c_dirt

    -- 105 - Fangorn
    elseif biome_id == 105 then
        return c_fangorngrass, c_dirt

    -- 106 - Lorien
    elseif biome_id == 106 then
        return c_loriengrass, c_dirt

    -- 107 - Iron Hills
    elseif biome_id == 107 then
        return c_ironhillgrass, c_dirt

    -- 108 - Wilderland
    elseif biome_id == 108 then
        return c_grass, c_dirt

    -- 109 - Dunland
    elseif biome_id == 109 then
        return c_dungrass, c_dirt

    -- 110 - Rohan
    elseif biome_id == 110 then
        return c_rohangrass, c_dirt

    -- 111 - Gondor
    elseif biome_id == 111 then
        return c_gondorgrass, c_dirt

    -- 112 - Ithilien
    elseif biome_id == 112 then
        return c_ithilgrass, c_dirt

    -- 113 - Mordor
    elseif biome_id == 113 then
        return c_morstone, c_morstone
    end

    return c_grass, c_dirt
end

-- =========================
-- BIOME DECORATION
-- =========================
function lottmapgen.decorate_surface(
    biome_id,
    x,
    ground_y,
    z,
    area,
    data,
    p2data
)
    local y = ground_y + 1

    -- Must be inside the voxelmanip.
    if y < area.MinEdge.y
    or y > area.MaxEdge.y then
        return
    end

    -- Give tree generators a little safety room
    -- around horizontal chunk boundaries.
    if x <= area.MinEdge.x + 2
    or x >= area.MaxEdge.x - 2
    or z <= area.MinEdge.z + 2
    or z >= area.MaxEdge.z - 2 then
        return
    end

    local vi =
        area:index(x, y, z)

    if data[vi] ~= c_air then
        return
    end

    -- =========================
    -- 100 - MISTY MOUNTAINS
    -- =========================
    if biome_id == 100 then

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
        end

    -- =========================
    -- 101 - FORODWAITH
    -- =========================
    elseif biome_id == 101 then

        -- Sparse vegetation.
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

    -- =========================
    -- 102 - ERIADOR
    -- =========================
    elseif biome_id == 102 then

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

    -- =========================
    -- 103 - SHIRE
    -- =========================
    elseif biome_id == 103 then

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
        end

    -- =========================
    -- 104 - MIRKWOOD
    -- =========================
    elseif biome_id == 104 then

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
        end

    -- =========================
    -- 105 - FANGORN
    -- =========================
    elseif biome_id == 105 then

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

    -- =========================
    -- 106 - LORIEN
    -- =========================
    elseif biome_id == 106 then

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
        end

    -- =========================
    -- 107 - IRON HILLS
    -- =========================
    elseif biome_id == 107 then

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

    -- =========================
    -- 108 - WILDERLAND
    -- =========================
    elseif biome_id == 108 then

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

    -- =========================
    -- 109 - DUNLAND
    -- =========================
    elseif biome_id == 109 then

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

    -- =========================
    -- 110 - ROHAN
    -- =========================
    elseif biome_id == 110 then

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
        end

    -- =========================
    -- 111 - GONDOR
    -- =========================
    elseif biome_id == 111 then

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
        end

    -- =========================
    -- 112 - ITHILIEN
    -- =========================
    elseif biome_id == 112 then

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

    -- =========================
    -- 113 - MORDOR
    -- =========================
    elseif biome_id == 113 then

        if math.random(TREE10) == 2 then
            lottmapgen_burnedtree(
                x, y, z,
                area, data
            )

        elseif math.random(PLANT4) == 2 then
            data[vi] = c_bomordor
            p2data[vi] = 42
        end
    end
end