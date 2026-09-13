-- =========================
-- CAVE DECORATION
-- =========================

local c_air = core.get_content_id("air")
local c_water = core.get_content_id("default:water_source")
local c_ignore = core.CONTENT_IGNORE

local c_mithril_lamp = core.get_content_id("lottblocks:mithril_stonelamp")
local c_darkage_lamp = core.get_content_id("darkage:lamp")


-- =========================
-- CAVE DECO SETTINGS
-- =========================

-- lower values place lamps more frequently
local CAVE_LAMP_CHANCE = 180


-- =========================
-- CAVE VOLUME REPORTING
-- =========================

-- records the final cave volume rather than temporary carving surfaces
-- cavern ownership replaces worm ownership where both formations overlap
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

		if cave_type == "cavern" then
			cave_node.cave_type = "cavern"
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


-- resolves one final boundary from the combined worm and cavern volume
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
		cavern = {}
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

				-- only resolve surfaces inside the same bounds
				-- used for cave generation
				if sx >= minp.x
				and sx <= maxp.x
				and sy >= minp.y
				and sy <= maxp.y
				and sz >= minp.z
				and sz <= maxp.z then

					local surface_vi = area:index(
						sx,
						sy,
						sz
					)

					-- another cave node is never a final surface
					-- ignore is never treated as terrain
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

local function get_cave_deco_hash(x, y, z)

	local hash = 16320 + x * 73856093 + y * 19349663 + z * 83492791
	hash = hash % 2147483647

	if hash < 0 then
		hash = hash + 2147483647
	end

	return math.floor(hash)
end


-- =========================
-- CAVE LAMPS
-- =========================

local function collect_cave_lamp_candidates(
	data,
	cave_data
)

	local candidates = {}
	local candidate_lookup = {}

	for i = 1, #cave_data.surfaces.all do

		local surface = cave_data.surfaces.all[i]

		if is_cave_surface_node(data[surface.vi]) then

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

	local lamp_candidates =
		collect_cave_lamp_candidates(
			data,
			cave_data
		)

	place_cave_lamps(
		data,
		lamp_candidates
	)
end