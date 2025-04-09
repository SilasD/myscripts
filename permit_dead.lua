--  Adds dead civs to the pre embark civ list to allow you to embark as them.
--
--[===[

permit_dead
=======
--  This script is started on the embark screen and causes dead playable civs to appear on the list
--  of civs you can select when you embark (on the civ tab screen). Struggling civs culled by DF from
--  the list are not added. This script can be used stand alone or be used in conjunction with slabciv
--  to pick up those civs put to rest by slabciv.

]===]
function permit_dead ()
  local histfigs
  local pops
  local start_id
  local found
  
  if not df.global.gview.view or
     not df.global.gview.view.child or
     not df.global.gview.view.child.available_civs then
    dfhack.color (COLOR_RED)
    dfhack.print("Error: This script is to be run on the pre embark screen")
    dfhack.color(COLOR_RESET)
    dfhack.println()
    return
  end
   
  for i, entity in ipairs (df.global.world.entities.all) do
    if entity.type == df.historical_entity_type.Civilization and
       entity.entity_raw.flags.CIV_CONTROLLABLE then
      histfigs = 0
      pops = 0
            
      for k, pop in ipairs (df.global.world.entity_populations) do
        if pop.civ_id == i then
          for l, count in ipairs (pop.counts) do
            pops = pops + count
          end
        
          break
        end
      end

      start_id = 0
   
      for k, histfig in ipairs (entity.histfig_ids) do
        for l = start_id, #df.global.world.history.figures - 1 do
          if df.global.world.history.figures [l].id == histfig then
            start_id = l
          
            if df.global.world.history.figures [l].died_year == -1 then
              histfigs = histfigs + 1
            end
          
            break
          end
        end
      end
    
      if histfigs == 0 and
         pops == 0 then
        found = false
    
        for k, civ in ipairs (df.global.gview.view.child.available_civs) do
          if civ == entity then
            found = true
            break
          end
        end
    
        if not found then
          df.global.gview.view.child.available_civs:insert ('#', entity)
          dfhack.println ("Permitting embark as " .. dfhack.TranslateName (entity.name, true))
        end
      end
    end
  end
end

permit_dead ()