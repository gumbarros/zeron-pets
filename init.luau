-- Zeron Pets: animated pixel companions on the message box.
-- Character-specific gags share the same bounded animation scheduler.

local zeron = require("./zeron")("zeron-pixel-pets")
local choose_pet = require("./pet-selection")
local pet_position = require("./pet-position")
local pet_handoff = require("./pet-handoff")
local pet_setting = zeron.setting("pet")
local position_setting = zeron.setting("position")

-- The sprite's grid, a pixel's size (points), and where it sits: its
-- outline's last row over the pill's top edge.
local GRID_W, GRID_H, PIXEL = 64, 64, 2
local FOOT = 62 * PIXEL
local WIDE_W = 96
local TALL_H, TALL_FOOT = 96, 94
local EZIO_GAG_W, EZIO_GAG_H, EZIO_GAG_FOOT = 100, 80, 78
local CRIME_GAG_W, CRIME_GAG_H, CRIME_GAG_FOOT = 100, 80, 78
local GAG_W, GAG_H, GAG_FOOT = 96, 80, 78

-- Each motion: its frames and how long each shows (ms), back to idle after.
local BLINK = { { "blink", 140 } }
local FLICK = { { "tail-out", 130 }, { "idle", 90 }, { "tail-over", 130 }, { "idle", 90 }, { "tail-out", 110 } }
local TWITCH = { { "ear", 120 }, { "idle", 80 }, { "ear", 120 } }
local THROW = {
	{ "windup", 220 }, { "lift", 180 }, { "release", 100 },
	{ "flight", 120 }, { "follow-through", 180 }, { "recover", 200 },
}
local EXPLODE = { { "charge", 500 }, { "charged", 600 }, { "explode", 180 }, { "smoke", 550 } }
local ASSASSINATE = {
	{ "assassinate-01", 220 }, { "assassinate-02", 180 },
	{ "assassinate-03", 140 }, { "assassinate-04", 100 },
	{ "assassinate-05", 130 }, { "assassinate-06", 200 },
	{ "assassinate-07", 300 }, { "assassinate-08", 220 },
}
local RELIC = {
	{ "relic-01", 260 }, { "relic-02", 260 },
	{ "relic-03", 220 }, { "relic-04", 230 },
	{ "relic-05", 280 }, { "relic-06", 350 },
	{ "relic-07", 420 }, { "relic-08", 300 },
}
local CAR_THEFT = {
	{ "car-theft-01", 280 }, { "car-theft-02", 260 },
	{ "car-theft-03", 300 }, { "car-theft-04", 360 },
	{ "car-theft-05", 340 }, { "car-theft-06", 250 },
	{ "car-theft-07", 220 }, { "car-theft-08", 300 },
}
local HEIST = {
	{ "heist-01", 280 }, { "heist-02", 280 },
	{ "heist-03", 340 }, { "heist-04", 340 },
	{ "heist-05", 240 }, { "heist-06", 300 },
	{ "heist-07", 240 }, { "heist-08", 300 },
}
local MILK = { { "milk-ready", 350 }, { "milk-jet", 250 }, { "milk-end", 180 }, { "milk-jet", 250 }, { "milk-end", 350 } }
local CART = { { "cart-arrive", 650 }, { "cart-explode", 220 }, { "cart-smoke", 850 } }
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
	{ motion = MILK, range = { 12, 20 }, pet = "otis" },
	{ motion = BLINK, range = { 2, 4 } },
	{ motion = FLICK, range = { 3, 6 } },
	{ motion = TWITCH, range = { 5, 9 } },
	{ motion = CART, range = { 15, 25 }, pet = "bergamini-cow" },
	{ motion = THROW, range = { 10, 20 }, pet = "whiplash" },
	{ motion = DOG, range = { 9, 16 }, pet = "anti-sergio" },
	{ motion = EXPLODE, range = { 15, 25 }, pet = "creeper" },
	{ motion = ASSASSINATE, range = { 14, 24 }, pet = "ezio" },
	{ motion = RELIC, range = { 14, 24 }, pet = "lara-croft" },
	{ motion = CAR_THEFT, range = { 16, 26 }, pet = "jason-duval" },
	{ motion = HEIST, range = { 16, 26 }, pet = "lucia-caminos" },
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
	local function wide_pet(): boolean
		local pet = selected_pet()
		return pet == "whiplash" or pet == "ornstein-smough"
	end
	local function tall_pet(): boolean
		return selected_pet() == "whiplash"
	end
	local frame = ui.use_state("idle")
	local motion_pet = selected_pet()
	local function gag_playing(): boolean
		return selected_pet() == "squidward" and motion_pet == "squidward" and string.sub(frame:get(), 1, 8) == "machine-"
	end
	local function assassination_playing(): boolean
		return selected_pet() == "ezio" and motion_pet == "ezio" and string.sub(frame:get(), 1, 12) == "assassinate-"
	end
	local function crime_playing(): boolean
		local pet, name = selected_pet(), frame:get()
		return pet == motion_pet and ((pet == "jason-duval" and string.sub(name, 1, 10) == "car-theft-") or (pet == "lucia-caminos" and string.sub(name, 1, 6) == "heist-"))
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
				assert(pending() <= MOST, "zeron-pixel-pets: timers left pending")
			end
			turns[i] = ui.after(within(each.range), turn)
		end
	end
	local function click_motion(): { { any } }?
		local pet = selected_pet()
		for _, each in EVERY do
			if each.pet == pet then
				return each.motion
			end
		end
		return nil
	end
	local function interactive(): boolean
		return click_motion() ~= nil and not reduced()
	end
	return ui.div {
		absolute = true, left = 0, right = 0, top = 0, h = 0,
		pointer_events = "none",
		on_resize = function(size)
			width:set(size.w)
		end,
		ui.button {
			id = "zeron-pixel-pets",
			label = zeron.t("pet.animate"),
			p = 0, bg = "#00000000",
			hover = { bg = "#00000000" },
			active = { bg = "#00000000" },
			focusable = interactive,
			aria_hidden = function(): boolean return not interactive() end,
			pointer_events = function(): string return if interactive() then "auto" else "none" end,
			cursor = function(): string return if interactive() then "pointer" else "default" end,
			on_click = function()
				local motion = click_motion()
				if motion then
					play(motion)
				end
			end,
			absolute = true,
			left = function(): number
				local sprite_width = (if gag_playing() then GAG_W elseif assassination_playing() then EZIO_GAG_W elseif crime_playing() then CRIME_GAG_W elseif wide_pet() then WIDE_W else GRID_W) * PIXEL
				local current = session()
				local fraction = pet_position(position_setting:get(), if current then current.id else nil, position:get()) or 0
				return math.floor(fraction * math.max(0, width:get() - sprite_width))
			end,
			top = function(): number
				return if gag_playing() then -GAG_FOOT * PIXEL elseif assassination_playing() then -EZIO_GAG_FOOT * PIXEL elseif crime_playing() then -CRIME_GAG_FOOT * PIXEL elseif tall_pet() then -TALL_FOOT * PIXEL else -FOOT
			end,
			w = function(): number
				return (if gag_playing() then GAG_W elseif assassination_playing() then EZIO_GAG_W elseif crime_playing() then CRIME_GAG_W elseif wide_pet() then WIDE_W else GRID_W) * PIXEL
			end,
			h = function(): number
				return (if gag_playing() then GAG_H elseif assassination_playing() then EZIO_GAG_H elseif crime_playing() then CRIME_GAG_H elseif tall_pet() then TALL_H else GRID_H) * PIXEL
			end,
			ui.image {
				src = function(): string
					local pet = selected_pet()
					local name = if pet == motion_pet then frame:get() else "idle"
					return `art/{pet}/{name}.png`
				end,
				w = "100%", h = "100%",
				image_rendering = "pixelated",
				pointer_events = "none", aria_hidden = true,
			},
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
