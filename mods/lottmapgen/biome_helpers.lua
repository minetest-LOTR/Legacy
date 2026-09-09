
-- retrieve biome data
local modpath = core.get_modpath(core.get_current_modname())
local biome_data = lottmapgen.load_compressed(modpath .. "/mapdata/biomes.bin.zlib")

-- raw bioem data
function lottmapgen.get_biome_raw(px, pz)
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

    local idx = pz * lottmapgen.MAP_WIDTH + px
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

-- smoothen biome borders
function lottmapgen.get_biome_id(wx, wz)
    -- small warp to stop borders looking mathematically perfect.
    local warp_x =
        lottmapgen.warp_x_noise:get_2d({
            x = wx * 0.04,
            y = wz * 0.04
        }) * lottmapgen.BIOME_WARP

    local warp_z =
        lottmapgen.warp_z_noise:get_2d({
            x = wx * 0.04,
            y = wz * 0.04
        }) * lottmapgen.BIOME_WARP

    local ix, iz =
        lottmapgen.get_map_coords(
            wx + warp_x,
            wz + warp_z
        )

    ix = lottmapgen.clamp(ix, 0, lottmapgen.MAP_WIDTH - 1)
    iz = lottmapgen.clamp(iz, 0, lottmapgen.MAP_HEIGHT - 1)

    local cx = math.floor(ix)
    local cz = math.floor(iz)

    local weights = {}

    for dz = -BIOME_SMOOTH_RADIUS, BIOME_SMOOTH_RADIUS do
        for dx = -BIOME_SMOOTH_RADIUS, BIOME_SMOOTH_RADIUS do

            local sx = lottmapgen.clamp(
                cx + dx,
                0,
                lottmapgen.MAP_WIDTH - 1
            )

            local sz = lottmapgen.clamp(
                cz + dz,
                0,
                lottmapgen.MAP_HEIGHT - 1
            )

            local biome =
                lottmapgen.get_biome_raw(sx, sz)

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
        lottmapgen.get_biome_raw(cx, cz)

    local best_weight = -1

    for biome, weight in pairs(weights) do
        if weight > best_weight then
            best_weight = weight
            best_biome = biome
        end
    end

    return best_biome
end
