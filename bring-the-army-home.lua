--@enabled = false

--[====[

bring-the-army-home
===================
After a raid, returning soldiers will enter the map quickly instead 
of trickling in one at a time.

In addition, all spoils items will be dropped and forbidden.

This script requires a Fishing Zone with tiles on the edge of the map.

Recommended: make the zone as big as 1x20 or even 1x30, on the map edge.
The zone can be disabled to prevent fishing jobs.

Only the earliest-created Fishing Zone with tiles on the map edge will 
be used.

After a raid, squad members who have not yet entered the map will have 
their entry point set to a random location in the zone.

Usage:

    bring-the-army-home

For manual use.  Run this immediately after the 
"Squad Name and others have returned." announcement.


    bring-the-army-home start

The activation is new-unit and notification-based: Every time a new unit 
is added to the map, the announcement queue is checked for a "Squad Name 
and others have returned." announcement.  This triggers the script.

--]====]


-- TODO generalize to other report types (migrants).

-- TODO find out what happens with messengers.
--   Messengers get an army_controller with goal type 19,
--   with data containing the hfids of the workers being requested.
--   The army_controller does not have squads, but does have an
--   entity id (to our group) and an 'epp id' (into our site's
--   historical_entity.positions.assignments[], which also has a 
--   backlink to the army_controller).
-- Messengers get an army when they leave the map.  The army links
--   to the relevant army_controller, has one member and no squads,
--   and the army.flags are all false.



-- DONE catch map load / unload.

-- TODO maybe: Instead of random, equal units per tile ?

-- DONT: keep a cache of already-processed unit-ids and tick time, and don't double-process them.
--   I dealt with this issue in a different way.

-- TODO maybe: I just found that squad_order_raid_sitest is where the exit point is defined.
--   could override that on close of the world map?  to force the army to exit on our zone.

-- note: squad return event is 301 GUEST_ARRIVAL

-- note: found out there are NO TICKS between the incoming units being placed
--   into units.active, and the announcement, and the first unit entering the map:
--	announcement GUEST_ARRIVAL at year 507 tick 77210
--	Squad4 and others have returned.
--	Triggered at tick 77210
--	At tick 77210, #units.active changed from 699 to 719
--	At this point, the squad leader was already on the map at the announcement.pos location.
-- (later) I also found that this is when the army is deleted.  likely the army_controller too.
--   so you can't study the army/army_controller to cross-check the incoming units.
--   (could grab any relevant info on every trigger.)

-- There are 100 ticks between waves, that is, attempts to enter.
--   DONE: could frequency be set as low as 100?  Is the 100 aligned to a boundary?
--	A: NO.  Probably 10.

-- TODO NEW ISSUE: Babies should not be removed from their mothers.
--	Mother 11046 Thikut Uz, SQ4 ; Baby 17054 Rith Laz.
--	On-map, active babies have flags1.rider set.
--	They also have relationship_ids.RiderMount == their mother's id.
--	mount_type == 1 (CARRIED).
--	TODO check if that is still true of .inactive babies.
--   So if a unit has .rider, move them to the same square as their mount, I think.

-- TODO maybe: it turns out that eventful.onUnitNewActive is pretty slow, because it scans
--   the entire active units vector every n ticks (based on frequency of course).
--   Consider switching back to a report-based trigger.
--   (OTOH, so many reports come in that that's slow as well.)


eventful = require('plugins.eventful')

local _, plotinfo = pcall(function() return df.global.ui; end)
if not _ then _, plotinfo = pcall(function() return df.global.plotinfo; end) end


local debugging = true


-- note: unlike normal printf, this ends the line even if '\n' is not used.
local function printf(...)
    print(string.format(...))
end


-- This is basically debug-printf.
-- If a global or top-level local variable 'debugging' is false or does not exist, there is no output.
-- If 'debugging' is true, this uses dfhack.printerr() to both print to the console (in red),
--   and log to the stderr.log file.  
-- The debug library is used to find both the filename and the function name.
--
local current_script_name = dfhack.current_script_name()
local function dprintf(format, ...)
    if not debugging then return; end
    -- unfortunately, even if we're not debugging, the script wastes time collecting
    --   all of the info that would be printed.  So don't do anything too slow.

    -- Lua 5.3 Reference Manual 4.9 lua_Debug and lua_getinfo.
    --   2 = immediate caller's frame, n = name info, t = istailcall.
    local info = debug.getinfo(2, "nt")
	    or { namewhat = "{no debug info}", name = "{no debug info}", istailcall = false, }
    -- we assume that info always contains details about a function, because that's what we asked for.
    -- Lua 5.3 Reference Manual 3.4.10:
    --   "However, a tail call erases any debug information about the calling function."
    info.name = info.name or ( (info.istailcall) and "{tail call}" or "{no function}" )
    -- I'm not sure we care about namewhat; 'global' or 'local' function doesn't really matter.
    --if info.namewhat == "upvalue" then info.namewhat = "local"; end	-- make things look familiar.
    dfhack.printerr(string.format("%s %s(): " .. format, current_script_name, info.name, ...))
end


local stop_catching_newunits	-- declared here, defined as a function near the end of the script.


local QError = qerror
local function qerror(msg, lvl)
    stop_catching_newunits()
    QError(msg, lvl)
end


---@alias coord {x=integer, y=integer, z=integer}	# coercible into a df.coord .


---@param  x integer
---@param  y integer
---@param  z integer
---@return string
local function xyz2str(x,y,z)
    x = math.tointeger(x); y = math.tointeger(y); z = math.tointeger(z)
    if not x or not y or not z then
	qerror("not enough parameters, or a parameter could not be converted to an integer.")
    end
    return(string.format("%d,%d,%d",x,y,z))
end


---@param pos coord
local function pos2str(pos)
    return xyz2str(pos2xyz(pos))
end


-- This should be static-local inside is_on_map_edge() .  I wish we had a way to make static local variables.
--   (Q: can closures do this?  A: no, you still need a variable in an outer scope.  so there's no gain.)
---@type { [string]: boolean }	# dictionary, i.e. a table<strpos, true>.
--  				# If the key exists, the strpos is on the (surface) map edge.
local is_on_map_edge_list = {}


---@param  x integer|coord|df.coord
---@param  y integer?
---@param  z integer?
---@return boolean
local function is_on_map_edge(x,y,z)

    if y == nil and z == nil then x,y,z = pos2xyz(x); end

    -- build the table, only once.
    if #is_on_map_edge_list == 0 then
	local source = plotinfo.map_edge

	-- unfortunately, can't use builtin get_path_xyz() because the data is not set up as a path.
	for i = 0, #source.surface_x-1 do
	    local xx, yy, zz = source.surface_x[i], source.surface_y[i], source.surface_z[i]
	    is_on_map_edge_list[xyz2str(xx,yy,zz)] = true
	end
    end

    return ( is_on_map_edge_list[xyz2str(x,y,z)] == true )
end


-- returns a list of all of the tiles which are actually in the building, considering extents.
--
-- note: only tested with building type df.building_civzonest .
--
---@param  building df.building
---@return coord[]
local function get_all_building_tiles(building)
    ---@type coord[]
    local tiles = {}

    local z = building.z
    for x = building.x1, building.x2 do
	for y = building.y1, building.y2 do

	    if dfhack.buildings.containsTile(building, x, y) then
		table.insert(tiles, xyz2pos(x,y,z))
	    end
	end
    end
    return tiles
end


---@return coord[]	# a (possibly-empty) list of coords of teleportation targets.
local function find_acceptable_tiles()

    ---@type coord[]
    local acceptable_tiles = {}			-- note: we do not cache this because e.g. trees
						--   can grow or buildings can be constructed.

    for _,zone in ipairs( df.global.world.buildings.other.ZONE_FISHING_AREA ) do

	if not df.building_civzonest:is_instance(zone) then 
	    qerror('ERR: not a zone!')  -- can't happen.
	end

	acceptable_tiles = {}

	for _, pos in ipairs(get_all_building_tiles(zone)) do

	    --dprintf("%s, %s, %d, %s", pos2str(pos), is_on_map_edge(pos) and 'true' or 'false',
	    --    dfhack.maps.getWalkableGroup(pos),
	    --    dfhack.buildings.checkFreeTiles(pos,{x=1,y=1},nil,false,true) and 'true' or 'false' )

	    if is_on_map_edge(pos) == true
		    and dfhack.maps.getWalkableGroup(pos) > 0
		    and dfhack.buildings.checkFreeTiles(pos,{x=1,y=1},nil,false,true) == true
	    then
		table.insert(acceptable_tiles, pos)
	    end
	end
	if #acceptable_tiles > 0 then break; end
    end

    return acceptable_tiles
end


-- returns whether an item is assigned to a miner, woodcutter, or hunter.
-- essentially like dfhack.items.isSquadEquipment()
--
---@param item df.item
---@return boolean
local function isMinerWoodcutterHunterEquipment(item)
    -- actually this was not hard to check.  nice.
    for _, id in ipairs(plotinfo.equipment.work_weapons) do
	if id == item.id then return true; end
    end
    return false
end


-- Drop and forbid an incoming unit's spoils.  Spoils are determined with these tests:
--	* Not squad equipment.
--	* The carry mode is .Hauled (for active units) or .Weapons (for inactive units).
--
-- Spoils tests that are not performed are:
--	* Not fort-produced.
--	* Not owned by the unit.  For some reason, returning soldiers don't own anything at all.  Bug!
--	* A spoils item is expected to be the last item in the inventory.
--
-- DONE: what happens if a miner/woodcutter/hunter is used as a site messenger?
--	Does their equipment count as squad-owned?  I bet not.  Resolution: manually checked.
--
---@param unit df.unit
local function drop_and_forbid_spoils(unit)

    ---@type coord
    local unitpos = xyz2pos(dfhack.units.getPosition(unit))
    ---@type df.item[]
    local items_to_drop = {}

    -- collector.
    for i, invitem in ipairs(unit.inventory) do
	local item = invitem.item

	-- DONT bother: the spoils should be the last item in the inventory.

	-- So for some reason, the returning squaddies don't haul the spoils item;
	--   it is carried as Weapons.  (so are shields, BTW.)

	-- Unfortunately, a returning soldier doesn't own any of their inventory items.
	-- That has to be a bug; I should extend preserve-rooms to deal with that.
	-- But this script just has to deal.

	if  (      invitem.mode == df.inv_item_role_type.Hauled	-- if unit is active.
	        or invitem.mode == df.inv_item_role_type.Weapon	-- if unit is inactive.
	    )
	    and not dfhack.items.isSquadEquipment(item)
	    and not isMinerWoodcutterHunterEquipment(item)
	    -- note: it can happen that an arriving active unit is hauling their squad equipment;
	    -- I saw one example of hauling a squad-assigned flask to the flask stockpile.
	then
	    if i ~= #unit.inventory-1 then
		dprintf("NOTICE: Spoils item %d is not the last inventory item.  So that happens.", item.id)
	    end
	    table.insert(items_to_drop, item)
	end
    end

    -- processor.
    for _, item in ipairs(items_to_drop) do
	if #items_to_drop > 1 then
	    dprintf("NOTICE: More than one spoils item.  Probably a bug.  unit %d, item %d", unit.id, item.id)
	end
	local success = dfhack.items.moveToGround(item, unitpos)
	dprintf("Dropping and forbidding spoils item %d at (%s).%s", item.id,
		pos2str(unitpos), (success) and '' or '  FAILED!' )
	if item.flags.on_ground then
	    item.flags.forbid = true
	end
    end
end


-- Teleport a unit to the special zone.  The unit can be active (alive & on the map) or inactive.
-- The unit's alive/dead status is not considered; this has not been tested with dead units.
--
-- TODO it would be better to deal with entrypos == nil in assign_incoming_units_to_tiles() .
--
---@param unit df.unit
---@param entrypos coord?
---@param acceptable_tiles coord[]
local function teleport_unit_to_a_random_incoming_tile(unit, entrypos, acceptable_tiles)

    -- making entrypos a valid coord that is not on the map simplifies processing.
    local had_an_entrypos = (entrypos ~= nil)
    if entrypos == nil then entrypos = xyz2pos(-30000, -30000, -30000); end

    ---@type coord
    local oldpos = xyz2pos(dfhack.units.getPosition(unit))

    -- testing whether this works.  if it works, it will avoid (most) double-processing.
    -- note that if the unit is on entrypos, and entrypos happens to be in acceptable_tiles, 
    --   we do not skip the teleport.
    if not (same_xyz(oldpos, entrypos)) then
	for _, atile in ipairs(acceptable_tiles) do
	    if same_xyz(oldpos, atile) then
		dprintf("NOTICE: unit %d 's current position is already in acceptable_tiles; " .. 
			"skipping teleport.", unit.id)
		return
	    end
	end
    end

    -- handle the case where the unit is not actually on the entrypos.
    --     this shouldn't happen, but early experiments showed that it does.
    --     later: probably the unit had moved away from the entrypos before the script ran.
    --     even later: or the unit got double-processed because entrypos was in the acceptable tiles,
    --       and two armies returned at nearly the same time.
    if had_an_entrypos and not same_xyz(entrypos, oldpos) then
	dprintf("NOTICE: Unit %d is is at (%s), not on the entrypos (%s).  So that does happen.",
		unit.id, pos2str(oldpos), pos2str(entrypos))
    end

    ---@type coord
    local pos

    -- I had an issue where the game's chosen incoming tile was in acceptable_tiles[].
    -- this manifested as: the units I assigned to that tile were not able to enter the map.
    -- the cause of this was tracked down to occ.unit and occ.unit_grounded, but I could
    --   not figure out why occ.unit kept being set.
    -- anyway, we need to skip the special case.
    --   (later: this may not have been properly diagnosed.  there is something going on with occ.unit.)
    -- TODO: the way to TEST this would be to force acceptable_tiles[] to contain the entrypos
    --     and one other tile.
    repeat
	pos = acceptable_tiles[ math.random(#acceptable_tiles) ]
    until not same_xyz(entrypos, pos)

    dprintf("Teleporting %s unit %d to arrive at (%s)", unit.flags1.inactive and 'inactive' or 'active',
	unit.id, pos2str(pos) )

    -- .inactive units are assigned a map tile, but do not yet occupy it.
    -- the teleport sets the occupancy flags per the normal case of an active unit.
    -- we need to undo that.

    local occ = dfhack.maps.getTileBlock(pos).occupancy[pos.x % 16][pos.y % 16]
    local old_occ_unit = occ.unit
    local old_occ_unit_grounded = occ.unit_grounded

    if (unit.flags1.inactive and unit.flags1.on_ground) then 
	dprintf("NOTICE: Before teleport, inactive unit %d had flags1.on_ground set.", unit.id)
    end

    local success = dfhack.units.teleport(unit, pos)

    if (unit.flags1.inactive and unit.flags1.on_ground) then
	dprintf("NOTICE: After teleport, inactive unit %d has flags1.on_ground set.", unit.id)
    end

    if success then

	-- restore the tile's unit occupancy flags, if necessary.
	if unit.flags1.inactive then
	    occ.unit = old_occ_unit
	    occ.unit_grounded = old_occ_unit_grounded
	    unit.flags1.on_ground = false
	end

	drop_and_forbid_spoils(unit)

    else
	dprintf("Teleport failed! Unit %d oldpos %s target %s", unit.id, pos2str(oldpos), pos2str(pos))
    end
end


---@param pos coord
---@return df.item[]
local function get_items_on_this_tile(pos)

    local itemlist = {}
    local block = dfhack.maps.getTileBlock(pos)
    if not (block) then return {}; end

    for _, id in ipairs(block.items) do
	local item = df.item.find(id)
	if (item) and same_xyz(xyz2pos(dfhack.items.getPosition(item)), pos) then
	    table.insert(itemlist, item)
	end
    end
    return itemlist
end


---@param itemlist df.item[]
---@param acceptable_tiles coord[]
local function move_items_to_a_random_incoming_tile(itemlist, acceptable_tiles)

    local pos = acceptable_tiles[ math.random(#acceptable_tiles) ]

    for _, item in ipairs(itemlist) do
	local success = dfhack.items.moveToGround(item, pos)
	dprintf("Moving and forbidding just-dropped item %d at (%s) to (%s).%s",
		item.id, xyz2str(dfhack.items.getPosition(item)), pos2str(pos), 
		(success) and '' or '  FAILED!' )
	-- TODO maybe, consider it: only forbid if it's not a fort-created item.
	if item.flags.on_ground then item.flags.forbid = true; end
    end
end


---@param entrypos coord?	# the original entrance location, parsed from the announcement.
---@return integer		# the number of units which were teleported.
local function assign_incoming_units_to_tiles(entrypos)

    local acceptable_tiles = find_acceptable_tiles()
    if #acceptable_tiles == 0 then
	dprintf("find_acceptable_tiles() returned false")
	printf("bring-the-army-home could not locate any tiles to place the returning army on!")
	printf("Please create a Fishing Zone on the edge of the map, in the location where the")
	printf("army should return.  (The Fishing Zone can be disabled to prevent fishing jobs.)")
	return 0
    end

    -- debug logging, chasing an issue.  kind of slow, but only if debugging, so it's okay.
    for _,unit in ipairs(df.global.world.units.active) do
	if not debugging then break; end
	if (not dfhack.units.isKilled(unit) and unit.flags1.inactive and unit.flags1.on_ground) then
	    dprintf("NOTICE: Before any teleports, inactive unit %d has flags1.on_ground set.", unit.id)
	    dprintf("    isFortControlled=%s  %s", 
		    dfhack.units.isFortControlled(unit) and 'true ' or 'false', 
		    dfhack.units.getReadableName(unit))
	end
    end
    -- debug logging, chasing an issue.  slow, but only if debugging, so it's okay.
    for _, pos in ipairs(acceptable_tiles) do
	if not debugging then break; end
	local occ = dfhack.maps.getTileBlock(pos).occupancy[pos.x % 16][pos.y % 16]
	if occ.unit_grounded then 
	    dprintf("NOTICE: Before any teleports, tile (%s) has occ.unit_grounded set.", pos2str(pos))
	    local a, ang, ag = 0, 0, 0
	    for _, unit in ipairs(df.global.world.units.active) do
		local unitpos = xyz2pos(dfhack.units.getPosition(unit))
		if same_xyz(unitpos, pos) then
		    dprintf("\tUnit %d is on this tile.  .flags1.inactive = %s, .flags1.on_ground = %s.",
			unit.id, (unit.flags1.inactive) and 'true ' or 'false',
			(unit.flags1.on_ground) and 'true ' or 'false' )
		end
		a = a + ((not unit.flags1.inactive) and 1 or 0)
		ang = ang + ((not unit.flags1.inactive and not unit.flags1.on_ground) and 1 or 0)
		ag = ag + ((not unit.flags1.inactive and unit.flags1.on_ground) and 1 or 0)
	    end
	    dprintf("\tThis tile had %d active, %d nongrounded, %d grounded units.", a, ang, ag)
	end
    end

    local processed = 0

    for _,unit in ipairs(df.global.world.units.active) do

	-- okay, as a catch-all, we're going to process all .incoming, .inactive,
	--     not .killed, fort-controlled units (whether or not they're at entrypos),
	-- TODO maybe: remove this catch-all case?  it causes double-teleporting when two
	--     arrivals occur in quick succession.
	-- and ALSO all units at entrypos (if given),
	--     even if they're on the map and active (i.e. the first unit to enter),
	--     even if they're not fort-controlled (e.g. freed prisoners).
	--
	-- we do NOT care about military squad.  war animals don't have a squad.
	--
	if ( unit.flags1.incoming and unit.flags1.inactive and not unit.flags2.killed
		and dfhack.units.isFortControlled(unit) )
	    or ( (entrypos) and same_xyz(xyz2pos(dfhack.units.getPosition(unit)), entrypos) )
	then
	    teleport_unit_to_a_random_incoming_tile(unit, entrypos, acceptable_tiles)

	    processed = processed + 1
	end
    end

    -- special case: soldiers who already entered the map may have already dropped their spoils.
    if (entrypos) then
	move_items_to_a_random_incoming_tile( get_items_on_this_tile(entrypos), acceptable_tiles )
    end

    -- debug logging, chasing an issue.  kind of slow, but only if debugging, so it's okay.
    for _,unit in ipairs(df.global.world.units.active) do
	if not debugging then break; end
	if (not dfhack.units.isKilled(unit) and unit.flags1.inactive and unit.flags1.on_ground) then
	    dprintf("NOTICE: After all teleports, inactive unit %d has flags1.on_ground set.", unit.id)
	    dprintf("    isFortControlled=%s  %s", 
		    dfhack.units.isFortControlled(unit) and 'true ' or 'false', 
		    dfhack.units.getReadableName(unit))
	end
    end
    -- debug logging, chasing an issue.  slow, but only if debugging, so it's okay.
    for _, pos in ipairs(acceptable_tiles) do
	if not debugging then break; end
	local occ = dfhack.maps.getTileBlock(pos).occupancy[pos.x % 16][pos.y % 16]
	if occ.unit_grounded then 
	    dprintf("NOTICE: After all teleports, tile (%s) has occ.unit_grounded set.", pos2str(pos))
	    local a, ang, ag = 0, 0, 0
	    for _, unit in ipairs(df.global.world.units.active) do
		local unitpos = xyz2pos(dfhack.units.getPosition(unit))
		if same_xyz(unitpos, pos) then
		    dprintf("\tUnit %d is on this tile.  .flags1.inactive = %s, .flags1.on_ground = %s.",
			unit.id, (unit.flags1.inactive) and 'true ' or 'false',
			(unit.flags1.on_ground) and 'true ' or 'false' )
		end
		a = a + ((not unit.flags1.inactive) and 1 or 0)
		ang = ang + ((not unit.flags1.inactive and not unit.flags1.on_ground) and 1 or 0)
		ag = ag + ((not unit.flags1.inactive and unit.flags1.on_ground) and 1 or 0)
	    end
	    dprintf("\tThis tile had %d active, %d nongrounded, %d grounded units.", a, ang, ag)
	end
    end

    if processed > 0 then 
	printf("%s: processed %d incoming %s.", current_script_name, processed, 
		(processed == 1) and 'unit' or 'units')
    end
    return processed
end


last_announcement_id = last_announcement_id or -1	-- global, persistant.


-- in the case of a NEW announcement type GUEST_ARRIVAL subtype "have returned.",
--   this returns the entry-point as a coord .
-- otherwise it returns nil.
--
---@return coord?
local function check_for_our_announcement()

    -- scan through all announcements, starting from the bottom.
    --   we expect that there are very few announcements, so no performance hit.

    for _, report in ipairs(df.global.world.status.announcements) do

	-- have we ever seen this report before?
	if report.id > last_announcement_id then

	    last_announcement_id = report.id
	    --dprintf("new announcement: id %d  year %d  tick %d  type %s  text %s", 
	    --	    report.id, report.year, report.time, df.announcement_type[report.type], report.text)

	    if report.type == df.announcement_type.GUEST_ARRIVAL then
		dprintf('Found a new GUEST_ARRIVAL announcement!')

		-- note: even the singular case gets plural text: "Squad1 have returned."
		--   however, the text " has returned." is in the binary, so better safe than sorry.
		-- aha, it does happen, when a single unit returns.
		-- TODO what happens with messengers?
		if string.match(report.text, "has returned.$")
		    or string.match(report.text, "have returned.$")
		then
		    ---@type coord
		    local pos = report.pos
		    dprintf("It is an army return!  at (%s)  tick %d", pos2str(pos), report.time)
		    if (report.time % 10) ~= 0 then
			-- test a hypothesis:
			dprintf("NOTICE: the announcement's time is not divisible by 10.  So that happens.")
		    end
		    return pos
		end
	    end
	end
    end
    return nil
end


catch_newunits_enabled = catch_newunits_enabled or false	-- global, persistant.


local function catch_newunits(unit_id)

    -- TODO counting for status reporting.

    if not catch_newunits_enabled then
	stop_catching_newunits()
	dprintf("unexpectedly triggered with catch_newunits_enabled==false")
	return
    end
    if not dfhack.isWorldLoaded() then
	stop_catching_newunits()
	dprintf("unexpectedly triggered without a world loaded.")
	return
    end
    if not dfhack.isMapLoaded() then
	stop_catching_newunits()
	dprintf("unexpectedly triggered without a map loaded.")
	return
    end
    if not dfhack.isSiteLoaded() then
	stop_catching_newunits()
	dprintf("unexpectedly triggered without a player fort loaded.")
	return
    end

    dprintf("Caught a new unit: id %d  tick %d", unit_id, dfhack.world.ReadCurrentTick())

    ---@type df.coord?
    local pos = check_for_our_announcement()

    -- if not nil, then we should trigger.
    if (pos) then
	dfhack.world.SetPauseState(true)
	print("\a")	-- ring the bell

	-- TODO this would be the place to check that all squad members arrived safely.
	--   (or, you know, were legitimately killed horribly by a demon....)

	-- DONE should we redo find_acceptable_tiles() on each arrival?
	--   in case of new constructions, bridges, newly-grown trees, etc....
	--   yes, did this in assign_incoming_units_to_tiles()

	if assign_incoming_units_to_tiles(pos) == 0 then
	    -- TODO report that no units could be teleported?
	    -- TODO somehow report if any teleports failed?
	end
    end
end


-- note: the eventful C++ code shuts down the world-specific exports at world-unload.
-- so we don't really _need_ to catch fort/map/world unloads.  Unless we're caching stuff.
--
-- note: onUnitNewActive is UNDOCUMENTED.
--
local bring_the_army_home_KEY = dfhack.current_script_name()	-- must be globally unique in all scripts.
local function start_catching_newunits()

    -- 2nd parameter is frequency.  1 == every tick, 16 == every 16 ticks.
    --   16 ticks is too many; we can miss the first incoming unit.
    --
    -- TODO: we don't need to check every tick; we just need to do our stuff before the
    --   first-to-arrive unit (i.e. already active on the map) takes their first step.
    --   (however, consider the fastdwarf module.)
    --   note: preserve-rooms checks every 109 ticks.
    --
    -- TODO: it looks like arrivals only happen on ticks where ticks % 10 == 0.  Needs more testing.
    --   TODO: if that's true, synchronize ourself to a 10-tick boundary.
    eventful.enableEvent(eventful.eventType.UNIT_NEW_ACTIVE, 10)

    eventful['onUnitNewActive'][bring_the_army_home_KEY] = 
	    function(unit_id) catch_newunits(unit_id); end

    catch_newunits_enabled = true
end


--[[ local function ]] stop_catching_newunits = function()
    -- note: the odd declaration syntax is because we pre-declared the local variable 
    -- stop_catching_newunits, so that my replacement qerror() could reference it.  
    -- Now we are defining it as a function.  see:
    -- https://stackoverflow.com/questions/12291203/lua-how-to-call-a-function-prior-to-it-being-defined

    -- note: this routine MUST not call qerror(), because it is called by my replacement qerror().

    -- DONE Q: how to disable?
    --     A: apparently you disable the callback by setting the key to nil.
    --     A2: you cannot disable the timer, though.  it keeps running.
    eventful['onUnitNewActive'][bring_the_army_home_KEY] = nil

    catch_newunits_enabled = false
end


local function catch_events(event_id)

    if event == SC_MAP_UNLOADED then
	dprintf("handling SC_MAP_UNLOADED.")
	stop_catching_newunits()
	dfhack.onStateChange[GLOBAL_KEY] = nil
    end
end


enabled = enabled or false
function isEnabled()
    return enabled
end


local function main(...)

    -- TODO real parsing.
    local cmd = ...

    if cmd == 'stop' then		-- TODO after module-izing, this will be redundant.
	stop_catching_newunits()
    elseif cmd == 'start' then
	start_catching_newunits()
    else
	local pos = check_for_our_announcement()		-- may return nil
	if assign_incoming_units_to_tiles(pos) == 0 then	-- if pos is nil?  run it anyway.
	    print('There were no incoming units!')
	end
    end
end


if dfhack_flags.module and dfhack_flags.enable_state then
    dprintf("running as an enabled module.  installing hooks.")
    enabled = true
    dfhack.onStateChange[GLOBAL_KEY] = function(event_id) catch_events(event_id); end
    start_catching_newunits()
elseif dfhack_flags.module and not dfhack_flags.enable_state then
    dprintf("running as a disabled module.  disabling hooks.")
    enabled = false
    dfhack.onStateChange[GLOBAL_KEY] = nil
    stop_catching_newunits()
else
    dprintf("running from commandline.")
    main(...)
end


--[[

I had one case where a soldier got all set up properly, but was not inserted into units.active.
I couldn't get him to move onto the map until I inserted the unit manually.

TODO try to catch this case.  At least complain, if not try to fix it.

--]]

--[[

1593856 69      D_MIGRANTS_ARRIVAL      Some migrants have arrived.     508     57410
1593855 344     MONARCH_ARRIVAL Your ruler has arrived with a full entourage.  Your thriving site is now the capital, and with continued fortune and toil, the legend of a true Mountainhome may yet be written.        508     57410

two of those migrants or entourage were soldiers who were out on a mission.  
they were unassigned from their squad.  ISTR they lost all their weapons/armor as well.

--]]

--[[

I sent 10 squads on a mission; about 95 units.  No war animals.

5 did not return.  Exploring this with DFHack:
A returner's HF has
    .info.whereabouts:
	.state		1 Settler
	.site_id	1851		my site
	.subregion_id	-1
	.feature_layer_id -1
	.army_id	-1
	.cz_id		(some world_object_data, all 0's)
	.cz_bld_num	-1
	.abs_smm_x	1504		this is presumably in my fort.
	.abs_smm_y	1969
	.flags
	    .XY_LOCATION_SMM_LEVEL false
	.flags
	    .XY_LOCATION_IN_SUL false
	.body_state	0 (Active)
	.body_state_id	-1
	.body_state_sub_id -1
	.year		508		current year.
	.year_tick	153920		this was the tick of the 'has returned' message.

A non-returner's HF has:
    .info.whereabouts:
	.state		1 Settler
	.site_id	1851
	.subregion_id	-1
	.feature_layer_id -1
	.army_id	-1
	.cz_id		1362742 (some world_object_data, all 0's)
	.cz_bld_num	-1
	.abs_smm_x	1504		this is presumably in my fort.
	.abs_smm_y	1969
	.flags
	    .XY_LOCATION_SMM_LEVEL false
	.flags
	    .XY_LOCATION_IN_SUL false
	.body_state	0 (Active)
	.body_state_id	-1
	.body_state_sub_id -1
	.year		508		current year.
	.year_tick	153920		this was the tick of the 'has returned' message.

	So exactly the same.

The same non-returner's unit has:
	.pos		(0, 60, 43)	This was the army-return entry location.
	.idle_area	same
	.path		none
	.flags1
	    .inactive	true
	    .incoming	true
	    .on_ground	true

This unit IS in units.active.  That really surprised me.

Another stuck incomer spot-checked at the same data.

The map tile.occupancy for the entry point has:
	.building	0
	.unit		true		(THIS IS WRONG!)
	.unit_grounded	false

Manually toggling block[0%16][60%16].occupancy.unit to false let a unit enter.
The unit appeared to crawl in.
And the flag got set again.
Running layer-occupancy cleared that flag, and let a unit enter.
The unit appeared to crawl in.
And the flag got set again.

Repeatedly running layer-occupancy let the units filter in, one-per-run.
They all crawled in, even the last one.
After they all entered, layer-occupancy didn't find that flag as falsely set.

layer-occupancy did report several units as not-on-the-map,
but spot-checking two of them revealed that they are caged trader animals.

Analysis: The units arrived okay.
Somehow that entry tile was repeatedly corrupted,
in that the block[0%16][60%16].occupancy.unit flag kept getting set.

The only thing I see is that the entry tile was inside my list of acceptable_tiles.


(later: So it turns out that teleporting an inactive unit onto a square with an 
active unit causes the inactive unit to have .flags1.on_ground set, also (maybe?)
.occupancy.unit_grounded is set.  Makes sense, but we need to workaround it.)

--]]

--[[

When an army dies while on mission, the units are _deleted_ from .units.all !  Why?
Why not just mark them as .flags2.killed ?  Bug?


(later) I just found a missing soldier in one of my returned squads.  Histfig exists,
indicates he is still alive, .info.whereabouts lists him as part of a surviving army,
but his unit-id is not in units.all, much less units.active.

Unfortunately, this happened so long ago that I don't have a save WITHOUT the issue.

Maybe the same bug.

--]]

--[[

When soldiers return from a mission, they do not regain ownership of their owned items.
Neither the clothes and crafts they're wearing, nor anything that may be stored in their room.
That has to be a bug.

--]]

--[[

Given an army_controller, how do you find the associated army?

IGNORE ALL THE STUFF BELOW, IT'S RIGHT HERE:
    plotinfo.main.fortress_entity.army_controllers
    plotinfo.main.fortress_entity.armies
and then just map each army back to its controller, and then its master controller.

The army doesn't form until at least one unit leaves the map.  (the army_controller does exist.)
Its .members is populated as units leave the map;
    so it can't be directly used to detect if all units have left the map.
    I really don't see a 'units which are leaving for this army' list.
    I guess you can
	(a) consult army->controller.assigned_squads to see if any members are still in units.active,
	(b) walk units.active looking for war animals with .PetOwner of those squad members are 
		still in units.active.
	note that you can't test flags1.inactive; it is set false even when units are not on the map.
	note that as a war animal leaves the map, .relationship_ids.PetOwner is set to -1,
		and .owner_type gets set to .DEAD_OWNER.
	ah ha, a war animal's histfig has a .histfig_links pf type histfig_hf_link_pet_ownerst.
	the owner's histfig.histfig_links doesn't have a back-link.

note: it seems that army.members is sorted by .nemesis_id, not by just appending entries as they leave.

As the members leave, army.flags.dwarf_mode_preparing is set.  So that lets a search skip armies
that have all left the map.

Note that the number of armies can fluctuate due to (it seems) camping and guarding the camp.
Possibly other reasons.
A guarding unit is placed in its own army, with a new army_controller with a .master_id different
than the .id; it is removed from the associated camping army.

TODO: look into unit.enemy.army_controller_id, unit.enemy.army_controller, and unit.enemy.army_info .
    unit.enemy.army_info not relevant, only has pathing info.

------------ the notes below are preserved for historical interest; don't do things that way.

( army to army_controller is easy, there's a direct link: army -> army_controller .)

fix/stuck-squad does it by following:
    each squad[*] -> squad.positions[*].occupant -> historical_figure.info.whereabouts.army_id
which is crazy.
crazy, except that they're looking for the situation where the army doesn't have an army_controller.


    army_controller.data[union type goal.SITE_INVASION].goal_site_invasion.camp_profile[*] ->
	army_camp_profile.army_id
is sometimes valid, sometimes nonexistant.  also fix/stuck_squads implies it's sometimes a
	sub-army_controller with .master_id -> a different army_controller ?  haven't seen that.

There's only ~3000 armies, that can be searched occasionally.  not every tick, obviously.

Given an arbitrary army, how do you figure out if it's one of our armies?
    army.squads is empty.
    army.members[*] -> army_nemesisst.nemesis_id -> nemesis_record.unit (not nil) -> 
	unit.military.squad_id
	    matches one of plotinfo.group_id -> historical_entity.squads
  or
    army.controller -> army_controller.assigned_squads[] 
	    matches one of plotinfo.group_id -> historical_entity.squads
  or
    army.controller (not nil) -> army_controller.entity_id == plotinfo.group_id
  that one looks best.
  note that fix/stuck-squad tells us that army.controller can be nil, for stuck armies.
  plotinfo.main.fortress_entity == df.historical_entity.find(plotinfo.group_id)

--]]

--[[

To save army/messenger item ownership,

Trigger, oh, 10 times a day.  call it every 128 ticks.
note: preserve-rooms checks every 109 ticks.

Note on frequency: we may be called more often than we requested.  (Is that actually true when
catching ticks?)  If it's been less than (128/2) ticks since we processed, skip processing.

What info should we save persistantly?
Unit id, histfig id, year and tick that this data was saved (or save time as year*403200 + tick),
list of all item ids that the unit owns.  data structure version?  use unit id as a key?

When triggered, check each plotinfo.main.fortress_entity.squads[] to see if there is a
squad_order_raid_sitest.  If so, for each squaddie that is on-site, save their owned
items in persistant storage.

Alternately look at plotinfo.main.fortress_entity.army_controllers, look for .goal == 2 SITE_INVASION,
and save the owned items for all squaddies in the assigned squads.  (there may not be any squads.)


For messengers, hypothetically: once, at the start of the game, go through
plotinfo.main.fortress_entity.positions.own[] looking for .responsibilities.DELIVER_MESSAGES.
For positions with that flag set, cache the .id for later use.

While looking at plotinfo.main.fortress_entity.army_controllers, look for .goal == 19 MAKE_REQUEST.
If there is one, look through plotinfo.main.fortress_entity.positions.assignments[] 
for any assignments with .position_id matching the cached position-deliver-messages ids.
Get the histfig, get the associated unit, save their owned items.

--]]
