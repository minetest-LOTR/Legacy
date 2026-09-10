
-- get map from world
function lottmapgen.get_map_coords(wx, wz)
    local half_w = (lottmapgen.MAP_WIDTH * lottmapgen.MAP_SCALE) / 2
    local half_h = (lottmapgen.MAP_HEIGHT * lottmapgen.MAP_SCALE) / 2
    local ix = (half_w - wx) / lottmapgen.MAP_SCALE
    local iz = (wz + half_h) / lottmapgen.MAP_SCALE
    return ix, iz
end

-- get world from map
function lottmapgen.get_world_coords(ix, iz)
    local half_w = (lottmapgen.MAP_WIDTH * lottmapgen.MAP_SCALE) / 2
    local half_h = (lottmapgen.MAP_HEIGHT * lottmapgen.MAP_SCALE) / 2
    local wx = half_w - ix * lottmapgen.MAP_SCALE
    local wz = iz * lottmapgen.MAP_SCALE - half_h
    return wx, wz
end

function lottmapgen.sample_byte(data, px, pz, fallback)
    px = lottmapgen.clamp(
        math.floor(px),
        0,
        lottmapgen.MAP_WIDTH - 1
    )
    pz = lottmapgen.clamp(
        math.floor(pz),
        0,
        lottmapgen.MAP_HEIGHT - 1
    )

    local index =
        pz * lottmapgen.MAP_WIDTH +
        px +
        1

    return (
        string.byte(
            data,
            index
        ) or fallback
    ) / 255
end

function lottmapgen.sample_bilinear(data, px, pz, fallback)
    px = lottmapgen.clamp(
        px,
        0,
        lottmapgen.MAP_WIDTH - 1
    )
    pz = lottmapgen.clamp(
        pz,
        0,
        lottmapgen.MAP_HEIGHT - 1
    )

    local x0 = math.floor(px)
    local z0 = math.floor(pz)

    local x1 = math.min(
        x0 + 1,
        lottmapgen.MAP_WIDTH - 1
    )

    local z1 = math.min(
        z0 + 1,
        lottmapgen.MAP_HEIGHT - 1
    )

    local tx = px - x0
    local tz = pz - z0

    local v00 =
        lottmapgen.sample_byte(
            data,
            x0,
            z0,
            fallback
        )

    local v10 =
        lottmapgen.sample_byte(
            data,
            x1,
            z0,
            fallback
        )

    local v01 =
        lottmapgen.sample_byte(
            data,
            x0,
            z1,
            fallback
        )

    local v11 =
        lottmapgen.sample_byte(
            data,
            x1,
            z1,
            fallback
        )

    local a =
        lottmapgen.lerp(
            v00,
            v10,
            tx
        )

    local b =
        lottmapgen.lerp(
            v01,
            v11,
            tx
        )

    return lottmapgen.lerp(
        a,
        b,
        tz
    )
end