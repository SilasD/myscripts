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
      local found = false
      local designated = false
      local skip = false
      
      for k, seed in ipairs (df.global.world.items.other.SEEDS) do
        if seed.mat_index == i then
          skip = true
          dfhack.println ("Skipping " .. v.id .. " as seeds are already available")
          break
        end
      end
      
      if not skip then
        for k, plant in ipairs (df.global.world.plants.all) do
          if plant.material == i then
            local cur = dfhack.maps.getTileBlock (plant.pos)
            local x = plant.pos.x % 16
            local y = plant.pos.y % 16
            local skip
   
            if cur.tiletype [x] [y] == df.tiletype.Shrub then
              if cur.designation [x] [y].dig == df.tile_dig_designation.No then
                current = df.global.world.jobs.list
                skip = false
  
                while current ~= nil do
                  if current.item ~= nil and
                     current.item.job_type == df.job_type.GatherPlants and
                     current.item.pos.x == plant.pos.x and
                     current.item.pos.y == plant.pos.y and
                     current.item.pos.z == plant.pos.z then
                    skip = true
                    break
                  end
    
                  current = current.next
                end
                        
                if not skip then
                  for l, u in ipairs (df.global.world.jobs.postings) do
                    if u.job ~= nil and
                       u.job.job_type == df.job_type.GatherPlants and
                       u.job.pos.x == plant.pos.x and
                       u.job.pos.y == plant.pos.y and
                       u.job.pos.z == plant.pos.z then
                      skip = true
                      break
                    end
                  end
                end
            
                if not skip then
                  found = true
                  designated = true
                  for l, growth in ipairs (v.growths) do
                    if growth.id == "FRUIT" and
                       (df.global.cur_year_tick < growth.timing_1 or
                        df.global.cur_year_tick > growth.timing_2) then
                      designated = false
                    end
                  end
               
                  if designated then
                    cur.designation [x] [y].dig = df.tile_dig_designation.Default
                    cur.flags.designated = true
                    dfhack.println ("Designated " .. v.id)
                    break
                  end
                end
              end
            end
          end        
        end
      end
      
      if not skip then
        if not found then
          dfhack.println ("Failed to find " .. v.id)
        elseif not designated then
          dfhack.println ("Found " .. v.id .. " but it's not ripe")
        end
      end
    end
  end
end

getone()