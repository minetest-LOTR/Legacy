minetest.register_node("lottplants:mushroom_red", {
	description = "Red Mushroom",
	tiles = {"lottplants_mushroom_red.png"},
	inventory_image = "lottplants_mushroom_red.png",
	wield_image = "lottplants_mushroom_red.png",
	drawtype = "plantlike",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	buildable_to = true,
	groups = {snappy = 3, attached_node = 1, flammable = 1},
	sounds = default.node_sound_leaves_defaults(),
	on_use = minetest.item_eat(-5),
	selection_box = {
		type = "fixed",
		fixed = {-4 / 16, -0.5, -4 / 16, 4 / 16, -1 / 16, 4 / 16},
	}
})

minetest.register_node("lottplants:mushroom_brown", {
	description = "Brown Mushroom",
	tiles = {"lottplants_mushroom_brown.png"},
	inventory_image = "lottplants_mushroom_brown.png",
	wield_image = "lottplants_mushroom_brown.png",
	drawtype = "plantlike",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	buildable_to = true,
	groups = {snappy = 3, attached_node = 1, flammable = 1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {-3 / 16, -0.5, -3 / 16, 3 / 16, -2 / 16, 3 / 16},
	}
})

minetest.register_node("lottplants:mushroom_white", {
	description = "White Mushroom",
	tiles = {"lottplants_mushroom_white.png"},
	inventory_image = "lottplants_mushroom_white.png",
	wield_image = "lottplants_mushroom_white.png",
	drawtype = "plantlike",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	buildable_to = true,
	groups = {snappy = 3, attached_node = 1, flammable = 1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {-3 / 16, -0.5, -3 / 16, 3 / 16, -2 / 16, 3 / 16},
	}
})

minetest.register_node("lottplants:mushroom_blue", {
	description = "Blue Mushroom",
	tiles = {"lottplants_mushroom_blue.png"},
	inventory_image = "lottplants_mushroom_blue.png",
	wield_image = "lottplants_mushroom_blue.png",
	drawtype = "plantlike",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	buildable_to = true,
	light_source = 4,
	groups = {snappy = 3, attached_node = 1, flammable = 1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {-3 / 16, -0.5, -3 / 16, 3 / 16, -2 / 16, 3 / 16},
	}
})

minetest.register_node("lottplants:mushroom_green", {
	description = "Green Mushroom",
	tiles = {"lottplants_mushroom_green.png"},
	inventory_image = "lottplants_mushroom_green.png",
	wield_image = "lottplants_mushroom_green.png",
	drawtype = "plantlike",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	buildable_to = true,
	light_source = 3,
	groups = {snappy = 3, attached_node = 1, flammable = 1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {-3 / 16, -0.5, -3 / 16, 3 / 16, -2 / 16, 3 / 16},
	}
})