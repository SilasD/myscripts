--  Ensures civs that die during worlgen history actually become dead civs rather than struggling ones.
--  Started before generating the world.
--[===[

slabciv
=======
--  This script is started before you starts to generate a world and runs while the world is generated.
--  Controllable (dwarven) civs that ought to be dead but refuse to realize it are slabbed to put them
--  to rest. Intended to be used in conjunction with the permit_dead script to allow you to embark as
--  those civs, but works "naturally" if all controllable civs are dead.
--  A civ is declared dead if it hasn't contained a histfig for 100 years and no generic population
--  changes have occured for 100 years. Thus, the script is useless if world gen is less than 100 years.

]===]
function slabciv ()
  if dfhack.isMapLoaded () then
    dfhack.color (COLOR_RED)
    dfhack.print("Error: This script is used for world generation manipulation and does not allow a map to be loaded")
    dfhack.color(COLOR_RESET)
    dfhack.println()
    return
  end

  local civ_state = {}
   
  local state = df.global.world.worldgen_status.state
  local active = not df.global.world.worldgen_status.placed_caves
  local finished_prehistory = false
  local century = 0
  local previous_year = 0
  local current_year
 
  local num_rejects = df.global.world.worldgen_status.num_rejects

  function callback ()
    if dfhack.isMapLoaded () then
      dfhack.println ("A map has been loaded, so slabciv terminates now.")
      return
    end
   
    if state > df.global.world.worldgen_status.state or
      num_rejects ~= df.global.world.worldgen_status.num_rejects then
      num_rejects = df.global.world.worldgen_status.num_rejects
      active = true
      state = df.global.world.worldgen_status.state
      finished_prehistory = false
      century = 0
      previous_year = 0
      dfhack.println ("Starting new run")
    end
   
    if active and df.global.world.worldgen_status.state == 9 then
      if not finished_prehistory and df.global.world.worldgen_status.finished_prehistory then
        finished_prehistory = true
      
        for i, entity in ipairs (df.global.world.entities.all) do
          if entity.type == df.historical_entity_type.Civilization and
             entity.entity_raw.flags.CIV_CONTROLLABLE then
            civ_state [i] = {entity_population_index = 0,
                             entity_population = 0,
                             entity_population_change_year = 1,
                             no_histfig_year = -1,
                             live_histfigs = 0,
                             slabbed = false}
         
            for k, pop in ipairs (df.global.world.entity_populations) do
              if pop.civ_id == i then
                civ_state [i].entity_population_index = k
            
                for l, count in ipairs (pop.counts) do
                  civ_state [i].entity_population = civ_state [i].entity_population + count
                end
            
                break
              end
            end

            local start_id = 0
         
            for k, histfig in ipairs (entity.histfig_ids) do
              for l = start_id, #df.global.world.history.figures - 1 do
                if df.global.world.history.figures [l].id == histfig then
                  found = true
                  start_id = l
             
                  if df.global.world.history.figures [l].died_year == -1 then
                    civ_state [i].live_histfigs = civ_state [i].live_histfigs + 1
                  end
             
                  break
                end
              end
            end
          end
        end
      end
    
      if finished_prehistory and df.global.world.worldgen_status.anon_4 < previous_year then
        century = century + 1
      end
   
      previous_year = df.global.world.worldgen_status.anon_4
      current_year = century * 100 + previous_year + 1
    
      for i, civ in pairs (civ_state) do
        local population = 0
        for k, count in ipairs (df.global.world.entity_populations [civ.entity_population_index].counts) do
          population = population + count
        end
      
        if population ~= civ.entity_population then
          civ.entity_population_change_year = current_year
          civ.entity_population = population
        end
      
        local histcount = 0
        local start_id = 0   
         
        for k, histfig in ipairs (df.global.world.entities.all [i].histfig_ids) do
          for l = start_id, #df.global.world.history.figures - 1 do
            if df.global.world.history.figures [l].id == histfig then
              start_id = l
             
              if df.global.world.history.figures [l].died_year == -1 then
                histcount = histcount + 1
              end
             
              break
            end
          end
        end
                  
        if histcount ~= 0 then
          civ.no_histfig_year = -1  --  To account for generation of histfig.
       
        elseif histcount == 0 and
           civ.live_histfigs ~= 0 then
          civ.no_histfig_year = current_year
        end
      
        civ.live_histfigs = histcount
      
        if civ.live_histfigs == 0 and
           not civ.slabbed and
           current_year - civ.no_histfig_year >= 100 and
           current_year - civ.entity_population_change_year >= 100 and  --  It seems the callback isn't triggered exactly on every year.
           civ.entity_population ~= 0 then
          dfhack.println ("Year " .. tostring (current_year) .. ": " ..
                          df.global.world.entities.all .entity_raw.translation ..
                          " civ " .. tostring (i) .. " lost last histfig in " ..
                          tostring (civ.no_histfig_year) ..
                          " and has had no pop changes for 100 years. Reported pop: " ..
                          tostring (civ.entity_population) ..
                          ". Slabbing it.")
          civ.slabbed = true
                   
          for k, count in ipairs (df.global.world.entity_populations [civ.entity_population_index].counts) do
            df.global.world.entity_populations [civ.entity_population_index].counts [k] = 0
          end
        end
      end
         
      if current_year == df.global.world.worldgen.worldgen_parms.end_year then
        dfhack.println ()
        dfhack.println ("End report")
        for i, civ in pairs (civ_state) do
          dfhack.print (df.global.world.entities.all [i].entity_raw.translation ..
                        " civ " .. tostring (i) .. " histfig count: " ..
                        tostring (civ.live_histfigs) .. ", population: " ..
                        tostring (civ.entity_population))
       
          if civ.no_histfig_year ~= -1 then
            dfhack.print (" no histfig year: " .. tostring (civ.no_histfig_year) ..
                          " last pop change year: " .. tostring (civ.entity_population_change_year))
          end
       
          if civ.slabbed then
            dfhack.println (" SLABBED " .. dfhack.TranslateName (df.global.world.entities.all [i].name, true))
          elseif civ.entity_population == 0 and civ.live_histfigs == 0 then
            dfhack.println (" Natural death " .. dfhack.TranslateName (df.global.world.entities.all [i].name, true))
          else
            dfhack.println ()
          end
        end
      
        dfhack.println ("slabciv is now done")
      else
        dfhack.timeout (1, 'frames', callback)
      end
    
    else
      dfhack.timeout (1, 'frames', callback)
    end
  end
  
  local started = dfhack.timeout (1, 'frames', callback)
  dfhack.println ("slabciv is now started.")
end

slabciv ()
