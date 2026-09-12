
local c_dirt = core.get_content_id("default:dirt")
local c_grass = core.get_content_id("default:dirt_with_grass")
local c_air = core.get_content_id("air")

-- =========================
-- SURFACE BY BIOME
-- =========================
function lottmapgen.get_surface_nodes(biome_id)
    local biome = lottmapgen.biome.get(biome_id)

    if not biome then
        return c_grass, c_dirt
    end

    return biome.c_top, biome.c_filler
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

    if y < area.MinEdge.y
    or y > area.MaxEdge.y then
        return
    end

    local vi = area:index(x, y, z)

    if data[vi] ~= c_air then
        return
    end

    local biome = lottmapgen.biome.get(biome_id)

    if biome and biome.decorate then
        biome.decorate(
            x, y, z,
            area, data, p2data, vi
        )
    end
end