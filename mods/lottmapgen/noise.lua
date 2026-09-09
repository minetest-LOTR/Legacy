lottmapgen.ridge_noise = nil
lottmapgen.detail_noise = nil
lottmapgen.warp_x_noise = nil
lottmapgen.warp_z_noise = nil

lottmapgen.mountain_shape_noise = nil
lottmapgen.mountain_breakup_noise = nil
lottmapgen.secondary_ridge_noise = nil

local modpath = core.get_modpath(core.get_current_modname())

-- =========================
-- TERRAIN HEIGHT
-- =========================
function lottmapgen.get_terrain_height(x, z)
    local ix, iz = lottmapgen.get_map_coords(x, z)

    local px = ix
    local pz = iz

    local h = lottmapgen.get_height(px, pz)

    -- SHIFT so SEA_LEVEL is treated as sea level.
    h =
        (h - lottmapgen.SEA_LEVEL) /
        (1.0 - lottmapgen.SEA_LEVEL)

    local mountain_mask =
        lottmapgen.smoothstep(
            0.2,
            0.8,
            lottmapgen.get_mask(px, pz)
        )

    -- =========================
    -- DOMAIN WARP
    -- =========================

    local warp_amp = 45

    local wx =
        lottmapgen.warp_x_noise:get_2d({
            x = x,
            y = z
        })

    local wz =
        lottmapgen.warp_z_noise:get_2d({
            x = x,
            y = z
        })

    local sx = x + wx * warp_amp
    local sz = z + wz * warp_amp

    -- =========================
    -- PRIMARY RIDGES
    -- =========================

    local r =
        lottmapgen.ridged(
            lottmapgen.ridge_noise:get_2d({
                x = sx,
                y = sz
            })
        )

    -- Sharpen large ridges slightly.
    r = r ^ 1.2

    -- =========================
    -- MOUNTAIN MACRO SHAPE
    -- =========================

    local shape =
        lottmapgen.mountain_shape_noise:get_2d({
            x = x,
            y = z
        })

    shape =
        lottmapgen.clamp(
            (shape + 1) * 0.5,
            0,
            1
        )

    shape =
        lottmapgen.smoothstep(
            0.15,
            0.85,
            shape
        )

    -- =========================
    -- RIDGE BREAKUP
    -- =========================

    local breakup =
        lottmapgen.mountain_breakup_noise:get_2d({
            x = x,
            y = z
        })

    breakup =
        lottmapgen.clamp(
            (breakup + 1) * 0.5,
            0,
            1
        )

    breakup =
        lottmapgen.smoothstep(
            0.25,
            0.75,
            breakup
        )

    -- Never completely remove the mountains.
    local ridge_strength =
        0.35 + breakup * 0.65

    -- =========================
    -- SECONDARY RIDGES
    -- =========================

    local secondary =
        lottmapgen.ridged(
            lottmapgen.secondary_ridge_noise:get_2d({
                x = sx,
                y = sz
            })
        )

    secondary = secondary ^ 2.2

    -- Secondary ridges only become important
    -- around established mountain terrain.
    secondary =
        secondary *
        r *
        32

    -- =========================
    -- LOCAL DETAIL
    -- =========================

    local detail =
        lottmapgen.detail_noise:get_2d({
            x = sx,
            y = sz
        })

    -- Detail should increase with mountainousness
    -- instead of affecting everything equally.
    local detail_strength =
        mountain_mask *
        (0.2 + r * 0.8)

    local detail_height =
        detail *
        10 *
        detail_strength

    -- =========================
    -- FINAL MOUNTAIN
    -- =========================

    local MOUNTAIN_BASE_HEIGHT = 45
    local MOUNTAIN_HEIGHT_BOOST = 115

    local mountain_base =
        MOUNTAIN_BASE_HEIGHT *
        (0.4 + shape * 0.6)

    local mountain_peak =
        r *
        MOUNTAIN_HEIGHT_BOOST *
        (0.4 + shape * 0.8) *
        ridge_strength

    local mountain =
        mountain_base +
        mountain_peak

    mountain =
        mountain +
        secondary +
        detail_height

    local terrain =
        h * 40 +
        mountain_mask * mountain

    -- =========================
    -- RIVER CARVING
    -- =========================

    local water_mask = lottmapgen.get_water(px, pz)
    local river_strength = 1 - water_mask

    river_strength =
        lottmapgen.smoothstep(
            0.2,
            0.8,
            river_strength
        )

    local river_level = -5

    if river_strength > 0.8 then
        terrain = river_level

    elseif river_strength > 0 then
        terrain =
            lottmapgen.lerp(
                terrain,
                river_level,
                river_strength
            )
    end

    return math.floor(terrain)
end