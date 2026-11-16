-- A chat ID supplies a stable pseudo-random choice, including after reopening.
local pets = { "anti-sergio", "cat", "darth-revan", "gordon-freeman", "hollow-knight", "omniman", "squidward", "the-witcher", "whiplash" }

return function(configured, session_id)
	if configured == nil or configured == "random" then
		local key = session_id or "new-chat"
		local hash = 5381
		for i = 1, #key do
			hash = (hash * 33 + string.byte(key, i)) % 2147483647
		end
		return pets[hash % #pets + 1]
	end
	if configured == "ginger" or configured == "black" or configured == "silver" then
		return "cat"
	end
	return configured
end
