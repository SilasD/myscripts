-- what are the viewed item(s) equipment.(un)assigned.* statuses?
local utils = require('utils')
local guidm = require('gui.dwarfmode')

local world = df.global.world
local plotinfo = df.global.plotinfo
local view_sheets = df.global.game.main_interface.view_sheets

local debugging = false

local function printf(...) print(string.format(...)); end
local function dprintf(...) if debugging == true then dfhack.printerr(string.format(...)); end; end


-- LuaLS typechecking does not support casting to fields of a class.  this is a workaround.
---@alias df.item.id integer
---@alias df.unit.id integer
---@alias df.historical_figure.id integer
---@alias df.squad.id integer

-- invert items_(un)assigned.* into a map of item id keys to boolean true (meaning exists);
--   the map also contains string keys such as "WEAPON" that themselves are maps of item id
--   keys (of that item_type) to boolean true.  these sub-maps duplicate the data in the
--   main map.
---@param vec DFEnumVector<df.item_type, integer[]>
---@return table<(df.item.id|string), (boolean|table<df.item.id, boolean>)>
local function invert_items(vec)
    local map = {}
    ---@type string,df.item.id[]
    for k,v in pairs(vec) do
        local k = tostring(k)
        assert(type(k) == "string")
        map[k] = {}
        for _,id in ipairs(v) do
            map[id] = true
            map[k][id] = true
        end
    end
    map[-2]=-2; map["BAR"][-2]=-2  -- for verification
    return map
end


--- returns a map from item ids directly to items or boolean false (meaning the item is not IN_PLAY).
--- the map also contains string keys such as "WEAPON" that themselves are maps from item ids to
---   items of that item_type. these sub-maps duplicate the data in the main map.
---@return table<df.item.id|string, df.item|boolean|table<df.item.id,df.item|boolean>>
---     boolean false means item does not exist.
local function gather_uniform_items()
--  TODO are the subkeys even useful?  I mean, the item vectors are *right there*.
--  TODO maybe: for nonexistent items, instead of false, a string describing the uniform position?
--  DONE: track double-assignment here?  no, not in scope.  detect and report if debugging.
--  TODO maybe: this should also gather info like squad, position, historical figure name,
--      bodypart index, uniform_spec index, assigned index.
--      but in a way that can be mapped to uniform ammo, and the non-squad uniform-like stuff.
--      like maybe build a unique variable name out from df.global.
--  TODO new info: assigned POSITION SYMBOLS go in .work_weapons .
    local id_map = {}
    local itypes = ("WEAPON,ARMOR,HELM,GLOVES,PANTS,SHOES,SHIELD,QUIVER,BACKPACK,FLASK,AMMO"):split(',')
    for _,itype in ipairs(itypes) do
        id_map[itype] = {}
    end

    local function add(id)
        assert(math.type(id) == "integer")
        if id == -1 then return; end
        if id_map[id] then
            dprintf("double-assigned item %d", id)
        end
        local item = df.item.find(id)
        if item then
            id_map[id] = item
            local key = df.item_type[item:getType()]
            if id_map[key] then
                id_map[key][id] = item
            else
                print("!! DIFFERENT ITEM TYPE!", key)
            end
        else
            dprintf("nonexistent assigned item %d", id)
            id_map[id] = false
        end
    end

    for _,id in ipairs(plotinfo.equipment.work_weapons) do add(id); end
    for _,id in ipairs(plotinfo.equipment.ammo_items) do add(id); end
    for _,ammo_spec in ipairs(plotinfo.equipment.hunter_ammunition) do
        -- DONE:not sure if this can legally be a double-allocation with .ammo_items above.
        --   A: YES, it absolutely is legal.  moreover, this can contain more items than the .ammo_items.
        -- TODO test some hunters already!
        for _,id in ipairs(ammo_spec.assigned) do add(id); end
    end
    for _,squad_id in ipairs(plotinfo.main.fortress_entity.squads) do
        local had_member = false
        local squad = df.squad.find(squad_id) or qerror("no squad")
        ---@cast squad -nil
        for _,pos in ipairs(squad.positions) do
            if pos.occupant == -1 then goto continue_positions; end
            had_member = true
            local eq = pos.equipment
            for _,id in ipairs({eq.quiver, eq.backpack, eq.flask}) do add(id); end

            for _,bodypart in pairs(eq.uniform) do
                for _,uniform_spec in ipairs(bodypart) do
                    for _,id in ipairs(uniform_spec.assigned) do
                        add(id)
                    end
                end
            end
            ::continue_positions::
        end
        if had_member then
            for _,id in ipairs(squad.ammo.ammo_items) do add(id); end
            for _,ammo_spec in ipairs(squad.ammo.ammunition) do
                for _,id in ipairs(ammo_spec.assigned) do add(id); end
            end
        end
        ::continue_squad::
    end

    return id_map
end

-- this does NOT look inside buildings.
---@param pos df.coord
---@param item_ids table<df.item.id, df.item>  # IN/OUT
local function glom_items_on_this_tile(pos, item_ids)
    assert((type(pos) == "table" or df.coord:is_instance(pos))
        and math.type(pos.x) == "integer" and pos.x ~= -30000
        and math.type(pos.y) == "integer" and math.type(pos.z) == "integer")
    local block = dfhack.maps.getTileBlock(pos)
    assert(block)
    assert(df.map_block:is_instance(block))
    for _, item_id in ipairs(block.items) do
        -- note that we could potentially cache item id -> item pos, or item id -> item.
        -- (no gain in a one-tile run, but major gains if we e.g. walk a stockpile.)
        local item = df.item.find(item_id)
        assert(item)
        assert(df.item:is_instance(item))
        local ipos = xyz2pos(dfhack.items.getPosition(item))
        assert(ipos and type(ipos) == "table" and math.type(ipos.x) == "integer" and ipos.x ~= -30000
            and math.type(pos.y) == "integer" and math.type(pos.z) == "integer")
        if same_xyz(pos, ipos) then
            utils.insert_sorted(item_ids, item.id)
            for _,item in ipairs(dfhack.items.getContainedItems(item)) do
                utils.insert_sorted(item_ids, item.id)
                for _,item in ipairs(dfhack.items.getContainedItems(item)) do
                    utils.insert_sorted(item_ids, item.id)
                end
            end
        end
    end
end

-- this does NOT look inside buildings.
---@param item df.item
---@param item_ids table<df.item.id, df.item>  # IN/OUT
local function glom_items_on_this_items_tile(item, item_ids)
    assert(item and df.isvalid(item) and df.item:is_instance(item))
    assert(dfhack.items.getGeneralRef(item, df.general_ref_type.BUILDING_HOLDER) == nil)
    assert(dfhack.items.getGeneralRef(item, df.general_ref_type.UNIT_HOLDER) == nil)
    local pos = xyz2pos(dfhack.items.getPosition(item))
    assert(pos and type(pos) == "table" and math.type(pos.x) == "integer" and pos.x ~= -30000)
    return glom_items_on_this_tile(pos, item_ids)
end

local suppress = false
local i_as = invert_items(plotinfo.equipment.items_assigned)
local i_un = invert_items(plotinfo.equipment.items_unassigned)
assert(type(i_as.WEAPON) == "table")
assert(i_as[-2] == -2)      -- verification
assert(i_as.BAR[-2] == -2)  -- verification
local unif_map = gather_uniform_items()
local item_ids = {}
local sitem = dfhack.gui.getSelectedItem(true)
local unit = dfhack.gui.getSelectedUnit(true)
local building = dfhack.gui.getSelectedBuilding(true)
local stockpile = dfhack.gui.getSelectedStockpile(true)
local civzone = dfhack.gui.getSelectedCivZone(true)

-- TODO should we table.insert instead of insert_sorted ?  to e.g. preserve inventory order.


-- TODO this is getting confusing.  refactor.
if sitem then
    local ref = dfhack.items.getOuterContainerRef(sitem)
--print("ref:"); printall(ref); print("---")
    -- there seems to be some confusion about this API return value.
    -- per docs it should return
    -- with ref.type == df.specific_ref_type.(UNIT|ITEM_GENERAL|VERMIN_EVENT)
    --    but it returns ref.type == true
    -- AND it should return ref.data == a unit, item, or vermin ,
    --    but it returns ref.object ==  a unit, item, or vermin .
    -- accordingly I have written this code to accept either .data or .object.
    ---@diagnostic disable-next-line: undefined-field
    local container = ref.data or ref.object
--print("container:", container, df.isvalid(container), df.unit:is_instance(container), df.item:is_instance(container))
    -- does not work: if ref.type == df.specific_ref_type.UNIT then
    if df.unit:is_instance(container) then
        ---@diagnostic disable-next-line: cast-local-type
        unit = container
        assert(df.unit:is_instance(unit))
        -- fall through
    -- does not work: elseif ref.type == df.specific_ref_type.ITEM_GENERAL then
    elseif df.item:is_instance(container) then
        ---@diagnostic disable-next-line: param-type-mismatch
        glom_items_on_this_items_tile(container, item_ids)
        assert(#item_ids > 0)
        sitem = nil
    elseif container then
        print("ref:", ref); printall(ref)
        assert(false, "NOTREACHED")  -- df.unit and df.item cases handles above, can't have a VERMIN_EVENT.
    else
        qerror("getOuterContainerRef didn't work! " .. tostring(ref) ..
                (df.isvalid(ref) and ref._type or type(ref)))
    end
end


local args = ...

if args == "--all" then
    for _,key in ipairs(
        ("WEAPON,ARMOR,HELM,GLOVES,PANTS,SHOES,SHIELD,QUIVER,BACKPACK,FLASK,AMMO"):split(',')
    ) do
        for _,item in ipairs(world.items.other[key]) do
            table.insert(item_ids, item.id)
        end
    end
    table.sort(item_ids)
    printf("item count %d", #item_ids)
    suppress = true
elseif unit then
    for _, invitem in ipairs(unit.inventory) do
        assert(invitem._type == df.unit_inventory_item)
        assert(df.item:is_instance(invitem.item))
        local item = invitem.item
        utils.insert_sorted(item_ids, item.id)
        for _,item in ipairs(dfhack.items.getContainedItems(item)) do
            utils.insert_sorted(item_ids, item.id)
            for _,item in ipairs(dfhack.items.getContainedItems(item)) do
                utils.insert_sorted(item_ids, item.id)
            end
        end
    end
    local pos = xyz2pos(dfhack.units.getPosition(unit))
    glom_items_on_this_tile(pos, item_ids)
    if view_sheets.open == true and view_sheets.active_sheet == df.view_sheet_type.UNIT then
        for _, item_id in ipairs(view_sheets.viewing_itid) do
            utils.insert_sorted(item_ids, item_id)
        end
    end
elseif building then
    for _, bitem in ipairs(building.contained_items) do
        assert(bitem._type == df.buildingitemst)
        utils.insert_sorted(item_ids, bitem.item.id)
    end
    if view_sheets.open == true and view_sheets.active_sheet == df.view_sheet_type.BUILDING then
        for _, item_id in ipairs(view_sheets.viewing_itid) do
            utils.insert_sorted(item_ids, item_id)
        end
        -- TODO what about items in containers in buildings?
    end
elseif sel_stockpile then
    qerror("figure out how to handle stockpiles!")
elseif sel_civzone then
    qerror("figure out how to handle civzones!")
elseif view_sheets.open == true and view_sheets.active_sheet == df.view_sheet_type.ITEM_LIST then
    print("TODO get contained items")
    for _, item_id in ipairs(view_sheets.viewing_itid) do
        utils.insert_sorted(item_ids, item_id)
    end
elseif guidm.getCursorPos() then
    local cursor = guidm.getCursorPos()
    glom_items_on_this_tile(cursor, item_ids)
else
    -- nothing; maybe this was the get-all-items-on-selected-item's-tile case.
end

assert(#item_ids > 0, "NOTREACHED: no items.")

printf("%-8s%-8s%-8s%-8s%-2s%s", "item id", "uniform", "assign", "unassig", "", "description")
for _, item_id in ipairs(item_ids) do
    assert(math.type(item_id) == "integer")
    local item = df.item.find(item_id)
    assert(item)
    ---@cast item df.item_actual
    local uniform    = not not unif_map[item_id]
    local assigned   = not not i_as[item_id]
    local unassigned = not not i_un[item_id]
    local gref_isart = dfhack.items.getGeneralRef(item, df.general_ref_type.IS_ARTIFACT)
    ---@cast gref_isart df.general_ref_is_artifactst
    local artrec_id = ((item) and (item.flags.artifact) and gref_isart.artifact_id) or -1
    local artrec = df.artifact_record.find(artrec_id)
    local artname = (artrec) and (' ' .. dfhack.translation.translateName(artrec.name)) or ''
    local desc = (item) and (dfhack.items.getDescription(item, 0, true) .. artname) or "(no item?)"
    local color = COLOR_RESET

    if (item.wear > 0) then  -- working on this case.
        if uniform and assigned and not unassigned then
            color = COLOR_LIGHTGREEN        -- this happens
        elseif uniform and not assigned and unassigned then
            color = COLOR_LIGHTBLUE
            print("\n        VERIFY THIS CASE!")
        elseif uniform and assigned and unassigned then
            color = COLOR_LIGHTCYAN
            print("\n        HANDLE THIS CASE!")
        elseif uniform and not assigned and not unassigned then
            color = COLOR_LIGHTMAGENTA
            print("\n        HANDLE THIS CASE!")
        elseif (assigned and unassigned) then
            color = COLOR_LIGHTRED
        elseif (unassigned) then
            -- nothing.  this case seems to be legal.
        elseif (assigned) then
            color = COLOR_BROWN
        else
            -- nothing at all set.  this is the normal case.
            color = COLOR_RESET
        end
    -- TODO items named by a soldier are in-uniform but neither assigned nor unassigned.
    --   named items have flags.artifact but not flags.artifact_mood.
    --   and the soldier has unit.used_items[linear or binary search for item id].flags.has_grown_attached
    -- (probably uniform-unstick should NOT remove these items ?.)
    -- (also the item could potentially be an artifact_mood that the soldier has grown attached to?)
    -- TODO *weapons* in a work detail can be the equivalent of "in a uniform" (listed in
    --   plotinfo.equipment.work_weapons) and still have the weapon unassigned.
    -- DONE find the has_grown_attached case that has NOT been named yet.  found one.
    --    the weapon is normal; it is in the uniform and in items_assigned, and not in items_unassigned.
    -- sometimes such items are forbidden in the soldier's inventory.
    -- oddity: bolts of invader origin are not in either assigned or unassigned, even after they
    --    have been claimed and dumped.  this may be due to item or stripcaged.
    -- TODO: I saw a few bolts that were marked assigned but not part of the squad ammo.
    --    unfortunately, I decided to diagnose that later, but when I came back, I just resumed the fight.
    --
    -- DONE: when a squad is disbanded, the item ids are removed from equipment.items_assigned.*
    --   but NOT added to equipment.items_unassigned.*
    --   oh that was testing a named weapon.  a helm was added to items_unassigned.HELM.  all is good.
    elseif (artrec and uniform and not assigned and not unassigned) then
        color = COLOR_WHITE
    elseif (uniform and not assigned) or (not uniform and assigned) or (assigned and unassigned) then
        color = COLOR_LIGHTRED
    end
    if not suppress or color ~= COLOR_RESET then
        dfhack.color(color)
        printf("%-8s%-8s%-8s%-8s%-2s%s", item_id, uniform, assigned, unassigned, item == sitem and '*' or '',
            desc:sub(1,40))
    end
    dfhack.color(COLOR_RESET)
end

-- TODO: note: in my most current main fort save, Risen Z SQ4 has all his inventory shown as
-- not assigned and not unassigned. this is wrong and bad.  CHECK WHAT HAPPENED AND WHEN in older saves.
--   same for Ushat T SQ4.  did I create a script bug?  YES.  the last thing I changed was recursing
--   into invenetory items that are containers, and after that some type checking.
--   including a tiny bit of code rework around general_ref type IS_ARTIFACT.

