return function(configured, session_id, random)
	if configured == "left" then
		return 0
	elseif configured == "random" then
		return random
	end
	return 1
end
