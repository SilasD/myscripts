function move_cursor (x, y)
  local screen = dfhack.gui.getCurViewscreen ()
  local original_x = screen.location.region_pos.x
  local original_y = screen.location.region_pos.y
  
  local large_x = math.floor (math.abs (original_x - x) / 10)
  local small_x = math.abs (original_x - x) % 10
  local large_y = math.floor (math.abs (original_y - y) / 10)
  local small_y = math.abs (original_y - y) % 10
  
  while large_x > 0 or large_y > 0 do
    if large_x > 0 and large_y > 0 then
      if original_x - x > 0 and original_y - y > 0 then
        screen:feed_key (df.interface_key.CURSOR_UPLEFT_FAST)
        
      elseif original_x - x > 0 and original_y - y < 0 then
        screen:feed_key (df.interface_key.CURSOR_DOWNLEFT_FAST)
        
      elseif original_y - y > 0 then
        screen:feed_key (df.interface_key.CURSOR_UPRIGHT_FAST)
        
      else
        screen:feed_key (df.interface_key.CURSOR_DOWNRIGHT_FAST)
      end
      
      large_x = large_x - 1
      large_y = large_y - 1
      
    elseif large_x > 0 then
      if original_x - x > 0 then
        screen:feed_key (df.interface_key.CURSOR_LEFT_FAST)
      
      else
        screen:feed_key (df.interface_key.CURSOR_RIGHT_FAST)
      end
      
      large_x = large_x - 1
      
    else
      if original_y - y > 0 then
        screen:feed_key (df.interface_key.CURSOR_UP_FAST)
        
      else
        screen:feed_key (df.interface_key.CURSOR_DOWN_FAST)
      end
      
      large_y = large_y - 1
    end
  end
  
  while small_x > 0 or small_y > 0 do
    if small_x > 0 and small_y > 0 then
      if original_x - x > 0 and original_y - y > 0 then
        screen:feed_key (df.interface_key.CURSOR_UPLEFT)
        
      elseif original_x - x > 0 and original_y - y < 0 then
        screen:feed_key (df.interface_key.CURSOR_DOWNLEFT)
        
      elseif original_y - y > 0 then
        screen:feed_key (df.interface_key.CURSOR_UPRIGHT)
        
      else
        screen:feed_key (df.interface_key.CURSOR_DOWNRIGHT)
      end
      
      small_x = small_x - 1
      small_y = small_y - 1
      
    elseif small_x > 0 then
      if original_x - x > 0 then
        screen:feed_key (df.interface_key.CURSOR_LEFT)
        
      else
        screen:feed_key (df.interface_key.CURSOR_RIGHT)
      end
      
      small_x = small_x - 1
      
    else
      if original_y - y > 0 then
        screen:feed_key (df.interface_key.CURSOR_UP)
        
      else
        screen:feed_key (df.interface_key.CURSOR_DOWN)
      end
      
      small_y = small_y - 1
    end
  end
end

----------------------------

function candy_corrector ()
  local show_progress_indication = true  --  Change to false if you find the indication annoying.
  
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
  local target_location_x = 0
  local target_location_y = 0
  local i = 0
  local k = 0
  local x_right = true
  local y_down = true
  local inhibit_x_turn = false
  local inhibit_y_turn = false
  local x_end
  local y_end
  local x_major_index
  local x_index
  local y_index
  
  while true do
    if (k == math.floor (dim_x / 16) and x_right) or
       (k == 0 and not x_right) then
      x_end = 0

    else
      x_end = 15    
    end
    
    if i == math.floor (dim_y / 16) then
      y_end = 0
      
    else
      y_end = 15
    end
    
    for l = 0, x_end do    
      if x_right then
        x_major_index = k
        x_index = l
          
      else
        x_major_index = math.floor (dim_x / 16) - k
        x_index = x_end - l
      end
        
      for m = 0, y_end do
        --  This is where the payload goes
        move_cursor (target_location_x, target_location_y)
        
        if y_down then
          y_index = m
        
        else
          y_index = y_end - m
        end
        
--        dfhack.println (target_location_x, target_location_y, k, i, x_index, y_index, x_end, y_end, x_right, x_major_index)
        
        for n, feature in ipairs (df.global.world.world_data.feature_map [x_major_index]:_displace (i).features.feature_init [x_index] [y_index]) do
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
        --  End of payload section
        
        if m ~= y_end then
          if y_down then
            if target_location_y < dim_y - 1 then
              target_location_y = target_location_y + 1
            end
            
          else
            if target_location_y > 0 then
              target_location_y = target_location_y - 1            
            end
          end
        
        else
          if target_location_x ~= 0 and
             target_location_x ~= dim_x - 1 then
            turn = true
          
          else
            inhibit_y_turn = not inhibit_y_turn
            turn = inhibit_y_turn
          end
          
          if turn then
            y_down = not y_down
            
          else
            if y_down then
              if target_location_y < dim_y - 1 then
                target_location_y  = target_location_y + 1
              end
              
            else
              if target_locaion_y > 0 then
                target_location_y = target_location_y - 1
              end
            end
          end
        end  
      end
      
      if x_right then  --  Won't do anything at the edge, so we don't bother filter those cases.
        if target_location_x < dim_x - 1 then
          target_location_x = target_location_x + 1
        end
        
      else
        if target_location_x > 0 then
          target_location_x = target_location_x - 1
        end
      end
      
      if not x_right and
         target_location_x == 0 then
        turn = not turn
        
        if turn then
          x_right = true
        end
        
      elseif x_right and
             target_location_x == dim_x - 1 then
        turn = not turn
          
        if turn then
          x_right = false
        end
      end
    end
    
    k = k + 1
    
    if k > math.abs (dim_x / 16) then
      k = 0
      i = i + 1
      
      if i > math.abs (dim_y / 16) then
        break
      end
    end
    
    if show_progress_indication then
      if k == 0 then
        dfhack.println ('.')
      else
        dfhack.print ('.')
      end
    end
  end
  
  dfhack.println ()
  dfhack.println ("Fixed " .. tostring (count) .. " spires")
end

candy_corrector ()