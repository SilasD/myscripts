local help = [====[
This script removes war animals from pens/pastures so that they can follow their owners on an off-site raid.
War animals that are not assigned to a raiding owner are not affected.

TODO: unchain and uncage relevant war animals.  Or at least warn about them.

TODO: experiment with assigning unit.idle_area* (pos, threshold=0, type=27 HeadForEdge) with the
squad's exit location.  See if it sticks or is overridden.

TODO: now that I know how, inspect all jobs to see if they are chaining, caging, or pasturing
a relevant war animal.

]====]

local verbose = false

local translateName = dfhack.TranslateName or dfhack.translation.translateName

function printf(...)
  print(dfhack.df2console(string.format(...)))
end

function vprintf(...)
  if verbose then
    printf(...)
  end
end


local squad_names = {}		-- sparse, maps squad_id to squad name or alias, cache for speed.
local raiding_units = {}	-- sparse, maps unit_id to squad_id.  also true/false 'is on a raid'.
local unit_names = {}		-- sparse, maps unit_id to (real) unit name, cache for speed.
				--   it would be nice to use getVisibleName(), but that 
				--   requires an existing unit, but raiding units do not exist
				--   in df.global.world.units.all after they leave the map.
				--   but it's okay, this is only for diagnostics.
				-- TODO wait what?  they MUST be in df.global.world.units.all !
				--   they are hf with associated unit !

local unpenned = 0


-- DONE: should I check the actual mission instead?  Now that I know how to find it.
--	A: no.  units only show up in the mission after they leave the map.
--	TODO: verify that.

-- search all squads, find all unit ids which are on raids.
--   (this works whether or not they've left the map.)
-- fills in squad_names[], raiding_units[], and unit_names[].
function find_raiders()
 -- TODO get the squadlist from plotinfo.group_id->.squads .
 for _, sq in ipairs(df.global.world.squads.all) do

  -- TODO is it true that order type squad_order_raid_sitest will always be the first and only order?
  -- maybe I should search every order?
  if sq.entity_id == df.global.plotinfo.group_id 
	and #sq.orders > 0 
	and sq.orders[0]:getType() == df.squad_order_type.RAID_SITE 
  then

    squad_names[sq.id] = (sq.alias ~= '') and sq.alias or translateName(sq.name, true)

    for _, position in ipairs(sq.positions) do
      local hf = df.historical_figure.find(position.occupant)
      if hf then
	local uid = hf.unit_id
	raiding_units[uid] = sq.id

	-- note that the 'uid' unit may not be in the units table.
	-- TODO they might not be in units.active, but they have to be in units.all
	-- TODO if the unit exists, it would be nice to use GetVisibleName() on it.
	unit_names[uid] = unit_names[uid] or translateName(hf.name, false)
      end
    end -- for all positions
  end -- if squad is ours and is on a mission
 end -- for all squads
end -- function


--printall(raiding_units)
--printall(squad_names)


-- now find all the pets that (a) have an owner on a raid and (b) are assigned to a pen:
function unpen_raiding_pets()
 for _, u in ipairs(df.global.world.units.active) do 

  -- note: it is not necessary to check dfhack.units.isFortControlled(u) because we know that
  --    any owners in our cache are part of our fort, because they are in one of our squads.
  -- TODO at some point, .relationship_ids.Pet changed name to .relationship_ids.PetOwner.
  --    make this script work with both.
  local owner = u.relationship_ids.PetOwner
  if (u.profession == df.profession.TRAINED_WAR and owner ~= -1 and raiding_units[owner]) then

    for i = #u.general_refs-1, 0, -1 do  -- walk the vector backwards so we can :erase() .
      if u.general_refs[i]:getType() == df.general_ref_type.BUILDING_CIVZONE_ASSIGNED then

	vprintf('Removing pen/pasture assignment for war animal %d %s because this animal ' ..
		'is assigned to raiding soldier %d %s, %s',
		u.id, 
		translateName(dfhack.units.getVisibleName(u), false),
		owner, 
		unit_names[owner],
		squad_names[raiding_units[owner]]
	)

	-- first, erase the owning building_civzonest's back-reference.
	--   building.assigned_units[] is a (NOT SORTED!) list of unit_id's.
	-- TODO potential optimization: cache mapping building_id -> building .
	local building = df.building.find(u.general_refs[i].building_id)
	if building then
	  -- walk the vector backwards so we can :erase() .
	  for j = #building.assigned_units-1, 0, -1 do
	    if building.assigned_units[j] == u.id then
	      building.assigned_units:erase(j)
	    end
	  end
	end

	-- finally, erase the pen/pasture general reference.
	u.general_refs:erase(i)

	unpenned = unpenned + 1
      end -- if civzone assigned
    end -- for all general refs
  end -- if war
 end -- for all units
end


find_raiders()
unpen_raiding_pets()

if unpenned > 0 then 
  printf("Removed %d war %s from pens/pastures.", 
	unpenned, 
	(unpenned == 1 and 'animal' or 'animals')
  )
end

