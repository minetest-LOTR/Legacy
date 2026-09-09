
function lottmapgen.load_compressed(path)
    local file = assert(io.open(path, "rb"))
    local compressed = file:read("*all")
    file:close()

    return core.decompress(compressed, "deflate")
end

-- =========================
-- UTILS
-- =========================
function lottmapgen.clamp(v, lo, hi)
    if v < lo then
        return lo
    end

    if v > hi then
        return hi
    end

    return v
end

function lottmapgen.smoothstep(a, b, x)
    local t = lottmapgen.clamp(
        (x - a) / (b - a),
        0,
        1
    )

    return t * t * (3 - 2 * t)
end

function lottmapgen.lerp(a, b, t)
    return a + (b - a) * t
end

function lottmapgen.ridged(n)
    return lottmapgen.clamp(
        1 - math.abs(n),
        0,
        1
    )
end