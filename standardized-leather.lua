--@ module = false
local utils = require('utils')


-- Based on Veok's Standardized Leather Mod v1.01 for DF version: 0.31.25 circa 2011.
-- https://dffd.bay12games.com/file.php?id=4779


-- TODO a lot of our variables aren't valid unless a world is loaded.
--	init them on SC_WORLD_LOADED, clear them on SC_WORLD_UNLOADED.
--	since we are in scripts_modactive, this may not be necessary.

if false then print('SL BASE_G'); printall(dfhack.BASE_G); print('!!'); end
if false then print('SL _G'); printall(_G); print('!!'); end
if false then print('SL _ENV'); printall(_ENV); print('!!'); end


local debugging = true

local Mod_ID = 'standardized_leather'
	-- ID of the mod, per the info.txt file.  
	--    can we parse that?  would it be worth it?)
	-- 	A: no; we don't have a starting directory; 
	--	getModSourcePath() requires us to already know it.
	--	can we get it from DFHack?  DFHack must know it.
	--	A: apparently not.
	-- okay, now that we have current_script_file(), we could find info.txt in the path,
	--	and parse it.  we could....


-- modified from dfhack.current_script_name()
-- this returns the entire path, which may be absolute, or may be relative to the DF executable directory.
local function current_script_file()
    local frame = 1
    while true do
	local info = debug.getinfo(frame, 'f')
	if not info then break end
	if info.func == dfhack.run_script_with_env then
	    local i = 1
	    while true do
		local name, value = debug.getlocal(frame, i)
		if not name then break end
		if name == 'file' then		-- this was my change: 'name' to 'file'.
		    return value
		end
		i = i + 1
	    end
	    break
	end
	frame = frame + 1
    end
end

--[[ to paste into Lua console:
function current_script_file() local frame = 1;while true do local info = debug.getinfo(frame, 'f');
if not info then break end;if info.func == dfhack.run_script_with_env then local i = 1;while true do
local name, value = debug.getlocal(frame, i);if not name then break end;if name == 'file' then return value;
end;i = i + 1;end;break;end;frame = frame + 1;end;end
]]

--print(current_script_file())
--local scriptmanager = require('script-manager')
--printall(scriptmanager.get_mod_script_paths())

--local GLOBAL_KEY = Mod_ID .. '+' .. dfhack.current_script_name()
	-- dfhack.current_script_name() ought to be unique itself; just use that?
	--   A: no, it's not guaranteed to be unique.
	--   A2: figured out how to get the entire script path, which is guaranteed unique.

local GLOBAL_KEY = current_script_file():escape_pattern()
	-- guaranteed unique key for the state-change callback.


---- Define locals.


local current_script_name = dfhack.current_script_name()

local world			= df.global.world
local creatures_all		= df.creature_raw.get_vector()
local mat_table			= world.raws.mat_table


local mat_common_skin		= dfhack.matinfo.find('INORGANIC:SL_SKIN_ANIMAL')
local mat_rare_skin		= dfhack.matinfo.find('INORGANIC:SL_SKIN_RARE')
local mat_exotic_skin		= dfhack.matinfo.find('INORGANIC:SL_SKIN_EXOTIC')

local mat_common_leather	= dfhack.matinfo.find('INORGANIC:SL_LEATHER_ANIMAL')
local mat_rare_leather		= dfhack.matinfo.find('INORGANIC:SL_LEATHER_RARE')
local mat_exotic_leather	= dfhack.matinfo.find('INORGANIC:SL_LEATHER_EXOTIC')

local mat_common_parchment	= dfhack.matinfo.find('INORGANIC:SL_PARCHMENT_ANIMAL')
local mat_rare_parchment	= dfhack.matinfo.find('INORGANIC:SL_PARCHMENT_RARE')
local mat_exotic_parchment	= dfhack.matinfo.find('INORGANIC:SL_PARCHMENT_EXOTIC')

-- TODO would this implementation be better?
--[[
local our_mats = {
	mat_common_skin		= dfhack.matinfo.find('INORGANIC:SL_SKIN_ANIMAL'),
	mat_rare_skin		= dfhack.matinfo.find('INORGANIC:SL_SKIN_RARE'),
	mat_exotic_skin		= dfhack.matinfo.find('INORGANIC:SL_SKIN_EXOTIC'),

	mat_common_leather	= dfhack.matinfo.find('INORGANIC:SL_LEATHER_ANIMAL'),
	mat_rare_leather	= dfhack.matinfo.find('INORGANIC:SL_LEATHER_RARE'),
	mat_exotic_leather	= dfhack.matinfo.find('INORGANIC:SL_LEATHER_EXOTIC'),

	mat_common_parchment	= dfhack.matinfo.find('INORGANIC:SL_PARCHMENT_ANIMAL'),
	mat_rare_parchment	= dfhack.matinfo.find('INORGANIC:SL_PARCHMENT_RARE'),
	mat_exotic_parchment	= dfhack.matinfo.find('INORGANIC:SL_PARCHMENT_EXOTIC'),
}
]]

--[[
if	   mat_common_skin == nil	or mat_rare_skin == nil 	or mat_exotic_skin == nil
	or mat_common_leather == nil 	or mat_rare_leather == nil 	or mat_exotic_leather == nil
	or mat_common_parchment == nil	or mat_rare_parchment == nil 	or mat_exotic_parchment == nil 
then
    qerror(("The %s mod's raws are not installed; aborting script."):format(Mod_ID))
end
]]


---- Magic numbers; these depend on DF internals.

local first_creature_mat = df.builtin_mats._last_item+1					-- == 19
	-- internal creature material types start just after the builtin materials.
	-- there are currently 18 builtin materials.
local last_creature_mat = (#df.plant_raw.get_vector() > 0)	-- safety; maybe no world is loaded.
		and ((df.plant_raw.get_vector()[0].material_defs.type.basic_mat)-1)	-- == 418
		or nil
	-- one less than the material type of the first plant, which is currently mat_type 419.
	-- this means that there can be a maximum of 400 creature material types.
	-- a creature generally has 20 to 25 material types.
	-- they generally start with SKIN and end with BLOOD, PUS, or ICHOR.
	-- note: the Lua idiom (test) and (true_result) or (false_result) is equivalent to C's ?: operator.


---- Helper functions


local function printf(...)
    print(string.format(...))
end


-- debug-printf: suppress the output if not debugging.
local function dprintf(format, ...)
    if debugging then
	printf("%s: " .. format, current_script_name, ...)
    end
end


---- Implementation code


-- for speed, we assume that only SKIN creature materials will generate organic leather and parchment.
-- we further assume that the reaction IDs are TAN_MAT and PARCHMENT_MAT.
---@param mat df.material	# a SKIN material of a creature.
---@return boolean
local function modify_SKIN_reactions(mat)
    local changed = false

    -- just replace the whole material; will it work?
    -- BADCODE: mat = mat_common_skin.material
    -- eh, doesn't really work.  Causes crashes on unload.  Need to do a deep copy?
    -- no, too hard; just massage the existing entry in-place.

    -- okay.  the only real difference should (hopefully) be in the reaction products.

    -- we use a numeric for loop because there are several arrays to walk in lockstep.
    for j = 0, (#mat.reaction_product.id-1) do  

	if mat.reaction_product.id[j].value == 'TAN_MAT' then

	    -- set the new leather type by skin value.

	    ---@type tm df.material	# "target material"
	    local tm = mat_common_leather
	    if mat.material_value == 2 then tm = mat_rare_leather; end
	    if mat.material_value >= 3 then tm = mat_exotic_leather; end

	    -- override the reaction product type.
	    if mat.reaction_product.material.mat_type[j] ~= tm.type 
			or mat.reaction_product.material.mat_index[j] ~= tm.index 
	    then
		mat.reaction_product.material.mat_type[j] = tm.type
		mat.reaction_product.material.mat_index[j] = tm.index
		changed = true
	    end

	elseif mat.reaction_product.id[j].value == 'PARCHMENT_MAT' then

	    -- set parchment type by skin value
	    ---@type tm df.material	# "target material"
	    local tm = mat_common_parchment
	    if mat.material_value == 2 then tm = mat_rare_parchment; end
	    if mat.material_value >= 3 then tm = mat_exotic_parchment; end

	    if mat.reaction_product.material.mat_type[j] ~= tm.type 
			or mat.reaction_product.material.mat_index[j] ~= tm.index 
	    then
		mat.reaction_product.material.mat_type[j] = tm.type
		mat.reaction_product.material.mat_index[j] = tm.index
		changed = true
	    end
	end

    end -- foreach reaction_product

    return changed
end


-- This needs to process every creature on every run, because creatures are fully loaded 
--   from raws at world load.  As such, it needs to be fast.
---@param start_at_index	# the index (not id) into world.raws.creatures.all to start at.
---@return number		# the number of creatures that were modified.
local function modify_creatures(start_at_index)

  if start_at_index > #creatures_all then start_at_index = 0; end    -- sanity check

  local numchanged = 0

  -- note: if start_at_index == #creatures_all, we just loop 0 times.
  for i = start_at_index, (#creatures_all-1) do
    c = creatures_all[i]
    local changed = false

    for _, mat in ipairs(c.material) do

	-- for speed, we assume that only SKIN creature materials will generate organic leather and parchment.
	-- we further assume that the reaction IDs are TAN_MAT and PARCHMENT_MAT.
	if mat.id == 'SKIN' then

	    -- this got too nested, so I broke it out.
	    changed = modify_SKIN_reactions(mat) or changed

	end

	-- clear any relevant .flags and orphan this creature material's backlinks into the raws.mat_table .
	if (mat.id == 'LEATHER') and (
		   mat.flags.ITEMS_LEATHER ~= false
		or mat.flags.LEATHER ~= false 
		or mat.food_mat_index.Leather ~= -1 
	) then
	    mat.flags.ITEMS_LEATHER = false		-- not sure if clearing the flags is necessary.
	    mat.flags.LEATHER = false			-- not sure if clearing the flags is necessary.
	    mat.food_mat_index.Leather = -1		-- orphan this backlink.
	    changed = true
	end

	if (mat.id == 'PARCHMENT') and (
		    mat.food_mat_index.Parchment ~= -1
	) then
	    -- there are no .flags related to parchment.
	    mat.food_mat_index.Parchment = -1		-- orphan this backlink.
	    changed = true
	end

    end

    numchanged = numchanged + (changed and 1 or 0)
  end

  dprintf("%d creatures modified.  started at %d, ended at %d.", 
	numchanged, start_at_index, (#creatures_all-1) )

  return numchanged
end


---@param start_at_id	df.item.id	# NOT an index into world.items.all[]; the item does not have to exist.
---@return number	# the number of items that were modified; NOT the number of modifications.
--x@return df.item.id	# this is basically a high-water mark, used to skip already-processed items.
local function modify_existing_items2(start_at_id)

    ---@type df.item[]
    local items = df.item.get_vector()		-- world.items.all

    -- conveniently, utils.binsearch() returns a valid index whether or not a match was found.
    local _, found, start_at_index = utils.binsearch(items, start_at_id, 'id')

    local items_modified = 0
--    local first_modified_id = nil

    -- in the special case where start_at_id is greater than any item.id in the vector, it just loops 0 times.
    for i = start_at_index, (#items-1) do

	local item = items[i]

	local changed = 0

	---@type df.material
	local material

	-- there are several item types that don't have .mat_type and .mat_index fields.
	--  for these item types, :getMaterial() and :getMaterialIndex return the creature
	--  number and caste number respectively.  That's not relevant; we need to skip them.
	-- I figured out this test instead of:
	--  * individually testing df.item_remainsst:is_instance(item) and the other possibilities.
	--  * probing for the existance of the .mat_type field inside a dfhack.safecall() .
	--  * testing for the existance of item._type.fields['mat_type'] .
	if dfhack.items.isCasteMaterial( item:getType() ) then goto CONTINUE; end

	-- the .decode() call is a bit expensive, so we skip over all non-creature materials for speed.
	if item.mat_type < first_creature_mat or item.mat_type > last_creature_mat then goto CONTINUE; end

	material = dfhack.matinfo.decode(item.mat_type,item.mat_index)

	-- if it is made of leather from a creature,
	if material.mode == 'creature' and material.material.id == 'LEATHER' then

	    -- change it to our special inorganic common leather.
	    -- TODO maybe should check the value of the material?
	    dprintf("modifying item %d to from material %d:%d to inorganic common leather.", 
		item.id, item.mat_type, item.mat_index)
	    item.mat_type = mat_common_leather.type
	    item.mat_index = mat_common_leather.index

	    changed = 1
--	    first_modified_id = first_modified_id or item.id
	end

	-- if it is made of parchment from a creature,
	if material.mode == 'creature' and material.material.id == 'PARCHMENT' then

	    -- change it to our special inorganic common parchment.
	    -- TODO maybe should check the value of the material?
	    dprintf("modifying item %d from material %d:%d to inorganic common parchment.", 
		item.id, item.mat_type, item.mat_index)
	    item.mat_type = mat_common_parchment.type
	    item.mat_index = mat_common_parchment.index

	    changed = 1
--	    first_modified_id = first_modified_id or item.id
	end

	::CONTINUE::

	-- what a pain.  I don't like the code duplication, but I can't be bothered to abstract it.
	if item:hasImprovements() then
	    for j, imp in ipairs(item.improvements) do
		-- it /seems/ that all subclasses of df.itemimprovement have .mat_type and .mat_index fields.
		-- they may be set to -1, but who cares, as long as they exist.


		-- this time, don't bother to filter out non-creatures.  improvements are rare.

		material = dfhack.matinfo.decode(imp.mat_type,imp.mat_index)

		-- if it is made of leather from a creature,
		if material and material.mode == 'creature' and material.material.id == 'LEATHER' then

		    -- change it to our special inorganic common leather.
		    -- TODO maybe should check the value of the material?
		    dprintf("modifying item %d improvement %d from material %d:%d to " ..
			"inorganic common leather.", 
			item.id, j, imp.mat_type, imp.mat_index)
		    imp.mat_type = mat_common_leather.type
		    imp.mat_index = mat_common_leather.index

		    changed = 1
--		    first_modified_id = first_modified_id or item.id
		end

		-- if it is made of parchment from a creature,
		if material and material.mode == 'creature' and material.material.id == 'PARCHMENT' then

		    -- change it to our special inorganic common parchment.
		    -- TODO maybe should check the value of the material?
		    dprintf("modifying item %d improvement %d from material %d:%d to " .. 
			"inorganic common parchment.", 
			item.id, j, imp.mat_type, imp.mat_index)
		    imp.mat_type = mat_common_parchment.type
		    imp.mat_index = mat_common_parchment.index

		    changed = 1
--		    first_modified_id = first_modified_id or item.id
		end

	    end		-- for each improvment
	end -- item has improvements

	items_modified = items_modified + changed
    end

--    first_modified_id = first_modified_id or df.global.item_next_id   -- special case of NO items modified.
--    return items_modified, first_modified_id
    return items_modified
end


-- this scans through one of the df.global.world.items.other.* arrays,
-- analyzing each item and adjusting it if necessary.
-- TODO would a high-water mark work, by assuming that items below that mark have already been processed?
--	this implies persistent data storage to cache the high-water mark between world-loads.

---@param items_other_TYPE df.item[]
local function modify_existing_item_type(items_other_TYPE)

    -- analyse all of this item type.
    for _,item in ipairs(items_other_TYPE) do

	-- TODO the .decode() call is a bit expensive.
	--	for speed, we could skip the material if item.mat_type < 19 (builtin) or >= 419 (plant)
	---@type df.material
	local material = dfhack.matinfo.decode(item.mat_type,item.mat_index)

	-- if it is made of leather from a creature,
	if material.mode == 'creature' and material.material.id == 'LEATHER' then

	    -- change it to our special inorganic common leather.
	    -- TODO maybe should check the value of the material?
	    dprintf("modifying item %d to from material %d:%d (%s) to inorganic common leather.", 
		item.id, item.mat_type, item.mat_index, 
		tostring(dfhack.matinfo.decode(item.mat_type,item.mat_index)))
	    item.mat_type = mat_common_leather.type
	    item.mat_index = mat_common_leather.index

	end

	-- if it is made of parchment from a creature,
	if material.mode == 'creature' and material.material.id == 'PARCHMENT' then

	    -- change it to our special inorganic common parchment.
	    -- TODO maybe should check the value of the material?
	    dprintf("modifying item %d to from material %d:%d to inorganic common parchment.", 
		item.id, item.mat_type, item.mat_index)
	    item.mat_type = mat_common_parchment.type
	    item.mat_index = mat_common_parchment.index

	end

	-- TODO I suppose we ought to scan improvements too, but it's a pain.
    end
end


local function modify_existing_items()

    -- I'm not sure if weapons can be leather.  oh, I think whips can?
    -- scrolls are TOOLs.
    -- crafts: FIGURINEs, SCEPTERs, CROWNs, and RINGs should not be possible.  Doesn't hurt.
    -- SKIN_TANNED is the big category when traders show up.
    local categories = 'WEAPON,SHIELD,QUIVER,BACKPACK,FLASK,INSTRUMENT,' .. 
		'INSTRUMENT_STATIONARY,TOY,TOOL,BAG,BOOK,FIGURINE,AMULET,SCEPTER,CROWN,' ..
		'RING,EARRING,BRACELET,SKIN_TANNED,SHEET,PANTS,ARMOR,SHOES,HELM,GLOVES'

    -- string:split() is a dfhack-specific string extension.
    for _, itype in ipairs( categories:split(',', true)) do

	dprintf("fixing up %s", itype)

	-- this voodoo converts a string containing a variable name into a variable reference.
	---@type df.item[]
	local category = load('return df.global.world.items.other.' .. itype)()

	modify_existing_item_type(category)
    end
end


creature_start_at_index = 0		-- global, per-world-load, per-script-reload.
					--   the index (NOT id) into world.raws.creatures.all to start at.
					--   this can be above the last index that exists.
p_item_start_at_id = nil		-- global, persistent, per-successful-save-game.
p_item_sizeof_vector = nil		-- global, persistent, used to sanity-check p_item_start_at_id.
p_item_next_id = nil			-- global, persistent, used to sanity-check p_item_start_at_id.


local function modify_raws()
    print("Installing Standardized Leather mod raws injections.")

    -- TODO. could keep a global last-creature-processed variable.
    --   just don't save it to external storage, unlike the items.
    --   would have to clear it on world unload, for safety.  hmmm.
    if true then
	modify_creatures(creature_start_at_index)
	creature_start_at_index = #creatures_all  -- global
    end

    if true then
	local old_debugging = debugging; debugging = false
	local items_modified = modify_existing_items2(p_item_start_at_id)
	debugging = old_debugging
	p_item_start_at_id = df.global.item_next_id
    end

    -- 80% of random leathers and parchments will be animal, 15% rare, 5% exotic.
    -- this is done by having 16 animal, 3 rare, and 1 exotic in the organic lists.
    -- TODO: weighting the values like this may not be working; needs further investigation.
    -- ANSWER: it doesn't always work; e.g. traders bring the same amounts of each type.
    -- ANSWER2: I haven't tested it, but I bet if we process each civ (we need to anyway,
    -- see the TODO) that we could duplicate our inorganic entries in 
    --     civ.resources.organic.leather and .parchement.
    -- ANSWER3: IN FACT, if massaging the civs works, we should NOT add extra entries to
    --     mat_table.organic*.Leather/Parchment.

    -- TODO This is not enough! Also need to process each civilization and check its
    --     .resources.organic.leather and .parchment for creature types.

    -- Note: this code assumes that the special inorganic leather/parchment are the first three entries.
    -- We could/should check that.  
    if true then
	mat_table.organic_types.Leather:resize(3)
	mat_table.organic_indexes.Leather:resize(3)
	mat_table.organic_temp.Leather:resize(3)
	mat_table.organic_types.Parchment:resize(3)
	mat_table.organic_indexes.Parchment:resize(3)
	mat_table.organic_temp.Parchment:resize(3)

	-- add 17 more entries to make 20 total.  add 2 rare, 15 animal.
	for i = 3, 19 do
	    local ml = mat_common_leather
	    local mp = mat_common_parchment
	    if i == 3 or i == 4 then 
		ml = mat_rare_leather
		mp = mat_rare_parchment
	    end

	    mat_table.organic_types.Leather:insert('#', ml.type)
	    mat_table.organic_indexes.Leather:insert('#', ml.index)
	    mat_table.organic_temp.Leather:insert('#', 0)

	    mat_table.organic_types.Parchment:insert('#', mp.type)
	    mat_table.organic_indexes.Parchment:insert('#', mp.index)
	    mat_table.organic_temp.Parchment:insert('#', 0)

	end
    end

    if true then
	for _, civ in ipairs( df.historical_entity.get_vector() ) do
	if civ.type
	end
    end

end


---- module code


local function mod_is_loaded()
    -- df.global.world.object_loader.object_loader_order_id string[]  # names of installed mods.
    return(utils.linear_index(df.global.world.object_loader.object_load_order_id, Mod_ID, 'value') ~= nil)
end


local function load_cached()

-- TODO before implementing.  this logic doesn't work, it doesn't handle the case of
--	aborting the game after world-load.
--	consider caching the timestamp of the savegame, logic off that.

-- okay, we need to find out if our changed were saved in the most recent savegame.
-- we can do that by cacheing the time-of-modification, and comparing it with the
-- timestamp of the current savegame.

--	dfhack.filesystem.mtime(path)

--	Returns the modification time (in seconds) of the file or directory specified 
--	by path, or -1 if path does not exist. This depends on the system clock and 
--	should only be used locally.

-- can we do that with: 
--	dfhack.persistent.getUnsavedSeconds()
--	Returns the number of seconds since last save or load of a save.
-- no, doesn't seem reliable.

-- this is important.  we want to use this as a key.
-- but we also want to key off something game-unique, like maybe the world name or seed.
--	dfhack.getSavePath()
--	Returns the path to the current save directory, or nil if no save loaded.
dprintf("dfhack.getSavePath() = %s", dfhack.getSavePath())

--	dfhack.isWorldLoaded()
--	Checks if the world is loaded.

-- this might work.  we can cache the game tick count when we do our mod, and compare it with
-- the game tick count at world load time.
-- NO NO NO this is not relevant.  this is ui ticks.
--	dfhack.getTickCount()
--	Returns the tick count in ms, exactly as DF ui uses.

-- these two are more relevant.
--	dfhack.world.ReadCurrentYear()
--	Returns the current game year.
dprintf("dfhack.world.ReadCurrentYear() = %s", tostring(dfhack.world.ReadCurrentYear()))

--	dfhack.world.ReadCurrentTick()
--	Returns the number of game ticks (df.global.world.frame_counter) 
--	since the start of the current game year.
dprintf("dfhack.world.ReadCurrentTick() = %s", tostring(dfhack.world.ReadCurrentTick()))

--	dfhack.world.ReadWorldFolder()
--	Returns the name of the directory/folder the current saved game is under, 
--	or an empty string if no game was loaded this session.
dprintf("dfhack.world.ReadWorldFolder() = %s", dfhack.world.ReadWorldFolder())


--	scriptmanager.getModSourcePath(mod_id)
--	Retrieve the source directory path for the mod with the given ID or nil 
--	if the mod cannot be found. If multiple versions of a mod are found, the 
--	path for the version loaded by the current world is used. If the current 
--	world does not have the mod loaded (or if a world is not currently loaded) 
--	then the path for the most recent version of the mod is returned. 
--	Example:
--		local scriptmanager = require('script-manager')
--		local path = scriptmanager.getModSourcePath('my_awesome_mod')
--		print(path)
--	Which would print something like: mods/2945575779/ or 
--	data/installed_mods/my_awesome_mod (108)/, depending on where the mod 
--	is being loaded from.
dprintf("scriptmanager.getModSourcePath(Mod_ID) = %s",
	require('scriptmanager').getModSourcePath(Mod_ID) )

--	scriptmanager.getModStatePath(mod_id)
--	Retrieve the directory path where a mod with the given ID should store its 
--	persistent state. 
--	Example:
--		local json = require('json')
--		local scriptmanager = require('script-manager')
--		local path = scriptmanager.getModStatePath('my_awesome_mod')
--		config = config or json.open(path .. 'settings.json')
--	Which would open dfhack-config/mods/my_awesome_mod/settings.json. 
--	After calling getModStatePath, the returned directory is guaranteed to exist.
dprintf("scriptmanager.getModStatePath(Mod_ID) = %s", 
	require('scriptmanager').getModStatePath(Mod_ID) )


-- okay.  what the plan is.
-- we key our data off of the savegame path.
-- at world-unload time, we
--	save the dfhack.world.ReadCurrentYear() and dfhack.world.ReadCurrentTick().
--	as last-unloaded-time.  (Q:really?)

-- immediately after running the mod, we immediately save:
--	data structure version
--	sanitized world name				REDUNDANT TO SAVEGAME
--	cur_savegame.world_header.id1 and .id2		REDUNDANT TO SAVEGAME
--	cur_savegame.save_dir				REDUNDANT TO SAVEGAME
--	dfhack.world.ReadWorldFolder()			REDUNDANT TO SAVEGAME
--	dfhack.world.ReadCurrentYear()			OUGHT TO BE REDUNDANT TO SAVEGAME
--	dfhack.world.ReadCurrentTick()			OUGHT TO BE REDUNDANT TO SAVEGAME
--	current #items_all
--	current next_item_id
--dfhack.persistent.saveWorldData(Mod_ID, data_table)

-- at world-load time, we check:
--dfhack.persistent.getWorldData(Mod_ID, {})
--	data structure version
--	world.cur_savegame.world_header.id1 and .id2 match
--	world.cur_savegame.save_dir matches
--		this hopefully lets us detect moving a savegame between folders.
--		although since the json is saved in the savegame folder itself, that will auto-correct.
--	#items_all >= saved #items_all
--	next_item_id >= saved next_item_id
--	dfhack.world.ReadWorldFolder() matches
--	dfhack.world.ReadCurrentYear() > saved current_year
--	OR ( dfhack.world.ReadCurrentYear() == saved current_year 
--		AND dfhack.world.ReadCurrentTick() >= saved current_tick )

--	Found this; consider the implications.
--	"The data is kept in memory, so no I/O occurs when getting or saving keys."
--	"It is all written to a json file in the game save directory when the game is saved."
--	IN THE GAME SAVE DIRECTORY.  WHEN A GAME IS SAVED.
--	Okay, well, that at least resolves the quit-without-saving issues.  (TO TEST.)
--	It also ensures coherence between the savegame and our saved data.
--		AS LONG AS THE JSON IS NOT SAVED ON QUIT-WITHOUT-SAVING.


	-- load the cached item id to start processing at.
	-- if it's not valid, reset it to 0.
	p_item_start_at_id = (nil) --[[TODO]] or 0

	-- load the per-world-load #item_get_vector.
	-- global, persistent, used to sanity-check p_item_start_at_id.
	p_item_sizeof_vector = (nil) --[[TODO]] or 0

	-- load the per-world-load 
	p_item_next_id = (nil) --[[TODO]] or 0

	-- test the sanity checks
	if p_item_sizeof_vector ~= #df.item.get_vector() then
	    dprintf("p_item_sizeof_vector ~= #df.item.get_vector(), resetting p_item_next_id")
	    p_item_start_at_id = 0
	end
	if p_item_next_id ~= df.global.item_next_id then
	    dprintf("p_item_next_id ~= df.global.item_next_id, resetting p_item_next_id")
	    p_item_start_at_id = 0
	end


	p_item_sizeof_vector = #df.item.get_vector()
	p_item_next_id = df.global.item_next_id

end


local function save_cached()
	-- TODO save p_item_start_at_id to persistent storage
	-- TODO save p_item_sizeof_vector to persistent storage
	-- TODO save p_item_next_id to persistent storage
end


-- Note: it would be nice to only catch the world-loaded event.
--	The problem is, if the player proceeds from world-generation to play-now, 
--	  the world's creatures are not complete.
--	In particular, the first auto-generated creatures haven't been generated yet.
--	(discovered later) Additionally, auto-generated creatures do get added during play.
--	  experiments and the like.  possibly cursed creature types?  dunno.

function events_callback(event)
    if event == SC_WORLD_LOADED then
	dprintf("handling SC_WORLD_LOADED.")

	creature_start_at_index = 0	-- global, per-world-load, per-script-reload
	load_cached()
	modify_raws()
	save_cached()

    elseif event == SC_MAP_LOADED then
	dprintf("handling SC_MAP_LOADED.")

    elseif event == SC_WORLD_UNLOADED then
	dprintf("handling SC_WORLD_UNLOADED.")

	dfhack.onStateChange[GLOBAL_KEY] = nil	-- unhook

    end
end
-- I bet if I catch SC_VIEWSCREEN_CHANGED and monitor it for worldgen screens,
--   I could figure out when worldgen is complete.  But it might be too late....?

-- okay, I found out how.  if the OLD viewscreen was type viewscreen_new_regionst
-- and the NEW viewscreen is type viewscreen_export_regionst, worldgen just finished successfully.
-- HOWEVER, at that point, SC_WORLD_UNLOADED has just fired, so I don't know if world is still valid.
-- Oh.  Well.  On a Play Now, SC_WORLD_LOADED fired just before the viewscreen_choose_game_typest fired.
-- So.  Maybe we don't need to hook SC_MAP_LOADED after all.


---- run-once


if not mod_is_loaded() then
    qerror(("The %s mod is not installed; aborting script."):format(Mod_ID))
end


if dfhack_flags.module then
    dprintf("installing hooks.")
    dfhack.onStateChange[GLOBAL_KEY] = events_callback
else
    -- TODO consider using a command-line variable to override, for debugging.
    if debugging then
	dprintf("calling load_cached()")
	load_cached()
	dprintf("calling modify_raws()")
	modify_raws()
	dprintf("NOT calling save_cached()")
    else
	printf("The %s script is auto-executed when the %s mod is loaded;", 
		dfhack.current_script_name(), Mod_ID)
	printf("It is not intended to be invoked directly.  No action taken.")
	return
    end
end


-- DONT figure out world.world_data.object_data[]
--	actually it seems not relevant.  and has a WHOLE lot of empty entries.
--	anyway, a search of a mature fort found no .altered_items, no .offloaded items,
--	and no df.creation_zone_pwg_alteration_campst's of item type LEATHER.


-- TODO okay, new problem.  being inorganic, our leather items don't count as
--	Other Materials/Leather for armor stockpile sorting.
--	If I flip on material.flags.IS_METAL, they can be specified as Metal/Leather.
--	Unknown side effects, probably weird ones.
--	They're not available as a metal at the forge.
--	They can be flagged to be melted.

-- TODO	I am ALSO having a similar / the same problem with plant-based clothing!
--	Other Materials/Silk/Cloth/Yarn is not being sorted into stockpiles.
--	I spent hours trying to figure out why this is happening; it must be my
--	mod although I don't see how.  TODO figure out if it's a DF bug.
