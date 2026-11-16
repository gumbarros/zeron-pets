-- No pet belongs to an unsent new-chat draft.
return function(configured, session_id, random)
	if session_id == nil or session_id == "" then
		return nil
	end
	if configured == "left" then
		return 0
	elseif configured == "random" then
		return random
	end
	return 1
end
