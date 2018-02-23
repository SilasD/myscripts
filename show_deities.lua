function show_deities ()
  local deities = {}

  local my_civ = df.global.world.world_data.active_site [0].entity_links [0].entity_id
  
  for i, entity in ipairs (df.global.world.entities.all [my_civ].unknown1b.deities) do
    table.insert (deities, {entity, 0, false})
  end
  
  for i, unit in ipairs (df.global.world.units.all) do
    if unit.civ_id == my_civ and
       not unit.flags2.visitor and
       unit.training_level == df.animal_training_level.WildUntamed then
      local hf = df.historical_figure.find (unit.hist_figure_id)
       
      for k, histfig_link in ipairs (hf.histfig_links) do
        if histfig_link._type == df.histfig_hf_link_deityst then
          local found = false
          
          for l, entry in ipairs (deities) do
            if histfig_link.target_hf == entry [1] then
              entry [2] = entry [2] + 1
              found = true
              break
            end
          end
          
          if not found then
            table.insert (deities, {histfig_link.target_hf, 1})
          end
        end
      end
    end
  end
  
  for i, building in ipairs (df.global.world.buildings.all) do
    if building._type == df.building_civzonest then
      if building.zone_flags.meeting_area and
         df.global.world.world_data.active_site [0].buildings [building.location_id]._type == df.abstract_building_templest then
        for k, deity in ipairs (deities) do
          if deity [1] == df.global.world.world_data.active_site [0].buildings [building.location_id].deity then
            deities [k] [3] = true
            break
          end
        end        
      end
    end
  end

  dfhack.println ("Civ deities:")
  
  for i = 1, #df.global.world.entities.all [my_civ].unknown1b.deities do
    if deities [i] [3] then
      dfhack.color (COLOR_LIGHTGREEN)
    else
      dfhack.color (COLOR_YELLOW)
    end
    
    local hf = df.historical_figure.find (deities [i] [1])
    dfhack.print (tostring (deities [i] [2]) .. " worshipers for " .. dfhack.TranslateName (hf.name, true))
    
      if hf.race ~= -1 then
        dfhack.print (" : " .. df.global.world.raws.creatures.all [hf.race].name [0])
      end
      
    for k, sphere in ipairs (hf.info.spheres) do
      dfhack.print (", " .. df.sphere_type [sphere])
    end
    
    dfhack.println ()
    
    dfhack.color (COLOR_RESET)
  end
  
  if #df.global.world.entities.all [my_civ].unknown1b.deities < #deities then
    dfhack.println ("Acquired deities:")
    
    for i = #df.global.world.entities.all [my_civ].unknown1b.deities + 1, #deities do
      if deities [i] [3] then
        dfhack.color (COLOR_LIGHTGREEN)
      else
        dfhack.color (COLOR_YELLOW)
      end
      
      local hf = df.historical_figure.find (deities [i] [1])
      
      dfhack.print (tostring (deities [i] [2]) .. " worshipers for " .. dfhack.TranslateName (hf.name, true))
    
      if hf.race ~= -1 then
        dfhack.print (" : " .. df.global.world.raws.creatures.all [hf.race].name [0])
      end
      
      if hf.info.spheres then
        for k, sphere in ipairs (hf.info.spheres) do
          dfhack.print (", " .. df.sphere_type [sphere])
        end
      end
      
      dfhack.println ()
      
      dfhack.color (COLOR_RESET)
    end
  end
end

show_deities ()