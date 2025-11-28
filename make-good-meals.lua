local debugging = true


local utils = require('utils')

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
local current_script_name = dfhack.current_script_name():match( '([^/]*)$' )
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


---@type { [string]: { key:string, item_type:df.item_type, type:integer, index: integer, name:string, units:integer, meals:integer, ingredient:integer, trader:integer } }
--   !!NO: dictionary; key is a string made from type and index.
--   array sorted by key; key is a string made from item_type, type, and index.
local ingredient_preferences = {}


local function ip_key(item_type, type, index)
    return string.format("%02d %03d %03d", item_type, type, index)
end


local function ip_key_by_item(item)
    local item_type, type, index = item:getType(), nil, nil
    if item_type == df.item_type.FISH then
	type = item:getRace()
	index = -1
    else
	type = item:getMaterial()
	index = item:getMaterialIndex()
    end
    return ip_key(item_type, type, index)
end


local function get_ip(ip_list, item_type, type, index)
--    if item_type == df.item_type.GLOB then return nil; end	-- there are never preferences for tallow.
--    if item_type == df.item_type.EGG then return nil; end	-- there are never preferences for eggs.
    local key = ip_key(item_type, type, index)
    local ip, _, idx = utils.binsearch(ip_list, key, 'key')
    return ip, idx
end


local function fill_in_ip(ip, item_type, type, index)
    local ip = ip or {}
	
    ip.key =		ip.key		or ip_key(item_type, type, index)
    ip.item_type =	ip.item_type	or item_type
    ip.type =		ip.type		or type
    ip.index =		ip.index	or index
    -- ip.name handled below
    ip.units =		ip.units	or 0		-- count of units with this pref.
    ip.meals =		ip.meals	or 0		-- count of prepared meals with this ingredient.
    ip.ingredient =	ip.ingredient	or 0		-- count of this ingredient that we own.
    ip.trader =		ip.trader	or 0		-- count of this ingredient that traders have
    ip.purchasing =	ip.purchasing	or 0		-- count of this ingredient marked for purchase.

    if ip.name == nil then
	if ip.item_type == df.item_type.FISH then
	    ip.name = 'CREATURE:' .. df.creature_raw.find(type).creature_id
	else
	    -- ip.name = tostring(dfhack.matinfo.decode(type,index)):match('%d+:%d+%s([^>]+)>$')
	    ip.name = dfhack.matinfo.decode(type,index):getToken()
	end
    end
    return ip
end


local function get_ip_by_item(ip_list, item)
    local key = ip_key_by_item(item)
    local ip, _, idx = utils.binsearch(ip_list, key, 'key')
    return ip, idx
end


local function add_ip(ip_list, ip)
    if ip == nil or ip.key == nil then return; end
    utils.insert_or_update(ip_list, ip, 'key')
end


local function remove_ip(ip_list, ip)
    if ip == nil or ip.key == nil then return; end
    utils.erase_sorted(ip_list, ip, 'key')
end


local function ensure_get_ip(ip_list, item_type, type, index)
    local ip = get_ip(ip_list, item_type, type, index)
    ip = fill_in_ip(ip, item_type, type, index)
    add_ip(ip_list, ip)
    return get_ip(ip_list, item_type, type, index)
end


local function remove_ip_by_item(ip_list, item)
    local key = ip_key_by_item(item)
    if key and key ~= "" then utils.erase_sorted_key(ip_list, key, 'key'); end
end


local function print_ingredient_preference(ip)
    printf("%-42s %-8s %-12s %3d %4d %4d %4d %4d",
	ip.name, ip.key, df.item_type[ip.item_type], ip.units, ip.meals, ip.ingredient, ip.trader, ip.purchasing)
end


local function ip_is_cookable(ip)
--print( ip.item_type, ip.type, ip.index, dfhack.matinfo.decode( ip.type, ip.index ))

    if ip.item_type == df.item_type.FISH then return true; end

    local matinfo = dfhack.matinfo.decode(ip.type, ip.index)
    if not matinfo then return false; end

    if matinfo.material.flags.EDIBLE_COOKED then return true; end

    return false
end


local function isCookable(item)

    if item:getType() == df.item_type.FISH then return true; end

--print( item:getMaterial(), item:getMaterialIndex() )
--print(dfhack.matinfo.decode( item:getMaterial(), item:getMaterialIndex() ))
    local matinfo = dfhack.matinfo.decode( item:getMaterial(), item:getMaterialIndex())
if not matinfo then print('no matinfo'); return false; end

    if matinfo.material.flags.EDIBLE_COOKED then return true; end

    return false
end


local function collect_ingredient_preferences()
    for _,unit in ipairs( dfhack.units.getCitizens() --[[ {df.unit.find(2636)} ]] ) do
	for i, pref in ipairs(unit.status.current_soul.preferences) do
	    if pref.type == df.unitpref_type.LikeFood then
		local item_type, type, index = pref.item_type, pref.mattype, pref.matindex
		local ip = ensure_get_ip(ingredient_preferences, item_type, type, index)
		ip.units = ip.units + 1
		if not ip_is_cookable(ip) then print('uncookable food preference:', unit.id, 'preference', i, ip_key(item_type, type, index), dfhack.matinfo.decode(type, index)); end
		add_ip(ingredient_preferences, ip)
	    end
	end
    end
end


local function collect_ingredient_counts()
    -- no preferences for GLOB or EGG
    local itypes = ([[
	PLANT
	PLANT_GROWTH
	SEEDS
	MEAT
	FISH
	CHEESE
	DRINK
	LIQUID_MISC
	POWDER_MISC
    ]]):trim():split( "[,%s]+" )	-- array of strings
    local iothers = {}			-- (lockstep) array of items.other.* vectors

    for i = 1, #itypes do
	local _, iother = safecall(load(string.format("return df.global.world.items.other.%s", itypes[i])))
	local item_type = df.item_type[itypes[i]]
	for _, item in ipairs(iother) do
	    local type, index = -1, -1

	    -- do not count drinks in flasks; they are unavailable for cooking.
	    -- do not count misc liquid that's not in anything; it's probably forgotten beast venom or blood.
	    -- so, in fact, only count liquid in barrels or pots.
	    -- TODO: and buckets?
	    if df.item_drinkst:is_instance(item) then
		local cont = dfhack.items.getContainer(item)
		if (cont) and df.item_barrelst:is_instance(cont) then
		    type, index = item.mat_type, item.mat_index
		elseif (cont) and df.item_toolst:is_instance(cont) and cont.subtype.tool_use[0] == df.tool_uses.FOOD_STORAGE then
		    type, index = item.mat_type, item.mat_index
		elseif (cont) and df.item_flaskst:is_instance(cont) then
		    type, index = -1, -1
		elseif (cont) and df.item_gobletst:is_instance(cont) then
		    type, index = -1, -1
		else
		    type, index = -1, -1  -- should not be reached (?)  TODO buckets.
		end
	    -- small fish don't have mattype/matindex; they have race/caste.
	    elseif df.item_fishst:is_instance(item) then
		type, index = item.race, -1			-- TODO include caste
	    else
		type, index = item.mat_type, item.mat_index
	    end

	    local ip
	    if type ~= -1 then
		ip = ensure_get_ip(ingredient_preferences, item_type, type, index)
		if item.flags.trader then
		    local gref = dfhack.items.getGeneralRef(item, df.general_ref_type.ENTITY_ITEMOWNER)
		    local entity = (gref ~= nil) and gref.entity_id or -1
		    -- TODO what should we do with the entity?
		    ip.trader = ip.trader + item.stack_size
		else
		    ip.ingredient = ip.ingredient + item.stack_size
		end
		add_ip(ingredient_preferences, ip)
	    end
	end
    end

    for _, item in ipairs(df.global.world.items.other.FOOD) do
	local used_ingredients = {}			-- used for detecting duplicate ingredients.
	for _, ing in ipairs(item.ingredients) do
	    local already_seen_ip = get_ip(used_ingredients, ing.item_type, ing.mat_type, ing.mat_index)
	    local ip = get_ip(ingredient_preferences, ing.item_type, ing.mat_type, ing.mat_index)
	    if already_seen_ip ~= nil then
		-- do nothing
		-- dprintf("detected a meal with double ingredients: item %d", item.id)
	    elseif ip and not item.flags.trader then
		ip.meals = ip.meals + item.stack_size
		add_ip(ingredient_preferences, ip)	-- TODO put meals in a different list?
		add_ip(used_ingredients, ip)
	    end
	end
    end
end


--[[
-- TODO convert to isFood() or some such?
-- returns the (numeric) df.item_type of the item.
-- incomplete; only deals with food-related item types.
local function item_to_item_type(item)

    local type = (item) and item:getType() or df.item_type.NONE

    if      type == df.item_type.BARREL
	or  type == df.item_type.BAG
	or  type == df.item_type.MEAT
	or  type == df.item_type.FISH
	or  type == df.item_type.FISH_RAW	-- maybe ignore raw fish?  not cookable.
	or  type == df.item_type.SEEDS
	or  type == df.item_type.PLANT
	or  type == df.item_type.PLANT_GROWTH
	or  type == df.item_type.DRINK
	or  type == df.item_type.POWDER_MISC
	or  type == df.item_type.CHEESE
	or  type == df.item_type.FOOD
	or  type == df.item_type.LIQUID_MISC
	or  type == df.item_type.GLOB		-- maybe ignore tallow?  no preferences.
	or  type == df.item_type.EGG		-- maybe ignore eggs?  no preferences.
    then
	-- TODO maybe: check POWDER_MISC, LIQUID_MISC for edibility.
	-- TODO maybe: can buckets contain interesting food?  like milk?
	return type
    else
	return df.item_type.NONE		-- not interesting
    end
end
]]


local function mark_for_purchase()
    local T = df.global.game.main_interface.trade
    if not T.open then return; end
    if T.choosing_merchant then return; end
    if T.stillunloading ~= 0 then return; end
    if T.havetalker ~= 1 then return; end

    for i = 0, #T.good[0]-1 do
	local good = T.good[0][i]			-- the item we are considering purchasing.
	local item = nil				-- the item we're actually interested in.
	local count = 1

	-- TODO are there ever food items flagged as contained, or is that just for cloth/leather ?
	--   if so, ((what?))
	if T.goodflag[0][i].contained and good:getType() ~= df.item_type.NONE then
	    dfhack.error("Hey, take a look at game.main_interface.trade.good[0]["..i.."]")
	end

	if T.goodflag[0][i].contained then
	    item = nil					-- TODO is this even necessary.

	elseif good:getType() == df.item_type.BARREL then
	    -- we assume there are either 0 or 1 items in the barrel; therefore 0 or 1 iterations.
	    count = 0
	    for _, iitem in ipairs(dfhack.items.getContainedItems(good)) do
		item = iitem
		count = count + 1
		if count > 1 then qerror("more than 1 item in barrel " .. good.id); end
	    end

	elseif good:getType() == df.item_type.BAG then
	    -- merchant bags can contain 0, 1, or 20 items (in the case of seeds).
	    -- however, we expect these items to all be identical.
	    -- so we count the total number of items in the bag, and
	    -- work with the last item in the bag.
	    count = 0
	    for _, iitem in ipairs(dfhack.items.getContainedItems(good)) do
		item = iitem
		count = count + 1
	    end

	-- TODO for FISH, prefer one caste over the other.
	-- in the cases of MEAT, FISH, PLANT, PLANT_GROWTH, and CHEESE, the good is the item.
	elseif good:getType() == df.item_type.MEAT		then item = good
	elseif good:getType() == df.item_type.FISH		then item = good
	elseif good:getType() == df.item_type.SEEDS		then item = good
	elseif good:getType() == df.item_type.PLANT		then item = good
	elseif good:getType() == df.item_type.PLANT_GROWTH	then item = good
	elseif good:getType() == df.item_type.CHEESE		then item = good
	-- in the cases of FLASK and BUCKET, we don't expect any contents.  skip.
	-- in the case of CAGE, we currently don't consider whether butchering the contained
	--   animal (if any) would be of interest.  TODO consider it.  skip.
	-- in the cases of SEED, DRINK, POWDER_MISC, and LIQUID_MISC, we don't expect to find these
	--   outside of containers, and we already dealt with the containers.  skip.
	-- in the cases of FOOD, FISH_RAW, GLOB, and EGG, we don't expect to find these for sale.  skip.
	else
	    item = nil
	end

	if item == nil then goto CONTINUE; end

	-- if count is > 1, then we assume that the items have stack_size of 1, so use the count.
	local stack_size = (count > 1) and count or item.stack_size

	-- inspect the actual item
	local item_type = item:getType()
	local type, index = 0, 0
	if item_type == df.item_type.NONE then
	    -- nothing
	elseif item_type == df.item_type.FISH then
	    type, index = item.race, -1			-- TODO include caste
	else
	    type, index = item.mat_type, item.mat_index
	end

	local purchase_it = false

	-- is it interesting?
	local ip = get_ip(ingredient_preferences, item_type, type, index)
	if not ip then goto CONTINUE; end
	if ip.units == 0 then goto CONTINUE; end	-- shouldn't happen.

	-- TODO maybe: it would be nice to consider derivative products:
	--	this milk type can be turned into this cheese type; does anyone like this cheese type?
	--	this plant/fruit type can be brewed into this drink type.
	--	this plant type can be milled into this flour type.
	--	this plant type can be brewed/milled, yielding this seed type.
	--	this plant can be processed-to-bag or processed-to-barrel.

	if ip.item_type == df.item_type.DRINK then
	    purchase_it = (ip.ingredient + ip.purchasing < 25)  -- TODO tune
	else
	    purchase_it = (ip.ingredient  + ip.purchasing < 20)
	end

	if purchase_it then
	    T.goodflag[0][i].selected = true
	    ip.purchasing = ip.purchasing + stack_size
	    printf("Marking: %s", dfhack.items.getReadableDescription(item))
	    add_ip(ingredient_preferences, ip)
	end

	::CONTINUE::
    end
end


local function purge_ip_by_field_is_0(ip_list, field)
    -- TODO ought to implement and use del_ip(ip_list)
    for i = #ip_list, 1, -1 do
	if ip_list[i][field] == 0 then
	    table.remove(ip_list, i)
	end
    end
end


local function purge_ip_by_cmpfn(ip_list, cmpfn)
    -- TODO ought to implement and use del_ip(ip_list)
    for i = #ip_list, 1, -1 do
	if cmpfn(ip_list[i]) then
	    table.remove(ip_list, i)
	end
    end
end


-- hacky -- edits an existing job instead of creating a new job.
---@param items (df.item|df.item.id|integer)[]
local function make_specific_prepared_meal(items)
    if type(items) ~= "table" or #items == 0 then qerror('no ingredients'); end

    for ii, item in ipairs(items) do  -- sanity/safety checks
	item = (math.type(item) == "integer") and df.item.find(item) or item
	if not df.item:is_instance(item) then qerror('not an item!'); end
	local i = utils.binsearch(df.global.world.items.other.ANY_COOKABLE,item.id,'id')  -- i should == item.
	-- TODO make sure that .ANY_COOKABLE includes barrels, bags, buckets, jugs.
	if not i then qerror(ii ..' ingredient not cookable: ' .. dfhack.items.getReadableDescription(item)); end
	if i.flags.in_job then qerror(ii .. ' ingredient in job: ' .. dfhack.items.getReadableDescription(item)); end
    end

    local b=dfhack.gui.getSelectedBuilding(true)
    if not b or b:getType() ~= 13 or b:getSubtype() ~= 19 then qerror('not in kitchen'); end

    local j = nil
    for i,jj in ipairs(b.jobs) do
	if jj.job_type == 114 and #jj.items == 0 then j = jj; print('editing job ' .. i); break; end
    end
    if not j then qerror('did not find a cooking job without assigned ingredients'); end
    -- TODO abort if the job has a worker assigned.

    for ii, item in ipairs(items) do
	item = (type(item) == "number") and df.item.find(item) or item
	dfhack.job.attachJobItem(j,item,df.job_role_type.Hauled,(ii==1) and 0 or 1, (ii-1));
    end

    for _,e in ipairs(j.job_items.elements) do e.quantity=0; end
end


local function isPreferenceFor(item)
   local ip, idx = get_ip_by_item(ingredient_preferences, item)
   return (ip ~= nil)
end


-- overly simplistic; currently returns the first match in the list.  fragile.
local function find_ingredient(item_type)

    for i,item in ipairs(df.global.world.items.other.ANY_COOKABLE) do
	f = item.flags

	if	   f.forbid 
		or f.in_job 
		or f.dump
		or f.rotten 
		or f.owned 
		or f.removed 
		or f.garbage_collect
		or f.already_uncategorized 
	then
	    goto CONTINUE
	end

	if      item_type == item:getType()
		and (
		   item:getType() == df.item_type.MEAT
		or item:getType() == df.item_type.FISH
		or item:getType() == df.item_type.PLANT
		or item:getType() == df.item_type.PLANT_GROWTH
		or item:getType() == df.item_type.CHEESE
		or item:getType() == df.item_type.SEEDS
	        )

		and isCookable(item)
		and isPreferenceFor(item)
	then
	    remove_ip_by_item(ingredient_preferences, item)
	    return item
	end

	if	item_type == df.item_type.POWDER_MISC
		and item:getType() == df.item_type.BAG
		and #dfhack.items.getContainedItems(item) == 1
	then
	    for _, item2 in ipairs(dfhack.items.getContainedItems(item)) do   -- exactly one iteration.
		if	item2:getType() == df.item_type.POWDER_MISC
			and isCookable(item2)
			and isPreferenceFor(item2)
		then
		    remove_ip_by_item(ingredient_preferences, item2)
		    return item
		end
	    end
	end

	if	( item_type == df.item_type.DRINK or item_type == df.item_type.LIQUID_MISC )
		and ( item:getType() == df.item_type.BARREL or item:getType() == df.item_type.TOOL )  -- TODO tool subtype use flags
		and #dfhack.items.getContainedItems(item) == 1
	then
	    for _, item2 in ipairs(dfhack.items.getContainedItems(item)) do   -- exactly one iteration.
		if	item_type == item2:getType()
			and isCookable(item2)
			and isPreferenceFor(item2)
		then
		    remove_ip_by_item(ingredient_preferences, item2)
		    return item
		end
	    end
	end

	::CONTINUE::
    end

    qerror('did not find item of type ' .. item_type)
end



collect_ingredient_preferences()
collect_ingredient_counts()
purge_ip_by_cmpfn(ingredient_preferences, function(ip) return (ip.units == 0); end)
purge_ip_by_cmpfn(ingredient_preferences, function(ip) return (ip.trader == 0); end)
--purge_ip_by_cmpfn(ingredient_preferences, function(ip) return (ip.purchasing == 0); end)
purge_ip_by_cmpfn(ingredient_preferences, function(ip) return (ip.ingredient >=20); end)
purge_ip_by_cmpfn(ingredient_preferences, function(ip) return(ip.meals>=ip.units*5); end)
mark_for_purchase()
--purge_ip_by_cmpfn(ingredient_preferences, function(ip) return(ip.meals>=ip.units*5 or ip.ingredient==0); end)
--purge_ip_by_cmpfn(ingredient_preferences, function(ip) return(ip.meals>=ip.units*5 or ip.ingredient~=0); end)



--[[
capture={};function print(...)local out={};for i,p in ipairs({...}) do p=tostring(p);p=p..(' '):rep((8-(p:len()%8))or 8)
table.insert(out,p);end;table.insert(capture,table.concat(out):trim()..'\n');end;-- TODO rtrim()
print(1,2,3);print(4,' ',' ',5);print(6,77,8888,9999,11111,222222,3333333,44444444,555555555);print(10 .. 11 .. 12);
print=dfhack.BASE_G.print;print('done');dfhack.internal.setClipboardTextCp437Multiline(table.concat(capture))
1       2       3
4                       5
6       77      8888    9999    11111   222222  3333333 44444444        555555555
101112
]]

if false then  -- print to clipboard

    local capture = {}
    local function print(...)   -- testing making this local
	local out={}
	for i,p in ipairs({...}) do
            p = tostring(p)
            p = p .. (' '):rep( (8-(p:len()%8)) or 8)
            table.insert(out,p)
	end
	table.insert(capture, table.concat(out):trim() .. '\n')  -- TODO rtrim()
    end
    for _, ip in ipairs(ingredient_preferences) do print_ingredient_preference(ip); end
    print = dfhack.BASE_G.print
    dfhack.internal.setClipboardTextCp437Multiline(table.concat(capture))
end

if true then  -- print to console
    for _, ip in ipairs(ingredient_preferences) do print_ingredient_preference(ip); end
end

print('done')

--[=[ -- cook a meal from a 'recipe'

-- TODO dfhack.kitchen.findExclusion(), dfhack.kitchen.removeExclusion(), dfhack.kitchen.addExclusion()

local item
ingredient_preferences = {}
collect_ingredient_preferences()
collect_ingredient_counts()
purge_ip_by_cmpfn(ingredient_preferences, function(ip) return((ip.meals>=ip.units*5)) or ip.ingredient==0; end)
for i = 1,1 do
  local ingredients = {
	find_ingredient(df.item_type.FISH),
	find_ingredient(df.item_type.PLANT),
	find_ingredient(df.item_type.DRINK),
	find_ingredient(df.item_type.CHEESE),
  }
  for _, item in ipairs(ingredients) do print(item.id, dfhack.items.getReadableDescription(item)); end
  make_specific_prepared_meal( ingredients )
end
--]=]


--[[
game.main_interface.trade
	.open = true
	.choosing_merchant = false
	.bld -> building trade depot
	.mer -> a caravan state
		.entity = historial_entity.id
		.animals[]
		.goods[] -> item_id's
	.good[0][] 	this merchant's items, "sorted"
	.good[1][]	the fort's items, "sorted"
	.goodflag[0][]	trade_interface_good_flags
	.goodflag[1][]	trade_interface_good_flags
		.selected
		.contained
		.container_collapsed
		.filtered_off
	.good_amount[0][]  not used?
	.good_amount[1][]  not used?
]]


--[==[	Collection of interesting / important food discussions.


(a recent discussion 4/15/25 on the current state of prepared meals.)
https://discord.com/channels/793331351645323264/873014631315148840/1361938112170954763

(an important post in that discussion)
https://discord.com/channels/793331351645323264/873014631315148840/1361942363458768906
it arguably creates more of an incentive to try to have meals that satisfy individual dwarf 
preferences, although the micro required for that is _insane_ especially since we've had 
very little lck manipulating PrepareMeal jobs (at least last i heard)

( 5/7/25 on immortal-cravings and forcing eat jobs.)
https://discord.com/channels/793331351645323264/873014631315148840/1369588977555865662
Interesting…I just noticed that goblin monster slayers eat by tasking the whole stack of 
meals to eat (via `immortal-cravings`) instead of taking one meal out of the stack like 
other citizens/residents. They still only consume one meal out of the whole stack though.

( 5/15/25 on food selection and fort design.)
https://discord.com/channels/793331351645323264/873014631315148840/1372563194433769674
Also why are my dwarves eating raw berries when I have over 150 lavish meals?
(later)
I did some tests, and it appears that if your meals aren't high value enough, they'll 
go for whatever is closest.  With high value meals, they'll skip any raw food that are 
closer and go for the meals.
And of course, they will go for preferred food if available, but not all the time.
*this was for short distances, with a difference of only a few tiles between the raw 
food and prepared meals; I didn't test to see how far is too far.
(later, Quietust formula)
When choosing meals, the "score" for a given food item starts at its distance (calculated 
as `max(dx,dy,dz)`) - if it matches a Preference, it cuts the score in half and subtracts 
30, and if it's recently-eaten (or is a live Vermin) it quadruples the score and adds 100. 
The item with the lowest score wins.
If dwarves are preferring berries over prepared meals despite them being further away, 
then those dwarves probably prefer to eat those berries.
And something I recently discovered: if your meals only contain one single unique ingredient 
(e.g. a cow meat roast consisting of well-minced cow meat, finely-minced cow meat, 
well-minced cow meat, and well-minced cow meat), then dwarves will treat them as if they 
were **just** that ingredient (e.g. they'll behave as if it's just an ordinary piece of cow 
meat) and will get tired of eating them.

Tachytaenius 1/3/2025
https://discord.com/channels/793331351645323264/793331351645323267/1324788382496329758
Is it possible to make meals less valuable

(and following discussion)

Quietust 1/3/25
Prepared meals aren't created using reactions - indeed, attempting to create a FOOD object 
via custom reaction tends to crash the game (unless that got fixed at some point).
We could certainly override the implementation of `item_foodst::getImprovementsValue()`, 
since that's where ingredients are actually taken into account (and _nothing else_).

Quietust 1/3/25
Right now, food ingredients follow the same formula as other items:
* 0: itemval
* 1: itemval * 1.1 + 3
* 2: itemval * 1.2 + 6
* 3: itemval * 1.33 + 10
* 4: itemval * 1.5 + 15
* 5: itemval * 2 + 30

Interestingly, the real formula works like this:
```
topval = itemval * 2 + 30;
if (quality == 0) outval = itemval;
if (quality == 1) outval = (topval + itemval*9) / 10;
if (quality == 2) outval = (topval + itemval*4) / 5;
if (quality == 3) outval = (topval + itemval*2) / 3;
if (quality == 4) outval = (topval + itemval) / 2;
if (quality == 5) outval = topval;
if (outval < itemval + quality) outval = itemval + quality;
```
(the last line is there, but it will never have any effect because `quality` is always
less than `30 / [10|5|3|2]`)

Izmerilda Richter — 1/3/2025 1:23 PM
Maybe, because single-ingredient food crash the game. When I tried to add meal type even
lesser than biscuits, with 1 ingredient, the game crashed.
https://discord.com/channels/793331351645323264/793331351645323267/1324867248393031710
rome of oxtrot — 1/3/2025 2:29 PM
any attempt to make a custom reaction that produces a FOOD item crashes the game
Quietust — 1/3/2025 7:14 PM
The *job* for creating prepared meals iterates across all items attached to the job, and 
when it finds a container, it uses all of the items inside that container.
For things like bags of flour/sugar or barrels of alcohol/Dwarven syrup, there's only one 
item in the barrel so it works fine.
But if the job mistakenly picks up a barrel containing **multiple** cookable items (e.g. 
meat/fish/plants, or multiple individual stacks of milk), then things go a bit weird.
When you milk creatures yourself, you can end up with a barrel containing 100 individual 
milk items, and if that barrel gets used by a Prepare Meal job, then it will add 100 
ingredients to the meal.
It's a **very** old bug, one I personally reproduced in a fortress in version 0.23.130.23a.
myk002 — 1/3/2025 7:18 PM
If we can't hook a reaction, another option might be to adjust stack sizes **as the items 
for the job are fetched**
myk002 — 1/3/2025 7:19 PM
that is, when an item is attached to the job, split the stack or dump things out of the 
barrel (hrm. liquids) before the item is grabbed
myk002 — 1/3/2025 7:21 PM
for items in barrels, maybe temporarily hold the extra items in limbo and re-insert them 
into the barrel after the job is complete/canceled


Very long discussion of cooked meals.
https://discord.com/channels/793331351645323264/873014631315148840/1349091352075305073
Thyrus — 3/11/25, 11:47 AM
So, some testing: it is absolutely possible to satisfy the EatGoodMeal need without catering 
for preferences. Cooking four stacks of quarry bush into a *quarry bush roast* yields a meal 
whose individual portions are worth 22, which seems to be enough to satisfy the need, 
regardless of preferences.
Thyrus — 3/11/25, 12:02 PM
Second observation: The primary ingredient (The only ingredient whose value is counted fully, 
in addition to being averaged with the other ingredients) seems to be the ingredient that is 
fetched last. This is sad, because I already know how to create jobs where the first job 
item is assigned.
{...}
https://discord.com/channels/793331351645323264/873014631315148840/1349102526271852695
rome of oxtrot — 3/11/25, 12:31 PM
i don't know if we can force specific ingredients into a prepared meal
we could try to reorder the ingredients vector, i suppose
{...}
https://discord.com/channels/793331351645323264/873014631315148840/1349180558701494405
Scunt — 3/11/25, 5:41 PM
Are we getting a dfhack tool to make dwarves cook proper meals with diverse ingredients?
tmPreston — 3/11/25, 6:29 PM
0.47 had a tool that allowed you to specify all 4 ingredients of a meal. Maybe you could 
look into that?
It was the same tool that allowed you to engrave only specific furniture or mill only dyes 
by editing the repeat job itself.
myk002 — 3/11/25, 8:19 PM
How about reordering the item requirements instead of the items? That will change the order 
that they are fetched and used
myk002 — 3/11/25, 8:20 PM
We have a PR open to reinstate that tool
Thyrus — 3/11/25, 11:08 PM
Unless I messes up, the primary ingredient is the last ingredient.
{...}
https://discord.com/channels/793331351645323264/873014631315148840/1349424295087964170
Thyrus — 3/12/25, 9:50 AM
I misread the meal value formula yesterday. The contribution of the main ingredient is:  
<meal_base=1> * <material value> * <quality multiplier> * + <quality bonus>. So this can 
differ greatly for ingredients of equal value (e.g. cheese has <base = 10> * <material=1> 
and quarry bushes have <base=2> * <material=5>. Sugar and syrup profit the most 
<base=1>*<material=20>.
{...}
https://discord.com/channels/793331351645323264/873014631315148840/1349485162215510070
Thyrus — 3/12/25, 1:52 PM
If your cook is skilled enough, a portion value of 22 should be obtainable fairly reliably 
from ingredients of value 10. An there's quite a few of those.
But 5 points in cooking is now a must on embark.
https://discord.com/channels/793331351645323264/873014631315148840/1349486149436969062
{this link has value calculation for drinks}
{or maybe it's for meals, the subsequent discussion isn't clear}
{lots and lots of subsequent discussion}


This is a very long and good discussion:
https://discord.com/channels/793331351645323264/873014631315148840/1348739871161978981
Thyrus — 3/10/25, 12:30 PM
Am I the only one who is basically unable to satisfy the EatGoodMeal need in the latest patch:
                Need  Strength  Focus Impact  Frequency  Num. Unfettered -> Badly distracted
                ----  --------  ------------  ---------  -----------------------------------
         EatGoodMeal        43       -161855         30      0    0    0    8   16    6    0
       AcquireObject        37       -145467         27      1    0    0    7   14    5    0
      PrayOrMeditate       350       -144239         75      6    2    8   31   24    4    0
I'm about a year and a half into a new fort, and this is now the least fulfilled need. 
Before the recent nerf to prepared meals, I don't think I have ever seen that. I think 
this solves the question whether the reduced meal value will have an impact in fulfilling 
dwarven needs. Can we fix this?
Ozzatron
[CLAM]
 — 3/10/25, 2:48 PM
I bet this is exactly related to the meal value nerf, because arbitrary meal value checkpoints 
in the mood satisfaction checks are unedited.
rome of oxtrot — 3/10/25, 2:56 PM
that's a fair point, the definition of "good meal" probably wasn't nerfed correspondingly
{...lots...}
rome of oxtrot — 3/11/25, 8:41 AM
in 50.15, to count as a "good meal", the meal has have a base value of at least 20 or a 
personal value (based on "liked foods") of at least 1, and the base value plus 4 times the 
personal value has to exceed 4
so eating liked foods will almost always be enough to count, but the base value nerf 
definitely makes it a lot harder without catering to preferences. expect toady to consider 
this "a desired consequence"
found same function in 51.06
Thyrus — 3/11/25, 8:50 AM
Will dwarves actually seek out prepared meals with ingredients they like? I thought this 
would only trigger if, by accident, they chose a meal containing ingredients they like.
{...}
Quietust — 3/11/25, 8:52 AM
The locatefood function checks if the unit "likes" the meal in question, and it gives the 
food a major priority boost.
And the like function checks ingredients inside prepared meals.
{...lots more good discussion AND reverse-engineered code...}
Quietust — 3/11/25, 8:59 AM
If you want to get valuable prepared meals, you need to start using valuable ingredients, 
not just 1-value meat.
{...}
Ozzatron — 3/11/25, 9:02 AM
"making food preferences actually matter" sounds great, if dwarves had like 12 food 
preferences so it was even possible
{...even more discussion...}
Quietust — 3/11/25, 9:20 AM
And actually, the like bonus isn't actually used directly when choosing meals to eat - 
all it does is boost the item's priority if it's greater than zero (and also make it 
exempt from "eating the same food lately" thoughts).
The game takes the "chessboard" distance (i.e. max(abs(dx),abs(dy),abs(dz)))between the 
unit and the food item, and if there's at least one preference match, it divides that 
value by 2 and subtracts 30.
Though I'm not sure what happens when that causes the "score" to go negative - I think 
it'll still work, since it looks like it's doing signed comparisons. 
Oh, and if the food has been eaten recently, it multiplies the score by 4 and adds 100.
Granted, I'm looking at the logic from 0.28.181.40d right now (since the decompilation 
is easier to read), but I expect this part still works exactly the same.
{...and more...}
tmPreston — 3/11/25, 9:51 AM
The way i see it, i would be fine with a tool that scans a fort wide list of preferences 
and then marks all meals (not ingredients, due to other uses) that don't include any for 
sale
However, one thing in this whole convo leaves me slightly confused. Let's say a dwarf 
likes oranges. Will eating them raw be pretty much the same as an 
orange+tallow+meat+booze meal?
Quietust — 3/11/25, 9:54 AM
Yes, it is. 
However, you can bake 1 orange and a hundreds other ingredients into 101 meals which 
will all make that dwarf happy.
tmPreston — 3/11/25, 9:54 AM
Yeah
Stops being relevant if i have 500 oranges, but some ingredients are hard to come by
myk002 — 3/11/25, 9:55 AM
that's a mechanic I'd like to see changed as well
Quietust — 3/11/25, 9:55 AM
Prepared meals only store the type/material information for their ingredients, not the 
quantity used.
myk002 — 3/11/25, 9:56 AM
I'd like to see the stack sizes of ingredients be equal, and the number of meals prepared 
equal the size of an ingredient stack
e.g. 1 orange, one tallow, one booze, one quarry bush leaf -> 1 lavish meal
{...}
Quietust — 3/11/25, 10:00 AM
If you're using more valuable ingredients like flour, dwarven sugar, quarry bush leaves, 
and cheese, then you'll get more valuable meals.
Or even if you use the meat of more valuable creatures - alligators instead of cows, for 
example.
rome of oxtrot — 3/11/25, 10:01 AM
balancing argues that more proecssed ingreients should generate more or more valuable meals

--]==]


--[=[   Classify ingredient types.

Parsing rules:
All-uppercase without colons matches an item type, or a creature or plant id.
If a creature id or plant id is given, any edible part of that creature or plant will match.
	FISH		matches any item of item type FISH.
	EGG		matches any item of item type EGG.
	TALLOW		matches any rendered animal fat.
	MILL		matches any flour, sugar, or other edible powder.
	BADGER		matches any edible badger material.  It does not match giant badgers, badger men, 
			or honey badgers.
	@@@ creatures
	@@@ plants
All-uppercase with one colon exact-matches a creature material or plant material.
	RAVEN:MUSCLE			matches raven meat.  It does not match giant ravens or raven men.
	@@@ plant
All-uppercase with two colons exact-matches a dfhack.matinfo token string (single-string type).
	CREATURE:GIANT_TOAD:MUSCLE	matches giant toad meat.
	PLANT:WEED_RAT:STRUCTURAL	matches rat weed plants.
	PLANT:TWO-GRAIN_WHEAT:MILL	matches two-grain wheat flour.
	CREATURE:HONEY_BEE:HONEY	matches honeybee honey.  It does not match bumblebee honey.
All-lowercase matches any part of a material.state.name.Solid or .Liquid, or a creature or plant name.
	flour		matches any material that contains the word 'flour'.
  * To use a space, substitute the two characters '%s'.
	plump%shelmet	matches the plant of that name.
	wheat%sflour	matches any material containing the words 'wheat flour'.
	TODO: support quotes?
  * Only the singular or plural species name is matched.  Matching is done against each word of the 
    species name.  Full-string matches are required.  Caste (gender) or child names are not tested.
	deer		matches deer, giant deer, and deer man.  It does not match reindeer.
	bull		matches bull shark.  It does not match bull.  The species name for that is cow.
All-lowercase can use symbols used by Lua string.match().
	a.*k		matches aardvark and angelshark.
	berry$		matches any food ending in berry. Does not match strawberry plants.
	@@@

The words 'not', 'and', and 'or' can be used.  The comma symbol ',' is a synonym for 'or'.
An implciit 'or' is inserted between two lines.
	elk and not men and not birds
			matches elk and giant elk.  it does not match elk man and elk bird.

Mixed-case with an equals symbol defines a category.  These can be recursively defined.
	Fish =		FISH or moghopper	-- TODO Q: moghopper can be a preference; are they edible?
Mixed-case without the equals sign uses that category.

TODO differentiate pressed cake and pastes.  can pastes be edible?  can slurries be edible?  are slurries pastes?


Define: Berries = berry$, GRAPE
-- the $ restricts the match to end in berry, because strawberry plants are edible but not fruit.
-- throw in grapes, they're almost berries.

Define: Sweetener = sugar$ or syrup$ or honey$
-- note: BUMBLEBEE:HONEY cannot be obtained in-game.  TODO is that true?

Define: TreeFruit = TODO
-- does not include OLIVE, all Citrus.

Define: TreeNuts = TODO

Define: Nuts = TreeNuts or BAMBARA_GROUNDNUT or PEANUT:SEED or rock%snut

Define: Citrus = TODO

Define: Fruit
	Berries
	TreeFruit
	MUSKMELON
	WATERMELON
	PASSION_FRUIT
	GRAPE
	PINEAPPLE
	@@@
-- does not include bitter melon
	
Define: SaladVegetable = ARTICHOKE, ASPARAGUS, BAMBARA_GROUNDNUT, STRING_BEAN, BROAD_BEAN, BEET,
	BITTER_MELON, CABBAGE, CAPER, WILD_CARROT, CASSAVA, CELERY, CHICKPEA, CHICORY, COWPEA,
	CUCUMBER, EGGPLANT, GARDEN_CRESS, LEEK, LENTIL, LETTUCE, MUNG_BEAN, MUSKMELON, ONION,
	PARSNIP, PEA, PEANUT, PEPPER, POTATO, RADISH, RED_BEAN, SOYBEAN, SPINACH, SQUASH, SWEET_POTATO,
	TARO, TOMATO, TOMATILLO, TURNIP, URAD_BEAN, WATERMELON,
	BUCKWHEAT, ALFALFA, MAIZE, QUINOA, KANIWA, BITTER_VETCH, amaranth, RED_SPINACH, millet,
	ROOT_MUCK, TUBER_BLOATED, MUSHROOM_HELMET_PLUMP, BERRIES_STRAW:STRUCTURAL, WEED_RAT, 
    TODO
	OLIVE
-- left out GARLIC, HORNED_MELON, RHUBARB, WINTER_MELON, LESSER_YAM, LONG_YAM, PURPLE_YAM, WHITE_YAM


Recipe: FruitSalad	Fruit, Fruit, Citrus or Fruit, optional Fruit, Sweetener

Recipe: Ceviche
	Fish
	Citrus
	optional Alcohol
	optional ONION
	optional PEPPER
	optional TOMATO or CUCUMBER
	optional AVOCADO or MANGO
-- Alcohol is not traditional, but we need recipes that use alcohol.

Recipe CaesarSalad
	Leaves
	optional GARLIC
	Oil
	EGG
	optional Citrus
	optional FISH_ANCHOVY
	CHEESE
-- romaine lettuce, garlic croutons, eggs, olive oil, lemon juice, parmesian, anchovies and/or worcestershire sauce.
-- sometimes a bit of raw garlic.  sometimes dijon mustard.

Define: RootVegetable = BEET, TUBER_BLOATED, WILD_CARROT, ROOT_MUCK, ONION, POTATO, SWEET_POTATO, yam
-- left out radish

Define: Leaves = LETTUCE or SPINACH or RED_SPINACH or CABBAGE or leaf or leaves

Define: Vegetable = GardenVegetable or 

Define: Fat = tallow or oil

Define:	PizzaTopping = spinach, artichoke, asparagus, onion, tomato, pineapple, olive

Recipe: Pizza:
	flour
	MEAT or PizzaTopping
	optional MEAT or PizzaTopping or FISH_ANCHOVY
	optional PizzaTopping
	CHEESE

]=]

--[==[

***
On the possibility of extending / overriding the df.food_ingredient_type vector.

The df.food_ingredient_type._identity points into the DFHack DLL ?
	userdata: 0000_7FFB_FE7F_A2D0

In the binary:
One hit for "The ingredients are "
One hit for "minced "
One hit for "cooked "
When is cooked used instead of minced?


]==]


--[==[
CREATURE:GILA_MONSTER:MUSCLE               48 020 167 MEAT           1    0    0    0    0
CREATURE:FISH_COELACANTH:MUSCLE            48 020 248 MEAT           1    0    5    0    0
CREATURE:FISH_COD:MUSCLE                   48 020 252 MEAT           1    0    0    0    0
CREATURE:FISH_GROUPER_GIANT:MUSCLE         48 020 254 MEAT           1    0    0    0    0
CREATURE:FISH_TIGERFISH:MUSCLE             48 020 270 MEAT           1    0    0    0    0
CREATURE:GIANT_ALLIGATOR:MUSCLE            48 020 304 MEAT           1    0    0    0    0
CREATURE:GIANT_ANOLE:MUSCLE                48 020 490 MEAT           1    0    0    0    0
CREATURE:GIANT_POND_TURTLE:MUSCLE          48 020 516 MEAT           1    0    0    0    0
CREATURE:FISH_HERRING:MUSCLE               48 020 546 MEAT           1    0    0    0    0   ??? !!!
CREATURE:FISH_GLASSEYE:MUSCLE              48 020 552 MEAT           1    0    0    0    0   ??? !!!
CREATURE:FISH_FLOUNDER:MUSCLE              48 020 555 MEAT           2    0    0    0    0   ??? !!!
CREATURE:FISH_LUNGFISH:MUSCLE              48 020 561 MEAT           1    0    0    0    0   ??? !!!
CREATURE:FISH_BULLHEAD_BROWN:MUSCLE        48 020 563 MEAT           1    0    0    0    0   ??? !!!
CREATURE:FISH_BULLHEAD_YELLOW:MUSCLE       48 020 564 MEAT           3    0    0    0    0   ??? !!!
CREATURE:FISH_CHAR:MUSCLE                  48 020 567 MEAT           1    0    0    0    0   ??? !!!
CREATURE:FISH_PERCH:MUSCLE                 48 020 571 MEAT           1    0    0    0    0   ??? !!!
CREATURE:MONITOR_LIZARD:MUSCLE             48 020 710 MEAT           1    0    0    0    0
CREATURE:BIRD_CARDINAL:MUSCLE              48 021 008 MEAT           1    0    0    0    0   !!!
CREATURE:BIRD_GRACKLE:MUSCLE               48 021 011 MEAT           1    0    0    0    0   !!!
CREATURE:BIRD_RW_BLACKBIRD:MUSCLE          48 021 017 MEAT           1    0    0    0    0
CREATURE:GIANT_SNOWY_OWL:MUSCLE            48 021 048 MEAT           1    0    0    0    0
CREATURE:BIRD_LORIKEET:MUSCLE              48 021 076 MEAT           2    0    0    0    0
CREATURE:GIANT_EAGLE:MUSCLE                48 021 108 MEAT           1    0    0    0    0
 CREATURE:BIRD_HORNBILL:MUSCLE              48 021 109 MEAT           1    1    0    5    0
CREATURE:GIANT_MASKED_LOVEBIRD:MUSCLE      48 021 114 MEAT           1    0    0    0    0
CREATURE:MANTIS:MUSCLE                     48 021 130 MEAT           1    0    0    0    0
CREATURE:THRIPS:MUSCLE                     48 021 139 MEAT           1    0    0    0    0
 CREATURE:PIG:MUSCLE                        48 021 177 MEAT           1    0    9    5    0
CREATURE:GIANT_BUTTERFLY_MONARCH:MUSCLE    48 021 208 MEAT           2    0    0    0    0
CREATURE:WALRUS:MUSCLE                     48 021 225 MEAT           1    0    0    0    0
 CREATURE:SHARK_NURSE:MUSCLE                48 021 235 MEAT           1    0    0    5    0
 CREATURE:SHARK_BLUE:MUSCLE                 48 021 242 MEAT           1    0    0    0    0
CREATURE:SHARK_ANGEL:MUSCLE                48 021 244 MEAT           1    0    0    0    0
CREATURE:NARWHAL:MUSCLE                    48 021 262 MEAT           1    0    0    0    0
CREATURE:RACCOON:MUSCLE                    48 021 287 MEAT           1    0    0    0    0
CREATURE:GIANT_RACCOON:MUSCLE              48 021 289 MEAT           1    0    0    0    0
CREATURE:MOOSE, GIANT:MUSCLE               48 021 319 MEAT           1    0    0    0    0
CREATURE:ELEPHANT:MUSCLE                   48 021 323 MEAT           1    0    0    0    0
CREATURE:ORANGUTAN:MUSCLE                  48 021 353 MEAT           1    0    0    0    0
 CREATURE:BIRD_VULTURE:MUSCLE               48 021 372 MEAT           1    0    0    0    0
CREATURE:GIANT_RHINOCEROS:MUSCLE           48 021 377 MEAT           1    0    0    0    0
CREATURE:ARMADILLO:MUSCLE                  48 021 387 MEAT           1    0    0    0    0
CREATURE:BEAR_POLAR:MUSCLE                 48 021 396 MEAT           1    0    0    0    0
CREATURE:CHINCHILLA:MUSCLE                 48 021 402 MEAT           1    0    0    0    0
CREATURE:DRUNIAN:MUSCLE                    48 021 406 MEAT           1    0    0    0    0
CREATURE:CREEPING_EYE:MUSCLE               48 021 407 MEAT           1    0    0    0    0
CREATURE:MAGMA_CRAB:MUSCLE                 48 021 411 MEAT           1    0    0    0    0
CREATURE:RUTHERER:MUSCLE                   48 021 418 MEAT           1    0    5    0    0
CREATURE:BLIND_CAVE_BEAR:MUSCLE            48 021 428 MEAT           1    0    0    0    0
CREATURE:GIANT_OCTOPUS:MUSCLE              48 021 439 MEAT           1    0    0    0    0
CREATURE:CRAB:MUSCLE                       48 021 440 MEAT           1    0    4    0    0   ??? !!!
CREATURE:GIANT_SPERM_WHALE:MUSCLE          48 021 460 MEAT           1    0    0    0    0
CREATURE:GIANT_HARP_SEAL:MUSCLE            48 021 466 MEAT           1    0    0    0    0
CREATURE:FOXSQUIRREL:MUSCLE                48 021 470 MEAT           2    0    0    0    0
CREATURE:GIANT_MINK:MUSCLE                 48 021 513 MEAT           1    0    0    0    0
CREATURE:GIANT_FLYING_SQUIRREL:MUSCLE      48 021 536 MEAT           1    0    0    0    0
CREATURE:FISH_LAMPREY_BROOK:MUSCLE         48 021 542 MEAT           1    0    0    0    0    ??? !!!
CREATURE:FISH_RAY_BAT:MUSCLE               48 021 543 MEAT           1    0    0    0    0
CREATURE:JELLYFISH_SEA_NETTLE:MUSCLE       48 021 557 MEAT           1    0    0    0    0
CREATURE:TOAD_GIANT_CAVE:MUSCLE            48 021 606 MEAT           1    0    0    0    0
CREATURE:OLM_GIANT:MUSCLE                  48 021 607 MEAT           1    0    4    0    0
CREATURE:IMP_FIRE:MUSCLE                   48 021 614 MEAT           1    0    0    0    0
CREATURE:OLM:MUSCLE                        48 021 621 MEAT           1    0    0    0    0
CREATURE:GIANT_KOALA:MUSCLE                48 021 649 MEAT           1    0    0    0    0
 CREATURE:BOBCAT:MUSCLE                     48 021 665 MEAT           1    0    0    5    0
CREATURE:GIANT_HYENA:MUSCLE                48 021 706 MEAT           3    0    0    0    0
CREATURE:GIANT_LION_TAMARIN:MUSCLE         48 021 760 MEAT           1    0    0    0    0
CREATURE:STOAT:MUSCLE                      48 021 761 MEAT           1    0    0    0    0
CREATURE:SPIDER_CAVE_GIANT:MUSCLE          48 022 615 MEAT           1    0    6    0    0
CREATURE:ANT:MUSCLE                        48 024 205 MEAT           1    0    0    0    0
 CREATURE:DONKEY:EYE                        48 026 173 MEAT           1    0    0    0    0
 CREATURE:SHARK_BLUE:KIDNEY                 48 035 242 MEAT           1    0    0    0    0

 CREATURE:CUTTLEFISH                        49 446 -01 FISH           1    0    0   35    0
CREATURE:NAUTILUS                          49 467 -01 FISH           4    0    0    0    0
CREATURE:MOGHOPPER                         49 471 -01 FISH           2    0    0    0    0
 CREATURE:MUSSEL                            49 537 -01 FISH           2    0    0   20    0
 CREATURE:OYSTER                            49 538 -01 FISH           2    0    0   20    0
 CREATURE:FISH_SALMON                       49 539 -01 FISH           2    0   13   30    0
CREATURE:FISH_HAGFISH                      49 541 -01 FISH           1    0    0    0    0
 CREATURE:FISH_LAMPREY_BROOK                49 542 -01 FISH           3    0    0   35    0
 CREATURE:FISH_HERRING                      49 546 -01 FISH           1    0    0   35    0
CREATURE:FISH_SHAD                         49 547 -01 FISH           2    0    0    0    0
CREATURE:FISH_ANCHOVY                      49 548 -01 FISH           3    0    0    0    0
CREATURE:FISH_TROUT_STEELHEAD              49 549 -01 FISH           3    0    0    0    0
CREATURE:FISH_HAKE                         49 550 -01 FISH           2    0    0    0    0
CREATURE:FISH_SEAHORSE                     49 551 -01 FISH           2    0    0    0    0
CREATURE:FISH_GLASSEYE                     49 552 -01 FISH           2    0    0    0    0
CREATURE:FISH_PUFFER_WHITE_SPOTTED         49 553 -01 FISH           1    0    0    0    0
CREATURE:FISH_SOLE                         49 554 -01 FISH           2    0    0    0    0
CREATURE:FISH_FLOUNDER                     49 555 -01 FISH           1    0    0    0    0
CREATURE:SQUID                             49 558 -01 FISH           2    0    0    0    0
 CREATURE:FISH_LUNGFISH                     49 561 -01 FISH           2    0    0   60    0
 CREATURE:FISH_LOACH_CLOWN                  49 562 -01 FISH           1    0   15   60    0
CREATURE:FISH_BULLHEAD_BROWN               49 563 -01 FISH           3    0    1    0    0
CREATURE:FISH_BULLHEAD_YELLOW              49 564 -01 FISH           1    0    8    0    0
CREATURE:FISH_BULLHEAD_BLACK               49 565 -01 FISH           4    0    0    0    0
CREATURE:FISH_KNIFEFISH_BANDED             49 566 -01 FISH           5    0    0   45    0
CREATURE:FISH_CHAR                         49 567 -01 FISH           2    0    9    0    0
CREATURE:FISH_TROUT_RAINBOW                49 568 -01 FISH           1    0    5    0    0
CREATURE:FISH_MOLLY_SAILFIN                49 569 -01 FISH           2    0    0    0    0
 CREATURE:FISH_GUPPY                        49 570 -01 FISH           1    0   17   40    0
CREATURE:FISH_PERCH                        49 571 -01 FISH           4    0   16    0    0
CREATURE:FISH_CAVE                         49 617 -01 FISH           2    0    6    0    0
CREATURE:LOBSTER_CAVE                      49 619 -01 FISH           1    0    7    0    0

PLANT:BAMBARA_GROUNDNUT:SEED               53 422 036 SEEDS          1    0    0    0    0
 PLANT:COWPEA:SEED                          53 422 048 SEEDS          1    0    0    0    0
PLANT:MUNG_BEAN:SEED                       53 422 057 SEEDS          1    0    0    0    0
PLANT:SINGLE-GRAIN_WHEAT:SEED              53 423 000 SEEDS          1    0    0    0    0
 PLANT:SOFT_WHEAT:SEED                      53 423 002 SEEDS          1    0    0    0    0
PLANT:HARD_WHEAT:SEED                      53 423 003 SEEDS          1    0    0    0    0
PLANT:EGGPLANT:SEED                        53 423 050 SEEDS          1    0    0    0    0
 PLANT:GARLIC:SEED                          53 423 052 SEEDS          1    0    0    0    0
PLANT:ACACIA:SEED                          53 423 200 SEEDS          1    0    0    0    0
PLANT:BUCKWHEAT:SEED                       53 424 006 SEEDS          1    0    0    0    0

PLANT:ASPARAGUS:STRUCTURAL                 54 419 035 PLANT          4    0    0   60    0
PLANT:BEET:STRUCTURAL                      54 419 039 PLANT          1    0    0    0    0
 PLANT:GARDEN_CRESS:STRUCTURAL              54 419 051 PLANT          2    0    0   15    0
 PLANT:LETTUCE:STRUCTURAL                   54 419 056 PLANT          3    0    0   30    0
 PLANT:RHUBARB:STRUCTURAL                   54 419 067 PLANT          2    0    3   40    0
PLANT:BERRY_SUN:STRUCTURAL                 54 419 192 PLANT          2    0    0    0    0

 PLANT:BITTER_MELON:LEAF                    56 421 040 PLANT_GROWTH   1    0    0   35    0
 PLANT:BLOOD_AMARANTH:LEAF                  56 422 017 PLANT_GROWTH   1    0    0   20    0
PLANT:CUCUMBER:FRUIT                       56 422 049 PLANT_GROWTH   1    0    0    0    0
PLANT:FEATHER:EGG                          56 422 213 PLANT_GROWTH   1    0    0    0    0   ??? !!!

CREATURE:HONEY_BEE:MEAD                    69 022 215 DRINK          3    0    0    0    0   !!!
PLANT:SINGLE-GRAIN_WHEAT:DRINK             69 420 000 DRINK          1    0    0    0    0
 PLANT:SOFT_WHEAT:DRINK                     69 420 002 DRINK          2    0    0   25    0
PLANT:HARD_WHEAT:DRINK                     69 420 003 DRINK          3    0    0    0    0
 PLANT:SPELT:DRINK                          69 420 004 DRINK          2    0   81    0    0
PLANT:BUCKWHEAT:DRINK                      69 420 006 DRINK          2    0    0    0    0
PLANT:KANIWA:DRINK                         69 420 014 DRINK          2    0    0    0    0
 PLANT:FONIO:DRINK                          69 420 025 DRINK          1    0    0   75    0
PLANT:TEFF:DRINK                           69 420 026 DRINK          5    0    0    0    0
PLANT:ARTICHOKE:DRINK                      69 420 034 DRINK          3    0   31    0    0
PLANT:BEET:DRINK                           69 420 039 DRINK          5    0    0    0    0
PLANT:TOMATO:DRINK                         69 420 073 DRINK          2    0    0    0    0
PLANT:TURNIP:DRINK                         69 420 075 DRINK          6    0    0   25    0
PLANT:SLIVER_BARB:DRINK                    69 420 191 DRINK          3    0    0    0    0
PLANT:BERRY_SUN:DRINK                      69 420 192 DRINK          5    0    0    0    0
PLANT:CARAMBOLA:DRINK                      69 421 134 DRINK          2    0    0    0    0
PLANT:DURIAN:DRINK                         69 421 137 DRINK          4    0    1    0    0
PLANT:LYCHEE:DRINK                         69 421 155 DRINK          5    0    0    0    0
PLANT:MANGO:DRINK                          69 424 221 DRINK          4    0    0    0    0

PLANT:SINGLE-GRAIN_WHEAT:MILL              70 421 000 POWDER_MISC    3    0    0    0    0
PLANT:TWO-GRAIN_WHEAT:MILL                 70 421 001 POWDER_MISC    1    0    0    0    0
PLANT:HARD_WHEAT:MILL                      70 421 003 POWDER_MISC    1    0    0    0    0
PLANT:BUCKWHEAT:MILL                       70 421 006 POWDER_MISC    1    0    0    0    0
PLANT:TEFF:MILL                            70 421 026 POWDER_MISC    1    0    0    0    0
 PLANT:FLAX:MILL                            70 422 027 POWDER_MISC    3    0    0   10    0

CREATURE:MAGGOT_PURRING:CHEESE             71 042 625 CHEESE         2    0    0    0    0
CREATURE:LLAMA:CHEESE                      71 046 186 CHEESE         1    0    5   45    0
CREATURE:CAMEL_1_HUMP:CHEESE               71 046 363 CHEESE         1    0    6    0    0
CREATURE:GIANT_CAMEL_1_HUMP:CHEESE         71 046 365 CHEESE         2    0    0    0    0
CREATURE:GIANT_KANGAROO:CHEESE             71 046 646 CHEESE         1    0    0    0    0
CREATURE:TAPIR:CHEESE                      71 046 749 CHEESE         3    0    0   30    0
CREATURE:GIANT_TAPIR:CHEESE                71 046 751 CHEESE         2    0    0    0    0
CREATURE:DONKEY:CHEESE                     71 047 173 CHEESE         2    0   13   50    0
CREATURE:WATER_BUFFALO:CHEESE              71 048 182 CHEESE         1    0   13   35    0
CREATURE:YAK:CHEESE                        71 048 185 CHEESE         1    0    0   85    0

CREATURE:BUMBLEBEE:ROYAL_JELLY             73 020 216 LIQUID_MISC    1    0    0    0    0

CREATURE:MAGGOT_PURRING:MILK               73 041 625 LIQUID_MISC    2    0    0    0    0
 CREATURE:LLAMA:MILK                        73 045 186 LIQUID_MISC    1    0    0   10    0
 CREATURE:CAMEL_2_HUMP:MILK                 73 045 366 LIQUID_MISC    1    0    0   20    0
CREATURE:GIANT_CAMEL_2_HUMP:MILK           73 045 368 LIQUID_MISC    1    0    0    0    0
CREATURE:KANGAROO:MILK                     73 045 644 LIQUID_MISC    2    0    0    0    0
 CREATURE:TAPIR:MILK                        73 045 749 LIQUID_MISC    2    0    0    0    0
 CREATURE:PIG:MILK                          73 046 177 LIQUID_MISC    3    0   10   10    0
 CREATURE:COW:MILK                          73 047 175 LIQUID_MISC    1    0    0    0    0

 PLANT:FLAX:OIL                             73 420 027 LIQUID_MISC    3    0    0    0    0
PLANT:HEMP:OIL                             73 420 029 LIQUID_MISC    1    0    0    0    0
PLANT:COTTON:OIL                           73 420 030 LIQUID_MISC    1    0    0    0    0
PLANT:KENAF:OIL                            73 420 032 LIQUID_MISC    2    0    0    0    0
PLANT:BUSH_QUARRY:OIL                      73 420 177 LIQUID_MISC    1    0    0    0    0
PLANT:POD_SWEET:EXTRACT                    73 422 176 LIQUID_MISC    1    0  120    0    0


]==]
