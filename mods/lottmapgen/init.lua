local modpath = core.get_modpath(core.get_current_modname())
local meta = dofile(modpath .. "/meta.lua")

dofile(minetest.get_modpath("lottmapgen").."/nodes.lua")
dofile(minetest.get_modpath("lottmapgen").."/functions.lua")

dofile(minetest.get_modpath("lottmapgen").."/worldedit.lua")
dofile(minetest.get_modpath("lottmapgen").."/schematics.lua")


-- =========================
-- LOAD DATA
-- =========================
local function load_compressed(path)
    local file = assert(io.open(path, "rb"))
    local compressed = file:read("*all")
    file:close()

    return core.decompress(compressed, "deflate")
end

local biome_data = load_compressed(modpath .. "/biomes.bin.zlib")
local height_data = load_compressed(modpath .. "/height.bin.zlib")
local mountain_data = load_compressed(modpath .. "/mmask.bin.zlib")
local water_data = load_compressed(modpath .. "/wmask.bin.zlib")

-- =========================
-- MAP SETTINGS
-- =========================
local MAP_WIDTH = meta.width
local MAP_HEIGHT = meta.height

local MAP_SCALE = 4 -- production scale: 16
local BIOME_WARP = MAP_SCALE

local WATER_LEVEL = 0
local SEA_LEVEL = 0.1

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
-- LOTR PLANTS
-- =========================
local c_mallos = core.get_content_id("lottplants:mallos")
local c_seregon = core.get_content_id("lottplants:seregon")
local c_bomordor = core.get_content_id("lottplants:brambles_of_mordor")
local c_pilinehtar = core.get_content_id("lottplants:pilinehtar")
local c_melon = core.get_content_id("lottplants:melon_wild")

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
-- UTILS
-- =========================
local function clamp(v, lo, hi)
    if v < lo then
        return lo
    end

    if v > hi then
        return hi
    end

    return v
end

local function smoothstep(a, b, x)
    local t = clamp(
        (x - a) / (b - a),
        0,
        1
    )

    return t * t * (3 - 2 * t)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function ridged(n)
    local r = 1 - math.abs(n)
    return r
end

-- =========================
-- SAMPLING
-- =========================
local function get_map_coords(wx, wz)
    local half_w = (MAP_WIDTH * MAP_SCALE) / 2
    local half_h = (MAP_HEIGHT * MAP_SCALE) / 2
    local ix = (half_w - wx) / MAP_SCALE
    local iz = (wz + half_h) / MAP_SCALE
    return ix, iz
end

local function sample_byte(data, px, pz, fallback)
    px = clamp(
        math.floor(px),
        0,
        MAP_WIDTH - 1
    )
    pz = clamp(
        math.floor(pz),
        0,
        MAP_HEIGHT - 1
    )

    local index =
        pz * MAP_WIDTH +
        px +
        1

    return (
        string.byte(
            data,
            index
        ) or fallback
    ) / 255
end

local function sample_bilinear(data, px, pz, fallback)
    px = clamp(
        px,
        0,
        MAP_WIDTH - 1
    )
    pz = clamp(
        pz,
        0,
        MAP_HEIGHT - 1
    )

    local x0 = math.floor(px)
    local z0 = math.floor(pz)

    local x1 = math.min(
        x0 + 1,
        MAP_WIDTH - 1
    )

    local z1 = math.min(
        z0 + 1,
        MAP_HEIGHT - 1
    )

    local tx = px - x0
    local tz = pz - z0

    local v00 =
        sample_byte(
            data,
            x0,
            z0,
            fallback
        )

    local v10 =
        sample_byte(
            data,
            x1,
            z0,
            fallback
        )

    local v01 =
        sample_byte(
            data,
            x0,
            z1,
            fallback
        )

    local v11 =
        sample_byte(
            data,
            x1,
            z1,
            fallback
        )

    local a =
        lerp(
            v00,
            v10,
            tx
        )

    local b =
        lerp(
            v01,
            v11,
            tx
        )

    return lerp(
        a,
        b,
        tz
    )
end

local function get_height(px, pz)
    return sample_bilinear(
        height_data,
        px,
        pz,
        0
    )
end

local function get_mask(px, pz)
    return sample_bilinear(
        mountain_data,
        px,
        pz,
        0
    )
end

local function get_water(px, pz)
    return sample_bilinear(
        water_data,
        px,
        pz,
        255
    )
end

-- =========================
-- NOISE
-- =========================
local ridge_noise
local detail_noise
local warp_x_noise
local warp_z_noise

-- BIOME HANDLING

local function get_biome_raw(px, pz)
    px = clamp(
        math.floor(px),
        0,
        MAP_WIDTH - 1
    )

    pz = clamp(
        math.floor(pz),
        0,
        MAP_HEIGHT - 1
    )

    local idx = pz * MAP_WIDTH + px
    local byte_idx = idx * 2 + 1

    local lo =
        string.byte(biome_data, byte_idx)
        or 0

    local hi =
        string.byte(biome_data, byte_idx + 1)
        or 0

    return lo + hi * 256
end

-- Current biome file is 16-bit little endian.
local BIOME_SMOOTH_RADIUS = 2
local BIOME_SMOOTH_SIGMA = 1.0

local function get_biome_id(wx, wz)
    -- small warp to stop borders looking mathematically perfect.
    local warp_x =
        warp_x_noise:get_2d({
            x = wx * 0.04,
            y = wz * 0.04
        }) * BIOME_WARP

    local warp_z =
        warp_z_noise:get_2d({
            x = wx * 0.04,
            y = wz * 0.04
        }) * BIOME_WARP

    local ix, iz =
        get_map_coords(
            wx + warp_x,
            wz + warp_z
        )

    ix = clamp(ix, 0, MAP_WIDTH - 1)
    iz = clamp(iz, 0, MAP_HEIGHT - 1)

    local cx = math.floor(ix)
    local cz = math.floor(iz)

    local weights = {}

    for dz = -BIOME_SMOOTH_RADIUS, BIOME_SMOOTH_RADIUS do
        for dx = -BIOME_SMOOTH_RADIUS, BIOME_SMOOTH_RADIUS do

            local sx = clamp(
                cx + dx,
                0,
                MAP_WIDTH - 1
            )

            local sz = clamp(
                cz + dz,
                0,
                MAP_HEIGHT - 1
            )

            local biome =
                get_biome_raw(sx, sz)

            -- dist from actual floating-point sample position.
            local dist_x =
                sx - ix

            local dist_z =
                sz - iz

            local dist2 =
                dist_x * dist_x +
                dist_z * dist_z

            -- Gaussian weighting.
            local weight =
                math.exp(
                    -dist2 /
                    (
                        2 *
                        BIOME_SMOOTH_SIGMA *
                        BIOME_SMOOTH_SIGMA
                    )
                )

            weights[biome] =
                (weights[biome] or 0) +
                weight
        end
    end

    local best_biome =
        get_biome_raw(cx, cz)

    local best_weight = -1

    for biome, weight in pairs(weights) do
        if weight > best_weight then
            best_weight = weight
            best_biome = biome
        end
    end

    return best_biome
end

-- =========================
-- TERRAIN HEIGHT
-- =========================
local function get_terrain_height(x, z)
    local ix, iz = get_map_coords(x, z)

    local px = ix
    local pz = iz

    local h = get_height(px, pz)

    -- SHIFT so SEA_LEVEL is treated as sea level.
    h =
        (h - SEA_LEVEL) /
        (1.0 - SEA_LEVEL)

    local mountain_mask =
        smoothstep(
            0.2,
            0.8,
            get_mask(px, pz)
        )

    local warp_amp = 25

    local sx =
        x +
        warp_x_noise:get_2d({
            x = x,
            y = z
        }) * warp_amp

    local sz =
        z +
        warp_z_noise:get_2d({
            x = x,
            y = z
        }) * warp_amp

    local r =
        ridged(
            ridge_noise:get_2d({
                x = sx,
                y = sz
            })
        )

    local detail =
        detail_noise:get_2d({
            x = sx,
            y = sz
        })

    local mountain_shape_noise =
        core.get_value_noise({
            offset = 0,
            scale = 1,

            spread = {
                x = 600,
                y = 600,
                z = 600
            },

            seed = 7007,
            octaves = 3,
            persist = 0.5,
            lacunarity = 2.0
        })

    local MOUNTAIN_HEIGHT_BOOST = 160 -- adjust mountain height boost here, default scale of 1 = 80
    local shape =
    mountain_shape_noise:get_2d({
        x = x,
        y = z
    })

    shape =
        clamp(
            (shape + 1) * 0.5,
            0,
            1
        )

    shape =
        smoothstep(
            0.2,
            0.8,
            shape
        )

    local mountain =
        r * MOUNTAIN_HEIGHT_BOOST * (0.35 + shape * 0.9) +
        detail * 18

    local terrain =
        h * 40 +
        mountain_mask * mountain

    -- =========================
    -- RIVER CARVING
    -- =========================
    local water_mask =
        get_water(px, pz)

    -- Black = river.
    local river_strength =
        1 - water_mask

    river_strength =
        smoothstep(
            0.2,
            0.8,
            river_strength
        )

    local river_level = -5

    if river_strength > 0.8 then
        terrain = river_level

    elseif river_strength > 0 then
        terrain =
            lerp(
                terrain,
                river_level,
                river_strength
            )
    end

    return math.floor(terrain)
end

-- =========================
-- SURFACE BY BIOME
-- =========================
local function get_surface_nodes(biome_id)

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
local function decorate_surface(
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

-- =========================
-- MAPGEN
-- =========================
core.register_on_generated(function(minp, maxp)

    -- =========================
    -- CREATE NOISE
    -- =========================
    if not warp_x_noise then

        ridge_noise =
            core.get_value_noise({
                offset = 0,
                scale = 1,

                spread = {
                    x = 280,
                    y = 160,
                    z = 280
                },

                seed = 3003,
                octaves = 5,
                persist = 0.55,
                lacunarity = 2.0
            })

        detail_noise =
            core.get_value_noise({
                offset = 0,
                scale = 1,

                spread = {
                    x = 40,
                    y = 40,
                    z = 40
                },

                seed = 4004,
                octaves = 4,
                persist = 0.5,
                lacunarity = 2.0
            })

        warp_x_noise =
            core.get_value_noise({
                offset = 0,
                scale = 1,

                spread = {
                    x = 200,
                    y = 200,
                    z = 200
                },

                seed = 5005,
                octaves = 3,
                persist = 0.5,
                lacunarity = 2.0
            })

        warp_z_noise =
            core.get_value_noise({
                offset = 0,
                scale = 1,

                spread = {
                    x = 200,
                    y = 200,
                    z = 200
                },

                seed = 6006,
                octaves = 3,
                persist = 0.5,
                lacunarity = 2.0
            })
    end

    -- =========================
    -- VOXELMANIP
    -- =========================
    local vm, emin, emax =
        core.get_mapgen_object(
            "voxelmanip"
        )

    local data =
        vm:get_data()

    local p2data =
        vm:get_param2_data()

    local area =
        VoxelArea:new({
            MinEdge = emin,
            MaxEdge = emax
        })

    -- =========================
    -- TERRAIN PASS
    -- =========================
    for z = minp.z, maxp.z do
        for x = minp.x, maxp.x do

            local biome_id =
                get_biome_id(x, z)

            local ground_y =
                get_terrain_height(x, z)

            local surface, filler =
                get_surface_nodes(
                    biome_id
                )

            for y = minp.y, maxp.y do

                local vi =
                    area:index(
                        x,
                        y,
                        z
                    )

                if y <= ground_y - 4 then

                    if biome_id == 113 then
                        data[vi] =
                            c_morstone
                    else
                        data[vi] =
                            c_stone
                    end

                elseif y <= ground_y - 1 then

                    data[vi] =
                        filler

                elseif y == ground_y
                and ground_y >= WATER_LEVEL then

                    data[vi] =
                        surface

                elseif y <= WATER_LEVEL then

                    data[vi] =
                        c_water

                -- else

                --     data[vi] =
                --         c_air
                end
            end
        end
    end

    -- =========================
    -- DECORATION PASS
    -- =========================
    --
    -- happen AFTER terrain.
    -- to prevent columns to erase parts
    -- of trees that extend horizontally.
    --
    for z = minp.z, maxp.z do
        for x = minp.x, maxp.x do
            local biome_id = get_biome_id(x, z)

            if biome_id >= 100 then
                local ground_y = get_terrain_height(x, z)

                if ground_y >= WATER_LEVEL
                and ground_y >= minp.y
                and ground_y <= maxp.y then
                    decorate_surface(
                        biome_id,
                        x,
                        ground_y,
                        z,
                        area,
                        data,
                        p2data
                    )
                end
            end
        end
    end

    -- =========================
    -- WRITE
    -- =========================
    vm:set_data(data)
    vm:set_param2_data(p2data)

    vm:set_lighting({day=0, night=0})
    vm:calc_lighting()
    vm:update_liquids()
    vm:write_to_map()
end)

-- TEMPORARY -- TO MOVE TO SOMEWHERE MORE SUITABLE LATER
minetest.register_on_joinplayer(function(player)
    -- hide clouds
    player:set_clouds({
        density = 0
    })

    -- shaders
    player:set_lighting({
        saturation = 1.0,

        shadows = {
            intensity = 0.4
        },

        volumetric_light = {
            strength = 0.2
        }
    })
end)