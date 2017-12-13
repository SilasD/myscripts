-- Edited 2017-11-20
--
function closer (x1, y1, x2, y2)
  local dx1
  local dx2
  local dy1
  local dy2
  local max_x, max_y, max_z = dfhack.maps.getTileSize()
  local center_x = max_x / 2
  local center_y = max_y / 2 

  dx1 = center_x - x1
  dy1 = center_y - y1
  dx2 = center_x - x2
  dy2 = center_y - y2
  
  return dx1 * dx1 + dy1 * dy1 < dx2 * dx2 + dy2 * dy2
end

function spareone ()
  local valuable

  for i, v in ipairs (df.global.world.raws.plants.all) do
    if v.flags.TREE and
       not v.flags.BIOME_SUBTERRANEAN_WATER and
       not v.flags.BIOME_SUBTERRANEAN_CHASM and
       not v.flags.BIOME_SUBTERRANEAN_LAVA then
      valuable = v.flags.DRINK or
                 v.flags.THREAD
      local found = false
      local skipped = nil
      local skipped_2 = nil
      local skipped_3 = nil
      local skip
      local sapling_found = false
      local spare_count = 1
      
      for k, growth in ipairs (v.growths) do
        if growth.id == "FRUIT" then  --  Should really tie to reaction
          if not growth.locations.twigs and
             not growth.locations.light_branches and
             not growth.locations.heavy_branches and
             growth.locations.trunk and
             v.trunk_branching == 0 then
            spare_count = 3  --  Grows only on the trunk, so the yield is poor.
          end
        end
      end
           
      for k, plant in ipairs (df.global.world.plants.all) do
        if plant.material == i then          
          local cur = dfhack.maps.getTileBlock (plant.pos)
          local x = plant.pos.x
          local y = plant.pos.y
          local z = plant.pos.z
            
          if cur.tiletype [x % 16] [y % 16] == df.tiletype.TreeTrunkPillar or
             cur.tiletype [x % 16] [y % 16] == df.tiletype.TreeTrunkNW or
             cur.tiletype [x % 16] [y % 16] == df.tiletype.TreeTrunkNE or
             cur.tiletype [x % 16] [y % 16] == df.tiletype.TreeTrunkSW or
             cur.tiletype [x % 16] [y % 16] == df.tiletype.TreeTrunkSE then
            if cur.designation [x % 16] [y % 16].dig == df.tile_dig_designation.No then
              current = df.global.world.jobs.list
              skip = false
  
              while current ~= nil do
                if current.item ~= nil and
                   current.item.job_type == df.job_type.FellTree and
                   current.item.pos.x == x and
                   current.item.pos.y == y and
                   current.item.pos.z == z then
                  skip = true
                  break
                end
    
                current = current.next
              end
                        
              if not skip then
                for l, u in ipairs (df.global.world.jobs.postings) do
                  if u.job ~= nil and
                     u.job.job_type == df.job_type.FellTree and
                     u.job.pos.x == x and
                     u.job.pos.y == y and
                     u.job.pos.z == z then
                    skip = true
                    break
                  end
                end
              end
            
              if not skip then                
                if skipped == nil and
                   valuable then
                  skipped = plant.pos
                  found = true
                  dfhack.println ("Skipping (" ..  tostring (x) .. ", "  ..  tostring (y) .. ") " .. v.id)
                  
                elseif spare_count == 3 and
                       skipped_2 == nil and
                       valuable then
                  skipped_2 = plant.pos
                  dfhack.println ("Skipping (" ..  tostring (x) .. ", "  ..  tostring (y) .. ") " .. v.id)
                       
                elseif spare_count == 3 and
                       skipped_3 == nil and
                       valuable then
                  skipped_3 = plant.pos
                  dfhack.println ("Skipping (" ..  tostring (x) .. ", "  ..  tostring (y) .. ") " .. v.id)
                       
                else
                  if valuable then
                    if closer (x, y, skipped.x, skipped.y) then
                      cur = dfhack.maps.getTileBlock (skipped)
                      x = skipped.x
                      y = skipped.y
                      z = skipped.z
                      skipped = plant.pos                
                      dfhack.println ("Swapping (" ..  tostring (x) .. ", "  ..  tostring (y) .. ") for ("
                                                      ..  tostring (skipped.x) .. ", " .. tostring (skipped.y) .. ")")
                    
                    elseif spare_count == 3 and
                           closer (x, y, skipped_2.x, skipped_2.y) then
                      cur = dfhack.maps.getTileBlock (skipped_2)
                      x = skipped_2.x
                      y = skipped_2.y
                      z = skipped_2.z
                      skipped_2 = plant.pos                
                      dfhack.println ("Swapping (" ..  tostring (x) .. ", "  ..  tostring (y) .. ") for ("
                                                      ..  tostring (skipped_2.x) .. ", " .. tostring (skipped_2.y) .. ")")
                    
                    elseif spare_count == 3 and
                           closer (x, y, skipped_3.x, skipped_3.y) then
                      cur = dfhack.maps.getTileBlock (skipped_3)
                      x = skipped_3.x
                      y = skipped_3.y
                      z = skipped_3.z
                      skipped_3 = plant.pos                
                      dfhack.println ("Swapping (" ..  tostring (x) .. ", "  ..  tostring (y) .. ") for ("
                                                      ..  tostring (skipped_3.x) .. ", " .. tostring (skipped_3.y) .. ")")
                    end
                  end
                  
                  cur.designation [x % 16] [y % 16].dig = df.tile_dig_designation.Default
                  cur.flags.designated = true
                  dfhack.println ("Designated " .. v.id .. " at (" .. tostring (x) .. ", " .. tostring (y) .. ")")
                  found = true
                end
              end
            end
            
          elseif cur.tiletype [x % 16] [y % 16] == df.tiletype.Sapling then
            sapling_found = true
          end
        end
      end
      
      if valuable and not found then
        if sapling_found then
          dfhack.println ("Found " .. v.id .. " sapling")
        else
          dfhack.println ("Failed to find " .. v.id)
        end
      end
    end
  end
end
  
spareone()