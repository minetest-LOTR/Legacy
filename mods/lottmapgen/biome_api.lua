-- =========================
-- BIOME REGISTRY
-- =========================
lottmapgen.biome = {
	registered = {}
}

function lottmapgen.biome.register(def)
	assert(def.id, "Biome requires an id")

	if lottmapgen.biome.registered[def.id] then
		error("Biome ID " .. def.id .. " already registered")
	end

	-- Defaults
	def.top_node = def.top_node or "default:dirt_with_grass"
	def.filler_node = def.filler_node or "default:dirt"

	-- Resolve content IDs once
	def.c_top = core.get_content_id(def.top_node)
	def.c_filler = core.get_content_id(def.filler_node)

	lottmapgen.biome.registered[def.id] = def
end

function lottmapgen.biome.get(id)
	return lottmapgen.biome.registered[id]
end