--  This script designates surface plants for collection, with the primary aim to get seeds for
--  farm production. Plants already designated are taken into account.
--  The script tries to select the plants closest to the center of the embark, but does not try
--  to replace ones already designated with closer ones.
--
local get_all = true       --  If true, every shrub is collected and the flags below are ignored
local get_paper = true     --    If true, include paper makeing plants (only papyrus in vanilla)
local get_drink = true     --    If true, include booze producing plants
local get_thread = true    --    If true, include thread producing plants
local get_mill = true      --    If true, include millable plants
local get_seedless = false -- Get plants that can't be grown as they produce no seeds. The vanilla
                           --  plants of this type are Valley Herb and Kobold Bulb. Note that get_all
                           --  does NOT override this setting.
local number_to_get = 1    --  Change this number if you want more of each. Note that the number of plants
                           --  actually collected is reduced by the number of seeds already at hand.
local verbose = false      --  If true, prints a line for every designated plant and plants for which
                           --  we already have sufficient seeds. If false, those messages are suppressed.
local skip_evil = false    --  If set, ignores plants in an evil biome. The main purpose for this is to
                           --  allow you to keep out of evil rain/clouds on multi biome embarks. If the
                           --  plant doesn't exist in the rest of the embark none will be designated.
  
local is_evil_offset = {}
local count = 0

for i = -1, 1 do
  local x = df.global.world.world_data.region_details [0].pos.x + i
  
  if x < 0 then
    x = 0
  elseif x == df.global.world.world_data.world_width then
    x = df.global.world.world_data.world_width - 1
  end
  
  for k = -1, 1 do
    local y = df.global.world.world_data.region_details [0].pos.y + k
    
    if y < 0 then
      y = 0
    elseif y == df.global.world.world_data.world_height then
      y = df.global.world.world_data.world_height - 1
    end
    
    is_evil_offset [1 + i + (k + 1) * 3] = df.global.world.world_data.region_map [x]:_displace (y).evilness >= 66
  end
end

--====================================

function reject_evil (block, x, y)
  return skip_evil and is_evil_offset [block.region_offset [block.designation [x] [y].biome]]
end

--====================================

local max_x, max_y, max_z = dfhack.maps.getTileSize ()
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
  --  The relation of the square of the distances is the same as that of the distances, so it's
  --  redundant to take the square root to compare the actual distances.
  --
  return distance_2 (x1, y1) < distance_2 (x2, y2)
end

--====================================

function getone ()
  for i, v in ipairs (df.global.world.raws.plants.bushes) do
    local paper_plant = false
    
    for k, material in ipairs (v.material) do
      for l, reaction in ipairs (material.reaction_class) do
        if reaction.value == "PAPER_PLANT" then
          paper_plant = true
          break
        end
      end
    end    
    
    if (((get_all or
         (get_drink and v.flags.DRINK) or
         (get_thread and v.flags.THREAD) or
         (get_mill and v.flags.MILL) or
         (get_paper and paper_plant)) and
         v.flags.SEED) or
        not v.flags.SEED and
        get_seedless) and
       not v.flags.SAPLING and  --  Should be redundant as we iterate over bushes only
       not v.flags.TREE and     --  -"-
       not v.flags.GRASS and    --  -"-
       not v.flags.BIOME_SUBTERRANEAN_WATER and
       not v.flags.BIOME_SUBTERRANEAN_CHASM and
       not v.flags.BIOME_SUBTERRANEAN_LAVA then
      local seeds = 0
      local found = 0
      local designated = 0
      local skip = false
 
      for k, seed in ipairs (df.global.world.items.other.SEEDS) do
        if seed.mat_index == v.index then
          seeds = seeds + 1
          
          if seeds >= number_to_get then
            skip = true
            if verbose then
              dfhack.color (COLOR_LIGHTGREEN)
              dfhack.println ("Skipping " .. v.id .. " as sufficient seeds are already available")
              dfhack.color (COLOR_RESET)
            end
            break
          end
        end
      end
      
      found = seeds
      local candidates = {}
      
      if not skip then
        for k, plant in ipairs (df.global.world.plants.all) do
          if plant.material == v.index then
            local cur = dfhack.maps.getTileBlock (plant.pos)
            local x = plant.pos.x % 16
            local y = plant.pos.y % 16
            local skip_inner
   
            if not reject_evil (cur, x, y) and cur.tiletype [x] [y] == df.tiletype.Shrub then
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
            dfhack.color (COLOR_YELLOW)
            dfhack.println ("Found " .. v.id .. " but it's not ripe (" .. tostring (#candidates) .. ")")
            dfhack.color (COLOR_RESET)
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
              if verbose then
                dfhack.println ("Already designated " .. v.id, candidates [l] [1].pos.x, candidates [l] [1].pos.y, candidates [l] [1].pos.z)
              end
              
            else
              local cur = dfhack.maps.getTileBlock (candidates [l] [1].pos)
              local x = candidates [l] [1].pos.x % 16
              local y = candidates [l] [1].pos.y % 16
            
              cur.designation [x] [y].dig = df.tile_dig_designation.Default
              cur.flags.designated = true
              count = count + 1
              
              if verbose then
                dfhack.println ("Designated " .. v.id, candidates [l] [1].pos.x, candidates [l] [1].pos.y, candidates [l] [1].pos.z)
              end
            end
          end
        end
      end
      
      if not skip then
        if #candidates == 0 then
          dfhack.color (COLOR_LIGHTRED)
          dfhack.println ("Failed to find any " .. v.id)
          dfhack.color (COLOR_RESET)
          
        elseif not designated then
          --  Not ripe
        
        elseif #candidates < number_to_get - seeds then
          dfhack.color (COLOR_LIGHTCYAN)
          dfhack.println ("Failed to find sufficient " .. v.id .. " (" .. tostring (#candidates) .. ")")
          dfhack.color (COLOR_RESET)
        end
      end
    end
  end
  
  dfhack.println ("Designated " ..  tostring (count) .. " plants for gathering")
end

getone ()