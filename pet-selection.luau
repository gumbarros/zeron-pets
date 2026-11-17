-- A chat ID supplies a stable pseudo-random choice, including after reopening.
local pets = { "otis", "bergamini-cow", "anti-sergio", "cat", "darth-revan", "ellie", "ezio", "gordon-freeman", "hollow-knight", "joel", "kratos", "la-casa-de-papel", "omniman", "squidward", "the-witcher", "whiplash", "silksong", "zombie", "ornstein-smough", "creeper", "grand-admiral-thrawn", "jak-and-daxter" }
-- Rendering reads the same chat repeatedly; keep only its last choice.
local last_key, last_pet

return function(configured, session_id, preview_random)
	if session_id == nil or session_id == "" then
		return pets[math.floor((preview_random or 0) * #pets) + 1]
	end
	if configured == nil or configured == "random" then
		local key = session_id
		if key == last_key then
			return last_pet
		end
		local hash = 5381
		for i = 1, #key do
			hash = (hash * 33 + string.byte(key, i)) % 2147483647
		end
		last_key, last_pet = key, pets[hash % #pets + 1]
		return last_pet
	end
	if configured == "ginger" or configured == "black" or configured == "silver" then
		return "cat"
	end
	return configured == "hornet" and "silksong" or configured
end
