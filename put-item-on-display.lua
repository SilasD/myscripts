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

local function printf(...)
    print(string.format(...))
end

local function vprintf(...)
    if verbose then
	printf(...)
    end
end


-- most logic taken from hack/scripts/gui/caravan/pedestal.lua:is_displayable_item()
function is_displayable_item(item)

    if not item
        or item.flags.hostile
        or item.flags.removed
        or item.flags.dead_dwarf
        or item.flags.spider_web
        or item.flags.construction
        or item.flags.encased
        or item.flags.murder
        or item.flags.trader  -- SWD TODO reconsider this, per notes in put_item_on_display_teleport()
        or item.flags.owned
        or item.flags.garbage_collect
        or item.flags.on_fire

	or item.flags.already_uncategorized  -- SWD added
	-- SWD allowing .forbid, .dump, .melt, .hidden
    then
        return false
    end

    if item.flags.in_job then
        local spec_ref = dfhack.items.getSpecificRef(item, df.specific_ref_type.JOB)
        if not spec_ref then return false end
        if spec_ref.data.job.job_type ~= df.job_type.PutItemOnDisplay then return false end
    elseif item.flags.in_inventory then
        local gref = dfhack.items.getGeneralRef(item, df.general_ref_type.CONTAINED_IN_ITEM)
        if not gref then return false end
        if not is_container(df.item.find(gref.item_id)) or item:isLiquidPowder() then
            return false
        end
    end

    if not dfhack.maps.isTileVisible(xyz2pos(dfhack.items.getPosition(item))) then
        return false
    end

    -- SWD added
    if dfhack.maps.getWalkableGroup(xyz2pos(dfhack.items.getPosition(item))) == 0 then
        return false
    end

    if item.flags.in_building then
        local bld = dfhack.items.getHolderBuilding(item)
        if not bld then return false end
        for _, contained_item in ipairs(bld.contained_items) do
--[[ TODO SWD what? this logic seems wrong.  this finds ANY contained_item that isn't building construction.
            if contained_item.use_mode == df.building_item_role_type.TEMP then return true end
            -- building construction materials
            if item == contained_item.item then return false end
--]]
	    -- SWD do this instead
	    if item == contained_item.item then
		if contained_item.use_mode ~= df.building_item_role_type.TEMP then return false end
		break
	    end
        end
    end

    -- SWD TODO are there any relevant GeneralRef's ?
    --if nil ~= dfhack.items.getGeneralRef(item, df.general_ref_xxxst) then

    return true
end


function put_item_on_display_teleport(item, building)
    local desc = dfhack.items.getReadableDescription(item, 0)
    desc = string.format("%s (%d)", desc, item.id)

    if not is_displayable_item(item) then
	vprintf("\aCould not display %s; the item is not in a displayable state.", desc)
	return false
    end
    -- item is okay to deal with.  verify the building and do the job.

    -- TODO (re)verify that the building is in a reasonable state.

    -- TODO if the item has a PutItemOnDisplay job, cancel it.

    if not dfhack.items.moveToBuilding(item, building) then
	vprintf("\aWarning: skipping %s: moveToBuilding() failed.", desc)
	return false
    end

    -- strangely, dfhack.items.moveToBuilding() doesn't set .in_building.
    -- no, that's because it has a special meaning.  it normally means the item is PART OF
    --   the building, but for the trade depot it means the item is for sale, and for
    --   display furniture it means the item is on display.
    item.flags.in_building = true

    -- TODO: no, these should be set by the moveToBuilding() function.
    if item.flags.on_ground then vprintf("\aWARNING: item.flags.on_ground still set."); end
    if item.flags.in_inventory then vprintf("\aWARNING: item.flags.on_ground still set."); end
    item.flags.dump = false  -- we already verified there isn't a dump job active.
    item.flags.forbid = true	-- I think I want this.
    item.flags.trader = false	-- it can happen that .trader items end up on the ground,
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
    -- DONE3: (found later) OTOH, scripts/internal/caravan/pedestal.lua sorts them.
    --   AND it expects them to be in sorted order when removing them ,in its unassign_item().
    -- So I think I really should.
    -- TODO: check the big 0.47 fort.  Check all pedestals.
    -- TODO if this is changed, also change the similar logic in put_item_on_display_job()
    --building.displayed_items:insert('#', item.id)
    utils.insert_sorted(building.displayed_items, item.id)

    -- ... and we're done.
    return true
end


function put_item_on_display_job(item, building)
    local desc = dfhack.items.getReadableDescription(item, 0)
    desc = string.format("%s (%d)", desc, item.id)

    if not is_displayable_item(item) then
	vprintf("\aCould not display %s; the item is not in a displayable state.", desc)
	return false
    end
    -- item is okay to deal with.  verify the building and do the job.
    item.flags.forbid = false  -- let the job happen.

    -- TODO (re)verify that the building is in a reasonable state.

    local pos = xyz2pos(building.centerx, building.centery, building.z)

    -- TODO don't ADD a move-to-display job if one already exists.
    -- TODO if the job exists but is targetting the wrong building, delete it (?)

    -- from here on, I just want to abort the script on failure.
    --   failure means the game is in an inconsistent state.

    -- TODO try some game with a safecall() or pcall() and windback on failure?

    -- Mark it for display.
    item.general_refs:insert('#', 
	{ new = df.general_ref_building_display_furniturest, building_id = building.id } )

    -- see notes in put_item_on_display_teleport()
    utils.insert_sorted(building.displayed_items, item.id)

    local job = df.job:new()
    job:assign( { job_type = df.job_type.PutItemOnDisplay, pos = pos, aux_id = -1 } )
    -- I tried this:
    --    local job = df.job:new():assign({ job_type = df.job_type.PutItemOnDisplay, pos = pos, aux_id = -1 })
    -- It didn't work; it set job to nil.
    -- And this doesn't work:
    --    local job = { new = df.job, job_type = df.job_type.PutItemOnDisplay, pos = pos, aux_id = -1 }
    -- because it doesn't create the actual job, which means if it was used in multiple calls, it would
    --   instantiate multiple jobs.  If I only needed to reference the job once, it would work.

    dfhack.job.attachJobItem(job, item, df.job_role_type.Hauled, -1, -1)
    dfhack.job.addGeneralRef(job, df.general_ref_type.BUILDING_HOLDER, building.id)
    building.jobs:insert("#", job)

    dfhack.job.linkIntoWorld(job, true)

    return true
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

--local items = { df.item.find( math.tointeger(({...})[1]) ) }	-- by item.id

for _, item in ipairs(items) do
    if item ~= nil and is_displayable_item(item) then
	if false then
	    put_item_on_display_teleport(item, building)
	else
	    put_item_on_display_job(item, building)
	end
    end
end


-- TODO consider catching SC_WORLD_UNLOADED and invalidating buildingid.

--[[ An example PutItemOnDisplay job:
job:
!id		2246635
!list_link	-> some job_list_link
-posting_index	-1
!job_type	238 PutItemOnDisplay
-job_subtype	-1 None
!pos		50, 41, 38  centerx, centery, z of pedestal building.
-completion_timer -1
-maxdur		0
-flags		
-    do_now	true  (because of the prioritize script)
-    all other false or 0
-mat_type	-1
-mat_index	-1
-spell		-1
-item_type	-1
-item_subtype	-1
-specflag.whole	0
-specdata	-1, -1, -1
-material_category all false
-reaction_name	""
-expire_timer	0
-recheck_cntdn	0
!aux_id		-1
-items		[1]
-  0 item	-> the item to put on display
-    role	2 Hauled
-    flags	all false
-    job_item_idx -1
-specific_refs	empty
!general_refs	
!  general_ref_building_holderst
!   building_id	13082 the building_id
-job_items
-  elements	empty
-guide_path	x,y,z all empty
-cur_path_index	0
-spec_loc	-30000, -30000, -30000
-art_spec	-1, -1, -1
-order_id	-1

after job is taken:

building:
jobs
  0	-> the job
specific_refs	empty
general_refs	empty
contained_items	does NOT have the item (yet).
displayed_items
  0		item.id of the item.

]]
