
-- retrieve biome data
local modpath = core.get_modpath(core.get_current_modname())
local biome_data = lottmapgen.load_compressed(modpath .. "/mapdata/biomes.bin.zlib")

-- raw biome data
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

-- warp biome borders to smoothen them
local function get_biome_map_coords(wx, wz)
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

	ix = lottmapgen.clamp(
		ix,
		0,
		lottmapgen.MAP_WIDTH - 1
	)

	iz = lottmapgen.clamp(
		iz,
		0,
		lottmapgen.MAP_HEIGHT - 1
	)

	return ix, iz
end

-- get raw biome at warped world position
function lottmapgen.get_raw_biome_id(wx, wz)
	local ix, iz =
		get_biome_map_coords(wx, wz)

	return lottmapgen.get_biome_raw(
		math.floor(ix),
		math.floor(iz)
	)
end

-- get biome with dithered borders
function lottmapgen.get_blended_biome_id(wx, wz)
	local ix, iz =
		get_biome_map_coords(wx, wz)

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

			local dist_x = sx - ix
			local dist_z = sz - iz

			local dist2 =
				dist_x * dist_x +
				dist_z * dist_z

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

	local biome_a = nil
	local biome_b = nil

	local weight_a = -1
	local weight_b = -1

	for biome, weight in pairs(weights) do
		if weight > weight_a then
			biome_b = biome_a
			weight_b = weight_a

			biome_a = biome
			weight_a = weight

		elseif weight > weight_b then
			biome_b = biome
			weight_b = weight
		end
	end

	if not biome_b then
		return biome_a
	end

	local total =
		weight_a +
		weight_b

	local blend =
		weight_b /
		total

	-- Optional: don't blend tiny contributions.
	if blend < 0.05 then
		return biome_a
	end

	-- Deterministic per-column dithering.
	local hash =
		(
			wx * 374761393 +
			wz * 668265263
		) % 2147483647

	local random =
		(hash % 10000) /
		10000

	if random < blend then
		return biome_b
	end

	return biome_a
end