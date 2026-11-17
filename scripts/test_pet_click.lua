-- Exercise the runtime's click lookup with every scheduled character and a normal pet.
local file = assert(io.open("init.luau"))
local source = file:read("*a")
file:close()
local selected
local scheduled = {}
for motion, pet in source:gmatch('motion = (%u+), range = { %d+, %d+ }, pet = "([^"]+)"') do
	scheduled[#scheduled + 1] = { pet = pet, motion = { motion } }
end
assert(#scheduled == 4, "Expected four special animations")
local body = assert(source:match('local function click_motion%(%)%:.-\n(.-)\n\tend'))
body = body:gsub('in EVERY do', 'in ipairs(EVERY) do')
local factory = assert((loadstring or load)(
	'return function(EVERY, selected_pet) return function()\n' .. body .. '\nend end'
))()
local lookup = factory(scheduled, function() return selected end)
for _, each in ipairs(scheduled) do
	selected = each.pet
	assert(lookup() == each.motion, "Click selected the wrong animation for " .. selected)
end
selected = "cat"
assert(lookup() == nil, "Normal pets must remain noninteractive")
print("Pet click: all four special animations and noninteractive fallback passed.")
