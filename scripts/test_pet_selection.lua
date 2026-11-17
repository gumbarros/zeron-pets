-- Run from the repository root: lua scripts/test_pet_selection.lua
local choose = dofile("pet-selection.luau")
local pets = { "bergamini-cow", "anti-sergio", "cat", "darth-revan", "ellie", "ezio", "gordon-freeman", "hollow-knight", "joel", "kratos", "la-casa-de-papel", "omniman", "squidward", "the-witcher", "whiplash", "silksong", "zombie", "ornstein-smough", "creeper", "grand-admiral-thrawn", "jak-and-daxter" }
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
for i, pet in ipairs(pets) do
	local random = (i - 0.5) / #pets
	for _, id in ipairs({ false, "" }) do
		assert(choose("cat", id or nil, random) == pet, "New-chat preview must ignore the configured pet")
		assert(choose("random", id or nil, random) == pet, "New-chat preview must keep its random pet")
	end
end
for _, legacy in ipairs({ "ginger", "black", "silver" }) do
	assert(choose(legacy, "chat-a") == "cat", "Legacy cat selection broke")
end
print("Pet selection: stable per-chat distribution, explicit choices, new chats and legacy settings passed.")

local position = dofile("pet-position.luau")
for _, id in ipairs({ false, "" }) do
	assert(position("left", id or nil, 0.37) == 0)
	assert(position("right", id or nil, 0.37) == 1)
	assert(position("random", id or nil, 0.37) == 0.37)
end
assert(position("left", "chat-a", 0.37) == 0)
assert(position("right", "chat-a", 0.37) == 1)
assert(position("random", "chat-a", 0.37) == 0.37)
assert(position(nil, "chat-a", 0.37) == 1, "Unset position must default to Right")
assert(position("activity", "chat-a", 0.37) == 1, "Removed activity setting must fall back to Right")
print("Pet position: new and existing chats, left, right, random and default fallback passed.")

local handoff = dofile("pet-handoff.luau")
local saved = {}
local function new_selector()
	return handoff(choose, function(id) return saved[id] end, function(id, pet) saved[id] = pet end)
end
local select = new_selector()
local existing = { ["chat-a"] = {} }
local preview = select("cat", nil, 0.01, existing)
assert(select("cat", "", 0.99, existing) == preview, "Preview changed during rendering")
assert(select("cat", "created", 0.99, existing) == preview, "Starting a chat replaced its preview")
assert(select("cat", "chat-a", 0.5, existing) == "cat", "Existing chat setting changed")
assert(select("cat", "created", 0.5, existing) == preview, "Returning to a chat lost its pet")
assert(new_selector()("cat", "created", 0.5, existing) == preview, "Restart lost the inherited pet")
assert(select("omniman", "created", 0.5, existing) == "omniman", "Changing settings must override inheritance")
select("cat", nil, 0.01, existing)
assert(select("cat", "chat-a", 0.5, existing) == "cat", "Navigating from a draft overwrote an existing chat")
assert(saved["chat-a"] == nil, "Existing chat must not inherit a draft pet")
for _, configured in ipairs({ "random", false }) do
	local id = "created-" .. tostring(configured)
	local pet = select(configured or nil, nil, 0.99, existing)
	assert(select(configured or nil, id, 0.01, existing) == pet)
	assert(new_selector()(configured or nil, id, 0.5, existing) == pet)
end
print("Pet handoff: creation, reopening, restart, setting changes and existing-chat navigation passed.")

local delayed = handoff(choose, function() return nil end, function() end)
local delayed_pet = delayed("cat", nil, 0.01, {})
assert(delayed("cat", "pending-save", 0.99, {}) == delayed_pet)
assert(delayed("cat", "pending-save", 0.99, {}) == delayed_pet, "Pending persistence must not cause a pet switch")

assert(choose("hornet", "chat-a") == "silksong", "Legacy Hornet setting must resolve to Silksong")
local legacy = handoff(choose, function() return { pet = "hornet", configured = "random" } end, function() end)
assert(legacy("random", "legacy-chat", 0.5, {}) == "silksong", "Saved Hornet pet must resolve to Silksong")
