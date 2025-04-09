--  This script is used to break out from various points in world gen to edit the world using other tools. It
--  does the same thing as using ESCAPE manually, but with higher precision. Once the desired manipulation has
--  been performed DF world gen is resumed normally through the native DF c(ontinue) command.
--  
--  The script can break out once or multiple times during world gen, depending on its setup (see below). The
--  script normally terminates (with a message) once the last breakout condition has been met, the exception
--  being an order to breakout every X years, as the script doesn't know when this ends. Regardless, the script
--  terminates once a map is loaded (such as when loading a save or embarking), so even if world gen is aborted
--  or accepted prematurely the script should terminate harmlessly. The worst thing happening is the script
--  continuing to run (and break out from the start) on a subsequent world gen. Exiting DF and restarting it
--  will definitely get rid of executing script...
--
--  The script has to be started before actual world gen starts, but any time before that will do, i.e. the
--  both the start screen and the world gen screens (normal or advanced) will do.
--
--  This script is controlled by changing the local variables below (before the worldgen_breakout_box function
--  is activated) to suit the conditions when the script should break out from world gen.
--
--  The author considers these to be good points for breakouts:
--  - before caves: Change geography without risking submerging any caves.
--  - before megabeasts: "correct" evil/good placement
--  - before each civ: Would be very useful if a means to move "incorrectly" starting sites properly (i.e. with
--    subsequent civ expansion being based on the new capital location) is found.
--  - At year/at every X years if there's a desire to guide civ expansion via savagery reductions, but this can
--    usually be done using ESCAPE manually.
--
--  Version 0.2 2018-01-01
--[====[

worldgen_breakout_box
=================
]====]
local new_progress = false

for field, value in pairs (df.global.world.worldgen_status) do
  if field == "place_caves" then
    new_progress = true
    break
  end
end

local breakout_before_caves = false
local breakout_before_good_evil = false
local breakout_before_megabeasts = true
local breakout_before_other_beasts = false
local breakout_before_cave_pops = false
local breakout_before_cave_civs = false
local breakout_before_civs = false
local breakout_before_each_civ = false
local breakout_before_history = false
local breakout_at_year = false        --  or a specified year number to activate it
local breakout_every_x_years = false  -- or a specific interval number to activate it

function worldgen_breakout_box ()
  if dfhack.isMapLoaded () then
    dfhack.printerr ("Error: This script is used for world generation manipulation and does not allow a map to be loaded")
    return
  end

  local state = df.global.world.worldgen_status.state
  local place_caves = false
  local active = (new_progress and not df.global.world.worldgen_status.place_caves) or
                 (not new_progress and not df.global.world.worldgen_status.placed_caves)
  local place_good_evil = false
  local place_megabeasts = false
  local place_other_beasts = false
  local make_cave_pops = false
  local make_cave_civs = false
  local place_civs = false
  local finished_prehistory = false
  local entities
  local century = 0
  local previous_year = 0
  local done = false
  
  local num_rejects = df.global.world.worldgen_status.num_rejects

  function callback ()    
    if dfhack.isMapLoaded () then
      dfhack.println ("A map has been loaded, so worldgen_breakout_box terminates now.")
      return
    end
    
    if state > df.global.world.worldgen_status.state or
      num_rejects ~= df.global.world.worldgen_status.num_rejects then
      num_rejects = df.global.world.worldgen_status.num_rejects
      active = true
      state = df.global.world.worldgen_status.state
      place_caves = false
      place_good_evil = false
      place_megabeasts = false
      place_other_beasts = false
      make_cave_pops = false
      make_cave_civs = false
      place_civs = false
      finished_prehistory = false
      century = 0
      previous_year = 0
      current_year = 0
      new_year = false
      dfhack.println ("Starting new run")
    end
    
    if active and df.global.world.worldgen_status.state == 9 then
      if breakout_before_caves then
        if not place_caves and
           ((new_progress and df.global.world.worldgen_status.place_caves) or
            (not new_progress and df.global.world.worldgen_status.placed_caves)) then
          place_caves = true
          dfhack.println ("About to place Caves")      
          local screen = dfhack.gui.getCurViewscreen ()
          screen:feed_key (df.interface_key.LEAVESCREEN)
        end
      end
    
      if breakout_before_good_evil then
        if not place_good_evil and
           ((new_progress and df.global.world.worldgen_status.place_good_evil) or
            (not new_progress and df.global.world.worldgen_status.placed_good_evil)) then
          dfhack.println ("About to place good/evil")
          place_good_evil = true
          local screen = dfhack.gui.getCurViewscreen ()
          screen:feed_key (df.interface_key.LEAVESCREEN)
        end
      end
      
      if breakout_before_megabeasts then
        if not place_megabeasts and
           ((new_progress and df.global.world.worldgen_status.place_megabeasts) or
            (not new_progress and df.global.world.worldgen_status.placed_megabeasts)) then
          dfhack.println ("About to place megabeasts")
          place_megabeasts = true
          local screen = dfhack.gui.getCurViewscreen ()
          screen:feed_key (df.interface_key.LEAVESCREEN)
        end
      end
      
      if breakout_before_other_beasts then
        if not place_other_beasts and
           ((new_progress and df.global.world.worldgen_status.place_other_beasts) or
            (not new_progress and df.global.world.worldgen_status.placed_other_beasts)) then
          dfhack.println ("About to place other beasts")
          place_other_beasts = true
          local screen = dfhack.gui.getCurViewscreen ()
          screen:feed_key (df.interface_key.LEAVESCREEN)
        end
      end
      
      if breakout_before_cave_pops then
        if not make_cave_pops and
           ((new_progress and df.global.world.worldgen_status.make_cave_pops) or
            (not new_progress and df.global.world.worldgen_status.made_cave_pops)) then
          dfhack.println ("About to make cave pops")
          make_cave_pops = true
          local screen = dfhack.gui.getCurViewscreen ()
          screen:feed_key (df.interface_key.LEAVESCREEN)
        end
      end
      
      if breakout_before_cave_civs then
        if not make_cave_civs and
        ((new_progress and df.global.world.worldgen_status.make_cave_civs) or
         (not new_progress and df.global.world.worldgen_status.made_cave_civs)) then
          dfhack.println ("About to make cave civs")
          make_cave_civs = true
          local screen = dfhack.gui.getCurViewscreen ()
          screen:feed_key (df.interface_key.LEAVESCREEN)
        end
      end
    
      if not place_civs and
         ((new_progress and df.global.world.worldgen_status.place_civs) or
          (not new_progress and df.global.world.worldgen_status.placed_civs)) then
        place_civs = true
        entities = #df.global.world.entities.all
        
        if breakout_before_civs then
          dfhack.println ("About to place civs")      
          local screen = dfhack.gui.getCurViewscreen ()
          screen:feed_key (df.interface_key.LEAVESCREEN)
        end
      end

      if place_civs and 
         not finished_prehistory then 
        local screen = dfhack.gui.getCurViewscreen ()

        if screen._type == df.viewscreen_new_regionst and
          screen.worldgen_paused == 0 and
          #df.global.world.entities.all ~= entities then
          if breakout_before_each_civ then
            entities = #df.global.world.entities.all
            dfhack.println ("About to place entity number " .. tostring (entities))
            screen:feed_key (df.interface_key.LEAVESCREEN)
          end
        end
      end
      
      if not finished_prehistory and df.global.world.worldgen_status.finished_prehistory then
        finished_prehistory = true
        
        if breakout_before_history then
          dfhack.println ("Finished prehistory")            
          local screen = dfhack.gui.getCurViewscreen ()
          screen:feed_key (df.interface_key.LEAVESCREEN)
          
          if not breakout_at_year and not breakout_every_x_years then
            done = true
          end
        end
      end
      
      if finished_prehistory and df.global.world.worldgen_status.anon_4 < previous_year then
        century = century + 1      
      end
    
      previous_year = df.global.world.worldgen_status.anon_4
      
      new_year = current_year ~= century * 100 + previous_year + 1
      current_year = century * 100 + previous_year + 1
    
      if new_year and
         df.global.gview.view.child.child.worldgen_paused ~= 1 and
         breakout_at_year and
         current_year == breakout_at_year then
        dfhack.println ("Reached year " .. tostring (current_year))
        
        if not breakout_every_x_years then
          done = true
        end
        
        local screen = dfhack.gui.getCurViewscreen ()
        screen:feed_key (df.interface_key.LEAVESCREEN)
      end
      
      if new_year and
         df.global.gview.view.child.child.worldgen_paused ~= 1 and
         breakout_every_x_years and 
         current_year % breakout_every_x_years == 0 then
        dfhack.println ("Reached year " .. tostring (current_year))            
        local screen = dfhack.gui.getCurViewscreen ()
        screen:feed_key (df.interface_key.LEAVESCREEN)
      end
      
      if not done then
          dfhack.timeout (1, 'frames', callback)
          
      else
          dfhack.println ("The breakout box is now done")
      end
    else
          dfhack.timeout (1, 'frames', callback)
    end
  end
   
  local started = dfhack.timeout (1, 'frames', callback)
  dfhack.println ("The breakout box is now started.")
end

worldgen_breakout_box ()