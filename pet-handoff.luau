-- Keep a draft's randomly chosen pet when it becomes a newly created chat.
return function(choose, load, save)
	local preview, existing
	local assigned = {}
	return function(configured, session_id, random, sessions)
		if configured ~= nil and configured ~= "random" then
			preview, existing = nil, nil
			return choose(configured, session_id, random)
		end
		if session_id == nil or session_id == "" then
			if preview == nil then
				preview = choose(configured, nil, random)
				existing = {}
				for id in pairs(sessions()) do
					existing[id] = true
				end
			end
			return preview
		end
		local inherited = assigned[session_id] or load(session_id)
		if preview ~= nil then
			if not existing[session_id] and inherited == nil then
				inherited = { pet = preview, configured = "random" }
				assigned[session_id] = inherited
				save(session_id, inherited)
			end
			preview, existing = nil, nil
		end
		if inherited and inherited.configured == "random" then
			return choose(inherited.pet, session_id, random)
		end
		return choose(configured, session_id, random)
	end
end
