function make_volcano_here ()
  if not dfhack.isWorldLoaded () then
    dfhack.color (COLOR_RED)
    dfhack.print("Error: This script requires a world to be loaded.")
    dfhack.color(COLOR_RESET)
    dfhack.println()
    return
  end

  if dfhack.isMapLoaded() then
    dfhack.color (COLOR_RED)
    dfhack.print("Error: This script requires a world to be loaded, but not a map.")
    dfhack.color(COLOR_RESET)
    dfhack.println()
    return
  end

  local x = df.global.world.world_data.region_details [0].pos.x
  local y = df.global.world.world_data.region_details [0].pos.y
  local mid_level_x = math.floor ((df.global.gview.view.child.location.embark_pos_max.x + df.global.gview.view.child.location.embark_pos_min.x) / 2)
  local mid_level_y = math.floor ((df.global.gview.view.child.location.embark_pos_max.y + df.global.gview.view.child.location.embark_pos_min.y) / 2)
  local region_feature

  if #df.global.world.world_data.region_details [0].features [mid_level_x] [mid_level_y] > 5 then
    dfhack.printerr ("The volcano would clash with another feature present in that tile (" .. tostring (mid_level_x) .. ", " .. tostring (mid_level_y) .. ")")
    return
  end

  df.global.world.world_data.mountain_peaks:insert ("#", {new = true})
  local volcano = df.global.world.world_data.mountain_peaks [#df.global.world.world_data.mountain_peaks - 1]
  volcano.pos.x = x
  volcano.pos.y = y
  volcano.flags:resize (1)
  volcano.flags [0] = true
  volcano.height = df.global.world.world_data.region_map [x]:_displace (y).elevation
  
  df.global.world.world_data.region_map [x]:_displace (y).flags.is_peak = true

  df.global.world.world_data.feature_map [math.floor (x / 16)]:_displace (math.floor (y / 16)).features.feature_init [x % 16] [y % 16]:insert ("#", {new = df.feature_init_volcanost})
  local feature = df.global.world.world_data.feature_map [math.floor (x / 16)]:_displace (math.floor (y / 16)).features.feature_init [x % 16] [y % 16] 
    [#df.global.world.world_data.feature_map [math.floor (x / 16)]:_displace (math.floor (y / 16)).features.feature_init [x % 16] [y % 16] - 1]
  feature.start_x = -1
  feature.start_y = -1
  feature.end_x = -1
  feature.end_y = -1
  feature.start_depth = -1
  feature.end_depth = 3
  feature.feature = df.feature_volcanost:new ()
  
  df.global.world.world_data.region_details [0].features [mid_level_x] [mid_level_y]:insert ("#", {new = true})
  region_feature = df.global.world.world_data.region_details [0].features [mid_level_x] [mid_level_y] [#df.global.world.world_data.region_details [0].features [mid_level_x] [mid_level_y] - 1]
  region_feature.feature_idx = #df.global.world.world_data.feature_map [math.floor (x / 16)]:_displace (math.floor (y / 16)).features.feature_init [x % 16] [y % 16] - 1
  region_feature.layer = -1
  region_feature.region_tile_idx = -1
  region_feature.min_z = -30000
  region_feature.unk_30:resize (1)
  region_feature.unk_38 [0] = 0
  region_feature.unk_38 [1] = 100
  region_feature.unk_38 [2] = 0
  region_feature.unk_38 [3] = 100
  region_feature.unk_38 [4] = 0
  region_feature.unk_38 [5] = 100
  region_feature.unk_38 [6] = 0
  region_feature.unk_38 [7] = 100
  region_feature.unk_38 [8] = 0
  region_feature.unk_38 [9] = 0
  region_feature.unk_38 [10] = -30000
  region_feature.unk_38 [11] = 100
  region_feature.unk_38 [12] = 100
  region_feature.unk_38 [13] = -1
  region_feature.unk_38 [14] = -1
  region_feature.top_layer_idx = -1
end

make_volcano_here ()