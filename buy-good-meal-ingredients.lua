local debugging = true


local utils = require('utils')

-- note: unlike normal printf, this ends the line even if '\n' is not used.
local function printf(...)
    print(string.format(...))
end

-- This is basically debug-printf().
-- This function only outputs if a global or top-level local variable named 'debugging' is true.
-- If 'debugging' is true, this prints to the console (in bright cyan), and logs to the stderr.log file.
-- The debug library is used to find the function name (if possible).
--
_dprintf_current_script_name = _dprintf_current_script_name or dfhack.current_script_name():match( '([^/\\]*)$' ) or ''
local function dprintf(format, ...)
    if debugging ~= true then return; end
    local info = debug.getinfo(2, "nt")
            or { namewhat = "{no debug info}", name = "{no debug info}", istailcall = false, }
    info.name = info.name or ((info.istailcall) and "{tail call}" or "{no function}")
    local message = string.format("%s %s(): " .. format, _dprintf_current_script_name, info.name, ...)
    local oldcolor = dfhack.color(COLOR_LIGHTCYAN)
    print(message)
    dfhack.color(oldcolor)
    io.stderr:write(message):write('\n')
end


-- TODO I think this entire construct with all its functions would be better as an object.
--   TODO rewrite (at)type for correctness { key:string, item_type:df.item_type, material:integer, index: integer, name:string, units:integer, meals:integer, ingredient:integer, trader:integer, products:string[] }
-- TODO plantable, for seeds.  (whether or not resulting plant is edible, I think.)
--   array is sorted by key; key is a string made from item_type, material type, and material index.
-- this is getting too big; would it be better to have multiple tables, most of them dictionaries?
--
local ingredient_preferences = {}


local function ip_key(item_type, material, index)
--    dprintf("%02d %03d %03d", item_type, material, index)
    return string.format("%02d %03d %03d", item_type, material, index)
end


local function ip_key_by_item(item)
    local item_type = item:getType()
    if item_type == df.item_type.FISH then
	return ip_key(item_type, item:getRace(), -1)
    elseif dfhack.items.isCasteMaterial(item_type) then
	error("can't deal with this caste food: item " .. item.id)
    else
	return ip_key(item_type, item:getMaterial(), item:getMaterialIndex())
    end
end


local function get_ip(ip_list, item_type, material, index)
    local key = ip_key(item_type, material, index)
    local ip, _, idx = utils.binsearch(ip_list, key, 'key')
    return ip, idx
end


local function fill_in_ip(ip, item_type, material, index)
    local ip = ip or {}

    ip.key =		ip.key		or ip_key(item_type, material, index)	-- TODO ensure_key() ?
    ip.item_type =	ip.item_type	or item_type
    ip.material =	ip.material	or material
    ip.index =		ip.index	or index
    -- ip.name handled below
    ip.units =		ip.units	or 0		-- count of units with this pref.
    ip.meals =		ip.meals	or 0		-- count of prepared meals with this ingredient.
    ip.ingredient =	ip.ingredient	or 0		-- count of this ingredient that we own.
    ip.trader =		ip.trader	or 0		-- count of this ingredient that traders have
    ip.purchasing =	ip.purchasing	or 0		-- count of this ingredient marked for purchase.
    ip.products =	ip.products	or {}		-- list of keys.  TODO working on this.

    -- TODO is this the best way?  for fish, returns e.g. 
    --   CREATURE:FISH_BULLHEAD_BROWN:BONE or CREATURE:FISH_LAMPREY_BROOK:CARTILAGE
    -- TODO what happens with EGG?  are there other caste-material foods?
    if dfhack.items.isCasteMaterial(item_type) then
	local race = material
	ip.name = 	ip.name		or dfhack.matinfo.decode(19, race):getToken()
    else
	ip.name = 	ip.name		or dfhack.matinfo.decode(material, index):getToken()
    end
--print(ip.name, item_type, material, index)
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
--    print('---1');printall(ip);
    ip = fill_in_ip(ip, item_type, type, index)
--    print('---2');printall(ip);print('--')
    add_ip(ip_list, ip)
    return get_ip(ip_list, item_type, type, index)
end


local function remove_ip_by_item(ip_list, item)
    utils.erase_sorted_key(ip_list, ip_key_by_item(item), 'key')
end


local function print_ingredient_preference(ip)
    printf("%-42s %-8s %-12s %3d %4d %4d %4d %4d",
	ip.name, ip.key, df.item_type[ip.item_type], ip.units, ip.meals, ip.ingredient, ip.trader, ip.purchasing)
end


-- TODO ip_is_edible()  ??


local function ip_is_cookable(ip)
--print( ip.item_type, ip.material, ip.index, dfhack.matinfo.decode( ip.material, ip.index ))

    if ip.item_type == df.item_type.FISH then return true; end

    local matinfo = dfhack.matinfo.decode(ip.material, ip.index)
    if not matinfo then return false; end

    if matinfo.material.flags.EDIBLE_COOKED then return true; end

    return false
end


-- TODO getProducts or isThereACookableProduct
-- TODO isCookable(item_type, material, index)


local function isCookable(item)

    if item:getType() == df.item_type.FISH then return true; end

--print( item:getMaterial(), item:getMaterialIndex() )
--print(dfhack.matinfo.decode( item:getMaterial(), item:getMaterialIndex() ))
    local matinfo = dfhack.matinfo.decode( item:getMaterial(), item:getMaterialIndex())
if not matinfo then print('no matinfo'); return false; end

    if matinfo.material.flags.EDIBLE_COOKED then return true; end

    return false
end


-- TODO track which units have been collected, add new units as they are added.
-- TODO maybe do this slowly, one unit every 10 ticks.  (couldn't use getCitizens in that case.)
-- TODO intelligent units that can eat bones?  but bones are not purchasable or cookable, I think.
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


-- TODO track PASTE and PRESSED specially.
local function collect_ingredient_counts()
    -- no preferences for GLOB or EGG.  although I want to add them.
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

    -- TODO item:isEdible*(), item:isLiquidPowder(), item:isFoodStorage()
    --    there is no isEdibleCooked or isCookable.
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

        -- note: press cakes, pastes, slurries are never offered for sale.
        -- note: currently, goods for sale are never contained in large pots.

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


local function print_ingredient_preferences()
    for _, ip in ipairs(ingredient_preferences) do
	print_ingredient_preference(ip)
    end
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


collect_ingredient_preferences()
collect_ingredient_counts()
purge_ip_by_cmpfn(ingredient_preferences, function(ip) return (ip.units == 0); end)
purge_ip_by_cmpfn(ingredient_preferences, function(ip) return (ip.trader == 0); end)  -- TODO this purges products
--purge_ip_by_cmpfn(ingredient_preferences, function(ip) return (ip.trader ~= 0); end)
purge_ip_by_cmpfn(ingredient_preferences, function(ip) return (ip.ingredient >= 20); end)
purge_ip_by_cmpfn(ingredient_preferences, function(ip) return(ip.meals>=ip.units*5); end)
mark_for_purchase()
--purge_ip_by_cmpfn(ingredient_preferences, function(ip) return (ip.purchasing == 0); end)
--purge_ip_by_cmpfn(ingredient_preferences, function(ip) return(ip.meals>=ip.units*5 or ip.ingredient==0); end)
--purge_ip_by_cmpfn(ingredient_preferences, function(ip) return(ip.meals>=ip.units*5 or ip.ingredient~=0); end)


if (false) then  -- print to clipboard
    if (false) then
        local function current_script_path()
            local frame = 1
            while true do
                local info = debug.getinfo(frame, 'f')
                if not info then break end
                if info.func == dfhack.run_script_with_env then
                    local i = 1
                    while true do
                        local name, value = debug.getlocal(frame, i)
                        if not name then break end
                        if name == 'file' then    -- look for variable 'file' instead of variable 'name'
                            return value
                        end
                        i = i + 1
                    end
                    break
                end
                frame = frame + 1
            end
            return nil
        end

        local profiler = require('profiler').newProfiler("time")
        profiler:start()
        print_to_clipboard(print_ingredient_preferences)
        profiler:stop()
        local outfile = (current_script_path() or "profiler_output"):gsub("%.lua$", "", 1) .. ".profile.txt"
        outfile = io.open(outfile, "w+")
        profiler:report(outfile)
        outfile:close()
    else
        print_to_clipboard(print_ingredient_preferences)
    end
end

if (true) then  -- print to console
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


]==]

--[=[ copy-paste to Lua console: preload clipboard with desired drinks, this prints the associated fruits.
DM=dfhack.matinfo;IO=df.global.world.items.other
function P(mdef,c) print(string.format("%-25s  %d",DM.getToken(mdef),c));end
function M(item,mdef)return(mdef ~= nil and item.mat_type==mdef.type and item.mat_index==mdef.index);end
function Z(s)local m=DM.find(s);local c=0;for _,i in ipairs(IO.PLANT_GROWTH)do if M(i,m)and not i.flags.trader then c=c+i:getStackSize();end;end;P(m,c);end
for _,s in ipairs(dfhack.internal.getClipboardTextCp437Multiline())do s=s:trim():gsub("(PLANT:[%w%-_]+:%a+)%s+%d+%s+%d+.*","%1"):gsub(":DRINK",":FRUIT");Z(s);end
]=]

