-- =========================
-- CAVE GENERATION
-- =========================

local c_air = core.get_content_id("air")
local c_water = core.get_content_id("default:water_source")

local c_stone = core.get_content_id("default:stone")
local c_morstone = core.get_content_id("lottmapgen:mordor_stone")

local c_mithril_lamp = core.get_content_id("lottblocks:mithril_stonelamp")


-- =========================
-- SETTINGS
-- =========================

-- keeps normal tunnels below the terrain surface
local CAVE_UNDERGROUND = 5

-- used instead of the mapblock seed so cave paths remain persistent across chunks
local CAVE_BASE_SEED = 14320

-- each cell owns a deterministic set of cave paths
local CAVE_CELL_SIZE = 160
local CAVE_SYSTEMS_PER_CELL = 4

-- nearby cells are replayed so paths remain continuous across chunk boundaries
local CAVE_SEARCH_RADIUS = 3

-- thickness of exposed stone around cave mouths
local CAVE_ENTRANCE_STONE_RING = 5

-- depth of surface material converted around cave mouths
local CAVE_ENTRANCE_STONE_DEPTH = 6

-- softens the outer edge of cave mouth stone
local CAVE_ENTRANCE_STONE_BLEND = 0.85


-- =========================
-- PATH SETTINGS
-- =========================

local CAVE_STEP_LENGTH = 3

local CAVE_MIN_STEPS = 70
local CAVE_MAX_STEPS = 120

-- prevents steep terrain changes from breaking tunnel continuity
local CAVE_MAX_DESCENT_PER_STEP = 6


-- =========================
-- SIZE SETTINGS
-- =========================

local CAVE_SIZE_SCALE = 0.75
local CAVE_SIZE_FLUCTUATION = 0.22

local CAVE_MIN_RADIUS = 5
local CAVE_MAX_RADIUS = 13

local CAVE_DEFORMATION = 0.30

-- used for chunk proximity checks before expensive voxel carving
local CAVE_MAX_CARVE_RADIUS = CAVE_MAX_RADIUS * (1 + CAVE_DEFORMATION)


-- =========================
-- SURFACE ENTRANCES
-- =========================

-- one in this many paths becomes a surface entrance
local CAVE_ENTRANCE_CHANCE = 2

local CAVE_ENTRANCE_DEPTH_MIN = 1
local CAVE_ENTRANCE_DEPTH_MAX = 3

-- first section forms the downward throat
local CAVE_ENTRANCE_THROAT_STEPS = 8
local CAVE_ENTRANCE_DESCENT = 2.5

-- keeps the entrance travelling underground before normal cave behaviour begins
local CAVE_ENTRANCE_TUNNEL_STEPS = 48

-- keeps the opening narrower than the main tunnel
local CAVE_ENTRANCE_RADIUS_SCALE = 0.75

-- avoids deliberately opening caves directly beside sea level
local CAVE_SURFACE_MIN_ABOVE_WATER = 3

-- extra horizontal river clearance around cave spheres
local CAVE_RIVER_EXTRA_MARGIN = 2


-- =========================
-- CAVE LIGHTING
-- =========================

-- lower values place lamps more frequently
local CAVE_LAMP_CHANCE = 100


-- =========================
-- NOISES
-- =========================

local cave_path_noise_1 = nil
local cave_path_noise_2 = nil
local cave_path_noise_3 = nil

local cave_vertical_noise = nil
local cave_width_noise = nil
local cave_shape_noise = nil


-- noises are created lazily because mapgen noise objects may not be available at load time
local function ensure_cave_noises()

	if cave_path_noise_1 then
		return
	end

	cave_path_noise_1 = core.get_value_noise({
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

	cave_path_noise_2 = core.get_value_noise({
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

	cave_path_noise_3 = core.get_value_noise({
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

	cave_vertical_noise = core.get_value_noise({
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

	cave_width_noise = core.get_value_noise({
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

	cave_shape_noise = core.get_value_noise({
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


local function get_cave_seed(cell_x, cell_z)
	return CAVE_BASE_SEED + cell_x * 73856093 + cell_z * 19349663
end


local function get_position_hash(x, y, z)

	local hash = CAVE_BASE_SEED + x * 73856093 + y * 19349663 + z * 83492791
	hash = hash % 2147483647

	if hash < 0 then
		hash = hash + 2147483647
	end

	return math.floor(hash)
end


local function get_path_value(path_type, x, z)

	if path_type == 2 then
		return cave_path_noise_2:get_2d({
			x = x,
			y = z
		})
	end

	if path_type == 3 then
		return cave_path_noise_3:get_2d({
			x = x,
			y = z
		})
	end

	return cave_path_noise_1:get_2d({
		x = x,
		y = z
	})
end


local function get_path_turn_strength(path_type)

	if path_type == 2 then
		return 0.085
	end

	if path_type == 3 then
		return 0.045
	end

	return 0.06
end


local function get_cave_radius(
	x,
	z,
	step,
	size_phase,
	size_rate
)

	local width = cave_width_noise:get_2d({
		x = x,
		y = z
	})

	local radius = (11 + width * 4) * CAVE_SIZE_SCALE
	radius = clamp(radius, 6, 11.25)

	local fluctuation = math.sin(size_phase + step * size_rate)
	local size_multiplier = 1 + fluctuation * CAVE_SIZE_FLUCTUATION

	radius = radius * size_multiplier

	return clamp(radius, CAVE_MIN_RADIUS, CAVE_MAX_RADIUS)
end


-- checks whether the cave footprint overlaps river carving
local function cave_near_river(x, z, radius)

	local sample_radius = math.ceil(radius)
	local diagonal_radius = math.ceil(sample_radius * 0.707)

	local checks = {
		{x = 0, z = 0},

		{x = sample_radius, z = 0},
		{x = -sample_radius, z = 0},
		{x = 0, z = sample_radius},
		{x = 0, z = -sample_radius},

		{x = diagonal_radius, z = diagonal_radius},
		{x = diagonal_radius, z = -diagonal_radius},
		{x = -diagonal_radius, z = diagonal_radius},
		{x = -diagonal_radius, z = -diagonal_radius}
	}

	for i = 1, #checks do

		local check = checks[i]

		local water_mask = lottmapgen.get_water(
			math.floor(x + check.x),
			math.floor(z + check.z)
		)

		local river_strength = 1 - water_mask

		river_strength = lottmapgen.smoothstep(
			0.2,
			0.8,
			river_strength
		)

		if river_strength > 0 then
			return true
		end
	end

	return false
end


-- checks whether a path sphere can affect the current mapgen area
local function cave_point_near_chunk(
	x,
	y,
	z,
	minp,
	maxp
)

	local margin = CAVE_MAX_CARVE_RADIUS + 2

	return x + margin >= minp.x
		and x - margin <= maxp.x
		and y + margin >= minp.y
		and y - margin <= maxp.y
		and z + margin >= minp.z
		and z - margin <= maxp.z
end


-- =========================
-- LAMP CANDIDATES
-- =========================

local function add_lamp_candidate(
	x,
	y,
	z,
	area,
	lamp_candidates,
	lamp_candidate_lookup
)

	local hash = get_position_hash(x, y, z)

	if hash % CAVE_LAMP_CHANCE ~= 0 then
		return
	end

	local vi = area:index(x, y, z)

	if lamp_candidate_lookup[vi] then
		return
	end

	lamp_candidate_lookup[vi] = true

	lamp_candidates[#lamp_candidates + 1] = {
		x = x,
		y = y,
		z = z,
		vi = vi
	}
end


-- =========================
-- SPHERE CARVING
-- =========================

local function carve_deformed_sphere(
	cx,
	cy,
	cz,
	radius,
	surface_opening,
	minp,
	maxp,
	area,
	data,
	lamp_candidates,
	lamp_candidate_lookup
)

	if radius <= 0 then
		return
	end

	local stone_ring = surface_opening and CAVE_ENTRANCE_STONE_RING or 0

	local max_radius = radius * (1 + CAVE_DEFORMATION) + stone_ring
	local max_radius_sq = max_radius * max_radius

	if cx + max_radius < minp.x
	or cx - max_radius > maxp.x
	or cy + max_radius < minp.y
	or cy - max_radius > maxp.y
	or cz + max_radius < minp.z
	or cz - max_radius > maxp.z then
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

			local surface_y

			if surface_opening then
				surface_y = lottmapgen.get_terrain_height(x, z)
			end

			if horizontal_sq <= max_radius_sq then
				for y = ymin, ymax do

					local dy = y - cy
					local distance_sq = horizontal_sq + dy * dy

					if distance_sq <= max_radius_sq then

						local deformation = cave_shape_noise:get_3d({
							x = x,
							y = y,
							z = z
						})

						local local_radius = radius + deformation * radius * CAVE_DEFORMATION
						local stone_radius = local_radius + stone_ring

						local vi = area:index(x, y, z)
						local current = data[vi]

						if distance_sq <= local_radius * local_radius then

							local carveable =
								current == c_stone
								or current == c_morstone

							-- only the entrance mouth may cut through surface terrain
							if surface_opening
							and current ~= c_air
							and current ~= c_water then
								carveable = true
							end

							if carveable then

								data[vi] = c_air

								if not surface_opening then
									add_lamp_candidate(
										x,
										y,
										z,
										area,
										lamp_candidates,
										lamp_candidate_lookup
									)
								end
							end

						elseif surface_opening
						and distance_sq <= stone_radius * stone_radius
						and current ~= c_air
						and current ~= c_water
						and y >= surface_y - CAVE_ENTRANCE_STONE_DEPTH
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

								local hash = get_position_hash(x, y, z)
								local dither = (hash % 1000) / 1000

								if dither < blend * CAVE_ENTRANCE_STONE_BLEND then
									data[vi] = c_stone
								end
							end
						end
					end
				end
			end
		end
	end
end


-- =========================
-- PATH DESCENT
-- =========================

-- fills large downward terrain corrections with overlapping spheres
local function move_cave_down(
	x,
	y,
	z,
	target_y,
	radius,
	minp,
	maxp,
	area,
	data,
	lamp_candidates,
	lamp_candidate_lookup
)

	while y - target_y > CAVE_MAX_DESCENT_PER_STEP do

		y = y - CAVE_MAX_DESCENT_PER_STEP

		if cave_point_near_chunk(
			x,
			y,
			z,
			minp,
			maxp
		) then

			carve_deformed_sphere(
				x,
				y,
				z,
				radius,
				false,
				minp,
				maxp,
				area,
				data,
				lamp_candidates,
				lamp_candidate_lookup
			)
		end
	end

	return target_y
end


-- =========================
-- PATH GENERATION
-- =========================

local function generate_cave_path(
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
	lamp_candidates,
	lamp_candidate_lookup
)

	local x = start_x
	local y = start_y
	local z = start_z

	local entrance_ground_y = lottmapgen.get_terrain_height(
		math.floor(start_x),
		math.floor(start_z)
	)

	local turn_strength = get_path_turn_strength(path_type)

	for step = 1, steps do

		local path_value = get_path_value(path_type, x, z)
		angle = angle + path_value * turn_strength

		local vertical = cave_vertical_noise:get_2d({
			x = x + 5000,
			y = z - 5000
		})

		local vertical_step = vertical * 1.5

		local radius = get_cave_radius(
			x,
			z,
			step,
			size_phase,
			size_rate
		)

		-- path state must always be reconstructed before chunk rejection
		local sample_x = math.floor(x)
		local sample_z = math.floor(z)

		local ground_y = lottmapgen.get_terrain_height(
			sample_x,
			sample_z
		)

		local maximum_radius = radius * (1 + CAVE_DEFORMATION)
		local river_radius = maximum_radius + CAVE_RIVER_EXTRA_MARGIN

		local surface_opening = false
		local carve_radius = radius

		if surface_path
		and step <= CAVE_ENTRANCE_THROAT_STEPS then

			if step == 1 then

				-- only one sphere intersects the surface to keep the opening circular
				y = entrance_ground_y - radius * 0.35

				surface_opening = true
				carve_radius = radius * CAVE_ENTRANCE_RADIUS_SCALE

			else

				-- force the first section downward to establish the entrance throat
				local target_y =
					entrance_ground_y
					- radius
					- (step - 1) * CAVE_ENTRANCE_DESCENT

				if y > target_y then
					y = target_y
				end
			end

		elseif surface_path
		and step <= CAVE_ENTRANCE_TUNNEL_STEPS then

			-- keep a guaranteed underground tunnel after the entrance throat
			local target_y =
				entrance_ground_y
				- radius
				- (CAVE_ENTRANCE_THROAT_STEPS - 1)
				* CAVE_ENTRANCE_DESCENT

			local near_river = cave_near_river(
				x,
				z,
				river_radius
			)

			if near_river then

				local river_safe_y =
					-5
					- maximum_radius
					- CAVE_UNDERGROUND

				if y > river_safe_y then

					y = move_cave_down(
						x,
						y,
						z,
						river_safe_y,
						radius,
						minp,
						maxp,
						area,
						data,
						lamp_candidates,
						lamp_candidate_lookup
					)
				end

			elseif y > target_y then

				y = target_y
			end

		else

			local safe_surface_y = ground_y

			local near_river = cave_near_river(
				x,
				z,
				river_radius
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
				- CAVE_UNDERGROUND

			if y > maximum_y then

				if near_river then

					y = move_cave_down(
						x,
						y,
						z,
						maximum_y,
						radius,
						minp,
						maxp,
						area,
						data,
						lamp_candidates,
						lamp_candidate_lookup
					)

				else

					y = move_cave_down(
						x,
						y,
						z,
						maximum_y,
						radius,
						minp,
						maxp,
						area,
						data,
						lamp_candidates,
						lamp_candidate_lookup
					)
				end
			end
		end

		if cave_point_near_chunk(
			x,
			y,
			z,
			minp,
			maxp
		) then

			carve_deformed_sphere(
				x,
				y,
				z,
				carve_radius,
				surface_opening,
				minp,
				maxp,
				area,
				data,
				lamp_candidates,
				lamp_candidate_lookup
			)
		end

		x = x + math.cos(angle) * CAVE_STEP_LENGTH
		z = z + math.sin(angle) * CAVE_STEP_LENGTH
		y = y + vertical_step
	end
end


-- =========================
-- LAMP PLACEMENT
-- =========================

local wall_directions = {
	{x = 1, y = 0, z = 0},
	{x = -1, y = 0, z = 0},
	{x = 0, y = 1, z = 0},
	{x = 0, y = -1, z = 0},
	{x = 0, y = 0, z = 1},
	{x = 0, y = 0, z = -1}
}


-- lamps are placed after all carving so overlapping paths cannot leave them floating
local function place_cave_lamps(
	area,
	data,
	lamp_candidates
)

	for i = 1, #lamp_candidates do

		local candidate = lamp_candidates[i]

		local x = candidate.x
		local y = candidate.y
		local z = candidate.z

		if data[candidate.vi] == c_air then

			local hash = get_position_hash(x, y, z)
			local first_direction = math.floor(hash / CAVE_LAMP_CHANCE) % #wall_directions + 1

			for offset = 0, #wall_directions - 1 do

				local direction_index =
					((first_direction - 1 + offset) % #wall_directions)
					+ 1

				local direction = wall_directions[direction_index]

				local wx = x + direction.x
				local wy = y + direction.y
				local wz = z + direction.z

				if wx >= area.MinEdge.x
				and wx <= area.MaxEdge.x
				and wy >= area.MinEdge.y
				and wy <= area.MaxEdge.y
				and wz >= area.MinEdge.z
				and wz <= area.MaxEdge.z then

					local wall_vi = area:index(wx, wy, wz)
					local wall_node = data[wall_vi]

					if wall_node == c_stone
					or wall_node == c_morstone then

						data[wall_vi] = c_mithril_lamp

						break
					end
				end
			end
		end
	end
end


-- =========================
-- CAVE GENERATION
-- =========================

function lottmapgen.generate_caves(
	minp,
	maxp,
	area,
	data
)

	ensure_cave_noises()

	local lamp_candidates = {}
	local lamp_candidate_lookup = {}

	local min_cell_x = math.floor(minp.x / CAVE_CELL_SIZE)
	local max_cell_x = math.floor(maxp.x / CAVE_CELL_SIZE)

	local min_cell_z = math.floor(minp.z / CAVE_CELL_SIZE)
	local max_cell_z = math.floor(maxp.z / CAVE_CELL_SIZE)

	for cell_z = min_cell_z - CAVE_SEARCH_RADIUS, max_cell_z + CAVE_SEARCH_RADIUS do
		for cell_x = min_cell_x - CAVE_SEARCH_RADIUS, max_cell_x + CAVE_SEARCH_RADIUS do

			local cave_seed = get_cave_seed(cell_x, cell_z)
			local pr = PcgRandom(cave_seed)

			local cell_min_x = cell_x * CAVE_CELL_SIZE
			local cell_min_z = cell_z * CAVE_CELL_SIZE

			for path_index = 1, CAVE_SYSTEMS_PER_CELL do

				local start_x = cell_min_x + pr:next(0, CAVE_CELL_SIZE - 1)
				local start_z = cell_min_z + pr:next(0, CAVE_CELL_SIZE - 1)

				local biome_id = lottmapgen.get_raw_biome_id(
					start_x,
					start_z
				)

				-- caves may travel beneath ocean biomes but never originate in them
				if biome_id ~= 1 then

					local ground_y = lottmapgen.get_terrain_height(
						start_x,
						start_z
					)

					local surface_path =
						pr:next(
							1,
							CAVE_ENTRANCE_CHANCE
						) == 1

					local start_y

					if surface_path
					and ground_y >= lottmapgen.WATER_LEVEL + CAVE_SURFACE_MIN_ABOVE_WATER then

						start_y =
							ground_y
							- pr:next(
								CAVE_ENTRANCE_DEPTH_MIN,
								CAVE_ENTRANCE_DEPTH_MAX
							)

					else

						surface_path = false

						start_y =
							ground_y
							- pr:next(
								30,
								100
							)
					end

					local angle = pr:next(0, 6283) / 1000

					local steps = pr:next(
						CAVE_MIN_STEPS,
						CAVE_MAX_STEPS
					)

					local path_type =
						((path_index - 1 + pr:next(0, 2)) % 3)
						+ 1

					local size_phase = pr:next(0, 6283) / 1000
					local size_rate = pr:next(120, 240) / 1000

					generate_cave_path(
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
						lamp_candidates,
						lamp_candidate_lookup
					)
				end
			end
		end
	end

	place_cave_lamps(
		area,
		data,
		lamp_candidates
	)
end