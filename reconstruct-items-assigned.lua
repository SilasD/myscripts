-- fully rebuild plotinfo.equipment.items.(un)assigned from uniform assigned equipment.
-- has a few discrepencies with 
-- does NOT remove equipment from unoccupied squad positions; out of scope.

local utils = require('utils')
local dialogs = require('gui.dialogs')
local world = df.global.world
local plotinfo = df.global.plotinfo

-- this does not model the fact that Lua lists can contain disparate types.
---@generic T
---@alias list (`T`[])

-- LuaLS typechecking does not support casting to fields of a class.  this is the best we can do.
---@alias df.item.id integer
---@alias df.unit.id integer
---@alias df.squad.id integer


--[[
TODO update the version of verify_vector_is_sorted in internal/notify/notifications.
no algorithm changes.  mostly conversion to use a `generic` instead
of `any`, since I have figured out how to use generics.
also converted to use `df.isvalid()`.
--]]

---@nodiscard
---@generic T
---@param vector DFContainer|list   # a df vector or array, or a Lua list.
---@param field string?    # nil, or the field name to sort on.
---@param comparator (fun(a:`T`, b:`T`):integer)?
---    # an optional comparator that returns -1,0,1 per `utils.compare_*`.
---    # nil falls back to `utils.compare` or `utils.compare_field`.
---    # if a comparator is given, the field parameter is ignored.
---@return boolean
local function verify_vector_is_sorted(vector, field, comparator)
    assert(type(vector) == "table" or utils.is_container(vector))
    assert(type(field) == "string" or field == nil)
    assert(type(comparator) == "function" or comparator == nil)
---@cast comparator -nil
    comparator = comparator or utils.compare_field(field)
    local lo, hi
    if type(vector) == "userdata" and df.isvalid(vector) == "ref" then
        lo, hi = 0, #vector-1
    else
        lo, hi = 1, #vector
    end
    local sorted = true
    for i = lo, hi-1 do
        if comparator(vector[i], vector[i+1]) ~= -1 then
            sorted = false
            break
        end
    end
    return sorted
end

--- copyall(), but adjusts the copy of a DF vector to Lua 1-based indexing, what a pain.
--- hopefully works on other DF table-ish variable types, or Lua tables for that matter.
--- tested extensively on DF vectors, not so much on DF arrays.  be careful.
---@nodiscard
---@param vector DFContainer|list   -- 'any', really, but we need to typecheck these ones.
---@return list                     -- 'any', again.
local function copyall_vector(vector)
    local t = copyall(vector)
    if utils.is_container(vector)
        ---@cast vector DFContainer
        and #vector > 0
        --  and (tostring(v._type):find('^vector<')         -- these tests are probably
        --      or tostring(v._type):find('%[%d*%]$') )     --   no longer necessary.
    then
        assert(#t == #vector-1)
        assert(t[0] == vector[0])
        assert(t[#vector-1] == vector[#vector-1])
        table.insert(t, 1, t[0])
        t[0] = nil
        assert(#vector == #t)
        assert(t[1] == vector[0])
        assert(t[#vector] == vector[#vector-1])
        ---@cast vector DFContainer|list
    end
    return t
end

---this caches direct references to items, so is only valid for a single tick.
-- yet another time when static locals would be a nice thing to have.
---@type table<df.item.id, df.item|true>  # boolean true means does NOT exist, so maps to nil.
local df_item_find_cache = {}

---@param item_id df.item.id
---@return df.item|nil
local function df_item_find(item_id)
    assert(math.type(item_id) == "integer")
    df_item_find_cache[item_id] = df_item_find_cache[item_id] or df.item.find(item_id) or true
    assert(((df_item_find_cache[item_id] ~= true) and df_item_find_cache[item_id] or nil) == df.item.find(item_id))  -- very slow!
    return (df_item_find_cache[item_id] ~= true) and df_item_find_cache[item_id] or nil
end

local function add_item_to_df_item_find_cache(item)
    if item == nil then return; end
    df_item_find_cache[item.id] = item
    assert(df_item_find(item.id) == item)
end

--[=[
---this caches direct references to units, so is only valid for a single tick.
---@type table<df.unit.id, df.unit|true>  # boolean true means does NOT exist, so maps to nil.
local df_unit_find_cache = {}

---@param unit_id df.unit.id
---@return df.unit|nil
local function df_unit_find(unit_id)
    assert(math.type(unit_id) == "integer")
    df_unit_find_cache[unit_id] = df_unit_find_cache[unit_id] or df.unit.find(unit_id) or true
    assert(((df_unit_find_cache[unit_id] ~= true) and df_unit_find_cache[unit_id] or nil) == df.unit.find(unit_id))  -- very slow!
    return (df_unit_find_cache[unit_id] ~= true) and df_unit_find_cache[unit_id] or nil
end
--]=]

--[=[
-- caches index into the vector, not the vector element.  safe to preserve as the game runs.
-- the unit at the cached index might not be the requested unit.  this may be because of a
--   stale cache, or it may indicate that the requested unit doesn't exist.
---@type table<df.unit.id, integer>  # index into df.unit.get_vector()
local df_unit_find_cache = {}

-- this is a LOT of code.  a C++ binary search might beat it.
---@param unit_id df.unit.id
---@return df.unit|nil
local function df_unit_find(unit_id)
    assert(math.type(unit_id) == "integer")
    local v = df.unit.get_vector()
    local index = df_unit_find_cache[unit_id]
    if index and index >= 0 and index < #v then
        if v[index].id == unit_id then
            --print("cached", "found")
            assert(df.unit.find(unit_id) == v[index])   -- slow check!
            return v[index]
        elseif v[index].id > unit_id and index >= 1 and v[index-1].id < unit_id then
            --print("cached", "not found")
            assert(df.unit.find(unit_id) == nil)        -- slow check!
            return nil
        else
            --print("cached, stale, falling through")
            df_unit_find_cache[unit_id] = nil
        end
    end
    -- note: it would be possible to set min, max by analyzing index and v[index].id
    local result, found, index = utils.binsearch(v, unit_id, 'id')
    --print("binsear", found and "found" or "not found")
    assert(index >= 0 and index <= #v)
    assert(index == 0 or v[index-1].id < unit_id)
    assert(index == #v or v[index].id >= unit_id)
    assert(result == nil or result.id == unit_id)
    assert(df.unit.find(unit_id) == result)  -- slow!
    df_unit_find_cache[unit_id] = index
    return result
end
--]=]


--[=[
implementation of Quietust's suggestion about using general references to do the cacheing.
  https://discordapp.com/channels/793331351645323264/793331351645323267/1304472883510116373
  Quietust — 11/8/2024 7:49 AM
  If you want to keep a reference to a unit and be able to re-fetch it safely, create a
    `general_ref_unitst`, set the ID inside, then call the `getUnit` vmethod - it'll cache
    the global vector index so the binary search only happens the first time (and if the index
    turns out to be bad, it'll automatically perform the binsearch and cache the new index).

note: it would be nice if there was a way to allocate a *vector* of `general_ref_unit`s.
--]=]

---[=[
-- `general_ref_unit`s used for caching.  safe to preserve between ticks.
-- must catch garbage collection and `:delete()` all elements.
-- the downside of this method is that it only caches *existing* units.
-- unit id's without a unit in world.units.all will redo the binary search each time.
--
---@type table<df.unit.id, df.general_ref_unit>
local df_unit_find_cache = setmetatable( {}, {
    __gc =
        ---@param t table<df.unit.id, df.general_ref_unit>
        function(t)
            local verbose_check = true
            if verbose_check then
                print("df_unit_find_cache __gc: beginning GC")
                local count = 0; for k,v in pairs(t) do count = count + 1; end
                print("df_unit_find_cache __gc: before count", count)
            end
            for k,v in pairs(t) do
                if df.isvalid(v) and v._type == df.general_ref_unit then
                    if verbose_check then print("df_unit_find_cache __gc: delete()ing", k, v._type, v.unit_id, v.cached_index); end
                    ---@diagnostic disable-next-line: cast-local-type
                    v:delete(); v = nil
                    rawset(t, k, nil)
                    if verbose_check then assert(rawget(t, k) == nil); end
                else
                    if verbose_check then print("df_unit_find_cache __gc: not dealing with element", k, v, df.isvalid(v) and v._type or type(v)); end
                end
            end
            if verbose_check then
                local count = 0; for k,v in pairs(t) do count = count + 1; end
                print("df_unit_find_cache __gc: after count", count)
                print("df_unit_find_cache __gc: ending GC")
            end
        end,
--[[
    __index = function(t, k)
            TODO would this be helpful?
            return v
        end,
    __newindex = function(t, k, v)
            TODO would this be helpful?  could move the :new() and :setID() in here.
            and maybe the :delete() for that matter, if v == nil.
        end,
--]]
} )

---@param unit_id df.unit.id
---@return df.unit?
local function df_unit_find(unit_id)
    assert(math.type(unit_id) == "integer")
    local cached = df_unit_find_cache[unit_id]
    if cached then
        assert(df.isvalid(cached) and cached._type == df.general_ref_unit)
        --print("df_unit_find cached (pre)", unit_id, cached.unit_id, cached.cached_index, cached:getID())
        local unit = cached:getUnit()
        --print("df_unit_find cached (post)", unit_id, cached.unit_id, cached.cached_index, cached:getID())
        assert(unit == nil or df.unit:is_instance(unit))
        assert(unit == nil or unit_id == unit.id)
        assert(unit == df.unit.find(unit_id))  -- slow
        return unit
    end
    local new = df.general_ref_unit:new()
    assert(df.isvalid(new) and new._type == df.general_ref_unit)
    new:setID(unit_id)
    assert(new:getID() == unit_id)
    --print("df_unit_find new  ", unit_id, new.unit_id, new.cached_index, new:getID())
    df_unit_find_cache[unit_id] = new
    assert(df_unit_find_cache[unit_id] == new and df.isvalid(df_unit_find_cache[unit_id]) and df_unit_find_cache[unit_id]._type == df.general_ref_unit)
    --print("df_unit_find tail recursing")
    return df_unit_find(unit_id)  -- tail recursing is the easiest way to fully validate asserts and such.
end
--]=]

--[===[
-- test code.
local c = 0
for _, u in ipairs(df.global.world.units.active) do
    df_unit_find(u.id)
    df_unit_find(u.id-1)
    df_unit_find(u.id+1)
    c = c + 1
    if c > 50 then break; end
end
local c = 0
for _, u in ipairs(df.global.world.units.active) do
    if c > 25 then
        df_unit_find(u.id)
        df_unit_find(u.id-1)
        df_unit_find(u.id+1)
    end
    c = c + 1
    if c > 75 then break; end
end
do return; end
--]===]


---@type table<df.squad.id, df.squad|boolean>  # always truthy.  boolean true maps to nil.
local df_squad_find_cache = {}
---@param squad_id df.squad.id
---@return df.squad?
local function df_squad_find(squad_id)
    df_squad_find_cache[squad_id] = df_squad_find_cache[squad_id] or df.squad.find(squad_id) or true
    assert(((df_squad_find_cache[squad_id] ~= true) and df_squad_find_cache[squad_id] or nil) == df.squad.find(squad_id))  -- slow
    return (df_squad_find_cache[squad_id] ~= true) and df_squad_find_cache[squad_id] or nil
end

local function clear_caches()
    df_item_find_cache = {}
    df_unit_find_cache = {}
    df_squad_find_cache = {}
end

--[[
TODO what to do about uniform items that are owned?  (can only happen for non-ARMORLEVEL clothing.)
    check if the item is worn by the squaddie.  if so, and he doesn't own it, remove ownership.
        maybe set ownership the the squaddie?
    else, remove it from the uniform.

TODO uniform items assigned to a squad position that is unoccupied remain allocated in the
uniform structure and marked as assigned.
    seen with a dead dwarf.
(however, damaged uniform items may be taken out of `.items_assigned`?  later: YES.)

[DFHack]# are-these-items-assigned
item id uniform assign  unassig
29710   true    true    false     {≡steel spear≡}
39834   true    true    false     lychee wine waterskin (emu leather)
57717   true    true    false     {≡steel right gauntlet≡}
78197   true    true    false     {≡steel high boot≡}
78379   true    true    false     {≡steel high boot≡}
78393   true    true    false     {≡steel breastplate≡}
78597   true    true    false     {≡steel greaves≡}
78635   true    true    false     {≡steel mail shirt≡}
78775   true    true    false     {≡steel shield≡}
78840   true    false   false     x{≡steel helm≡}x                NOTE the damage.
78924   true    true    false     {≡steel left gauntlet≡}
86576   false   false   true      {≡hemp right glove≡}            NOTE that owned items are still unassigned.
86577   false   false   true      {☼hemp left glove☼}
86856   false   false   true      {≡llama wool sock≡}
86915   false   false   true      {≡sheep wool sock≡}
87619   false   false   true      {☼hemp trousers☼}
90895   false   false   true      {☼hemp tunic☼}
91737   false   false   false     x{☼hemp hood☼}x                 NOTE the damage.
94432   false   false   true      {☼rope reed cloak☼}
128838  false   false   false     Dodók Adilotung's mangled corpse


generational inheritance is a thing; all of the non-uniform items Dodok dropped on death
are now owned by Dodok's daughter, Unib Rithemath.
And probably Dodok's stored items.  Yes.  But not the bedroom zone or buildings.

--]]

---@return table<df.item.id, df.item|boolean>  # boolean false means item does not exist.
--   TODO maybe: for nonexistent items, instead of false, a string describing the uniform position?
--   TODO: track double-assignment here?  ~~no, not in scope.~~  YES, this is the best place and time.
local function gather_uniform_items()
    local id_map = {}
    local function add(id)
        assert(math.type(id) == "integer")
        if id == -1 then return; end
        if id_map[id] then print("double-assigned item %d", id); end  -- TODO zap
        id_map[id] = df_item_find(id) or false
        if not id_map[id] then print("nonexistent assigned item %d", id); end  -- TODO zap
    end

    for _,id in ipairs(plotinfo.equipment.ammo_items)   do add(id); end
    for _,id in ipairs(plotinfo.equipment.work_weapons) do add(id); end
    for _,ammo_spec in ipairs(plotinfo.equipment.hunter_ammunition) do
        -- not sure if this can legally be a double-allocation with .ammo_items above.
        -- TODO test some hunters already!
        for _,id in ipairs(ammo_spec.assigned) do add(id); end
    end

    for _,squad_id in ipairs(plotinfo.main.fortress_entity.squads) do
        local squad = df_squad_find(squad_id)
        for _,id in ipairs(squad.ammo.ammo_items) do add(id); end

        for _,pos in ipairs(squad.positions) do
            local eq = pos.equipment
for _,id in ipairs({eq.quiver, eq.backpack, eq.flask}) do assert(id == eq.quiver  -- TODO zap
or id == eq.backpack or id == eq.flask); end                                      -- TODO zap
            for _,id in ipairs({eq.quiver, eq.backpack, eq.flask}) do add(id); end

            for _,bodypart in pairs(eq.uniform) do
                for _,uniform_spec in ipairs(bodypart) do
                    for _,id in ipairs(uniform_spec.assigned) do
                        add(id)
    end;end;end;end;end   -- five levels of nested for loops! crazy.

    return id_map
end


---TODO full description
-- this is much faster than I expected, even with the assert slowdowns.
-- TODO try it on forts with thousands of items, forts with lots of soldiers.
-- TODO this is getting a bit long, but I don't see refactoring opportunities.
--   the stat-tracking takes up linespace but is pretty much needed.
--   (also a lot of the linespace is asserts, which can die when this is done.)
--
---@return { [string]: integer }  dictionary of possibly-interesting stats
local function fully_rebuild_items_un_assigned()
    local items_assigned     = plotinfo.equipment.items_assigned
    local items_unassigned   = plotinfo.equipment.items_unassigned
    local items_unmanifested = plotinfo.equipment.items_unmanifested

    -- map ids to items. boolean false means nonexistent item.
    local uniform_items = gather_uniform_items()
    -- map ids to boolean true, meaning "this item doesn't belong in either list."
    local ignore = {}

    local stats = {}
    local function stat(s, i)
        stats[s] = (stats[s] or 0) + (i or 1)
    end

    local itypes = ("WEAPON,ARMOR,HELM,GLOVES,PANTS,SHOES,SHIELD,QUIVER,BACKPACK,FLASK,AMMO"):split(',')
    for _,itype in ipairs(itypes) do
        assert(verify_vector_is_sorted(world.items.other[itype], 'id'), "unsorted world.items.other." .. itype)
        assert(verify_vector_is_sorted(items_assigned    [itype]), "unsorted items_assigned."     .. itype)
        assert(verify_vector_is_sorted(items_unassigned  [itype]), "unsorted items_unassigned."   .. itype)
        assert(verify_vector_is_sorted(items_unmanifested[itype]), "unsorted items_unmanifested." .. itype)

        stat("oldsize items_assigned."   .. itype, #items_assigned    [itype])
        stat("oldsize items_unassigned." .. itype, #items_unassigned  [itype])
        stat("size items_unmanifested."  .. itype, #items_unmanifested[itype])

        local old_a = copyall_vector(items_assigned[itype]);
        local old_u = copyall_vector(items_unassigned[itype]);

        assert(#old_a == #items_assigned[itype])
        assert(#old_u == #items_unassigned[itype])
        --! for i,id in ipairs(old_a) do assert(items_assigned  [itype][i-1] == id); end
        -- this is crashing out, disabling: assert((function(t,v)for i,id in ipairs(t)do if v[i-1]~=id then print(i,id);return false;end;return true;end;end)(old_a,items_assigned  [itype]))
        --! for i,id in ipairs(old_u) do assert(items_unassigned[itype][i-1] == id); end
        -- this is crashing out, disabling: assert((function(t,v)for i,id in ipairs(t)do if v[i-1]~=id then print(i,id);return false;end;return true;end;end)(old_u,items_unassigned[itype]))

        -- ignore item ids in `plotinfo.equipment.unmanifested[]`. items in it are in the
        --   process of being created (e.g. by crafting), so any such items should never
        --   be assigned or unassigned.  or in a uniform item, for that matter.
        -- (this is a very rare case, and I need to catch it in a savegame.)
        for _, id in ipairs(items_unmanifested[itype]) do
            stat("total items_unmanifested")
            stat("total items_unmanifested." .. itype)
            ignore[id] = true
            if not df_item_find(id) then
                stat("missing items_unmanifested")
                stat("missing items_unmanifested." .. itype)
            end
        end

        -- invarient: we are walking up a sorted vector, and appending the sort key into
        --   one of two lists.  therefore, the two resulting lists are automatically sorted.
        local new_a, new_u = {}, {}
        for _,item in ipairs(world.items.other[itype]) do
            stat("total all items")
            stat("total all items." .. itype)
            add_item_to_df_item_find_cache(item)
            local id = item.id

            -- TODO should armor-type items be ignored if they don't have an ARMORLEVEL ?

            -- TODO move this test into its own function.  TODO what tests does uniform-unstick use?
            if     item.flags.removed
                or item.flags.in_building
                or item.flags.dead_dwarf
                or item.flags.garbage_collect
                or item.flags.already_uncategorized  -- can't happen
                -- TODO what about hostile, trader, owned, others ?  MUST RESEARCH EVERY FLAG.
            then
                ignore[id] = true
                stat("total ignored by flags")
            end

            if ignore[id] then
                stat("total ignored")
                stat("total ignored." .. itype)
            elseif uniform_items[item.id] then
                stat("total assigned")
                stat("total assigned." .. itype)
                table.insert(new_a, id)
            else
                stat("total unassigned")
                stat("total unassigned." .. itype)
                table.insert(new_u, id)
            end
        end

        assert(verify_vector_is_sorted(new_a), "unsorted new_a." .. itype)
        assert(verify_vector_is_sorted(new_u), "unsorted new_u." .. itype)

        items_assigned  [itype]:resize(0)
        items_assigned  [itype]:assign(new_a)
        items_unassigned[itype]:resize(0)
        items_unassigned[itype]:assign(new_u)

        assert(#new_a == #items_assigned  [itype], "assign failed new_a." .. itype)
        assert(#new_u == #items_unassigned[itype], "assign failed new_u." .. itype)
        assert((#new_a == 0) or (new_a[1] == items_assigned  [itype][0]))
        assert((#new_u == 0) or (new_u[1] == items_unassigned[itype][0]))
        assert((#new_a == 0) or (new_a[#new_a] == items_assigned  [itype][#new_a-1]))
        assert((#new_u == 0) or (new_u[#new_u] == items_unassigned[itype][#new_u-1]))

        assert(verify_vector_is_sorted(items_assigned    [itype]), "unsorted items_assigned."   .. itype)
        assert(verify_vector_is_sorted(items_unassigned  [itype]), "unsorted items_unassigned." .. itype)

        stat("newsize items_assigned."     .. itype, #items_assigned    [itype])
        stat("newsize items_unassigned."   .. itype, #items_unassigned  [itype])
--[=[
        -- this stat-tracking could be done in a sub-function:
        -- now that we are done with old_* and new_*, we can tear them apart for stats.
        -- all four of these lists are sorted, so we should be able to do this in one pass.

        -- prepend a sentinal value of -1 to each list.
        -- while there are elements left in any list,
        -- * get the math.max() of the last id of all four lists
        --   * if that value is -1, we're done.
        -- * remove that element from the 1,2,or 3 lists that contain it,
        --    (invarient: new_u and new_a can't contain the same id)
        -- * deal with all the match cases
        -- * 
        -- * 
        -- * 
        -- * 
        -- * 
        for _,t in ipairs(old_a, old_u, new_a, new_u) do table.insert(t, 1, -1); end  -- prepend sentinals.
        repeat
            local oa, ou = table.remove(old_a), table.remove(old_u)     -- grab the last values.
            local na, nu = table.remove(new_a), table.remove(new_u)
            local max = math.max(oa, ou, na, nu)
            if max == -1 then break; end
            if oa ~= max then table.insert(old_a, oa); oa = false; end
            if ou ~= max then table.insert(old_u, ou); ou = false; end
            if na ~= max then table.insert(new_a, na); na = false; end
            if nu ~= max then table.insert(new_u, nu); nu = false; end
            getting too sleepy here.  I want to conditionally remove the last element if it == max.
            probably want a subfunction?
            
        until max == -1
--]=]

    end
    -- TODO is there any final cleanup to do?

    return stats
end


local function on_accept()
    local stats = fully_rebuild_items_un_assigned()
    local sorted_keys = (function(ts) local t = {}; for s,_ in pairs(ts) do table.insert(t, s); end; table.sort(t); return t; end)(stats)
    print("stats:"); for _, k in ipairs(sorted_keys) do print(string.format("%-40s%d", k, stats[k])); end; print()
    print("either it worked or it didn't.")
    print("assign new uniforms to squads,")
    print("and press the 'Update' button.")
end

--do on_accept(); return; end
dialogs.showYesNoPrompt("Rebuild assigned items lists",
([[
Experimental!

This script fully rebuilds the lists
that control whether items are
available to be used in uniforms:

* plotinfo.equipment.items_assigned
* plotinfo.equipment.items_unassigned
]]):trim() .. "\n" ..
--[[
Items which are part of a uniform
will be added to the items_assigned
list.  All other items which could
be used in uniforms will be added to
the items_unassigned list.
--]]
([[
Only run this script if:

* You have a savegame that you can
  revert to.
* There are NO SQUADS on missions.

If you are sure, press 'Enter'.
]]):trim(), nil, on_accept)

