function removeflyingtrees ()
  local count = 0
  
  for i, plant in ipairs (df.global.world.plants.all) do
    if plant.tree_info ~= nil and
	   dfhack.maps.getTileType (plant.pos) == df.tiletype.OpenSpace then
	  plant.tree_info = nil
	  count = count + 1
	end	
  end

  dfhack.println (tostring (count) .. " flying trees removed")
end

removeflyingtrees ()