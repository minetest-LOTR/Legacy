local modpath = core.get_modpath(core.get_current_modname())
local meta = dofile(modpath .. "/meta.lua")

lottmapgen = {}

dofile(minetest.get_modpath("lottmapgen").."/nodes.lua")
dofile(minetest.get_modpath("lottmapgen").."/helpers.lua")

dofile(minetest.get_modpath("lottmapgen").."/functions.lua")

dofile(minetest.get_modpath("lottmapgen").."/worldedit.lua")
dofile(minetest.get_modpath("lottmapgen").."/schematics.lua")

-- =========================
-- MAP SETTINGS
-- =========================
lottmapgen.MAP_WIDTH = meta.width
lottmapgen.MAP_HEIGHT = meta.height

lottmapgen.MAP_SCALE = 4 -- production scale: 16
lottmapgen.BIOME_WARP = lottmapgen.MAP_SCALE

lottmapgen.WATER_LEVEL = 0
lottmapgen.SEA_LEVEL = 0.1

-- SAMPLING
dofile(minetest.get_modpath("lottmapgen").."/sampling.lua")

-- =========================
-- NODES
-- =========================
local c_air = core.get_content_id("air")
local c_water = core.get_content_id("default:water_source")
local c_stone = core.get_content_id("default:stone")
local c_morstone = core.get_content_id("lottmapgen:mordor_stone")

-- =========================
-- retrieve data
-- =========================
local height_data = lottmapgen.load_compressed(modpath .. "/mapdata/height.bin.zlib")
local water_data = lottmapgen.load_compressed(modpath .. "/mapdata/wmask.bin.zlib")
local mountain_data = lottmapgen.load_compressed(modpath .. "/mapdata/mmask.bin.zlib")

function lottmapgen.get_height(px, pz)
	return lottmapgen.sample_bilinear(
		height_data,
		px,
		pz,
		0
	)
end

function lottmapgen.get_water(px, pz)
	return lottmapgen.sample_bilinear(
		water_data,
		px,
		pz,
		255
	)
end

function lottmapgen.get_mask(px, pz)
	return lottmapgen.sample_bilinear(
		mountain_data,
		px,
		pz,
		0
	)
end

-- TERRAIN NOISES
dofile(minetest.get_modpath("lottmapgen").."/noise.lua")

-- BIOME HANDLING
dofile(minetest.get_modpath("lottmapgen").."/biome_helpers.lua")

-- BIOME DECORATION
dofile(minetest.get_modpath("lottmapgen").."/biome_api.lua")
dofile(minetest.get_modpath("lottmapgen").."/biome_deco.lua")
dofile(minetest.get_modpath("lottmapgen").."/biomes.lua")

-- =========================
-- MAPGEN
-- =========================
core.register_on_generated(function(minp, maxp)

	-- =========================
	-- CREATE NOISE
	-- =========================
	if not lottmapgen.warp_x_noise then

		lottmapgen.ridge_noise =
			core.get_value_noise({
				offset = 0,
				scale = 1,

				spread = {
					x = 280,
					y = 160,
					z = 280
				},

				seed = 3003,
				octaves = 5,
				persist = 0.55,
				lacunarity = 2.0
			})

		lottmapgen.detail_noise =
			core.get_value_noise({
				offset = 0,
				scale = 1,

				spread = {
					x = 40,
					y = 40,
					z = 40
				},

				seed = 4004,
				octaves = 4,
				persist = 0.5,
				lacunarity = 2.0
			})

		lottmapgen.warp_x_noise =
			core.get_value_noise({
				offset = 0,
				scale = 1,

				spread = {
					x = 200,
					y = 200,
					z = 200
				},

				seed = 5005,
				octaves = 3,
				persist = 0.5,
				lacunarity = 2.0
			})

		lottmapgen.warp_z_noise =
			core.get_value_noise({
				offset = 0,
				scale = 1,

				spread = {
					x = 200,
					y = 200,
					z = 200
				},

				seed = 6006,
				octaves = 3,
				persist = 0.5,
				lacunarity = 2.0
			})

		lottmapgen.mountain_shape_noise =
			core.get_value_noise({
				offset = 0,
				scale = 1,

				spread = {
					x = 600,
					y = 600,
					z = 600
				},

				seed = 7007,
				octaves = 3,
				persist = 0.5,
				lacunarity = 2.0
			})

		lottmapgen.mountain_breakup_noise =
			core.get_value_noise({
				offset = 0,
				scale = 1,

				spread = {
					x = 900,
					y = 900,
					z = 900
				},

				seed = 8123,
				octaves = 2,
				persist = 0.5,
				lacunarity = 2.0
			})

		lottmapgen.secondary_ridge_noise =
			core.get_value_noise({
				offset = 0,
				scale = 1,

				spread = {
					x = 120,
					y = 120,
					z = 120
				},

				seed = 9341,
				octaves = 3,
				persist = 0.45,
				lacunarity = 2.1
			})
	end

	-- =========================
	-- VOXELMANIP
	-- =========================
	local vm, emin, emax =
		core.get_mapgen_object(
			"voxelmanip"
		)
	local data = vm:get_data()
	local p2data = vm:get_param2_data()
	local area =
		VoxelArea:new({
			MinEdge = emin,
			MaxEdge = emax
		})

	-- =========================
	-- TERRAIN PASS
	-- =========================
	-- generate terrain one node beyond the vertical chunk bounds
	-- triggers engine overgeneration
	local terrain_min_y = math.max(
		minp.y - 1,
		emin.y
	)
	local terrain_max_y = math.min(
		maxp.y + 2,
		emax.y
	)

	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do

			local raw_biome_id = lottmapgen.get_raw_biome_id(x, z)
			local biome_id = lottmapgen.get_blended_biome_id(x, z)
			local ground_y = lottmapgen.get_terrain_height(x, z)
			local surface, filler = lottmapgen.get_surface_nodes(biome_id)

			for y = terrain_min_y, terrain_max_y do
				local vi = area:index(x, y, z)
				if y <= ground_y - 4 then
					-- deep geology uses the raw biome
					-- (to prevent awkward columns of stone)
					if raw_biome_id == 113 then
						data[vi] = c_morstone
					else
						data[vi] = c_stone
					end

				elseif y <= ground_y - 1 then
					-- surface layers use the blended biome.
					data[vi] = filler

				elseif y == ground_y
				and ground_y >= lottmapgen.WATER_LEVEL then
					data[vi] = surface

				elseif y <= lottmapgen.WATER_LEVEL then
					data[vi] = c_water
				end
			end
		end
	end

	-- =========================
	-- DECORATION PASS
	-- =========================
	--
	-- happen AFTER terrain.
	-- to prevent columns to erase parts
	-- of trees that extend horizontally.
	--
	-- Decoration ORIGINS belong to this chunk.
	-- The decoration itself may write into the
	-- VoxelManip overgeneration area.

	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			local biome_id =
				lottmapgen.get_blended_biome_id(x, z)

			if biome_id >= 100 then
				local ground_y = lottmapgen.get_terrain_height(x, z)

				-- IN-CHUNK GENERATION
				--
				-- Only this chunk is responsible
				-- for starting decorations whose
				-- surface belongs to this chunk.
				if ground_y >= lottmapgen.WATER_LEVEL
				and ground_y >= minp.y
				and ground_y <= maxp.y then

					lottmapgen.decorate_surface(
						biome_id,
						x,
						ground_y,
						z,
						area,
						data,
						p2data
					)
				end
			end
		end
	end

	-- =========================
	-- UNDERGROUND STRUCTURE PASS
	-- =========================

	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do

			local biome_id = lottmapgen.get_blended_biome_id(x, z)

			if biome_id == 107 and math.random(50000) == 1 then

				local ground_y = lottmapgen.get_terrain_height(x, z)
				local y = ground_y - math.random(5, 40)

				if y >= minp.y
				and y <= maxp.y then

					lottmapgen.enqueue_building(
						"Dwarf House",
						{
							x = x,
							y = y,
							z = z
						}
					)
				end

			elseif biome_id == 106 then
				local ground_y = lottmapgen.get_terrain_height(x, z)

				local min_y =
					math.max(
						minp.y,
						ground_y - 100
					)

				local max_y =
					math.min(
						maxp.y,
						ground_y - 50
					)

				if min_y <= max_y and math.random(10000) == 1 then

					local y = math.random(min_y, max_y)
					lottmapgen_elf_workshop(x, y, z, area, data, p2data)
				end
			end
		end
	end

	-- =========================
	-- WRITE
	-- =========================
	vm:set_data(data)
	vm:set_param2_data(p2data)

	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:update_liquids()
	vm:write_to_map()
end)

-- TEMPORARY -- TO MOVE TO SOMEWHERE MORE SUITABLE LATER
minetest.register_on_joinplayer(function(player)
	-- hide clouds
	player:set_clouds({
		density = 0
	})

	-- shaders
	player:set_lighting({
		saturation = 1.0,

		shadows = {
			intensity = 0.4
		},

		volumetric_light = {
			strength = 0.2
		}
	})
end)