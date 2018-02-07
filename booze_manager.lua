--  This script is intended to try to keep the number of volumes of plant based booze of each
--  kind close to the cut_off_volume variable value. It relies on a number of assumptions and
--  pre conditions:
--  - The player has created one farm plot for each booze producing shrub and assigned it to
--    be planted in a season. Once there the script will detect the farm plot and name it
--    (which is not displayed by DF), to keep track of which plots belong to each crop even
--    when fallow.
--    The script will then enable/disable production as required. Note that the script does
--    not detect if the initial assignment was done via hacking to specify a crop that is
--    not allowed in the plot's biome. In fact, no biome checking is done by the script.
--  - The script manages only one farm plot per crop. The rest are ignored, as are plots
--    for non booze producing crops (such as e.g. papyrus).
--  - Farm plots are managed to enable production during legal seasons (which means all
--    of them for vanilla surface crops, but limited seasons for subsurface ones), but tries
--    to produce only during spring if possible to allow for the author's preference
--    of having summer as a catch up, autumn as a "wrap up" season and winter for R&R.
--  - The script relies on the user to set up gathering zones around booze producing fruit
--    trees and name these such that the beginning of the zone name matches the tree name.
--    The name match is case insensitive, but beware of curve balls such as "DATE_PALM".
--  - Since some fruit trees have a low yield, the script manages all the matching zones
--    for fruit trees. All zones matching a fruit tree are enabled/disabled as a collective.
--  - The script has no memory, so adding and removing farm plots and gathering zones should
--    be treated as during the initial script execution, i.e. naming of farm plots. The
--    "memory" is thus in the farm plot names and the zone names.
--  - The script does not deal with the actual booze production, only with the source plant
--    production. It's still left to the player to juggle thread/booze production for dual
--    use plants, and to make sure the plants are actually processed.
--  - The script looks at plant stocks and converts those into booze equivalents using a
--    yield factor of 4, allowing for some produce nibbling by the dorfs.
--
--  The script is intended for fairly low pop fortresses, as popular drinks might run out
--  in higher pop fortresses. Given its yearly cycle target environment, it ought to be
--  run towards the end of the year so production is set up for the coming year, but no
--  harm (and very little benefit, as it does not make use of what the current season is)
--  should come from running it more often.
--
--  The script output:
--  - Enabling production (in green), and disabling production (in light red), when present.
--  - A list of all booze production plants in the "random" order they're found in the raws.
--    It shows plot/zone presence, plant name, and booze and plant stock counts (the latter
--    is the actual stock, not booze equivalents).
--  - This is color coded as:
--    - Green: Plot/zone available and production is enabled.
--    - Yellow: Plot/zone missing. Stocks are listed, but do not affect the color.
--    - Default: Plot/zone available, but production is disabled as sufficient stocks are
--      available.
--
function booze_manager ()
  local cut_off_volume = 50
  local booze_plants = {}
  local farm_plots = {}
  local zones = {}
  local plant_stock = {}
  local booze
  
  for i, plant in ipairs (df.global.world.raws.plants.all) do
    if plant.flags.DRINK then
      table.insert (booze_plants, {index = i, plant = plant, plot = -1, zone = false, volume = 0})
    end
  end
  
  for i, building in ipairs (df.global.world.buildings.all) do
    if building._type == df.building_farmplotst then
      if building.name == "" then  --  Not allocated
        for k, plant_id in ipairs (building.plant_id) do
          if plant_id ~= -1 then
            for l, plant in ipairs (booze_plants) do
              if plant.index == plant_id then
                if plant.plot == -1 then
                  plant.plot = i
                  building.name = plant.plant.id
                  table.insert (farm_plots, {index = i, plot = building})
                end
                  
                break
              end
            end
              
            break
          end
        end
      
      else
        for k, raw in ipairs (df.global.world.raws.plants.all) do
          if building.name == raw.id then
            for l, plant in ipairs (booze_plants) do
              if plant.index == k then
                if plant.plot == -1 then
                  plant.plot = i
                end

                break
              end
            end
            
            break
          end
        end
               
        table.insert (farm_plots, {index = i, plot = building})
      end
    
    elseif building._type == df.building_civzonest then
      if building.zone_flags.gather then
        for k, plant in ipairs (booze_plants) do
          if building.name:len() >= plant.plant.id:len() and
             string.sub (building.name:upper (), 1, plant.plant.id:len()) == plant.plant.id then
            plant.zone = true 
            table.insert (zones, {index = i, zone = building, plant = plant.plant.id})
             
          end
        end
      end
    end
  end
  
  for i, drink in ipairs (df.global.world.items.other.DRINK) do
    local mat_info = dfhack.matinfo.decode (drink.mat_type, drink.mat_index)
    if mat_info.plant ~= nil then  --  Need to weed out animal based drinks.
      for k, plant in ipairs (booze_plants) do
        if mat_info.plant == plant.plant then
          plant.volume = plant.volume + drink.stack_size
        end
      end
    end
  end
  
  --  Collect boozable plants
  --
  for i, plant in ipairs (df.global.world.items.other.PLANT) do
    local material = dfhack.matinfo.decode (plant.mat_type, plant.mat_index)

    for i = 0, #material.material.reaction_product.id - 1 do
      if material.material.reaction_product.id [i].value == "DRINK_MAT" then        
        if plant_stock [plant.mat_index] then
          plant_stock [plant.mat_index] = plant_stock [plant.mat_index] + plant.stack_size
        else
          plant_stock [plant.mat_index] = plant.stack_size
        end
        
        break
      end
    end
  end
    
  --  Collect boozable fruit
  --
  for i, plant in ipairs (df.global.world.items.other.PLANT_GROWTH) do
    local material = dfhack.matinfo.decode (plant.mat_type, plant.mat_index)

    for i = 0, #material.material.reaction_product.id - 1 do
      if material.material.reaction_product.id [i].value == "DRINK_MAT" then        
        if plant_stock [plant.mat_index] then
          plant_stock [plant.mat_index] = plant_stock [plant.mat_index] + plant.stack_size
        else
          plant_stock [plant.mat_index] = plant.stack_size
        end
        
        break
      end
    end
  end
  
  for i, entry in ipairs (booze_plants) do
    if plant_stock [entry.index] then
      booze = entry.volume + plant_stock [entry.index] * 4  --  Yield is 5, but assume some nibbling
      
    else
      booze = entry.volume
    end
    
    if booze >= cut_off_volume then  --  Stop production
      if entry.plot ~= -1 then
        for k, plant_id in ipairs (df.global.world.buildings.all [entry.plot].plant_id) do
          if plant_id ~= -1 then
            df.global.world.buildings.all [entry.plot].plant_id [k] = -1
            dfhack.color (COLOR_LIGHTRED)
            dfhack.println ("Disabling production of " ..  entry.plant.name)
            dfhack.color (COLOR_RESET)
          end
        end
                
      elseif entry.zone then
        for k, zone in ipairs (zones) do  --  There may be more than one zone for some trees, so no "break"
          if zone.plant == entry.plant.id and
             zone.zone.gather_flags.pick_trees then
            zone.zone.gather_flags.pick_trees = false
            zone.zone.gather_flags.gather_fallen = false
            dfhack.color (COLOR_LIGHTRED)
            dfhack.println ("Disabling production of " ..  entry.plant.name)
            dfhack.color (COLOR_RESET)
          end
        end        
      end
      
    else  --  Start production
      if entry.plot ~= -1 then
        if entry.plant.flags.SPRING then
--          if entry.plant.flags.SUMMER then
--            if entry.volume < 50 then  --  "Great shortage"
--              df.global.world.buildings.all [entry.plot].plant_id [0] = entry.index
--              df.global.world.buildings.all [entry.plot].plant_id [1] = entry.index
--            elseif (entry.index % 2) == 1 then
--             --  Spread "randomly" between spring and summer when possible
--              df.global.world.buildings.all [entry.plot].plant_id [1] = entry.index
--            else 
--              df.global.world.buildings.all [entry.plot].plant_id [0] = entry.index
--            end
--            
--          else
--            df.global.world.buildings.all [entry.plot].plant_id [0] = entry.index
--          end
          if df.global.world.buildings.all [entry.plot].plant_id [0] ~= entry.index then
            df.global.world.buildings.all [entry.plot].plant_id [0] = entry.index
            dfhack.color (COLOR_LIGHTGREEN)
            dfhack.println ("Enabling production of " ..  entry.plant.name)
            dfhack.color (COLOR_RESET)
          end
          
        elseif entry.plant.flags.SUMMER then
          if df.global.world.buildings.all [entry.plot].plant_id [1] ~= entry.index then
            df.global.world.buildings.all [entry.plot].plant_id [1] = entry.index
            dfhack.color (COLOR_LIGHTGREEN)
            dfhack.println ("Enabling production of " ..  entry.plant.name)
            dfhack.color (COLOR_RESET)
          end
          
        elseif entry.plant.flags.AUTUMN then
          if df.global.world.buildings.all [entry.plot].plant_id [2] ~= entry.index then
            df.global.world.buildings.all [entry.plot].plant_id [2] = entry.index
            dfhack.color (COLOR_LIGHTGREEN)
            dfhack.println ("Enabling production of " ..  entry.plant.name)
            dfhack.color (COLOR_RESET)
          end
          
        elseif entry.plant.flags.WINTER then
          if df.global.world.buildings.all [entry.plot].plant_id [3] ~= entry.index then
            df.global.world.buildings.all [entry.plot].plant_id [3] = entry.index
            dfhack.color (COLOR_LIGHTGREEN)
            dfhack.println ("Enabling production of " ..  entry.plant.name)
             dfhack.color (COLOR_RESET)
         end
          
        else
          dfhack.println ("Error: plant has no growth seasons: " .. entry.plant.id)
        end
        
      elseif entry.zone then
        for k, zone in ipairs (zones) do  --  There may be more than one zone for some trees, so no "break"
          if zone.plant == entry.plant.id then
            if not zone.zone.gather_flags.pick_trees then
              zone.zone.gather_flags.pick_trees = true
              zone.zone.gather_flags.gather_fallen = true
              --  Might want to set this only for low yield trees, to reduce the bycatch volume.
             dfhack.color (COLOR_LIGHTGREEN)
             dfhack.println ("Enabling production of " ..  entry.plant.name)
            dfhack.color (COLOR_RESET)
            end
          end
        end
      end
    end
  end
  
  dfhack.println ()
  dfhack.println ("Status for booze production")
  for i, entry in ipairs (booze_plants) do
    local plants_available = 0
    if plant_stock [entry.index] then
      plants_available = plant_stock [entry.index]    
    end
         
    if entry.plot == -1 and
       not entry.zone then
      dfhack.color (COLOR_YELLOW)
      dfhack.println ("Plot/zone missing for " .. entry.plant.name, "Booze available: " .. tostring (entry.volume), "Plants available:" .. tostring (plants_available))
      dfhack.color (COLOR_RESET)

    else
      if entry.plot ~= -1 then
        for k, season in pairs (df.global.world.buildings.all [entry.plot].plant_id) do
          if season ~= -1 then
            dfhack.color (COLOR_LIGHTGREEN)
            break
          end
        end
      
      else
        for k, zone in ipairs (zones) do
          if zone.plant == entry.plant.id then
            if zone.zone.gather_flags.pick_trees then
            dfhack.color (COLOR_LIGHTGREEN)
            break
            end
          end
        end
      end
      
      dfhack.println ("Plot/zone present for " .. entry.plant.name, "Booze available: " .. tostring (entry.volume), "Plants available:" .. tostring (plants_available))
      dfhack.color (COLOR_RESET)
    end
  end

if false then  --  suppress this for the time being.
  dfhack.println ()
  dfhack.println ("Farm plots:")
  
  for i, entry in ipairs (farm_plots) do
    dfhack.println (entry.index, entry.plot.name)
  end
  
  dfhack.println ()
  dfhack.println ("Gathering zones:")
  
  for i, entry in ipairs (zones) do
    dfhack.println (entry.index, entry.zone.name, entry.plant)
  end
end
end

booze_manager()