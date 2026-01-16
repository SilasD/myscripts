-- SWD Combine seeds in seed bags in the selected stockpile.
-- Seeds are like drinks: they are normally in a container.  but they don't have to be.
-- Seeds are like plants: there can be multiple types in a container.  we don't want that.
-- Seeds are not like drinks or plants: they can be, and usually are, in nested containers.
--   Q: drink in a bucket or goblet or waterskin in a barrel; can this happen?
-- Seeds are not like drinks or plants: they don't stack.  (Caveat: nuts stack.)
--[====[

combine-seeds
--=--=--=--===
Merge bags of seeds in the selected stockpile.

]====]


local utils = require 'utils'
local function IRD(i) return string.format("%-8d%s",i.id,dfhack.items.getReadableDescription(i));end  -- debugging
local function EC(t)local i=0;for k,_ in pairs(t)do i=i+1;end;return i;end  -- element count; debugging


---@alias any_DF_type  table  # I don't think we can do better than this, but I would sure like to.
---@alias any_DF_item_type  df.item
---@alias plant_matindex  integer  # aka matgloss


-- ipairsF() is ipairs with a filter, so you don't have to nest an if/then/end inside your for/do/end.
-- the intent is to reduce indentation overall, and to focus attention on the loop logic.
--
-- implementation difference: this returns iterator, array, nil unlike ipairs() which returns iterator, array, 0.
-- (this is because 0 is a valid index for DF vectors.)
--
-- TODO Q: what happens with nested ipairsF calls?  are the upvalues handled properly?  test.
--   Hmm, nested ipairsF implies nested data structures.
--
---@alias array table  # a table that is (or has) a list, or a DF vector.
--
---@param array array  # a table that is (or has) a list, or a DF vector.  ipairs semantics.
---@param match fun(any):boolean|any_DF_type
---@return fun(array, integer?) integer, T  # basically a filtered ipairs-like next-element iterator, expected to be used by generic for
---@return table  # the array or vector being iterated over.
---@return nil  # signals the start of the iteration, per ipairs semantics.
local function ipairsF(array, match)
    assert(type(array) == "table" or (df.isvalid(array) == "ref" and array._kind == "container"))
    assert(type(match) == "function" or df.isvalid(match) == "type")
    local debugging_verify_arraysize = #array

    ---@param Array array|any_DF_type
    ---@param index integer?
    ---@return integer?
    ---@return any
    -- note: uses upvalue match to maintain ipairs-like semantics.
    -- note: uses upvalues array and debugging_verify_arraysize in assertions.
    local function iterator(Array, index)
        assert(type(Array) == "table" or (df.isvalid(Array) == "ref" and Array._kind == "container"))
        assert(index == nil or math.type(index) == "integer")
        assert(Array == array)
        assert(#Array == debugging_verify_arraysize)
        assert(type(match) == "function")

        local min = df.isvalid(Array) and 0 or 1
        local max = df.isvalid(Array) and #Array-1 or #Array
        while true do
            index = (index) and index + 1 or min
            index = (index <= max) and index or nil
            local value = (index) and Array[index] or nil

            if index == nil then return nil, nil; end
            if match(value) then return index, value; end
        end
    end

    -- if given a DF type, create a closure to test for matching that type.
    if df.isvalid(match) == "type" then
        local _match = match  -- this local variable is required to retain knowledge of the DF type.
        match = function(Type) return _match:is_instance(Type); end
    end
    assert(type(match) == "function")

    return iterator, array, nil
end


local _cache_DF_v50
---@return boolean
local function DF_v50()
    _cache_DF_v50 = (_cache_DF_v50 ~= nil) and _cache_DF_v50
        or (tonumber(dfhack.getCompiledDFVersion():match("^0*%.*(%d+%.%d+)")) >= 50.00)
    return _cache_DF_v50
end


-- TODO deal with .flags.forbid and other cases.
-- DONT implement this such that tree seeds are not seeds.
--    WHY: actually, many tree seeds are not edible raw.  mostly fruit trees.
-- TODO actually this test should be restricted to plantable seeds, even if they are edible raw.
--    TODO maybe: cache the plantable+edible tests, as they will be a bit expensive.
-- TODO non-plantable + edible seeds should be combined by normal combine.lua rules.
--    Q:what happens to bags that hold non-plantable seeds?  would the seeds be moved to the ground?
--      would the bags be considered unusable?
-- TODO we may need both isSeed and isPlantableSeed ?
---@param seed df.item_seedsst|df.item
---@return boolean
local function isSeed(seed)
    return df.item_seedsst:is_instance(seed)
end


-- TODO deal with .flags.forbid and other cases.
---@param bag df.item_boxst|df.item_bagst|df.item
---@return boolean
local function isBag(bag)
    if DF_v50() then  -- note: in 0.50+, BAG was split out of BOX.
        return df.item_bagst:is_instance(bag)
    else
        return df.item_boxst:is_instance(bag) and bag:isBag()
    end
end


-- TODO deal with any special cses not handled by isBag()
---@param bag df.item_boxst|df.item_bagst|df.item
---@return boolean
local function isEmptyBag(bag)
    if not isBag(bag) then return false; end
    if bag.flags.in_job then return false; end  -- empty bags in jobs are not considered empty.
    return #dfhack.items.getContainedItems(bag) == 0
end


-- TODO maybe: fail on bag-contains-powder?  but powder and seed probably never happens.
---@param bag df.item_boxst|df.item_bagst|df.item
---@return boolean
local function isSeedBag(bag)
    if not isBag(bag) then return false; end
    for _, item in ipairsF(dfhack.items.getContainedItems(bag), isSeed) do
	return true  -- even one hit means this is a seedbag.
    end
    return false
end


-- TODO deal with .flags.forbid and other cases.
---@param barrel df.item_barrelst|df.item_toolst|df.item
---@return boolean
local function isBarrel(barrel)
    if not barrel or not df.item:is_instance(barrel) then return false; end
    if df.item_barrelst:is_instance(barrel) then return true; end
    if df.item_toolst:is_instance(barrel) then
	return utils.linear_index(item.subtype.tool_use, df.tool_uses.FOOD_STORAGE) ~= nil
    end
    return false
end


-- only returns items nested up to two containers deep.
-- does NOT return empty barrels/large pots, empty bins, or assigned wheelbarrows,
--   per getStockpileContents() API definition.
--
---@param stockpile df.building_stockpilest
---@return df.item[]
local function getAllItemsInStockpile(stockpile)
    assert(df.building_stockpilest:is_instance(stockpile))
    local flags = stockpile.flags
    if not flags.exists or flags.almost_deleted or flags.in_update then return {}; end

    local items = {}
    for _, item in ipairs(dfhack.buildings.getStockpileContents(stockpile)) do
	table.insert(items, item)
	for _, item in ipairs(dfhack.items.getContainedItems(item)) do
	    table.insert(items, item)
	    for _, item in ipairs(dfhack.items.getContainedItems(item)) do
		table.insert(items, item)
	    end
	end
    end
    return items
end


-- only returns items nested up to two containers deep.
-- does NOT return empty barrels/large pots, empty bins, or assigned wheelbarrows,
--   per getStockpileContents() API definition.
--
---@param stockpile df.building_stockpilest
---@param filter fun(item:any_DF_item_type):boolean|any_DF_item_type
---@return df.item[]
local function getFilteredItemsInStockpile(stockpile, filter)
    assert(df.building_stockpilest:is_instance(stockpile))
    assert(type(filter) == "function" or df.isvalid(filter) == "type")

    local flags = stockpile.flags
    if not flags.exists or flags.almost_deleted or flags.in_update then return {}; end

    local items = {}
    for _, item in ipairsF(getAllItemsInStockpile(stockpile), filter) do
	table.insert(items, item)
    end
    return items
end


-- returns true iff this stockpile accepts at least one seed type.
---@param stockpile df.building_stockpilest
---@return boolean
local function stockpileAcceptsSeeds(stockpile)
    assert(df.building_stockpilest:is_instance(stockpile))
    local flags = stockpile.flags
    if not flags.exists or flags.almost_deleted or flags.in_update then return false; end

    if not stockpile.settings.flags.food then return false; end		-- must have food category
    for i, set in ipairs(stockpile.settings.food.seeds) do
	if set == 1 then return true; end				-- must have at least one seed type
    end
end


-- TODO untested.
-- returns false if this stockpile accepts any non-food category or non-seed food type.
--   otherwise, returns true iff this stockpile accepts at least one type of seed.
-- TODO it is possible to have a stockpile with ex: .flags.sheet set and the .sheet substructure
--   populated but have every element of the sheet[] and parchment[] types vectors set to 0.
--   This can be done just by enabling sheets then disabling it again.  So need to deal with that.
---@param stockpile df.building_stockpilest
---@return boolean
local function stockpileIsOnlySeeds(stockpile)
    assert(df.building_stockpilest:is_instance(stockpile))
    local flags = stockpile.flags
    if not flags.exists or flags.almost_deleted or flags.in_update then return false; end

    for i, cat in ipairs(df.stockpile_group_set) do		-- must not have any non-food categories
	if cat ~= nil and cat ~= "food" and stockpile.settings.flags[cat] then return false; end  -- TODO here
    end

    if not stockpile.settings.flags.food then return false; end  -- must have food category enabled.
    for k, foodcat in pairs(stockpile.settings.food) do
	if k ~= "seeds" and type(foodcat) == "userdata" and foodcat._type == "vector<char>" then
	    for i, set in ipairs(foodcat) do
		if set == 1 then return false; end		-- must not have any non-seed types
	    end
	end
    end
    for i, set in ipairs(stockpile.settings.food.seeds) do
	if set == 1 then return true; end			-- must have at least one seed type
    end
    return false
end


-- TODO untested.
---@param stockpile df.building_stockpilest
---@param seedtype plant_matindex
local function stockpileAcceptsThisSeedType(stockpile, seedtype)
    assert(df.building_stockpilest:is_instance(stockpile))
    assert(math.type(seedtype) == "integer")
    local flags = stockpile.flags
    if not flags.exists or flags.almost_deleted or flags.in_update then return false; end

    if not stockpile.settings.flags.food then return false; end  -- must have food category enabled.
    if stockpile.settings.food.seeds[seedtype] then return true; end  -- TODO maybe: make this less fragile?
    return false
end


---@param stockpile df.building_stockpilest
---@param emptybags (df.item|df.item_boxst|df.item_bagst)[]  # in/out
local function addAllEmptyBagsInStockpile(stockpile, emptybags)
    assert(df.building_stockpilest:is_instance(stockpile))
    assert(type(emptybags) == "table")

    -- TODO maybe: convert to table.move() to append the whole thing at once.
    for _, bag in ipairs(getFilteredItemsInStockpile(stockpile, isEmptyBag)) do
	table.insert(emptybags, bag)
    end    
end


---@param stockpile df.building_stockpilest
---@param map_matindex_to_bag table<plant_matindex, df.item_boxst|df.item_bagst|boolean|nil>  # in/out  dictionary
local function findAssignedBags(stockpile, map_matindex_to_bag)
    assert(df.building_stockpilest:is_instance(stockpile))
    assert(type(map_matindex_to_bag) == "table")
    local flags = stockpile.flags
    if not flags.exists or flags.almost_deleted or flags.in_update then return false; end

    ---@type (df.item_boxst|df.item_bagst|df.item)[]
    local bags = getFilteredItemsInStockpile(stockpile, isSeedBag)
--print(20,#bags)

    for _, bag in ipairs(bags) do
--print(21,IRD(bag))

	-- special-case handling for jobs. skip bags in jobs, except allow a couple of types of jobs.
	local job_ref = dfhack.items.getSpecificRef(bag, df.specific_ref_type.JOB)
	local j = (job_ref) and job_ref.data.job.job_type or nil

	if j and j ~= df.job_type.PlantSeeds and j ~= df.job_type.StoreItemInBag then goto nextbag; end

	-- TODO verify that PlantSeeds jobs _tag_ the bag at all.
	-- TODO consider refactoring the duplicated code into an embedded function.

	-- special: for every seed in the bag, if the bag is in a PlantSeeds job,
	--   and the seed is also in any job (we assume it's also PlantSeeds),
	--   override that seed type to that bag, even if there was already a bag assigned.
	for _, seed in ipairsF( dfhack.items.getContainedItems(bag),
	    function(seed)
		return j == df.job_type.PlantSeeds and isSeed(seed) and seed.flags.in_job
	    end
	) do
--print(24,seed:getMaterialIndex(),IRD(seed),IRD(bag))
	    map_matindex_to_bag[seed:getMaterialIndex()] = bag
	    break
	end

	-- TODO maybe: look at StoreItemInBag jobs, check if the item is a seed, if not, skip the bag.
	-- (currently, we'll just let the problem be cleared up next time the script runs.)
	--   these jobs have items[0].role=Hauled -> the bag and items[1].role=QueuedContainer -> the seed
	--   (TODO verify that, it seems backwards.)

	-- for every seed in the bag, if there is not already a bag assigned to that seed type,
	--   assign this bag to this seed type.
	for _, seed in ipairsF( dfhack.items.getContainedItems(bag),
	    function(seed)
		return isSeed(seed) and not(map_matindex_to_bag[seed:getMaterialIndex()])
	    end
	) do
--print(27,seed:getMaterialIndex(),IRD(seed),IRD(bag))
	    map_matindex_to_bag[seed:getMaterialIndex()] = bag
	    break
	end
	::nextbag::
    end
end


---@param stockpile df.building_stockpilest
---@param map_matindex_to_bag table<plant_matindex, df.item_boxst|df.item_bagst|boolean|nil>  # in/out  dictionary
local function assignSeedsToEmptyBags(stockpile, map_matindex_to_bag)
    assert(df.building_stockpilest:is_instance(stockpile))
    assert(type(map_matindex_to_bag) == "table")
    local flags = stockpile.flags
    if not flags.exists or flags.almost_deleted or flags.in_update then return false; end

    ---@type (df.item_seedsst|df.item)[]
    local all_seeds = getFilteredItemsInStockpile(stockpile, isSeed)
--print(31,#all_seeds)
    ---@type (df.item_boxst|df.item_bagst|df.item)[]
    local empty_bags = getFilteredItemsInStockpile(stockpile, isEmptyBag)
--print(32,#empty_bags)

    -- make sure all seeds have a bag (if at all possible).
    for _, seed in ipairs(all_seeds) do
	if not map_matindex_to_bag[seed:getMaterialIndex()] then
--print(37,EC(map_matindex_to_bag),#empty_bags)
	    local bag = (#empty_bags > 0) and table.remove(empty_bags) or false
	    map_matindex_to_bag[seed:getMaterialIndex()] = bag
--print(38,EC(map_matindex_to_bag),#empty_bags,(bag)and IRD(bag) or bag)
	end
    end
end


---@param stockpile df.building_stockpilest
---@param map_matindex_to_bag table<plant_matindex, df.item_boxst|df.item_bagst|boolean|nil>  # in/out  dictionary
local function moveSeedsToAssignedBags(stockpile, map_matindex_to_bag)
    assert(df.building_stockpilest:is_instance(stockpile))
    assert(type(map_matindex_to_bag) == "table")
    local flags = stockpile.flags
    if not flags.exists or flags.almost_deleted or flags.in_update then return false; end

    local all_seeds = getFilteredItemsInStockpile(stockpile, isSeed)
--print(50,#all_seeds)

    -- move all seeds in the stockpile to the assigned bag.
    -- if there is no bag (map_matindex_to_bag holds false), move the seed to the ground.
    for _, seed in ipairs(all_seeds) do
	local bag = map_matindex_to_bag[seed:getMaterialIndex()]
--print(52,IRD(seed),bag and IRD(bag) or bag)

	-- at this point, bag should be a bag item or false, not nil.
	-- TODO for some reason, it can be nil.  track that down; is it harmless?
	assert(bag == nil or bag == false or isBag(bag))

	-- note: if the seed is in a job, the seed will not be moved by .moveTo* .
	if bag then
	    -- move it into that bag.
--print(53,dfhack.items.getContainer(seed)and IRD(dfhack.items.getContainer(seed))or "no container", IRD(bag), dfhack.items.getContainer(seed)==bag)
	    if dfhack.items.getContainer(seed) ~= bag then
--print(54,"move seed to container", IRD(seed), IRD(bag))
		dfhack.items.moveToContainer(seed, bag)
--else print(55)
	    end
	else
	    -- bag can also be false, meening no bag could be assigned.
	    -- (note: moveToGround tests if it's already on the ground, and skips the move.)
	    if not seed.flags.on_ground then
--print(56,"move seed to ground", IRD(seed), bag)
		dfhack.items.moveToGround(seed, xyz2pos(dfhack.items.getPosition(seed)))
--else print(57)
	    end
	end
    end
end


-- this is written to allow multiple stockpiles (future direction, not tested)
-- note that this will move seeds between stockpiles.
-- TODO all of this doesn't handle tree seeds properly; that is NUTS !!
---@param stockpiles df.building_stockpilest[]
local function combineSeeds(stockpiles)
    ---@type { [plant_matindex]: df.item_boxst|df.item_bagst|boolean|nil }
    local map_matindex_to_bag = {}  -- this does double duty as our list of seed bags.
    -- TODO maybe: consider this into a list sorted by matindex.
    -- TODO maybe: consider splitting this into a map->bag and a table/list of types without a bag.

    for _, stockpile in ipairs(stockpiles) do
	findAssignedBags(stockpile, map_matindex_to_bag)
--print(80,stockpile,EC(map_matindex_to_bag))
    end

--    local empty_bags = {}  TODO currently this is handled in assignSeedsToEmptyBags
--    for _, stockpile in ipairs(stockpiles)
--	addAllEmptyBagsInStockpile(stockpile, empty_bags)
--    end

    for _, stockpile in ipairs(stockpiles) do
	-- Q: gather and pass in/out empty bags?
	-- A: probably yes, especially if we are moving seed bags to their proper stockpile.
	assignSeedsToEmptyBags(stockpile, map_matindex_to_bag)
--print(82,stockpile,EC(map_matindex_to_bag));for k,bag in pairs(map_matindex_to_bag)do print(82,'',k,(bag)and #dfhack.items.getContainedItems(bag) or -1,IRD(bag));end
    end

--    for _, stockpile in ipairs(stockpiles) do
--	### 
--    end

    for _, stockpile in ipairs(stockpiles) do
	moveSeedsToAssignedBags(stockpile, map_matindex_to_bag)
--print(84,stockpile,EC(map_matindex_to_bag))
    end

    -- for each seed bag, move non-seed items (expected to be no such items) to the ground.
    --   (this will destroy powders: flour, sand, etc.)
    for _, bag in pairs(map_matindex_to_bag) do
	if isBag(bag) then  -- bag can be false or a an actual item_boxst/item_bagst.
	    for _, item in ipairsF(dfhack.items.getContainedItems(bag),
		function(item) return not isSeed(item) end
	    ) do
--print(87,"move non-seed to ground",IRD(item))
		dfhack.items.moveToGround(item, xyz2pos(df.items.getPosition(bag)))
	    end
	end
    end

    -- TODO maybe: if a seed type isn't accepted by the stockpile, move that seed bag to the ground.

    -- don't bother moving empty bags to the ground; the game does that soon enough.

-- but do consider doing this if extending this to multiple stockpiles.
--  for _, stockpile in ipairs(stockpiles) do
--	moveBagsToProperStockpiles(stockpile, map_matindex_to_bag)
--  end
end


local validArgs = utils.invert({ 'stockpile' })
local args = utils.processArgs({...}, validArgs)

-- TODO find by stockpile.stockpile_number .
-- TODO find stockpile by name.
local stockpile = (args.stockpile) and df.building.find(tonumber(args.stockpile))
    or dfhack.gui.getSelectedStockpile(true)
assert(stockpile == nil or df.building_stockpilest:is_instance(stockpile))

-- try finding the stockpile by viewed item or first item in itemlist viewsheet.
if stockpile == nil then
    local item
    if dfhack.gui.getSelectedItem(--[[silent]]true) ~= nil then
        item = dfhack.gui.getSelectedItem(--[[silent]]true)
    elseif DF_v50()
        and dfhack.gui.matchFocusString("dwarfmode/ViewSheets/ITEM_LIST", dfhack.gui.getDFViewscreen())
        and df.global.game.main_interface.view_sheets.open == true
        and df.global.game.main_interface.view_sheets.active_sheet == df.view_sheet_type.ITEM_LIST
        and #df.global.game.main_interface.view_sheets.viewing_itid > 0
    then
        local itemid = df.global.game.main_interface.view_sheets.viewing_itid[0]
        item = df.item.find(itemid)
    else  -- TODO implement for 0.47.05
    end

    local pos = (item) and xyz2pos(dfhack.items.getPosition(item)) or nil
    stockpile = (pos) and dfhack.buildings.findAtTile(pos) or nil
    stockpile = (df.building_stockpilest:is_instance(stockpile)) and stockpile or nil
end
assert(stockpile == nil or df.building_stockpilest:is_instance(stockpile))

if stockpile == nil then
    qerror("Select a stockpile")
end

--[[ TODO consider doing this:
for _, stockpile in ipairsF(world.buildings.other.STOCKPILE, stockpileAcceptsSeeds)
    table.insert(stockpiles, stockpile)
end
]]

local stockpiles = { stockpile }
stockpile = nil

do
    local stockpiles2 = {}
    for _, stockpile in ipairsF(stockpiles, stockpileAcceptsSeeds) do
	table.insert(stockpiles2, stockpile)
    end
    stockpiles = stockpiles2
end

if #stockpiles == 0 then
    qerror("Select a stockpile that allows seeds")
end


combineSeeds(stockpiles)
