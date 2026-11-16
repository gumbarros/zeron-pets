-- Zeron Pets: animated pixel companions on the message box.
-- Character-specific gags share the same bounded animation scheduler.

local zeron = require("./zeron")("zeron-pets")
local choose_pet = require("./pet-selection")
local pet_position = require("./pet-position")
local pet_handoff = require("./pet-handoff")
local pet_setting = zeron.setting("pet")
local position_setting = zeron.setting("position")

-- The sprite's grid, a pixel's size (points), and where it sits: its
-- outline's last row over the pill's top edge.
local GRID_W, GRID_H, PIXEL = 40, 48, 2
local FOOT = 46 * PIXEL
local LARGE_W, LARGE_H, LARGE_FOOT = 64, 64, 62
local GAG_W, GAG_H, GAG_FOOT = 96, 80, 78

-- Each motion: its frames and how long each shows (ms), back to idle after.
local BLINK = { { "blink", 140 } }
local FLICK = { { "tail-out", 130 }, { "idle", 90 }, { "tail-over", 130 }, { "idle", 90 }, { "tail-out", 110 } }
local TWITCH = { { "ear", 120 }, { "idle", 80 }, { "ear", 120 } }
local THROW = {
	{ "windup", 220 }, { "lift", 180 }, { "release", 100 },
	{ "flight", 120 }, { "follow-through", 180 }, { "recover", 200 },
}
local DOG = { { "dog-arrive", 350 }, { "dog-pet", 2600 }, { "dog-leave", 450 } }
local DESTROY = {
	{ "machine-01", 500 },
	{ "machine-02", 1000 },
	{ "machine-03", 500 },
	{ "machine-04", 170 },
	{ "machine-05", 100 },
	{ "machine-06", 100 },
	{ "machine-07", 100 },
	{ "machine-05", 100 },
	{ "machine-06", 100 },
	{ "machine-07", 100 },
	{ "machine-05", 100 },
	{ "machine-06", 100 },
	{ "machine-07", 100 },
	{ "machine-05", 100 },
	{ "machine-06", 100 },
	{ "machine-07", 100 },
	{ "machine-05", 100 },
	{ "machine-06", 100 },
	{ "machine-07", 100 },
	{ "machine-08", 500 },
	{ "machine-09", 500 },
	{ "machine-10", 500 },
	{ "machine-11", 660 },
	{ "machine-12", 670 },
	{ "machine-13", 330 },
	{ "machine-14", 500 },
	{ "machine-15", 500 },
	{ "machine-16", 500 },
	{ "machine-17", 500 },
	{ "machine-18", 500 },
	{ "machine-19", 570 },
	{ "machine-20", 30 },
}
-- How often each comes (seconds, a range).
local EVERY = {
	{ motion = BLINK, range = { 2, 4 } },
	{ motion = FLICK, range = { 3, 6 } },
	{ motion = TWITCH, range = { 5, 9 } },
	{ motion = THROW, range = { 10, 20 }, pet = "whiplash" },
	{ motion = DOG, range = { 9, 16 }, pet = "anti-sergio" },
	{ motion = DESTROY, range = { 14, 25 }, pet = "squidward" },
}

local function reduced(): boolean
	local p = (ui :: any).prefers
	return p ~= nil and p.reduced_motion ~= nil and p.reduced_motion:peek() == true
end

local function within(range: { number }): number
	return (range[1] + math.random() * (range[2] - range[1])) * 1200
end

-- At most this many timers are ever pending (checked as each motion comes
-- round): one per motion's next turn, and its frames and
-- its end. Fired timers are let go, so a composer left open all day holds
-- no more than at its first minute.
local LONGEST = 0
for _, each in EVERY do
	LONGEST = math.max(LONGEST, #each.motion)
end
local MOST = #EVERY + LONGEST + 1

local function Pet(session: () -> any, select_pet: any): Node
	local preview_random = math.random()
	local function selected_pet(): string
		local current = session()
		return select_pet(pet_setting:get(), if current then current.id else nil, preview_random, zeron.sessions())
	end
	local function large_pet(): boolean
		local pet = selected_pet()
		return pet == "whiplash" or pet == "anti-sergio" or pet == "squidward" or pet == "ornstein-smough"
	end
	local frame = ui.use_state("idle")
	local motion_pet = selected_pet()
	local function gag_playing(): boolean
		return selected_pet() == "squidward" and motion_pet == "squidward" and string.sub(frame:get(), 1, 8) == "machine-"
	end
	-- Each motion's next turn (its one pending timer, replaced as it fires),
	-- and the playing motion's frame timers (let go when it ends).
	local turns: { [number]: (() -> ())? } = {}
	local steps: { () -> () } = {}
	local width = ui.use_state(0)
	local position = ui.use_state(math.random())
	local busy = false
	local gone = false
	local function pending(): number
		local n = #steps
		for i = 1, #EVERY do
			if turns[i] then
				n += 1
			end
		end
		return n
	end
	ui.on_cleanup(function()
		gone = true
		for i = 1, #EVERY do
			local cancel = turns[i]
			if cancel then
				cancel()
			end
		end
		for _, cancel in steps do
			cancel()
		end
	end)
	-- A motion's frames one after another, then idle. (One at a time: one
	-- that comes while another plays waits for its next turn.)
	local function play(motion: { { any } })
		if gone or busy or reduced() then
			return
		end
		busy = true
		motion_pet = selected_pet()
		steps = {}
		local at = 0
		for _, step in motion do
			local name, ms = step[1], step[2]
			table.insert(steps, ui.after(at, function()
				frame:set(name)
			end))
			at += ms
		end
		table.insert(steps, ui.after(at, function()
			frame:set("idle")
			busy = false
			-- (All its timers have fired: none to keep.)
			steps = {}
		end))
	end
	if not reduced() then
		for i, each in EVERY do
			local function turn()
				turns[i] = nil
				local pet = selected_pet()
				if each.pet == pet or (each.pet == nil and (pet ~= "whiplash" or each.motion == BLINK)) then
					play(each.motion)
				end
				turns[i] = ui.after(within(each.range), turn)
				assert(pending() <= MOST, "zeron-pets: timers left pending")
			end
			turns[i] = ui.after(within(each.range), turn)
		end
	end
	return ui.div {
		absolute = true, left = 0, right = 0, top = 0, h = 0,
		pointer_events = "none", aria_hidden = true,
		on_resize = function(size)
			width:set(size.w)
		end,
		ui.image {
			id = "zeron-pets",
			src = function(): string
				local pet = selected_pet()
				local name = if pet == motion_pet then frame:get() else "idle"
				return `art/{pet}/{name}.png`
			end,
			image_rendering = "pixelated",
			absolute = true,
			left = function(): number
				local sprite_width = (if gag_playing() then GAG_W elseif large_pet() then LARGE_W else GRID_W) * PIXEL
				local current = session()
				local fraction = pet_position(position_setting:get(), if current then current.id else nil, position:get()) or 0
				return math.floor(fraction * math.max(0, width:get() - sprite_width))
			end,
			top = function(): number
				return if gag_playing() then -GAG_FOOT * PIXEL elseif large_pet() then -LARGE_FOOT * PIXEL else -FOOT
			end,
			w = function(): number
				return (if gag_playing() then GAG_W elseif large_pet() then LARGE_W else GRID_W) * PIXEL
			end,
			h = function(): number
				return (if gag_playing() then GAG_H elseif large_pet() then LARGE_H else GRID_H) * PIXEL
			end,
			pointer_events = "none",
			aria_hidden = true,
		},
	}
end

zeron.place { at = "#composer-toolbar", before = function(): Node
	local session = zeron.live("session")
	local select_pet = pet_handoff(choose_pet, function(id)
		return zeron.store(`pet.{id}`, nil):peek()
	end, function(id, pet)
		zeron.store(`pet.{id}`, nil):set(pet)
	end)
	return ui.presence(function(): string?
		local current = session()
		select_pet(pet_setting:get(), if current then current.id else nil, math.random(), zeron.sessions())
		return if current and current.id and current.id ~= "" then current.id else "new-chat"
	end, function(): Node
		return Pet(session, select_pet)
	end)
end }
