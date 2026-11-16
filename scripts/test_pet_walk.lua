local walk = dofile("pet-walk.luau")
local random = math.random
math.random = function() return 0 end
local x, direction = walk(84, 1, 0, 600, 80)
assert(x == 81 and direction == -1, "Random turn must walk left at the slower speed")
x, direction = walk(x, direction, 0, 600, 80)
assert(x == 84 and direction == 1, "Random turn must also walk right")
x, direction = walk(x, direction, 1, 600, 80)
assert(x == 87 and direction == 1, "Only consider random turns once per step cycle")
math.random = function() return 1 end
for _, sprite in ipairs({80, 128}) do
	local x, direction, phase, bob = 84, 1, 0, 0
	local left, right, lifted, planted = false, false, false, false
	for _ = 1, 2000 do
		x, direction, phase, bob = walk(x, direction, phase, 600, sprite)
		assert(x >= 0 and x <= 600 - sprite)
		assert(bob == 0 or bob == 2)
		left = left or x == 0
		right = right or x == 600 - sprite
		lifted = lifted or bob == 2
		planted = planted or bob == 0
	end
	assert(left and right and lifted and planted)
	for _, width in ipairs({200, 50, 0, 700}) do
		x, direction, phase, bob = walk(x, direction, phase, width, sprite)
		assert(x >= 0 and x <= math.max(0, width - sprite))
		if width <= sprite then assert(x == 0 and bob == 0) end
	end
end
math.random = random
print("Pet walking: both edges, step animation, resizing and narrow composers passed.")
