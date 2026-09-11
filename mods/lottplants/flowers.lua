-- FLOWERS

minetest.register_node("lottplants:athelas", {
	description = "Athelas",
	drawtype = "plantlike",
	tiles = { "lottplants_athelas.png" },
	inventory_image = "lottplants_athelas.png",
	wield_image = "lottplants_athelas.png",
	sunlight_propagates = true,
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 2,
	waving = 1,
	drop = {
		max_items = 3,
		items = {
			{ items = {'lottfarming:athelas'} },
			{ items = {'lottfarming:athelas'}, rarity = 5},
		}
	},
	walkable = false,
	buildable_to = true,
	groups = {snappy=3,flammable=2,flora=1,attached_node=1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})

minetest.register_node("lottplants:anemones", {
	description = "Anemones",
	drawtype = "plantlike",
	tiles = { "lottplants_anemones.png" },
	inventory_image = "lottplants_anemones.png",
	wield_image = "lottplants_anemones.png",
	sunlight_propagates = true,
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 40,
	waving = 1,
	walkable = false,
	buildable_to = true,
	drop = {
		max_items = 1,
		items = {
			{ items = {'lottplants:honey'}, rarity = 20},
			{ items = {'lottplants:anemones'} },
		}
	},
	groups = {snappy=3,flammable=2,flower=1,flora=1,attached_node=1,color_blue=1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})

minetest.register_node("lottplants:asphodel", {
	drawtype = "plantlike",
	tiles = { "lottplants_asphodel.png" },
	sunlight_propagates = true,
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 40,
	waving = 1,
	walkable = false,
	buildable_to = true,
	drop = {
		max_items = 1,
		items = {
			{ items = {'lottplants:honey'}, rarity = 20},
			{ items = {'lottplants:asphodel'} },
		}
	},
	groups = {snappy=3,flammable=2,flower=1,flora=1,attached_node=1,color_white=1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})

minetest.register_node("lottplants:eglantive", {
	description = "Eglantive",
	drawtype = "plantlike",
	tiles = { "lottplants_eglantive.png" },
	inventory_image = "lottplants_eglantive.png",
	wield_image = "lottplants_eglantive.png",
	sunlight_propagates = true,
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 40,
	waving = 1,
	walkable = false,
	buildable_to = true,
	drop = {
		max_items = 1,
		items = {
			{ items = {'lottplants:honey'}, rarity = 20},
			{ items = {'lottplants:eglantive'} },
		}
	},
	groups = {snappy=3,flammable=2,flower=1,flora=1,attached_node=1,color_pink=1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})

minetest.register_node("lottplants:elanor", {
	drawtype = "plantlike",
	tiles = { "lottplants_elanor.png" },
	inventory_image = "lottplants_elanor.png",
	wield_image = "lottplants_elanor.png",
	sunlight_propagates = true,
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 10,
	waving = 1,
	walkable = false,
	buildable_to = true,
	drop = {
		max_items = 1,
		items = {
			{ items = {'lottplants:honey'}, rarity = 20},
			{ items = {'lottplants:elanor'} },
		}
	},
	groups = {snappy=3,flammable=2,flower=1,flora=1,attached_node=1,color_yellow=1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})

minetest.register_node("lottplants:iris", {
	description = "Iris",
	drawtype = "plantlike",
	tiles = { "lottplants_iris.png" },
	inventory_image = "lottplants_iris.png",
	wield_image = "lottplants_iris.png",
	sunlight_propagates = true,
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 40,
	waving = 1,
	walkable = false,
	buildable_to = true,
	drop = {
		max_items = 1,
		items = {
			{ items = {'lottplants:honey'}, rarity = 20},
			{ items = {'lottplants:iris'}}
		}
	},
	groups = {snappy=3,flammable=2,flower=1,flora=1,attached_node=1,color_yellow=1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})

minetest.register_node("lottplants:lissuin", {
	description = "Lissuin",
	drawtype = "plantlike",
	tiles = { "lottplants_lissuin.png" },
	inventory_image = "lottplants_lissuin.png",
	wield_image = "lottplants_lissuin.png",
	sunlight_propagates = true,
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 41,
	waving = 1,
	walkable = false,
	buildable_to = true,
	drop = {
		max_items = 1,
		items = {
			{ items = {'lottplants:honey'}, rarity = 20},
			{ items = {'lottplants:lissuin'} },
		}
	},
	groups = {snappy=3,flammable=2,flower=1,flora=1,attached_node=1,color_pink=1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})

minetest.register_node("lottplants:mallos", {
	description = "Mallos",
	drawtype = "plantlike",
	tiles = { "lottplants_mallos.png" },
	inventory_image = "lottplants_mallos.png",
	wield_image = "lottplants_mallos.png",
	sunlight_propagates = true,
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 42,
	waving = 1,
	walkable = false,
	buildable_to = true,
	drop = {
		max_items = 1,
		items = {
			{ items = {'lottplants:honey'}, rarity = 20},
			{ items = {'lottplants:mallos'} },
		}
	},
	groups = {snappy=3,flammable=2,flower=1,flora=1,attached_node=1,color_yellow=1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})

minetest.register_node("lottplants:niphredil", {
	description = "Niphredil",
	drawtype = "plantlike",
	tiles = { "lottplants_niphredil.png" },
	inventory_image = "lottplants_niphredil.png",
	wield_image = "lottplants_niphredil.png",
	sunlight_propagates = true,
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 8,
	waving = 1,
	walkable = false,
	buildable_to = true,
	drop = {
		max_items = 1,
		items = {
			{ items = {'lottplants:honey'}, rarity = 20},
			{ items = {'lottplants:niphredil'} },
		}
	},
	groups = {snappy=3,flammable=2,flower=1,flora=1,attached_node=1,color_brown=1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})

minetest.register_node("lottplants:seregon", {
	description = "Seregon",
	drawtype = "plantlike",
	tiles = { "lottplants_seregon.png" },
	inventory_image = "lottplants_seregon.png",
	wield_image = "lottplants_seregon.png",
	sunlight_propagates = true,
	paramtype = "light",
	paramtype2 = "meshoptions",
	place_param2 = 40,
	waving = 1,
	walkable = false,
	buildable_to = true,
	drop = {
		max_items = 2,
		items = {
			{ items = {'lottplants:seregon'} },
			{ items = {'lottplants:honey'}, rarity = 20},
		}
	},
	groups = {snappy=3,flammable=2,flower=1,flora=1,attached_node=1,color_red=1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})

minetest.register_alias("lottplants:anemones_fake", "lottplants:anemones")
minetest.register_alias("lottplants:asphodel_fake", "lottplants:asphodel")
minetest.register_alias("lottplants:eglantive_fake", "lottplants:eglantive")
minetest.register_alias("lottplants:elanor_fake", "lottplants:elanor")
minetest.register_alias("lottplants:iris_fake", "lottplants:iris")
minetest.register_alias("lottplants:lissuin_fake", "lottplants:lissuin")
minetest.register_alias("lottplants:mallos_fake", "lottplants:mallos")
minetest.register_alias("lottplants:niphredil_fake", "lottplants:niphredil")
minetest.register_alias("lottplants:seregon_fake", "lottplants:seregon")

-- from minetest_game flowers
minetest.register_node("lottplants:dandelion_white", {
	description = "White Dandelion",
	drawtype = "plantlike",
	tiles = { "lottplants_dandelion_white.png" },
	inventory_image = "lottplants_dandelion_white.png",
	wield_image = "lottplants_dandelion_white.png",
	sunlight_propagates = true,
	paramtype = "light",
	walkable = false,
	buildable_to = true,
    drop = {
		max_items = 2,
		items = {
			{ items = {'lottplants:dandelion_white'} },
			{ items = {'lottplants:honey'}, rarity = 20},
		}
	},
	groups = {snappy=3,flammable=2,flower=1,flora=1,attached_node=1,color_white=1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})

minetest.register_node("lottplants:dandelion_yellow", {
	description = "Yellow Dandelion",
	drawtype = "plantlike",
	tiles = { "lottplants_dandelion_yellow.png" },
	inventory_image = "lottplants_dandelion_yellow.png",
	wield_image = "lottplants_dandelion_yellow.png",
	sunlight_propagates = true,
	paramtype = "light",
	walkable = false,
	buildable_to = true,
    drop = {
		max_items = 2,
		items = {
			{ items = {'lottplants:dandelion_yellow'} },
			{ items = {'lottplants:honey'}, rarity = 20},
		}
	},
	groups = {snappy=3,flammable=2,flower=1,flora=1,attached_node=1,color_yellow=1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})

minetest.register_node("lottplants:geranium", {
	description = "Blue Geranium",
	drawtype = "plantlike",
	tiles = { "lottplants_geranium.png" },
	inventory_image = "lottplants_geranium.png",
	wield_image = "lottplants_geranium.png",
	sunlight_propagates = true,
	paramtype = "light",
	walkable = false,
	buildable_to = true,
    drop = {
		max_items = 2,
		items = {
			{ items = {'lottplants:geranium'} },
			{ items = {'lottplants:honey'}, rarity = 20},
		}
	},
	groups = {snappy=3,flammable=2,flower=1,flora=1,attached_node=1,color_blue=1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})

minetest.register_node("lottplants:rose", {
	description = "Rose",
	drawtype = "plantlike",
	tiles = { "lottplants_rose.png" },
	inventory_image = "lottplants_rose.png",
	wield_image = "lottplants_rose.png",
	sunlight_propagates = true,
	paramtype = "light",
	walkable = false,
	buildable_to = true,
    drop = {
		max_items = 2,
		items = {
			{ items = {'lottplants:rose'} },
			{ items = {'lottplants:honey'}, rarity = 20},
		}
	},
	groups = {snappy=3,flammable=2,flower=1,flora=1,attached_node=1,color_red=1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})

minetest.register_node("lottplants:tulip", {
	description = "Tulip",
	drawtype = "plantlike",
	tiles = { "lottplants_tulip.png" },
	inventory_image = "lottplants_tulip.png",
	wield_image = "lottplants_tulip.png",
	sunlight_propagates = true,
	paramtype = "light",
	walkable = false,
	buildable_to = true,
    drop = {
		max_items = 2,
		items = {
			{ items = {'lottplants:tulip'} },
			{ items = {'lottplants:honey'}, rarity = 20},
		}
	},
	groups = {snappy=3,flammable=2,flower=1,flora=1,attached_node=1,color_orange=1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})

minetest.register_node("lottplants:viola", {
	description = "Viola",
	drawtype = "plantlike",
	tiles = { "lottplants_viola.png" },
	inventory_image = "lottplants_viola.png",
	wield_image = "lottplants_viola.png",
	sunlight_propagates = true,
	paramtype = "light",
	walkable = false,
	buildable_to = true,
    drop = {
		max_items = 2,
		items = {
			{ items = {'lottplants:viola'} },
			{ items = {'lottplants:honey'}, rarity = 20},
		}
	},
	groups = {snappy=3,flammable=2,flower=1,flora=1,attached_node=1,color_violet=1},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15, 0.2, 0.15 },
	},
})