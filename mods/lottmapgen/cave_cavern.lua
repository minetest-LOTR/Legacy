-- =========================
-- CAVERN GENERATION
-- =========================

local c_air = core.get_content_id("air")

local c_stone = core.get_content_id("default:stone")
local c_morstone = core.get_content_id("lottmapgen:mordor_stone")


-- =========================
-- CAVERN SETTINGS
-- =========================

-- highest point where caverns may appear
local CAVERN_MAX_Y = -100

-- distance between successive underground cavern layers
local CAVERN_LAYER_SPACING = 170

-- controls how much of each cavern layer is carved
local CAVERN_REGION_THRESHOLD = 0.08

-- distance over which cavern edges taper closed
local CAVERN_REGION_BLEND = 0.22

local CAVERN_MIN_HEIGHT = 20
local CAVERN_MAX_HEIGHT = 45

local CAVERN_CENTER_VARIATION = 18
local CAVERN_FLOOR_VARIATION = 8
local CAVERN_CEILING_VARIATION = 10


-- =========================
-- CAVERN PILLAR SETTINGS
-- =========================

local CAVERN_PILLAR_CELL_SIZE = 38

local CAVERN_PILLAR_WAIST_MIN = 2
local CAVERN_PILLAR_WAIST_MAX = 5

local CAVERN_PILLAR_FLARE_MIN = 2
local CAVERN_PILLAR_FLARE_MAX = 6

local CAVERN_PILLAR_EXPONENT_MIN = 180
local CAVERN_PILLAR_EXPONENT_MAX = 280

-- prevents every pillar cell from containing a pillar
local CAVERN_PILLAR_CHANCE = 3


-- =========================
-- CAVERN NOISES
-- =========================

local cavern_region_noise = nil
local cavern_center_noise = nil
local cavern_height_noise = nil
local cavern_floor_noise = nil
local cavern_ceiling_noise = nil


-- noises are created lazily because mapgen noise objects may not be available at load time
local function ensure_cavern_noises()

	if cavern_region_noise then
		return
	end

	cavern_region_noise = core.get_value_noise({
		offset = 0,
		scale = 1,

		spread = {
			x = 150,
			y = 150,
			z = 150
		},

		seed = 15320,
		octaves = 3,
		persist = 0.55,
		lacunarity = 2.0
	})

	cavern_center_noise = core.get_value_noise({
		offset = 0,
		scale = 1,

		spread = {
			x = 220,
			y = 220,
			z = 220
		},

		seed = 15321,
		octaves = 2,
		persist = 0.5,
		lacunarity = 2.0
	})

	cavern_height_noise = core.get_value_noise({
		offset = 0,
		scale = 1,

		spread = {
			x = 180,
			y = 180,
			z = 180
		},

		seed = 15322,
		octaves = 2,
		persist = 0.5,
		lacunarity = 2.0
	})

	cavern_floor_noise = core.get_value_noise({
		offset = 0,
		scale = 1,

		spread = {
			x = 75,
			y = 75,
			z = 75
		},

		seed = 15323,
		octaves = 3,
		persist = 0.5,
		lacunarity = 2.0
	})

	cavern_ceiling_noise = core.get_value_noise({
		offset = 0,
		scale = 1,

		spread = {
			x = 90,
			y = 90,
			z = 90
		},

		seed = 15324,
		octaves = 3,
		persist = 0.5,
		lacunarity = 2.0
	})
end


-- =========================
-- CAVERN HELPERS
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


local function smoothstep(value)

	value = clamp(value, 0, 1)

	return value
		* value
		* (3 - 2 * value)
end


local function get_cavern_layer_center(layer)

	-- first layer sits just below the cavern ceiling limit
	return CAVERN_MAX_Y - 35 - layer * CAVERN_LAYER_SPACING
end


local function get_cavern_region_value(x, z, layer)

	return cavern_region_noise:get_2d({
		x = x + layer * 713,
		y = z - layer * 947
	})
end


local function get_cavern_bounds(
	x,
	z,
	layer,
	region
)

	local layer_center = get_cavern_layer_center(layer)

	local center_noise = cavern_center_noise:get_2d({
		x = x + layer * 419,
		y = z - layer * 631
	})

	local height_noise = cavern_height_noise:get_2d({
		x = x - layer * 823,
		y = z + layer * 367
	})

	local floor_noise = cavern_floor_noise:get_2d({
		x = x + layer * 271,
		y = z + layer * 557
	})

	local ceiling_noise = cavern_ceiling_noise:get_2d({
		x = x - layer * 661,
		y = z - layer * 313
	})

	local center_y =
		layer_center
		+ center_noise * CAVERN_CENTER_VARIATION

	local height_t = clamp(
		(height_noise + 1) * 0.5,
		0,
		1
	)

	local region_strength = clamp(
		(region - CAVERN_REGION_THRESHOLD)
		/ CAVERN_REGION_BLEND,
		0,
		1
	)

	region_strength = smoothstep(region_strength)

	local cavern_height =
		CAVERN_MIN_HEIGHT
		+ (CAVERN_MAX_HEIGHT - CAVERN_MIN_HEIGHT)
		* height_t

	local half_height =
		cavern_height
		* region_strength
		* 0.5

	local floor_variation =
		floor_noise
		* CAVERN_FLOOR_VARIATION
		* region_strength

	local ceiling_variation =
		ceiling_noise
		* CAVERN_CEILING_VARIATION
		* region_strength

	local floor_y =
		center_y
		- half_height
		+ floor_variation

	local ceiling_y =
		center_y
		+ half_height
		+ ceiling_variation

	ceiling_y = math.min(
		ceiling_y,
		CAVERN_MAX_Y
	)

	return floor_y, ceiling_y
end


-- =========================
-- CAVERN PILLARS
-- =========================

local function get_cavern_pillar_seed(
	cell_x,
	cell_z,
	layer
)

	local hash =
		15325
		+ cell_x * 73856093
		+ cell_z * 19349663
		+ layer * 83492791

	hash = hash % 2147483647

	if hash < 0 then
		hash = hash + 2147483647
	end

	return math.floor(hash)
end


local function get_cavern_pillar(
	cell_x,
	cell_z,
	layer
)

	local pr = PcgRandom(
		get_cavern_pillar_seed(
			cell_x,
			cell_z,
			layer
		)
	)

	if pr:next(1, CAVERN_PILLAR_CHANCE) ~= 1 then
		return nil
	end

	local cell_min_x = cell_x * CAVERN_PILLAR_CELL_SIZE
	local cell_min_z = cell_z * CAVERN_PILLAR_CELL_SIZE

	local margin =
		CAVERN_PILLAR_FLARE_MAX
		+ CAVERN_PILLAR_WAIST_MAX
		+ 2

	local usable_size =
		CAVERN_PILLAR_CELL_SIZE
		- margin * 2

	if usable_size <= 0 then
		return nil
	end

	local x =
		cell_min_x
		+ margin
		+ pr:next(0, usable_size)

	local z =
		cell_min_z
		+ margin
		+ pr:next(0, usable_size)

	local waist =
		pr:next(
			CAVERN_PILLAR_WAIST_MIN * 100,
			CAVERN_PILLAR_WAIST_MAX * 100
		)
		/ 100

	local bottom_flare =
		math.min(
			pr:next(
				CAVERN_PILLAR_FLARE_MIN * 100,
				CAVERN_PILLAR_FLARE_MAX * 100
			)
			/ 100,
			waist * 1.5
		)

	local top_flare =
		math.min(
			pr:next(
				CAVERN_PILLAR_FLARE_MIN * 100,
				CAVERN_PILLAR_FLARE_MAX * 100
			)
			/ 100,
			waist * 1.5
		)

	local bottom_exponent =
		pr:next(
			CAVERN_PILLAR_EXPONENT_MIN,
			CAVERN_PILLAR_EXPONENT_MAX
		)
		/ 100

	local top_exponent =
		pr:next(
			CAVERN_PILLAR_EXPONENT_MIN,
			CAVERN_PILLAR_EXPONENT_MAX
		)
		/ 100

	return {
		x = x,
		z = z,
		waist = waist,

		bottom_flare = bottom_flare,
		top_flare = top_flare,

		bottom_exponent = bottom_exponent,
		top_exponent = top_exponent
	}
end


-- generates nearby pillars once instead of rebuilding them for every cavern column
local function get_cavern_pillars(
	minp,
	maxp,
	layer
)

	local pillars = {}

	local margin =
		CAVERN_PILLAR_FLARE_MAX
		+ CAVERN_PILLAR_WAIST_MAX
		+ 2

	local min_cell_x =
		math.floor(
			(minp.x - margin)
			/ CAVERN_PILLAR_CELL_SIZE
		)

	local max_cell_x =
		math.floor(
			(maxp.x + margin)
			/ CAVERN_PILLAR_CELL_SIZE
		)

	local min_cell_z =
		math.floor(
			(minp.z - margin)
			/ CAVERN_PILLAR_CELL_SIZE
		)

	local max_cell_z =
		math.floor(
			(maxp.z + margin)
			/ CAVERN_PILLAR_CELL_SIZE
		)

	for cell_z = min_cell_z, max_cell_z do
		for cell_x = min_cell_x, max_cell_x do

			local pillar =
				get_cavern_pillar(
					cell_x,
					cell_z,
					layer
				)

			if pillar then
				pillars[#pillars + 1] = pillar
			end
		end
	end

	return pillars
end


local function get_cavern_pillar_at(
	x,
	z,
	pillars
)

	local best_pillar = nil
	local best_distance_sq = nil

	for i = 1, #pillars do

		local pillar = pillars[i]

		local dx = x - pillar.x
		local dz = z - pillar.z

		local distance_sq =
			dx * dx
			+ dz * dz

		local maximum_flare =
			math.max(
				pillar.bottom_flare,
				pillar.top_flare
			)

		local maximum_radius =
			pillar.waist
			+ maximum_flare

		if distance_sq <= maximum_radius * maximum_radius then

			if not best_distance_sq
			or distance_sq < best_distance_sq then

				best_pillar = pillar
				best_distance_sq = distance_sq
			end
		end
	end

	return best_pillar, best_distance_sq
end


local function cavern_pillar_contains(
	y,
	floor_y,
	ceiling_y,
	pillar,
	distance_sq
)

	local height = ceiling_y - floor_y

	if height <= 0 then
		return false
	end

	local t = (y - floor_y) / height
	t = clamp(t, 0, 1)

	local radius

	if t < 0.5 then

		local edge =
			1
			- t * 2

		radius =
			pillar.waist
			+ math.pow(
				edge,
				pillar.bottom_exponent
			)
			* pillar.bottom_flare

	else

		local edge =
			(t - 0.5)
			* 2

		radius =
			pillar.waist
			+ math.pow(
				edge,
				pillar.top_exponent
			)
			* pillar.top_flare
	end

	return distance_sq <= radius * radius
end


-- =========================
-- CAVERN GENERATION
-- =========================

function lottmapgen.generate_caverns(
	minp,
	maxp,
	area,
	data,
	cave_data
)

	if minp.y > CAVERN_MAX_Y then
		return
	end

	ensure_cavern_noises()


	-- determine every cavern layer capable of intersecting this chunk
	local layer_min =
		math.max(
			0,
			math.floor(
				(CAVERN_MAX_Y - maxp.y)
				/ CAVERN_LAYER_SPACING
			) - 1
		)

	local layer_max =
		math.max(
			0,
			math.floor(
				(CAVERN_MAX_Y - minp.y)
				/ CAVERN_LAYER_SPACING
			) + 1
		)

	for layer = layer_min, layer_max do

		local layer_center =
			get_cavern_layer_center(layer)

		local layer_margin =
			CAVERN_MAX_HEIGHT
			+ CAVERN_CENTER_VARIATION
			+ CAVERN_FLOOR_VARIATION
			+ CAVERN_CEILING_VARIATION

		if layer_center + layer_margin >= minp.y
		and layer_center - layer_margin <= maxp.y then

			local pillars =
				get_cavern_pillars(
					minp,
					maxp,
					layer
				)

			for z = minp.z, maxp.z do
				for x = minp.x, maxp.x do

					local region =
						get_cavern_region_value(
							x,
							z,
							layer
						)

					if region > CAVERN_REGION_THRESHOLD then

						local floor_y, ceiling_y =
							get_cavern_bounds(
								x,
								z,
								layer,
								region
							)

						if ceiling_y - floor_y >= 6 then

							local pillar, pillar_distance_sq =
								get_cavern_pillar_at(
									x,
									z,
									pillars
								)

							local ymin =
								math.max(
									math.ceil(floor_y),
									minp.y
								)

							local ymax =
								math.min(
									math.floor(ceiling_y),
									maxp.y
								)

							for y = ymin, ymax do

								local inside_pillar = false

								if pillar then

									inside_pillar =
										cavern_pillar_contains(
											y,
											floor_y,
											ceiling_y,
											pillar,
											pillar_distance_sq
										)
								end

								if not inside_pillar then

									local vi =
										area:index(
											x,
											y,
											z
										)

									local current = data[vi]

									if current == c_stone
									or current == c_morstone then
										data[vi] = c_air
										current = c_air
									end

									-- cavern ownership replaces worm ownership inside overlapping volume
									if current == c_air then
										lottmapgen.mark_cave_node(
											x,
											y,
											z,
											vi,
											"cavern",
											cave_data
										)
									end
								end
							end
						end
					end
				end
			end
		end
	end

end