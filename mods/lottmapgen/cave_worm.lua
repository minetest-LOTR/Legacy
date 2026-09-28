-- =========================
-- WORM CAVE GENERATION
-- =========================

local c_air = core.get_content_id("air")
local c_water = core.get_content_id("default:water_source")

local c_stone = core.get_content_id("default:stone")
local c_morstone = core.get_content_id("lottmapgen:mordor_stone")


-- =========================
-- WORM CAVE SETTINGS
-- =========================

-- enables detailed worm cave timing and counters
local WORM_CAVE_PROFILING = false

-- keeps normal tunnels below the terrain surface
local WORM_CAVE_UNDERGROUND = 5

-- used instead of the mapblock seed so cave paths remain persistent across chunks
local WORM_CAVE_BASE_SEED = 14320

-- each cell owns a deterministic set of worm cave paths
local WORM_CAVE_CELL_SIZE = 160
local WORM_CAVE_SYSTEMS_PER_CELL = 4

-- nearby cells are replayed so paths remain continuous across chunk boundaries
local WORM_CAVE_SEARCH_RADIUS = 3

-- thickness of exposed stone around cave mouths
local WORM_CAVE_ENTRANCE_STONE_RING = 5

-- depth of surface material converted around cave mouths
local WORM_CAVE_ENTRANCE_STONE_DEPTH = 6

-- softens the outer edge of cave mouth stone
local WORM_CAVE_ENTRANCE_STONE_BLEND = 0.85


-- =========================
-- WORM CAVE PATH SETTINGS
-- =========================

local WORM_CAVE_STEP_LENGTH = 3

local WORM_CAVE_MIN_STEPS = 180
local WORM_CAVE_MAX_STEPS = 360

-- prevents steep terrain changes from breaking tunnel continuity
local WORM_CAVE_MAX_DESCENT_PER_STEP = 6


-- =========================
-- WORM CAVE SIZE SETTINGS
-- =========================

local WORM_CAVE_SIZE_SCALE = 0.75
local WORM_CAVE_SIZE_FLUCTUATION = 0.22

local WORM_CAVE_MIN_RADIUS = 5
local WORM_CAVE_MAX_RADIUS = 13

local WORM_CAVE_DEFORMATION = 0.30

-- used for chunk proximity checks before expensive voxel carving
local WORM_CAVE_MAX_CARVE_RADIUS = WORM_CAVE_MAX_RADIUS * (1 + WORM_CAVE_DEFORMATION)

-- =========================
-- WORM CAVE SURFACE ENTRANCES
-- =========================

-- one in this many paths becomes a surface entrance
local WORM_CAVE_ENTRANCE_CHANCE = 2

local WORM_CAVE_ENTRANCE_DEPTH_MIN = 1
local WORM_CAVE_ENTRANCE_DEPTH_MAX = 3

-- first section forms the downward throat
local WORM_CAVE_ENTRANCE_THROAT_STEPS = 8
local WORM_CAVE_ENTRANCE_DESCENT = 2.5

-- keeps the entrance travelling underground before normal cave behaviour begins
local WORM_CAVE_ENTRANCE_TUNNEL_STEPS = 48

-- keeps the opening narrower than the main tunnel
local WORM_CAVE_ENTRANCE_RADIUS_SCALE = 0.75

-- avoids deliberately opening caves directly beside sea level
local WORM_CAVE_SURFACE_MIN_ABOVE_WATER = 3

-- extra horizontal river clearance around cave spheres
local WORM_CAVE_RIVER_EXTRA_MARGIN = 2

-- reports a point inside the throat for entrance decoration
-- keeping this away from step 1 prevents formations crowding the visible mouth
local WORM_CAVE_ENTRANCE_DECO_STEP = 5


-- =========================
-- WORM CAVE NOISES
-- =========================

local worm_cave_path_noise_1 = nil
local worm_cave_path_noise_2 = nil
local worm_cave_path_noise_3 = nil

local worm_cave_vertical_noise = nil
local worm_cave_width_noise = nil
local worm_cave_shape_noise = nil


-- noises are created lazily because mapgen noise objects may not be available at load time
local function ensure_worm_cave_noises()

	if worm_cave_path_noise_1 then
		return
	end

	worm_cave_path_noise_1 = core.get_value_noise({
		offset = 0,
		scale = 1,

		spread = {
			x = 220,
			y = 220,
			z = 220
		},

		seed = 14321,
		octaves = 3,
		persist = 0.5,
		lacunarity = 2.0
	})

	worm_cave_path_noise_2 = core.get_value_noise({
		offset = 0,
		scale = 1,

		spread = {
			x = 110,
			y = 110,
			z = 110
		},

		seed = 14325,
		octaves = 3,
		persist = 0.55,
		lacunarity = 2.1
	})

	worm_cave_path_noise_3 = core.get_value_noise({
		offset = 0,
		scale = 1,

		spread = {
			x = 380,
			y = 380,
			z = 380
		},

		seed = 14326,
		octaves = 2,
		persist = 0.45,
		lacunarity = 2.0
	})

	worm_cave_vertical_noise = core.get_value_noise({
		offset = 0,
		scale = 1,

		spread = {
			x = 180,
			y = 180,
			z = 180
		},

		seed = 14322,
		octaves = 3,
		persist = 0.5,
		lacunarity = 2.0
	})

	worm_cave_width_noise = core.get_value_noise({
		offset = 0,
		scale = 1,

		spread = {
			x = 110,
			y = 110,
			z = 110
		},

		seed = 14323,
		octaves = 2,
		persist = 0.5,
		lacunarity = 2.0
	})

	worm_cave_shape_noise = core.get_value_noise({
		offset = 0,
		scale = 1,

		spread = {
			x = 18,
			y = 18,
			z = 18
		},

		seed = 14324,
		octaves = 2,
		persist = 0.5,
		lacunarity = 2.0
	})
end


-- =========================
-- HELPERS
-- =========================

local function clamp(value, min_value, max_value)

	if value < min_value then
		return min_value
	end

	if value > max_value then
		return max_value
	end

	return value
end


local function profile_add(profile, key, value)

	if profile then
		profile[key] = profile[key] + value
	end
end


local function profile_start(profile)

	if profile then
		return core.get_us_time()
	end

	return nil
end


local function profile_finish(profile, key, start_time)

	if profile then
		profile[key] = profile[key] + core.get_us_time() - start_time
	end
end


local function get_worm_cave_seed(cell_x, cell_z)
	return WORM_CAVE_BASE_SEED + cell_x * 73856093 + cell_z * 19349663
end


local function get_worm_cave_position_hash(x, y, z)

	local hash = WORM_CAVE_BASE_SEED + x * 73856093 + y * 19349663 + z * 83492791
	hash = hash % 2147483647

	if hash < 0 then
		hash = hash + 2147483647
	end

	return hash
end


local function get_worm_cave_path_value(path_type, x, z)

	if path_type == 2 then
		return worm_cave_path_noise_2:get_2d({
			x = x,
			y = z
		})
	end

	if path_type == 3 then
		return worm_cave_path_noise_3:get_2d({
			x = x,
			y = z
		})
	end

	return worm_cave_path_noise_1:get_2d({
		x = x,
		y = z
	})
end


local function get_worm_cave_path_turn_strength(path_type)

	if path_type == 2 then
		return 0.085
	end

	if path_type == 3 then
		return 0.045
	end

	return 0.06
end


local function get_worm_cave_radius(
	x,
	z,
	step,
	size_phase,
	size_rate
)

	local width = worm_cave_width_noise:get_2d({
		x = x,
		y = z
	})

	local radius = (11 + width * 4) * WORM_CAVE_SIZE_SCALE
	radius = clamp(radius, 6, 11.25)

	local fluctuation = math.sin(size_phase + step * size_rate)
	local size_multiplier = 1 + fluctuation * WORM_CAVE_SIZE_FLUCTUATION

	radius = radius * size_multiplier

	return clamp(radius, WORM_CAVE_MIN_RADIUS, WORM_CAVE_MAX_RADIUS)
end


-- caches repeated terrain samples during the current mapgen call
local function get_cached_terrain_height(
	x,
	z,
	terrain_cache,
	profile
)

	x = math.floor(x)
	z = math.floor(z)

	local row = terrain_cache[x]

	if not row then
		row = {}
		terrain_cache[x] = row
	end

	local height = row[z]

	if height == nil then

		local start_time = profile_start(profile)

		height = lottmapgen.get_terrain_height(x, z)
		row[z] = height

		profile_finish(profile, "terrain_time", start_time)
		profile_add(profile, "terrain_samples", 1)
	end

	return height
end


-- caches repeated water samples during the current mapgen call
local function get_cached_water(
	x,
	z,
	water_cache,
	profile
)

	x = math.floor(x)
	z = math.floor(z)

	local row = water_cache[x]

	if not row then
		row = {}
		water_cache[x] = row
	end

	local water = row[z]

	if water == nil then

		local start_time = profile_start(profile)

		water = lottmapgen.get_water(x, z)
		row[z] = water

		profile_finish(profile, "water_time", start_time)
		profile_add(profile, "water_samples", 1)
	end

	return water
end


-- checks whether one river sample intersects the cave footprint
local function worm_cave_river_sample(
	x,
	z,
	water_cache,
	profile
)

	local water_mask = get_cached_water(
		x,
		z,
		water_cache,
		profile
	)

	local river_strength = 1 - water_mask

	river_strength = lottmapgen.smoothstep(
		0.2,
		0.8,
		river_strength
	)

	return river_strength > 0
end


-- checks whether the worm cave footprint overlaps river carving
local function worm_cave_near_river(
	x,
	z,
	radius,
	water_cache,
	profile
)

	local start_time = profile_start(profile)

	profile_add(profile, "river_checks", 1)

	local sample_radius = math.ceil(radius)
	local diagonal_radius = math.ceil(sample_radius * 0.707)

	local sample_x = math.floor(x)
	local sample_z = math.floor(z)

	if worm_cave_river_sample(
		sample_x,
		sample_z,
		water_cache,
		profile
	) then

		profile_finish(profile, "river_time", start_time)
		return true
	end

	if worm_cave_river_sample(
		sample_x + sample_radius,
		sample_z,
		water_cache,
		profile
	) then

		profile_finish(profile, "river_time", start_time)
		return true
	end

	if worm_cave_river_sample(
		sample_x - sample_radius,
		sample_z,
		water_cache,
		profile
	) then

		profile_finish(profile, "river_time", start_time)
		return true
	end

	if worm_cave_river_sample(
		sample_x,
		sample_z + sample_radius,
		water_cache,
		profile
	) then

		profile_finish(profile, "river_time", start_time)
		return true
	end

	if worm_cave_river_sample(
		sample_x,
		sample_z - sample_radius,
		water_cache,
		profile
	) then

		profile_finish(profile, "river_time", start_time)
		return true
	end

	if worm_cave_river_sample(
		sample_x + diagonal_radius,
		sample_z + diagonal_radius,
		water_cache,
		profile
	) then

		profile_finish(profile, "river_time", start_time)
		return true
	end

	if worm_cave_river_sample(
		sample_x + diagonal_radius,
		sample_z - diagonal_radius,
		water_cache,
		profile
	) then

		profile_finish(profile, "river_time", start_time)
		return true
	end

	if worm_cave_river_sample(
		sample_x - diagonal_radius,
		sample_z + diagonal_radius,
		water_cache,
		profile
	) then

		profile_finish(profile, "river_time", start_time)
		return true
	end

	if worm_cave_river_sample(
		sample_x - diagonal_radius,
		sample_z - diagonal_radius,
		water_cache,
		profile
	) then

		profile_finish(profile, "river_time", start_time)
		return true
	end

	profile_finish(profile, "river_time", start_time)

	return false
end


-- checks whether a path sphere can affect the current mapgen area
local function worm_cave_point_near_chunk(
	x,
	y,
	z,
	minp,
	maxp
)

	local margin = WORM_CAVE_MAX_CARVE_RADIUS + 2

	return x + margin >= minp.x
		and x - margin <= maxp.x
		and y + margin >= minp.y
		and y - margin <= maxp.y
		and z + margin >= minp.z
		and z - margin <= maxp.z
end


-- reports the interior of a surface entrance to later decoration handling
local function report_worm_cave_surface_opening(
	x,
	y,
	z,
	cave_data
)

	if not cave_data.surface_openings then
		cave_data.surface_openings = {}
	end

	cave_data.surface_openings[#cave_data.surface_openings + 1] = {
		x = x,
		y = y,
		z = z
	}
end


-- =========================
-- WORM CAVE SPHERE CARVING
-- =========================

-- normal cave spheres accumulate their union directly into the current mapgen area
-- each voxel keeps only the strongest sphere influence before shape noise is sampled
local function accumulate_worm_cave_sphere(
	cx,
	cy,
	cz,
	radius,
	minp,
	maxp,
	area,
	worm_carve,
	profile
)

	if radius <= 0 then
		return
	end

	local carve_start = profile_start(profile)

	profile_add(profile, "carve_calls", 1)

	local max_radius = radius * (1 + WORM_CAVE_DEFORMATION)
	local max_radius_sq = max_radius * max_radius
	local radius_sq = radius * radius

	if cx + max_radius < minp.x
	or cx - max_radius > maxp.x
	or cy + max_radius < minp.y
	or cy - max_radius > maxp.y
	or cz + max_radius < minp.z
	or cz - max_radius > maxp.z then
		profile_finish(profile, "carve_time", carve_start)
		return
	end

	local xmin = math.max(math.floor(cx - max_radius), minp.x)
	local xmax = math.min(math.ceil(cx + max_radius), maxp.x)
	local ymin = math.max(math.floor(cy - max_radius), minp.y)
	local ymax = math.min(math.ceil(cy + max_radius), maxp.y)
	local zmin = math.max(math.floor(cz - max_radius), minp.z)
	local zmax = math.min(math.ceil(cz + max_radius), maxp.z)

	local ystride = area.ystride

	for z = zmin, zmax do

		local dz = z - cz
		local dz_sq = dz * dz

		for x = xmin, xmax do

			local dx = x - cx
			local horizontal_sq = dx * dx + dz_sq

			if horizontal_sq <= max_radius_sq then

				local vertical_radius = math.sqrt(max_radius_sq - horizontal_sq)
				local column_ymin = math.max(math.ceil(cy - vertical_radius), ymin)
				local column_ymax = math.min(math.floor(cy + vertical_radius), ymax)

				local vi = area:index(x, column_ymin, z)

				for y = column_ymin, column_ymax do

					local dy = y - cy
					local distance_sq = horizontal_sq + dy * dy
					local influence = distance_sq / radius_sq

					profile_add(profile, "voxel_candidates", 1)

					local current_influence = worm_carve[vi]

					if current_influence == nil
					or influence < current_influence then
						worm_carve[vi] = influence
					end

					vi = vi + ystride
				end
			end
		end
	end

	profile_finish(profile, "carve_time", carve_start)
end


-- resolves the accumulated cave union once per unique candidate voxel
local function resolve_worm_cave_carving(
	area,
	data,
	cave_data,
	worm_carve,
	shape_cache,
	profile
)

	local carve_start = profile_start(profile)

	for vi, influence in pairs(worm_carve) do

		profile_add(profile, "unique_voxels", 1)

		local pos = area:position(vi)
		local deformation = shape_cache[vi]

		if deformation == nil then

			deformation = worm_cave_shape_noise:get_3d({
				x = pos.x,
				y = pos.y,
				z = pos.z
			})

			shape_cache[vi] = deformation
			profile_add(profile, "noise_3d_samples", 1)
		end

		local radius_multiplier = 1 + deformation * WORM_CAVE_DEFORMATION
		local radius_multiplier_sq = radius_multiplier * radius_multiplier

		if influence <= radius_multiplier_sq then

			local current = data[vi]

			if current == c_stone
			or current == c_morstone then

				data[vi] = c_air
				profile_add(profile, "nodes_carved", 1)

				lottmapgen.mark_cave_node(
					pos.x,
					pos.y,
					pos.z,
					vi,
					"worm",
					cave_data
				)
			end
		end
	end

	profile_finish(profile, "carve_time", carve_start)
end


-- surface openings keep their original immediate carving and stone ring handling
local function carve_worm_cave_surface_sphere(
	cx,
	cy,
	cz,
	radius,
	minp,
	maxp,
	area,
	data,
	cave_data,
	terrain_cache,
	shape_cache,
	profile
)

	if radius <= 0 then
		return
	end

	local carve_start = profile_start(profile)

	profile_add(profile, "carve_calls", 1)

	local stone_ring = WORM_CAVE_ENTRANCE_STONE_RING

	local max_radius = radius * (1 + WORM_CAVE_DEFORMATION) + stone_ring
	local max_radius_sq = max_radius * max_radius

	if cx + max_radius < minp.x
	or cx - max_radius > maxp.x
	or cy + max_radius < minp.y
	or cy - max_radius > maxp.y
	or cz + max_radius < minp.z
	or cz - max_radius > maxp.z then

		profile_finish(profile, "carve_time", carve_start)
		return
	end

	local xmin = math.max(math.floor(cx - max_radius), minp.x)
	local xmax = math.min(math.ceil(cx + max_radius), maxp.x)

	local ymin = math.max(math.floor(cy - max_radius), minp.y)
	local ymax = math.min(math.ceil(cy + max_radius), maxp.y)

	local zmin = math.max(math.floor(cz - max_radius), minp.z)
	local zmax = math.min(math.ceil(cz + max_radius), maxp.z)

	for z = zmin, zmax do
		for x = xmin, xmax do

			local dx = x - cx
			local dz = z - cz
			local horizontal_sq = dx * dx + dz * dz

			if horizontal_sq <= max_radius_sq then

				local surface_y = get_cached_terrain_height(
					x,
					z,
					terrain_cache,
					profile
				)

				local vertical_radius = math.sqrt(max_radius_sq - horizontal_sq)
				local column_ymin = math.max(math.ceil(cy - vertical_radius), ymin)
				local column_ymax = math.min(math.floor(cy + vertical_radius), ymax)

				local vi = area:index(x, column_ymin, z)

				for y = column_ymin, column_ymax do

					local dy = y - cy
					local distance_sq = horizontal_sq + dy * dy

					profile_add(profile, "voxel_candidates", 1)

					local deformation = shape_cache[vi]

					if deformation == nil then

						deformation = worm_cave_shape_noise:get_3d({
							x = x,
							y = y,
							z = z
						})

						shape_cache[vi] = deformation
						profile_add(profile, "noise_3d_samples", 1)
					end

					local local_radius = radius + deformation * radius * WORM_CAVE_DEFORMATION
					local local_radius_sq = local_radius * local_radius

					local current = data[vi]

					if distance_sq <= local_radius_sq then

						local carveable =
							current == c_stone
							or current == c_morstone

						if current ~= c_air
						and current ~= c_water then
							carveable = true
						end

						if carveable then

							data[vi] = c_air
							profile_add(profile, "nodes_carved", 1)

							lottmapgen.mark_cave_node(
								x,
								y,
								z,
								vi,
								"worm",
								cave_data
							)
						end

					else

						local stone_radius = local_radius + stone_ring

						if distance_sq <= stone_radius * stone_radius
						and current ~= c_air
						and current ~= c_water
						and y >= surface_y - WORM_CAVE_ENTRANCE_STONE_DEPTH
						and y <= surface_y + 1 then

							local distance = math.sqrt(distance_sq)
							local ring_width = stone_radius - local_radius
							local ring_position = 0

							if ring_width > 0 then
								ring_position = clamp(
									(distance - local_radius) / ring_width,
									0,
									1
								)
							end

							-- small solid core with a long dithered fade into surrounding terrain
							if ring_position <= 0.2 then

								data[vi] = c_stone

							else

								local blend = 1 - ((ring_position - 0.2) / 0.8)
								blend = clamp(blend, 0, 1)

								-- keeps scattered stone farther into the outer edge
								blend = math.sqrt(blend)

								local hash = get_worm_cave_position_hash(x, y, z)
								local dither = (hash % 1000) / 1000

								if dither < blend * WORM_CAVE_ENTRANCE_STONE_BLEND then
									data[vi] = c_stone
								end
							end
						end
					end

					vi = vi + area.ystride
				end
			end
		end
	end

	profile_finish(profile, "carve_time", carve_start)
end


-- =========================
-- WORM CAVE PATH DESCENT
-- =========================

-- fills large downward terrain corrections with overlapping spheres
local function move_worm_cave_down(
	x,
	y,
	z,
	target_y,
	radius,
	minp,
	maxp,
	area,
	data,
	cave_data,
	terrain_cache,
	worm_carve,
	profile
)

	while y - target_y > WORM_CAVE_MAX_DESCENT_PER_STEP do

		y = y - WORM_CAVE_MAX_DESCENT_PER_STEP

		if worm_cave_point_near_chunk(
			x,
			y,
			z,
			minp,
			maxp
		) then

			profile_add(profile, "near_spheres", 1)

			accumulate_worm_cave_sphere(
				x,
				y,
				z,
				radius,
				minp,
				maxp,
				area,
				worm_carve,
				profile
			)
		end
	end

	return target_y
end


-- =========================
-- WORM CAVE PATH GENERATION
-- =========================

-- cheaply previews the actual horizontal path before doing terrain and carving work
-- this keeps long winding caves while rejecting paths that never approach this chunk
local function worm_cave_path_can_reach_chunk(
	start_x,
	start_z,
	angle,
	steps,
	path_type,
	minp,
	maxp
)

	local x = start_x
	local z = start_z

	local margin = WORM_CAVE_MAX_CARVE_RADIUS + 2
	local turn_strength = get_worm_cave_path_turn_strength(path_type)

	local xmin = minp.x - margin
	local xmax = maxp.x + margin
	local zmin = minp.z - margin
	local zmax = maxp.z + margin

	for step = 1, steps do

		local path_value = get_worm_cave_path_value(path_type, x, z)
		angle = angle + path_value * turn_strength

		if x >= xmin
		and x <= xmax
		and z >= zmin
		and z <= zmax then
			return true
		end

		x = x + math.cos(angle) * WORM_CAVE_STEP_LENGTH
		z = z + math.sin(angle) * WORM_CAVE_STEP_LENGTH
	end

	return false
end

local function generate_worm_cave_path(
	start_x,
	start_y,
	start_z,
	angle,
	steps,
	path_type,
	size_phase,
	size_rate,
	surface_path,
	minp,
	maxp,
	area,
	data,
	cave_data,
	terrain_cache,
	water_cache,
	worm_carve,
	shape_cache,
	profile
)

	profile_add(profile, "paths", 1)

	local x = start_x
	local y = start_y
	local z = start_z

	local entrance_ground_y = get_cached_terrain_height(
		start_x,
		start_z,
		terrain_cache,
		profile
	)

	local turn_strength = get_worm_cave_path_turn_strength(path_type)

	for step = 1, steps do

		profile_add(profile, "steps", 1)

		local path_value = get_worm_cave_path_value(path_type, x, z)
		angle = angle + path_value * turn_strength

		local vertical = worm_cave_vertical_noise:get_2d({
			x = x + 5000,
			y = z - 5000
		})

		local vertical_step = vertical * 1.5

		local radius = get_worm_cave_radius(
			x,
			z,
			step,
			size_phase,
			size_rate
		)

		local maximum_radius = radius * (1 + WORM_CAVE_DEFORMATION)
		local river_radius = maximum_radius + WORM_CAVE_RIVER_EXTRA_MARGIN

		local surface_opening = false
		local carve_radius = radius

		if surface_path
		and step <= WORM_CAVE_ENTRANCE_THROAT_STEPS then

			if step == 1 then

				-- only one sphere intersects the surface to keep the opening circular
				y = entrance_ground_y - radius * 0.35

				surface_opening = true
				carve_radius = radius * WORM_CAVE_ENTRANCE_RADIUS_SCALE

			else

				-- force the first section downward to establish the entrance throat
				local target_y =
					entrance_ground_y
					- radius
					- (step - 1) * WORM_CAVE_ENTRANCE_DESCENT

				if y > target_y then
					y = target_y
				end
			end

		elseif surface_path
		and step <= WORM_CAVE_ENTRANCE_TUNNEL_STEPS then

			-- keep a guaranteed underground tunnel after the entrance throat
			local target_y =
				entrance_ground_y
				- radius
				- (WORM_CAVE_ENTRANCE_THROAT_STEPS - 1)
				* WORM_CAVE_ENTRANCE_DESCENT

			local near_river = worm_cave_near_river(
				x,
				z,
				river_radius,
				water_cache,
				profile
			)

			if near_river then

				local river_safe_y =
					-5
					- maximum_radius
					- WORM_CAVE_UNDERGROUND

				if y > river_safe_y then

					y = move_worm_cave_down(
						x,
						y,
						z,
						river_safe_y,
						radius,
						minp,
						maxp,
						area,
						data,
						cave_data,
						terrain_cache,
						worm_carve,
						profile
					)
				end

			elseif y > target_y then

				y = target_y
			end

		else

			local ground_y = get_cached_terrain_height(
				x,
				z,
				terrain_cache,
				profile
			)

			local safe_surface_y = ground_y

			local near_river = worm_cave_near_river(
				x,
				z,
				river_radius,
				water_cache,
				profile
			)

			if near_river then
				safe_surface_y = math.min(
					safe_surface_y,
					-5
				)
			end

			local maximum_y =
				safe_surface_y
				- maximum_radius
				- WORM_CAVE_UNDERGROUND

			if y > maximum_y then

				y = move_worm_cave_down(
					x,
					y,
					z,
					maximum_y,
					radius,
					minp,
					maxp,
					area,
					data,
					cave_data,
					terrain_cache,
					worm_carve,
					profile
				)
			end
		end

		local near_chunk = worm_cave_point_near_chunk(
			x,
			y,
			z,
			minp,
			maxp
		)

		-- report one point inside each surface throat for forced cave decoration
		if surface_path
		and step == WORM_CAVE_ENTRANCE_DECO_STEP
		and near_chunk then

			report_worm_cave_surface_opening(
				x,
				y,
				z,
				cave_data
			)
		end

		if near_chunk then

			profile_add(profile, "near_spheres", 1)

			if surface_opening then

				carve_worm_cave_surface_sphere(
					x,
					y,
					z,
					carve_radius,
					minp,
					maxp,
					area,
					data,
					cave_data,
					terrain_cache,
					shape_cache,
					profile
				)

			else

				accumulate_worm_cave_sphere(
					x,
					y,
					z,
					carve_radius,
					minp,
					maxp,
					area,
					worm_carve,
					profile
				)
			end
		end

		x = x + math.cos(angle) * WORM_CAVE_STEP_LENGTH
		z = z + math.sin(angle) * WORM_CAVE_STEP_LENGTH
		y = y + vertical_step
	end
end


-- =========================
-- WORM CAVE GENERATION
-- =========================

function lottmapgen.generate_worm_caves(
	minp,
	maxp,
	area,
	data,
	cave_data
)

	local total_start
	local profile

	if WORM_CAVE_PROFILING then

		total_start = core.get_us_time()

		profile = {
			paths = 0,
			skipped_paths = 0,
			steps = 0,

			near_spheres = 0,
			carve_calls = 0,

			voxel_candidates = 0,
			unique_voxels = 0,
			noise_3d_samples = 0,
			nodes_carved = 0,

			terrain_samples = 0,
			water_samples = 0,
			river_checks = 0,

			terrain_time = 0,
			water_time = 0,
			river_time = 0,
			carve_time = 0
		}
	end
	ensure_worm_cave_noises()

	-- caches only live for this mapgen call
	local terrain_cache = {}
	local water_cache = {}
	local worm_carve = {}
	local shape_cache = {}

	local min_cell_x = math.floor(minp.x / WORM_CAVE_CELL_SIZE)
	local max_cell_x = math.floor(maxp.x / WORM_CAVE_CELL_SIZE)

	local min_cell_z = math.floor(minp.z / WORM_CAVE_CELL_SIZE)
	local max_cell_z = math.floor(maxp.z / WORM_CAVE_CELL_SIZE)

	for cell_z = min_cell_z - WORM_CAVE_SEARCH_RADIUS, max_cell_z + WORM_CAVE_SEARCH_RADIUS do
		for cell_x = min_cell_x - WORM_CAVE_SEARCH_RADIUS, max_cell_x + WORM_CAVE_SEARCH_RADIUS do

			local worm_cave_seed = get_worm_cave_seed(cell_x, cell_z)
			local pr = PcgRandom(worm_cave_seed)

			local cell_min_x = cell_x * WORM_CAVE_CELL_SIZE
			local cell_min_z = cell_z * WORM_CAVE_CELL_SIZE

			for path_index = 1, WORM_CAVE_SYSTEMS_PER_CELL do

				local start_x = cell_min_x + pr:next(0, WORM_CAVE_CELL_SIZE - 1)
				local start_z = cell_min_z + pr:next(0, WORM_CAVE_CELL_SIZE - 1)

				local biome_id = lottmapgen.get_raw_biome_id(
					start_x,
					start_z
				)

				-- worm caves may travel beneath ocean biomes but never originate in them
				if biome_id ~= 1 then

					local ground_y = get_cached_terrain_height(
						start_x,
						start_z,
						terrain_cache,
						profile
					)

					local surface_path =
						pr:next(
							1,
							WORM_CAVE_ENTRANCE_CHANCE
						) == 1

					local start_y

					if surface_path
					and ground_y >= lottmapgen.WATER_LEVEL + WORM_CAVE_SURFACE_MIN_ABOVE_WATER then

						start_y =
							ground_y
							- pr:next(
								WORM_CAVE_ENTRANCE_DEPTH_MIN,
								WORM_CAVE_ENTRANCE_DEPTH_MAX
							)

					else

						surface_path = false

						start_y =
							ground_y
							- pr:next(
								30,
								500
							)
					end

					local angle = pr:next(0, 6283) / 1000

					local steps = pr:next(
						WORM_CAVE_MIN_STEPS,
						WORM_CAVE_MAX_STEPS
					)

					local path_type =
						((path_index - 1 + pr:next(0, 2)) % 3)
						+ 1

					local size_phase = pr:next(0, 6283) / 1000
					local size_rate = pr:next(120, 240) / 1000

					if worm_cave_path_can_reach_chunk(
						start_x,
						start_z,
						angle,
						steps,
						path_type,
						minp,
						maxp
					) then

						generate_worm_cave_path(
							start_x,
							start_y,
							start_z,
							angle,
							steps,
							path_type,
							size_phase,
							size_rate,
							surface_path,
							minp,
							maxp,
							area,
							data,
							cave_data,
							terrain_cache,
							water_cache,
							worm_carve,
							shape_cache,
							profile
						)

					else
						profile_add(profile, "skipped_paths", 1)
					end
				end
			end
		end
	end

	resolve_worm_cave_carving(
		area,
		data,
		cave_data,
		worm_carve,
		shape_cache,
		profile
	)

	if WORM_CAVE_PROFILING then
		local total_time = core.get_us_time() - total_start
		local other_time = total_time - profile.carve_time - profile.river_time
	
		core.log(
			"warning",
			string.format(
				"[lottmapgen] worm profile y=%d..%d | total=%.2f ms | carve=%.2f ms | river=%.2f ms | other=%.2f ms | paths=%d | skipped=%d | steps=%d | spheres=%d | voxels=%d | unique=%d | noise3d=%d | carved=%d | terrain=%d/%.2f ms | water=%d/%.2f ms",
				minp.y,
				maxp.y,
				total_time / 1000,
				profile.carve_time / 1000,
				profile.river_time / 1000,
				other_time / 1000,
				profile.paths,
				profile.skipped_paths,
				profile.steps,
				profile.near_spheres,
				profile.voxel_candidates,
				profile.unique_voxels,
				profile.noise_3d_samples,
				profile.nodes_carved,
				profile.terrain_samples,
				profile.terrain_time / 1000,
				profile.water_samples,
				profile.water_time / 1000
			)
		)
	end
end