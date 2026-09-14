-- =========================
-- CAVE DECORATION
-- =========================

local c_air = core.get_content_id("air")
local c_water = core.get_content_id("default:water_source")
local c_ignore = core.CONTENT_IGNORE

local c_mithril_lamp = core.get_content_id("lottblocks:mithril_stonelamp")
local c_darkage_lamp = core.get_content_id("darkage:lamp")

local c_stalagmite_base = core.get_content_id("lottblocks:stalagmite_base_stone")
local c_stalagmite_middle = core.get_content_id("lottblocks:stalagmite_middle_stone")
local c_stalagmite_top = core.get_content_id("lottblocks:stalagmite_top_stone")

local c_stalactite_base = core.get_content_id("lottblocks:stalactite_base_stone")
local c_stalactite_middle = core.get_content_id("lottblocks:stalactite_middle_stone")
local c_stalactite_top = core.get_content_id("lottblocks:stalactite_top_stone")

local c_small_stalagmites = {}
local c_small_stalactites = {}

for i = 1, 5 do
	c_small_stalagmites[i] = core.get_content_id("lottblocks:stalagmite_stone_" .. i)
	c_small_stalactites[i] = core.get_content_id("lottblocks:stalactite_stone_" .. i)
end

local c_mushroom_blue = core.get_content_id("lottplants:mushroom_blue")
local c_mushroom_green = core.get_content_id("lottplants:mushroom_green")
local c_mushroom_red = core.get_content_id("lottplants:mushroom_red")
local c_mushroom_brown = core.get_content_id("lottplants:mushroom_brown")


-- =========================
-- CAVE DECO SETTINGS
-- =========================

-- lower values place lamps more frequently
local CAVE_LAMP_CHANCE = 180

-- only noise values above this become speleothem regions
-- lower values create more regions
local CAVE_SPELEOTHEM_REGION_THRESHOLD = 0.58

-- forced regions around reported worm cave surface entrances
-- the core is fully dense and the outer radius fades into normal cave handling
local CAVE_OPENING_REGION_CORE_RADIUS = 8
local CAVE_OPENING_REGION_RADIUS = 22

-- lower values create more drip sites inside active regions
local CAVE_DRIP_EDGE_CHANCE = 10
local CAVE_DRIP_CORE_CHANCE = 2

-- lower values create more large formations
local CAVE_BIG_EDGE_CHANCE = 8
local CAVE_BIG_CORE_CHANCE = 4

-- controls the relative frequency of each drip site type
local CAVE_DRIP_PAIRED_WEIGHT = 6
local CAVE_DRIP_CEILING_WEIGHT = 2
local CAVE_DRIP_FLOOR_WEIGHT = 2

local CAVE_DRIP_TOTAL_WEIGHT = CAVE_DRIP_PAIRED_WEIGHT
	+ CAVE_DRIP_CEILING_WEIGHT
	+ CAVE_DRIP_FLOOR_WEIGHT

local CAVE_STALAGMITE_MIDDLE_MIN = 1
local CAVE_STALAGMITE_MIDDLE_MAX = 4

local CAVE_STALACTITE_MIDDLE_MIN = 1
local CAVE_STALACTITE_MIDDLE_MAX = 4


-- =========================
-- MUSHROOM SETTINGS
-- =========================

-- only noise values above this become mushroom colonies
-- lower values create more colonies
local CAVE_MUSHROOM_REGION_THRESHOLD = 0.60

-- controls the physical size of mushroom colonies
local CAVE_MUSHROOM_REGION_SPREAD_XZ = 55
local CAVE_MUSHROOM_REGION_SPREAD_Y = 30

-- controls the size of broad blue and green mushroom regions
local CAVE_MUSHROOM_SPECIES_SPREAD_XZ = 140
local CAVE_MUSHROOM_SPECIES_SPREAD_Y = 70

-- lower values place mushrooms more densely
local CAVE_MUSHROOM_EDGE_CHANCE = 18
local CAVE_MUSHROOM_CORE_CHANCE = 3

-- colony species becomes more dominant toward the center
local CAVE_MUSHROOM_CORE_SPECIES_MIN = 0.45
local CAVE_MUSHROOM_CORE_SPECIES_MAX = 0.90


-- =========================
-- CAVE DECO NOISES
-- =========================

local cave_speleothem_noise = nil
local cave_mushroom_noise = nil
local cave_mushroom_species_noise = nil


-- created lazily because mapgen noise objects may not be available at load time
local function ensure_cave_deco_noises()

	if cave_speleothem_noise
	and cave_mushroom_noise
	and cave_mushroom_species_noise then
		return
	end

	if not cave_speleothem_noise then

		cave_speleothem_noise = core.get_value_noise({
			offset = 0,
			scale = 1,

			spread = {
				x = 90,
				y = 50,
				z = 90
			},

			seed = 16321,
			octaves = 2,
			persist = 0.5,
			lacunarity = 2.0
		})
	end

	if not cave_mushroom_noise then

		cave_mushroom_noise = core.get_value_noise({
			offset = 0,
			scale = 1,

			spread = {
				x = CAVE_MUSHROOM_REGION_SPREAD_XZ,
				y = CAVE_MUSHROOM_REGION_SPREAD_Y,
				z = CAVE_MUSHROOM_REGION_SPREAD_XZ
			},

			seed = 16322,
			octaves = 2,
			persist = 0.5,
			lacunarity = 2.0
		})
	end

	if not cave_mushroom_species_noise then

		cave_mushroom_species_noise = core.get_value_noise({
			offset = 0,
			scale = 1,

			spread = {
				x = CAVE_MUSHROOM_SPECIES_SPREAD_XZ,
				y = CAVE_MUSHROOM_SPECIES_SPREAD_Y,
				z = CAVE_MUSHROOM_SPECIES_SPREAD_XZ
			},

			seed = 16323,
			octaves = 2,
			persist = 0.5,
			lacunarity = 2.0
		})
	end
end


-- =========================
-- CAVE VOLUME REPORTING
-- =========================

-- records the final cave volume rather than temporary carving surfaces
-- cavern ownership replaces worm ownership where both formations overlap
local cave_type_priority = {
	worm = 1,
	cavern = 2,
	vault = 3
}


function lottmapgen.mark_cave_node(
	x,
	y,
	z,
	vi,
	cave_type,
	cave_data
)

	local cave_node = cave_data.mask[vi]

	if cave_node then

		local current_priority =
			cave_type_priority[cave_node.cave_type]
			or 0

		local new_priority =
			cave_type_priority[cave_type]
			or 0

		if new_priority > current_priority then
			cave_node.cave_type = cave_type
		end

		return
	end

	cave_node = {
		x = x,
		y = y,
		z = z,
		vi = vi,
		cave_type = cave_type
	}

	cave_data.mask[vi] = cave_node
	cave_data.nodes[#cave_data.nodes + 1] = cave_node
end


-- =========================
-- CAVE SURFACE RESOLUTION
-- =========================

local cave_surface_directions = {
	{
		x = 1,
		y = 0,
		z = 0,
		surface_type = "wall"
	},
	{
		x = -1,
		y = 0,
		z = 0,
		surface_type = "wall"
	},
	{
		x = 0,
		y = 0,
		z = 1,
		surface_type = "wall"
	},
	{
		x = 0,
		y = 0,
		z = -1,
		surface_type = "wall"
	},
	{
		x = 0,
		y = -1,
		z = 0,
		surface_type = "floor"
	},
	{
		x = 0,
		y = 1,
		z = 0,
		surface_type = "ceiling"
	}
}


local function is_cave_surface_node(content_id)

	return content_id ~= c_air
		and content_id ~= c_water
		and content_id ~= c_ignore
end


local function add_cave_surface(
	surface_type,
	cave_type,
	x,
	y,
	z,
	vi,
	air_x,
	air_y,
	air_z,
	air_vi,
	cave_data
)

	local surface_lookup = cave_data.surface_lookup[vi]

	if not surface_lookup then
		surface_lookup = {}
		cave_data.surface_lookup[vi] = surface_lookup
	end

	if surface_lookup[air_vi] then
		return
	end

	surface_lookup[air_vi] = true

	local surface = {
		x = x,
		y = y,
		z = z,
		vi = vi,

		air_x = air_x,
		air_y = air_y,
		air_z = air_z,
		air_vi = air_vi,

		cave_type = cave_type,
		surface_type = surface_type
	}

	cave_data.surfaces.all[#cave_data.surfaces.all + 1] = surface
	cave_data.surfaces[surface_type][#cave_data.surfaces[surface_type] + 1] = surface
	cave_data.surfaces[cave_type][#cave_data.surfaces[cave_type] + 1] = surface
end


-- resolves boundaries from the final combined worm and cavern volume
function lottmapgen.resolve_cave_surfaces(
	minp,
	maxp,
	area,
	data,
	cave_data
)

	cave_data.surfaces = {
		all = {},
		wall = {},
		floor = {},
		ceiling = {},

		worm = {},
		cavern = {},
		vault = {}
	}
	cave_data.surface_lookup = {}

	for i = 1, #cave_data.nodes do

		local cave_node = cave_data.nodes[i]

		-- only nodes that remain air belong to the final cave volume
		if data[cave_node.vi] == c_air then

			for direction_index = 1, #cave_surface_directions do

				local direction = cave_surface_directions[direction_index]

				local sx = cave_node.x + direction.x
				local sy = cave_node.y + direction.y
				local sz = cave_node.z + direction.z

				-- only resolve surfaces inside the cave generation bounds
				if sx >= minp.x
				and sx <= maxp.x
				and sy >= minp.y
				and sy <= maxp.y
				and sz >= minp.z
				and sz <= maxp.z then

					local surface_vi = area:index(sx, sy, sz)

					-- cave nodes and ignore are never final terrain surfaces
					if not cave_data.mask[surface_vi]
					and is_cave_surface_node(data[surface_vi]) then

						add_cave_surface(
							direction.surface_type,
							cave_node.cave_type,
							sx,
							sy,
							sz,
							surface_vi,
							cave_node.x,
							cave_node.y,
							cave_node.z,
							cave_node.vi,
							cave_data
						)
					end
				end
			end
		end
	end
end


-- =========================
-- CAVE DECO HELPERS
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


local function get_cave_deco_hash(x, y, z, salt)

	salt = salt or 0

	local hash = 16320
		+ x * 73856093
		+ y * 19349663
		+ z * 83492791
		+ salt * 2654435761

	hash = hash % 2147483647

	if hash < 0 then
		hash = hash + 2147483647
	end

	return hash
end


local function get_density_chance(
	density,
	edge_chance,
	core_chance
)

	local chance = edge_chance + (core_chance - edge_chance) * density

	return math.max(1, math.floor(chance + 0.5))
end


local function cave_air_available(
	x,
	y,
	z,
	minp,
	maxp,
	area,
	data,
	cave_data
)

	if x < minp.x
	or x > maxp.x
	or y < minp.y
	or y > maxp.y
	or z < minp.z
	or z > maxp.z then
		return false
	end

	local vi = area:index(x, y, z)

	return cave_data.mask[vi] ~= nil
		and data[vi] == c_air
end


local function can_place_cave_column(
	surface,
	direction,
	height,
	minp,
	maxp,
	area,
	data,
	cave_data
)

	for offset = 0, height - 1 do

		local y = surface.air_y + direction * offset

		if not cave_air_available(
			surface.air_x,
			y,
			surface.air_z,
			minp,
			maxp,
			area,
			data,
			cave_data
		) then
			return false
		end
	end

	return true
end


local function write_cave_column_node(
	surface,
	direction,
	offset,
	content_id,
	area,
	data
)

	local vi = area:index(
		surface.air_x,
		surface.air_y + direction * offset,
		surface.air_z
	)

	data[vi] = content_id
end


-- =========================
-- SPELEOTHEM REGIONS
-- =========================

-- returns 0 outside a normal speleothem region and 0..1 inside one
local function get_cave_speleothem_density(x, y, z)

	local noise = cave_speleothem_noise:get_3d({
		x = x,
		y = y,
		z = z
	})

	local normalized = clamp((noise + 1) * 0.5, 0, 1)

	if normalized <= CAVE_SPELEOTHEM_REGION_THRESHOLD then
		return 0
	end

	local density = (normalized - CAVE_SPELEOTHEM_REGION_THRESHOLD)
		/ (1 - CAVE_SPELEOTHEM_REGION_THRESHOLD)

	-- density rises quickly after entering an active region
	return math.sqrt(density)
end


-- creates a guaranteed region around reported worm cave surface entrances
local function get_cave_opening_density(
	x,
	y,
	z,
	cave_data
)

	local openings = cave_data.surface_openings

	if not openings then
		return 0
	end

	local core_radius_sq =
		CAVE_OPENING_REGION_CORE_RADIUS
		* CAVE_OPENING_REGION_CORE_RADIUS

	local region_radius_sq =
		CAVE_OPENING_REGION_RADIUS
		* CAVE_OPENING_REGION_RADIUS

	local best_density = 0

	for i = 1, #openings do

		local opening = openings[i]

		local dx = x - opening.x
		local dy = y - opening.y
		local dz = z - opening.z

		local distance_sq = dx * dx + dy * dy + dz * dz

		if distance_sq <= core_radius_sq then
			return 1
		end

		if distance_sq < region_radius_sq then

			local distance = math.sqrt(distance_sq)

			local density =
				1
				- (
					distance - CAVE_OPENING_REGION_CORE_RADIUS
				)
				/ (
					CAVE_OPENING_REGION_RADIUS
					- CAVE_OPENING_REGION_CORE_RADIUS
				)

			if density > best_density then
				best_density = density
			end
		end
	end

	return best_density
end


-- combines natural cave regions with forced surface entrance regions
local function get_cave_drip_density(
	x,
	y,
	z,
	cave_data
)

	local natural_density = get_cave_speleothem_density(
		x,
		y,
		z
	)

	local opening_density = get_cave_opening_density(
		x,
		y,
		z,
		cave_data
	)

	return math.max(
		natural_density,
		opening_density
	)
end


-- =========================
-- STALAGMITES AND STALACTITES
-- =========================

local function place_large_stalagmite(
	surface,
	minp,
	maxp,
	area,
	data,
	cave_data
)

	local hash = get_cave_deco_hash(
		surface.air_x,
		surface.air_y,
		surface.air_z,
		11
	)

	local middle_count = CAVE_STALAGMITE_MIDDLE_MIN
		+ hash % (CAVE_STALAGMITE_MIDDLE_MAX - CAVE_STALAGMITE_MIDDLE_MIN + 1)

	local height = middle_count + 2

	if not can_place_cave_column(
		surface,
		1,
		height,
		minp,
		maxp,
		area,
		data,
		cave_data
	) then
		return false
	end

	write_cave_column_node(
		surface,
		1,
		0,
		c_stalagmite_base,
		area,
		data
	)

	for offset = 1, middle_count do

		write_cave_column_node(
			surface,
			1,
			offset,
			c_stalagmite_middle,
			area,
			data
		)
	end

	write_cave_column_node(
		surface,
		1,
		middle_count + 1,
		c_stalagmite_top,
		area,
		data
	)

	return true
end


local function place_large_stalactite(
	surface,
	minp,
	maxp,
	area,
	data,
	cave_data
)

	local hash = get_cave_deco_hash(
		surface.air_x,
		surface.air_y,
		surface.air_z,
		12
	)

	local middle_count = CAVE_STALACTITE_MIDDLE_MIN
		+ hash % (CAVE_STALACTITE_MIDDLE_MAX - CAVE_STALACTITE_MIDDLE_MIN + 1)

	local height = middle_count + 2

	if not can_place_cave_column(
		surface,
		-1,
		height,
		minp,
		maxp,
		area,
		data,
		cave_data
	) then
		return false
	end

	write_cave_column_node(
		surface,
		-1,
		0,
		c_stalactite_base,
		area,
		data
	)

	for offset = 1, middle_count do

		write_cave_column_node(
			surface,
			-1,
			offset,
			c_stalactite_middle,
			area,
			data
		)
	end

	write_cave_column_node(
		surface,
		-1,
		middle_count + 1,
		c_stalactite_top,
		area,
		data
	)

	return true
end


local function place_small_stalagmite(
	surface,
	data
)

	if data[surface.air_vi] ~= c_air then
		return false
	end

	local hash = get_cave_deco_hash(
		surface.air_x,
		surface.air_y,
		surface.air_z,
		21
	)

	local variant = hash % #c_small_stalagmites + 1
	data[surface.air_vi] = c_small_stalagmites[variant]

	return true
end


local function place_small_stalactite(
	surface,
	data
)

	if data[surface.air_vi] ~= c_air then
		return false
	end

	local hash = get_cave_deco_hash(
		surface.air_x,
		surface.air_y,
		surface.air_z,
		22
	)

	local variant = hash % #c_small_stalactites + 1
	data[surface.air_vi] = c_small_stalactites[variant]

	return true
end


local function place_stalagmite(
	surface,
	density,
	minp,
	maxp,
	area,
	data,
	cave_data
)

	local big_chance = get_density_chance(
		density,
		CAVE_BIG_EDGE_CHANCE,
		CAVE_BIG_CORE_CHANCE
	)

	local hash = get_cave_deco_hash(
		surface.x,
		surface.y,
		surface.z,
		41
	)

	if hash % big_chance == 0
	and place_large_stalagmite(
		surface,
		minp,
		maxp,
		area,
		data,
		cave_data
	) then
		return true
	end

	return place_small_stalagmite(
		surface,
		data
	)
end


local function place_stalactite(
	surface,
	density,
	minp,
	maxp,
	area,
	data,
	cave_data
)

	local big_chance = get_density_chance(
		density,
		CAVE_BIG_EDGE_CHANCE,
		CAVE_BIG_CORE_CHANCE
	)

	local hash = get_cave_deco_hash(
		surface.x,
		surface.y,
		surface.z,
		42
	)

	if hash % big_chance == 0
	and place_large_stalactite(
		surface,
		minp,
		maxp,
		area,
		data,
		cave_data
	) then
		return true
	end

	return place_small_stalactite(
		surface,
		data
	)
end


-- =========================
-- DRIP FIELDS
-- =========================

-- maps the top cave air node of each column to its ceiling surface
local function build_ceiling_air_lookup(cave_data)

	local lookup = {}

	for i = 1, #cave_data.surfaces.ceiling do

		local surface = cave_data.surfaces.ceiling[i]
		lookup[surface.air_vi] = surface
	end

	return lookup
end


-- follows continuous cave air upward until its ceiling is reached
local function find_ceiling_above(
	floor_surface,
	maxp,
	area,
	data,
	cave_data,
	ceiling_air_lookup
)

	local x = floor_surface.air_x
	local z = floor_surface.air_z

	for y = floor_surface.air_y, maxp.y do

		local vi = area:index(x, y, z)

		if not cave_data.mask[vi]
		or data[vi] ~= c_air then
			return nil
		end

		local ceiling_surface = ceiling_air_lookup[vi]

		if ceiling_surface then
			return ceiling_surface
		end
	end

	return nil
end


-- chooses whether a drip site affects both surfaces or only one
local function get_drip_mode(x, y, z)

	local hash = get_cave_deco_hash(
		x,
		y,
		z,
		52
	)

	local roll = hash % CAVE_DRIP_TOTAL_WEIGHT

	if roll < CAVE_DRIP_PAIRED_WEIGHT then
		return "paired"
	end

	roll = roll - CAVE_DRIP_PAIRED_WEIGHT

	if roll < CAVE_DRIP_CEILING_WEIGHT then
		return "ceiling"
	end

	return "floor"
end


local function place_cave_drip_fields(
	minp,
	maxp,
	area,
	data,
	cave_data
)

	local occupied_surface_lookup = {}
	local ceiling_air_lookup = build_ceiling_air_lookup(cave_data)
	local processed_ceiling_lookup = {}

	for i = 1, #cave_data.surfaces.floor do

		local floor_surface = cave_data.surfaces.floor[i]

		if data[floor_surface.air_vi] == c_air then

			local ceiling_surface = find_ceiling_above(
				floor_surface,
				maxp,
				area,
				data,
				cave_data,
				ceiling_air_lookup
			)

			if ceiling_surface
			and not processed_ceiling_lookup[ceiling_surface.air_vi]
			and data[ceiling_surface.air_vi] == c_air then

				-- one ceiling can only belong to one resolved drip column
				processed_ceiling_lookup[ceiling_surface.air_vi] = true

				local midpoint_y = math.floor(
					(floor_surface.air_y + ceiling_surface.air_y) * 0.5
				)

				-- natural noise and surface entrances both contribute to the field
				local density = get_cave_drip_density(
					floor_surface.air_x,
					midpoint_y,
					floor_surface.air_z,
					cave_data
				)

				if density > 0 then

					local drip_chance = get_density_chance(
						density,
						CAVE_DRIP_EDGE_CHANCE,
						CAVE_DRIP_CORE_CHANCE
					)

					local drip_hash = get_cave_deco_hash(
						floor_surface.air_x,
						midpoint_y,
						floor_surface.air_z,
						51
					)

					if drip_hash % drip_chance == 0 then

						local drip_mode = get_drip_mode(
							floor_surface.air_x,
							midpoint_y,
							floor_surface.air_z
						)

						if drip_mode == "paired"
						or drip_mode == "floor" then

							if place_stalagmite(
								floor_surface,
								density,
								minp,
								maxp,
								area,
								data,
								cave_data
							) then
								occupied_surface_lookup[floor_surface.vi] = true
							end
						end

						if drip_mode == "paired"
						or drip_mode == "ceiling" then

							if place_stalactite(
								ceiling_surface,
								density,
								minp,
								maxp,
								area,
								data,
								cave_data
							) then
								occupied_surface_lookup[ceiling_surface.vi] = true
							end
						end
					end
				end
			end
		end
	end

	return occupied_surface_lookup
end


-- =========================
-- MUSHROOM COLONIES
-- =========================

-- returns 0 outside mushroom colonies and 0..1 toward colony cores
local function get_cave_mushroom_density(x, y, z)

	local noise = cave_mushroom_noise:get_3d({
		x = x,
		y = y,
		z = z
	})

	local normalized = clamp((noise + 1) * 0.5, 0, 1)

	if normalized <= CAVE_MUSHROOM_REGION_THRESHOLD then
		return 0
	end

	local density = (normalized - CAVE_MUSHROOM_REGION_THRESHOLD)
		/ (1 - CAVE_MUSHROOM_REGION_THRESHOLD)

	-- gives colonies stronger centers while keeping softer outer edges
	return math.sqrt(density)
end


-- broad noise determines whether a colony is primarily blue or green
local function get_cave_mushroom_colony_species(x, y, z)

	local species_noise = cave_mushroom_species_noise:get_3d({
		x = x,
		y = y,
		z = z
	})

	if species_noise >= 0 then
		return c_mushroom_blue
	end

	return c_mushroom_green
end


-- central blue or green growth dominates while red and brown scatter around it
local function get_cave_mushroom(
	x,
	y,
	z,
	density
)

	local colony_species = get_cave_mushroom_colony_species(
		x,
		y,
		z
	)

	local hash = get_cave_deco_hash(
		x,
		y,
		z,
		62
	)

	local roll = hash % 1000 / 1000

	local colony_species_chance = CAVE_MUSHROOM_CORE_SPECIES_MIN
		+ (
			CAVE_MUSHROOM_CORE_SPECIES_MAX
			- CAVE_MUSHROOM_CORE_SPECIES_MIN
		)
		* density

	if roll < colony_species_chance then
		return colony_species
	end

	-- red and brown form the secondary scatter around the main colony
	if hash % 2 == 0 then
		return c_mushroom_red
	end

	return c_mushroom_brown
end


local function place_cave_mushrooms(
	data,
	cave_data,
	occupied_surface_lookup
)

	for i = 1, #cave_data.surfaces.floor do

		local surface = cave_data.surfaces.floor[i]

		-- speleothems take priority over mushrooms
		if not occupied_surface_lookup[surface.vi]
		and data[surface.air_vi] == c_air then

			local density = get_cave_mushroom_density(
				surface.air_x,
				surface.air_y,
				surface.air_z
			)

			if density > 0 then

				local mushroom_chance = get_density_chance(
					density,
					CAVE_MUSHROOM_EDGE_CHANCE,
					CAVE_MUSHROOM_CORE_CHANCE
				)

				local hash = get_cave_deco_hash(
					surface.air_x,
					surface.air_y,
					surface.air_z,
					63
				)

				if hash % mushroom_chance == 0 then

					data[surface.air_vi] = get_cave_mushroom(
						surface.air_x,
						surface.air_y,
						surface.air_z,
						density
					)

					occupied_surface_lookup[surface.vi] = true
				end
			end
		end
	end
end


-- =========================
-- CAVE LAMPS
-- =========================

local function collect_cave_lamp_candidates(
	data,
	cave_data,
	occupied_surface_lookup
)

	local candidates = {}
	local candidate_lookup = {}

	for i = 1, #cave_data.surfaces.all do

		local surface = cave_data.surfaces.all[i]

		if not occupied_surface_lookup[surface.vi]
		and is_cave_surface_node(data[surface.vi]) then

			local hash = get_cave_deco_hash(
				surface.x,
				surface.y,
				surface.z
			)

			if hash % CAVE_LAMP_CHANCE == 0 then

				local candidate = candidate_lookup[surface.vi]

				if not candidate then

					candidate = {
						vi = surface.vi,
						surface_type = surface.surface_type
					}

					candidate_lookup[surface.vi] = candidate
					candidates[#candidates + 1] = candidate

				elseif surface.surface_type == "floor"
				or surface.surface_type == "ceiling" then

					-- horizontal surfaces take priority over walls
					candidate.surface_type = surface.surface_type
				end
			end
		end
	end

	return candidates
end


local function place_cave_lamps(
	data,
	candidates
)

	for i = 1, #candidates do

		local candidate = candidates[i]

		if is_cave_surface_node(data[candidate.vi]) then

			if candidate.surface_type == "wall" then
				data[candidate.vi] = c_mithril_lamp
			else
				data[candidate.vi] = c_darkage_lamp
			end
		end
	end
end


-- =========================
-- CAVE DECO GENERATION
-- =========================

function lottmapgen.generate_cave_decorations(
	minp,
	maxp,
	area,
	data,
	cave_data
)

	ensure_cave_deco_noises()

	local occupied_surface_lookup = place_cave_drip_fields(
		minp,
		maxp,
		area,
		data,
		cave_data
	)

	place_cave_mushrooms(
		data,
		cave_data,
		occupied_surface_lookup
	)

	local lamp_candidates = collect_cave_lamp_candidates(
		data,
		cave_data,
		occupied_surface_lookup
	)

	place_cave_lamps(
		data,
		lamp_candidates
	)
end