local utils = require('utils')
local eventful = require('plugins.eventful')

local error = dfhack.error
local function errorf(...)
    dfhack.error(string.format(...))
end

local target_food_stack_item_id = 373114

local function printf(...)
    print(string.format(...))
end

local function itemdesc(item)
    return(string.format("%d %s", item.id, dfhack.items.getReadableDescription(item)))
end

local function print_job_info(job)  -- not general-purpose; customized for Eat
    printf(df.job_type[job.job_type])
    -- printall(job)
    -- printall(utils.parse_bitfield_int(job.flags.whole, df.job_flags))
    for index, ji in ipairs(job.items) do
	local item = ji.item
	printf("job.item %d: role %s  %s", index, df.job_role_type[ji.role], itemdesc(item))
        -- role can be Reagent or Other.
	--   it starts as Other.
        --   (maybe?) Reagent only when there is a target building (which is a throne).
	--printall(utils.parse_bitfield_int(ji.flags.whole, df.jobitem_flag))
    end
    if #job.job_items.elements ~= 0 then printf("NOTICE: this job has nonzero job_items.elements, INVESTIGATE FURTHER"); end
    local gref=dfhack.job.getGeneralRef(job, df.general_ref_type.BUILDING_USE_TARGET_1)
    if gref then 
	printf("Target: %d %s", gref.building_id, dfhack.buildings.getName(df.building.find(gref.building_id)) )
	-- Example: Green Glass Throne.
    else
	--printf("No Target")
    end
    local gref=dfhack.job.getGeneralRef(job, df.general_ref_type.UNIT_WORKER)
    if gref then
	local unit = df.unit.find(gref.unit_id)
	printf("Unit: %d  %s", gref.unit_id, dfhack.units.getReadableName(unit) )
	--printall(unit.path.dest)
	--printf("%s", df.unit_path_goal[unit.path.goal])
	--printf("#unit.path.path.x: %d", #unit.path.path.x)
    else
	printf("\aNO UNIT! WTF!")
    end
    print('----')
end

local function unsplit_stack(item)
    -- TODO probably copy from combine.lua
end

local function is_interesting_job(job)
    if not df.job:is_instance(job) then errorf("not a job"); end
    return job.job_type == df.job_type.Eat
    -- TODO fetching food for a backpack.  Probably df.job_type.GetProvisions
end

local function handle_job(job)
    if not df.job:is_instance(job) then errorf("not a job"); end
    if not is_interesting_job(job) then return; end

    -- by the time we receive the notification,
    -- * the food item has already been chosen,
    -- * it has been split from its original stack, 
    -- * it is owned,
    -- * it is assigned to the job,
    -- * the unit is assigned to the job, 
    -- * the unit.path.dest has been set to the item.pos
    -- * the unit.path.goal has been set to @@@
    -- * the unit.path.path has been computed, 
    -- * a unit.action.Move has been created,
    -- ! the df.general_ref_type.BUILDING_USE_TARGET_1 has not been chosen.
    --    maybe that is chosen when the food is picked up.
    --    the target building is NOT the barrel.  it is the chair that will be used.
    if true then print_job_info(job); end

    -- TODO does this properly handle the on-duty soldiers case?
    if job.job_type == df.job_type.Eat then
	if (#job.items == 0) then errorf("\aNo old item in job"); end
	if (#job.items > 1) then errorf("\aMore than 1 item in job"); end
	local ji = job.items[0]
	if ji.role ~= df.job_role_type.Other then printf("\aJob item role type is not Other"); return; end
	local olditem = ji.item

	local unit = dfhack.job.getWorker(job)
	if not unit then errorf("\aJob doesn't have an assigned unit"); end
	if dfhack.items.getHolderUnit(olditem) ~= nil then
	    if dfhack.items.getHolderUnit(olditem) == unit then
		printf("\aItem-to-replace is already in the unit's inventory")
		return
	    else
		printf("\aItem-to-replace is in some other unit's inventory")
		return
	    end
	end

	local stack = df.item.find(target_food_stack_item_id)  -- TODO find best food.
	if not stack then printf("\aNo replacement item"); return; end
	if stack:getStackSize() == 1 then printf("\aStack size 1; can't split."); return; end  -- TODO special-case
	if stack.flags.in_job then printf("\a.flags.in_job"); return; end
	if stack.flags.owned then printf("\a.flags.owned"); return; end
	-- ... and more tests.
	-- TODO especially abort if the olditem is mergeable with the chosen stack, by combine.lua rules.

	printf("Disconnecting old job item  %s", itemdesc(olditem))
	dfhack.job.disconnectJobItem(job, job.items[0] )	-- undocumented
	job.items:erase(0)

 	printf("Unsplitting old job item %s", itemdesc(olditem))
	unsplit_stack(olditem)

	printf("Splitting item stack %s", itemdesc(stack))
	local item = stack:splitStack(1, true)
	item:categorize(true)
	printf(":splitStack(1, true) into %s", itemdesc(item))

	printf("Attaching item %s to this job", itemdesc(item))
	local success = dfhack.job.attachJobItem(job, item, df.job_role_type.Other, -1, -1)
	if not success then
	    printf("\aFailed to attach item")
	    return
	end

	if false then print_job_info(job); end


if true then printf("Old Goal  %s @%d,%d,%d", df.unit_path_goal[unit.path.goal], pos2xyz(unit.path.dest)); end
	printf("Setting new Goal.")
	-- df.unit_path_goal.StartEatJob or df.unit_path_goal.SeekFoodItem  ??
	dfhack.units.setPathGoal(unit, xyz2pos(dfhack.items.getPosition(item)), df.unit_path_goal.StartEatJob)
if true then printf("New Goal  %s @%d,%d,%d", df.unit_path_goal[unit.path.goal], pos2xyz(unit.path.dest)); end

	if true then dfhack.world.SetPauseState(true); end

    elseif job.job_type == df.job_type.GetProvisions then
	printf("TODO GetProvisions job found")
	print_job_info(job)
    else
	errorf("Oops, unimplemented job_type!  %d %s", job.job_type, df.job_type[job.job_type])
    end
end

local function analyze_job(job)
    if not df.job:is_instance(job) then errorf("not a job"); end
    if not is_interesting_job(job) then return; end

    local unit = dfhack.job.getWorker(job)
    local prefs = {}
    for _,p in ipairs(unit.status.current_soul.preferences) do
	if p.type == df.unitpref_type.LikeFood then
	    local it, mt, mi = p.item_type, p.mattype, p.matindex
	    local s = string.format("%d,%d,%d", it, mt, mi)
	    prefs[s] = true
	end
    end

    local match = false

    local item = job.items[0].item
    printf("%-40s %s", dfhack.units.getReadableName(unit), dfhack.items.getReadableDescription(item))
    if item:getType() == df.item_type.FOOD then
	for _, ing in ipairs(item.ingredients) do
	    local it, mt, mi = ing.item_type, ing.mat_type, ing.mat_index
	    if dfhack.items.isCasteMaterial(it) then
		mi = -1
	    end
	    local s = string.format("%d,%d,%d", it, mt, mi)
	    if prefs[s] then match = true; end
	end
    else
	local it, mt, mi = item:getType(), -1, -1
	if dfhack.items.isCasteMaterial(item:getType()) then
	    mt = item.race
	else
	    mt, mi = item.mat_type, item.mat_index
	end
	local s = string.format("%d,%d,%d", it, mt, mi)
	if prefs[s] then match = true; end
    end
    printf("The unit %s a preference for the food.", match and "has" or "does not have")
end

local function catch_new_jobs(job)
    --printf('caught %d', job.id)
    --handle_job(job)
    analyze_job(job)
end

local function main()
    if false then
	for _, job in utils.listpairs(df.global.world.jobs.list) do
	    if is_interesting_job(job) then
		--print_job_info(job)
            	--handle_job(job)
		analyze_job(job)
	    end
	end
    end
    if true then
        eventful.enableEvent(eventful.eventType.JOB_INITIATED, 99 )
	eventful['onJobInitiated']['KEY_KEY_KEY'] = catch_new_jobs
    end
end

main()


--[=[
14686	id matmorul
likes 69/420/64 PLANT:POTATO:DRINK
food 373190 matches PLANT:POTATO:DRINK

she was content after eating a wonderful dish.
she was content after having a fine drink.
.status.eat_history.drink	
	has a lot of 69/420/64. the last 15 entries, and others.
	PLANT:POTATO:DRINK.  he has a preference for it.
.status.eat_history.food
	MEAT		21	182	CREATURE:WATER_BUFFALO:MUSCLE
	MEAT		21	182	CREATURE:WATER_BUFFALO:MUSCLE
	PLANT_GROWTH	423	145	PLANT:POMELO:FRUIT
	FOOD		-1	-1
	FOOD		-1	-1
	FOOD		-1	-1
	FOOD		-1	-1
	FOOD		-1	-1
	FOOD		-1	-1
	FOOD		-1	-1
	FOOD		-1	-1	
	MEAT		21	399	CREATURE:WOLVERINE:MUSCLE	PREF
	MEAT		21	399	CREATURE:WOLVERINE:MUSCLE	PREF
	MEAT		21	399	CREATURE:WOLVERINE:MUSCLE	PREF
	MEAT		21	399	CREATURE:WOLVERINE:MUSCLE	PREF
	FOOD		-1	-1
	FOOD		-1	-1

food 373190 roast
	69/420/64	PLANT:POTATO:DRINK
	54/419/185	PLANT:WEED_RAT:STRUCTURAL
	54/419/45	PLANT:CELERY:STRUCTURAL
	48/21/704	CREATURE:HYENA:MUSCLE
setting food 373190 (main) quality to masterful.

made her hungry: .counters2.hunger_timer = 50000
she chose that potato wine roast.
she is delighted after eating a truly decadent dish.
quite a few others who ate that same roast were:
... content after eating a fine dish.

value of 1 masterful potato wine roast = 39
5 + 2*4 + 1*4 + 2*4 + 2*4   = 33
5 + 2*5 + 1*5 + 2*5 + 2*5   = 40


413767

invoking item2=item1:splitStack(size,true) yields an item2 that is not in a job.
it is still owned if the item1 was owned.
you do need to invoke item2:categorize(true).

if there is a matching item stack on the same tile / in the same container
    (not owned and no job),
item2:addStackSize(1)
dfhack.items.remove(item1)

otherwise, 
item1:addStackSize( --[[amount]] 1)
item2 = item1:splitStack( --[[stack_size]] 1, --[[preservecontainment]] true)
item2:categorize( --[[in_play]] true)
dfhack.items.remove(item1)
dfhack.items.setOwner(item2, nil)

NO, dfhack.items.remove() does NOT do what we want, because it cancels the job,
it doesn't just remove that item from the job.

We do need to maually delete the item.specific_ref.JOB and clear the item.flags.in_job.

Ahah! No we don't!  DFHack::Job::disconnectJobItem is exported to Lua as 
dfhack.job.disconnectJobItem().  Undocumented.  Exactly the same API.

dfhack.units.setPathGoal(u, i4.pos, 57)

]=]

--[==[

[DFHack]# monitor_eat_jobs
[DFHack]#
[DFHack]#
[DFHack]#
Run 'help' or '?' for the list of available commands.
Stukos Sefolkogan, SQ6                   (potato plant)
The unit has a preference for the food.
[DFHack]#
[DFHack]#
Libash Ekastlòr, Occupy                  (giant kangaroo cheese)
The unit has a preference for the food.
immortal-cravings: Feb Ukerfikod, outpost liaison necromancer is getting a drink
ùshrir Bomrektilesh, sq15                (mussel)
The unit has a preference for the food.
Obok Guzalåth, SQ6                       strawberry plant
The unit does not have a preference for the food.
îton Dorenvabôk, sq14                    (herring, ♂)
The unit has a preference for the food.
Rebalanced prayer needs for 1 units.
Id Teshkadfikod, SQ3                     strawberry plant
The unit has a preference for the food.
åblel Sûbilzasit, SQ7                    (nurse shark meat)
The unit has a preference for the food.
Id Kekimäs, sq15                         donkey meat
The unit does not have a preference for the food.
Mörul Alisoltar, SQ15                    (cow cheese)
The unit has a preference for the food.
èrith Urdimaral, SQ4                     (lungfish, ♀)
The unit does not have a preference for the food.
Logem Stukónlitast, sq14                 (rhubarb)
The unit has a preference for the food.
Doren Aliszulban, Furnace Operator       deer meat
The unit does not have a preference for the food.
Urdim Datanlisid, SQ10                   strawberry plant
The unit does not have a preference for the food.
Kûbuk Steliddeler, sacred gravel         *potato wine roast*
The unit does not have a preference for the food.
Uzol èrithmosus, SQ9                     (rhubarb)
The unit does not have a preference for the food.
preserve-rooms: restoring room ownership for Ral `Stress' Lolorlòr, SQ8
Zefon Uzolthimshur, Furnace Operator     (lettuce)
The unit has a preference for the food.
preserve-rooms: restoring room ownership for Limul Zulbanlimâr, SQ8
preserve-rooms: restoring room ownership for Mörul Kokebkulet, SQ8
preserve-rooms: restoring room ownership for Fath Fathgongith, SQ8
preserve-rooms: restoring room ownership for Urist Otungathel, SQ8
preserve-rooms: restoring room ownership for Erush Likotdakost, SQ8
Bomrek Ngaláklòr, SQ7                    (pig meat)
The unit does not have a preference for the food.
Amost Eralmatul, SQ14                    strawberry plant
The unit does not have a preference for the food.
Rimtar ùshrirelis, SQ01                  (salmon, ♂)
The unit has a preference for the food.
Ubbul Dedukdallith, SQ15                 (vulture meat)
The unit has a preference for the food.
Rimtar Zuglarnëlas, SQ2                  deer meat
The unit does not have a preference for the food.
Fath Kûbukudist, militia captain         (cow cheese)
The unit does not have a preference for the food.
Deduk Dakasoslan, militia captain        (oyster)
The unit has a preference for the food.
Zulban `Coward' Migrurrigòth, Carpenter  (bobcat meat)
The unit has a preference for the food.
Momuz Bomrekmat, Occupy                  strawberry plant
The unit does not have a preference for the food.
Kadol Ungòbendok, SQ5                    (lungfish, ♀)
The unit has a preference for the food.
Thîkut `Stress' Gåkïzmelbil, Scholar     (wild carrot plant)
The unit has a preference for the food.
Iden Italäs, SQ6                         (sailfin molly, ♂)
The unit has a preference for the food.
Kûbuk Delerottem, SQ13                   (tapir cheese)
The unit has a preference for the food.
Uvash Bisekèrith, sq13                   (sweet potato plant)
The unit has a preference for the food.
Asmel Alåthkobel, sq13                   deer meat
The unit does not have a preference for the food.
Thob Dakostalmôsh, SQ15                  deer meat
The unit does not have a preference for the food.
Udil Stâkudthak, SQ12                    deer meat
The unit does not have a preference for the food.
Avuz Kälánmosus, SQ11                    (giant kangaroo meat)
The unit has a preference for the food.
Led Libashcudïst, Woodcrafter            deer meat
The unit does not have a preference for the food.
Medtob `Coward' ïngizekur, SQ10          (squid, ♀)
The unit has a preference for the food.
Kivish Febrigòth, SQ14                   strawberry plant
The unit does not have a preference for the food.
Iden Athelstigaz, SQ11                   (leek)
The unit has a preference for the food.
Id `Stress' Thobnokgol, SQ01             (brown bullhead, ♂)
The unit has a preference for the food.
Atîs `Stress' Listfikod, SQ12            (prickle berry)
The unit has a preference for the food.
Asmel `Stress' Mìshosïteb, Miner         (cave fish, ♀)
The unit does not have a preference for the food.
Oddom `Stress' Zursùlgoden, SQ9          deer meat
The unit does not have a preference for the food.
Ber Borushlolor, SQ2                     llama meat
The unit does not have a preference for the food.
Thîkut `Stress!' Storluteshtân, Miner Scholar water buffalo meat
The unit does not have a preference for the food.
idle-crafting: assigned crafting job to Atîs `Stress' Listfikod, SQ12
idle-crafting: assigned crafting job to Fath Kûbukudist, militia captain
Lòr Regìnal Lavathtegir Lanlar, SQ5      llama meat
The unit does not have a preference for the food.
Solon Therlethdeler, Miner               llama meat
The unit does not have a preference for the food.
Vutok Domasdegël, SQ5                    llama meat
The unit does not have a preference for the food.
Tholtig Fikodnïr, SQ15                   strawberry plant
The unit does not have a preference for the food.
Zuglar `Stress' Tiristnimak, Doctor Scholar llama meat
The unit does not have a preference for the food.
Olin Nokimâbir, H Messenger              (asparagus)
The unit has a preference for the food.
Eral Lokumsinsot Gusilkåtdir Arros, SQ5  (goose meat)
The unit has a preference for the food.
Rigòth Logemgusil, SQ11                  (rainbow trout, ♂)
The unit has a preference for the food.
Ubbul Dodóktalul, SQ01                   llama meat
The unit does not have a preference for the food.
Logem åmkûbuk Mat, SQ5                   (brook lamprey, ♂)
The unit has a preference for the food.
Goden Orrunmörul, SQ11                   llama meat
The unit does not have a preference for the food.
idle-crafting: assigned crafting job to Tosid `Cowardish' Geshudzokun, H WC
Libash Sazirokol, SQ2                    (pomegranate)
The unit has a preference for the food.
Urist Ularthîkut, sq14                   (clown loach, ♂)
The unit has a preference for the food.
èrith Fashuzol, broker                   llama meat
The unit does not have a preference for the food.
îton `Coward' Langgudmeng, Holy Howl, Planter llama meat
The unit does not have a preference for the food.
îton Berurist, Occupy                    donkey meat
The unit has a preference for the food.
Ineth `Stress Strong' Rovodnimak, Scholar strawberry plant
The unit does not have a preference for the food.
Bomrek `Stress' Nethcilob, Metalcrafter  (apricot)
The unit has a preference for the food.
Mistêm Kadôleral, SQ4                    (glasseye, ♂)
The unit has a preference for the food.
Tosid `Cowardish' Geshudzokun, H WC      llama meat
The unit does not have a preference for the food.
Lolor Arrosimush, Dwarven Child          llama meat
The unit does not have a preference for the food.
Lòr Nanirlolok, SQ14                     strawberry plant
The unit does not have a preference for the food.
Shorast Raglorbam, Dwarven Child         strawberry plant
The unit does not have a preference for the food.
Sarvesh `Stress' Menglîlar, SQ10         (round lime)
The unit has a preference for the food.
Zulban Osorilral, Dwarven Child          llama meat
The unit does not have a preference for the food.
Thob `Coward' ïlunvucar, Weaponsmith     llama meat
The unit does not have a preference for the food.
Aban Zasitkan, Dwarven Child             ≡water buffalo meat roast≡
The unit has a preference for the food.
Cerol Volallibash, H                     (perch, ♀)
The unit has a preference for the food.
Stukos Gisëkfikod, SQ5                   (brown bullhead, ♂)
The unit has a preference for the food.
Thob Tangathkadôl, sq14                  strawberry plant
The unit does not have a preference for the food.
Kosoth `Stress' âbiroltar, H             (char, ♀)
The unit does not have a preference for the food.
Kumil Gethshorast, SQ5                   llama meat
The unit does not have a preference for the food.
Kol Nicatber, SQ7                        (monitor lizard meat)
The unit has a preference for the food.
Mosus `Nervous' Cattenemal, SQ01         llama meat
The unit does not have a preference for the food.
Sanera Ecateawiri, Scholar               strawberry plant
The unit does not have a preference for the food.
Limul Zulbanlimâr, SQ8                   (guppy, ♂)
The unit does not have a preference for the food.
Kivish `Cowardish' Akrultögum, SQ10      strawberry plant
The unit does not have a preference for the food.
Stâkud Bêngengsazir, SQ4                 (donkey cheese)
The unit has a preference for the food.
Dumat `Coward!' Belalmistêm, H           (alfalfa)
The unit has a preference for the food.
Stodir Stizashkûbuk, SQ01                (guppy, ♂)
The unit does not have a preference for the food.
Likot Koganurmim, Dwarven Child          (olive)
The unit has a preference for the food.
Stodir Oslanuzol, sq14                   (water buffalo cheese)
The unit has a preference for the food.
Id Libadmeng ùnil Litast, SQ5            (brook lamprey, ♂)
The unit has a preference for the food.
Cog Asënodkish, SQ13                     (bloated tuber)
The unit does not have a preference for the food.
ùshrir `Stress' Gikutfikod, H            (lettuce)
The unit has a preference for the food.
Mosus Uristkälán, SQ4                    (seahorse, ♀)
The unit has a preference for the food.
Sarvesh Mengalåth, sq14                  (asparagus)
The unit has a preference for the food.
idle-crafting: assigned crafting job to Sidaya `Very Weak' Lithoimepe, Queen Scholar
Olin Kilrudnokgol, Manager Scholar       (guppy, ♂)
The unit does not have a preference for the food.
idle-crafting: assigned crafting job to ùshrir `Stress' Gikutfikod, H
Lorbam Zonartob, SQ7                     (plump helmet)
The unit has a preference for the food.
[DFHack]#                                                                                       
]==]