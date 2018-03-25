local number_to_get = 1  --  Change this number if you want more of each. Note that the number of plants
                         --  actually collected is reduced by the number of seeds already at hand.
  
--====================================

local max_x, max_y, max_z = dfhack.maps.getTileSize()
local center_x = max_x / 2
local center_y = max_y / 2 
  
--====================================

function distance_2 (x, y)
  local dx = center_x - x
  local dy = center_y - y
  return dx * dx + dy * dy
end

--====================================

function closer (x1, y1, x2, y2)
  return distance_2 (x1, y1) < distance_2 (x2, y2)
end

--====================================

function getone ()
  for i, v in ipairs (df.global.world.raws.plants.all) do
    local paper_plant = false
    
    for k, material in ipairs (v.material) do
      for l, reaction in ipairs (material.reaction_class) do
        if reaction.value == "PAPER_PLANT" then
          paper_plant = true
          break
        end
      end
    end    
    
    if (v.flags.DRINK or
        v.flags.THREAD or
        paper_plant) and
       not v.flags.SAPLING and
       not v.flags.TREE and
       not v.flags.GRASS and
       not v.flags.BIOME_SUBTERRANEAN_WATER and
       not v.flags.BIOME_SUBTERRANEAN_CHASM and
       not v.flags.BIOME_SUBTERRANEAN_LAVA then
      local seeds = 0
      local found = 0
      local designated = 0
      local skip = false
 
      for k, seed in ipairs (df.global.world.items.other.SEEDS) do
        if seed.mat_index == i then
          seeds = seeds + 1
          
          if seeds >= number_to_get then
            skip = true
            dfhack.println ("Skipping " .. v.id .. " as sufficient seeds are already available")
            break
          end
        end
      end
      
      found = seeds
      local candidates = {}
      
      if not skip then
        for k, plant in ipairs (df.global.world.plants.all) do
          if plant.material == i then
            local cur = dfhack.maps.getTileBlock (plant.pos)
            local x = plant.pos.x % 16
            local y = plant.pos.y % 16
            local skip_inner
   
            if cur.tiletype [x] [y] == df.tiletype.Shrub then
              if cur.designation [x] [y].dig == df.tile_dig_designation.No then
                current = df.global.world.jobs.list
                skip_inner = false
  
                while current ~= nil do
                  if current.item ~= nil and
                     current.item.job_type == df.job_type.GatherPlants and
                     current.item.pos.x == plant.pos.x and
                     current.item.pos.y == plant.pos.y and
                     current.item.pos.z == plant.pos.z then
                    table.insert (candidates, {plant, true})
                    skip_inner = true
                    break
                  end
    
                  current = current.next
                end
                        
                if not skip_inner then
                  for l, u in ipairs (df.global.world.jobs.postings) do
                    if u.job ~= nil and
                       u.job.job_type == df.job_type.GatherPlants and
                       u.job.pos.x == plant.pos.x and
                       u.job.pos.y == plant.pos.y and
                       u.job.pos.z == plant.pos.z then
                      table.insert (candidates, {plant, true})
                      skip_inner = true
                      break
                    end
                  end
                end
            
                if not skip_inner then
                  table.insert (candidates, {plant, false})
                end
                
              elseif cur.designation [x] [y].dig == df.tile_dig_designation.Default then
                table.insert (candidates, {plant, true})
              end              
            end  
          end    
        end
        
        if #candidates + seeds >= number_to_get then  --  Need to sort the list   
          local temp
          
          for l = 1, #candidates - 1 do
            if not candidates [l] [2] then  --  Already designated ones are kept. Don't know with certainty how to replace those.
              for m = l + 1, #candidates do
                if candidates [m] [2] then
                  temp = candidates [l]
                  candidates [l] = candidates [m]
                  candidates [m] = temp
                  break
                end
                
                if distance_2 (candidates [l] [1].pos.x, candidates [l] [1].pos.y) > distance_2 (candidates [m] [1].pos.x, candidates [m] [1].pos.y) then
                  temp = candidates [l]
                  candidates [l] = candidates [m]
                  candidates [m] = temp
                end
              end
            end
          end
        end
        
        for l, growth in ipairs (v.growths) do
          if growth.id == "FRUIT" and
             (df.global.cur_year_tick < growth.timing_1 or
              df.global.cur_year_tick > growth.timing_2) then
            dfhack.println ("Found " .. v.id .. " but it's not ripe")
            designated = false
            break
          end
        end
        
        if designated then
          local last = #candidates
        
          if #candidates > number_to_get - seeds then
            last = number_to_get - seeds
          end
        
                  
          for l = 1, last do
            if candidates [l] [2] then
              dfhack.println ("Already designated " .. v.id, candidates [l] [1].pos.x, candidates [l] [1].pos.y, candidates [l] [1].pos.z)
              
            else
              local cur = dfhack.maps.getTileBlock (candidates [l] [1].pos)
              local x = candidates [l] [1].pos.x % 16
              local y = candidates [l] [1].pos.y % 16
            
              cur.designation [x] [y].dig = df.tile_dig_designation.Default
              cur.flags.designated = true
              dfhack.println ("Designated " .. v.id, candidates [l] [1].pos.x, candidates [l] [1].pos.y, candidates [l] [1].pos.z)
            end
          end
        end
      end
      
      if not skip then
        if #candidates == 0 then
          dfhack.println ("Failed to find any " .. v.id)
          
        elseif not designated then
          --  Not ripe
        
        elseif #candidates < number_to_get - seeds then
          dfhack.println ("Failed to find sufficient " .. v.id)
        end
      end
    end
  end
end

getone()