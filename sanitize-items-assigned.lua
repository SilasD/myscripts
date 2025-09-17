local fix = ({...})[1] == 'fix'		-- TODO use real command-line parameters

local utils=require('utils')
local world = df.global.world
local plotinfo = (df.global._fields.plotinfo ~= nil) and df.global.plotinfo or df.global.ui



local function printf(...)
    print(string.format(...))
end


--------------------------------------------------------------------------------------------------------
-- Returns none/some/all of the current fort's squads, filtered by the test callback.
--
---@param test fun(squad:df.squad):boolean
---@return df.squad[]
function get_filtered_squads(test)
    ---@type (df.squad.id|integer)[]
    local squad_ids = df.historical_entity.find(plotinfo.group_id).squads
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
-- Caution!  This will happily return units that are not in world.units.active, i.e.
--   not on the map.  If you only want active units, you must check e.g. .isActive()
--   in your test callback.
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
-- Given a squad, returns a list of all soldiers in that squad,
--   and a corresponding list of their positions.
--
---@param  squad df.squad
---@return df.unit[], df.squad_position[]
local function get_all_soldiers_in_squad(squad)
    ---@param squad df.squad
    ---@param position df.squad_position
    ---@param unit df.unit
    ---@return boolean
    local function test(squad, position, unit)
        return true
    end

    return get_filtered_soldiers_in_squad(squad, test)
end


--------------------------------------------------------------------------------------------------------
---@param spos df.squad_position
---@return (df.item.id|integer)[]  -- sorted
local function get_squad_position_assigned_item_ids(spos)
    local ids = {}  -- sorted
    
    local eq = spos.equipment
    local uni = eq.uniform
    local assi = eq.assigned_items
    for k1, v1 in pairs(uni) do
        for _, v2 in ipairs(v1) do
            for _, id in ipairs(v2.assigned) do
                utils.insert_sorted(ids, id)
            end
        end
    end
    for _, special in ipairs({"quiver", "backpack", "flask"}) do
        local id = eq[special]
        if id ~= -1 then
            utils.insert_sorted(ids, id)
        end
    end
    local fix = false  -- override fixing while testing uniform-unstick
    local bad = false
    local z1 = utils.clone(assi)
    local z2 = utils.clone(assi)
    table.sort(z2)
    for i, _ in ipairs(z1) do
        if z1[i] ~= z2[i] then
            print("WARNING: .assigned_items not sorted%s", (fix) and "; fixing" or "")
            bad = true
            break
        end
    end
    if #assi ~= #ids then 
        printf("WARNING: .assigned_items length mismatch %d:%d %s", #assi, #ids,
		(fix) and "; fixing" or "")
        bad = true
    else
        for i,id in ipairs(ids) do
            if z1[i] ~= id then
                printf("WARNING: .assigned_items id mismatch%s", (fix) and "; fixing" or "")
                bad = true
                break
            end
        end
    end
    if (fix) and (bad) then
        assi:resize(0)
        for _, id in ipairs(ids) do
            utils.insert_sorted(assi, id)
        end
    elseif (bad) then
	printf("WARNING: .assigned_items vector was bad; NOT FIXED")
    end
    return ids
end


--------------------------------------------------------------------------------------------------------
---@return (df.item.id|integer)[]  -- sorted
local function collect_all_ids_in_uniform()
    local ids_in_uniforms = {}  -- sorted
    for _, squad in ipairs(get_all_squads()) do
        for i, spos in ipairs(squad.positions) do
            local ids = get_squad_position_assigned_item_ids(spos)
            for _, id in ipairs(ids) do
                if not utils.insert_sorted(ids_in_uniforms, id) then
                    printf("Warning: double id %d", id)
                    -- don't try to fix; that's not this scripts job.
                end
            end
        end
        for _, id in ipairs(squad.ammo.ammo_items) do
            if not utils.insert_sorted(ids_in_uniforms, id) then
                printf("Warning: double id %d in squad ammo", id)
            end
        end
    end
    for _, id in ipairs(plotinfo.equipment.work_weapons) do
        if not utils.insert_sorted(ids_in_uniforms, id) then
            printf("Warning: double id %d in hunter weapons", id)
        end
    end
    for _, id in ipairs(plotinfo.equipment.ammo_items) do
        if not utils.insert_sorted(ids_in_uniforms, id) then
            printf("Warning: double id %d in hunter ammo", id)
        end
    end
    return ids_in_uniforms
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
		    id, gRD(item), (fix) and "; CAN'T FIX" or "")
	    end
            local type = df.item_type[item:getType()]
            local _, in_eqa, _ = utils.binsearch(eqa[type], id)
            local _, in_equ, _ = utils.binsearch(equ[type], id)
            if not in_eqa and in_equ then
                printf("Warning: item %d %s is not in .items_assigned and is in .items_unassigned%s",
                    id, gRD(item), (fix) and "; fixing" or "")
            elseif not in_eqa and item.flags.artifact then
                -- nothing!  it turns out that pseudo-artifacts are not in eqa, and that's okay.
            elseif not in_eqa then
                printf("Warning: item %d %s is not in .items_assigned%s",
                    id, gRD(item), (fix) and "; fixing" or "")
            elseif in_equ then
                printf("Warning: item %d %s is in .items_unassigned%s",
                    id, gRD(item), (fix) and "; fixing" or "")
            end
            if fix then
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
                    id, gRD(item), (fix) and "; fixing" or "")
            elseif in_eqa then
                printf("WARNING: item %d %s is not in fort but is .items_assigned%s",
                    id, gRD(item), (fix) and "; fixing" or "")
            elseif in_equ then
                printf("WARNING: item %d %s is not in fort but is .items_unassigned%s",
                    id, gRD(item), (fix) and "; fixing" or "")
            else
                printf("Warning: item %d is not in fort", id)
            end
            if fix then
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

    -- TODO these comments are old
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

	    local fixing = (fix) and "; fixing" or ""
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
		if fix then
		    utils.erase_sorted(equ[item_type], id)
		end
	    end

            if utils.binsearch(ids, id) then
                -- good case.  nothing?
            elseif (item) and item.flags.artifact then
		-- grown attached to.  nothing?
	    else
		printf("Warning: %s is in .items_assigned but not in any uniform%s",
			desc, fixing)
		if fix then
		    utils.erase_sorted(eqa[item_type], id)
		    utils.insert_sorted(equ[item_type], id)
		end
	    end
        end
        local tequ = {}
	for _, id in ipairs(equ[item_type]) do table.insert(tequ, id); end
	for _, id in ipairs(tequ) do

	    local fixing = (fix) and "; fixing" or ""
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
		if fix then
		    utils.erase_sorted(equ[item_type], id)
		end
	    end
	end
    end
end


local ids = collect_all_ids_in_uniform()
verify_uniforms_un_assigned(ids)
-- TODO verify squad-level assignments (basically AMMO)
verify_items_un_assigned(ids)


--[=[
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

