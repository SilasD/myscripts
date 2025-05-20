--Teleports and displays an item in a display furniture.
--[====[

put-item-on-display
===================
Teleports and displays an item in a display furniture.

Usage:
    First, set the target display furniture by running the script 
    while viewing the display furniture building.

    After doing this, you can teleport items to the display furniture 
    by running the script while viewing an item's description page.

Suggestion: assign keybindings to do this. 
    e.g. add these lines to dfhack-config/init/dfhack.init :

    keybinding add Ctrl-Shift-Z@dwarfmode/ViewSheets/ITEM "put-item-on-display"
    keybinding add Ctrl-Shift-Z@dwarfmode/ViewSheets/BUILDING "put-item-on-display"
]====]


local utils=require('utils')

local verbose = true

function printf(...)
    print(string.format(...))
end

function vprintf(...)
    if verbose then
	printf(...)
    end
end

function dfprintf(...)	-- for strings coming from inside DF that may have non-ascii characters.
			-- example: dfhack.units.getReadableName()
    print(dfhack.df2console(string.format(...)))
end


function put_item_on_display_teleport(item, building)
--    local desc = dfhack.items.getDescription(item, 0)
    local desc = dfhack.items.getReadableDescription(item, 0)
    --local title = dfhack.items.getBookTitle(item)
    --if title ~= '' then desc = title; end
    desc = string.format("%s (%d)", desc, item.id)

    -- TODO a more elegant way to test item flags.  
    --  based on probe_for_nonstandard_materials.lua verification?

    if --[[not item.flags.on_ground]] false then   -- this works
	vprintf("Warning: skipping %s: not .on_ground", desc)
    elseif item.flags.in_job then
	vprintf("Warning: skipping %s: .in_job", desc)
    elseif item.flags.hostile then
	vprintf("Warning: skipping %s: .hostile", desc)
    elseif --[[item.flags.in_inventory]] false then  -- this works
	vprintf("Warning: skipping %s: .in_inventory", desc)
    elseif item.flags.removed then
	vprintf("Warning: skipping %s: .removed", desc)
    elseif item.flags.in_building then  -- redundant to .on_ground
	vprintf("Warning: skipping %s: .in_building", desc)
    --elseif item.flags.container then  -- redundant to .on_ground  
    ----NO IT ISNT; it means THIS ITEM is a container.
    --  vprintf("Warning: skipping %s: .container", desc)
    --	allow .dead_dwarf
    --	allow .rotten
    --	allow .spider_web
    elseif item.flags.construction then
	vprintf("Warning: skipping %s: .construction", desc)
    -- 	allow .encased
    -- 	allow .unk12
    -- 	allow .murder
    -- 	allow .foreign
    -- 	allow .trader; see below.
    -- 	allow .owned
    elseif item.flags.garbage_collect then
	vprintf("Warning: skipping %s: .garbage_collect", desc)
    --	allow .artifact
    --	allow .forbid
    elseif item.flags.already_uncategorized then
	vprintf("Warning: skipping %s: .already_uncategorized", desc)
    --	allow .dump
    elseif item.flags.on_fire then
	vprintf("Warning: skipping %s: .on_fire", desc)
    elseif item.flags.melt then
	vprintf("Warning: skipping %s: .melt", desc)
    --	allow .hidden
--[[ THIS CHANGED FROM .in_chest TO .25 IN 0.50.14, unknown reasons.
    elseif item.flags.in_chest then
--]]
    -- RESOLVED: how to refer to a flag that is a number ?
    -- A: in square brackets, or in square brackets as a string.  [25] or ['25']
    elseif item.flags[25] then
	vprintf("Warning: skipping %s: .in_chest/.25", desc)
    elseif item.flags.use_recorded then
	vprintf("Warning: skipping %s: .use_recorded", desc)
    elseif item.flags.artifact_mood then
	vprintf("Warning: skipping %s: .use_recorded", desc)
    --	allow .temps_computed
    --	allow .weight_computed
--[[ THIS CHANGED FROM .unk30 TO .top_open IN 0.50.14, unknown reasons.
    elseif item.flags.unk30 then
--]]
    elseif item.flags.top_open then
	vprintf("Warning: skipping %s: .unk30/.top_open", desc)
    --	allow .from_worldgen
    elseif item.flags2.has_rider then
	vprintf("Warning: skipping %s: .has_rider", desc)
--[[ THIS CHANGED FROM .unk1 TO .forbid_on_unretire IN 0.50.14, unknown reasons.
    elseif item.flags2.unk1 then
--]]
    elseif item.flags2.forbid_on_unretire then
	vprintf("Warning: skipping %s: .unk1/.forbid_on_unretire", desc)
    --	allow .grown
    --	allow .unk_book
    --	NOTE: .unk_book CHANGED TO .location_reserved IN 0.50.14, unknown reasons.
    --	TODO: test flags2 .4 through .31 ??  They do get set sometimes.
    --	NOTE: .utterly_destroyed ADDED IN 0.50.14, unknown reasons.
    --	NOTE: .might_contain_artifact ADDED IN 0.50.14, unknown reasons.


    -- TODO are there any relevant GeneralRef's ?
    --elseif nil ~= dfhack.items.getGeneralRef(item, df.general_ref_xxxst) then
    --  vprintf("Warning: skipping %s: GeneralRef xxx", desc)

    -- TODO maybe delete the GeneralRef df.general_ref_type.UNIT_ITEMOWNER
    --   and clear flags.owner ??  hmm, also delete the item.id from unit.owned_items[] .
    

    else -- item is okay to deal with.  verify the building and do the job.
	-- local pos = xyz2pos(building.centerx, building.centery, building.z)
	local pos = utils.getBuildingCenter(building)

	-- TODO is this step necessary?  Probably not.
	if not dfhack.items.moveToGround(item, pos) then
	    vprintf("Warning: skipping %s: moveToGround() failed.", desc)
	    return
	end

	if not dfhack.items.moveToBuilding(item, building) then
	    vprintf("Warning: skipping %s: moveToBuilding() failed.", desc)
	    return
	end

	-- strangely, dfhack.items.moveToBuilding() doesn't set .in_building.
	-- no, that's because it has a special meaning.  it normally means the item is PART OF
	--  the building, but for the trade depot it means the item is for sale, and for
	--  display furniture it means the item is on display.
	item.flags.in_building = true

	-- TODO: no, these should be set by the moveToBuilding() function.
	item.flags.on_ground = false
	item.flags.in_inventory = false
	item.flags.dump = false
	item.flags.forbid = true	-- I think I want this.
	item.flags.trader = false -- it can happen that .trader items end up on the ground,
				--  sometimes visitors bring them and drop them.  Claim them.
				--  (Do they drop them when they are grabbed for interrogation?)

	-- from here on, I just want to abort the script on failure.
	--   failure means the game is in an inconsistent state.

	-- TODO try some game with a safecall() or pcall() and windback on failure?

	-- Okay.  It's in the building.  Now we need to display it.
	local igr = df.general_ref_building_display_furniturest:new()
	igr.building_id = building.id
	item.general_refs:insert('#', igr)

	-- on brief inspection (one example, 3 .displayed_items[]) this is probably sorted.
	-- DONE check that, because if it's sorted, it gets out-of-sync with the building contents.
	-- Answer: checked with an 80-item pedestal.
	--   building.contained_items[] also gets sorted by item/id.  But just the .mode 0 items,
	--   the .mode 2 item still comes first.
	-- DONE2: Actually, I have a pedestal with NONSORTED items in lockstep.
	--   I now suspect that they get incidentally sorted during the fortress map load.
	-- Accordingly, I am going to NOT keep .displayed_items sorted; I will insert in lockstep
	--   with .contained_items.
	--utils.insert_sorted(building.displayed_items, item.id)
	building.displayed_items:insert('#', item.id)

	-- ... and we're done.

    end -- big if
end



-- GLOBAL for persistence.  Uses the .id instead of the actual building object to 
--   prevent problems from objects being moved around in memory, deallocated, etc.
buildingid = buildingid or -1


-- if Viewing a building and that building's type is display furniture, cache that building's id.
local building = dfhack.gui.getSelectedBuilding(true)
if building ~= nil then
    if df.building_display_furniturest:is_instance(building) then
	buildingid = building.id
	vprintf("Targetting %s (id %d)", utils.getBuildingName(building), buildingid)
	return
    else
	-- TODO complain.
	return
    end
end


if buildingid == -1 then
    printf("First, you must specify a display furniture building, "..
	    "by running this script while Viewing the building.")
    return
end


local building = df.building.find(buildingid)
if building == nil then   -- this could happen e.g. if the building is deconstructed.
    printf("Error: could not find building with id %d", buildingid)
    return
end


if not df.building_display_furniturest:is_instance(building) then   -- can't happen.
    printf("Error: targetted building (id %d) is not display furniture", buildingid);
    return
end


-- TODO do this for all items in a tile.
-- TODO do this to all items in a user-selected rectangle.
--	in both cases, with options for forbidden/unforbidden
local items = { dfhack.gui.getSelectedItem() }


for _, item in ipairs(items) do
    if item ~= nil then
	put_item_on_display_teleport(item, building)
    end
end


-- TODO consider catching SC_WORLD_UNLOADED and invalidating buildingid.