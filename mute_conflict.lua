local help = [====[

mute_conflict
=============
Attempts to put a damper on a conflict the selected unit is involved in by reducing its level
to a Brawl. Note that there are checks in place to try to detect 'real' conflict and not
tamper with those, as the effects are even less predictable than on a normal lethal non lethal
fight.
]====]

function mute_conflict (arg)
  if arg and (arg:match ('help') or arg:match ('?')) then
    print (help)
    return
  end

  local unit = dfhack.gui.getSelectedUnit (true)

  if not unit then
    qerror ("This script acts on a selected unit")
  end
  
  local activity
  
  for i, act in ipairs (unit.activities) do
    activity = df.activity_entry.find (act)
    
    if activity and activity.type == df.activity_entry_type.Conflict then
      for m, event in ipairs (activity.events) do  
        for k, side in ipairs (event.sides) do
          for l, unit_2_id in ipairs (side.unit_ids) do
            local unit_2 = df.unit.find (unit_2_id)
            if unit_2 then
              if unit_2.flags1.active_invader then
                qerror ("Sorry, at least one of the involved is an active invader, indicating a 'real' conflict")
            
              elseif unit_2.flags1.hidden_in_ambush then
                qerror ("Sorry, at least one of the involved is hidden in ambush, indicating a 'real' conflict")
            
              elseif unit_2.flags1.invader_origin then
                qerror ("Sorry, at least one of the involved is of invader origin, indicating a 'real' conflict")
            
              elseif unit_2.flags1.hidden_ambusher then
                qerror ("Sorry, at least one of the involved is a hidden ambusher, indicating a 'real' conflict")
            
              elseif unit_2.flags1.invades then
                qerror ("Sorry, at least one of the involved is currently invading, indicating a 'real' conflict")
            
              elseif unit_2.flags2.visitor_uninvited then
                qerror ("Sorry, at least one of the involved is an uninvited visitor, indicating a 'real' conflict")        
              end
            end
          
            if side.enemies [0].conflict_level < df.conflict_level.Lethal then
              qerror ("This doesn't seem to be a serious conflict: " .. df.conflict_level [side.enemies [0].conflict_level])
            end
          end
        end
        
        for k, side in ipairs (event.sides) do
          side.enemies [0].conflict_level = df.conflict_level.Brawl
        end
        
        dfhack.println ("Deescalated a conflict to a mutual Brawl")        
        return
      end
    end
  end
  
  qerror ("Failed to find a conflict this unit is involved in.")
end

mute_conflict (...)