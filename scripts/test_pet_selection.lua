-- Run from the repository root: lua scripts/test_pet_selection.lua
local choose = dofile("pet-selection.luau")
local pets = { "anti-sergio", "cat", "darth-revan", "gordon-freeman", "hollow-knight", "omniman", "squidward", "the-witcher", "whiplash" }
local seen = {}
for _, pet in ipairs(pets) do
	seen[pet] = 0
	assert(choose(pet, "chat-a") == pet)
	assert(choose(pet, "chat-b") == pet)
end

local original = choose("random", "chat-a")
assert(choose("cat", "chat-a") == "cat", "Cached random choice must not override explicit settings")
assert(choose(nil, "chat-a") == original, "Returning to Random must retain the chat's choice")
for i = 1, 1000 do
	local id = "chat-" .. i
	local pet = choose("random", id)
	assert(seen[pet], "Random returned a missing sprite: " .. pet)
	seen[pet] = seen[pet] + 1
	assert(choose("random", id) == pet, "Chat selection changed on another read")
	assert(choose(nil, id) == pet, "Unset settings must use Random")
end
assert(choose("random", "chat-a") == original, "Returning to a chat changed its pet")
for _, pet in ipairs(pets) do
	assert(seen[pet] > 0, "Random never selected " .. pet)
end
assert(choose(nil, nil) == choose("random", nil), "New-chat preview must be stable")
for _, legacy in ipairs({ "ginger", "black", "silver" }) do
	assert(choose(legacy, "chat-a") == "cat", "Legacy cat selection broke")
end
print("Pet selection: stable per-chat distribution, explicit choices, new chats and legacy settings passed.")

local position = dofile("pet-position.luau")
for _, choice in ipairs({ "left", "right", "random", "activity" }) do
	assert(position(choice, nil, 0.37) == nil, "A new-chat draft must not have a pet")
	assert(position(choice, "", 0.37) == nil, "An empty chat ID must not have a pet")
end
assert(position("left", "chat-a", 0.37) == 0)
assert(position("right", "chat-a", 0.37) == 1)
assert(position("random", "chat-a", 0.37) == 0.37)
assert(position(nil, "chat-a", 0.37) == 1, "Unset position must default to Right")
assert(position("activity", "chat-a", 0.37) == 1, "Removed activity setting must fall back to Right")
print("Pet position: existing chats only, left, right, random and default fallback passed.")
