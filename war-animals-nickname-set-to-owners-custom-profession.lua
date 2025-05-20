for _,u in ipairs(df.global.world.units.active) do 

  -- TODO consider using dfhack.units.isPet(unit)
  if	dfhack.units.isFortControlled(u) 
	and not dfhack.units.isCitizen(u) 
	and dfhack.units.isActive(u)  -- this filters out incoming units.
	and u.profession == df.profession.TRAINED_WAR
	and not u.flags1.inactive	-- this filters out units that are not avtively on the map.
	and not u.flags2.killed
	and not u.flags1.left
	and not u.flags1.incoming	-- this also filters out incoming units.
  then

    -- TODO: At some point, relationship_ids.Pet changed to relationship_ids.PetOwner .
    --    make the script work with both.
    local owner = (u.relationship_ids.PetOwner ~= -1) and df.unit.find(u.relationship_ids.PetOwner) or nil

    local customprof = (owner) and owner.custom_profession or ''

    if (owner) and customprof ~= '' then

      if not owner.flags1.inactive
	and not owner.flags2.killed
	-- TODO other conditions?
      then
        dfhack.units.setNickname(u, customprof)


      -- deal with dead owners by clearing the nickname and setting owner to -1.
      -- TODO: is removing the owner the right thing to do?
      -- TODO: why am I check for not .killed ?  Shouldn't I check for .killed ?
      elseif owner.flags1.inactive
	and not owner.flags2.killed
      then
        dfhack.units.setNickname(u, '')
	u.relationship_ids.PetOwner = -1
      end
    end

  end
end
