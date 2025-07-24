
local utils = require('utils')

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
    if item_type == df.item_type.FISH then		-- TODO :isCasteMaterial()x
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

    ip.key =		ip.key		or ip_key(item_type, type, index)	-- TODO ensure_key()
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
	    purchase_it = (ip.ingredient + ip.purchasing < 50)  -- TODO tune
	else
	    purchase_it = (ip.ingredient + ip.purchasing < 20)	-- TODO tune
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


local function isPreferenceFor(item)
   local ip, idx = get_ip_by_item(ingredient_preferences, item)
   return (ip ~= nil and ip.units ~= 0)
end


collect_ingredient_preferences()
collect_ingredient_counts()
purge_ip_by_cmpfn(ingredient_preferences, function(ip) return (ip.units == 0); end)
--purge_ip_by_cmpfn(ingredient_preferences, function(ip) return (ip.trader == 0); end)
--purge_ip_by_cmpfn(ingredient_preferences, function(ip) return (ip.ingredient >= 30); end)
purge_ip_by_cmpfn(ingredient_preferences, function(ip) return(ip.meals>=ip.units*5); end)
mark_for_purchase()
purge_ip_by_cmpfn(ingredient_preferences, function(ip) return (ip.purchasing == 0); end)
--purge_ip_by_cmpfn(ingredient_preferences, function(ip) return(ip.meals>=ip.units*5 or ip.ingredient==0); end)
--purge_ip_by_cmpfn(ingredient_preferences, function(ip) return(ip.meals>=ip.units*5 or ip.ingredient~=0); end)


local function print_ingredient_preferences()
    for _, ip in ipairs(ingredient_preferences) do print_ingredient_preference(ip); end
end


local function print_to_clipboard(...)	-- params as you would pass to pcall() or curry()
    local capture = {}

    local function captureprint(...)
	local line = {}
	local nextindent = 0
	for i,p in ipairs({...}) do
	    p = tostring(p)
	    p, nextindent = (' '):rep(nextindent) .. p , 8-(p:len()%8)
	    table.insert(line,p)
	end
	table.insert(line,NEWLINE)
	table.insert(capture, table.concat(line))
    end

    local oldprint = print
    print = captureprint
    local success, msg = pcall(...)
    print = oldprint
    if not success then dfhack.error(msg); end
    dfhack.internal.setClipboardTextCp437Multiline(table.concat(capture))
end


if (false) then
    function ptest(...)
	print(1,2,3)
	print(4,'','',5, '')
	print(6,77,888,9999,11111,222222,3333333,44444444,555555555)
	print(...)
    end
    print_to_clipboard(ptest,'A','BB','CCC','DDDD')
    do return; end
end
--[[
1       2       3
4                       5       
6       77      888     9999    11111   222222  3333333 44444444        555555555
A       BB      CCC     DDDD
]]


if (false) then  -- print to clipboard
    print_to_clipboard(print_ingredient_preferences)
end

if (false) then  -- print to console
    print_ingredient_preferences()
end

print('done')


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
rome of oxtrot — 4/15/25, 10:52 PM
https://discord.com/channels/793331351645323264/873014631315148840/1361942363458768906
it arguably creates more of an incentive to try to have meals that satisfy individual dwarf 
preferences, although the micro required for that is _insane_ especially since we've had 
very little lck manipulating PrepareMeal jobs (at least last i heard)

( 5/7/25 on immortal-cravings and forcing eat jobs.)
amade — 5/7/25, 1:17 AM
https://discord.com/channels/793331351645323264/873014631315148840/1369588977555865662
Interesting…I just noticed that goblin monster slayers eat by tasking the whole stack of 
meals to eat (via `immortal-cravings`) instead of taking one meal out of the stack like 
other citizens/residents. They still only consume one meal out of the whole stack though.

( 5/15/25 on food selection and fort design.)
Saint — 5/15/25, 6:16 AM
https://discord.com/channels/793331351645323264/873014631315148840/1372563194433769674
Also why are my dwarves eating raw berries when I have over 150 lavish meals?
(later in that discussion)
amade — 5/15/25, 7:04 AM
I did some tests, and it appears that if your meals aren't high value enough, they'll 
go for whatever is closest.  With high value meals, they'll skip any raw food that are 
closer and go for the meals.
And of course, they will go for preferred food if available, but not all the time.
*this was for short distances, with a difference of only a few tiles between the raw 
food and prepared meals; I didn't test to see how far is too far.
Quietust — 5/15/25, 3:03 PM
When choosing meals, the "score" for a given food item starts at its distance (calculated 
as `max(dx,dy,dz)`) - if it matches a Preference, it cuts the score in half and subtracts 
30, and if it's recently-eaten (or is a live Vermin) it quadruples the score and adds 100. 
The item with the lowest score wins.
If dwarves are preferring berries over prepared meals despite them being further away, 
then those dwarves probably prefer to eat those berries.
Quietust — 5/15/25, 3:07 PM
And something I recently discovered: if your meals only contain one single unique ingredient 
(e.g. a cow meat roast consisting of well-minced cow meat, finely-minced cow meat, 
well-minced cow meat, and well-minced cow meat), then dwarves will treat them as if they 
were **just** that ingredient (e.g. they'll behave as if it's just an ordinary piece of cow 
meat) and will get tired of eating them.

--]==]


--[==[

? +cabbage seeds, +sorghum seeds, -teff seeds, -lentils, -leek seeds, +garlic seeds

CREATURE:GILA_MONSTER:MUSCLE               48 020 167 MEAT           1    0    0    0    0
CREATURE:FISH_COELACANTH:MUSCLE            48 020 248 MEAT           1    0   11    0    0
CREATURE:FISH_COD:MUSCLE                   48 020 252 MEAT           1    0    0    0    0
CREATURE:FISH_GROUPER_GIANT:MUSCLE         48 020 254 MEAT           1    0    0    0    0
CREATURE:FISH_TIGERFISH:MUSCLE             48 020 270 MEAT           1    0    0    0    0
CREATURE:FISH_PIKE:MUSCLE                  48 020 271 MEAT           1    0    0    0    0
CREATURE:GIANT_ALLIGATOR:MUSCLE            48 020 304 MEAT           1    0    0    0    0
CREATURE:GIANT_ANOLE:MUSCLE                48 020 490 MEAT           1    0    0    0    0
CREATURE:GIANT_POND_TURTLE:MUSCLE          48 020 516 MEAT           1    0    0    0    0
CREATURE:FISH_HERRING:MUSCLE               48 020 546 MEAT           1    0    0    0    0
CREATURE:FISH_FLOUNDER:MUSCLE              48 020 555 MEAT           2    0    0    0    0
CREATURE:FISH_LUNGFISH:MUSCLE              48 020 561 MEAT           1    0    0    0    0
CREATURE:FISH_BULLHEAD_BROWN:MUSCLE        48 020 563 MEAT           1    0    0    0    0
CREATURE:FISH_BULLHEAD_YELLOW:MUSCLE       48 020 564 MEAT           3    0    0    0    0
CREATURE:FISH_CHAR:MUSCLE                  48 020 567 MEAT           1    0    0    0    0
CREATURE:FISH_PERCH:MUSCLE                 48 020 571 MEAT           1    0    0    0    0
CREATURE:MONITOR_LIZARD:MUSCLE             48 020 710 MEAT           1    0    3    0    0
CREATURE:BIRD_CARDINAL:MUSCLE              48 021 008 MEAT           1    0    0    0    0
CREATURE:BIRD_GRACKLE:MUSCLE               48 021 011 MEAT           1    0    0    0    0
CREATURE:BIRD_RW_BLACKBIRD:MUSCLE          48 021 017 MEAT           1    0    0    0    0
CREATURE:BIRD_FALCON_PEREGRINE:MUSCLE      48 021 025 MEAT           1    0    0    0    0
CREATURE:GIANT_SNOWY_OWL:MUSCLE            48 021 048 MEAT           1    0    0    0    0
CREATURE:BIRD_LORIKEET:MUSCLE              48 021 076 MEAT           2    0    0    0    0
CREATURE:GIANT_EAGLE:MUSCLE                48 021 108 MEAT           1    0    0    0    0
CREATURE:BIRD_HORNBILL:MUSCLE              48 021 109 MEAT           1    0    2    0    0
CREATURE:GIANT_MASKED_LOVEBIRD:MUSCLE      48 021 114 MEAT           1    0    0    0    0
CREATURE:MANTIS:MUSCLE                     48 021 130 MEAT           1    0    0    0    0
CREATURE:THRIPS:MUSCLE                     48 021 139 MEAT           1    0    0    0    0
CREATURE:DONKEY:MUSCLE                     48 021 173 MEAT           1    0  123    0    0
CREATURE:PIG:MUSCLE                        48 021 177 MEAT           1    0   14    0    0
CREATURE:WATER_BUFFALO:MUSCLE              48 021 182 MEAT           1   74  106    0    0
CREATURE:BIRD_GOOSE:MUSCLE                 48 021 184 MEAT           1    0    4    0    0
CREATURE:GIANT_BUTTERFLY_MONARCH:MUSCLE    48 021 208 MEAT           2    0    0    0    0
CREATURE:GIANT_DRAGONFLY:MUSCLE            48 021 214 MEAT           1    0    0    0    0
CREATURE:WALRUS:MUSCLE                     48 021 225 MEAT           1    0    0    0    0
CREATURE:SHARK_NURSE:MUSCLE                48 021 235 MEAT           1    0    3    0    0
CREATURE:SHARK_BLUE:MUSCLE                 48 021 242 MEAT           2    0    0    0    0
CREATURE:SHARK_ANGEL:MUSCLE                48 021 244 MEAT           1    0    0    0    0
CREATURE:NARWHAL:MUSCLE                    48 021 262 MEAT           1    0    0    0    0
CREATURE:GIANT_BEAR_BLACK:MUSCLE           48 021 280 MEAT           2   21    0    0    0
CREATURE:RACCOON:MUSCLE                    48 021 287 MEAT           1    0    0    0    0
CREATURE:GIANT_RACCOON:MUSCLE              48 021 289 MEAT           1    0    0    0    0
CREATURE:BADGER:MUSCLE                     48 021 314 MEAT           1    0    7    0    0
CREATURE:MOOSE, GIANT:MUSCLE               48 021 319 MEAT           1    0    0    0    0
CREATURE:ELEPHANT:MUSCLE                   48 021 323 MEAT           1    0  111    0    0
CREATURE:JAGUAR:MUSCLE                     48 021 335 MEAT           1    0    0    0    0
CREATURE:ORANGUTAN:MUSCLE                  48 021 353 MEAT           1    0    0    0    0
CREATURE:GIBBON_BLACK_HANDED:MUSCLE        48 021 356 MEAT           1    0    3    0    0
CREATURE:BIRD_VULTURE:MUSCLE               48 021 372 MEAT           1    0    3    0    0
CREATURE:GIANT_RHINOCEROS:MUSCLE           48 021 377 MEAT           1    0    0    0    0
CREATURE:ARMADILLO:MUSCLE                  48 021 387 MEAT           1    0    0    0    0
CREATURE:BEAR_POLAR:MUSCLE                 48 021 396 MEAT           1    0    0    0    0
CREATURE:WOLVERINE:MUSCLE                  48 021 399 MEAT           1    0    0    0    0
CREATURE:CHINCHILLA:MUSCLE                 48 021 402 MEAT           1    0    0    0    0
CREATURE:DRUNIAN:MUSCLE                    48 021 406 MEAT           1    0    3    0    0
CREATURE:CREEPING_EYE:MUSCLE               48 021 407 MEAT           1    0    0    0    0
CREATURE:MAGMA_CRAB:MUSCLE                 48 021 411 MEAT           1    0    0    0    0
CREATURE:RUTHERER:MUSCLE                   48 021 418 MEAT           1    0    4    0    0
CREATURE:BLIND_CAVE_BEAR:MUSCLE            48 021 428 MEAT           1    0    0    0    0
CREATURE:GIANT_OCTOPUS:MUSCLE              48 021 439 MEAT           1    0    0    0    0
CREATURE:CRAB:MUSCLE                       48 021 440 MEAT           1    0    3    0    0
CREATURE:GIANT_SPERM_WHALE:MUSCLE          48 021 460 MEAT           1    0    0    0    0
CREATURE:GIANT_HARP_SEAL:MUSCLE            48 021 466 MEAT           1    0    0    0    0
CREATURE:FOXSQUIRREL:MUSCLE                48 021 470 MEAT           2    0    0    0    0
CREATURE:GIANT_MINK:MUSCLE                 48 021 513 MEAT           1    0    0    0    0
CREATURE:RAT:MUSCLE                        48 021 517 MEAT           1    0    0    0    0
CREATURE:GIANT_FLYING_SQUIRREL:MUSCLE      48 021 536 MEAT           1    0    0    0    0
CREATURE:FISH_LAMPREY_BROOK:MUSCLE         48 021 542 MEAT           1    0    0    0    0
CREATURE:FISH_RAY_BAT:MUSCLE               48 021 543 MEAT           1    0    0    0    0
CREATURE:JELLYFISH_SEA_NETTLE:MUSCLE       48 021 557 MEAT           1    0    0    0    0
CREATURE:TOAD_GIANT_CAVE:MUSCLE            48 021 606 MEAT           1    0    0    0    0
CREATURE:OLM_GIANT:MUSCLE                  48 021 607 MEAT           1    0    4    0    0
CREATURE:IMP_FIRE:MUSCLE                   48 021 614 MEAT           1    0    0    0    0
CREATURE:OLM:MUSCLE                        48 021 621 MEAT           1    0    0    0    0
CREATURE:COYOTE:MUSCLE                     48 021 641 MEAT           1    0   11    0    0
CREATURE:GIANT_KANGAROO:MUSCLE             48 021 646 MEAT           1    0    3    0    0
CREATURE:GIANT_KOALA:MUSCLE                48 021 649 MEAT           1    0    0    0    0
CREATURE:BOBCAT:MUSCLE                     48 021 665 MEAT           1    0   18    0    0
CREATURE:GIANT_DINGO:MUSCLE                48 021 694 MEAT           1    0    0    0    0
CREATURE:HYENA:MUSCLE                      48 021 704 MEAT           1   60    2    0    0
CREATURE:GIANT_HYENA:MUSCLE                48 021 706 MEAT           3    0    0    0    0
CREATURE:LION_TAMARIN:MUSCLE               48 021 758 MEAT           1    0    0    0    0
CREATURE:GIANT_LION_TAMARIN:MUSCLE         48 021 760 MEAT           1    0    0    0    0
CREATURE:STOAT:MUSCLE                      48 021 761 MEAT           1    0    0    0    0
CREATURE:SPIDER_CAVE_GIANT:MUSCLE          48 022 615 MEAT           1    0    2    0    0
CREATURE:ANT:MUSCLE                        48 024 205 MEAT           1    0    0    0    0
CREATURE:CUTTLEFISH                        49 446 -01 FISH           1    0   12    0    0
CREATURE:NAUTILUS                          49 467 -01 FISH           4    0    2    0    0
CREATURE:MOGHOPPER                         49 471 -01 FISH           2    0    0    0    0
CREATURE:MUSSEL                            49 537 -01 FISH           2    0   14    0    0
CREATURE:OYSTER                            49 538 -01 FISH           2    0   15    0    0
CREATURE:FISH_SALMON                       49 539 -01 FISH           2    0    9    0    0
CREATURE:FISH_HAGFISH                      49 541 -01 FISH           1    0    0    0    0
CREATURE:FISH_LAMPREY_BROOK                49 542 -01 FISH           3    0   11    0    0
CREATURE:FISH_HERRING                      49 546 -01 FISH           1    0    8    0    0
CREATURE:FISH_SHAD                         49 547 -01 FISH           2    0    0    0    0
CREATURE:FISH_ANCHOVY                      49 548 -01 FISH           3    0    0    0    0
CREATURE:FISH_TROUT_STEELHEAD              49 549 -01 FISH           4    0    0    0    0
CREATURE:FISH_HAKE                         49 550 -01 FISH           2    0    0    0    0
CREATURE:FISH_SEAHORSE                     49 551 -01 FISH           2    0    9    0    0
CREATURE:FISH_GLASSEYE                     49 552 -01 FISH           2    0    0    0    0
CREATURE:FISH_PUFFER_WHITE_SPOTTED         49 553 -01 FISH           1    0   14    0    0
CREATURE:FISH_SOLE                         49 554 -01 FISH           2    0    0    0    0
CREATURE:FISH_FLOUNDER                     49 555 -01 FISH           1    0    0    0    0
CREATURE:SQUID                             49 558 -01 FISH           2    0    6    0    0
CREATURE:FISH_LUNGFISH                     49 561 -01 FISH           2    0    8    0    0
CREATURE:FISH_LOACH_CLOWN                  49 562 -01 FISH           1    0   17    0    0
CREATURE:FISH_BULLHEAD_BROWN               49 563 -01 FISH           3    0   10    0    0
CREATURE:FISH_BULLHEAD_YELLOW              49 564 -01 FISH           1    0   16    0    0
CREATURE:FISH_BULLHEAD_BLACK               49 565 -01 FISH           3    0   11    0    0
CREATURE:FISH_KNIFEFISH_BANDED             49 566 -01 FISH           5    0    0    0    0
CREATURE:FISH_CHAR                         49 567 -01 FISH           2    0   12    0    0
CREATURE:FISH_TROUT_RAINBOW                49 568 -01 FISH           1    0   15    0    0
CREATURE:FISH_MOLLY_SAILFIN                49 569 -01 FISH           2    0   16    0    0
CREATURE:FISH_PERCH                        49 571 -01 FISH           4    0    7    0    0
CREATURE:FISH_CAVE                         49 617 -01 FISH           2    0   16    0    0
CREATURE:LOBSTER_CAVE                      49 619 -01 FISH           1    0    5    0    0
PLANT:WEED_RAT:SEED                        53 421 185 SEEDS          1    0  100    0    0
PLANT:BERRIES_FISHER:SEED                  53 421 186 SEEDS          1    0  100    0    0
PLANT:BAMBARA_GROUNDNUT:SEED               53 422 036 SEEDS          1    0    0    0    0
PLANT:COWPEA:SEED                          53 422 048 SEEDS          2    0    0    0    0
PLANT:MUNG_BEAN:SEED                       53 422 057 SEEDS          1    0    0    0    0
PLANT:RED_BEAN:SEED                        53 422 066 SEEDS          1    0    0    0    0
PLANT:SOYBEAN:SEED                         53 422 068 SEEDS          1    0   18    0    0
PLANT:GINKGO:SEED                          53 422 164 SEEDS          1    0   30  115    0
PLANT:MUSHROOM_HELMET_PLUMP:SEED           53 422 173 SEEDS          1    0  100    0    0
PLANT:SINGLE-GRAIN_WHEAT:SEED              53 423 000 SEEDS          1    0    0    0    0
PLANT:SOFT_WHEAT:SEED                      53 423 002 SEEDS          1    0    0    0    0
PLANT:HARD_WHEAT:SEED                      53 423 003 SEEDS          1    0    0    0    0
PLANT:BARLEY:SEED                          53 423 005 SEEDS          2    0   75    0    0
PLANT:RICE:SEED                            53 423 011 SEEDS          1    0  100    0    0
PLANT:MAIZE:SEED                           53 423 012 SEEDS          1    0  100    0    0
PLANT:PURPLE_AMARANTH:SEED                 53 423 018 SEEDS          2    0   87    0    0
PLANT:FINGER_MILLET:SEED                   53 423 023 SEEDS          1    0  100    0    0
PLANT:WILD_CARROT:SEED                     53 423 043 SEEDS          1    0  100    0    0
PLANT:EGGPLANT:SEED                        53 423 050 SEEDS          1    0    0    0    0
PLANT:GARLIC:SEED                          53 423 052 SEEDS          1    0    0    0    0
PLANT:ACACIA:SEED                          53 423 200 SEEDS          1    0    0    0    0
PLANT:BUCKWHEAT:SEED                       53 424 006 SEEDS          2    0    0    0    0
PLANT:SORGHUM:SEED                         53 424 010 SEEDS          1    0   19    0    0
PLANT:ALFALFA:STRUCTURAL                   54 419 008 PLANT          2    0    6    0    0
PLANT:ASPARAGUS:STRUCTURAL                 54 419 035 PLANT          4    0    3    0    0
PLANT:BEET:STRUCTURAL                      54 419 039 PLANT          1    0    0    0    0
PLANT:WILD_CARROT:STRUCTURAL               54 419 043 PLANT          2    0    8    0    0
PLANT:CELERY:STRUCTURAL                    54 419 045 PLANT          1   60    5    0    0
PLANT:CHICORY:STRUCTURAL                   54 419 047 PLANT          1    0    4    0    0
PLANT:GARDEN_CRESS:STRUCTURAL              54 419 051 PLANT          2    0    6    0    0
PLANT:LEEK:STRUCTURAL                      54 419 054 PLANT          2    0    6    0    0
PLANT:LETTUCE:STRUCTURAL                   54 419 056 PLANT          3    0    0    0    0
PLANT:POTATO:STRUCTURAL                    54 419 064 PLANT          2    0   45    0    0
PLANT:RADISH:STRUCTURAL                    54 419 065 PLANT          1    0   10    0    0
PLANT:RHUBARB:STRUCTURAL                   54 419 067 PLANT          2    0   15    0    0
PLANT:SWEET_POTATO:STRUCTURAL              54 419 071 PLANT          1    0   34    0    0
PLANT:LONG_YAM:STRUCTURAL                  54 419 080 PLANT          2    0    0    0    0
PLANT:MUSHROOM_HELMET_PLUMP:STRUCTURAL     54 419 173 PLANT          3    0  132    0    0
PLANT:BERRIES_PRICKLE:STRUCTURAL           54 419 181 PLANT          2    0   68    0    0
PLANT:BERRIES_STRAW:STRUCTURAL             54 419 182 PLANT          1    0  111    0    0
PLANT:BERRY_SUN:STRUCTURAL                 54 419 192 PLANT          2    0    0    0    0
PLANT:BERRIES_STRAW:FRUIT                  56 420 182 PLANT_GROWTH   1    0   84    0    0
PLANT:BITTER_MELON:LEAF                    56 421 040 PLANT_GROWTH   1    0   13    0    0
PLANT:CAPER:BUD                            56 421 042 PLANT_GROWTH   1    0   17    0    0
PLANT:BITTER_MELON:FRUIT                   56 422 040 PLANT_GROWTH   2    0    0    0    0
PLANT:CUCUMBER:FRUIT                       56 422 049 PLANT_GROWTH   1    0    0    0    0
PLANT:SAGUARO:FRUIT                        56 422 195 PLANT_GROWTH   1    0   32  265    0
PLANT:FEATHER:EGG                          56 422 213 PLANT_GROWTH   1    0    0    0    0
PLANT:PALM:NUT                             56 422 224 PLANT_GROWTH   1    0   33  285    0
PLANT:CRANBERRY:FRUIT                      56 423 085 PLANT_GROWTH   2    0   26    0    0
PLANT:LIME:FRUIT                           56 423 144 PLANT_GROWTH   1    0   33  270    0
PLANT:CITRON:FRUIT                         56 423 146 PLANT_GROWTH   1    0   54   25    0
PLANT:BITTER_ORANGE:FRUIT                  56 423 148 PLANT_GROWTH   1    0   43  255    0
PLANT:FINGER_LIME:FRUIT                    56 423 149 PLANT_GROWTH   1    0   44  140    0
PLANT:ROUND_LIME:FRUIT                     56 423 150 PLANT_GROWTH   2    0   54  180    0
PLANT:KUMQUAT:FRUIT                        56 423 152 PLANT_GROWTH   1    0   99  300    0
PLANT:DURIAN:FRUIT                         56 424 137 PLANT_GROWTH   1    0   87   65    0
PLANT:POMEGRANATE:FRUIT                    56 424 158 PLANT_GROWTH   1    0   88   45    0
PLANT:APRICOT:FRUIT                        56 424 161 PLANT_GROWTH   2    0   73  485    0
PLANT:CHERRY:FRUIT                         56 424 163 PLANT_GROWTH   2    0   91  700    0
PLANT:PEACH:FRUIT                          56 424 166 PLANT_GROWTH   1    0   96  630    0
PLANT:SAND_PEAR:FRUIT                      56 424 171 PLANT_GROWTH   2    0  109  660    0
PLANT:OLIVE:FRUIT                          56 425 157 PLANT_GROWTH   1    0   91  310    0
CREATURE:HONEY_BEE:MEAD                    69 022 215 DRINK          3    0    0    0    0
PLANT:SINGLE-GRAIN_WHEAT:DRINK             69 420 000 DRINK          1    0    0    0    0
PLANT:TWO-GRAIN_WHEAT:DRINK                69 420 001 DRINK          2    0    0    0    0
PLANT:SOFT_WHEAT:DRINK                     69 420 002 DRINK          2    0    0    0    0
PLANT:HARD_WHEAT:DRINK                     69 420 003 DRINK          3    0    0    0    0
PLANT:SPELT:DRINK                          69 420 004 DRINK          3    0   68    0    0
PLANT:BARLEY:DRINK                         69 420 005 DRINK          2    0    3    0    0
PLANT:BUCKWHEAT:DRINK                      69 420 006 DRINK          2    0    0    0    0
PLANT:RYE:DRINK                            69 420 009 DRINK          1    0   10    0    0
PLANT:SORGHUM:DRINK                        69 420 010 DRINK          3    0    0    0    0
PLANT:MAIZE:DRINK                          69 420 012 DRINK          6    0   30    0    0
PLANT:QUINOA:DRINK                         69 420 013 DRINK          1    0    0    0    0
PLANT:KANIWA:DRINK                         69 420 014 DRINK          2    0    0    0    0
PLANT:PENDANT_AMARANTH:DRINK               69 420 016 DRINK          1    0    1    0    0
PLANT:BLOOD_AMARANTH:DRINK                 69 420 017 DRINK          3    0   36    0    0
PLANT:PURPLE_AMARANTH:DRINK                69 420 018 DRINK          4    0   37    0    0
PLANT:PEARL_MILLET:DRINK                   69 420 021 DRINK          3    0    1    0    0
PLANT:WHITE_MILLET:DRINK                   69 420 022 DRINK          1    0   40    0    0
PLANT:FINGER_MILLET:DRINK                  69 420 023 DRINK          3    0   36    0    0
PLANT:FOXTAIL_MILLET:DRINK                 69 420 024 DRINK          5    0   34    0    0
PLANT:FONIO:DRINK                          69 420 025 DRINK          2    0   14    0    0
PLANT:TEFF:DRINK                           69 420 026 DRINK          5    0    0    0    0
PLANT:ARTICHOKE:DRINK                      69 420 034 DRINK          3    0   37    0    0
PLANT:BEET:DRINK                           69 420 039 DRINK          4    0    0    0    0
PLANT:WILD_CARROT:DRINK                    69 420 043 DRINK          2    0   15    0    0
PLANT:CASSAVA:DRINK                        69 420 044 DRINK          4    0   34    0    0
PLANT:PARSNIP:DRINK                        69 420 060 DRINK          2    0   10    0    0
PLANT:POTATO:DRINK                         69 420 064 DRINK          2   60   17    0    0
PLANT:RADISH:DRINK                         69 420 065 DRINK          3    0   29    0    0
PLANT:SWEET_POTATO:DRINK                   69 420 071 DRINK          4    0   53    0    0
PLANT:TOMATO:DRINK                         69 420 073 DRINK          2    0    0    0    0
PLANT:TOMATILLO:DRINK                      69 420 074 DRINK          3    0   34    0    0
PLANT:TURNIP:DRINK                         69 420 075 DRINK          6    0    0    0    0
PLANT:PASSION_FRUIT:DRINK                  69 420 083 DRINK          1    0   72    0    0
PLANT:GRAPE:DRINK                          69 420 084 DRINK          3    0   32    0    0
PLANT:CRANBERRY:DRINK                      69 420 085 DRINK          6    0    6    0    0
PLANT:BILBERRY:DRINK                       69 420 086 DRINK          1    0   40    0    0
PLANT:BLUEBERRY:DRINK                      69 420 087 DRINK          1    0   44    0    0
PLANT:BLACKBERRY:DRINK                     69 420 088 DRINK          1    0   99    0    0
PLANT:RASPBERRY:DRINK                      69 420 089 DRINK          3    0   34    0    0
PLANT:PINEAPPLE:DRINK                      69 420 090 DRINK          3    0   31    0    0
PLANT:GRASS_TAIL_PIG:DRINK                 69 420 174 DRINK          3    0   11    0    0
PLANT:GRASS_WHEAT_CAVE:DRINK               69 420 175 DRINK          1    0    0    0    0
PLANT:POD_SWEET:DRINK                      69 420 176 DRINK          2    0    7    0    0
PLANT:ROOT_MUCK:DRINK                      69 420 178 DRINK          3    0    4    0    0
PLANT:TUBER_BLOATED:DRINK                  69 420 179 DRINK          2    0   37    0    0
PLANT:GRASS_LONGLAND:DRINK                 69 420 183 DRINK          3    0    0    0    0
PLANT:WEED_RAT:DRINK                       69 420 185 DRINK          4    0    0    0    0
PLANT:BERRIES_FISHER:DRINK                 69 420 186 DRINK          3    0   57    0    0
PLANT:SLIVER_BARB:DRINK                    69 420 191 DRINK          3    0    0    0    0
PLANT:BERRY_SUN:DRINK                      69 420 192 DRINK          5    0    0    0    0
PLANT:VINE_WHIP:DRINK                      69 420 193 DRINK          1    0   40    0    0
PLANT:CARAMBOLA:DRINK                      69 421 134 DRINK          2    0    0    0    0
PLANT:DURIAN:DRINK                         69 421 137 DRINK          4    0    4    0    0
PLANT:GUAVA:DRINK                          69 421 138 DRINK          3    0    4    0    0
PLANT:RAMBUTAN:DRINK                       69 421 141 DRINK          1    0   37    0    0
PLANT:CUSTARD-APPLE:DRINK                  69 421 153 DRINK          8    0    1    0    0
PLANT:DATE_PALM:DRINK                      69 421 154 DRINK          5    0    1    0    0
PLANT:LYCHEE:DRINK                         69 421 155 DRINK          5    0   28    0    0
PLANT:POMEGRANATE:DRINK                    69 421 158 DRINK          3    0   23    0    0
PLANT:APPLE:DRINK                          69 421 160 DRINK          2    0   34    0    0
PLANT:APRICOT:DRINK                        69 421 161 DRINK          1    0   31    0    0
PLANT:BAYBERRY:DRINK                       69 421 162 DRINK          1    0   34    0    0
PLANT:CHERRY:DRINK                         69 421 163 DRINK          3   74    6    0    0
PLANT:PEAR:DRINK                           69 421 167 DRINK          2    0    0    0    0
PLANT:PERSIMMON:DRINK                      69 421 169 DRINK          3    0   27    0    0
PLANT:PLUM:DRINK                           69 421 170 DRINK          3    0   36    0    0
PLANT:SAND_PEAR:DRINK                      69 421 171 DRINK          2    0   10    0    0
PLANT:MUSHROOM_HELMET_PLUMP:DRINK          69 421 173 DRINK          2    0   11    0    0
PLANT:BERRIES_STRAW:DRINK                  69 421 182 DRINK          4    0   33    0    0
PLANT:MANGO:DRINK                          69 424 221 DRINK          4    0    0    0    0
PLANT:OATS:MILL                            70 420 007 POWDER_MISC    1    0    0    0    0
PLANT:SINGLE-GRAIN_WHEAT:MILL              70 421 000 POWDER_MISC    3    0    0    0    0
PLANT:TWO-GRAIN_WHEAT:MILL                 70 421 001 POWDER_MISC    1    0   10    0    0
PLANT:SOFT_WHEAT:MILL                      70 421 002 POWDER_MISC    1   21    0    0    0
PLANT:HARD_WHEAT:MILL                      70 421 003 POWDER_MISC    1    0    0    0    0
PLANT:SPELT:MILL                           70 421 004 POWDER_MISC    2    0    0    0    0
PLANT:BARLEY:MILL                          70 421 005 POWDER_MISC    2    0   21    0    0
PLANT:BUCKWHEAT:MILL                       70 421 006 POWDER_MISC    1    0    0    0    0
PLANT:RYE:MILL                             70 421 009 POWDER_MISC    1    0   23    0    0
PLANT:SORGHUM:MILL                         70 421 010 POWDER_MISC    2    0   10    0    0
PLANT:RICE:MILL                            70 421 011 POWDER_MISC    5    0    0    0    0
PLANT:PENDANT_AMARANTH:MILL                70 421 016 POWDER_MISC    1    0    0    0    0
PLANT:BLOOD_AMARANTH:MILL                  70 421 017 POWDER_MISC    1    0    0    0    0
PLANT:PURPLE_AMARANTH:MILL                 70 421 018 POWDER_MISC    1    0   10    0    0
PLANT:PEARL_MILLET:MILL                    70 421 021 POWDER_MISC    4    0    7    0    0
PLANT:WHITE_MILLET:MILL                    70 421 022 POWDER_MISC    1   74    0    0    0
PLANT:FINGER_MILLET:MILL                   70 421 023 POWDER_MISC    2    0   20    0    0
PLANT:TEFF:MILL                            70 421 026 POWDER_MISC    1    0    0    0    0
PLANT:GRASS_WHEAT_CAVE:MILL                70 421 175 POWDER_MISC    1    0   80    0    0
PLANT:POD_SWEET:MILL                       70 421 176 POWDER_MISC    1    0  110    0    0
PLANT:GRASS_LONGLAND:MILL                  70 421 183 POWDER_MISC    1    0   10    0    0
PLANT:FLAX:MILL                            70 422 027 POWDER_MISC    3    0   20    0    0
CREATURE:MAGGOT_PURRING:CHEESE             71 042 625 CHEESE         2    0    0    0    0
CREATURE:LLAMA:CHEESE                      71 046 186 CHEESE         1    0   19    0    0
CREATURE:CAMEL_1_HUMP:CHEESE               71 046 363 CHEESE         1    0   17    0    0
CREATURE:GIANT_CAMEL_1_HUMP:CHEESE         71 046 365 CHEESE         2    0    0    0    0
CREATURE:GIANT_KANGAROO:CHEESE             71 046 646 CHEESE         1    0   18    0    0
CREATURE:TAPIR:CHEESE                      71 046 749 CHEESE         3    0    9    0    0
CREATURE:GIANT_TAPIR:CHEESE                71 046 751 CHEESE         2    0    0    0    0
CREATURE:DONKEY:CHEESE                     71 047 173 CHEESE         2    0   15    0    0
CREATURE:COW:CHEESE                        71 048 175 CHEESE         1    0   15    0    0
CREATURE:GOAT:CHEESE                       71 048 178 CHEESE         3    0    2    0    0
CREATURE:WATER_BUFFALO:CHEESE              71 048 182 CHEESE         1    0   14    0    0
CREATURE:YAK:CHEESE                        71 048 185 CHEESE         1    0   16    0    0
CREATURE:BUMBLEBEE:ROYAL_JELLY             73 020 216 LIQUID_MISC    1    0    0    0    0
CREATURE:MAGGOT_PURRING:MILK               73 041 625 LIQUID_MISC    2    0   20    0    0
CREATURE:LLAMA:MILK                        73 045 186 LIQUID_MISC    1    0   20    0    0
CREATURE:CAMEL_2_HUMP:MILK                 73 045 366 LIQUID_MISC    1    0   20    0    0
CREATURE:GIANT_CAMEL_2_HUMP:MILK           73 045 368 LIQUID_MISC    1    0    0    0    0
CREATURE:KANGAROO:MILK                     73 045 644 LIQUID_MISC    2    0   20    0    0
CREATURE:GIANT_KANGAROO:MILK               73 045 646 LIQUID_MISC    3    0    0    0    0
CREATURE:TAPIR:MILK                        73 045 749 LIQUID_MISC    2    0    0    0    0
CREATURE:PIG:MILK                          73 046 177 LIQUID_MISC    3    0   30    0    0
CREATURE:COW:MILK                          73 047 175 LIQUID_MISC    1    0   20    0    0
CREATURE:GOAT:MILK                         73 047 178 LIQUID_MISC    1    0   20    0    0
CREATURE:REINDEER:MILK                     73 047 183 LIQUID_MISC    1   13    1    0    0
PLANT:FLAX:OIL                             73 420 027 LIQUID_MISC    3    0    0    0    0
PLANT:HEMP:OIL                             73 420 029 LIQUID_MISC    1    0    0    0    0
PLANT:COTTON:OIL                           73 420 030 LIQUID_MISC    1    0    0    0    0
PLANT:KENAF:OIL                            73 420 032 LIQUID_MISC    2    0    0    0    0
PLANT:BUSH_QUARRY:OIL                      73 420 177 LIQUID_MISC    1    0    0    0    0
PLANT:POD_SWEET:EXTRACT                    73 422 176 LIQUID_MISC    1    0  120    0    0
]==]

--[=[ copy-paste to Lua console: preload clipboard with desired drinks, this prints the associated fruits.
DM=dfhack.matinfo;IO=df.global.world.items.other
function P(mdef,c) print(string.format("%-25s  %d",DM.getToken(mdef),c));end
function M(item,mdef)return(mdef ~= nil and item.mat_type==mdef.type and item.mat_index==mdef.index);end
function Z(s)local m=DM.find(s);local c=0;for _,i in ipairs(IO.PLANT_GROWTH)do if M(i,m)and not i.flags.trader then c=c+i:getStackSize();end;end;P(m,c);end
for _,s in ipairs(dfhack.internal.getClipboardTextCp437Multiline())do s=s:trim():gsub("(PLANT:[%w%-_]+:%a+)%s+%d+%s+%d+.*","%1"):gsub(":DRINK",":FRUIT");Z(s);end
]=]

