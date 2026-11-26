-- Exercise the runtime's click lookup with every scheduled character and a normal pet.
local file = assert(io.open("init.luau"))
local source = file:read("*a")
file:close()
local selected
local scheduled = {}
for motion, pet in source:gmatch('motion = (%u+), range = { %d+, %d+ }, pet = "([^"]+)"') do
	scheduled[#scheduled + 1] = { pet = pet, motion = { motion } }
end
assert(#scheduled == 9, "Expected nine special animations")
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
print("Pet click: all nine special animations and noninteractive fallback passed.")

-- Inert pets must not inherit the button's disabled opacity.
assert(not source:find("disabled =", 1, true), "Disabled buttons dim decorative pets")
assert(source:find("focusable = interactive", 1, true), "Only interactive pets should take keyboard focus")

local applies = assert(source:match("local function applies_to.-\n(.-)\nend"))
local effect_source = assert(source:match("ui.effect%(function%(%)\n(.-)\n\tend%)"))
effect_source = effect_source:gsub("in EVERY do", "in ipairs(EVERY) do")
local blink = {}
scheduled[#scheduled + 1] = { motion = blink }
scheduled[#scheduled + 1] = { motion = {} }
scheduled[#scheduled + 1] = { motion = {} }
local no_motion, active, resets, played = false, {}, 0
local ui = { after = function(_, turn)
	active[turn] = true
	return function() active[turn] = nil end
end }
local schedule = assert((loadstring or load)([[
return function(EVERY, BLINK, ui, selected_pet, reduced, cancel_steps, play)
	local scheduled_pet, scheduled_reduced, turns = nil, nil, {}
	local function applies_to(each, pet)
]] .. applies .. [[

	end
	local function cancel_turns()
		for _, cancel in pairs(turns) do cancel() end
		turns = {}
	end
	local frame = { set = function(_, name) assert(name == "idle") end }
	local function within() return 0 end
	return function()
]] .. effect_source .. "\nend end"))()
local update = schedule(scheduled, blink, ui, function() return selected end,
	function() return no_motion end, function() resets = resets + 1 end,
	function(motion) played = motion end)
local function count_turns()
	local count = 0
	for _ in pairs(active) do count = count + 1 end
	return count
end
update()
assert(count_turns() == 3, "A regular pet needs only its three common timers")
update()
assert(count_turns() == 3 and resets == 1, "An unrelated update must keep the schedule")
selected = "whiplash"
update()
assert(count_turns() == 2 and resets == 2, "Fletcher needs blink and throw only")
local turn = next(active)
active[turn] = nil
turn()
assert(played and count_turns() == 2, "Each scheduled motion must re-arm once")
selected = "squidward"
update()
assert(count_turns() == 4 and resets == 3, "A special animation adds one timer")
no_motion = true
update()
assert(count_turns() == 0 and resets == 4, "Reduce Motion must cancel pending turns and frames")
no_motion = false
update()
assert(count_turns() == 4 and resets == 5, "Turning motion back on must restore the schedule")
print("Pet scheduler: eligible timers, re-arming, pet changes and Reduce Motion passed.")
