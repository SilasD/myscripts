local breakout_before_caves = false
local breakout_before_good_evil = false
local breakout_before_megabeasts = true
local breakout_before_other_beasts = false
local breakout_before_cave_pops = false
local breakout_before_cave_civs = false
local breakout_before_civs = false
local breakout_before_each_civ = false
local breakout_before_history = false
local breakout_at_year = false        --  or a specified year number to activate it
local breakout_every_x_years = false  --  or a specific interval number to activate it

function biodiversity ()
  local profile = 
    {BIOME_MOUNTAIN = false,
     BIOME_GLACIER = false,
     BIOME_TUNDRA = false,
     BIOME_SWAMP_TEMPERATE_FRESHWATER = false,
     BIOME_SWAMP_TEMPERATE_SALTWATER = false,
     BIOME_MARSH_TEMPERATE_FRESHWATER = false,
     BIOME_MARSH_TEMPERATE_SALTWATER = false,
     BIOME_SWAMP_TROPICAL_FRESHWATER = false,
     BIOME_SWAMP_TROPICAL_SALTWATER = false,
     BIOME_SWAMP_MANGROVE = false,
     BIOME_MARSH_TROPICAL_FRESHWATER = false,
     BIOME_MARSH_TROPICAL_SALTWATER = false,
     BIOME_FOREST_TAIGA = false,
     BIOME_FOREST_TEMPERATE_CONIFER = false,
     BIOME_FOREST_TEMPERATE_BROADLEAF = false,
     BIOME_FOREST_TROPICAL_CONIFER = false,
     BIOME_FOREST_TROPICAL_DRY_BROADLEAF = false,
     BIOME_FOREST_TROPICAL_MOIST_BROADLEAF = false,
     BIOME_GRASSLAND_TEMPERATE = false,
     BIOME_SAVANNA_TEMPERATE = false,
     BIOME_SHRUBLAND_TEMPERATE = false,
     BIOME_GRASSLAND_TROPICAL = false,
     BIOME_SAVANNA_TROPICAL = false,
     BIOME_SHRUBLAND_TROPICAL = false,
     BIOME_DESERT_BADLAND = false,
     BIOME_DESERT_ROCK = false,
     BIOME_DESERT_SAND = false,
     BIOME_OCEAN_TROPICAL = false,
     BIOME_OCEAN_TEMPERATE = false,
     BIOME_OCEAN_ARCTIC = false,
     BIOME_LAKE_TEMPERATE_FRESHWATER = false,
     BIOME_LAKE_TEMPERATE_BRACKISHWATER = false,
     BIOME_LAKE_TEMPERATE_SALTWATER = false,
     BIOME_LAKE_TROPICAL_FRESHWATER = false,
     BIOME_LAKE_TROPICAL_BRACKISHWATER = false,
     BIOME_LAKE_TROPICAL_SALTWATER = false,
     --BIOME_SUBTERRANEAN_WATER = false,
     --BIOME_SUBTERRANEAN_CHASM = false,
     --BIOME_SUBTERRANEAN_LAVA = false,
     GOOD = false,
     EVIL = false,
     SAVAGE = false}
  local map_height = df.global.world.world_data.world_height
  local pole = df.global.world.world_data.flip_latitude
  
  --============================================================
  
  function check_tropicality_no_poles_world (temperature)
    local is_possible_tropical_area_by_latitude = false
    local is_tropical_area_by_latitude = false
    
    --  No poles => Temperature determines tropicality
    --
    if temperature >= 75 then
      is_possible_tropical_area_by_latitude = true
    end
    is_tropical_area_by_latitude = temperature >= 85
    
    return is_possible_tropical_area_by_latitude, is_tropical_area_by_latitude
  end
  
  --============================================================
  
  function check_tropicality_north_pole_only_world (pos_y,
                                                    map_height)
    local v6
    local is_possible_tropical_area_by_latitude = false
    local is_tropical_area_by_latitude = false
    
    if map_height == 17 then
      v6 = pos_y * 16
      
    elseif map_height == 33 then
      v6 = pos_y * 8
      
    elseif map_height == 65 then
      v6 = pos_y * 4
      
    elseif map_height == 129 then
      v6 = pos_y * 2
    
    else
      v6 = pos_y
    end
    
    is_possible_tropical_area_by_latitude = v6 > 170
    is_tropical_area_by_latitude = v6 >= 200
    
    return is_possible_tropical_area_by_latitude, is_tropical_area_by_latitude
  end
  
  --============================================================
  
  function check_tropicality_south_pole_only_world (pos_y,
                                                    map_height)
    local v6 = map_height - pos_y - 1
    local is_possible_tropical_area_by_latitude = false
    local is_tropical_area_by_latitude = false
    
    if map_height == 17 then
      v6 = v6 * 16
      
    elseif map_height == 33 then
      v6 = v6 * 8
      
    elseif map_height == 65 then
      v6 = v6 * 4
      
    elseif map_height == 129 then
      v6 = v6 * 2
    
    else
      v6 = v6
    end
    
      is_possible_tropical_area_by_latitude = v6 > 170
    is_tropical_area_by_latitude = v6 >= 200
        
    return is_possible_tropical_area_by_latitude, is_tropical_area_by_latitude
  end
  
  --============================================================

  function check_tropicality_both_poles_world (pos_y,
                                               map_height)
    local v6
    local is_possible_tropical_area_by_latitude = false
    local is_tropical_area_by_latitude = false

    if pos_y < math.floor (map_height / 2) then
      v6 = 2 * pos_y
    
    else
      v6 = map_height + 2 * (math.floor (map_height / 2) - pos_y) - 1
      
      if v6 < 0 then
         v6 = 0
      end

      if v6 >= map_height then
        v6 = map_height - 1
      end
    end

    if map_height == 17 then
      v6 = v6 * 16
      
    elseif map_height == 33 then
      v6 = v6 * 8
      
    elseif map_height == 65 then
      v6 = v6 * 4
      
    elseif map_height == 129 then
      v6 = v6 * 2
    
    else
      v6 = v6
    end
    
    is_possible_tropical_area_by_latitude = v6 > 170
    is_tropical_area_by_latitude = v6 >= 200
    
    return is_possible_tropical_area_by_latitude, is_tropical_area_by_latitude
  end
  
  --============================================================
  
  function check_tropicality (pos_y,
                              map_height,
                              temperature,
                              pole)
    
    if pole == -1 then  --  No poles
      return check_tropicality_no_poles_world (temperature)
                                            
    elseif pole == 0 then  --  North pole
      return check_tropicality_north_pole_only_world (pos_y,
                                                      map_height)
                                                      
    elseif pole == 1 then  --  South pole
      return check_tropicality_south_pole_only_world (pos_y,
                                                      map_height)
                                                      
    elseif pole == 2 then  -- Both poles
      return check_tropicality_both_poles_world (pos_y,
                                                 map_height)

    else
      return false, false
    end
  end
  
  --============================================================
  
  function get_parameter_percentage (flip_latitude,
                                     pos_y,
                                     rainfall,
                                     map_height)
    local result
    local ypos = pos_y
    
    if flip_latitude == -1 then  -- No poles
      return 100
      
    elseif flip_latitude == 1 then --  South pole
      ypos = map_height - ypos - 1
      
    elseif flip_latitude == 2 then  --  North and South pole
      if ypos < math.floor (map_height / 2) then
        ypos = ypos * 2
      
      else
        ypos = map_height + 2 * (math.floor (map_height / 2) - ypos) - 1
        if ypos < 0 then
          ypos = 0
        end
        
        if ypos >= map_height then
          ypos = map_height - 1
        end
      end
    end
    
    local latitude
    if map_height == 17 then
      latitude = 16 * ypos
    elseif map_height == 33 then
      latitude = 8 * ypos
    elseif map_height == 65 then
      latitude = 4 * ypos
    elseif map_height == 129 then
      latitude = 2 * ypos
    else
      latitude = ypos
    end
    
    if latitude > 220 then
      return 100

    elseif latitude > 190 and
           latitude < 201 then
      return 0

    elseif latitude >= 201 then
      result = rainfall + 16 * (latitude - 207)

    else
      result = 16 * (184 - latitude) - rainfall
    end
    
    if result < 0 then
      return 0
    elseif result > 100 then
      return 100
    else
      return result
    end      
  end
  
  --============================================================
   
  function get_region_parameter (pos_y,
                                 rainfall,
                                 map_height)
  
    local result = 100
    
    if map_height > 65 then  --  Medium & Large worlds
      return get_parameter_percentage (pole,
                                       pos_y,
                                       rainfall,
                                       map_height)
    end
    
    return result
  end
  
  --============================================================
  

  function get_ocean_biome (is_tropical_area_by_latitude,
                            temperature)
    if is_tropical_area_by_latitude then
      return df.biome_type.OCEAN_TROPICAL
    elseif temperature <= -5 then
      return df.biome_type.OCEAN_ARCTIC
    else
      return df.biome_type.OCEAN_TEMPERATE
    end
  end
  
  --============================================================
  
  function get_desert_biome (drainage)
    if drainage < 33 then
      return df.biome_type.DESERT_SAND
    elseif drainage < 66 then
      return df.biome_type.DESERT_ROCK
    else
      return df.biome_type.DESERT_BADLAND
    end
  end
  
  --============================================================
  
  function get_biome_grassland (is_possible_tropical_area_by_latitude,
                                is_tropical_area_by_latitude,
                                rainfall,
                                pos_y,
                                map_height)
       
    if (is_possible_tropical_area_by_latitude and
        get_region_parameter(pos_y, rainfall, map_height) < 66) or
       is_tropical_area_by_latitude then
      return df.biome_type.GRASSLAND_TROPICAL
    else
      return df.biome_type.GRASSLAND_TEMPERATE
    end
  end
  
  --============================================================

  function get_biome_savanna (is_possible_tropical_area_by_latitude,
                              is_tropical_area_by_latitude,
                              rainfall,
                              pos_y,
                              map_height)

    if is_tropical_area_by_latitude or
       (is_possible_tropical_area_by_latitude and
        get_region_parameter (pos_y, rainfall, map_height) <= 6) then
      return df.biome_type.SAVANNA_TROPICAL
    else
      return df.biome_type.SAVANNA_TEMPERATE
    end       
  end
  
  
  --============================================================

  function get_biome_desert_or_grassland_or_savanna (is_possible_tropical_area_by_latitude,
                                                     is_tropical_area_by_latitude,
                                                     vegetation,
                                                     drainage,
                                                     rainfall,
                                                     pos_y,
                                                     map_height)
    if vegetation < 10 then
      return get_desert_biome (drainage)
      
    elseif vegetation < 20 then
       return get_biome_grassland (is_possible_tropical_area_by_latitude,
                                   is_tropical_area_by_latitude,
                                   rainfall,
                                   pos_y,
                                   map_height)
    
    else
      return get_biome_savanna (is_possible_tropical_area_by_latitude,
                                is_tropical_area_by_latitude,
                                  rainfall,
                                  pos_y,
                                map_height)
    end
  end
  
  
  --============================================================

  function get_biome_shrubland (is_possible_tropical_area_by_latitude,
                                is_tropical_area_by_latitude,
                                rainfall,
                                pos_y,
                                map_height)

    if is_tropical_area_by_latitude or
      (is_possible_tropical_area_by_latitude and
       get_region_parameter (pos_y, rainfall, map_height) < 66) then
      return df.biome_type.SHRUBLAND_TROPICAL
    else
      return df.biome_type.SHRUBLAND_TEMPERATE
    end
  end
  
  --============================================================

  function get_biome_marsh (is_possible_tropical_area_by_latitude,
                            is_tropical_area_by_latitude,
                            salinity,
                            rainfall,
                            pos_y,
                            map_height)
    if salinity < 66 then
      if is_tropical_area_by_latitude or
         (is_possible_tropical_area_by_latitude and
          get_region_parameter (pos_y, rainfall, map_height) < 66) then
        return df.biome_type.MARSH_TROPICAL_FRESHWATER
      else
        return df.biome_type.MARSH_TEMPERATE_FRESHWATER
      end
      
    else
      if is_tropical_area_by_latitude or
         (is_possible_tropical_area_by_latitude and
          get_region_parameter (pos_y, rainfall, map_height) < 66) then
        return df.biome_type.MARSH_TROPICAL_SALTWATER
      else
        return df.biome_type.MARSH_TEMPERATE_SALTWATER
      end
    end
  end
  
  --============================================================

  function get_biome_shrubland_or_marsh (is_possible_tropical_area_by_latitude,
                                         is_tropical_area_by_latitude,
                                         drainage,
                                         salinity,
                                         rainfall,
                                         pos_y,
                                         map_height)
    if drainage < 33 then
      return get_biome_marsh (is_possible_tropical_area_by_latitude,
                              is_tropical_area_by_latitude,
                              salinity,
                              rainfall,
                              pos_y,
                              map_height)
    else
      return get_biome_shrubland (is_possible_tropical_area_by_latitude,
                                  is_tropical_area_by_latitude,
                                  rainfall,
                                  pos_y,
                                  map_height)
    end
  end
  
  --============================================================

  function get_biome_forest (is_possible_tropical_area_by_latitude,
                             is_tropical_area_by_latitude,
                             rainfall,
                             temperature,
                             pos_y,
                             map_height)
    local parameter = get_region_parameter (pos_y, rainfall, map_height)
    
    if is_possible_tropical_area_by_latitude then
      if (parameter < 66 or
          is_tropical_area_by_latitude) and
         rainfall < 75 then
         return df.biome_type.FOREST_TROPICAL_CONIFER
    
      elseif parameter < 66 then
         return df.biome_type.FOREST_TROPICAL_DRY_BROADLEAF
      
      elseif is_tropical_area_by_latitude then
         return df.biome_type.FOREST_TROPICAL_MOIST_BROADLEAF
        
      elseif rainfall < 75 or
             temperature < 65 then
        if temperature < 10 then
          return df.biome_type.FOREST_TAIGA
          
        else
          return df.biome_type.FOREST_TEMPERATE_CONIFER
        end
        
      else
         return df.biome_type.FOREST_TEMPERATE_BROADLEAF
      end
      
    else
      if rainfall < 75 or
         temperature < 65 then
           if temperature < 10 then
             return df.biome_type.FOREST_TAIGA
           else
             return df.biome_type.FOREST_TEMPERATE_CONIFER
           end
           
         else
          return df.biome_type.FOREST_TEMPERATE_BROADLEAF
         end
    end
  end
  
  --============================================================

  function get_biome_swamp (is_possible_tropical_area_by_latitude,
                            is_tropical_area_by_latitude,
                            salinity,
                            drainage,
                            rainfall,
                            pos_y,
                            map_height)
    local parameter = get_region_parameter (pos_y, rainfall, map_height)
    
    if is_possible_tropical_area_by_latitude then
      if salinity < 66 then
        if parameter < 66 or
           is_tropical_area_by_latitude then
          return df.biome_type.SWAMP_TROPICAL_FRESHWATER
        else
          return df.biome_type.SWAMP_TEMPERATE_FRESHWATER
        end
     
      elseif parameter < 66 or
             is_tropical_area_by_latitude then
        if drainage < 10 then
           return df.biome_type.SWAMP_MANGROVE
        else
          return df.biome_type.SWAMP_TROPICAL_SALTWATER
        end
        
      else
           return df.biome_type.SWAMP_TEMPERATE_SALTWATER
      end
    
    else
      if salinity < 66 then
           return df.biome_type.SWAMP_TEMPERATE_FRESHWATER
      else
           return df.biome_type.SWAMP_TEMPERATE_SALTWATER
      end
    end
  end
  
  --============================================================
  
  function get_biome_type (biome_pos_y,
                           map_height,
                           temperature,
                           elevation,
                           drainage,
                           rainfall,
                           salinity,
                           vegetation,
                           pole,
                           is_possible_tropical_area_by_latitude,
                           is_tropical_area_by_latitude)
    
    if elevation >= 150 then  --  Adjusted to world gen elevations
         return df.biome_type.MOUNTAIN
      
    elseif elevation < 100 then
      return get_ocean_biome (is_tropical_area_by_latitude,
                              temperature)
                                
    elseif temperature <= -5 then
      if drainage < 75 then
           return df.biome_type.TUNDRA
      else
           return df.biome_type.GLACIER
      end
        
    elseif vegetation < 33 then
      return get_biome_desert_or_grassland_or_savanna (is_possible_tropical_area_by_latitude,
                                                       is_tropical_area_by_latitude,
                                                       vegetation,
                                                       drainage,
                                                       rainfall,
                                                       biome_pos_y,
                                                       map_height)
        
    elseif vegetation < 66 then
      return get_biome_shrubland_or_marsh (is_possible_tropical_area_by_latitude,
                                           is_tropical_area_by_latitude,
                                           drainage,
                                           salinity,
                                           rainfall,
                                           biome_pos_y,
                                           map_height)
        
    elseif drainage < 33 then
      return get_biome_swamp (is_possible_tropical_area_by_latitude,
                              is_tropical_area_by_latitude,
                              salinity,
                              drainage,
                              rainfall,
                              biome_pos_y,
                              map_height)
    else
      return get_biome_forest (is_possible_tropical_area_by_latitude,
                               is_tropical_area_by_latitude,
                               rainfall,
                               temperature,
                               biome_pos_y,
                               map_height)
    end
  end
  

  --============================================================

  for i, region in ipairs (df.global.world.world_data.regions) do
    for k, value in pairs (region.biome_tile_counts) do
      profile ["BIOME_" .. tostring (k)] = value
    end
--    profile.BIOME_MOUNTAIN = 0
--    profile.BIOME_GLACIER = 0
--    profile.BIOME_TUNDRA = 0
--    profile.BIOME_SWAMP_TEMPERATE_FRESHWATER = 0
--    profile.BIOME_SWAMP_TEMPERATE_SALTWATER = 0
--    profile.BIOME_MARSH_TEMPERATE_FRESHWATER = 0
--    profile.BIOME_MARSH_TEMPERATE_SALTWATER = 0
--    profile.BIOME_SWAMP_TROPICAL_FRESHWATER = 0
--    profile.BIOME_SWAMP_TROPICAL_SALTWATER = 0
--    profile.BIOME_SWAMP_MANGROVE = 0
--    profile.BIOME_MARSH_TROPICAL_FRESHWATER = 0
--    profile.BIOME_MARSH_TROPICAL_SALTWATER = 0
--    profile.BIOME_FOREST_TAIGA = 0
--    profile.BIOME_FOREST_TEMPERATE_CONIFER = 0
--    profile.BIOME_FOREST_TEMPERATE_BROADLEAF = false
--    profile.BIOME_FOREST_TROPICAL_CONIFER = false
--    profile.BIOME_FOREST_TROPICAL_DRY_BROADLEAF = false
--    profile.BIOME_FOREST_TROPICAL_MOIST_BROADLEAF = false
--    profile.BIOME_GRASSLAND_TEMPERATE = false
--    profile.BIOME_SAVANNA_TEMPERATE = false
--    profile.BIOME_SHRUBLAND_TEMPERATE = false
--    profile.BIOME_GRASSLAND_TROPICAL = false
--    profile.BIOME_SAVANNA_TROPICAL = false
--    profile.BIOME_SHRUBLAND_TROPICAL = false
--    profile.BIOME_DESERT_BADLAND = false
--    profile.BIOME_DESERT_ROCK = false
--    profile.BIOME_DESERT_SAND = false
--    profile.BIOME_OCEAN_TROPICAL = false
--    profile.BIOME_OCEAN_TEMPERATE = false
--    profile.BIOME_OCEAN_ARCTIC = false
--    profile.BIOME_LAKE_TEMPERATE_FRESHWATER = false
--    profile.BIOME_LAKE_TEMPERATE_BRACKISHWATER = false
--    profile.BIOME_LAKE_TEMPERATE_SALTWATER = false
--    profile.BIOME_LAKE_TROPICAL_FRESHWATER = false
--    profile.BIOME_LAKE_TROPICAL_BRACKISHWATER = false
--    profile.BIOME_LAKE_TROPICAL_SALTWATER = false
    --profile.BIOME_SUBTERRANEAN_WATER = false
    --profile.BIOME_SUBTERRANEAN_CHASM = false
    --profile.BIOME_SUBTERRANEAN_LAVA = false
    profile.GOOD = region.good
    profile.EVIL = region.evil
    profile.SAVAGE = 0

    for k, y in ipairs (region.region_coords.y) do
      local biome = df.global.world.world_data.region_map [region.region_coords.x [k]]:_displace(y)
--      local is_possible_tropical_area_by_latitude, is_tropical_area_by_latitude = 
--       check_tropicality (y,
--                          map_height,
--                          biome.temperature,
--                          pole)
                          
--      local biome_type = get_biome_type
--         (y,
--         map_height,
--         biome.temperature,
--         biome.elevation,
--         biome.drainage,
--         biome.rainfall,
--         biome.salinity,
--         biome.rainfall,  --  biome_data.vegetation, --  Should be vegetation, but doesn't seem to be set before finalization.
--         pole,
--         is_possible_tropical_area_by_latitude,
--         is_tropical_area_by_latitude)
    
--      if biome.evilness < 33 then
--        profile.GOOD = true
--      elseif biome.evilness >= 66 then
--        profile.EVIL = true
--      end
      
      if biome.savagery >= 66 then
        profile.SAVAGE = profile.SAVAGE + 1
      end
--      
--      profile ["BIOME_" .. df.biome_type [biome_type]] = true
    end
    
    dfhack.println ("Diversifying region " .. tostring (i) .. " " .. df.world_region_type [region.type])
    for k, plant in ipairs (df.global.world.raws.plants.all) do
      local found = false
      local matching = false
      
      for l, v in ipairs (region.population) do
        if (v.type == df.world_population_type.Tree or
            v.type == df.world_population_type.Grass or
            v.type == df.world_population_type.Bush) and
           v.plant == k then
          found = true
          break
        end   
      end
      
      if not found then
        for l, value in pairs (profile) do
          if l == "GOOD" or
             l == "EVIL" or
             l == "SAVAGE" then
            if l == "SAVAGE" then
              if plant.flags [l] and value == 0 then
                matching = false
                break
              end
              
            else
              if plant.flags [l] and not value then
                matching = false
                break
              end
            end
            
          elseif plant.flags [l] and value > 0 then
            matching = true
          end
        end
                  
        if matching then
--          dfhack.println ("Adding " .. plant.id .. " to region " .. tostring (i) .. " " .. df.world_region_type [region.type])
          local new_plant = df.world_population:new()
          
          if plant.flags.TREE then
            new_plant.type = df.world_population_type.Tree
            
          elseif plant.flags.GRASS then
            new_plant.type = df.world_population_type.Grass
            
          else
            new_plant.type = df.world_population_type.Bush
          end
          
          new_plant.plant = k
          region.population:insert ("#", new_plant)                  
        end
      end
    end
    
    for k, creature in ipairs (df.global.world.raws.creatures.all) do
      local found = false
      local matching = false
      
      for l, v in ipairs (region.population) do
        if (v.race == df.world_population_type.ColonyInsect or
            v.race == df.world_population_type.VerminInnumerable or
            v.race == df.world_population_type.Vermin or
            v.race == df.world_population_type.Animal) and
            v.race == k then
           found = true
           break
        end   
      end
      
      if not found and
         creature.flags.EQUIPMENT_WAGON or
         creature.flags.CASTE_MEGABEAST or
         creature.flags.CASTE_SEMIMEGABEAST or
--         creature.flags.GENERATED or  --  When is this flag set?
         creature.flags.CASTE_TITAN or
         creature.flags.CASTE_UNIQUE_DEMON or
         creature.flags.CASTE_DEMON or
         creature.flags.CASTE_NIGHT_CREATURE_ANY then
        found = true
      end
      
      if not found then
        for l, value in pairs (profile) do
          if l == "GOOD" or
             l == "EVIL" or
             l == "SAVAGE" then
            if l == "SAVAGE" then
              if creature.flags [l] and value == 0 then
                matching = false
                break
              end
              
            else
              if creature.flags [l] and not value then
                matching = false
                break
              end
            end
            
            
          elseif creature.flags [l] and value > 0 then
            matching = true
          end
        end
                  
        if matching then
--          dfhack.println ("Adding " .. creature.creature_id .. " to region " .. tostring (i))
          local new_creature = df.world_population:new ()
          new_creature.race = k
    
          if creature.flags.VERMIN_SOIL_COLONY then
            new_creature.type = df.world_population_type.ColonyInsect
          
          elseif creature.flags.any_vermin then
            if creature.flags.UBIQUITOUS then
              new_creature.type = df.world_population_type.VerminInnumerable
              
            else
              new_creature.type = df.world_population_type.Vermin
            end
            
          else
            new_creature.type = df.world_population_type.Animal
          end          
     
          if not creature.flags.UBIQUITOUS then
            local creature_biome_count = 0
            for t, q in pairs (profile) do
              if type (q) == 'number' and
                 q ~= "SAVAGE" and                 
                 creature.flags [t] then
                creature_biome_count = creature_biome_count + q
              end
            end
            
            new_creature.count_min = creature_biome_count * (7 + math.random (9))
            new_creature.count_max = new_creature.count_min
          end
          
          df.global.world.world_data.regions [i].population:insert ("#", new_creature)
        end
      end
    end
  end
end

function worldgen_breakout_box ()
  if dfhack.isMapLoaded () then
    dfhack.printerr ("Error: This script is used for world generation manipulation and does not allow a map to be loaded")
    return
  end

  local civ_state = {}
   
  local state = df.global.world.worldgen_status.state
  local placed_caves = false
  local active = not df.global.world.worldgen_status.placed_caves
  local placed_good_evil = false
  local placed_megabeasts = false
  local placed_other_beasts = false
  local made_cave_pops = false
  local made_cave_civs = false
  local placed_civs = false
  local finished_prehistory = false
  local entities
  local century = 0
  local previous_year = 0
  local done = false
  
  local num_rejects = df.global.world.worldgen_status.num_rejects

  function callback ()    
    if dfhack.isMapLoaded () then
      dfhack.println ("A map has been loaded, so worldgen_breakout_box terminates now.")
      return
    end
    
    if state > df.global.world.worldgen_status.state or
      num_rejects ~= df.global.world.worldgen_status.num_rejects then
      num_rejects = df.global.world.worldgen_status.num_rejects
      active = true
      state = df.global.world.worldgen_status.state
      placed_caves = false
      placed_good_evil = false
      placed_megabeasts = false
      placed_other_beasts = false
      made_cave_pops = false
      made_cave_civs = false
      placed_civs = false
      finished_prehistory = false
      century = 0
      previous_year = 0
      current_year = 0
      new_year = false
      civ_state = {}
      dfhack.println ("Starting new run")
    end
    
    if active and df.global.world.worldgen_status.state == 9 then
      if breakout_before_caves then
        if not placed_caves and df.global.world.worldgen_status.placed_caves then
          placed_caves = true
          dfhack.println ("About to place Caves")      
          local screen = dfhack.gui.getCurViewscreen ()
          screen:feed_key (df.interface_key.LEAVESCREEN)
        end
      end
    
      if breakout_before_good_evil then
        if not placed_good_evil and df.global.world.worldgen_status.placed_good_evil then
          dfhack.println ("About to place good/evil")
          placed_good_evil = true
          local screen = dfhack.gui.getCurViewscreen ()
          screen:feed_key (df.interface_key.LEAVESCREEN)
        end
      end
      
      if breakout_before_megabeasts then
        if not placed_megabeasts and df.global.world.worldgen_status.placed_megabeasts then
          dfhack.println ("About to place megabeasts")
          placed_megabeasts = true
          
          for i, region in ipairs (df.global.world.world_data.regions) do
            if region.type == df.world_region_type.Mountains then
              if region.evil or region.good then
                region.evil = false
                region.good = false
                
                for k, x_pos in ipairs (region.region_coords.x) do
                  df.global.world.world_data.region_map [x_pos]:_displace (region.region_coords.y [k]).evilness = 50
                end
              end
              
            elseif region.type == df.world_region_type.Glacier then
              if not region.evil then
                region.evil = true
                region.good = false
                
                for k, x_pos in ipairs (region.region_coords.x) do
                  df.global.world.world_data.region_map [x_pos]:_displace (region.region_coords.y [k]).evilness = 100
                end
              end
            end
          end
                    
          biodiversity ()
--          local screen = dfhack.gui.getCurViewscreen ()
--          screen:feed_key (df.interface_key.LEAVESCREEN)
        end
      end
      
      if breakout_before_other_beasts then
        if not placed_other_beasts and df.global.world.worldgen_status.placed_other_beasts then
          dfhack.println ("About to place other beasts")
          placed_other_beasts = true
          local screen = dfhack.gui.getCurViewscreen ()
          screen:feed_key (df.interface_key.LEAVESCREEN)
        end
      end
      
      if breakout_before_cave_pops then
        if not made_cave_pops and df.global.world.worldgen_status.made_cave_pops then
          dfhack.println ("About to make cave pops")
          made_cave_pops = true
          local screen = dfhack.gui.getCurViewscreen ()
          screen:feed_key (df.interface_key.LEAVESCREEN)
        end
      end
      
      if breakout_before_cave_civs then
        if not made_cave_civs and df.global.world.worldgen_status.made_cave_civs then
          dfhack.println ("About to make cave civs")
          made_cave_civs = true
          local screen = dfhack.gui.getCurViewscreen ()
          screen:feed_key (df.interface_key.LEAVESCREEN)
        end
      end
    
      if not placed_civs and df.global.world.worldgen_status.placed_civs then
        placed_civs = true
        entities = #df.global.world.entities.all
        
        if breakout_before_civs then
          dfhack.println ("About to place civs")      
          local screen = dfhack.gui.getCurViewscreen ()
          screen:feed_key (df.interface_key.LEAVESCREEN)
        end
      end

      if placed_civs and 
         not finished_prehistory then 
        local screen = dfhack.gui.getCurViewscreen ()

        if screen._type == df.viewscreen_new_regionst and
          screen.worldgen_paused == 0 and
          #df.global.world.entities.all ~= entities then
          if breakout_before_each_civ then
            entities = #df.global.world.entities.all
            dfhack.println ("About to place entity number " .. tostring (entities))
            screen:feed_key (df.interface_key.LEAVESCREEN)
          end
        end
      end
      
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
        
        if breakout_before_history then
          dfhack.println ("Finished prehistory")            
          local screen = dfhack.gui.getCurViewscreen ()
          screen:feed_key (df.interface_key.LEAVESCREEN)
          
          if not breakout_at_year and not breakout_every_x_years then
            dfhack.println ("Finished prehistory and no history breaks scheduled.")
            done = true
          end
        end
      end
      
      if finished_prehistory and df.global.world.worldgen_status.anon_4 < previous_year then
        century = century + 1      
      end
    
      previous_year = df.global.world.worldgen_status.anon_4
      
      new_year = current_year ~= century * 100 + previous_year + 1
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
                          df.global.world.entities.all [i].entity_raw.translation ..
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
         
      if new_year and
         df.global.gview.view.child.child.worldgen_paused ~= 1 and
         breakout_at_year and
         current_year == breakout_at_year then
        dfhack.println ("Reached year " .. tostring (current_year))
        
        if not breakout_every_x_years then
          done = true
        end
        
        local screen = dfhack.gui.getCurViewscreen ()
        screen:feed_key (df.interface_key.LEAVESCREEN)
      end
      
      if new_year and
         df.global.gview.view.child.child.worldgen_paused ~= 1 and
         breakout_every_x_years and 
         current_year % breakout_every_x_years == 0 then
        dfhack.println ("Reached year " .. tostring (current_year))            
        local screen = dfhack.gui.getCurViewscreen ()
        screen:feed_key (df.interface_key.LEAVESCREEN)
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
        
        done = true
      end
      
      if not done then
        dfhack.timeout (1, 'frames', callback)
      
      else
        dfhack.println ("The breakout box is now done")
      end
      
    else
      dfhack.timeout (1, 'frames', callback)
    end
  end
   
  local started = dfhack.timeout (1, 'frames', callback)
  dfhack.println ("The breakout box is now started.")
end

worldgen_breakout_box ()