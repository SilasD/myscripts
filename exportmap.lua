--  Exports the world generation parameters and the map as a parameter + PSV set. The file is <DF directory>\data\init\exported_map.txt.
--  Note that the exported parameters are not the ones actually in the world, but tweaked to generate the same parameters in the world
--  when used for generation of a new one, as closely as possible. Elevation uses a different scale between the game and generation,
--  and temperature is affected by elevation and latitude.
--  version 0.1 2016-10-22
--[====[

exportmap
========
]====]

function exportmap()
  if not dfhack.isWorldLoaded () then
    dfhack.color (COLOR_LIGHTRED)
    dfhack.println ("exportmap requires a world to be loaded in DF.")
    dfhack.color (COLOR_RESET)
    return
  end
  
  --  Couldn't find the definition of the enum.
  --
  local pole_map = {}
    pole_map [0] = "NONE"
    pole_map [1] = "NORTH_OR_SOUTH"
    pole_map [2] = "NORTH_AND_OR_SOUTH"
    pole_map [3] = "NORTH"
    pole_map [4] = "SOUTH" 
    pole_map [5] = "NORTH_AND_SOUTH"
  
  local pole = df.global.world.world_data.flip_latitude
  
  function pole_to_string (pole)
    if pole == -1 then
      return "NONE"
    elseif pole == 0 then
      return "NORTH"
    elseif pole == 1 then
      return "SOUTH"
    else
      return "NORTH_AND_SOUTH"
    end
  end
  
  function boolean_to_int (b)
    if true then
      return 1
    else
      return 0
    end
  end
  
  local file = io.open (dfhack.getDFPath().."\\data\\init\\exported_map.txt", "w")
  local param = df.global.world.worldgen.worldgen_parms
  local temperature_north_257 =
  {-81, -80, -79, -78, -76, -75, -74, -73, -72, -70, -69, -68, -67, -66, -64, -63,
   -62, -61, -60, -59, -58, -57, -56, -55, -54, -53, -52, -51, -50, -49, -48, -47,
   -46, -45, -44, -43, -42, -41, -40, -39, -38, -37, -36, -36, -35, -34, -33, -32,
   -31, -30, -29, -28, -28, -27, -26, -25, -25, -24, -23, -23, -22, -21, -21, -20,
   -19, -19, -18, -18, -17, -16, -16, -15, -15, -14, -14, -13, -13, -12, -12, -11,
   -11, -10, -10, -9, -9, -8, -8, -8, -7, -7, -6, -6, -6, -5, -5, -5,
   -4, -4, -4, -3, -3, -3, -3, -2, -2, -2, -2, -2, -1, -1, -1, -1,
   -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1,
   1, 2, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 6, 6, 6,
   7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 14, 14, 15,
   16, 16, 17, 18, 18, 19, 20, 20, 21, 22, 23, 24, 24, 25, 26, 27,
   28, 29, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42,
   43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 54, 55, 56, 57, 58, 60,
   61, 62, 64, 65, 66, 68, 69, 70, 72, 73, 74, 76, 77, 79, 80, 82,
   83, 85, 86, 88, 89, 91, 92, 94, 96, 97, 99, 100, 102, 104, 105, 107,
   109}
  
  local temperature_north_65 =
  {-85, -80, -75, -70, -65, -60, -56, -52, -48, -44, -40, -36, -33, -30, -27, -24,
   -21, -18, -16, -14, -12, -10, -8, -6, -5, -4, -3, -2, -1, 0, 0, 0,
   0, 0, 0, 1, 1, 2, 4, 5, 7, 9, 11, 13, 16, 18, 21, 25,
   28, 32, 36, 40, 44, 49, 53, 58, 64, 69, 75, 81, 87, 93, 100, 106,
   113}
  
  local temperature_north_33 =
  {-85, -75, -65, -56, -48, -40, -33, -27, -21, -16, -12, -8, -5, -3, -1, 0,
   0, 0, 2, 4, 8, 12, 18, 24, 32, 40, 50, 60, 72, 84, 98, 112,
   128}
  
  local temperature_north_17 =
  {-64, -49, -36, -25, -16, -9, -4, -1, 0, 1, 4, 9, 16, 25, 36, 49, 64}
  
  local elevation_hill_1 = 228  --  Elevation at which temperature is reduced by 1
  local elevation_hill_2 = 280  --  Elevation at which temperature is reduced by 2
  local elevation_temperature_mountain =
  {-2, -2, -2, -2, -2,                  --  300 - 304
   -3, -3, -3, -3, -3, -3, -3, -3, -3,  --  305 - 313
   -4, -4, -4, -4, -4, -4, -4,          --  314 - 320
   -5, -5, -5, -5, -5, -5, -5,          --  321 - 327
   -6, -6, -6, -6, -6, -6,              --  328 - 333
   -7, -7, -7, -7, -7, -7,              --  334 - 339
   -8, -8, -8, -8, -8,                  --  340 - 344
   -9, -9, -9, -9, -9,                  --  345 - 349
   -10, -10, -10, -10, -10,             --  350 - 354
   -11, -11, -11, -11, -11,             --  355 - 359
   -12, -12, -12, -12, -12,             --  360 - 364
   -13, -13, -13, -13,                  --  365 - 368
   -14, -14, -14, -14,                  --  369 - 372
   -15, -15, -15, -15,                  --  373 - 376
   -16, -16, -16, -16,                  --  377 - 380
   -17, -17, -17, -17,                  --  381 - 384
   -18, -18, -18,                       --  385 - 387
   -19, -19, -19, -19,                  --  388 - 391
   -20, -20, -20,                       --  392 - 394
   -21, -21, -21, -21,                  --  395 - 398
   -22, -22, -22}                       --  399 - 400
  
  file:write ("[WORLD_GEN]\n")
  file:write ("     [TITLE:" .. param.title .. "]\n")
  file:write ("     [SEED:" .. param.seed .. "]\n")
  file:write ("     [HISTORY_SEED:" .. param.history_seed .. "]\n")
  file:write ("     [NAME_SEED:" .. param.name_seed .. "]\n")
  file:write ("     [CREATURE_SEED:" .. param.creature_seed .. "]\n")
  file:write ("     [DIM:" .. tostring (param.dim_x) .. ":" .. 
                              tostring (param.dim_y) .. "]\n")
  file:write ("     [EMBARK_POINTS:" .. tostring (param.embark_points) .. "]\n")
  file:write ("     [END_YEAR:" .. tostring (param.end_year) .. "]\n")
  file:write ("     [BEAST_END_YEAR:"  .. tostring (param.beast_end_year) .. ":" .. 
                                          tostring (param.beast_end_year_percent) .. "]\n")
  file:write ("     [REVEAL_ALL_HISTORY:" .. tostring (param.reveal_all_history) .. "]\n")
  file:write ("     [CULL_HISTORICAL_FIGURES:" .. tostring (param.cull_historical_figures) .. "]\n")
  file:write ("     [ELEVATION:" .. tostring (param.ranges [0] [df.worldgen_range_type.ELEVATION]) .. ":" .. 
                                    tostring (param.ranges [1] [df.worldgen_range_type.ELEVATION]) .. ":3200:3200]\n") -- ..
--                                    tostring (param.ranges [2] [df.worldgen_range_type.ELEVATION]) .. ":" ..
--                                    tostring (param.ranges [3] [df.worldgen_range_type.ELEVATION]) .. "]\n")
  file:write ("     [RAINFALL:" .. tostring (param.ranges [0] [df.worldgen_range_type.RAINFALL]) .. ":" .. 
                                   tostring (param.ranges [1] [df.worldgen_range_type.RAINFALL]) .. ":0:0]\n") -- ..
--                                   tostring (param.ranges [2] [df.worldgen_range_type.RAINFALL]) .. ":" ..
--                                   tostring (param.ranges [3] [df.worldgen_range_type.RAINFALL]) .. "]\n")
  file:write ("     [TEMPERATURE:-1000:1000:0:0]\n") -- .. tostring (param.ranges [0] [df.worldgen_range_type.TEMPERATURE]) .. ":" .. 
--                                      tostring (param.ranges [1] [df.worldgen_range_type.TEMPERATURE]) .. ":" ..
--                                      tostring (param.ranges [2] [df.worldgen_range_type.TEMPERATURE]) .. ":" ..
--                                      tostring (param.ranges [3] [df.worldgen_range_type.TEMPERATURE]) .. "]\n")
  file:write ("     [DRAINAGE:" .. tostring (param.ranges [0] [df.worldgen_range_type.DRAINAGE]) .. ":" .. 
                                   tostring (param.ranges [1] [df.worldgen_range_type.DRAINAGE]) .. ":0:0]\n") -- ..
--                                   tostring (param.ranges [2] [df.worldgen_range_type.DRAINAGE]) .. ":" ..
--                                   tostring (param.ranges [3] [df.worldgen_range_type.DRAINAGE]) .. "]\n")
  file:write ("     [VOLCANISM:" .. tostring (param.ranges [0] [df.worldgen_range_type.VOLCANISM]) .. ":" .. 
                                    tostring (param.ranges [1] [df.worldgen_range_type.VOLCANISM]) .. ":0:0]\n") -- ..
--                                    tostring (param.ranges [2] [df.worldgen_range_type.VOLCANISM]) .. ":" ..
--                                    tostring (param.ranges [3] [df.worldgen_range_type.VOLCANISM]) .. "]\n")
  file:write ("     [SAVAGERY:" .. tostring (param.ranges [0] [df.worldgen_range_type.SAVAGERY]) .. ":" .. 
                                   tostring (param.ranges [1] [df.worldgen_range_type.SAVAGERY]) .. ":0:0]\n") -- ..
--                                   tostring (param.ranges [2] [df.worldgen_range_type.SAVAGERY]) .. ":" ..
--                                   tostring (param.ranges [3] [df.worldgen_range_type.SAVAGERY]) .. "]\n")
  file:write ("     [ELEVATION_FREQUENCY:" .. tostring (param.elevation_frequency [0]) .. ":" ..
                                              tostring (param.elevation_frequency [1]) .. ":" ..
                                              tostring (param.elevation_frequency [2]) .. ":" ..
                                              tostring (param.elevation_frequency [3]) .. ":" ..
                                              tostring (param.elevation_frequency [4]) .. ":" ..
                                              tostring (param.elevation_frequency [5]) .. "]\n")
  file:write ("     [RAIN_FREQUENCY:" .. tostring (param.rain_frequency [0]) .. ":" ..
                                         tostring (param.rain_frequency [1]) .. ":" ..
                                         tostring (param.rain_frequency [2]) .. ":" ..
                                         tostring (param.rain_frequency [3]) .. ":" ..
                                         tostring (param.rain_frequency [4]) .. ":" ..
                                         tostring (param.rain_frequency [5]) .. "]\n")
  file:write ("     [DRAINAGE_FREQUENCY:" .. tostring (param.drainage_frequency [0]) .. ":" ..
                                             tostring (param.drainage_frequency [1]) .. ":" ..
                                             tostring (param.drainage_frequency [2]) .. ":" ..
                                             tostring (param.drainage_frequency [3]) .. ":" ..
                                             tostring (param.drainage_frequency [4]) .. ":" ..
                                             tostring (param.drainage_frequency [5]) .. "]\n")
  file:write ("     [TEMPERATURE_FREQUENCY:" .. tostring (param.temperature_frequency [0]) .. ":" ..
                                                tostring (param.temperature_frequency [1]) .. ":" ..
                                                tostring (param.temperature_frequency [2]) .. ":" ..
                                                tostring (param.temperature_frequency [3]) .. ":" ..
                                                tostring (param.temperature_frequency [4]) .. ":" ..
                                                tostring (param.temperature_frequency [5]) .. "]\n")
  file:write ("     [SAVAGERY_FREQUENCY:" .. tostring (param.savagery_frequency [0]) .. ":" ..
                                             tostring (param.savagery_frequency [1]) .. ":" ..
                                             tostring (param.savagery_frequency [2]) .. ":" ..
                                             tostring (param.savagery_frequency [3]) .. ":" ..
                                             tostring (param.savagery_frequency [4]) .. ":" ..
                                             tostring (param.savagery_frequency [5]) .. "]\n")
  file:write ("     [VOLCANISM_FREQUENCY:" .. tostring (param.volcanism_frequency [0]) .. ":" ..
                                              tostring (param.volcanism_frequency [1]) .. ":" ..
                                              tostring (param.volcanism_frequency [2]) .. ":" ..
                                              tostring (param.volcanism_frequency [3]) .. ":" ..
                                              tostring (param.volcanism_frequency [4]) .. ":" ..
                                              tostring (param.volcanism_frequency [5]) .. "]\n")
  file:write ("     [POLE:" .. pole_to_string (pole) .."]\n") -- pole_map [param.pole] .."]\n")
  file:write ("     [MINERAL_SCARCITY:" .. tostring (param.mineral_scarcity) .. "]\n")
  file:write ("     [MEGABEAST_CAP:" .. tostring (param.megabeast_cap) .. "]\n")
  file:write ("     [SEMIMEGABEAST_CAP:" .. tostring (param.semimegabeast_cap) .. "]\n")
  file:write ("     [TITAN_NUMBER:" .. tostring (param.titan_number) .. "]\n")
  file:write ("     [TITAN_ATTACK_TRIGGER:" .. tostring (param.titan_attack_trigger [0]) .. ":" ..
                                               tostring (param.titan_attack_trigger [1]) .. ":" ..
                                               tostring (param.titan_attack_trigger [2]).. "]\n")
  file:write ("     [DEMON_NUMBER:" .. tostring (param.demon_number) .. "]\n")
  file:write ("     [NIGHT_TROLL_NUMBER:" .. tostring (param.night_troll_number) .. "]\n")
  file:write ("     [BOGEYMAN_NUMBER:" .. tostring (param.bogeyman_number) .. "]\n")
  if dfhack.pcall (function () local dummy = param.nightmare_number end) then
    file:write ("     [NIGHTMARE_NUMBER:" .. tostring (param.nightmare_number) .. "]\n")
  end  
  file:write ("     [VAMPIRE_NUMBER:" .. tostring (param.vampire_number) .. "]\n")
  file:write ("     [WEREBEAST_NUMBER:" .. tostring (param.werebeast_number) .. "]\n")
  if dfhack.pcall (function () local dummy = param.werebeast_attack_trigger [0] end) then
    file:write ("     [WEREBEAST_ATTACK_TRIGGER:" .. tostring (param.werebeast_attack_trigger [0]) .. ":" .. 
                                                     tostring (param.werebeast_attack_trigger [1]) .. ":" ..
                                                     tostring (param.werebeast_attack_trigger [2]).. "]\n")
  end
  file:write ("     [SECRET_NUMBER:" .. tostring (param.secret_number) .. "]\n")
  file:write ("     [REGIONAL_INTERACTION_NUMBER:".. tostring (param.regional_interaction_number).. "]\n")
  file:write ("     [DISTURBANCE_INTERACTION_NUMBER:" .. tostring(param.disturbance_interaction_number) .. "]\n")
  file:write ("     [EVIL_CLOUD_NUMBER:" .. tostring (param.evil_cloud_number) .. "]\n")
  file:write ("     [EVIL_RAIN_NUMBER:" .. tostring (param.evil_rain_number) .. "]\n")
  local generate_divine_materials
  if not dfhack.pcall (function () generate_divine_materials = param.generate_divine_materials end) then  --  Expected new name
    generate_divine_materials = param.anon_1   --  Will probably be renamed soon.
  end
  file:write ("     [GENERATE_DIVINE_MATERIALS:" .. tostring (generate_divine_materials) .. "]\n")
  if dfhack.pcall (function () local dummy = param.allow_divination end) then
    file:write ("     [ALLOW_DIVINATION:" .. tostring (param.allow_divination) .. "]\n")
    file:write ("     [ALLOW_DEMONIC_EXPERIMENTS:" .. tostring (param.allow_demonic_experiments) .. "]\n")
    file:write ("     [ALLOW_NECROMANCER_EXPERIMENTS:" .. tostring (param.allow_necromancer_experiments) .. "]\n")
    file:write ("     [ALLOW_NECROMANCER_LIEUTENANTS:" .. tostring (param.allow_necromancer_lieutenants) .. "]\n")
    file:write ("     [ALLOW_NECROMANCER_GHOULS:" .. tostring (param.allow_necromancer_ghouls) .. "]\n")
    file:write ("     [ALLOW_NECROMANCER_SUMMONS:" .. tostring (param.allow_necromancer_summons) .. "]\n")
  end
  file:write ("     [GOOD_SQ_COUNTS:" .. tostring (param.good_sq_counts_0) .. ":" ..
                                         tostring (param.good_sq_counts_1) .. ":" ..
                                         tostring (param.good_sq_counts_2) .. "]\n")
  file:write ("     [EVIL_SQ_COUNTS:" .. tostring (param.evil_sq_counts_0) .. ":" ..
                                         tostring (param.evil_sq_counts_1) .. ":" ..
                                         tostring (param.evil_sq_counts_2) .. "]\n")
  file:write ("     [PEAK_NUMBER_MIN:" .. tostring (param.peak_number_min) .. "]\n")
  file:write ("     [PARTIAL_OCEAN_EDGE_MIN:" .. tostring (param.partial_ocean_edge_min) .. "]\n")
  file:write ("     [COMPLETE_OCEAN_EDGE_MIN:" .. tostring (param.complete_ocean_edge_min) .. "]\n")
  file:write ("     [VOLCANO_MIN:" .. tostring (param.volcano_min) .. "]\n")
  file:write ("     [REGION_COUNTS:SWAMP:" .. tostring (param.region_counts [0] [df.worldgen_region_type.SWAMP]) .. ":" ..
                                              tostring (param.region_counts [1] [df.worldgen_region_type.SWAMP]) .. ":" ..
                                              tostring (param.region_counts [2] [df.worldgen_region_type.SWAMP]) .. "]\n")
  file:write ("     [REGION_COUNTS:DESERT:" .. tostring (param.region_counts [0] [df.worldgen_region_type.DESERT]) .. ":" ..
                                               tostring (param.region_counts [1] [df.worldgen_region_type.DESERT]) .. ":" ..
                                               tostring (param.region_counts [2] [df.worldgen_region_type.DESERT]) .. "]\n")
  file:write ("     [REGION_COUNTS:FOREST:" .. tostring (param.region_counts [0] [df.worldgen_region_type.FOREST]) .. ":" ..
                                               tostring (param.region_counts [1] [df.worldgen_region_type.FOREST]) .. ":" ..
                                               tostring (param.region_counts [2] [df.worldgen_region_type.FOREST]) .. "]\n")
  file:write ("     [REGION_COUNTS:MOUNTAINS:" .. tostring (param.region_counts [0] [df.worldgen_region_type.MOUNTAINS]) .. ":" ..
                                                  tostring (param.region_counts [1] [df.worldgen_region_type.MOUNTAINS]) .. ":" ..
                                                  tostring (param.region_counts [2] [df.worldgen_region_type.MOUNTAINS]) .. "]\n")
  file:write ("     [REGION_COUNTS:OCEAN:" .. tostring (param.region_counts [0] [df.worldgen_region_type.OCEAN]) .. ":" ..
                                              tostring (param.region_counts [1] [df.worldgen_region_type.OCEAN]) .. ":" ..
                                              tostring (param.region_counts [2] [df.worldgen_region_type.OCEAN]) .. "]\n")
  file:write ("     [REGION_COUNTS:GLACIER:" .. tostring (param.region_counts [0] [df.worldgen_region_type.GLACIER]) .. ":" ..
                                                tostring (param.region_counts [1] [df.worldgen_region_type.GLACIER]) .. ":" ..
                                                tostring (param.region_counts [2] [df.worldgen_region_type.GLACIER]) .. "]\n")
  file:write ("     [REGION_COUNTS:TUNDRA:" .. tostring (param.region_counts [0] [df.worldgen_region_type.TUNDRA]) .. ":" ..
                                               tostring (param.region_counts [1] [df.worldgen_region_type.TUNDRA]) .. ":" ..
                                               tostring (param.region_counts [2] [df.worldgen_region_type.TUNDRA]) .. "]\n")
  file:write ("     [REGION_COUNTS:GRASSLAND:" .. tostring (param.region_counts [0] [df.worldgen_region_type.GRASSLAND]) .. ":" ..
                                                  tostring (param.region_counts [1] [df.worldgen_region_type.GRASSLAND]) .. ":" ..
                                                  tostring (param.region_counts [2] [df.worldgen_region_type.GRASSLAND]) .. "]\n")
  file:write ("     [REGION_COUNTS:HILLS:" .. tostring (param.region_counts [0] [df.worldgen_region_type.HILLS]) .. ":" ..
                                              tostring (param.region_counts [1] [df.worldgen_region_type.HILLS]) .. ":" ..
                                              tostring (param.region_counts [2] [df.worldgen_region_type.HILLS]) .. "]\n")
  file:write ("     [EROSION_CYCLE_COUNT:0]\n") -- .. tostring (param.erosion_cycle_count) .. "]\n")
  file:write ("     [RIVER_MINS:" .. tostring (param.river_mins [0]) ..":" .. 
                                     tostring (param.river_mins [1]) .. "]\n")
  file:write ("     [PERIODICALLY_ERODE_EXTREMES:0]\n") -- .. tostring (param.periodically_erode_extremes) .. "]\n")
  file:write ("     [OROGRAPHIC_PRECIPITATION:0]\n") -- .. tostring (param.orographic_precipitation) .. "]\n")
  file:write ("     [SUBREGION_MAX:5000]\n") -- .. tostring (param.subregion_max) .. "]\n")
  file:write ("     [CAVERN_LAYER_COUNT:" .. tostring (param.cavern_layer_count) .. "]\n")
  file:write ("     [CAVERN_LAYER_OPENNESS_MIN:" .. tostring (param.cavern_layer_openness_min) .. "]\n")
  file:write ("     [CAVERN_LAYER_OPENNESS_MAX:" .. tostring (param.cavern_layer_openness_max) .. "]\n")
  file:write ("     [CAVERN_LAYER_PASSAGE_DENSITY_MIN:" .. tostring (param.cavern_layer_passage_density_min) .. "]\n")
  file:write ("     [CAVERN_LAYER_PASSAGE_DENSITY_MAX:" .. tostring (param.cavern_layer_passage_density_max) .. "]\n")
  file:write ("     [CAVERN_LAYER_WATER_MIN:" .. tostring (param.cavern_layer_water_min) .. "]\n")
  file:write ("     [CAVERN_LAYER_WATER_MAX:" .. tostring (param.cavern_layer_water_max) .. "]\n")
  file:write ("     [HAVE_BOTTOM_LAYER_1:" .. tostring (boolean_to_int (param.have_bottom_layer_1)) .. "]\n")
  file:write ("     [HAVE_BOTTOM_LAYER_2:" .. tostring (boolean_to_int (param.have_bottom_layer_2)) .. "]\n")
  file:write ("     [LEVELS_ABOVE_GROUND:" .. tostring (param.levels_above_ground) .. "]\n")
  file:write ("     [LEVELS_ABOVE_LAYER_1:" .. tostring (param.levels_above_layer_1) .. "]\n")
  file:write ("     [LEVELS_ABOVE_LAYER_2:" .. tostring (param.levels_above_layer_2) .. "]\n")
  file:write ("     [LEVELS_ABOVE_LAYER_3:" .. tostring (param.levels_above_layer_3) .. "]\n")
  file:write ("     [LEVELS_ABOVE_LAYER_4:" .. tostring (param.levels_above_layer_4) .. "]\n")
  file:write ("     [LEVELS_ABOVE_LAYER_5:" .. tostring (param.levels_above_layer_5) .. "]\n")
  file:write ("     [LEVELS_AT_BOTTOM:" .. tostring (param.levels_at_bottom) .. "]\n")
  file:write ("     [CAVE_MIN_SIZE:" .. tostring (param.cave_min_size) .. "]\n")
  file:write ("     [CAVE_MAX_SIZE:" .. tostring (param.cave_max_size) .. "]\n")
  file:write ("     [MOUNTAIN_CAVE_MIN:" .. tostring (param.mountain_cave_min) .. "]\n")
  file:write ("     [NON_MOUNTAIN_CAVE_MIN:" .. tostring (param.non_mountain_cave_min) .. "]\n")
  file:write ("     [ALL_CAVES_VISIBLE:" .. tostring (param.all_caves_visible) .. "]\n")
  file:write ("     [SHOW_EMBARK_TUNNEL:" .. tostring (param.show_embark_tunnel) .. "]\n")
  file:write ("     [TOTAL_CIV_NUMBER:" .. tostring (param.total_civ_number) .. "]\n")
  file:write ("     [TOTAL_CIV_POPULATION:" .. tostring (param.total_civ_population) .. "]\n")
  file:write ("     [SITE_CAP:" .. tostring (param.site_cap) .. "]\n")
  file:write ("     [PLAYABLE_CIVILIZATION_REQUIRED:" .. tostring (param.playable_civilization_required) .. "]\n")
  file:write ("     [ELEVATION_RANGES:" .. tostring (param.elevation_ranges_0) .. ":" ..
                                           tostring (param.elevation_ranges_1) .. ":" ..
                                           tostring (param.elevation_ranges_2) .. "]\n")
  file:write ("     [RAIN_RANGES:" .. tostring (param.rain_ranges_0) .. ":" ..
                                      tostring (param.rain_ranges_1) .. ":" ..
                                      tostring (param.rain_ranges_2) .. "]\n")
  file:write ("     [DRAINAGE_RANGES:" .. tostring (param.drainage_ranges_0) .. ":" ..
                                          tostring (param.drainage_ranges_1) .. ":" ..
                                          tostring (param.drainage_ranges_2) .. "]\n")
  file:write ("     [SAVAGERY_RANGES:" .. tostring (param.savagery_ranges_0) .. ":" ..
                                          tostring (param.savagery_ranges_1) .. ":" ..
                                          tostring (param.savagery_ranges_2) .. "]\n")
  file:write ("     [VOLCANISM_RANGES:" .. tostring (param.volcanism_ranges_0) .. ":" ..
                                           tostring (param.volcanism_ranges_1) .. ":" ..
                                           tostring (param.volcanism_ranges_2) .. "]\n") 

  --  Elevation is rescaled between world generation and world usage. The code below seems to
  --  work to restore it. Note that world gen introduces variations even when that is disabled.
  --
  for i = 0, df.global.world.worldgen.worldgen_parms.dim_y - 1 do
    file:write ("[PS_EL")
    for k = 0, df.global.world.worldgen.worldgen_parms.dim_x - 1 do
      local elevation = df.global.world.world_data.region_map[k]:_displace(i).elevation
      if elevation >= 150 then
        elevation = elevation + 150
      elseif elevation > 100 then
        elevation = 100 + (elevation - 100) * 4
      end
      
      file:write (":" .. tostring (elevation))
    end
    file:write ("]\n")
  end
  
  --  Rainfall seems to exactly match what was input, at least when uniform, provided orographic_precipitation
  --  is disabled.
  --
  for i = 0, df.global.world.worldgen.worldgen_parms.dim_y - 1 do
    file:write ("[PS_RF")
    for k = 0, df.global.world.worldgen.worldgen_parms.dim_x - 1 do
      file:write (":" .. tostring (df.global.world.world_data.region_map[k]:_displace(i).rainfall))
    end
    file:write ("]\n")
  end
  
  --  Temperature is adjusted based on poles and elevation.
  --
  for i = 0, df.global.world.worldgen.worldgen_parms.dim_y - 1 do
    file:write ("[PS_TP")
    for k = 0, df.global.world.worldgen.worldgen_parms.dim_x - 1 do
      local temperature = df.global.world.world_data.region_map[k]:_displace(i).temperature
      local elevation = df.global.world.world_data.region_map[k]:_displace(i).elevation
      
      if elevation >= 150 then
        elevation = elevation + 150
      elseif elevation > 100 then
        elevation = 100 + (elevation - 100) * 4
      end
      
      if elevation >= 300 then
        temperature = temperature - elevation_temperature_mountain [elevation - 299]
      elseif elevation >= elevation_hill_2 then
        temperature = temperature + 2
      elseif elevation >= elevation_hill_1 then
        temperature = temperature + 1
      end

      if pole == -1 then  -- None
        --  We're done
        
      elseif pole == 0 then  --  North
        if param.dim_y == 257 then
          temperature = temperature - temperature_north_257 [i + 1]
          
        elseif param.dim_y == 129 then
          temperature = temperature - temperature_north_257 [i * 2 + 1]
          
        elseif param.dim_y == 65 then
          temperature = temperature - temperature_north_65 [i + 1]
          
        elseif param.dim_y == 33 then
          temperature = temperature - temperature_north_33 [i + 1]
          
        else  --  Should be 17, but we'll end up here for whacky ones as well.
          temperature = temperature - temperature_north_17 [i + 1]
        end
        
      elseif pole == 1 then  --  South
        if param.dim_y == 257 then
          temperature = temperature - temperature_north_257 [256 - i + 1]
          
        elseif param.dim_y == 129 then
          temperature = temperature - temperature_north_257 [(128 - i) * 2 + 1]
          
        elseif param.dim_y == 65 then
          temperature = temperature - temperature_north_65 [64 - i + 1]
          
        elseif param.dim_y == 33 then
          temperature = temperature - temperature_north_33 [32 - i + 1]
          
        else  --  Should be 17, but we'll end up here for whacky ones as well.
          temperature = temperature - temperature_north_17 [16 - i + 1]
        end
        
      else  --  Both
        if param.dim_y == 257 then
          local latitude = i
          if latitude > 128 then
            latitude = (256 - latitude) * 2
          
          else
            latitude = latitude * 2
          end
          
          temperature = temperature - temperature_north_257 [latitude + 1]
          
        elseif param.dim_y == 129 then
          local latitude = i
          if latitude > 64 then
            latitude = (128 - latitude) * 2
            
          else
            latitude = latitude * 2
          end
          
          temperature = temperature - temperature_north_257 [latitude * 2 + 1]
          
        elseif param.dim_y == 65 then
          local latitude = i
          if latitude > 32 then
            latitude = (64 - latitude) * 2
            
          else
            latitude = latitude * 2
          end
        
          temperature = temperature - temperature_north_65 [latitude + 1]
          
        elseif param.dim_y == 33 then
          local latitude = i
          if latitude > 16 then
            latitude = (32 - latitude) * 2
            
          else
            latitude = latitude * 2
          end
          temperature = temperature - temperature_north_33 [latitude + 1]
          
        else  --  Should be 17, but we'll end up here for whacky ones as well.
          local latitude = i
          if latitude > 8 then
            latitude = (16 - latitude) * 2
            
          else
            latitude = latitude * 2
          end
          temperature = temperature - temperature_north_17 [latitude + 1]
        end        
      end
      
      file:write (":" .. tostring (temperature))
    end
    file:write ("]\n")
  end
  
  --  Drainage seems to match exactly what was input, at least when it is uniform...
  --
  for i = 0, df.global.world.worldgen.worldgen_parms.dim_y - 1 do
    file:write ("[PS_DR")
    for k = 0, df.global.world.worldgen.worldgen_parms.dim_x - 1 do
      file:write (":" .. tostring (df.global.world.world_data.region_map[k]:_displace(i).drainage))
    end
    file:write ("]\n")
  end
  
  --  Volcanism is smoothed somehow. It might be rainfall and drainage use the same logic.
  --
  for i = 0, df.global.world.worldgen.worldgen_parms.dim_y - 1 do
    file:write ("[PS_VL")
    for k = 0, df.global.world.worldgen.worldgen_parms.dim_x - 1 do
      file:write (":" .. tostring (df.global.world.world_data.region_map[k]:_displace(i).volcanism))
    end
    file:write ("]\n")
  end
  
  --  Uniform savagery remained unifomr.
  --
  for i = 0, df.global.world.worldgen.worldgen_parms.dim_y - 1 do
    file:write ("[PS_SV")
    for k = 0, df.global.world.worldgen.worldgen_parms.dim_x - 1 do
      file:write (":" .. tostring (df.global.world.world_data.region_map[k]:_displace(i).savagery))
    end
    file:write ("]\n")
  end
  
  file:flush()
  file:close()
end

exportmap()


