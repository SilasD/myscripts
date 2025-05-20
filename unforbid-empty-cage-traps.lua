-- unforbids cage traps which are not loaded.

function printf(...)
  print(dfhack.df2console(string.format(...)))
end


local traps_unforbidden = 0
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
      if (not has_cage) and (item._type == df.item_trappartsst) then
        if item.flags.forbid == true then
          item.flags.forbid = false
          changed = 1
        end
      end
    end
    traps_unforbidden = traps_unforbidden + changed
  end
end


if traps_unforbidden > 0 then
  printf("%d empty %s unforbidden.",
        traps_unforbidden, 
        (traps_unforbidden == 1) and 'cage trap' or 'cage traps'
  )
end
