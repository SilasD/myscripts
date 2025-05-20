local verbose = false

local penned = 0
local reassigned = 0
local raiders = 0

-- Sets used to cache data in order to avoid function calls.
local map_penid_to_pen = {}       -- by building.id
local map_pen_names_to_pen = {}   -- by building.name, wrapped with spaces.
local caged_or_chained_units = {} -- by unit.id
local war_animals_on_mission = {} -- by unit.id


local debugging = true


-- note: unlike normal printf, this ends the line even if '\n' is not used.
local function printf(...)
    print(string.format(...))
end


-- printf if verbose
local function vprintf(...)
    if not verbose then return; end
    printf(...)
end


-- This is basically debug-printf.
-- If a global or top-level local variable 'debugging' is false or does not exist, there is no output.
-- If 'debugging' is true, this uses dfhack.printerr() to both print to the console (in red),
--   and log to the stderr.log file.  
-- The debug library is used to print both the filename and the function name.
local current_script_name = dfhack.current_script_name()
local function dprintf(format, ...)
    if not debugging then return; end

    -- Lua 5.3 Reference Manual 4.9 lua_Debug and lua_getinfo.
    --   2 = immediate caller's frame, nt = only fill in name, namewhat, and istailcall.
    local info = debug.getinfo(2, 'nt')
	    or { namewhat = "{no debug info}", name = "{no function}", istailcall = false }
    -- we assume that info always contains details about a function, because that's what we asked for.
    -- Lua 5.3 Reference Manual 3.4.10:
    --   "However, a tail call erases any debug information about the calling function."
    info.name = info.name or ( (info.istailcall) and "{tail call}" or "{no function}" )

    dfhack.printerr(string.format("%s %s(): " .. format, current_script_name, info.name, ...))
end


function populate_caches()

  -- populate map_penid_to_pen[] and map_pen_names_to_pen[]
  for _,pen in ipairs(df.global.world.buildings.other.ZONE_PEN) do
    if pen:getType() == df.building_type.Civzone and pen.type == df.civzone_type.Pen then   -- sanity test
      map_penid_to_pen[pen.id] = pen

      if pen.name ~= '' then
        -- use spaces as a word seperator.  (workaround for lack of regex \w .)
        map_pen_names_to_pen[string.format(" %s ", pen.name)] = pen
      end
    end
  end
  --printall(map_pen_names_to_pen)

  
  -- populate caged_or_chained_units[]
  -- animals assigned to cages or chains should not be considered.
  --    (animals not assigned but currently caged or chained should be considered,
  --    so this Set is poorly named.)
  for _,cage in ipairs(df.global.world.buildings.other.CAGE) do
    for _,id in ipairs(cage.assigned_units) do
      caged_or_chained_units[id] = true
    end
  end
  for _,chain in ipairs(df.global.world.buildings.other.CHAIN) do
    if chain.assigned ~= nil then   -- hint:df.unit
      caged_or_chained_units[chain.assigned.id] = true
    end
  end
  --printall(caged_or_chained_units)

  -- TODO war animals

end


function remove_current_pen(unit)

  -- walk every pen, removing this unit's assignments if they exist.
  --    (there should be at most one, but in a previous version of this script,
  --    I had a bug that didn't remove assignments in unnamed pens.)
  for _,pen in ipairs(df.global.world.buildings.other.ZONE_PEN) do
    if pen:getType() == df.building_type.Civzone and pen.type == df.civzone_type.Pen then   -- sanity test

      for j = #(pen.assigned_units)-1, 0, -1 do  -- walk it backwards so we can :erase()
        if pen.assigned_units[j] == unit.id then
          pen.assigned_units:erase(j)
        end
        -- don't early-out just in case there's spurious duplicates.
      end   -- foreach assigned units
    end   -- if
  end   -- foreach pen

  -- then remove the unit's assigned pen(s), if any.
  for i = #(unit.general_refs)-1, 0, -1 do  -- walk it backwards so we can :erase()
    if unit.general_refs[i]:getType() == df.general_ref_type.BUILDING_CIVZONE_ASSIGNED then
      unit.general_refs:erase(i)
    end
  end
end


function add_pen(unit, pen)
  gen_ref = df.general_ref_building_civzone_assignedst:new()
  gen_ref.building_id = pen.id
  unit.general_refs:insert('#', gen_ref)

  -- DONT: use utils.insert_sorted() ?  use utils.insert_or_update() ?
  --    A: No.  pen.assigned_units[] is not a sorted list.
  --    so we're just going to assume that the id is not already in the pen.assigned_units list.
  -- TODO: should use utils.linear_index() at least.
  pen.assigned_units:insert('#', unit.id)
end


-- TODO use real argument parsing.
if     ({...})[1] == '-v' 
    or ({...})[1] == '-verbose' 
    or ({...})[1] == '--verbose' 
    or ({...})[1] == 'verbose' 
then
  verbose = true
end


populate_caches()


-- TODO this is too complex.  refactor.
for _,unit in ipairs(df.global.world.units.active) do 

  -- TODO: I would like to ensure the unit is an _animal_, not sapient.
  local doit = dfhack.units.isFortControlled(unit) 
        and not dfhack.units.isCitizen(unit) 
        and not unit.flags1.left
	and not unit.flags2.killed
	and not caged_or_chained_units[unit.id]
	and not war_animals_on_mission[unit.id]


  -- note that we intentionally allow penning animals that are not .isActive() (e.g. incoming).

  if doit then

      local race = df.creature_raw.find(unit.race)
      local search  = 'XXXDONOTMATCHXXX'   -- it would be really nice if string.find() had alternation;
      local search2 = 'XXXDONOTMATCHXXX'   --    instead I have to use two separate string.find() calls.
                                           -- TODO maybe: search could be made into a list with all
                                           --    search terms.  that would avoid the clumsy search2.

      if unit.name.nickname ~= '' then
        search = unit.name.nickname
      elseif unit.custom_profession ~= '' then
        search = unit.custom_profession
      elseif race ~= nil then   -- should always be a valid test.
        search  = race.name[0]  -- singular race name, e.g. chicken.
        search2 = race.name[1]  -- plural race name, e.g. chickens.
      end
      -- use spaces as a word seperator.  (workaround for lack of regex \w .)
      search  = string.format(" %s ", search)
      search2 = string.format(" %s ", search2)
      --print(unit.id, search, search2)

      -- TODO: currently this does not test more general search terms if a specific one fails.
      --   e.g. if 'Fido' fails, 'dog' is not checked.  Should it fall back?

      -- TODO: it might be nice to allow multiple pens to have the same matches, and choose
      --   semi-randomly between them, perhaps with the % modulo operator on the unit.id.
      --   However, that would mean that a pen named 'Squad1' and a pen named 'dog' would
      --   split the animals between them, which is not desirable.

      for penname,pen in pairs(map_pen_names_to_pen) do
        -- is one of the search terms in the pen name?
        if string.find(penname, search) or string.find(penname, search2) then

          -- for diagnostic reporting only
          if not string.find(penname, search) then search = search2; end

          --vprintf("match: %s, %s", penname, search)

          local assigned = dfhack.units.getGeneralRef(unit, df.general_ref_type.BUILDING_CIVZONE_ASSIGNED)
          if assigned and assigned.building_id == pen.id then
            --vprintf("animal %d (%s) already properly assigned", unit.id, search)
            -- do nothing
          elseif assigned and assigned.building_id ~= pen.id then
            -- DONE: is this the correct action?  this will prevent e.g. cats from being assigned to
            --    specific zones for vermin hunting.  Unless you give them nicknames.
            --    A: yes, this is the correct action.
            vprintf("removing animal %d (%s) from pen %d", unit.id, search, assigned.building_id)
            remove_current_pen(unit)
            assigned = nil  -- override to trigger the next if/then.
            reassigned = reassigned + 1
          end

          -- note: we cannot make this if/then an /else of the previous if/then because we may change
          --    assigned in the previous if/then.
          if assigned == nil then
            vprintf("adding animal %d (%s) to pen %d", unit.id, search, pen.id)
            add_pen(unit, pen)
            penned = penned + 1
          end
          break   -- we're done; early-out.

        end   -- if search term is in the pen name
      end   -- for all pens

  end   -- if doit
end   -- for all units


if reassigned ~= 0 then
  printf("%d %s removed from pens for reassignment.", reassigned, (reassigned == 1 and 'animal' or 'animals'))
end
if penned ~= 0 then 
  printf("%d %s assigned to pens.", penned, (penned == 1 and 'animal' or 'animals'))
end
if raiders ~= 0 then
  printf("%d on-mission war %s removed from pens.", raiders, (raiders == 1 and 'animal' or 'animals'))
end
