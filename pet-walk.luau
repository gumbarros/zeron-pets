-- Advance in display pixels; clamp after resizing and turn at either edge.
return function(x, direction, phase, width, sprite_width)
	local limit = math.max(0, width - sprite_width)
	x = math.max(0, math.min(limit, x))
	if limit == 0 then
		return 0, direction, 0, 0
	end
	if phase == 0 and math.random() < 0.15 then
		direction = -direction
	end
	x = x + direction * 3
	if x >= limit then
		x, direction = limit, -1
	elseif x <= 0 then
		x, direction = 0, 1
	end
	phase = (phase + 1) % 6
	local bob = (phase == 1 or phase == 2 or phase == 4 or phase == 5) and 2 or 0
	return x, direction, phase, bob
end
