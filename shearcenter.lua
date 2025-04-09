function shearcenter ()
  if not dfhack.isMapLoaded() then
	dfhack.color (COLOR_RED)
    dfhack.print("Error: This script requires a Fortress Mode embark to be loaded.")
	dfhack.color(COLOR_RESET)
	dfhack.println()
	return
  end
  
  local max_x, max_y, max_z = dfhack.maps.getTileSize()
   
  function Is_Air_Tile (x, y, z)
    local tile_type
    local block = dfhack.maps.getBlock (math.floor (x / 16), math.floor (y / 16), z)
	local region_offset = block.region_offset [block.designation [0][0].biome]
	local result = true

	for i = 0, 15 do
	  for k = 0, 15 do
        if dfhack.maps.getTileBiomeRgn (x, y, max_z - 1 - z) ~= nil then	
          tile_type = dfhack.maps.getTileType (x + k, y + i, z)
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
			  result = false
              break
		  end
		end
		
		if region_offset ~= block.region_offset [block.designation [k][i].biome] then  --  Air tiles have uniform offsets (even when they are shears)
		  result = false
		  break
		end		
	  end
	  
	  if not result then
	    break
	  end
	end
	
	if result and region_offset ~= 0 then
	  dfhack.println ("Shear at " .. tostring (x) .. ", " .. tostring (y) .. ", " .. tostring (z))
	end
	
	return result
  end
  
  local block
  
  for i = 0, math.floor ((max_y - 1) / 16) do
	for k = 0, math.floor (max_x - 1) / 16 do
      for l = 0, max_z - 1 do
	    if i==0 and k==0 then
		end
	    if not Is_Air_Tile (k * 16, i * 16, max_z - 1 - l) then		
		  break
		end
		
        block = dfhack.maps.getBlock (k, i, max_z - 1 - l)
	    
		for m = 0, 15 do
	      for n = 0, 15 do
		    block.region_offset [block.designation [n][m].biome] = 4
		  end
		end
	  end
	end
  end
end

shearcenter ()