-- forbids cage traps which are loaded with a cage.  forbids the mechanism and the cage.

function printf(...)
  print(dfhack.df2console(string.format(...)))
end


local traps_forbidden = 0
for _,trap in ipairs(df.global.world.buildings.other.TRAP) do

  -- only look at cage traps.
  if trap._type == df.building_trapst and trap.trap_type == df.trap_type.CageTrap then 
    local has_cage = false

    -- first walk the building's contained items list looking for a cage.
    for _, item in ipairs(trap.contained_items) do
      local item = item.item
      if item._type == df.item_cagest then 
        has_cage = true
      end
    end

    -- second, walk the list again, marking trap parts and cages as forbidden.
    local changed = 0
    for _, item in ipairs(trap.contained_items) do
      local item = item.item
      if (has_cage) and (item._type == df.item_cagest or item._type == df.item_trappartsst) then
        if item.flags.forbid == false then
          item.flags.forbid = true
          changed = 1
        end
      end
    end
    traps_forbidden = traps_forbidden + changed
  end
end


if traps_forbidden > 0 then
  printf("%d loaded %s marked as forbidden.", 
        traps_forbidden, 
        (traps_forbidden == 1) and 'cage trap' or 'cage traps'
  )
end
