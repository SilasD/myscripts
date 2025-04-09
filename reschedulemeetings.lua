function reschedulemeetings ()
  local site_entity = df.global.world.world_data.active_site [0].entity_links [1].entity_id

  for i, unit in ipairs (df.global.world.units.active) do
    if unit.meeting.target_entity ~= -1 then
		dfhack.println (dfhack.TranslateName (dfhack.units.getVisibleName (unit)))
	    dfhack.println (site_entity)
	  if unit.meeting.target_role ~= -1 then
		if df.global.world.entities.all [site_entity].assignments_by_type [unit.meeting.target_role] ~= nil and
		   unit.meeting.target_entity ~= df.global.world.entities.all [site_entity].assignments_by_type [unit.meeting.target_role] [0].histfig2 then
		   dfhack.println ("Replacing meeting receiver " .. 
		                    dfhack.TranslateName (dfhack.units.getVisibleName (df.global.world.units.active [unit.meeting.target_entity])) .. 
		                   " for unit " .. 
						   dfhack.TranslateName (dfhack.units.getVisibleName (unit)) .. " with " .. 
						   dfhack.TranslateName (dfhack.units.getVisibleName 
						   (df.global.world.entities.all [site_entity].assignments_by_type [unit.meeting.target_role]) [0].histfig2))
--		   unit.meeting.target_entity = df.global.world.entities.all [site_entity].assignments_by_type [unit.meeting.target_role] [0].histfig2		  
		end
	  end
    end	  
  end
end

reschedulemeetings ()