local walk = dofile("pet-walk.luau")
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
print("Pet walking: both edges, step animation, resizing and narrow composers passed.")
