-- =========================
-- VAULT CAVE GENERATION
-- =========================

local c_air = core.get_content_id("air")

local c_stone = core.get_content_id("default:stone")
local c_morstone = core.get_content_id("lottmapgen:mordor_stone")


-- =========================
-- VAULT SETTINGS
-- =========================

-- highest point where vault cave layers may originate
local VAULT_MAX_Y = -100

-- distance between successive underground vault layers
local VAULT_LAYER_SPACING = 240

-- distance between parallel vault systems
-- lower values produce more vault systems
local VAULT_SPACING = 360

-- horizontal half-width of the main caveway
local VAULT_MIN_WIDTH = 14
local VAULT_MAX_WIDTH = 128

-- biases both width and height toward smaller vaults
-- extreme vaults remain possible but are uncommon
local VAULT_SIZE_BIAS = 2.6

-- independent variation applied after shared size scaling
local VAULT_HEIGHT_VARIATION = 0.15

-- occasional broad chamber expansion
local VAULT_EXPANSION_THRESHOLD = 0.78
local VAULT_EXPANSION_MAX = 24

-- vault height follows the same scale factor as width
local VAULT_MIN_HEIGHT = 55
local VAULT_MAX_HEIGHT = 255

-- controls how strongly the main cave path wanders sideways
local VAULT_PATH_VARIATION = 90

-- controls broad vertical movement of the cave
local VAULT_CENTER_VARIATION = 24

local VAULT_FLOOR_VARIATION = 8
local VAULT_CEILING_VARIATION = 18

-- softens the cave walls instead of ending at a perfect vertical boundary
local VAULT_EDGE_BLEND = 5


-- =========================
-- VAULT BRANCH SETTINGS
-- =========================

-- branch begins appearing above this noise value
local VAULT_BRANCH_THRESHOLD = 0.42

-- maximum distance a branch can move away from the main path
local VAULT_BRANCH_MAX_OFFSET = 55

-- branch width relative to the main vault width
local VAULT_BRANCH_WIDTH_MIN = 0.65
local VAULT_BRANCH_WIDTH_MAX = 0.9

-- removes tiny branches that barely separate from the main cave
local VAULT_BRANCH_MIN_OFFSET = 8


-- =========================
-- VAULT SPELEOTHEM SETTINGS
-- =========================

-- dense world-space distribution of giant formations
local VAULT_SPELEOTHEM_CELL_SIZE = 18

-- every eligible cell attempts to place one formation
local VAULT_SPELEOTHEM_CHANCE = 1

-- avoid only the absolute wall edge and absolute centre line
local VAULT_SPELEOTHEM_MIN_STRENGTH = 0.08
local VAULT_SPELEOTHEM_MAX_STRENGTH = 0.94

-- horizontal size of giant formations
local VAULT_SPELEOTHEM_RADIUS_MIN = 4
local VAULT_SPELEOTHEM_RADIUS_MAX = 10

-- slightly stretches formations so they are rarely perfect circles
local VAULT_SPELEOTHEM_STRETCH_MIN = 70
local VAULT_SPELEOTHEM_STRETCH_MAX = 140

-- cut-off floor and ceiling forms use a large part of the vault height
local VAULT_SPELEOTHEM_HEIGHT_MIN = 0.25
local VAULT_SPELEOTHEM_HEIGHT_MAX = 0.65

-- prevents exceptionally tall vaults from creating absurd spikes
local VAULT_SPELEOTHEM_HEIGHT_MAXIMUM = 58

-- lower values preserve a broad base while producing a sharper tip
local VAULT_SPELEOTHEM_SHAPE_MIN = 45
local VAULT_SPELEOTHEM_SHAPE_MAX = 85

-- one in this many formations becomes a complete floor-to-ceiling pillar
local VAULT_SPELEOTHEM_PILLAR_CHANCE = 6


-- =========================
-- VAULT NOISES
-- =========================

local vault_path_noise = nil
local vault_width_noise = nil
local vault_center_noise = nil
local vault_height_noise = nil
local vault_floor_noise = nil
local vault_ceiling_noise = nil
local vault_wall_noise = nil

local vault_branch_noise = nil
local vault_branch_side_noise = nil
local vault_branch_width_noise = nil


-- noises are created lazily because mapgen noise objects may not be available at load time
local function ensure_vault_noises()

	if vault_path_noise then
		return
	end

	vault_path_noise = core.get_value_noise({
		offset = 0,
		scale = 1,

		spread = {
			x = 420,
			y = 420,
			z = 420
		},

		seed = 15400,
		octaves = 3,
		persist = 0.55,
		lacunarity = 2.0
	})

	vault_width_noise = core.get_value_noise({
		offset = 0,
		scale = 1,

		spread = {
			x = 190,
			y = 190,
			z = 190
		},

		seed = 15401,
		octaves = 2,
		persist = 0.5,
		lacunarity = 2.0
	})

	vault_center_noise = core.get_value_noise({
		offset = 0,
		scale = 1,

		spread = {
			x = 320,
			y = 320,
			z = 320
		},

		seed = 15402,
		octaves = 2,
		persist = 0.5,
		lacunarity = 2.0
	})

	vault_height_noise = core.get_value_noise({
		offset = 0,
		scale = 1,

		spread = {
			x = 220,
			y = 220,
			z = 220
		},

		seed = 15403,
		octaves = 2,
		persist = 0.5,
		lacunarity = 2.0
	})

	vault_floor_noise = core.get_value_noise({
		offset = 0,
		scale = 1,

		spread = {
			x = 75,
			y = 75,
			z = 75
		},

		seed = 15404,
		octaves = 3,
		persist = 0.5,
		lacunarity = 2.0
	})

	vault_ceiling_noise = core.get_value_noise({
		offset = 0,
		scale = 1,

		spread = {
			x = 105,
			y = 105,
			z = 105
		},

		seed = 15405,
		octaves = 3,
		persist = 0.5,
		lacunarity = 2.0
	})

	vault_wall_noise = core.get_value_noise({
		offset = 0,
		scale = 1,

		spread = {
			x = 40,
			y = 40,
			z = 40
		},

		seed = 15406,
		octaves = 2,
		persist = 0.5,
		lacunarity = 2.0
	})

	vault_branch_noise = core.get_value_noise({
		offset = 0,
		scale = 1,

		spread = {
			x = 520,
			y = 520,
			z = 520
		},

		seed = 15407,
		octaves = 2,
		persist = 0.5,
		lacunarity = 2.0
	})

	vault_branch_side_noise = core.get_value_noise({
		offset = 0,
		scale = 1,

		spread = {
			x = 900,
			y = 900,
			z = 900
		},

		seed = 15408,
		octaves = 1,
		persist = 0.5,
		lacunarity = 2.0
	})

	vault_branch_width_noise = core.get_value_noise({
		offset = 0,
		scale = 1,

		spread = {
			x = 260,
			y = 260,
			z = 260
		},

		seed = 15409,
		octaves = 2,
		persist = 0.5,
		lacunarity = 2.0
	})
end


-- =========================
-- VAULT HELPERS
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

	return value * value * (3 - 2 * value)
end


local function get_vault_layer_center(layer)

	return VAULT_MAX_Y - 60 - layer * VAULT_LAYER_SPACING
end


-- returns the horizontal centre of the winding vault at this z position
local function get_vault_path_x(z, layer)

	local path =
		vault_path_noise:get_2d({
			x = z + layer * 577,
			y = layer * 911
		})

	return path * VAULT_PATH_VARIATION
end


-- shared scale controls both vault width and height
local function get_vault_size(z, layer)

	local size_noise =
		vault_width_noise:get_2d({
			x = z - layer * 431,
			y = layer * 719
		})

	local t = clamp((size_noise + 1) * 0.5, 0, 1)

	return math.pow(t, VAULT_SIZE_BIAS)
end


local function get_vault_width(z, layer)

	local t = get_vault_size(z, layer)

	local width =
		VAULT_MIN_WIDTH
		+ (VAULT_MAX_WIDTH - VAULT_MIN_WIDTH) * t

	if t > VAULT_EXPANSION_THRESHOLD then

		local expansion =
			(t - VAULT_EXPANSION_THRESHOLD)
			/ (1 - VAULT_EXPANSION_THRESHOLD)

		width = width + expansion * VAULT_EXPANSION_MAX
	end

	return width
end


local function get_vault_branch(
	z,
	layer,
	main_width
)

	local branch_noise =
		vault_branch_noise:get_2d({
			x = z + layer * 827,
			y = layer * 613
		})

	if branch_noise <= VAULT_BRANCH_THRESHOLD then
		return nil
	end

	local strength =
		(branch_noise - VAULT_BRANCH_THRESHOLD)
		/ (1 - VAULT_BRANCH_THRESHOLD)

	strength = smoothstep(strength)

	local offset = strength * VAULT_BRANCH_MAX_OFFSET

	if offset < VAULT_BRANCH_MIN_OFFSET then
		return nil
	end

	local side_noise =
		vault_branch_side_noise:get_2d({
			x = z - layer * 331,
			y = layer * 947
		})

	local side = 1

	if side_noise < 0 then
		side = -1
	end

	local width_noise =
		vault_branch_width_noise:get_2d({
			x = z + layer * 479,
			y = layer * 269
		})

	local width_t =
		clamp(
			(width_noise + 1) * 0.5,
			0,
			1
		)

	local width_scale =
		VAULT_BRANCH_WIDTH_MIN
		+ (
			VAULT_BRANCH_WIDTH_MAX
			- VAULT_BRANCH_WIDTH_MIN
		)
		* width_t

	return {
		offset = offset * side,
		width = main_width * width_scale
	}
end


-- section values are shared across the vault width
local function get_vault_section(
	z,
	layer
)

	local layer_center = get_vault_layer_center(layer)

	local center_noise =
		vault_center_noise:get_2d({
			x = z + layer * 313,
			y = layer * 467
		})

	local height_noise =
		vault_height_noise:get_2d({
			x = z - layer * 619,
			y = layer * 283
		})

	local floor_noise =
		vault_floor_noise:get_2d({
			x = z + layer * 181,
			y = layer * 541
		})

	local ceiling_noise =
		vault_ceiling_noise:get_2d({
			x = z - layer * 337,
			y = layer * 761
		})

	local center_y =
		layer_center
		+ center_noise
		* VAULT_CENTER_VARIATION

	local size_t =
		get_vault_size(
			z,
			layer
		)

	local vault_height =
		VAULT_MIN_HEIGHT
		+ (
			VAULT_MAX_HEIGHT
			- VAULT_MIN_HEIGHT
		)
		* size_t

	-- preserves some independent height character without breaking scale correlation
	local height_scale =
		1
		+ height_noise
		* VAULT_HEIGHT_VARIATION

	vault_height =
		clamp(
			vault_height * height_scale,
			VAULT_MIN_HEIGHT,
			VAULT_MAX_HEIGHT
		)

	return {
		center_y = center_y,
		height = vault_height,
		floor_variation = floor_noise * VAULT_FLOOR_VARIATION,
		ceiling_variation = ceiling_noise * VAULT_CEILING_VARIATION
	}
end


local function get_vault_bounds(
	section,
	horizontal_strength
)

	local vertical_strength = smoothstep(horizontal_strength)

	local half_height =
		section.height
		* vertical_strength
		* 0.5

	local floor_y =
		section.center_y
		- half_height
		+ section.floor_variation
		* vertical_strength

	local ceiling_y =
		section.center_y
		+ half_height
		+ section.ceiling_variation
		* vertical_strength

	return floor_y, ceiling_y
end


-- returns the strongest contribution from the main path or branch
local function get_vault_strength(
	x,
	main_center_x,
	main_width,
	branch_center_x,
	branch_width,
	layer,
	z
)

	local wall_noise =
		vault_wall_noise:get_2d({
			x = x + layer * 173,
			y = z - layer * 397
		})

	local main_local_width =
		main_width
		+ wall_noise
		* VAULT_EDGE_BLEND

	local strength = 0

	if main_local_width > 0 then

		local main_distance =
			math.abs(
				x
				- main_center_x
			)

		if main_distance <= main_local_width then

			strength =
				1
				- main_distance
				/ main_local_width
		end
	end

	if branch_center_x then

		local branch_local_width =
			branch_width
			+ wall_noise
			* VAULT_EDGE_BLEND

		if branch_local_width > 0 then

			local branch_distance =
				math.abs(
					x
					- branch_center_x
				)

			if branch_distance <= branch_local_width then

				local branch_strength =
					1
					- branch_distance
					/ branch_local_width

				if branch_strength > strength then
					strength = branch_strength
				end
			end
		end
	end

	return strength
end


local function get_vault_strength_at(
	x,
	z,
	layer
)

	local path_x = get_vault_path_x(z, layer)
	local main_width = get_vault_width(z, layer)

	local branch =
		get_vault_branch(
			z,
			layer,
			main_width
		)

	local band =
		math.floor(
			(x - path_x)
			/ VAULT_SPACING
			+ 0.5
		)

	local main_center_x =
		path_x
		+ band
		* VAULT_SPACING

	local branch_center_x = nil
	local branch_width = 0

	if branch then
		branch_center_x = main_center_x + branch.offset
		branch_width = branch.width
	end

	return get_vault_strength(
		x,
		main_center_x,
		main_width,
		branch_center_x,
		branch_width,
		layer,
		z
	)
end


-- =========================
-- VAULT SPELEOTHEMS
-- =========================

local function get_vault_speleothem_seed(
	cell_x,
	cell_z,
	layer
)

	local hash =
		15420
		+ cell_x * 73856093
		+ cell_z * 19349663
		+ layer * 83492791

	hash = hash % 2147483647

	if hash < 0 then
		hash = hash + 2147483647
	end

	return math.floor(hash)
end


local function get_vault_speleothem_candidate(
	cell_x,
	cell_z,
	layer
)

	local pr =
		PcgRandom(
			get_vault_speleothem_seed(
				cell_x,
				cell_z,
				layer
			)
		)

	if VAULT_SPELEOTHEM_CHANCE > 1
	and pr:next(1, VAULT_SPELEOTHEM_CHANCE) ~= 1 then
		return nil
	end

	local cell_min_x =
		cell_x
		* VAULT_SPELEOTHEM_CELL_SIZE

	local cell_min_z =
		cell_z
		* VAULT_SPELEOTHEM_CELL_SIZE

	local x =
		cell_min_x
		+ pr:next(
			0,
			VAULT_SPELEOTHEM_CELL_SIZE - 1
		)

	local z =
		cell_min_z
		+ pr:next(
			0,
			VAULT_SPELEOTHEM_CELL_SIZE - 1
		)

	local radius =
		pr:next(
			VAULT_SPELEOTHEM_RADIUS_MIN * 100,
			VAULT_SPELEOTHEM_RADIUS_MAX * 100
		)
		/ 100

	local stretch =
		pr:next(
			VAULT_SPELEOTHEM_STRETCH_MIN,
			VAULT_SPELEOTHEM_STRETCH_MAX
		)
		/ 100

	local radius_x = radius
	local radius_z = radius * stretch

	if pr:next(1, 2) == 1 then
		radius_x, radius_z = radius_z, radius_x
	end

	local type_roll =
		pr:next(
			1,
			VAULT_SPELEOTHEM_PILLAR_CHANCE
		)

	local speleothem_type

	if type_roll == 1 then

		speleothem_type = "pillar"

	elseif pr:next(1, 2) == 1 then

		speleothem_type = "floor"

	else

		speleothem_type = "ceiling"
	end

	local height_scale =
		pr:next(
			VAULT_SPELEOTHEM_HEIGHT_MIN * 1000,
			VAULT_SPELEOTHEM_HEIGHT_MAX * 1000
		)
		/ 1000

	local shape =
		pr:next(
			VAULT_SPELEOTHEM_SHAPE_MIN,
			VAULT_SPELEOTHEM_SHAPE_MAX
		)
		/ 100

	local waist_scale = pr:next(28, 50) / 100
	local bottom_flare = pr:next(80, 120) / 100
	local top_flare = pr:next(80, 120) / 100

	local bottom_exponent = pr:next(170, 280) / 100
	local top_exponent = pr:next(170, 280) / 100

	return {
		x = x,
		z = z,

		type = speleothem_type,

		radius_x = radius_x,
		radius_z = radius_z,

		height_scale = height_scale,
		shape = shape,

		waist_scale = waist_scale,
		bottom_flare = bottom_flare,
		top_flare = top_flare,

		bottom_exponent = bottom_exponent,
		top_exponent = top_exponent
	}
end


local function get_speleothem_cell_key(
	cell_x,
	cell_z
)

	return
		tostring(cell_x)
		.. ":"
		.. tostring(cell_z)
end


local function get_vault_speleothems(
	minp,
	maxp,
	layer
)

	local cells = {}

	local margin =
		VAULT_SPELEOTHEM_RADIUS_MAX
		+ 4

	local min_cell_x =
		math.floor(
			(minp.x - margin)
			/ VAULT_SPELEOTHEM_CELL_SIZE
		)

	local max_cell_x =
		math.floor(
			(maxp.x + margin)
			/ VAULT_SPELEOTHEM_CELL_SIZE
		)

	local min_cell_z =
		math.floor(
			(minp.z - margin)
			/ VAULT_SPELEOTHEM_CELL_SIZE
		)

	local max_cell_z =
		math.floor(
			(maxp.z + margin)
			/ VAULT_SPELEOTHEM_CELL_SIZE
		)

	for cell_z = min_cell_z, max_cell_z do
		for cell_x = min_cell_x, max_cell_x do

			local speleothem =
				get_vault_speleothem_candidate(
					cell_x,
					cell_z,
					layer
				)

			if speleothem then

				local strength =
					get_vault_strength_at(
						speleothem.x,
						speleothem.z,
						layer
					)

				if strength >= VAULT_SPELEOTHEM_MIN_STRENGTH
				and strength <= VAULT_SPELEOTHEM_MAX_STRENGTH then

					local section =
						get_vault_section(
							speleothem.z,
							layer
						)

					local floor_y, ceiling_y =
						get_vault_bounds(
							section,
							strength
						)

					local height =
						ceiling_y
						- floor_y

					if height >= 16 then

						speleothem.height =
							math.min(
								height
									* speleothem.height_scale,
								VAULT_SPELEOTHEM_HEIGHT_MAXIMUM
							)

						local key =
							get_speleothem_cell_key(
								cell_x,
								cell_z
							)

						cells[key] = speleothem
					end
				end
			end
		end
	end

	return cells
end


local function get_vault_speleothem_column(
	x,
	z,
	floor_y,
	ceiling_y,
	speleothem_cells
)

	local floor_top = nil
	local ceiling_bottom = nil
	local pillars = nil

	local cell_x =
		math.floor(
			x
			/ VAULT_SPELEOTHEM_CELL_SIZE
		)

	local cell_z =
		math.floor(
			z
			/ VAULT_SPELEOTHEM_CELL_SIZE
		)

	for offset_z = -1, 1 do
		for offset_x = -1, 1 do

			local key =
				get_speleothem_cell_key(
					cell_x + offset_x,
					cell_z + offset_z
				)

			local speleothem =
				speleothem_cells[key]

			if speleothem then

				local dx = x - speleothem.x
				local dz = z - speleothem.z

				local nx = dx / speleothem.radius_x
				local nz = dz / speleothem.radius_z

				local distance_sq =
					nx * nx
					+ nz * nz

				if distance_sq <= 1 then

					if speleothem.type == "floor" then

						local distance =
							math.sqrt(
								distance_sq
							)

						local radial =
							1
							- distance

						local height =
							speleothem.height
							* math.pow(
								radial,
								speleothem.shape
							)

						local top =
							floor_y
							+ height

						if not floor_top
						or top > floor_top then
							floor_top = top
						end

					elseif speleothem.type == "ceiling" then

						local distance =
							math.sqrt(
								distance_sq
							)

						local radial =
							1
							- distance

						local height =
							speleothem.height
							* math.pow(
								radial,
								speleothem.shape
							)

						local bottom =
							ceiling_y
							- height

						if not ceiling_bottom
						or bottom < ceiling_bottom then
							ceiling_bottom = bottom
						end

					else

						if not pillars then
							pillars = {}
						end

						pillars[#pillars + 1] = {
							speleothem = speleothem,
							distance_sq = distance_sq
						}
					end
				end
			end
		end
	end

	return floor_top, ceiling_bottom, pillars
end


local function vault_pillar_contains(
	y,
	floor_y,
	ceiling_y,
	pillar_data
)

	local speleothem =
		pillar_data.speleothem

	local height =
		ceiling_y
		- floor_y

	if height <= 0 then
		return false
	end

	local t =
		(y - floor_y)
		/ height

	t = clamp(t, 0, 1)

	local radius_scale

	if t < 0.5 then

		local edge =
			1
			- t * 2

		radius_scale =
			speleothem.waist_scale
			+ math.pow(
				edge,
				speleothem.bottom_exponent
			)
			* (
				speleothem.bottom_flare
				- speleothem.waist_scale
			)

	else

		local edge =
			(t - 0.5)
			* 2

		radius_scale =
			speleothem.waist_scale
			+ math.pow(
				edge,
				speleothem.top_exponent
			)
			* (
				speleothem.top_flare
				- speleothem.waist_scale
			)
	end

	return
		pillar_data.distance_sq
		<= radius_scale
			* radius_scale
end


local function vault_speleothem_contains(
	y,
	floor_y,
	ceiling_y,
	floor_top,
	ceiling_bottom,
	pillars
)

	if floor_top
	and y <= floor_top then
		return true
	end

	if ceiling_bottom
	and y >= ceiling_bottom then
		return true
	end

	if pillars then

		for i = 1, #pillars do

			if vault_pillar_contains(
				y,
				floor_y,
				ceiling_y,
				pillars[i]
			) then
				return true
			end
		end
	end

	return false
end


-- =========================
-- VAULT GENERATION
-- =========================

function lottmapgen.generate_vault_caves(
	minp,
	maxp,
	area,
	data,
	cave_data
)

	if minp.y > VAULT_MAX_Y then
		return
	end

	ensure_vault_noises()

	local area_index = area.index
	local ystride = area.ystride

	local mark_cave_node =
		lottmapgen.mark_cave_node

	local floor = math.floor
	local ceil = math.ceil
	local abs = math.abs
	local max = math.max
	local min = math.min


	-- determine every vault layer capable of intersecting this chunk
	local layer_min =
		max(
			0,
			floor(
				(VAULT_MAX_Y - maxp.y)
				/ VAULT_LAYER_SPACING
			) - 1
		)

	local layer_max =
		max(
			0,
			floor(
				(VAULT_MAX_Y - minp.y)
				/ VAULT_LAYER_SPACING
			) + 1
		)

	local layer_margin =
		VAULT_MAX_HEIGHT
		+ VAULT_CENTER_VARIATION
		+ VAULT_FLOOR_VARIATION
		+ VAULT_CEILING_VARIATION

	for layer = layer_min, layer_max do

		local layer_center =
			get_vault_layer_center(layer)

		if layer_center + layer_margin >= minp.y
		and layer_center - layer_margin <= maxp.y then

			local speleothem_cells =
				get_vault_speleothems(
					minp,
					maxp,
					layer
				)

			for z = minp.z, maxp.z do

				local path_x =
					get_vault_path_x(
						z,
						layer
					)

				local main_width =
					get_vault_width(
						z,
						layer
					)

				local section =
					get_vault_section(
						z,
						layer
					)

				local branch =
					get_vault_branch(
						z,
						layer,
						main_width
					)

				local max_width =
					main_width
					+ VAULT_EDGE_BLEND

				local branch_offset = 0
				local branch_width = 0

				if branch then

					branch_offset =
						branch.offset

					branch_width =
						branch.width

					max_width =
						max(
							max_width,
							abs(branch_offset)
								+ branch_width
								+ VAULT_EDGE_BLEND
						)
				end

				-- inspect only vault systems capable of intersecting this chunk
				local band_min =
					ceil(
						(
							minp.x
							- path_x
							- max_width
						)
						/ VAULT_SPACING
					)

				local band_max =
					floor(
						(
							maxp.x
							- path_x
							+ max_width
						)
						/ VAULT_SPACING
					)

				for band = band_min, band_max do

					local main_center_x =
						path_x
						+ band
						* VAULT_SPACING

					local branch_center_x = nil

					if branch then
						branch_center_x =
							main_center_x
							+ branch_offset
					end

					local xmin =
						max(
							minp.x,
							floor(
								main_center_x
								- main_width
								- VAULT_EDGE_BLEND
							)
						)

					local xmax =
						min(
							maxp.x,
							ceil(
								main_center_x
								+ main_width
								+ VAULT_EDGE_BLEND
							)
						)

					if branch_center_x then

						xmin =
							max(
								minp.x,
								min(
									xmin,
									floor(
										branch_center_x
										- branch_width
										- VAULT_EDGE_BLEND
									)
								)
							)

						xmax =
							min(
								maxp.x,
								max(
									xmax,
									ceil(
										branch_center_x
										+ branch_width
										+ VAULT_EDGE_BLEND
									)
								)
							)
					end

					for x = xmin, xmax do

						local horizontal_strength =
							get_vault_strength(
								x,
								main_center_x,
								main_width,
								branch_center_x,
								branch_width,
								layer,
								z
							)

						if horizontal_strength > 0 then

							local floor_y, ceiling_y =
								get_vault_bounds(
									section,
									horizontal_strength
								)

							if ceiling_y - floor_y >= 8 then

								local ymin =
									max(
										ceil(floor_y),
										minp.y
									)

								local ymax =
									min(
										floor(ceiling_y),
										maxp.y
									)

								if ymin <= ymax then

									local floor_top,
										ceiling_bottom,
										pillars =
											get_vault_speleothem_column(
												x,
												z,
												floor_y,
												ceiling_y,
												speleothem_cells
											)

									local vi =
										area_index(
											area,
											x,
											ymin,
											z
										)

									for y = ymin, ymax do

										local inside_speleothem =
											vault_speleothem_contains(
												y,
												floor_y,
												ceiling_y,
												floor_top,
												ceiling_bottom,
												pillars
											)

										if not inside_speleothem then

											local current =
												data[vi]

											if current == c_stone
											or current == c_morstone then

												data[vi] = c_air
												current = c_air
											end

											if current == c_air then

												mark_cave_node(
													x,
													y,
													z,
													vi,
													"vault",
													cave_data
												)
											end
										end

										vi = vi + ystride
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