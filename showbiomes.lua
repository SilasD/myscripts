--Displays the surface biomes of the current embark, as well as biome and enviroment parameters per Z level for examination of air biomes Use ? for help. 
--Can be used with a Fortress Mode loaded embark only.
--[====[

showbiomes
========
--  The biome determination logic is mainly copied and adapted from https://github.com/ragundo/exportmaps/blob/master/cpp/df_utils/biome_type.cpp#L105
--
]====]

local gui = require 'gui'
local dialog = require 'gui.dialogs'
local widgets =require 'gui.widgets'
local guiScript = require 'gui.script'

--================================================================
--  The Grid widget defines an pen supporting X/Y character display grid supporting display of
--  a grid larger than the frame allows through a panning viewport. The init function requires
--  the specification of the width and height attributes that defines the grid dimensions.
--  The grid coordinates are 0 based.
--
Grid = defclass (Grid, widgets.Widget)
Grid.ATTRS = 
  {width = DEFAULT_NIL,
   height = DEFAULT_NIL}

--================================================================

function Grid:init ()
  if type (self.width) ~= 'number' or
     type (self.height) ~= 'number' or
	 self.width < 0 or
	 self.height < 0 then
    error ("Grid widgets have to have their width and height set permanently on initiation")
	return
  end
  
  self.grid = dfhack.penarray.new (self.width, self.height)
  
  self.viewport = {x1 = 0,
                   x2 = self.frame.r - self.frame.l,
				   y1 = 0,
				   y2 = self.frame.b - self.frame.t}  
end

--================================================================

function Grid:panTo (x, y)
  local x_size = self.viewport.x2 - self.viewport.x1 + 1
  local y_size = self.viewport.y2 - self.viewport.y1 + 1
  
  self.viewport.x1 = x

  if self.viewport.x1 + x_size > self.width then
    self.viewport.x1 = self.width - x_size
  end
  
  if self.viewport.x1 < 0 then
    self.viewport.x1 = 0
  end
  
  self.viewport.x2 = self.viewport.x1 + x_size - 1
  
  self.viewport.y1 = y
  
  if self.viewport.y1 + y_size > self.height then
    self.viewport.y1 = self.height - y_size
  end
  
  if self.viewport.y1 < 0 then
    self.viewport.y1 = 0
  end
  
  self.viewport.y2 = self.viewport.y1 + y_size - 1
end

--================================================================
--  Pans the viewport in the X and Y dimensions the number of steps specified by the parameters.
--  It will stop the panning at 0, however, and will not pan outside of the grid (a grid smaller)
--  than the frame will still have non grid parts in the frame, of course).
--
function Grid:pan (x, y)
  self:panTo (self.viewport.x1 + x, self.viewport.y1 + y)
end

--================================================================

function Grid:panCenter (x, y)
  self:panTo (x - math.floor ((self.viewport.x2 - self.viewport.x1 + 1) / 2),
              y - math.floor ((self.viewport.y2 - self.viewport.y1 + 1) / 2))
end

--================================================================
--  Assigns a value to the specified grid (not frame) coordinates. The 'pen'
--  parameter has to be a DFHack 'pen' table or object.
--
function Grid:set (x, y, pen)
  if x < 0 or x >= self.width then
	error ("Grid:set error: x out of bounds " .. tostring (x) .. " vs 0 - " .. tostring (self.width - 1))
	return
    
  elseif y < 0 or y >= self.height then
	error ("Grid:set error: y out of bounds " .. tostring (y) .. " vs 0 - " .. tostring (self.height - 1))
	return
  end

  self.grid:set_tile (x, y, pen)  
end

--================================================================
--  Returns the data at position x, y in the grid.
--
function Grid:get (x, y)
  if x < 0 or x >= self.width then
	error ("Grid:set error: x out of bounds " .. tostring (x) .. " vs 0 - " .. tostring (self.width - 1))
	return
    
  elseif y < 0 or y >= self.height then
	error ("Grid:set error: y out of bounds " .. tostring (y) .. " vs 0 - " .. tostring (self.height - 1))
	return
  else
    return self.grid:get_tile (x, y)
  end
end

--================================================================
--  Renders the contents within the viewport into the frame.
--
function Grid:onRenderBody (dc)
  self.grid:draw (self.frame.l,
                  self.frame.t,
				  self.viewport.x2 - self.viewport.x1 + 1,
				  self.viewport.y2 - self.viewport.y1 + 1,
				  self.viewport.x1,
				  self.viewport.y1)
end

--================================================================
--================================================================

function showbiomes ()
  if not dfhack.isMapLoaded () then
    dfhack.printerr ("Error: This script requires a Fortress Mode embark to be loaded.")
	return
  end

  local elevation
  local temperature
  local savagery
  local evilness
  local drainage
  local volcanism
  local rainfall
  local vegetation
  local salinity
  local broad_biome
  local max_x, max_y, max_z = dfhack.maps.getTileSize ()
  local x = 0
  local y = 0
  local help_screen = {}
  local help_length
  local help_x = 1
  local help_y = 1
  local help_max_x
  local help_max_y
  local move_key = {}
  local move_key_index = 0
  local normal_key = {}
  local normal_key_index = 0	
  local z = max_z - 1 - df.global.world.worldgen.worldgen_parms.levels_above_ground
  local tile_type
  local flow_size
  local liquid_type
  local pole = df.global.world.world_data.flip_latitude
  local map_width = df.global.world.world_data.world_width
  local map_height = df.global.world.world_data.world_height
  local embark = df.global.world.world_data.active_site[0].pos.y + 1
  local embark_x = df.global.world.world_data.active_site[0].pos.x
  local embark_y = df.global.world.world_data.active_site[0].pos.y
  local embark_region_min_x = df.global.world.world_data.active_site[0].rgn_min_x
  local embark_region_min_y = df.global.world.world_data.active_site[0].rgn_min_y
  local region_id
  local cursor_x = df.global.cursor.x
  local cursor_y = df.global.cursor.y
  local focus = "Biome"
  local biome_set = {}
  --  Structure:
  --  {biome = <biome structure>,
  --   home_x = <map x coordinate>,
  --   home_y = <map y coordinate>,
  --   sav_evil_color = <the color code associated with the corresponding combination of savagery and evilness> 
  --   biome_type_1 = <enum value of the first biome encountered>,
  --   air = <boolean indicated if it's been detected in the air only so far>
  --   --  The element below will be present only if two biomes have been detected.
  --   biome_type_2 = <enum value of the second biome encountered>}
  --   --  There can be two of them if one is temperate and one tropical. The second one will never be air, as air is detected first.
  local biome_set_count = 0
  local potential_biome_set = {}
  --  Structure:
  --  {biome = <biome structure>,
  --   home_x = <map x coordinate>,
  --   home_y = <map y coordinate>,
  --   sav_evil_color = <the color code associated with the corresponding combination of savagery and evilness> 
  --   biome_type = <enum value of the biome>}
  local potential_biome_set_count = 0
  
  local biome_map ={}
  --  Built gradually as Z levels are explored. It's indexed by Z, with 0 used for the surface map, then Y (row), and finally X (column).
  --  The column should contain the following "type":
  --  {is_anomaly = <boolean>,  -- Switch/discriminant. The rest of the fields are present only if false
  --     is_air = <boolean>,
  --     biome = biome set,
  --     biome_home_x = <map x coordinate>,
  --     biome_home_y = <map_y_coordinate>,
  --     biome_reference_x = <home x coordinate for biome tropicality determination>,
  --     biome_reference_y = <home y coordinate for biome tropicality determination>,
  --     biome_offset = <des.biome>,
  --     broad_biome = <broad biome>,
  --     tile_type = <tile type>,
  --     biome_character = <character representation of the biome>}
  
  local debug = false
  --a variable the stores persistant screen
  persist_screen=persist_screen or nil --does nothing, here just to remind everyone
  local Main_Page = {}

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
	
	if debug then
	  dfhack.print ("check_tropicality_south_pole_only_world: pos_y: ")
	  dfhack.print (pos_y)
	  dfhack.print (", map_height: ")
	  dfhack.print (map_height)
	  dfhack.print (", temperature: ")
	  dfhack.print (temperature)
	  dfhack.print (", v6: ")
	  dfhack.print (v6)
	  dfhack.print (", is_possible_tropical_area_by_latitude: ")
	  dfhack.print (is_possible_tropical_area_by_latitude)
	  dfhack.print (", is_tropical_area_by_latitude: ")
	  dfhack.println (is_tropical_area_by_latitude)
	end
	
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
                              temperature)
	local flip_latitude = df.global.world.world_data.flip_latitude
	
	if flip_latitude == -1 then  --  No poles
	  return check_tropicality_no_poles_world (temperature)
											
	elseif flip_latitude == 0 then  --  North pole
	  return check_tropicality_north_pole_only_world (pos_y,
	                                                  map_height)
													  
	elseif flip_latitude == 1 then  --  South pole
	  return check_tropicality_south_pole_only_world (pos_y,
	                                                  map_height)
													  
	elseif flip_latitude == 2 then  -- Both poles
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
	  return get_parameter_percentage (df.global.world.world_data.flip_latitude,
	                                   pos_y,
									   rainfall,
									   map_height)
	end
	
	return result
  end
  
  --============================================================
  
  function get_lake_biome (is_possible_tropical_area_by_latitude,
                           salinity)
	if debug then
	  dfhack.print ("get_lake_biome: is_possible_tropical_area_by_latitude: ")
	  dfhack.print (is_possible_tropical_area_by_latitude)
	  dfhack.print (", salinity: ")
	  dfhack.println (salinity)
	end
	if salinity < 33 then
      if is_possible_tropical_area_by_latitude then
        return df.biome_type.LAKE_TROPICAL_FRESHWATER
	  else
		return df.biome_type.LAKE_TEMPERATE_FRESHWATER
      end
	
	elseif salinity < 66 then
	  if is_possible_tropical_area_by_latitude then
		return df.biome_type.LAKE_TROPICAL_BRACKISHWATER
      else
		return df.biome_type.LAKE_TEMPERATE_BRACKISHWATER
	  end
	 	  
	else
	  if is_possible_tropical_area_by_latitude then
	    return df.biome_type.LAKE_TROPICAL_SALTWATER
	  else
	    return df.biome_type.LAKE_TEMPERATE_SALTWATER
	  end
	end
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
	if debug then
	  dfhack.print ("get_biome_savanna: is_possible_tropical_area_by_latitude: ")
	  dfhack.print (is_possible_tropical_area_by_latitude)
	  dfhack.print (", is_tropical_area_by_latitude: ")
	  dfhack.print (is_tropical_area_by_latitude)
	  dfhack.print (", rainfall: ")
	  dfhack.print (rainfall)
	  dfhack.print (", pos_y: ")
	  dfhack.print (pos_y)
	  dfhack.print (", map_height: ")
	  dfhack.print (map_height)
	  dfhack.print (", get_region_parameter(): ")
	  dfhack.println (get_region_parameter (pos_y, rainfall, map_height))
	end
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
	if debug then
	  dfhack.print ("get_biome_shrubland: is_possible_tropical_area_by_latitude: ")
	  dfhack.print (is_possible_tropical_area_by_latitude)
	  dfhack.print (", is_tropical_area_by_latitude: ")
	  dfhack.print (is_tropical_area_by_latitude)
	  dfhack.print (", rainfall: ")
	  dfhack.print (rainfall)
	  dfhack.print (", pos_y: ")
	  dfhack.print (pos_y)
	  dfhack.print (",map_height: ")
	  dfhack.print (map_height)
	  dfhack.print (", get_region_parameter: ")
	  dfhack.println (get_region_parameter (pos_y, rainfall, map_height))
	end
	
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
					       region_id)
					  
    local is_possible_tropical_area_by_latitude, is_tropical_area_by_latitude = 
	  check_tropicality (biome_pos_y,
	                     map_height,
		  			     temperature)
		  
    if df.global.world.world_data.regions[region_id].type == df.world_region_type.Lake then
	  return get_lake_biome (is_possible_tropical_area_by_latitude,
	                         salinity)
	  
	elseif elevation >= 150 then
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
  
  function get_biome_character (is_air,
                                local_pos_y,
                                biome_reference_y,
								                biome_home_y,
                                map_height,
                                temperature,
                                elevation,
                                drainage,
                                rainfall,
                                salinity,
						        vegetation,
					            region_id,
								tile_type)
	
    local biome_type	

	if is_air then
	  biome_type = get_biome_type (biome_home_y,  --  Very much a guess. The biome appears to be uniform, and local_pos_y got it wrong at one place.
	                               map_height,
                                   temperature,
                                   elevation,
                                   drainage,
                                   rainfall,
                                   salinity,
						           vegetation,
					               region_id)
	else
	  biome_type = get_biome_type (biome_reference_y,
	                               map_height,
                                   temperature,
                                   elevation,
                                   drainage,
                                   rainfall,
                                   salinity,
						           vegetation,
					               region_id)
	end
    
	if tile_type == df.tiletype.MurkyPool or
       tile_type == df.tiletype.MurkyPoolRamp then
       local is_possible_tropical_area_by_latitude, is_tropical_area_by_latitude = 
	           check_tropicality (local_pos_y,
	                              map_height,
		  			              temperature)
	
	   local lake_type = get_lake_biome (is_possible_tropical_area_by_latitude,
	                                     salinity)
										 
	   if lake_type == df.biome_type.LAKE_TEMPERATE_FRESHWATER then
	     biome_type = df.biome_type. POOL_TEMPERATE_FRESHWATER
	  
       elseif lake_type == df.biome_type.LAKE_TEMPERATE_BRACKISHWATER then
	     biome_type = df.biome_type.POOL_TEMPERATE_BRACKISHWATER
		 
       elseif lake_type == df.biome_type.LAKE_TEMPERATE_SALTWATER then
	     biome_type = df.biome_type.POOL_TEMPERATE_SALTWATER
		 
       elseif lake_type == df.biome_type.LAKE_TROPICAL_FRESHWATER then
	     biome_type = df.biome_type.POOL_TROPICAL_FRESHWATER
		 
       elseif lake_type == df.biome_type.LAKE_TROPICAL_BRACKISHWATER then
	     biome_type = df.biome_type.POOL_TROPICAL_BRACKISHWATER
		 
       elseif lake_type == df.biome_type.LAKE_TROPICAL_SALTWATER then
         biome_type = df.biome_type.POOL_TROPICAL_SALTWATER
	   end
    
	elseif tile_type == df.tiletype.Waterfall or
           tile_type == df.tiletype.RiverSource or
           (tile_type >= df.tiletype.RiverN and
            tile_type <= df.tiletype.BrookTop) or
           (tile_type >= df.tiletype.RiverRampN and
            tile_type <= df.tiletype.RiverRampSE) then
       local is_possible_tropical_area_by_latitude, is_tropical_area_by_latitude = 
	           check_tropicality (local_pos_y,
	                              map_height,
		  			              temperature)
	
	   local lake_type = get_lake_biome (is_possible_tropical_area_by_latitude,
	                                     salinity)
										 
	   if lake_type == df.biome_type.LAKE_TEMPERATE_FRESHWATER then
	     biome_type = df.biome_type.RIVER_TEMPERATE_FRESHWATER
	  
     elseif lake_type == df.biome_type.LAKE_TEMPERATE_BRACKISHWATER then
	     biome_type = df.biome_type.RIVER_TEMPERATE_BRACKISHWATER
		 
     elseif lake_type == df.biome_type.LAKE_TEMPERATE_SALTWATER then
	     biome_type = df.biome_type.RIVER_TEMPERATE_SALTWATER
		 
     elseif lake_type == df.biome_type.LAKE_TROPICAL_FRESHWATER then
	     biome_type = df.biome_type.RIVER_TROPICAL_FRESHWATER
		 
     elseif lake_type == df.biome_type.LAKE_TROPICAL_BRACKISHWATER then
	     biome_type = df.biome_type.RIVER_TROPICAL_BRACKISHWATER
		 
     elseif lake_type == df.biome_type.LAKE_TROPICAL_SALTWATER then
       biome_type = df.biome_type.RIVER_TROPICAL_SALTWATER
	   end
     
 	elseif flow_size ~= 0 then
      if liquid_type then  --  Magma. For some reason this is a boolean rather than an enum...
        biome_type = df.biome_type.SUBTERRANEAN_LAVA
      end
    end

    if biome_type == df.biome_type.MOUNTAIN then
	  return '+'	  
    elseif biome_type == df.biome_type.GLACIER then
	  return '*'
    elseif biome_type == df.biome_type.TUNDRA then
	  return 't'
    elseif biome_type == df.biome_type.SWAMP_TEMPERATE_FRESHWATER then
	  return 'p'
    elseif biome_type == df.biome_type.SWAMP_TEMPERATE_SALTWATER then
	  return 'r'
    elseif biome_type == df.biome_type.MARSH_TEMPERATE_FRESHWATER then
	  return 'n'
    elseif biome_type == df.biome_type.MARSH_TEMPERATE_SALTWATER then
	  return 'y'
    elseif biome_type == df.biome_type.SWAMP_TROPICAL_FRESHWATER then
	  return 'P'
    elseif biome_type == df.biome_type.SWAMP_TROPICAL_SALTWATER then
	  return 'R'
    elseif biome_type == df.biome_type.SWAMP_MANGROVE then
	  return 'M'
    elseif biome_type == df.biome_type.MARSH_TROPICAL_FRESHWATER then
	  return 'N'
    elseif biome_type == df.biome_type.MARSH_TROPICAL_SALTWATER then
	  return 'Y'
    elseif biome_type == df.biome_type.FOREST_TAIGA then
	  return 'T'
    elseif biome_type == df.biome_type.FOREST_TEMPERATE_CONIFER then
	  return 'c'
    elseif biome_type == df.biome_type.FOREST_TEMPERATE_BROADLEAF then
	  return 'l'
    elseif biome_type == df.biome_type.FOREST_TROPICAL_CONIFER then
	  return 'C'
    elseif biome_type == df.biome_type.FOREST_TROPICAL_DRY_BROADLEAF then
	  return 'd'
    elseif biome_type == df.biome_type.FOREST_TROPICAL_MOIST_BROADLEAF then
	  return 'L'
    elseif biome_type == df.biome_type.GRASSLAND_TEMPERATE then
	  return 'g'
    elseif biome_type == df.biome_type.SAVANNA_TEMPERATE then
	  return 's'
    elseif biome_type == df.biome_type.SHRUBLAND_TEMPERATE then
	  return 'u'
    elseif biome_type == df.biome_type.GRASSLAND_TROPICAL then
	  return 'G'
    elseif biome_type == df.biome_type.SAVANNA_TROPICAL then
	  return 'S'
    elseif biome_type == df.biome_type.SHRUBLAND_TROPICAL then
	  return 'U'
    elseif biome_type == df.biome_type.DESERT_BADLAND then
	  return 'B'
    elseif biome_type == df.biome_type.DESERT_ROCK then
	  return 'e'
    elseif biome_type == df.biome_type.DESERT_SAND then
	  return 'D'
    elseif biome_type == df.biome_type.OCEAN_TROPICAL then
	  return 'O'
    elseif biome_type == df.biome_type.OCEAN_TEMPERATE then
	  return 'o'
    elseif biome_type == df.biome_type.OCEAN_ARCTIC then
	  return 'a'
    elseif biome_type == df.biome_type.POOL_TEMPERATE_FRESHWATER then
	  return '.'
    elseif biome_type == df.biome_type.POOL_TEMPERATE_BRACKISHWATER then
	  return ':'
    elseif biome_type == df.biome_type.POOL_TEMPERATE_SALTWATER then
	  return '!'
    elseif biome_type == df.biome_type.POOL_TROPICAL_FRESHWATER then
	  return ','
    elseif biome_type == df.biome_type.POOL_TROPICAL_BRACKISHWATER then
	  return ';'
    elseif biome_type == df.biome_type.POOL_TROPICAL_SALTWATER then
	  return '|'
    elseif biome_type == df.biome_type.LAKE_TEMPERATE_FRESHWATER then
	  return '<'
    elseif biome_type == df.biome_type.LAKE_TEMPERATE_BRACKISHWATER then
	  return '-'
    elseif biome_type == df.biome_type.LAKE_TEMPERATE_SALTWATER then
	  return '['
    elseif biome_type == df.biome_type.LAKE_TROPICAL_FRESHWATER then
	  return '>'
    elseif biome_type == df.biome_type.LAKE_TROPICAL_BRACKISHWATER then
	  return '='
    elseif biome_type == df.biome_type.LAKE_TROPICAL_SALTWATER then
	  return ']'
    elseif biome_type == df.biome_type.RIVER_TEMPERATE_FRESHWATER then
	  return '\\'
    elseif biome_type == df.biome_type.RIVER_TEMPERATE_BRACKISHWATER then
	  return '%'
    elseif biome_type == df.biome_type.RIVER_TEMPERATE_SALTWATER then
	  return '('
    elseif biome_type == df.biome_type.RIVER_TROPICAL_FRESHWATER then
	  return '/'
    elseif biome_type == df.biome_type.RIVER_TROPICAL_BRACKISHWATER then
	  return '&'
    elseif biome_type == df.biome_type.RIVER_TROPICAL_SALTWATER then
	  return ')'
    elseif biome_type == df.biome_type.SUBTERRANEAN_WATER then  --  Never generated
	  return '_'
    elseif biome_type == df.biome_type.SUBTERRANEAN_CHASM then  --  Never generated
	  return '^'
    elseif biome_type == df.biome_type.SUBTERRANEAN_LAVA then
	  return '~'
    end
  end
  
  --============================================================

  function adjust_coordinates_region (x, y, delta)
    local adjusted_x = x
	local adjusted_y = y
	
    if delta == 1 then -- SW
	  adjusted_x = adjusted_x - 1
	  adjusted_y = adjusted_y + 1
		      
	elseif delta == 2 then  --  S
	  adjusted_y = adjusted_y + 1
				
	elseif delta == 3 then  --  SE
	  adjusted_x = adjusted_x + 1
	  adjusted_y = adjusted_y + 1
				
	elseif delta == 4 then  --  W
	  adjusted_x = adjusted_x - 1
				
	elseif delta == 5 then  --  Center
	  --  Don't need to adjust
			
	elseif delta == 6 then  -- E
	  adjusted_x = adjusted_x + 1
				
	elseif delta == 7 then  --  NW
	  adjusted_x = adjusted_x - 1
	  adjusted_y = adjusted_y - 1
				
	elseif delta == 8 then  --  N
	  adjusted_y = adjusted_y - 1
				
	elseif delta == 9 then  --  NE
	  adjusted_x = adjusted_x + 1
	  adjusted_y = adjusted_y - 1
				
	else
	  dfhack.print ("BUG: adjusted_coordinates_region delta out of range: ")
	  dfhack.println (delta)
	end
			    
	if adjusted_x < 0 then
	  adjusted_x = 0
	elseif adjusted_x >= map_width then
	  adjusted_x = map_width - 1
	end
			  
	if adjusted_y < 0 then
	  adjusted_y = 0
	elseif adjusted_y >= map_height then
	  adjusted_y = map_height - 1
	end
	
	return adjusted_x, adjusted_y
  end
    
  --============================================================

  function adjust_coordinates (x, y, delta)
    local adjusted_x = x
	local adjusted_y = y
	local offset
	
    if delta == 0 then -- NW
	  adjusted_x = adjusted_x - 1
	  adjusted_y = adjusted_y - 1
		      
	elseif delta == 1 then  --  N
	  adjusted_y = adjusted_y - 1
				
	elseif delta == 2 then  --  NE
	  adjusted_x = adjusted_x + 1
	  adjusted_y = adjusted_y - 1
				
	elseif delta == 3 then  --  W
	  adjusted_x = adjusted_x - 1
				
	elseif delta == 4 then  --  Center
	  --  Don't need to adjust
			
	elseif delta == 5 then  -- E
	  adjusted_x = adjusted_x + 1
				
	elseif delta == 6 then  --  SW
	  adjusted_x = adjusted_x - 1
	  adjusted_y = adjusted_y + 1
				
	elseif delta == 7 then  --  S
	  adjusted_y = adjusted_y + 1
				
	elseif delta == 8 then  --  SE
	  adjusted_x = adjusted_x + 1
	  adjusted_y = adjusted_y + 1
				
	else
	  dfhack.print ("BUG: adjusted_coordinates delta out of range: ")
	  dfhack.println (delta)
	end

	if adjusted_x < 0 then
	  adjusted_x = 0
	end
	
	if adjusted_y < 0 then
	  adjusted_y = 0
	end
	  
	return adjusted_x, adjusted_y
  end
  
  --============================================================

  local keybindings={
    biome={key="CUSTOM_B",
           desc="Show biome info of the embark surface. Static.          "},
    rainfall={key="CUSTOM_R",
           desc="Show rainfall at the current Z level of the embark.     "},
    vegetation={key="CUSTOM_G",
           desc="Show biome offset at the current Z level of the embark. "},
	--
	--  Vegetation currently matches Rainfall exactly, so it doesn't add anything, but that might change in the future.
    temperature={key="CUSTOM_T",
           desc="Show temperature at the current Z level of the embark.  "},
    evilness={key="CUSTOM_E",
           desc="Show evilness at the current Z level of the embark.     "},
    drainage={key="CUSTOM_D",
           desc="Show drainage at the current Z level of the embark.     "},
    volcanism={key="CUSTOM_V",
           desc="Show volcanism at the current Z level of the embark.    "},
    savagery={key="CUSTOM_S",
           desc="Show savagery at the current Z level of the embark.     "},
    salinity={key="CUSTOM_L",
           desc="Show salinity at the current Z level of the embark.     "},
    shear_biome={key="CUSTOM_H",
           desc="Show biome info of the current Z level.                 "},
    elevation={key="CUSTOM_Z",
           desc="Show elevation of the current Z level.                  "},
    broad_biome={key="CUSTOM_I",
           desc="Show broad biome of the current Z level.                "},
    up_z={key="CURSOR_UP_Z",
        desc="Step up one Z level"},
    down_z={key="CURSOR_DOWN_Z",
        desc="Step down one Z level"},
    up={key="CURSOR_UP",
	    desc="Pan view 1 step upwards"},
    down={key="CURSOR_DOWN",
	    desc="Pan view 1 step downwards"},
	left={key="CURSOR_LEFT",
	    desc="Pan view 1 step to the left"},
    right={key="CURSOR_RIGHT",
	    desc="Pan view 1 step to the right"},
	upleft={key="CURSOR_UPLEFT",
	    desc="Pan view 1 step up to the left"},
    upright={key="CURSOR_UPRIGHT",
	    desc="Pan view 1 step up to the right"},
	downleft={key="CURSOR_DOWNLEFT",
	    desc="Pan view 1 step down to the left"},
    downright={key="CURSOR_DOWNRIGHT",
	    desc="Pan view 1 step down to the right"},
    up_fast={key="CURSOR_UP_FAST",
	    desc="Pan view 10 step upwards"},
    down_fast={key="CURSOR_DOWN_FAST",
	    desc="Pan view 10 step downwards"},
	left_fast={key="CURSOR_LEFT_FAST",
	    desc="Pan view 10 step to the left"},
    right_fast={key="CURSOR_RIGHT_FAST",
	    desc="Pan view 10 step to the right"},
	upleft_fast={key="CURSOR_UPLEFT_FAST",
	    desc="Pan view 10 step up to the left"},
    upright_fast={key="CURSOR_UPRIGHT_FAST",
	    desc="Pan view 10 step up to the right"},
	downleft_fast={key="CURSOR_DOWNLEFT_FAST",
	    desc="Pan view 10 step down to the left"},
    downright_fast={key="CURSOR_DOWNRIGHT_FAST",
	    desc="Pan view 10 step down to the right"},
   help={key="HELP",
           desc="Show this help/info                                     "},
  }

  --============================================================

  function Fit_Right (Item, Size)
	if string.len (Item) > Size then
	  return string.rep ('#', Size)
	else
	  return string.rep (' ', Size - string.len (Item)) .. Item
	end
  end

  --============================================================

  function rangeColor(arg)
    if arg < 0 then
      return COLOR_WHITE
    elseif arg < 10 then
      return COLOR_LIGHTCYAN
    elseif arg < 20 then
      return COLOR_CYAN
    elseif arg < 30 then
      return COLOR_LIGHTBLUE
    elseif arg < 40 then
      return COLOR_BLUE
    elseif arg < 50 then
      return COLOR_LIGHTGREEN
    elseif arg < 60 then
      return COLOR_GREEN
    elseif arg < 70 then
      return COLOR_YELLOW
    elseif arg < 80 then
      return COLOR_LIGHTMAGENTA
    elseif arg < 90 then
      return COLOR_LIGHTRED
    elseif arg < 100 then
      return COLOR_RED
    elseif arg < 110 then
      return COLOR_GREY
    else
      return COLOR_DARKGREY
    end
  end

  --============================================================

  function BiomeColor (savagery, evilness)
    if evilness < 33 then
      if savagery < 33 then
        return COLOR_BLUE
      elseif savagery < 66 then
        return COLOR_GREEN
      else
        return COLOR_LIGHTCYAN
      end

    elseif evilness < 66 then
      if savagery < 33 then
        return COLOR_GREY
      elseif savagery < 66 then
        return COLOR_LIGHTGREEN
      else
        return COLOR_YELLOW
      end

    else
      if savagery < 33 then
        return COLOR_MAGENTA
      elseif savagery < 66 then
        return COLOR_LIGHTRED
      else
        return COLOR_RED
      end
    end
  end

  --============================================================

  function ElevationColor (elevation)
    if elevation < 100 then
	  return COLOR_WHITE
	elseif elevation < 120 then
	  return COLOR_LIGHTCYAN
	elseif elevation < 140 then
	  return COLOR_CYAN
	elseif elevation < 160 then
	  return COLOR_LIGHTBLUE
	elseif elevation < 180 then
	  return COLOR_BLUE
	elseif elevation < 200 then
	  return COLOR_LIGHTGREEN
	elseif elevation < 220 then
	  return COLOR_GREEN
	elseif elevation < 240 then
	  return COLOR_YELLOW
	elseif elevation < 260 then
	  return COLOR_LIGHTMAGENTA
	elseif elevation < 280 then
	  return COLOR_LIGHTRED
	elseif elevation < 300 then
	  return COLOR_RED
	elseif elevation < 350 then
	  return COLOR_GREY
	else
	  return COLOR_DARKGREY
	end
  end
  
  --============================================================

  function BroadBiomeCharacter (broad_biome)
    if broad_biome == df.world_region_type.Swamp then
	  return 'P'
	elseif broad_biome == df.world_region_type.Desert then
	  return 'D'
	elseif broad_biome == df.world_region_type.Jungle then
	  return 'J'
	elseif broad_biome == df.world_region_type.Mountains then
	  return 'M'
	elseif broad_biome == df.world_region_type.Ocean then
	  return 'O'
	elseif broad_biome == df.world_region_type.Lake then
	  return 'L'
	elseif broad_biome == df.world_region_type.Glacier then
	  return 'G'
	elseif broad_biome == df.world_region_type.Tundra then
	  return 'T'
	elseif broad_biome == df.world_region_type.Steppe then
	  return 'S'
	elseif broad_biome == df.world_region_type.Hills then
	  return 'H'
	else
	  return '*'
	end
 end
  
  --============================================================

  function find_Potential_Air_Biomes ()
    for i = -1, 1 do
	  for k = -1, 1 do
	    if embark_x + i >= 0 and
		   embark_x + i < map_width and
		   embark_y + k >= 0 and
		   embark_y + k < map_height then
		  local biome = df.global.world.world_data.region_map[embark_x + i]:_displace(embark_y + k)
		  local biome_type = get_biome_type (embark_y + k,
                                             map_height,
                                             biome.temperature,
                                             biome.elevation,
                                             biome.drainage,
                                             biome.rainfall,
                                             biome.salinity,
						                     biome.vegetation,
					                         biome.region_id)
		  local found = false
		  for m = 1, biome_set_count do
			if biome_set [m].biome == biome and
			   (biome_set [m].biome_type_1 == biome_type or
			    (biome_set [m].biome_type_2 ~= nil and
				 biome_set [m].biome_type_2 == biome_type)) then
			  found = true
			  break
			end
		  end
			
		  if not found then
		    for m = 1, potential_biome_set_count do
			  if potential_biome_set [m].biome == biome then
			    found = true
			    break
			  end
			end
	      end
		  
		  if not found then
			potential_biome_set_count = potential_biome_set_count + 1
			potential_biome_set [potential_biome_set_count] = {}
			potential_biome_set [potential_biome_set_count].biome = biome
			potential_biome_set [potential_biome_set_count].home_x = embark_x + i
			potential_biome_set [potential_biome_set_count].home_y = embark_y + k
			potential_biome_set [potential_biome_set_count].sav_evil_color = BiomeColor (biome.savagery, biome.evilness)
			potential_biome_set [potential_biome_set_count].biome_type = biome_type
		  end		  
		end
	  end
	end
  end
  
  --============================================================

  function Detect_Shear ()
	local tile_type
	
    for i = 0, math.floor (max_y / 16) - 1 do
      for k = 0, math.floor (max_x / 16) - 1 do
        for l = 0, max_z - 1 do
          tile_type = dfhack.maps.getTileType (k * 16, i * 16, max_z - 1 - l)
		  
          if dfhack.maps.getTileBiomeRgn (k * 16, i * 16, max_z - 1 - l) ~= nil then			
            if tile_type > df.tiletype.Void and
               tile_type ~= df.tiletype.OpenSpace and
               (tile_type < df.tiletype.BurningTreeTrunk or
                tile_type > df.tiletype.BurningTreeCapFloor) and
               (tile_type < df.tiletype.TreeRootSloping or
                tile_type > df.tiletype.TreeDeadTrunkInterior) and
               (tile_type < df.tiletype.ConstructedFloor or
                tile_type > df.tiletype.ConstructedRamp) and
               (tile_type < df.tiletype.ConstructedFloorTrackN or
                tile_type > df.tiletype.ConstructedFloorTrackNSEW) and
               (tile_type < df.tiletype.ConstructedRampTrackN or
                tile_type > df.tiletype.ConstructedRampTrackNSEW) then
              break
			end
		  end
		  
       	  local blockX = k
	      local tileX = 0
	      local blockY = i
	      local tileY = 0
	      local block = dfhack.maps.getTileBlock (k * 16, i * 16, max_z - 1 - l)
	      local des = block.designation [tileX] [tileY]
	      local offset = block.region_offset [des.biome]
		  local bx
		  local by
		  
		  if offset >= 0 and offset < 9 then
	        bx = block.region_pos.x + (offset % 3) - 1
	     
  		    if bx < 0 then
	          bx = 0
            elseif bx >= map_width then
	          bx = maxp_width - 1
	        end
	     
		    by = block.region_pos.y + math.floor (offset / 3) - 1
	     
		    if by < 0 then
	          by = 0
	        elseif by >= map_height then
	          by = map_height - 1
	        end		   
        		   
 	        local biome = df.global.world.world_data.region_map[bx]:_displace(by)
		    local biome_type = get_biome_type (by,
                                               map_height,
                                               biome.temperature,
                                               biome.elevation,
                                               biome.drainage,
                                               biome.rainfall,
                                               biome.salinity,
						                       biome.vegetation,
					                           biome.region_id)
						
		    local found = false
		    for m = 1, biome_set_count do
			  if biome_set [m].biome == biome then  --  We don't need to check the other parameters as air biome detection is done first.
			    found = true
			    break
			  end
		    end
			
		    if not found then
			  biome_set_count = biome_set_count + 1
			  biome_set [biome_set_count] = {}
			  biome_set [biome_set_count].biome = biome
			  biome_set [biome_set_count].home_x = bx
			  biome_set [biome_set_count].home_y = by
			  biome_set [biome_set_count].sav_evil_color = BiomeColor (biome.savagery, biome.evilness)
			  biome_set [biome_set_count].biome_type_1 = biome_type
			  biome_set [biome_set_count].air = true
			  --  biome_set [biome_set_count].biome_type_2 = nil  --  Redundant...
		    end
          end			
		end
      end
    end
  end
  
  --============================================================

  function Recalculate (z)
	if biome_map [z] == nil then
 	  biome_map [z] = {}
	
	  for i = 0, math.floor ((max_y - 1) / 16) do
	    for k = 0, math.floor (max_x - 1) / 16 do
		  local blockX = k
		  local blockY = i
		  local block = dfhack.maps.getBlock (k, i, z)
		  local is_air = true
		  local is_anomaly = false
		
		  for m = 0, 15 do
		    for n = 0, 15 do
		      if block.designation [m][n].biome ~= 0 then
			    is_air = false
			  end
			
			  if block.region_offset [block.designation [m][n].biome] < 0 or
			     block.region_offset [block.designation [m][n].biome] > 8 then
			     is_anomaly = true
			  end
		    end
		  end
		
		  if is_anomaly then
		    for m = 0, 15 do
		      if k == 0 then
		        biome_map [z] [i * 16 + m] = {}
	          end
		  
		      for n = 0, 15 do
			    biome_map [z] [i * 16 + m] [k * 16 + n] = {}
			    biome_map [z] [i * 16 + m] [k * 16 + n].is_anomaly = true				
		      end
		    end
		  
		  elseif is_air then  --  All tiles within the block have the same biome
		    local des = block.designation [0][0]
	        local offset = block.region_offset [des.biome]		
		    local bx
		    local by
		    local biome
			local biome_reference_x
			local biome_reference_y

		    if block.region_pos.x ~= embark_x or 
		       block.region_pos.y ~= embark_y then
		       dfhack.print ("Illegal block self reference for block at x: ")
		       dfhack.print (k)
		       dfhack.print (", y: ")
		       dfhack.print (i)
		       dfhack.print (", z: ")
		       dfhack.print (z)
		       dfhack.print (", referring to: x: ")
		       dfhack.print (block.region_pos.x)
		       dfhack.print (", y: ")
		       dfhack.println (block.region_pos.y)
		    end

	        bx = block.region_pos.x + (offset % 3) - 1
	     
		    if bx < 0 then
	          bx = 0
            elseif bx >= map_width then
	          bx = map_width - 1
	        end
	     
		    by = block.region_pos.y + math.floor(offset / 3) - 1
	     
		    if by < 0 then
	          by = 0
	        elseif by >= map_height then
	          by = map_height - 1
	        end

  	        biome = df.global.world.world_data.region_map[bx]:_displace(by)
		  
		    --  Adjust region tile to the one having the biome as the "main" one
		    local adjusted_x, adjusted_y = adjust_coordinates (embark_region_min_x + math.floor (k / 3),
   			                                                   embark_region_min_y + math.floor (i / 3),
															   des.biome)

		    local delta = df.global.world.world_data.region_details[0].biome[adjusted_x][adjusted_y]
		    if delta > 48 then  --  Embark tiles have their values incresed by 48
			  delta = delta - 48
		    end
						
		    biome_reference_x, biome_reference_y = adjust_coordinates_region (embark_x, embark_y, delta)

		    for m = 0, 15 do
		      if k == 0 then
		        biome_map [z] [i * 16 + m] = {}
	          end
		  
		      for n = 0, 15 do
			    biome_map [z] [i * 16 + m] [k * 16 + n] = {}
			    biome_map [z] [i * 16 + m] [k * 16 + n].is_anomaly = false
			    biome_map [z] [i * 16 + m] [k * 16 + n].is_air = true
			    biome_map [z] [i * 16 + m] [k * 16 + n].biome = biome
			    biome_map [z] [i * 16 + m] [k * 16 + n].biome_home_x = bx
			    biome_map [z] [i * 16 + m] [k * 16 + n].biome_home_y = by
			    biome_map [z] [i * 16 + m] [k * 16 + n].biome_reference_x = biome_reference_x
			    biome_map [z] [i * 16 + m] [k * 16 + n].biome_reference_y = biome_reference_y
			    biome_map [z] [i * 16 + m] [k * 16 + n].biome_offset = des.biome
			    biome_map [z] [i * 16 + m] [k * 16 + n].broad_biome = df.global.world.world_data.regions[biome.region_id].type
			    biome_map [z] [i * 16 + m] [k * 16 + n].tile_type = df.tiletype.OpenSpace
				biome_map [z] [i * 16 + m] [k * 16 + n].biome_character = get_biome_character 
				 (biome_map [z][i * 16 + m] [k * 16 + n].is_air,
			      embark_y,
			      biome_map [z][i * 16 + m] [k * 16 + n].biome_reference_y,
				  biome_map [z][i * 16 + m] [k * 16 + n].biome_home_y,
                  map_height,
                  biome_map [z][i * 16 + m] [k * 16 + n].biome.temperature,
                  biome_map [z][i * 16 + m] [k * 16 + n].biome.elevation,
                  biome_map [z][i * 16 + m] [k * 16 + n].biome.drainage,
                  biome_map [z][i * 16 + m] [k * 16 + n].biome.rainfall,
                  biome_map [z][i * 16 + m] [k * 16 + n].biome.salinity,
				  biome_map [z][i * 16 + m] [k * 16 + n].biome.vegetation,
				  biome_map [z][i * 16 + m] [k * 16 + n].biome.region_id,
				  biome_map [z][i * 16 + m] [k * 16 + n].tile_type)
		      end
		    end
		  
	      else				
		    for m = 0, 15 do
		      if k == 0 then
		        biome_map [z] [i * 16 + m] = {}
	          end
		  
		      for n = 0, 15 do
		        local des = block.designation [n] [m]
	            local offset = block.region_offset [des.biome]
		        local bx
		        local by
		        local biome
				local biome_reference_x
				local biome_reference_y

		        if block.region_pos.x ~= embark_x or 
			       block.region_pos.y ~= embark_y then
		          dfhack.print ("Illegal block self reference for block at x: ")
		          dfhack.print (k)
		          dfhack.print (", y: ")
		          dfhack.print (i)
		          dfhack.print (", z: ")
		          dfhack.print (z)
		          dfhack.print (", referring to: x: ")
		          dfhack.print (block.region_pos.x)
		          dfhack.print (", y: ")
		          dfhack.println (block.region_pos.y)
		        end

	            bx = block.region_pos.x + (offset % 3) - 1
	     
		        if bx < 0 then
	              bx = 0
                elseif bx >= map_width then
	              bx = map_width - 1
	            end
	     
		        by = block.region_pos.y + math.floor(offset / 3) - 1
	     
		        if by < 0 then
	              by = 0
	            elseif by >= map_height then
	              by = map_height - 1
	            end

  	            biome = df.global.world.world_data.region_map[bx]:_displace(by)
		  
		        --  Adjust region tile to the one having the biome as the "main" one
		        local adjusted_x, adjusted_y = adjust_coordinates (embark_region_min_x + math.floor (k / 3),
   			                                                       embark_region_min_y + math.floor (i / 3),
																   des.biome)

		        local delta = df.global.world.world_data.region_details[0].biome[adjusted_x][adjusted_y]
		        if delta > 48 then  --  Embark tiles have their values incresed by 48
			      delta = delta - 48
		        end
						
		        biome_reference_x, biome_reference_y = adjust_coordinates_region (embark_x, embark_y, delta)
			  
			    biome_map [z] [i * 16 + m] [k * 16 + n] = {}
			    biome_map [z] [i * 16 + m] [k * 16 + n].is_anomaly = false
			    biome_map [z] [i * 16 + m] [k * 16 + n].is_air = false
			    biome_map [z] [i * 16 + m] [k * 16 + n].biome = biome
			    biome_map [z] [i * 16 + m] [k * 16 + n].biome_home_x = bx
			    biome_map [z] [i * 16 + m] [k * 16 + n].biome_home_y = by
			    biome_map [z] [i * 16 + m] [k * 16 + n].biome_reference_x = biome_reference_x
			    biome_map [z] [i * 16 + m] [k * 16 + n].biome_reference_y = biome_reference_y		      
			    biome_map [z] [i * 16 + m] [k * 16 + n].biome_offset = des.biome
			    biome_map [z] [i * 16 + m] [k * 16 + n].broad_biome = df.global.world.world_data.regions[biome.region_id].type
			    biome_map [z] [i * 16 + m] [k * 16 + n].tile_type = dfhack.maps.getTileType (k * 16 + n, i * 16 + m, z)
				biome_map [z] [i * 16 + m] [k * 16 + n].biome_character = get_biome_character 
				 (biome_map [z][i * 16 + m] [k * 16 + n].is_air,
			      embark_y,
			      biome_map [z][i * 16 + m] [k * 16 + n].biome_reference_y,
				  biome_map [z][i * 16 + m] [k * 16 + n].biome_home_y,
                  map_height,
                  biome_map [z][i * 16 + m] [k * 16 + n].biome.temperature,
                  biome_map [z][i * 16 + m] [k * 16 + n].biome.elevation,
                  biome_map [z][i * 16 + m] [k * 16 + n].biome.drainage,
                  biome_map [z][i * 16 + m] [k * 16 + n].biome.rainfall,
                  biome_map [z][i * 16 + m] [k * 16 + n].biome.salinity,
				  biome_map [z][i * 16 + m] [k * 16 + n].biome.vegetation,
				  biome_map [z][i * 16 + m] [k * 16 + n].biome.region_id,
				  biome_map [z][i * 16 + m] [k * 16 + n].tile_type)
		      end
		    end		
	      end
	    end
	  end
	end
  end

  --============================================================

  BiomeViewerUi = defclass(BiomeViewerUi, gui.FramedScreen)
  BiomeViewerUi.ATTRS = {
    frame_style = gui.GREY_LINE_FRAME,
    frame_title = "Biome Viewer",
  }

  --============================================================

  function BiomeViewerUi:onHelp ()
    self.subviews.pages:setSelected (2)
	focus = "Help"
  end

  --============================================================

  function fit_biome (s)
	return s .. string.rep (' ', string.len ('FOREST_TROPICAL_MOIST_BROADLEAF') - string.len (s))  --  The longest name
  end
  
  --============================================================

   function biome_level_indicator_2 (line, biome_count, biome)
	if line > biome_count then
	  return "     "
	elseif biome [line].air then
	  return " Air "
	else
	  return " Gnd "
	end  
  end
  
  --============================================================

  function biome_level_indicator_2_color (line, biome_count, biome)
	if line > biome_count then
	  return dfhack.pen.parse {fg = COLOR_WHITE, bg = 0}
	elseif biome [line].air then
	  return dfhack.pen.parse {fg = COLOR_RED, bg = 0}
	else
	  return dfhack.pen.parse {fg = COLOR_WHITE, bg = 0}
	end  
  end
  
  --============================================================

  function biome_line_2 (line, biome_count, biome)
	if line == 0 then
  	  return tostring (biome_count) .. " biomes found.     Air only/ground Potential biomes in anomalies: "
	elseif line <= biome_count then	 
	  return fit_biome (df.biome_type [biome [line].biome_type])
	else
	  return fit_biome ("")
	end
  end
  
  --============================================================
  
  function biome_line_2_color (line, biome_count, biome)
	if line == 0 then
  	  return dfhack.pen.parse {fg = COLOR_WHITE, bg = 0}
	elseif line <= biome_count then	 
	  return dfhack.pen.parse {fg = biome [line].sav_evil_color, bg = 0}
	else
	  return dfhack.pen.parse {fg = COLOR_WHITE, bg = 0}
	end
  end

  --============================================================

  function Disclaimer (biome_set_count, biome_set, potential_biome_set_count, potential_biome_set)
    local certain_biome = {}
	local certain_biome_count = 0
	local potential_biome = {}
	local potential_biome_count = 0
	
	for i = 1, biome_set_count do
	  local found = false
	  
	  for k = 1, certain_biome_count do
	    if certain_biome [k].biome_type == biome_set [i].biome_type_1 and
		   certain_biome [k].sav_evil_color == biome_set [i].sav_evil_color then
		     found = true
			 certain_biome [k].air = certain_biome [k].air and biome_set [i].air
			 break
	    end
	  end
	  
	  if not found then
	    certain_biome_count = certain_biome_count + 1
		certain_biome [certain_biome_count] = {biome_type = biome_set [i].biome_type_1,
		                                       sav_evil_color = biome_set [i].sav_evil_color,
											   air = biome_set [i].air}
	  end
	  
	  found = false
	  
	  for k = 1, certain_biome_count do
	    if biome_set [i].biome_type_2 ~= nil and
		   certain_biome [k].biome_type == biome_set [i].biome_type_2 and
		   certain_biome [k].sav_evil_color == biome_set [i].sav_evil_color then
		     found = true
			 certain_biome [k].air = false  --  The second biome is always a surface one
			 break
	    end
	  end
	  
	  if not found and
	     biome_set [i].biome_type_2 ~= nil then
	    certain_biome_count = certain_biome_count + 1
		certain_biome [certain_biome_count] = {biome_type = biome_set [i].biome_type_2,
		                                       sav_evil_color = biome_set [i].sav_evil_color,
											   air = false}
	  end
	end
	
	for i = 1, potential_biome_set_count do
	  local found = false
	  
	  for k = 1, potential_biome_count do
	    if potential_biome_set [i].biome_type == potential_biome [k].biome_type and
		   potential_biome_set [i].sav_evil_color == potential_biome [k].sav_evil_color then
		   found = true
		   break
		end
	  end
		
	  for k = 1, certain_biome_count do
	    if certain_biome [k].biome_type == potential_biome_set [i].biome_type and
		   certain_biome [k].sav_evil_color == potential_biome_set [i].sav_evil_color then
		     found = true
			 break
	    end
	  end

	  if not found then
		potential_biome_count = potential_biome_count + 1
		potential_biome [potential_biome_count] = {biome_type = potential_biome_set [i].biome_type,
		                                           sav_evil_color = potential_biome_set [i].sav_evil_color}
	  end
	end

	local help_line = 1
	local help_row
	local help_row_max = 0
	
    --==========================================================

	function add_help (s)
	  if not help_screen [help_line] then
	    help_screen [help_line] = {}
		help_row = 1
	  end	
		
	  for i = 1, s:len() do
	    help_screen [help_line] [help_row] = s:sub (i, i)
		help_row = help_row + 1
	  end
	end
	
    --==========================================================

	function add_help_newline ()
	  if not help_screen [help_line] then
	    help_screen [help_line] = {}
		help_row = 1
	  end	
		
	  help_screen [help_line] [help_row] = NEWLINE
	  help_line = help_line + 1
	  if help_row > help_row_max then
	    help_row_max = help_row
	  end
	end
	
    --==========================================================

	function add_help_line (s)
	  add_help (s)
	  add_help_newline ()
	end
	
    --==========================================================

	function add_help_pen (s, pen)
	  if not help_screen [help_line] then
	    help_screen [help_line] = {}
		help_row = 1
	  end	
		
	  for i = 1, s:len () do
	    help_screen [help_line] [help_row] = {text = s:sub (i, i), pen = pen}
		help_row = help_row + 1
	  end
	end
	
    --==========================================================

	function add_help_pen_line (s, pen)
	  add_help_pen (s, pen)
	  add_help_newline ()
	end
	
    --==========================================================

	add_help_line ("The purposes of showbiomes are to display the surface biomes of the embark, the indentified air biomes in the air above the embark (the main air biome")
	add_help_line ("seems to be the biome of the world map tile to the NW of the embark), and the locations of 'biome shears', i.e. blocks of the air space that have an")
	add_help_line ("unidentified biome that may match either a known one, or be one of the biomes of the surrounding world map tiles, including the embark itself. The")
	add_help_line ("identified biomes are listed below, with the 'Air only/ground' indicator showing if it appears in the air only (if present in both locations it's shown as")
	add_help_line ("ground. Finally, the indication below shows the additional surrounding biomes that may appear in 'biome shears'. The lists are collated so similar biomes")
	add_help_line ("are displayed only once, and the potential list only shows potential biomes not present in the first list. The base biome, other air only biomes, and biome")
	add_help_line ("shears can result in unexpected appearance of creatures and weather (such as undead fliers in an embark without evil surface biomes).")
	add_help_line ("showbiomes displays the surface (ground/water) biome in the main view and biome and environmental information about the embark on a per Z level basis,")
	add_help_line ("in the others. I.e. it displays the information for a single Z level at a time, starting around the ground level of the embark (usually slightly above).")
   	add_help_line ("The Current Z Biome screenshows the biomes at the displayed Z level, which indicates what kind of plants you might grow there if a plot was set up there")
	add_help_line ("(you still need to aquire the seeds, of course), and wild plants do not appear on levels that did not start out at ground level or below (and since dug")
	add_help_line ("out), even if soil is provided, but muddied farm plots can still be built.")
	add_help_line ("The script provides panning of the view. This help screen is panned independently from the others (which use a common panning offset).")
	add_help_line ("The Biome offset shows an internal DF value of little value to a user. Likewise, the broad biome shows the value assigned to the region of the biome.")
    add_help_line ("The script also prints out which biomes it has detected in the DFHack window, and this list is not collated, so similar biomes can appear in it.")
	add_help_line ("Legends: The parameter views are coded using a color for the magnitude of the value (each range of 10), with the single digit displayed in that color.")
	add_help_line ("The exception is Elevation which has too great a range. The single digit is still displayed, but the actual decile within the range is not displayed.")
    add_help_line ("The color ranges are:  General parameters                               Elevation")
	add_help_pen_line ("WHITE        < 0, with the actual decile lost.                        < 100", dfhack.pen.parse {fg = COLOR_WHITE, bg = 0})
	add_help_pen_line ("LIGHT CYAN     0 -   9                                                  100 - 119", dfhack.pen.parse {fg = COLOR_LIGHTCYAN, bg = 0})
	add_help_pen_line ("CYAN          10 -  19                                                  120 - 139", dfhack.pen.parse {fg = COLOR_CYAN, bg = 0})
	add_help_pen_line ("LIGHT BLUE    20 -  29                                                  140 - 159", dfhack.pen.parse {fg = COLOR_LIGHTBLUE, bg = 0})
	add_help_pen_line ("BLUE          30 -  39                                                  160 - 179", dfhack.pen.parse {fg = COLOR_BLUE, bg = 0})
	add_help_pen_line ("LIGHT GREEN   40 -  49                                                  180 - 199", dfhack.pen.parse {fg = COLOR_LIGHTGREEN, bg = 0})
	add_help_pen_line ("GREEN         50 -  59                                                  200 - 219", dfhack.pen.parse {fg = COLOR_GREEN, bg = 0})
	add_help_pen_line ("YELLOW        60 -  69                                                  220 - 239", dfhack.pen.parse {fg = COLOR_YELLOW, bg = 0})
	add_help_pen_line ("LIGHT MAGENTA 70 -  79                                                  240 - 259", dfhack.pen.parse {fg = COLOR_LIGHTMAGENTA, bg = 0})
	add_help_pen_line ("LIGHT RED     80 -  89                                                  260 - 279", dfhack.pen.parse {fg = COLOR_LIGHTRED, bg = 0})
	add_help_pen_line ("RED           90 -  99                                                  280 - 299", dfhack.pen.parse {fg = COLOR_RED, bg = 0})
	add_help_pen_line ("GREY         100 - 109                                                  300 - 349", dfhack.pen.parse {fg = COLOR_GREY, bg = 0})
	add_help_pen_line ("DARK GREY  > 109, with the actual decile lost.                        > 349", dfhack.pen.parse {fg = COLOR_DARKGREY, bg = 0})
	add_help_newline ()
	add_help_line ("The biome map uses a different color coding to indicate savagery + evilness and a large number of characters to indicate various biome versions.")
	add_help_line ("The biomes listed are the ones present in the corresponding DF enumeration, (except for Subterranean Chasm and Subterranean Water which aren't detected).")
	add_help_newline ()
	add_help_line ("Color coding key:")
	add_help_pen ("Serene       ", dfhack.pen.parse {fg = COLOR_BLUE, bg = 0})
	add_help_pen ("Mirthful     ", dfhack.pen.parse {fg = COLOR_GREEN, bg = 0})
	add_help_pen ("Joyous Wilds ", dfhack.pen.parse {fg = COLOR_LIGHTCYAN, bg = 0})
	add_help_newline ()
	add_help_pen ("Calm         ", dfhack.pen.parse {fg = COLOR_GREY, bg = 0})
	add_help_pen ("Wilderness   ", dfhack.pen.parse {fg = COLOR_LIGHTGREEN, bg = 0})
	add_help_pen ("Untamed Wilds", dfhack.pen.parse {fg = COLOR_YELLOW, bg = 0})
	add_help_newline ()
	add_help_pen ("Sinister     ", dfhack.pen.parse {fg = COLOR_MAGENTA, bg = 0})
	add_help_pen ("Haunted      ", dfhack.pen.parse {fg = COLOR_LIGHTRED, bg = 0})
	add_help_pen ("Terrifying   ", dfhack.pen.parse {fg = COLOR_RED, bg = 0})
	add_help_newline ()
	add_help_newline ()
	add_help_line ("The environment character symbols use lower case for the temperate version and upper case for the tropical one. The one exception is d/D.")
    add_help_newline ()
    add_help ("Normal                                                         Broad         ")
	add_help_pen (biome_line_2 (0, certain_biome_count, certain_biome), biome_line_2_color (0, certain_biome_count, certain_biome))
	add_help_line (tostring (potential_biome_count))
	add_help_line ("a = Arctic Ocean")
	add_help ("                               B = Badlands                    D = Desert    ")
	add_help_pen (biome_line_2 (1, certain_biome_count, certain_biome), biome_line_2_color (1, certain_biome_count, certain_biome))
	add_help_pen (biome_level_indicator_2 (1, certain_biome_count, certain_biome), biome_level_indicator_2_color (1, certain_biome_count, certain_biome))
	add_help_pen_line (biome_line_2 (1, potential_biome_count, potential_biome), biome_line_2_color (1, potential_biome_count, potential_biome))
	add_help ("c = Temperate Conifer          C = Tropical Conifer            G = Glacier   ")
	add_help_pen (biome_line_2 (2, certain_biome_count, certain_biome), biome_line_2_color (2, certain_biome_count, certain_biome))
	add_help_pen (biome_level_indicator_2 (2, certain_biome_count, certain_biome), biome_level_indicator_2_color (2, certain_biome_count, certain_biome))
	add_help_pen_line (biome_line_2 (2, potential_biome_count, potential_biome), biome_line_2_color (2, potential_biome_count, potential_biome))
	add_help ("d = Dry Tropical Broadleaf     D = Sand Desert                 H = Hills     ")
	add_help_pen (biome_line_2 (3, certain_biome_count, certain_biome), biome_line_2_color (3, certain_biome_count, certain_biome))
	add_help_pen (biome_level_indicator_2 (3, certain_biome_count, certain_biome), biome_level_indicator_2_color (3, certain_biome_count, certain_biome))
	add_help_pen_line (biome_line_2 (3, potential_biome_count, potential_biome), biome_line_2_color (3, potential_biome_count, potential_biome))
	add_help ("e = Rocky Desert                                               J = Jungle    ")
	add_help_pen (biome_line_2 (4, certain_biome_count, certain_biome), biome_line_2_color (4, certain_biome_count, certain_biome))
	add_help_pen (biome_level_indicator_2 (4, certain_biome_count, certain_biome), biome_level_indicator_2_color (4, certain_biome_count, certain_biome))
	add_help_pen_line (biome_line_2 (4, potential_biome_count, potential_biome), biome_line_2_color (4, potential_biome_count, potential_biome))
	add_help ("g = Temperate Grassland        G = Tropical Grassland          L = Lake      ")
	add_help_pen (biome_line_2 (5, certain_biome_count, certain_biome), biome_line_2_color (5, certain_biome_count, certain_biome))
	add_help_pen (biome_level_indicator_2 (5, certain_biome_count, certain_biome), biome_level_indicator_2_color (5, certain_biome_count, certain_biome))
	add_help_pen_line (biome_line_2 (5, potential_biome_count, potential_biome), biome_line_2_color (5, potential_biome_count, potential_biome))
	add_help ("l = Temperate Broadleaf        L = Tropical Moist Broadleaf    M = Mountain  ")
	add_help_pen (biome_line_2 (6, certain_biome_count, certain_biome), biome_line_2_color (6, certain_biome_count, certain_biome))
	add_help_pen (biome_level_indicator_2 (6, certain_biome_count, certain_biome), biome_level_indicator_2_color (6, certain_biome_count, certain_biome))
	add_help_pen_line (biome_line_2 (6, potential_biome_count, potential_biome), biome_line_2_color (6, potential_biome_count, potential_biome))
	add_help ("                               M = Mangrove Swamp              O = Ocean     ")
	add_help_pen (biome_line_2 (7, certain_biome_count, certain_biome), biome_line_2_color (7, certain_biome_count, certain_biome))
	add_help_pen (biome_level_indicator_2 (7, certain_biome_count, certain_biome), biome_level_indicator_2_color (7, certain_biome_count, certain_biome))
	add_help_pen_line (biome_line_2 (7, potential_biome_count, potential_biome), biome_line_2_color (7, potential_biome_count, potential_biome))
	add_help ("n = Temperate Freshwater Marsh N = Tropical Freshwater Marsh   P = Swamp     ")
	add_help_pen (biome_line_2 (8, certain_biome_count, certain_biome), biome_line_2_color (8, certain_biome_count, certain_biome))
	add_help_pen (biome_level_indicator_2 (8, certain_biome_count, certain_biome), biome_level_indicator_2_color (8, certain_biome_count, certain_biome))
	add_help_pen_line (biome_line_2 (8, potential_biome_count, potential_biome), biome_line_2_color (8, potential_biome_count, potential_biome))
	add_help ("o = Temperate Ocean            O = Tropical Ocean              S = Steppe    ")
	add_help_pen (biome_line_2 (9, certain_biome_count, certain_biome), biome_line_2_color (9, certain_biome_count, certain_biome))
	add_help_pen (biome_level_indicator_2 (9, certain_biome_count, certain_biome), biome_level_indicator_2_color (9, certain_biome_count, certain_biome))
	add_help_pen_line (biome_line_2 (9, potential_biome_count, potential_biome), biome_line_2_color (9, potential_biome_count, potential_biome))
	add_help ("p = Temperate Freshwater Swamp P = Tropical Freshwater Swamp   T = Tundra    ")
	add_help_pen (biome_line_2 (10, certain_biome_count, certain_biome), biome_line_2_color (10, certain_biome_count, certain_biome))
	add_help_pen (biome_level_indicator_2 (10, certain_biome_count, certain_biome), biome_level_indicator_2_color (10, certain_biome_count, certain_biome))
	add_help_pen_line (biome_line_2 (10, potential_biome_count, potential_biome), biome_line_2_color (10, potential_biome_count, potential_biome))
	add_help ("r = Temperate Saltwater Swamp  R = Tropical Saltwater Swamp                  ")
	add_help_pen (biome_line_2 (11, certain_biome_count, certain_biome), biome_line_2_color (11, certain_biome_count, certain_biome))
	add_help_pen (biome_level_indicator_2 (11, certain_biome_count, certain_biome), biome_level_indicator_2_color (11, certain_biome_count, certain_biome))
	add_help_pen_line (biome_line_2 (11, potential_biome_count, potential_biome), biome_line_2_color (11, potential_biome_count, potential_biome))
	add_help ("s = Temperate Savanna          S = Tropical Savanna                          ")
	add_help_pen (biome_line_2 (12, certain_biome_count, certain_biome), biome_line_2_color (12, certain_biome_count, certain_biome))
	add_help_pen (biome_level_indicator_2 (12, certain_biome_count, certain_biome), biome_level_indicator_2_color (12, certain_biome_count, certain_biome))
	add_help_pen_line (biome_line_2 (12, potential_biome_count, potential_biome), biome_line_2_color (12, potential_biome_count, potential_biome))
	add_help ("t = Tundra                     T = Taiga                                     ")
	add_help_pen (biome_line_2 (13, certain_biome_count, certain_biome), biome_line_2_color (13, certain_biome_count, certain_biome))
	add_help_pen (biome_level_indicator_2 (13, certain_biome_count, certain_biome), biome_level_indicator_2_color (13, certain_biome_count, certain_biome))
	add_help_pen_line (biome_line_2 (13, potential_biome_count, potential_biome), biome_line_2_color (13, potential_biome_count, potential_biome))
	add_help ("u = Temperate Shrubland        U = Tropical Shrubland                        ")
	add_help_pen (biome_line_2 (14, certain_biome_count, certain_biome), biome_line_2_color (14, certain_biome_count, certain_biome))
	add_help_pen (biome_level_indicator_2 (14, certain_biome_count, certain_biome), biome_level_indicator_2_color (14, certain_biome_count, certain_biome))
	add_help_pen_line (biome_line_2 (14, potential_biome_count, potential_biome), biome_line_2_color (14, potential_biome_count, potential_biome))
	add_help ("Y = Temperate Saltwater Marsh  Y = Tropical Saltwater Marsh                  ")
	add_help_pen (biome_line_2 (15, certain_biome_count, certain_biome), biome_line_2_color (15, certain_biome_count, certain_biome))
	add_help_pen (biome_level_indicator_2 (15, certain_biome_count, certain_biome), biome_level_indicator_2_color (15, certain_biome_count, certain_biome))
	add_help_pen_line (biome_line_2 (15, potential_biome_count, potential_biome), biome_line_2_color (15, potential_biome_count, potential_biome))
	add_help ("+ = Mountain                   * = Glacier                                   ")
	add_help_pen (biome_line_2 (16, certain_biome_count, certain_biome), biome_line_2_color (16, certain_biome_count, certain_biome))
	add_help_pen (biome_level_indicator_2 (16, certain_biome_count, certain_biome), biome_level_indicator_2_color (16, certain_biome_count, certain_biome))
	add_help_pen_line (biome_line_2 (16, potential_biome_count, potential_biome), biome_line_2_color (16, potential_biome_count, potential_biome))
	add_help ("                               ~ = Subterranean Lava                         ")
	add_help_pen (biome_line_2 (17, certain_biome_count, certain_biome), biome_line_2_color (17, certain_biome_count, certain_biome))
	add_help_pen (biome_level_indicator_2 (17, certain_biome_count, certain_biome), biome_level_indicator_2_color (17, certain_biome_count, certain_biome))
	add_help_pen_line (biome_line_2 (17, potential_biome_count, potential_biome), biome_line_2_color (17, potential_biome_count, potential_biome))
	add_help (". = Temperate Freshwater Pool  , = Tropical Freshwater Pool                  ")
	add_help_pen (biome_line_2 (18, certain_biome_count, certain_biome), biome_line_2_color (18, certain_biome_count, certain_biome))
	add_help_pen (biome_level_indicator_2 (18, certain_biome_count, certain_biome), biome_level_indicator_2_color (18, certain_biome_count, certain_biome))
	add_help_pen_line (biome_line_2 (18, potential_biome_count, potential_biome), biome_line_2_color (18, potential_biome_count, potential_biome))
	add_help_line (": = Temperate Brackish Pool    ; = Tropical Brackish Pool")
	add_help_line ("! = Temperate Saltwater Pool   | = Tropical Saltwater Pool")
	add_help_line ("< = Temperate Freshwater Lake  > = Tropical Freshwater Lake")
	add_help_line ("- = Temperate Brackish Lake    = = Tropical Brackish Lake")
	add_help_line ("[ = Temperate Saltwater Lake   ] = Tropical Saltwater Lake")
	add_help_line ("\\ = Temperate Freshwater River / = Tropical Freshwater River")
	add_help_line ("% = Temperate Brackish River   & = Tropical Brackish River")
	add_help_line ("( = Temperate Saltwater River  ) = Tropical Saltwater River")
	add_help_newline ()
	add_help ("The location of the DF cursor, ignoring the Z dimension is displayed on top of all the views, provided the cursor is active, using this symbol: ")
    add_help_pen ("X", dfhack.pen.parse {fg = COLOR_BLACK, bg = COLOR_YELLOW, tile_color=true})
    add_help_pen (" ", dfhack.pen.parse {bg = COLOR_BLACK, tile_color = false})
    add_help_newline ()
	if cursor_x >= 0 and cursor_y >= 0 then
	  add_help_line ("The DF cursor location is X: " .. tostring (cursor_x) .. ", Y: " .. tostring (cursor_y) .. ", Z: " .. tostring (df.global.cursor.z))
	else
	  add_help_line ("There is no active DF cursor.")
	end
    add_help_newline ()
	add_help_line ("Disclaimers, caveats, etc:")
    add_help_line ("- The script is a CPU hog. While used the rendering of the data will use up a lot of CPU cycles even though the script itself does nothing (shifting Z")
    add_help_line ("  level results in collection of new data unless the level has been viewed before, but shifting view only selects which set of already collected data to present).")
    add_help_line ("- The script has not been extensively tested, so there are most probably bugs. Bug reports are gratefully received in the")
    add_help_line ("  http://www.bay12forums.com/smf/index.php?topic=160856.0 forum thread.")
    add_help_line ("- It's known changing the Z level to near the bottom of the embark will result in error output and no update in the window on some embarks. Since the purpose")
    add_help_line ("  of the script is to view the surface biomes and those of the air, there's no intention to investigate the issue, given that it doesn't result in a crash.")
    add_help_line ("- The script will probably not provide completely accurate information on developed embarks.")
	add_help_newline ()
    add_help_line ("Version 2.6, 2017-02-16")
	
	for line = 1, #help_screen do
	  if #help_screen [line] < help_row_max then
	    for row = #help_screen [line], help_row_max - 1 do  --  we need to replace the previous newline
		  help_screen [line] [row] = " "
		end
		
		help_screen [line] [help_row_max] = NEWLINE
	  end
	end
	
	help_max_x = help_row_max
	help_max_y = #help_screen
  end

  --============================================================

  function Transform_Surface_Data (x, y)
	local fg
	local bg
	local tile_color
    local ch

    for i = 0, max_y - 1 do
	  for k = 0, max_x - 1 do
		if k == cursor_x and i == cursor_y then
          ch = 'X'
	      fg = COLOR_BLACK
	      bg = COLOR_YELLOW		  
	      tile_color = true
		  
		else
		  ch = biome_map [0][i][k].biome_character
	      fg = BiomeColor (biome_map [0] [i] [k].biome.savagery,
			               biome_map [0] [i] [k].biome.evilness)
	      bg = COLOR_BLACK
	      tile_color = false
		end
				
	    Main_Page.Surface_Grid:set (k,
                         	        i,
							        {ch = ch,
		                             fg = fg,
							         bg = bg,
							         bold = false,
							         tile = nil,
							         tile_color = tile_color,
							         tile_fg = nil,
							         tile_bg = nil})
	  end
	end
  end
  
  --============================================================

  function Pan_Help ()
    local helptext = {{text="Help/Info"}, NEWLINE, NEWLINE}
	 
	for i = 1, help_length do
	  if i <= normal_key_index then
	    table.insert (helptext, {text = normal_key [i].desc, key = normal_key [i].key, key_sep = ": "})
	  else
	    table.insert (helptext, string.rep (" ", string.len (normal_key [1].desc) + 3))
	  end
	  
	  if i <= move_key_index then
	    table.insert (helptext, {text = move_key [i].desc, key = move_key [i].key, key_sep = ": "})
	  end
	  table.insert (helptext, NEWLINE)
	end

    table.insert(helptext, NEWLINE)

    for line = help_y, #help_screen do
	  for column = help_x, #help_screen [line] do
	    table.insert (helptext, help_screen [line] [column])
	  end
	end
	
	return helptext
  end
 
  --============================================================

  function BiomeViewerUi:init ()
    local screen_width, screen_height = dfhack.screen.getWindowSize ()

	Detect_Shear()
    Recalculate (z)

 	biome_map [0] = {}
	
    for i = 0, max_y - 1 do
      biome_map [0] [i] = {}
	  
      for k = 0, max_x - 1 do
        for l = 0, max_z - 1 do
          local biome 	  
       	  local blockX = math.floor (k / 16)
	      local tileX = k % 16
	      local blockY = math.floor (i / 16)
	      local tileY = i % 16
	      local block = dfhack.maps.getTileBlock (k, i, max_z - 1 - l)
	      local des = block.designation[tileX][tileY]
	      local offset = block.region_offset[des.biome]
		  local bx
		  local by
		  if offset >= 0 and offset < 9 then
	        bx = block.region_pos.x + (offset % 3) - 1
	     
		    if bx < 0 then
	          bx = 0
            elseif bx >= map_width then
	          bx = maxp_width - 1
	        end
	     
		    by = block.region_pos.y + math.floor(offset / 3) - 1
	     
		    if by < 0 then
	          by = 0
	        elseif by >= map_height then
	          by = map_height - 1
	        end

		  else
		    bx = block.region_pos.x
			by = block.region_pos.y
		  end
		  
  	      biome = df.global.world.world_data.region_map[bx]:_displace(by)
		 
          if biome ~= nil then
            tile_type = dfhack.maps.getTileType (k, i, max_z - 1 - l)
		  
            flow_size = dfhack.maps.getTileFlags
              (k, i, max_z - 1 - l).flow_size

            liquid_type = dfhack.maps.getTileFlags
                (k, i, max_z - 1 - l).liquid_type

            if tile_type > df.tiletype.RampTop and
               (tile_type ~= df.tiletype.OpenSpace or
			    (flow_size ~= 0 and
                 liquid_type == df.tile_liquid.Magma)) and
               (tile_type < df.tiletype.BurningTreeTrunk or
                tile_type > df.tiletype.BurningTreeCapFloor) and
               (tile_type < df.tiletype.TreeRootSloping or
                tile_type > df.tiletype.TreeDeadTrunkInterior) and
               (tile_type < df.tiletype.ConstructedFloor or
                tile_type > df.tiletype.ConstructedRamp) and
               (tile_type < df.tiletype.ConstructedFloorTrackN or
                tile_type > df.tiletype.ConstructedFloorTrackNSEW) and
               (tile_type < df.tiletype.ConstructedRampTrackN or
                tile_type > df.tiletype.ConstructedRampTrackNSEW) then

			  --  Adjust region tile to the one having the biome as the "main" one
			  local adjusted_x, adjusted_y = adjust_coordinates (embark_region_min_x + math.floor (k / 48),
   			                                                     embark_region_min_y + math.floor (i / 48),
																 des.biome)
			  local adjusted_embark_x = embark_x
			  local adjusted_embark_y = embark_y
			  local biome_reference_x
			  local biome_reference_y
			  local delta
			  
			  delta = df.global.world.world_data.region_details[0].biome[adjusted_x][adjusted_y]
			  if delta > 48 then  --  Embark tiles have their values incresed by 48
			    delta = delta - 48
			  end

			  biome_reference_x, biome_reference_y = adjust_coordinates_region (adjusted_embark_x, adjusted_embark_y, delta)
			  																		 
		      local biome_type = get_biome_type (biome_reference_y,
                                                 map_height,
                                                 biome.temperature,
                                                 biome.elevation,
                                                 biome.drainage,
                                                 biome.rainfall,
                                                 biome.salinity,
						                         biome.vegetation,
					                             biome.region_id)

 			  biome_map [0] [i] [k] = {}
			  biome_map [0] [i] [k].is_anomaly = false
			  biome_map [0] [i] [k].is_air = false
			  biome_map [0] [i] [k].biome = biome
			  biome_map [0] [i] [k].biome_home_x = bx
			  biome_map [0] [i] [k].biome_home_y = by
			  biome_map [0] [i] [k].biome_reference_x = biome_reference_x
			  biome_map [0] [i] [k].biome_reference_y = biome_reference_y		      
			  biome_map [0] [i] [k].biome_offset = des.biome
			  biome_map [0] [i] [k].broad_biome = df.global.world.world_data.regions[biome.region_id].type
			  biome_map [0] [i] [k].tile_type = tile_type
			  biome_map [0] [i] [k].biome_character = get_biome_character
			   (biome_map [0][i][k].is_air,
			    embark_y,
			    biome_map [0] [i] [k].biome_reference_y,
                biome_map [0] [i] [k].biome_home_y,
				map_height,
                biome_map [0] [i] [k].biome.temperature,
                biome_map [0] [i] [k].biome.elevation,
                biome_map [0] [i] [k].biome.drainage,
                biome_map [0] [i] [k].biome.rainfall,
                biome_map [0] [i] [k].biome.salinity,
				biome_map [0] [i] [k].biome.vegetation,
				biome_map [0] [i] [k].biome.region_id,
				biome_map [0] [i] [k].tile_type)

			  local found = false
			  for m = 1, biome_set_count do
			    if biome_set [m].biome == biome then
		          found = true
				  
				  if biome_set [m].biome_type_1 == biome_type then
				    biome_set [m].air = false
				  else
				    biome_set [m].biome_type_2 = biome_type
				  end
				  
				  break
			    end
			  end
			
			  if not found then
			    biome_set_count = biome_set_count + 1
				biome_set [biome_set_count] = {}
			    biome_set [biome_set_count].biome = biome
				biome_set [biome_set_count].home_x = biome_reference_x
				biome_set [biome_set_count].home_y = biome_reference_y
				biome_set [biome_set_count].sav_evil_color = BiomeColor (biome.savagery, biome.evilness)
				biome_set [biome_set_count].air = false
				biome_set [biome_set_count].biome_type_1 = biome_type
			  end
			  
              break
			end
          end
        end
      end
    end

	dfhack.print ("biomes found: ")
	dfhack.println (biome_set_count)
	for i = 1, biome_set_count do
	  dfhack.print ("Biome reference: x: ")
	  dfhack.print (biome_set [i].home_x)
	  dfhack.print (", y: ")
	  dfhack.print (biome_set [i].home_y)
	  dfhack.color (biome_set [i].sav_evil_color)
	  dfhack.print (", biome: ")
	  dfhack.print (df.biome_type [biome_set [i].biome_type_1])
	  dfhack.color(COLOR_RESET)
	  dfhack.print (", Savagery: ")
      dfhack.print (biome_set [i].biome.savagery)
	  dfhack.print (". Evilness: ")
	  dfhack.print (biome_set [i].biome.evilness)
	  if biome_set [i].air then
	    dfhack.println (", found in the air only")
	  else
	    dfhack.println (", found at ground level")
	  end
	  if biome_set [i].biome_type_2 ~= nil then
	    dfhack.print ("Biome reference: x: ")
	    dfhack.print (biome_set [i].home_x)
	    dfhack.print (", y: ")
	    dfhack.print (biome_set [i].home_y)
	    dfhack.color (biome_set [i].sav_evil_color)
	    dfhack.print (", biome: ")
	    dfhack.print (df.biome_type [biome_set [i].biome_type_2])
	    dfhack.color(COLOR_RESET)
	    dfhack.print (", Savagery: ")
        dfhack.print (biome_set [i].biome.savagery)
	    dfhack.print (". Evilness: ")
	    dfhack.print (biome_set [i].biome.evilness)
	    dfhack.println (", found at ground level")
	  end
	end
	
	find_Potential_Air_Biomes ()
	
	if potential_biome_set_count >= 1 then
	  dfhack.print ("Potential air biomes found:")
	  dfhack.println (potential_biome_set_count)
	  
	  for i = 1, potential_biome_set_count do
	    dfhack.print ("Biome reference x: ")
		dfhack.print (potential_biome_set [i].home_x)
		dfhack.print (", y: ")
		dfhack.print (potential_biome_set [i].home_y)
	    dfhack.color (potential_biome_set [i].sav_evil_color)
		dfhack.print (", biome: ")
	    dfhack.print (df.biome_type [potential_biome_set [i].biome_type])
	    dfhack.color(COLOR_RESET)
	    dfhack.print (", Savagery: ")
        dfhack.print (potential_biome_set [i].biome.savagery)
	    dfhack.print (". Evilness: ")
	    dfhack.println (potential_biome_set [i].biome.evilness)
	  end
	end
	
    self.stack = {}
    self.item_count = 0
    self.keys = {}
	
    for k,v in pairs(keybindings) do
	  if df.interface_key [v.key] >= df.interface_key.CURSOR_UP and
	     df.interface_key [v.key] <= df.interface_key.CURSOR_DOWN_Z then
	  	move_key_index = move_key_index + 1
	    move_key [move_key_index] = v
		 
	  else
	    normal_key_index = normal_key_index + 1
		normal_key [normal_key_index] = v
	  end
	end
	
	for i = 1, normal_key_index - 1 do
	  for k = i, normal_key_index do
	    if df.interface_key [normal_key [i].key] > 
	       df.interface_key [normal_key [k].key] then
		   local temp = normal_key [i]
		   normal_key [i] = normal_key [k]
		   normal_key [k] = temp
		end
	  end
	end
	
	for i = 1, move_key_index - 1 do
	  for k = i, move_key_index do
	    if df.interface_key [move_key [i].key] > 
	       df.interface_key [move_key [k].key] then
		   local temp = move_key [i]
		   move_key [i] = move_key [k]
		   move_key [k] = temp
		end
	  end
	end

	if move_key_index > normal_key_index then
	  help_length = move_key_index
	else
	  help_length = normal_key_index
	end
	
    Disclaimer(biome_set_count, biome_set, potential_biome_set_count, potential_biome_set)

    Main_Page.Header =
      widgets.Label {text = {{text = "Help/Info",
                              key = keybindings.help.key,
                              key_sep = '()'},
							 " X:     Y:     Z: "},
					 frame = {l = 1, t = 1, yalign = 0}}
					 
	Main_Page.X =
	  widgets.Label {text = Fit_Right (tostring (cursor_x), 3),
	                 frame = {l = 18, t = 1, yalign = 0}}
	  
	Main_Page.Y =
	  widgets.Label {text = Fit_Right (tostring (cursor_y), 3),
	                 frame = {l = 25, t = 1, yalign = 0}}

	Main_Page.Z =
	  widgets.Label {text = Fit_Right (tostring (z), 3),
	                 frame = {l = 32, t = 1, yalign = 0}}

	Main_Page.Legend =
	  widgets.Label {text = "Surface Biome",
	                 frame = {l = 36, t = 1, yalign = 0}}
		
	 Main_Page.Visibility_List = {}
	
	Main_Page.Surface_Grid = Grid {frame = {l = 1,
                                            t = 3,
										    r = math.min (max_x, screen_width - 2),
										    b = math.min (max_y + 3, screen_height - 2)},
	                               width = max_x,
								   height = max_y,
	                               visible = true}

	table.insert (Main_Page.Visibility_List, Main_Page.Surface_Grid)
	
    Main_Page.Rainfall_Grid = Grid {frame = {l = 1,
                                             t = 3,
										     r = math.min (max_x, screen_width - 2),
										     b = math.min (max_y + 3, screen_height - 2)},
	                                width = max_x,
								    height = max_y,
	                                visible = false}
									
	table.insert (Main_Page.Visibility_List, Main_Page.Rainfall_Grid)
	
    Main_Page.Biome_Offset_Grid = Grid {frame = {l = 1,
                                                 t = 3,
										         r = math.min (max_x, screen_width - 2),
										         b = math.min (max_y + 3, screen_height - 2)},
	                                    width = max_x,
								        height = max_y,
	                                    visible = false}
										
	table.insert (Main_Page.Visibility_List, Main_Page.Biome_Offset_Grid)
	
    Main_Page.Temperature_Grid = Grid {frame = {l = 1,
                                                t = 3,
										        r = math.min (max_x, screen_width - 2),
										        b = math.min (max_y + 3, screen_height - 2)},
	                                            width = max_x,
								                height = max_y,
	                                   visible = false}
									   
	table.insert (Main_Page.Visibility_List, Main_Page.Temperature_Grid)
	
    Main_Page.Evilness_Grid = Grid {frame = {l = 1,
                                             t = 3,
										     r = math.min (max_x, screen_width - 2),
										     b = math.min (max_y + 3, screen_height - 2)},
	                                width = max_x,
								    height = max_y,
	                                visible = false}

	table.insert (Main_Page.Visibility_List, Main_Page.Evilness_Grid)
	
	Main_Page.Drainage_Grid = Grid {frame = {l = 1,
                                             t = 3,
										     r = math.min (max_x, screen_width - 2),
										     b = math.min (max_y + 3, screen_height - 2)},
	                                width = max_x,
								    height = max_y,
	                                visible = false}
	
	table.insert (Main_Page.Visibility_List, Main_Page.Drainage_Grid)
	
    Main_Page.Volcanism_Grid = Grid {frame = {l = 1,
                                              t = 3,
										      r = math.min (max_x, screen_width - 2),
										      b = math.min (max_y + 3, screen_height - 2)},
	                                 width = max_x,
								     height = max_y,
	                                 visible = false}

	table.insert (Main_Page.Visibility_List, Main_Page.Volcanism_Grid)
	
    Main_Page.Savagery_Grid = Grid {frame = {l = 1,
                                             t = 3,
										     r = math.min (max_x, screen_width - 2),
										     b = math.min (max_y + 3, screen_height - 2)},
	                                width = max_x,
								    height = max_y,
	                                visible = false}

	table.insert (Main_Page.Visibility_List, Main_Page.Savagery_Grid)
	
    Main_Page.Salinity_Grid = Grid {frame = {l = 1,
                                             t = 3,
										     r = math.min (max_x, screen_width - 2),
										     b = math.min (max_y + 3, screen_height - 2)},
	                                width = max_x,
								    height = max_y,
	                                visible = false}

	table.insert (Main_Page.Visibility_List, Main_Page.Salinity_Grid)
	
    Main_Page.Shear_Biome_Grid = Grid {frame = {l = 1,
                                                t = 3,
										        r = math.min (max_x, screen_width - 2),
										        b = math.min (max_y + 3, screen_height - 2)},
	                                   width = max_x,
								       height = max_y,
	                                   visible = false}

	table.insert (Main_Page.Visibility_List, Main_Page.Shear_Biome_Grid)
	
    Main_Page.Elevation_Grid = Grid {frame = {l = 1,
                                              t = 3,
										      r = math.min (max_x, screen_width - 2), 
										      b = math.min (max_y + 3, screen_height - 2)},
	                                 width = max_x,
								     height = max_y,
	                                 visible = false}

	table.insert (Main_Page.Visibility_List, Main_Page.Elevation_Grid)
	
    Main_Page.Broad_Biome_Grid = Grid {frame = {l = 1,
                                                t = 3,
										        r = math.min (max_x, screen_width - 2),
										        b = math.min (max_y + 3, screen_height - 2)},
	                                   width = max_x,
								       height = max_y,
	                                   visible = false}

	table.insert (Main_Page.Visibility_List, Main_Page.Broad_Biome_Grid)

	Transform_Surface_Data (x, y)
	
    local mainPage = widgets.Panel {
        subviews=		
         {Main_Page.Header,
		  Main_Page.X,
		  Main_Page.Y,
		  Main_Page.Z,
		  Main_Page.Legend,
		  Main_Page.Surface_Grid,
		  Main_Page.Rainfall_Grid,
		  Main_Page.Biome_Offset_Grid,
		  Main_Page.Temperature_Grid,
		  Main_Page.Evilness_Grid,
		  Main_Page.Drainage_Grid,
		  Main_Page.Volcanism_Grid,
		  Main_Page.Savagery_Grid,
		  Main_Page.Salinity_Grid,
		  Main_Page.Shear_Biome_Grid,
		  Main_Page.Elevation_Grid,
		  Main_Page.Broad_Biome_Grid}}

    local helpPage = widgets.Panel {
        subviews={widgets.Label {text = Pan_Help (),
                  frame = {l = 1, t = 1, yalign = 0}}}}

    local pages = widgets.Pages 
      {subviews = {mainPage,
                   helpPage},view_id = "pages"}

    self:addviews{
        pages
    }
  end

  --============================================================

  function Update_Rainfall (x, y, z, pages)
	local fg
	local bg
	local tile_color
    local ch

	Main_Page.Legend:setText ("Rainfall")
	
    for i = 0, max_y - 1 do
	  for k = 0, max_x - 1 do
		if k == cursor_x and i == cursor_y then
          ch = 'X'
	      fg = COLOR_BLACK
	      bg = COLOR_YELLOW		  
	      tile_color = true
		  
		elseif biome_map [z] [i] [k].is_anomaly then
		  ch = '@'
		  fg = COLOR_RED
		  bg = COLOR_BLACK
		  tile_color = false
		  
		else
		  ch = tostring (biome_map [z][i][k].biome.rainfall % 10)
	      fg = rangeColor (biome_map [z] [i] [k].biome.rainfall)
	      bg = COLOR_BLACK
	      tile_color = false
		end
				
	    Main_Page.Rainfall_Grid:set (k,
                         	         i,
							         {ch = ch,
		                              fg = fg,
							          bg = bg,
							          bold = false,
							          tile = nil,
							          tile_color = tile_color,
							          tile_fg = nil,
							          tile_bg = nil})
	  end
	end
  end
  
  --============================================================

  function Update_Biome_Offset (x, y, z, pages)
	local fg
	local bg
	local tile_color
    local ch

	Main_Page.Legend:setText ("Biome Offset")
	
    for i = 0, max_y - 1 do
	  for k = 0, max_x - 1 do
		if k == cursor_x and i == cursor_y then
          ch = 'X'
	      fg = COLOR_BLACK
	      bg = COLOR_YELLOW		  
	      tile_color = true
		  
		elseif biome_map [z] [i] [k].is_anomaly then
		  ch = '@'
		  fg = COLOR_RED
		  bg = COLOR_BLACK
		  tile_color = false
		  
		else
		  ch = tostring (biome_map [z][i][k].biome_offset % 10)
	      fg = rangeColor (biome_map [z] [i] [k].biome_offset)
	      bg = COLOR_BLACK
	      tile_color = false
		end
				
	    Main_Page.Biome_Offset_Grid:set (k,
                         	             i,
							             {ch = ch,
		                                  fg = fg,
							              bg = bg,
							              bold = false,
							              tile = nil,
							              tile_color = tile_color,
							              tile_fg = nil,
							              tile_bg = nil})
	  end
	end
  end
  
  --============================================================

   function Update_Temperature (x, y, z, pages)
	local fg
	local bg
	local tile_color
    local ch

	Main_Page.Legend:setText ("Temperature")
	
    for i = 0, max_y - 1 do
	  for k = 0, max_x - 1 do
		if k == cursor_x and i == cursor_y then
          ch = 'X'
	      fg = COLOR_BLACK
	      bg = COLOR_YELLOW		  
	      tile_color = true
		  
		elseif biome_map [z] [i] [k].is_anomaly then
		  ch = '@'
		  fg = COLOR_RED
		  bg = COLOR_BLACK
		  tile_color = false
		  
		else
		  ch = tostring (biome_map [z][i][k].biome.temperature % 10)
	      fg = rangeColor (biome_map [z] [i] [k].biome.temperature)
	      bg = COLOR_BLACK
	      tile_color = false
		end
				
	    Main_Page.Temperature_Grid:set (k,
                         	            i,
							            {ch = ch,
		                                 fg = fg,
							             bg = bg,
							             bold = false,
							             tile = nil,
							             tile_color = tile_color,
							             tile_fg = nil,
							             tile_bg = nil})
	  end
	end
  end
 
  --============================================================

  function Update_Evilness (x, y, z, pages)
	local fg
	local bg
	local tile_color
    local ch

	Main_Page.Legend:setText ("Evilness")
	
    for i = 0, max_y - 1 do
	  for k = 0, max_x - 1 do
		if k == cursor_x and i == cursor_y then
          ch = 'X'
	      fg = COLOR_BLACK
	      bg = COLOR_YELLOW		  
	      tile_color = true
		  
		elseif biome_map [z] [i] [k].is_anomaly then
		  ch = '@'
		  fg = COLOR_RED
		  bg = COLOR_BLACK
		  tile_color = false
		  
		else
		  ch = tostring (biome_map [z][i][k].biome.evilness % 10)
	      fg = rangeColor (biome_map [z] [i] [k].biome.evilness)
	      bg = COLOR_BLACK
	      tile_color = false
		end
				
	    Main_Page.Evilness_Grid:set (k,
                         	         i,
							         {ch = ch,
		                              fg = fg,
							          bg = bg,
							          bold = false,
							          tile = nil,
							          tile_color = tile_color,
							          tile_fg = nil,
							          tile_bg = nil})
	  end
	end
  end
  
  --============================================================

  function Update_Drainage (x, y, z, pages)
	local fg
	local bg
	local tile_color
    local ch

	Main_Page.Legend:setText ("Drainage")
	
    for i = 0, max_y - 1 do
	  for k = 0, max_x - 1 do
		if k == cursor_x and i == cursor_y then
          ch = 'X'
	      fg = COLOR_BLACK
	      bg = COLOR_YELLOW		  
	      tile_color = true
		  
		elseif biome_map [z] [i] [k].is_anomaly then
		  ch = '@'
		  fg = COLOR_RED
		  bg = COLOR_BLACK
		  tile_color = false
		  
		else
		  ch = tostring (biome_map [z][i][k].biome.drainage % 10)
	      fg = rangeColor (biome_map [z] [i] [k].biome.drainage)
	      bg = COLOR_BLACK
	      tile_color = false
		end
				
	    Main_Page.Drainage_Grid:set (k,
                         	         i,
							         {ch = ch,
		                              fg = fg,
							          bg = bg,
							          bold = false,
							          tile = nil,
							          tile_color = tile_color,
							          tile_fg = nil,
							          tile_bg = nil})
	  end
	end
  end
  
  --============================================================

  function Update_Volcanism (x, y, z, pages)
	local fg
	local bg
	local tile_color
    local ch

	Main_Page.Legend:setText ("Volcanism")
	
    for i = 0, max_y - 1 do
	  for k = 0, max_x - 1 do
		if k == cursor_x and i == cursor_y then
          ch = 'X'
	      fg = COLOR_BLACK
	      bg = COLOR_YELLOW		  
	      tile_color = true
		  
		elseif biome_map [z] [i] [k].is_anomaly then
		  ch = '@'
		  fg = COLOR_RED
		  bg = COLOR_BLACK
		  tile_color = false
		  
		else
		  ch = tostring (biome_map [z][i][k].biome.volcanism % 10)
	      fg = rangeColor (biome_map [z] [i] [k].biome.volcanism)
	      bg = COLOR_BLACK
	      tile_color = false
		end
				
	    Main_Page.Volcanism_Grid:set (k,
                         	          i,
							          {ch = ch,
		                               fg = fg,
							           bg = bg,
							           bold = false,
							           tile = nil,
							           tile_color = tile_color,
							           tile_fg = nil,
							           tile_bg = nil})
	  end
	end
  end
  
  --============================================================

  function Update_Savagery (x, y, z, pages)
	local fg
	local bg
	local tile_color
    local ch

	Main_Page.Legend:setText ("Savagery")
	
    for i = 0, max_y - 1 do
	  for k = 0, max_x - 1 do
		if k == cursor_x and i == cursor_y then
          ch = 'X'
	      fg = COLOR_BLACK
	      bg = COLOR_YELLOW		  
	      tile_color = true
		  
		elseif biome_map [z] [i] [k].is_anomaly then
		  ch = '@'
		  fg = COLOR_RED
		  bg = COLOR_BLACK
		  tile_color = false
		  
		else
		  ch = tostring (biome_map [z][i][k].biome.savagery % 10)
	      fg = rangeColor (biome_map [z] [i] [k].biome.savagery)
	      bg = COLOR_BLACK
	      tile_color = false
		end
				
	    Main_Page.Savagery_Grid:set (k,
                         	         i,
							         {ch = ch,
		                              fg = fg,
							          bg = bg,
							          bold = false,
							          tile = nil,
							          tile_color = tile_color,
							          tile_fg = nil,
							          tile_bg = nil})
	  end
	end
  end
  
  
  --============================================================

  function Update_Salinity (x, y, z, pages)
	local fg
	local bg
	local tile_color
    local ch

	Main_Page.Legend:setText ("Salinity")
	
    for i = 0, max_y - 1 do
	  for k = 0, max_x - 1 do
		if k == cursor_x and i == cursor_y then
          ch = 'X'
	      fg = COLOR_BLACK
	      bg = COLOR_YELLOW		  
	      tile_color = true
		  
		elseif biome_map [z] [i] [k].is_anomaly then
		  ch = '@'
		  fg = COLOR_RED
		  bg = COLOR_BLACK
		  tile_color = false
		  
		else
		  ch = tostring (biome_map [z][i][k].biome.salinity % 10)
	      fg = rangeColor (biome_map [z] [i] [k].biome.salinity)
	      bg = COLOR_BLACK
	      tile_color = false
		end
				
	    Main_Page.Salinity_Grid:set (k,
                         	         i,
							         {ch = ch,
		                              fg = fg,
							          bg = bg,
							          bold = false,
							          tile = nil,
							          tile_color = tile_color,
							          tile_fg = nil,
							          tile_bg = nil})
	  end
	end
  end
  
  --============================================================

  function Update_Shear_Biome (x, y, z, pages)
	local fg
	local bg
	local tile_color
    local ch

	Main_Page.Legend:setText ("Shear Biome")
	
    for i = 0, max_y - 1 do
	  for k = 0, max_x - 1 do
		if k == cursor_x and i == cursor_y then
          ch = 'X'
	      fg = COLOR_BLACK
	      bg = COLOR_YELLOW		  
	      tile_color = true
		  
		elseif biome_map [z] [i] [k].is_anomaly then
		  ch = '@'
		  fg = COLOR_RED
		  bg = COLOR_BLACK
		  tile_color = false
		  
		else
		  ch = biome_map [z][i][k].biome_character
	      fg = BiomeColor (biome_map [z][i][k].biome.savagery, 
			               biome_map [z][i][k].biome.evilness)
	      bg = COLOR_BLACK
	      tile_color = false
		end
				
	    Main_Page.Shear_Biome_Grid:set (k,
                         	            i,
							            {ch = ch,
		                                 fg = fg,
							             bg = bg,
							             bold = false,
							             tile = nil,
							             tile_color = tile_color,
							             tile_fg = nil,
							             tile_bg = nil})
	  end
	end
  end
  
  --============================================================

  function Update_Elevation (x, y, z, pages)
	local fg
	local bg
	local tile_color
    local ch

	Main_Page.Legend:setText ("Elevation")
	
    for i = 0, max_y - 1 do
	  for k = 0, max_x - 1 do
		if k == cursor_x and i == cursor_y then
          ch = 'X'
	      fg = COLOR_BLACK
	      bg = COLOR_YELLOW		  
	      tile_color = true
		  
		elseif biome_map [z] [i] [k].is_anomaly then
		  ch = '@'
		  fg = COLOR_RED
		  bg = COLOR_BLACK
		  tile_color = false
		  
		else
		  ch = tostring(biome_map [z][i][k].biome.elevation % 10)
	      fg = ElevationColor (biome_map [z] [i] [k].biome.elevation)
	      bg = COLOR_BLACK
	      tile_color = false
		end
				
	    Main_Page.Elevation_Grid:set (k,
                         	          i,
							          {ch = ch,
		                               fg = fg,
							           bg = bg,
							           bold = false,
							           tile = nil,
							           tile_color = tile_color,
							           tile_fg = nil,
							           tile_bg = nil})
	  end
	end
  end
  
  --============================================================

  function Update_Broad_Biome (x, y, z, pages)
	local fg
	local bg
	local tile_color
    local ch

	Main_Page.Legend:setText ("Broad Biome")
	
    for i = 0, max_y - 1 do
	  for k = 0, max_x - 1 do
		if k == cursor_x and i == cursor_y then
          ch = 'X'
	      fg = COLOR_BLACK
	      bg = COLOR_YELLOW		  
	      tile_color = true
		  
		elseif biome_map [z] [i] [k].is_anomaly then
		  ch = '@'
		  fg = COLOR_RED
		  bg = COLOR_BLACK
		  tile_color = false
		  
		else
		  ch = BroadBiomeCharacter (biome_map [z][i][k].broad_biome)
	      fg = BiomeColor (biome_map [z][i][k].biome.savagery, 
		                   biome_map [z][i][k].biome.evilness)
	      bg = COLOR_BLACK
	      tile_color = false
		end
				
	    Main_Page.Broad_Biome_Grid:set (k,
                         	            i,
							            {ch = ch, 
		                                 fg = fg,
							             bg = bg,
							             bold = false,
							             tile = nil,
							             tile_color = tile_color,
							             tile_fg = nil,
							             tile_bg = nil})
	  end
	end
  end

  --============================================================

  function Update (x, y, z, pages)
    Main_Page.Z:setText (Fit_Right (z, 3))
	
    if focus == "Biome" then
	  --  Nothing needs to be done
	elseif focus == "Rainfall" then
	  Update_Rainfall (x, y, z, pages)
	  
	elseif focus == "Biome Offset" then
	  Update_Biome_Offset (x, y, z, pages)
	  
	elseif focus == "Temperature" then
	  Update_Temperature (x, y, z, pages)
	  
	elseif focus == "Evilness" then
	  Update_Evilness (x, y, z, pages)
	  
	elseif focus == "Drainage" then
	  Update_Drainage (x, y, z, pages)
	  
	elseif focus == "Volcanism" then
	  Update_Volcanism (x, y, z, pages)
	  
	elseif focus == "Savagery" then
	  Update_Savagery (x, y, z, pages)
	  
	elseif focus == "Salinity" then
	  Update_Salinity (x, y, z, pages)
	  
	elseif focus == "Shear Biome" then
	  Update_Shear_Biome (x, y, z, pages)
	  
	elseif focus == "Elevation" then
	  Update_Elevation (x, y, z, pages)
	  
	elseif focus == "Broad Biome" then
	  Update_Broad_Biome (x, y, z, pages)
	 
	else
	  dfhack.println ("Error: 'focus' failed to match " .. focus)
	end
  end
  
  --============================================================

  function Update_Help (pages)
    local helpPage = widgets.Panel {
        subviews={widgets.Label {text = Pan_Help (),
                  frame = {l = 1, t = 1, yalign = 0}}}}

    pages.subviews[2].subviews[1].text_lines = helpPage.subviews[1].text_lines
  end
  
  --============================================================

  function Pan (delta_x, delta_y)
	Main_Page.Surface_Grid:pan (delta_x, delta_y)
	Main_Page.Rainfall_Grid:pan (delta_x, delta_y)
	Main_Page.Biome_Offset_Grid:pan (delta_x, delta_y)
	Main_Page.Temperature_Grid:pan (delta_x, delta_y)
	Main_Page.Evilness_Grid:pan (delta_x, delta_y)
	Main_Page.Drainage_Grid:pan (delta_x, delta_y)
	Main_Page.Volcanism_Grid:pan (delta_x, delta_y)
	Main_Page.Savagery_Grid:pan (delta_x, delta_y)
	Main_Page.Salinity_Grid:pan (delta_x, delta_y)
	Main_Page.Shear_Biome_Grid:pan (delta_x, delta_y)
	Main_Page.Elevation_Grid:pan (delta_x, delta_y)
	Main_Page.Broad_Biome_Grid:pan (delta_x, delta_y)

	x = Main_Page.Surface_Grid.viewport.x1
	y = Main_Page.Surface_Grid.viewport.y1
--  
--    Main_Page.X:setText (Fit_Right (x, 3))
--	Main_Page.Y:setText (Fit_Right (y, 3))
  end
  
  --============================================================

  function BiomeViewerUi:onInput(keys)
    if keys.LEAVESCREEN_ALL  then
        self:dismiss()
    end
    
    if keys.LEAVESCREEN  then
            self:dismiss()
    end

    if keys[keybindings.biome.key] then
      self.subviews.pages:setSelected (1)
	  focus = "Biome"
      for i, item in ipairs (Main_Page.Visibility_List) do
	    item.visible = false
	  end
	  Main_Page.Surface_Grid.visible = true	  
	  Main_Page.Legend:setText ("Surface Biome")
	
    elseif keys[keybindings.rainfall.key] then
      self.subviews.pages:setSelected (1)
	  focus = "Rainfall"
	  Update_Rainfall (x, y, z, self.subviews.pages)
      for i, item in ipairs (Main_Page.Visibility_List) do
	    item.visible = false
	  end
	  Main_Page.Rainfall_Grid.visible = true

    elseif keys[keybindings.vegetation.key] then
      self.subviews.pages:setSelected (1)
	  focus = "Biome Offset"
	  Update_Biome_Offset (x, y, z, self.subviews.pages)
      for i, item in ipairs (Main_Page.Visibility_List) do
	    item.visible = false
	  end
	  Main_Page.Biome_Offset_Grid.visible = true
      
    elseif keys[keybindings.temperature.key] then
      self.subviews.pages:setSelected (1)
	  focus = "Temperature"
	  Update_Temperature (x, y, z, self.subviews.pages)
      for i, item in ipairs (Main_Page.Visibility_List) do
	    item.visible = false
	  end
	  Main_Page.Temperature_Grid.visible = true

    elseif keys[keybindings.evilness.key] then
      self.subviews.pages:setSelected (1)
	  focus = "Evilness"
	  Update_Evilness (x, y, z, self.subviews.pages)
      for i, item in ipairs (Main_Page.Visibility_List) do
	    item.visible = false
	  end
	  Main_Page.Evilness_Grid.visible = true

    elseif keys[keybindings.drainage.key] then
      self.subviews.pages:setSelected (1)
	  focus = "Drainage"
	  Update_Drainage (x, y, z, self.subviews.pages)
      for i, item in ipairs (Main_Page.Visibility_List) do
	    item.visible = false
	  end
	  Main_Page.Drainage_Grid.visible = true

    elseif keys[keybindings.volcanism.key] then
      self.subviews.pages:setSelected (1)
	  focus = "Volcanism"
	  Update_Volcanism (x, y, z, self.subviews.pages)
      for i, item in ipairs (Main_Page.Visibility_List) do
	    item.visible = false
	  end
	  Main_Page.Volcanism_Grid.visible = true

    elseif keys[keybindings.savagery.key] then 
      self.subviews.pages:setSelected (1)
	  focus = "Savagery"
	  Update_Savagery (x, y, z, self.subviews.pages)
      for i, item in ipairs (Main_Page.Visibility_List) do
	    item.visible = false
	  end
	  Main_Page.Savagery_Grid.visible = true

    elseif keys[keybindings.salinity.key] then 
      self.subviews.pages:setSelected (1)
	  focus = "Salinity"
	  Update_Salinity (x, y, z, self.subviews.pages)
      for i, item in ipairs (Main_Page.Visibility_List) do
	    item.visible = false
	  end
	  Main_Page.Salinity_Grid.visible = true

    elseif keys[keybindings.shear_biome.key] then 
      self.subviews.pages:setSelected (1)
	  focus = "Shear Biome"
	  Update_Shear_Biome (x, y, z, self.subviews.pages)
      for i, item in ipairs (Main_Page.Visibility_List) do
	    item.visible = false
	  end
	  Main_Page.Shear_Biome_Grid.visible = true

    elseif keys[keybindings.elevation.key] then 
      self.subviews.pages:setSelected (1)
	  focus = "Elevation"
	  Update_Elevation (x, y, z, self.subviews.pages)
      for i, item in ipairs (Main_Page.Visibility_List) do
	    item.visible = false
	  end
	  Main_Page.Elevation_Grid.visible = true

    elseif keys[keybindings.broad_biome.key] then 
      self.subviews.pages:setSelected (1)
	  focus = "Broad Biome"
	  Update_Broad_Biome (x, y, z, self.subviews.pages)
      for i, item in ipairs (Main_Page.Visibility_List) do
	    item.visible = false
	  end
	  Main_Page.Broad_Biome_Grid.visible = true

    elseif keys[keybindings.up_z.key] then
      if z < max_z - 1 then
        z = z + 1
      end
	  
      Recalculate (z)
	  Update (x, y, z, self.subviews.pages)

    elseif keys[keybindings.down_z.key] then
      if z > 1 then
        z = z - 1
      end

      Recalculate (z)
	  Update (x, y, z, self.subviews.pages)
    
	elseif keys[keybindings.up.key] then
	  if focus == "Help" then
	    if help_y > 1 then
	      help_y = help_y - 1
	    end

	    Update_Help (self.subviews.pages)

	  else
	    Pan (0, -1)
	  end
	  	  
	elseif keys[keybindings.down.key] then
	  if focus == "Help" then
	    if help_y < help_max_y then
	      help_y = help_y + 1
	    end
	  
	    Update_Help (self.subviews.pages)
		
	  else
	    Pan (0, 1)
	  end
	  	  
	elseif keys[keybindings.left.key] then
	  if focus == "Help"  then
	    if help_x > 1 then
	      help_x = help_x - 1
	    end
	  
	    Update_Help (self.subviews.pages)
		
	  else
	    Pan (-1, 0)
	  end
	  
	elseif keys[keybindings.right.key] then
	  if focus == "Help" then
	    if help_x < help_max_x then
	      help_x = help_x + 1
	    end
	    
		Update_Help (self.subviews.pages)
	  
	  else
	    Pan (1, 0)
	  end
	  
	elseif keys[keybindings.upleft.key] then
	  if focus == "Help" then
	    if help_x > 1 then
	      help_x = help_x - 1
	    end
	  
	    if help_y > 1 then
	      help_y = help_y - 1
	    end
	  
	    Update_Help (self.subviews.pages)
	  
	  else
	    Pan (-1, -1)
	  end
	  
	elseif keys[keybindings.upright.key] then
	  if focus == "Help" then
	    if help_x < help_max_x then
	      help_x = help_x + 1
	    end
	  
	    if help_y > 1 then
	      help_y = help_y - 1
	    end
	    
		Update_Help (self.subviews.pages)
	  
	  else
	    Pan (1, -1)
	  end
	  
	elseif keys[keybindings.downleft.key] then
	  if focus == "Help" then
	    if help_x > 1 then
	      help_x = help_x - 1
	    end
	  
	    if help_y < help_max_y then
	      help_y = help_y + 1
	    end
	  
	    Update_Help (self.subviews.pages)
	  
	  else
	    Pan (-1, 1)
	  end
	  
	elseif keys[keybindings.downright.key] then
	  if focus == "Help" then
	    if help_x < help_max_x then
	      help_x = help_x + 1
	    end
	  
	    if help_y < help_max_y then
	      help_y = help_y + 1
	    end
	  
	    Update_Help (self.subviews.pages)
	  
	  else
	    Pan (1, 1)
	  end
	  
	elseif keys[keybindings.up_fast.key] then
	  if focus == "Help" then
	    help_y = help_y - 10
	  
	    if help_y < 1 then
	      help_y = 1
	    end
	  
	    Update_Help (self.subviews.pages)
	  
	  else
	    Pan (0, -10)
	  end
	  
	elseif keys[keybindings.down_fast.key] then
	  if focus == "Help" then
	    help_y = help_y + 10
	  
	    if help_y > help_max_y then
	      help_y = help_max_y
	    end
	  
	    Update_Help (self.subviews.pages)
	  
	  else
	    Pan (0, 10)
	  end
	  
	elseif keys[keybindings.left_fast.key] then
	  if focus == "Help" then
	    help_x = help_x - 10
	  
	    if help_x < 1 then
	      help_x = 1
	    end
	  
	    Update_Help (self.subviews.pages)

	  else
	    Pan (-10, 0)
	  end
	  
	elseif keys[keybindings.right_fast.key] then
	  if focus == "Help" then
	    help_x = help_x + 10
	  
	    if help_x > help_max_x then
	      help_x = help_max_x
	    end
	  
	    Update_Help (self.subviews.pages)
	  
	  else
	    Pan (10, 0)
	  end
	  
	elseif keys[keybindings.upleft_fast.key] then
	  if focus == "Help" then
	    help_x = help_x - 10
	  
	    if help_x < 1 then
	      help_x = 1
	    end
	  
	    help_y = help_y - 10
	  
	    if help_y < 1 then
	      help_y = 1
	    end
	  
	    Update_Help (self.subviews.pages)
	  
	  else
	    Pan (-10, -10)
	  end
	  
	elseif keys[keybindings.upright_fast.key] then
	  if focus == "Help" then
	    help_x = help_x + 10
	  
	    if help_x > help_max_x then
	      help_x = help_max_x
	    end
	  
	    help_y = help_y - 10
	  
	    if help_y < 1 then
	      help_y = 1
	    end
	  
	    Update_Help (self.subviews.pages)
	  
	  else
	    Pan (10, 10)
	  end
	  
	elseif keys[keybindings.downleft_fast.key] then
	  if focus == "Help" then
	    help_x = help_x - 10
	  
	    if help_x < 1 then
	      help_x = 1
	    end
	  
	    help_y = help_y + 10
	  
	    if help_y > help_max_y then
	      help_y = help_max_y
	    end
	  
	    Update_Help (self.subviews.pages)
	  
	  else
	    Pan (-10, 10)
	  end
	  
	elseif keys[keybindings.downright_fast.key] then
	  if focus == "Help" then
	    help_x = help_x + 10
	  
	    if help_x > help_max_x then
	      help_x = help_max_x
	    end
	  
	    help_y = help_y + 10
	  
	    if help_y > help_max_y then
	      help_y = help_max_y
	    end
	  
	    Update_Help (self.subviews.pages)
		
	  else
	    Pan (10, 10)
	  end	 
	end

    self.super.onInput(self,keys)
  end

  --============================================================

  function show_viewer()
    local screen = BiomeViewerUi{}
    persist_screen=screen
    screen:show()
  end

  show_viewer()
end

--==============================================================

showbiomes()
