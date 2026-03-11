
-- TODO I believe this does NOT take into account the fact that items can be assigned
-- to unoccupied positions' uniforms.

local check_assigned_items = true	-- sanity-check squad_position.equipment.assigned_items ?
local fix_items_assigned = ({...})[1] == '--fix'	-- TODO use real command-line parameters

local utils = require('utils')
local world = df.global.world
local plotinfo = (df.global._fields.plotinfo ~= nil) and df.global.plotinfo or df.global.ui


local function printf(...)
    print(string.format(...))
end


local stats = {}

---@param stat string
---@param delta integer?
local function record(stat, delta)
    stats[stat] = (stats[stat] or 0) + (delta or 1)
end


--------------------------------------------------------------------------------------------------------
-- Returns none/some/all of the current fort's squads, filtered by the test callback.
--
---@param test fun(squad:df.squad):boolean
---@return df.squad[]
function get_filtered_squads(test)
    ---@type (df.squad.id|integer)[]
    local squad_ids = plotinfo.main.fortress_entity.squads
    ---@type df.squad[]
    local squads = {}

    for _, squad_id in ipairs(squad_ids) do
	local squad = df.squad.find(squad_id)
        if (squad) and test(squad) then
	    table.insert(squads, squad)
	end
    end

    return squads
end


--------------------------------------------------------------------------------------------------------
-- Returns all of the current fort's squads, including empty squads.
--
---@return df.squad[]
local function get_all_squads()
    ---@param squad df.squad
    ---@return boolean
    local test = function(squad)
	return true
    end

    return get_filtered_squads(test)
end


--------------------------------------------------------------------------------------------------------
-- Given a squad and a test callback, returns a list of some/all/none of the soldiers in the squad,
--   and a corresponding list of their positions, both filtered by the test callback.
--
-- The test callback should take a df.squad, a df.squad_position, and a df.unit.
--   It should return true iff the unit should be included in the returned list.
--   The callback is only called for valid, existing units.
--
-- Caution!  This will happily return units that are not in the fort / not on the map.
--   If you only want active units, you must check e.g. .isActive() in your test callback.
--
---@param  squad df.squad
---@param  test fun(squad:df.squad, position:df.squad_position, unit:df.unit):boolean
---@return df.unit[], df.squad_position[]
local function get_filtered_soldiers_in_squad(squad, test)
    local soldiers = {}
    local positions = {}
    for _, pos in ipairs(squad.positions) do
	-- note: df.historical_figure.find returns nil if it can't find the hf with that hf.id.
	local hf = (pos.occupant ~= -1) and df.historical_figure.find(pos.occupant) or nil
	local unit = (hf) and df.unit.find(hf.unit_id) or nil
	if (unit) and test(squad, pos, unit) then
	    table.insert(soldiers, unit)
	    table.insert(positions, pos)
        end
    end
    return soldiers, positions
end


--------------------------------------------------------------------------------------------------------
-- Given a squad, returns a list of all soldiers in that squad who are present in the fort,
--   and a corresponding list of their positions.
--
---@param  squad df.squad
---@return df.unit[], df.squad_position[]
local function get_active_soldiers_in_squad(squad)
    ---@param squad df.squad
    ---@param position df.squad_position
    ---@param unit df.unit
    ---@return boolean
    local function test(squad, position, unit)
        return dfhack.units.isActive(unit)
    end

    return get_filtered_soldiers_in_squad(squad, test)
end


local function get_inactive_soldiers_in_squad(squad)
    ---@param squad df.squad
    ---@param position df.squad_position
    ---@param unit df.unit
    ---@return boolean
    local function test(squad, position, unit)
        return not dfhack.units.isActive(unit)
    end

    return get_filtered_soldiers_in_squad(squad, test)
end


--------------------------------------------------------------------------------------------------------
---@param squad_position  df.squad_position
---@return (df.item.id|integer)[]  -- unsorted, not deduplicated, does not contain -1's.
local function get_squad_position_assigned_item_ids(squad_position)
    local ids = {}

    local function add_id(id)
	-- TODO maybe: check for duplicates here?  Gauntlets and boots could potentially duplicate.
	if id ~= -1 then table.insert(ids, id); end
    end

    -- get all items out of the triply-nested structure
    for _, squad_uniform_specs in pairs(squad_position.equipment.uniform) do
	for _, squad_uniform_spec in ipairs(squad_uniform_specs) do
	    for _, id in ipairs(squad_uniform_spec.assigned) do
		add_id(id)
	    end
	end
    end
    for _, special in ipairs({"quiver", "backpack", "flask"}) do
	add_id(squad_position.equipment[special])
    end

    if not check_assigned_items then return ids; end

    -- sanity-check and optionally fix .assigned_items
    local assigned_items = squad_position.equipment.assigned_items
    local bad = false
    local ids2 = utils.clone(ids)
    table.sort(ids2)  -- ignore the possibility of duplicates

    repeat  -- runs once; this idiom allows break to work
	-- TODO maybe: give a more informative warning (unit name, squad name, position number).
	local warning = string.format("WARNING: squad position %s .assigned_items:", tostring(squad_position))
	local fixing = (fix_items_assigned) and "; fixing" or ""

	for i = 0, #assigned_items-2 do  -- verify sorted
	    if not (assigned_items[i] < assigned_items[i+1]) then
		bad = true
		record("AI_UNSORTED")
		printf("%s is not sorted%s", warning, fixing)
		break
	    end
	end
	if #assigned_items ~= #ids2 then  -- verify correct length
	    bad = true
	    record("AI_BADLENGTH")
	    printf("%s length is not equal to proper length%s", warning, fixing)
	    break
	end
	for i = 0, #assigned_items-1 do  -- verify correct contents
	    if assigned_items[i] ~= ids2[i+1] then  -- comparing a 0-based C++ vector with a 1-based Lua list.
		bad = true
		record("AI_BADCONTENTS")
		printf("%s contents do not match proper contents%s", warning, fixing)
		break
	    end
	end
    until true

    if (bad) and (fix_items_assigned) then
	assigned_items:resize(0)
	assigned_items:assign(ids2)  -- auto-vivification is so cool.
    end

    return ids
end


--------------------------------------------------------------------------------------------------------
--
-- Does not return items assigned to units that are away on a mission.
--
--  TODO items assigned to units that are away on a mission may be in-play if they left without wearing them.
--
---@return (df.item.id|integer)[], (df.item.id|integer)[]
--	item ids which are in uniforms	sorted, deduplicated;
--	raw item ids in uniforms	unsorted, not deduplicated;
--	raw item ids to ignore		unsorted, not deduplicated.
local function collect_all_actually_assigned_items()
    local raw_ids = {}	-- item ids from each .isActive() squad position, squad ammo, and hunter weapons/ammo.
    local ignore = {}	-- item ids from not .isActive() squad positions; that is, units not in the fort.

    function table_append(source, dest)
	if not (type(source) == 'table' or source._kind == 'container') then error(); end
	if type(dest) ~= 'table' then error(); end
	local t = utils.clone(source)  -- coerce to Lua table
	table.move(t, 1, #t, #dest+1, dest)
    end

    for _, squad in ipairs(get_all_squads()) do
	local _, positions = get_active_soldiers_in_squad(squad)
	for i, spos in ipairs(positions) do
	    table_append(get_squad_position_assigned_item_ids(spos), raw_ids)
	end
	table_append(squad.ammo.ammo_items, raw_ids)

	local _, positions = get_inactive_soldiers_in_squad(squad)
	for i, spos in ipairs(positions) do
	    table_append(get_squad_position_assigned_item_ids(spos), ignore)
	end
    end
    table_append(plotinfo.equipment.work_weapons, raw_ids)
    table_append(plotinfo.equipment.ammo_items, raw_ids)

    -- deduplicate -- is there a better way?  utils.insert_sorted()?  But that's implemented in Lua too.
    local ids_map = {}
    local all_ids = {}
    for _, id in ipairs(raw_ids) do
	ids_map[id] = true
    end
    for k, _ in pairs(ids_map) do
	table.insert(all_ids, k)
    end

    table.sort(all_ids)
    return all_ids, raw_ids
end


--------------------------------------------------------------------------------------------------------
---@param ids (df.item.id|integer)[]  -- must be sorted
local function verify_uniforms_un_assigned(ids)
    local eqa = plotinfo.equipment.items_assigned
    local equ = plotinfo.equipment.items_unassigned
    local IN_PLAY = world.items.other.IN_PLAY
    local gRD = dfhack.items.getReadableDescription

    for _, id in ipairs(ids) do
        local item = utils.binsearch(IN_PLAY, id, 'id')
        -- TODO refactor; there's duplicated code
        if item then
	    if item.flags.in_building then
		printf("WARNING! item %d %s is .in_building%s",
		    id, gRD(item), (fix_items_assigned) and "; CAN'T FIX" or "")
	    end
            local type = df.item_type[item:getType()]
            local _, in_eqa, _ = utils.binsearch(eqa[type], id)
            local _, in_equ, _ = utils.binsearch(equ[type], id)
            if not in_eqa and in_equ then
                printf("Warning: item %d %s is not in .items_assigned and is in .items_unassigned%s",
                    id, gRD(item), (fix_items_assigned) and "; fixing" or "")
            elseif not in_eqa and item.flags.artifact then
                -- nothing!  it turns out that pseudo-artifacts are not in eqa, and that's okay.
            elseif not in_eqa then
                printf("Warning: item %d %s is not in .items_assigned%s",
                    id, gRD(item), (fix_items_assigned) and "; fixing" or "")
            elseif in_equ then
                printf("Warning: item %d %s is in .items_unassigned%s",
                    id, gRD(item), (fix_items_assigned) and "; fixing" or "")
            end
            if fix_items_assigned then
                utils.insert_sorted(eqa[type], id)
                utils.erase_sorted(equ[type], id)
            end
        else
            local item = df.item.find(id)
            if not item then
                printf("WARNING: item %d %s does not exist",
                    id, "(no description)")
                -- TODO MAYBE: could walk every single .items_{un}assigned.* vector
                goto continue
            end
            local type = df.item_type[item:getType()]
            local _, in_eqa, _ = utils.binsearch(eqa[type], id)
            local _, in_equ, _ = utils.binsearch(equ[type], id)
            if in_eqa and in_equ then
                printf("WARNING: item %d %s is not in fort but is in both .items_assigned and .items_unassigned%s",
                    id, gRD(item), (fix_items_assigned) and "; fixing" or "")
            elseif in_eqa then
                printf("WARNING: item %d %s is not in fort but is .items_assigned%s",
                    id, gRD(item), (fix_items_assigned) and "; fixing" or "")
            elseif in_equ then
                printf("WARNING: item %d %s is not in fort but is .items_unassigned%s",
                    id, gRD(item), (fix_items_assigned) and "; fixing" or "")
            else
                printf("Warning: item %d is not in fort", id)
            end
            if fix_items_assigned then
                utils.erase_sorted(eqa[type], id)
                utils.erase_sorted(equ[type], id)
            end
            ::continue::
        end
    end
end


--------------------------------------------------------------------------------------------------------
---@param ids (df.item.id|integer)[]  -- must be sorted
local function verify_items_un_assigned(ids)

    -- TODO this needs rewritten and refactored for clarity.

    -- TODO these comments are old and do not describe the current algorithm.
    -- okay, so now we need to walk .items_unassigned.* and .items.other.* at the same time,
    --   checking that, for every nonzero .items_unassigned.* vector,
    --   for every item in the matching .items.other.* vector : check that its item_id
    --   * is in the ids parameter
    --   * or is in .items_unassigned.*
    -- note: it appears that we want to use e.g. items.other.ARMOR instead of items.other.ANY_TRUE_ARMOR
    --
    -- for every relevant type, walk its items.other.* vector, checking that the item_id
    --   *    is .flags.in_building
    --   * or is in both ids and its .items.assigned.* vector
    --   * or is in its .items.unassigned.* vector
    -- note: it appears that we want to use e.g. items.other.ARMOR instead of items.other.ANY_TRUE_ARMOR

    local relevant = ([[
	FLASK
	WEAPON
	ARMOR
	SHOES
	SHIELD
	HELM
	GLOVES
	PANTS
	BACKPACK
	QUIVER
    ]]):trim():split("%s+")
	-- TODO handle AMMO which is per-squad not per-uniform

    local eqa = plotinfo.equipment.items_assigned
    local equ = plotinfo.equipment.items_unassigned
    local IN_PLAY = world.items.other.IN_PLAY
    local gRD = dfhack.items.getReadableDescription

    for _, item_type in ipairs(relevant) do
	-- print(item_type)
	local teqa = {}
	for _, id in ipairs(eqa[item_type]) do table.insert(teqa, id); end
	for _, id in ipairs(teqa) do

	    local fixing = (fix_items_assigned) and "; fixing" or ""
	    local desc = ""
	    local item = utils.binsearch(IN_PLAY, id, 'id')
	    if item then
		desc = gRD(item)
	    else
		item = df.item.find(id)
		desc = (item) and ("{not in fort} " .. gRD(item)) or "{no such item}"
	    end
	    desc = string.format("item %d %s", id, desc)

	    if utils.binsearch(equ[item_type], id) then
		printf("Warning: %s is in both .items_assigned and .items_unassigned%s",
			desc, fixing)
		if fix_items_assigned then
		    utils.erase_sorted(equ[item_type], id)
		end
	    end

	    if utils.binsearch(ids, id) then
		-- good case.  nothing?
	    elseif (item) and item.flags.artifact then
		-- grown attached to.  nothing?
		-- TODO what are the indicators?  .artifact but not .artifact_mood,
		--   .artifact but quality level is < 6.
	    else
		printf("Warning: %s is in .items_assigned but not in any uniform%s",
			desc, fixing)
		if fix_items_assigned then
		    utils.erase_sorted(eqa[item_type], id)
		    utils.insert_sorted(equ[item_type], id)
		end
	    end
	end

	local tequ = {}
	for _, id in ipairs(equ[item_type]) do table.insert(tequ, id); end
	for _, id in ipairs(tequ) do

	    local fixing = (fix_items_assigned) and "; fixing" or ""
	    local desc = ""
	    local item = utils.binsearch(IN_PLAY, id, 'id')
	    if item then
		desc = gRD(item)
	    else
		item = df.item.find(id)
		desc = (item) and ("{not in fort} " .. gRD(item)) or "{no such item}"
	    end
	    desc = string.format("item %d %s", id, desc)

	    if utils.binsearch(ids, id) then
		printf("Warning: %s is in .items_unassigned and is in a uniform%s",
			desc, fixing)
		if fix_items_assigned then
		    utils.erase_sorted(equ[item_type], id)
		end
	    end
	end
    end
end


if fix_items_assigned then
    print("trying to fix up the items_assigned and items_unassigned vectors.")
else
    print("analyzing only.  to attempt repairs, re-run with '--fix'.")
end
local all_ids, raw_ids = collect_all_actually_assigned_items()
-- TODO check for items that do not exist or are not IN_PLAY
verify_uniforms_un_assigned(all_ids)
-- TODO verify squad-level assignments (basically AMMO)
verify_items_un_assigned(all_ids)


--[=[
DEAD
local printed_header = false
for _,v in ipairs(plotinfo.equipment.items_assigned) do
    local purge = {}
    for _,id in ipairs(v) do
	if not utils.binsearch(world.items.all, id, 'id') then
	    if not printed_header then print('assigned military items'); printed_header = true; end
	    print('item does not exist',tostring(v), id, (fix) and 'fixing' or '')
	    table.insert(purge, id)
        elseif not utils.binsearch(world.items.other.IN_PLAY, id, 'id') then
	    if not printed_header then print('assigned military items'); printed_header = true; end
	    print('item is not in fort', tostring(v), id, (fix) and 'fixing' or '')
	    table.insert(purge, id)
        end
    end
    for _,id in ipairs(purge) do
	if not fix then break; end
	utils.erase_sorted(v, id)
    end
end


DEAD
printed_header = false
for _,v in ipairs(plotinfo.equipment.items_unassigned) do
    local purge = {}
    for _,id in ipairs(v) do
	if not utils.binsearch(world.items.all, id, 'id') then
	    if not printed_header then print('\nunassigned military items'); printed_header = true; end
	    print('item does not exist',tostring(v), id, (fix) and 'fixing' or '')
	    table.insert(purge, id)
        elseif not utils.binsearch(world.items.other.IN_PLAY, id, 'id') then
	    if not printed_header then print('\nunassigned military items'); printed_header = true; end
	    print('item is not in fort', tostring(v), id, (fix) and 'fixing' or '')
	    table.insert(purge, id)
        end
    end
    for _,id in ipairs(purge) do
	if not fix then break; end
	utils.erase_sorted(v, id)
    end
end
--]=]
