
-- dig directionally
local function dig_dir(pos, nodes, dir, digger)
	local np = {x = pos.x, y = pos.y + dir, z = pos.z}
	local nn = minetest.get_node(np)
	for i=1,#nodes do
		if nn.name == nodes[i] then
			if digger == nil then
				minetest.remove_node(np)
			else
				minetest.node_dig(np, nn, digger)
			end
		end
	end
end

lottblocks.register_stalagmites = function(base_node, drop)
	local base_definition = minetest.registered_nodes[base_node]
	local sname = string.match(base_node, ':(.*)')
	local base_description = base_definition.description
	local groups = table.copy(base_definition.groups)
	groups.loot = nil
	local sounds = base_definition.sounds
	local box_floor = {
		type = "fixed",
		fixed = {
			{-4/16, -8/16, -4/16, 4/16, 2/16, 4/16},
		},
	}
	local box_ceiling = {
		type = "fixed",
		fixed = {
			{-4/16, -2/16, -4/16, 4/16, 8/16, 4/16},
		},
	}
	local box_big = {
		type = "fixed",
		fixed = {
			{-6/16, -8/16, -6/16, 6/16, 8/16, 6/16},
		},
	}
	drop = drop or "default:" .. sname
	for i=1,5 do
		minetest.register_node("lottblocks:stalagmite_" .. sname .. "_" .. i, {
			description = (base_description .. " Stalagmite"),
			drawtype = "plantlike",
			tiles = {"lottblocks_stalagmites_" .. sname .. ".png^[sheet:13x1:" .. i+4 .. ",0"},
			inventory_image = "lottblocks_stalagmites_" .. sname .. ".png^[sheet:13x1:" .. i+4 .. ",0",
			visual_scale = 2.0,
			sunlight_propagates = true,
			paramtype = "light",
			use_texture_alpha = "blend",
			floodable = true,
			drop = {
				items = {
					{
						rarity = 1,
						items = {drop},
					},
					{
						rarity = 2,
						items = {drop},
					},
					{
						rarity = 3,
						items = {drop},
					},
				},
			},
			collision_box = box_floor,
			selection_box = box_floor,
			groups = groups,
			sounds = sounds,
		})
		minetest.register_node("lottblocks:stalactite_" .. sname .. "_" .. i, {
			description = (base_description .. " Stalactite"),
			drawtype = "mesh",
			mesh = "lottblocks_stalactite.obj",
			tiles = {"lottblocks_stalagmites_" .. sname .. ".png^[sheet:13x1:" .. i-1 .. ",0"},
			inventory_image = "lottblocks_stalagmites_" .. sname .. ".png^[sheet:13x1:" .. i-1 .. ",0",
			sunlight_propagates = true,
			paramtype = "light",
			use_texture_alpha = "blend",
			floodable = true,
			drop = {
				items = {
					{
						rarity = 1,
						items = {drop},
					},
					{
						rarity = 2,
						items = {drop},
					},
					{
						rarity = 3,
						items = {drop},
					},
				},
			},
			collision_box = box_ceiling,
			selection_box = box_ceiling,
			groups = groups,
			sounds = sounds,
		})
	end
	minetest.register_node("lottblocks:stalagmite_base_" .. sname, {
		description = (base_description .. " Stalagmite"),
		drawtype = "plantlike",
		tiles = {"lottblocks_stalagmites_" .. sname .. ".png^[sheet:13x1:11,0"},
		inventory_image = "lottblocks_stalagmites_" .. sname .. ".png^[sheet:13x1:11,0",
		sunlight_propagates = true,
		paramtype = "light",
		use_texture_alpha = "blend",
		visual_scale = 2,
		floodable = true,
		drop = {
			items = {
				{
					rarity = 1,
					items = {drop},
				},
				{
					rarity = 2,
					items = {drop},
				},
				{
					rarity = 3,
					items = {drop},
				},
			},
		},
		collision_box = box_big,
		selection_box = box_big,
		groups = groups,
		sounds = sounds,
		on_flood = function(pos)
			dig_dir(pos, {"lottblocks:stalagmite_middle_" .. sname, "lottblocks:stalagmite_top_" .. sname}, 1)
		end,
		after_dig_node = function(pos, node, metadata, digger)
			dig_dir(pos, {"lottblocks:stalagmite_middle_" .. sname, "lottblocks:stalagmite_top_" .. sname}, 1, digger)
		end,
		after_destruct = function(pos)
			dig_dir(pos, {"lottblocks:stalagmite_middle_" .. sname, "lottblocks:stalagmite_top_" .. sname}, 1)
		end,
	})
	minetest.register_node("lottblocks:stalactite_base_" .. sname, {
		description = (base_description .. " Stalactite"),
		drawtype = "plantlike",
		tiles = {"lottblocks_stalagmites_" .. sname .. ".png^[sheet:26x2:20,0"},
		inventory_image = "lottblocks_stalagmites_" .. sname .. ".png^[sheet:26x2:20,0",
		sunlight_propagates = true,
		paramtype = "light",
		use_texture_alpha = "blend",
		floodable = true,
		drop = {
			items = {
				{
					rarity = 1,
					items = {drop},
				},
				{
					rarity = 2,
					items = {drop},
				},
				{
					rarity = 3,
					items = {drop},
				},
			},
		},
		collision_box = box_big,
		selection_box = box_big,
		groups = groups,
		sounds = sounds,
		on_flood = function(pos)
			dig_dir(pos, {"lottblocks:stalactite_middle_" .. sname, "lottblocks:stalactite_top_" .. sname}, -1)
		end,
		after_dig_node = function(pos, node, metadata, digger)
			dig_dir(pos, {"lottblocks:stalactite_middle_" .. sname, "lottblocks:stalactite_top_" .. sname}, -1, digger)
		end,
		after_destruct = function(pos)
			dig_dir(pos, {"lottblocks:stalactite_middle_" .. sname, "lottblocks:stalactite_top_" .. sname}, -1)
		end,
	})
	minetest.register_node("lottblocks:stalagmite_middle_" .. sname, {
		description = (base_description .. " Stalagmite"),
		drawtype = "plantlike",
		tiles = {"lottblocks_stalagmites_" .. sname .. ".png^[sheet:26x2:24,1"},
		inventory_image = "lottblocks_stalagmites_" .. sname .. ".png^[sheet:26x2:24,1",
		sunlight_propagates = true,
		paramtype = "light",
		use_texture_alpha = "blend",
		floodable = true,
		drop = {
			items = {
				{
					rarity = 1,
					items = {drop},
				},
				{
					rarity = 2,
					items = {drop},
				},
				{
					rarity = 3,
					items = {drop},
				},
			},
		},
		collision_box = box_big,
		selection_box = box_big,
		groups = groups,
		sounds = sounds,
		on_flood = function(pos)
			dig_dir(pos, {"lottblocks:stalagmite_middle_" .. sname, "lottblocks:stalagmite_top_" .. sname}, 1)
		end,
		after_dig_node = function(pos, node, metadata, digger)
			dig_dir(pos, {"lottblocks:stalagmite_middle_" .. sname, "lottblocks:stalagmite_top_" .. sname}, 1, digger)
		end,
		after_destruct = function(pos)
			dig_dir(pos, {"lottblocks:stalagmite_middle_" .. sname, "lottblocks:stalagmite_top_" .. sname}, 1)
		end,
	})
	minetest.register_node("lottblocks:stalactite_middle_" .. sname, {
		description = (base_description .. " Stalactite"),
		drawtype = "plantlike",
		tiles = {"lottblocks_stalagmites_" .. sname .. ".png^[sheet:26x2:25,0"},
		inventory_image = "lottblocks_stalagmites_" .. sname .. ".png^[sheet:26x2:25,0",
		sunlight_propagates = true,
		paramtype = "light",
		use_texture_alpha = "blend",
		floodable = true,
		drop = {
			items = {
				{
					rarity = 1,
					items = {drop},
				},
				{
					rarity = 2,
					items = {drop},
				},
				{
					rarity = 3,
					items = {drop},
				},
			},
		},
		collision_box = box_big,
		selection_box = box_big,
		groups = groups,
		sounds = sounds,
		on_flood = function(pos)
			dig_dir(pos, {"lottblocks:stalactite_middle_" .. sname, "lottblocks:stalactite_top_" .. sname}, -1)
		end,
		after_dig_node = function(pos, node, metadata, digger)
			dig_dir(pos, {"lottblocks:stalactite_middle_" .. sname, "lottblocks:stalactite_top_" .. sname}, -1, digger)
		end,
		after_destruct = function(pos)
			dig_dir(pos, {"lottblocks:stalactite_middle_" .. sname, "lottblocks:stalactite_top_" .. sname}, -1)
		end,
	})
	minetest.register_node("lottblocks:stalagmite_top_" .. sname, {
		description = (base_description .. " Stalagmite"),
		drawtype = "plantlike",
		tiles = {"lottblocks_stalagmites_" .. sname .. ".png^[sheet:26x2:24,0"},
		inventory_image = "lottblocks_stalagmites_" .. sname .. ".png^[sheet:26x2:24,0",
		sunlight_propagates = true,
		paramtype = "light",
		use_texture_alpha = "blend",
		floodable = true,
		drop = {
			items = {
				{
					rarity = 1,
					items = {drop},
				},
				{
					rarity = 2,
					items = {drop},
				},
				{
					rarity = 3,
					items = {drop},
				},
			},
		},
		collision_box = box_big,
		selection_box = box_big,
		groups = groups,
		sounds = sounds,
	})
	minetest.register_node("lottblocks:stalactite_top_" .. sname, {
		description = (base_description .. " Stalactite"),
		drawtype = "plantlike",
		tiles = {"lottblocks_stalagmites_" .. sname .. ".png^[sheet:26x2:25,1"},
		inventory_image = "lottblocks_stalagmites_" .. sname .. ".png^[sheet:26x2:25,1",
		sunlight_propagates = true,
		paramtype = "light",
		use_texture_alpha = "blend",
		floodable = true,
		drop = {
			items = {
				{
					rarity = 1,
					items = {drop},
				},
				{
					rarity = 2,
					items = {drop},
				},
				{
					rarity = 3,
					items = {drop},
				},
			},
		},
		collision_box = box_big,
		selection_box = box_big,
		groups = groups,
		sounds = sounds,
	})
end

lottblocks.register_stalagmites("default:stone")
--blocks.register_stalagmites("lottblocks:obsidian", "lottblocks:obsidian_shard")
--blocks.register_stalagmites("lottblocks:sandstone", "lottblocks:sand")
--blocks.register_stalagmites("lottblocks:desert_sandstone", "lottblocks:desert_sand")
--blocks.register_stalagmites("lottblocks:silver_sandstone", "lottblocks:silver_sand")
--blocks.register_stalagmites("lottblocks:desert_stone")
--blocks.register_stalagmites("lottblocks:granite")
--blocks.register_stalagmites("lottblocks:marble")
--blocks.register_stalagmites("lottblocks:basalt")
--blocks.register_stalagmites("lottblocks:ice", "lottblocks:snow")
