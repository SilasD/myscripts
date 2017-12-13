function candy_corrector ()
  if not dfhack.isWorldLoaded () then
	dfhack.color (COLOR_RED)
    dfhack.print ("Error: This script requires a world to be loaded.")
	dfhack.color (COLOR_RESET)
	dfhack.println ()
	return
  end

  if dfhack.isMapLoaded() then
	dfhack.color (COLOR_RED)
    dfhack.print ("Error: This script requires a world to be loaded, but not a map.")
	dfhack.color (COLOR_RESET)
	dfhack.println ()
	return
  end
  
  if df.global.world.worldgen.worldgen_parms.cavern_layer_count == 3 then
    dfhack.println ("This world has three cavern layers, so there's no need to correct anything.")
	return
  end
  
  local screen = dfhack.gui.getCurViewscreen ()
  local dim_x = df.global.world.worldgen.worldgen_parms.dim_x
  local dim_y = df.global.world.worldgen.worldgen_parms.dim_y
  local caverns = df.global.world.worldgen.worldgen_parms.cavern_layer_count
  local count = 0
  
  for i = 0, 256 do
    screen:feed_key (df.interface_key.CURSOR_UPLEFT)
  end

  --  Populate the feature structure
  --
  for i = 0, dim_x - 1 do
    for k = 0, dim_y - 1 do
      screen:feed_key (df.interface_key.CURSOR_DOWN)	  
	end
	
    for k = 0, dim_y - 1 do
      screen:feed_key (df.interface_key.CURSOR_UP)	  
	end
	
    screen:feed_key (df.interface_key.CURSOR_RIGHT)	  
  end
  
  for i = 0, (dim_x - 1) / 16 do
    for k = 0, (dim_y - 1) / 16 do
	  for l = 0, 15 do	  
        for m = 0, 15 do
		  for n, feature in ipairs (df.global.world.world_data.feature_map [i]:_displace (k).features.feature_init [l] [m]) do
		    if feature._type == df.feature_init_deep_special_tubest then
			  if feature.start_depth < 3 then  -- Above magma sea
			    if caverns == 0 then
				  feature.start_depth = 3
				
  				  count = count + 1
				elseif feature.start_depth > caverns - 1 then
			      feature.start_depth = feature.start_depth - (3 - caverns)
				  
				  if feature.start_depth < 0 then  --  Don't know if DF can generate spires reaching too high, but fix it if it does.
				    feature.start_depth = 0
				  end
				
				  count = count + 1
				end
			  end
			end			
		  end
		end
	  end	  
	end
  end
  
  dfhack.println ("Fixed " .. tostring (count) .. " spires")
end

candy_corrector ()