--Manipulates the parameters of the region in focus pre embark. Use ? for help. 
--NOTE: Manipulations made are NOT permanent. They will be applied to the embark if the user embarks while
--the region is still in focus, but they will be discarded as soon as the focus is shifted. They are also
--lost for any subsequent embarks in the same region (but the previous embark will still retain the effects
--of the changes in place when it was embarked upon). It is unknown what effects manipulations have on
--Adventure Mode, but weird discontinuities are likely at the border between an abandoned/retired embark
--generated while under manipulation influence and the region itself (which is back to its original state).
--[====[

regionmanipulator
=================
]====]

local gui = require 'gui'
local dialog = require 'gui.dialogs'
local widgets =require 'gui.widgets'
local guiScript = require 'gui.script'

local Main_Page = {}

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
     type (self.frame.w) ~= 'number' or
     type (self.frame.h) ~= 'number' or
     self.width < 0 or
     self.height < 0 then
    error ("Grid widgets have to have their widths and heights set permanently on initiation")
    return
  end
  
  self.grid = dfhack.penarray.new (self.width, self.height)
  
  self.viewport = {x1 = 0,
                   x2 = self.frame.w - 1,
                   y1 = 0,
                   y2 = self.frame.h - 1}
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

function regionmanipulator ()
  if not dfhack.isWorldLoaded () then
    dfhack.color (COLOR_RED)
    dfhack.print("Error: This script requires a world to be loaded.")
    dfhack.color(COLOR_RESET)
    dfhack.println()
    return
  end

  if dfhack.isMapLoaded() then
    dfhack.color (COLOR_RED)
    dfhack.print("Error: This script requires a world to be loaded, but not a map.")
    dfhack.color(COLOR_RESET)
    dfhack.println()
    return
  end

  local map_width = df.global.world.world_data.world_width
  local map_height = df.global.world.world_data.world_height
  local x = math.floor ((df.global.gview.view.child.location.embark_pos_max.x + 
              df.global.gview.view.child.location.embark_pos_min.x) / 2)
  local y = math.floor ((df.global.gview.view.child.location.embark_pos_max.y + 
              df.global.gview.view.child.location.embark_pos_min.y) / 2)
  local max_x = 16
  local max_y = 16
  local region = df.global.world.world_data.region_details [0]
  local Edit_Focus
  local Focus = "Main"
  
  local Vertical_River_Image = {[-1] = "North",
                                [0] = "None",
                                [1] = "South"}
                                 
  local Horizontal_River_Image = {[-1] = "East",
                                  [0] = "None",
                                  [1] = "West"}

  local keybindings = {
    elevation = {key = "CUSTOM_ALT_E",
                 desc = "Change display to region elevation"},
    biome = {key = "CUSTOM_ALT_B",
             desc = "Change display to region biome"},
    rivers = {key = "CUSTOM_ALT_R",
              desc = "Change display to rivers"},
    top_cavern = {key = "CUSTOM_ALT_T",
                  desc = "Change display to top cavern"},
    mid_cavern = {key = "CUSTOM_ALT_M",
                  desc = "Change display to mid cavern"},
    low_cavern = {key = "CUSTOM_ALT_L",
                  desc = "Change display to lowest cavern"},
    invisible = {key = "CUSTOM_ALT_I",
                 desc = "Change display to show the DF region map"},
    flatten = {key = "CUSTOM_ALT_F",
               desc = "Flatten the region to the elevation of the current region tile"},
    command_region_elevation = {key = "CUSTOM_E",
                                desc = "Change elevation of the region tile"},
    command_biome = {key = "CUSTOM_B",
                     desc = "Change biome reference of the region tile"},
    command_river_elevation = {key = "CUSTOM_SHIFT_E",
                               desc = "Change river elevation of the region tile"},
    command_vertical = {key = "CUSTOM_V",
                        desc = "Set/change/remove river vertical course component"},
    command_river_x = {key = "CUSTOM_X",
                       desc = "Change river vertical flow min x boundary"},
    command_river_X = {key = "CUSTOM_SHIFT_X",
                       desc = "Change river vertical flow Max X boundary"},
    command_horizontal = {key = "CUSTOM_H",
                          desc = "Set/change/remove river horizontal course component "},
    command_river_y = {key = "CUSTOM_Y",
                       desc = "Change river horizontal flow min y boundary"},
    command_river_Y = {key = "CUSTOM_SHIFT_Y",
                       desc = "Change river horizontal flow Max Y boundary"},
    command_top = {key = "CUSTOM_T",
                   desc = "Set 1:st cavern water indicator"},
    command_mid = {key = "CUSTOM_M",
                   desc = "Set 2:nd cavern water indicator"},
    command_low = {key = "CUSTOM_L",
                   desc = "Set 3:rd cavern water indicator"},
    command_is_brook = {key = "CUSTOM_W",
                        desc = "Toggle Is Brook flag of the world tile"},
    up = {key = "CURSOR_UP",
          desc = "Shifts focus 1 step upwards"},
    down = {key = "CURSOR_DOWN",
            desc = "Shifts focus 1 step downwards"},
    left = {key = "CURSOR_LEFT",
            desc = "Shifts focus 1 step to the left"},
    right = {key = "CURSOR_RIGHT",
             desc = "Shift focus 1 step to the right"},
    upleft = {key = "CURSOR_UPLEFT",
              desc = "Shifts focus 1 step up to the left"},
    upright = {key = "CURSOR_UPRIGHT",
               desc = "Shifts focus 1 step up to the right"},
    downleft = {key = "CURSOR_DOWNLEFT",
                desc = "Shifts focus 1 step down to the left"},
    downright = {key = "CURSOR_DOWNRIGHT",
                 desc = "Shifts focus 1 step down to the right"},
    help = {key = "HELP",
            desc= " Show this help/info"}}
            
   --============================================================

  function Range_Color (arg)
    if arg < 100 then
      return COLOR_WHITE
    elseif arg < 110 then
      return COLOR_LIGHTCYAN
    elseif arg < 120 then
      return COLOR_CYAN
    elseif arg < 130 then
      return COLOR_LIGHTBLUE
    elseif arg < 140 then
      return COLOR_BLUE
    elseif arg < 150 then
      return COLOR_LIGHTGREEN
    elseif arg < 160 then
      return COLOR_GREEN
    elseif arg < 170 then
      return COLOR_YELLOW
    elseif arg < 180 then
      return COLOR_LIGHTMAGENTA
    elseif arg < 190 then
      return COLOR_LIGHTRED
    elseif arg < 200 then
      return COLOR_RED
    elseif arg < 210 then
      return COLOR_GREY
    else
      return COLOR_DARKGREY
    end
  end

  --============================================================

  function River_Elevation_Image (x, y)
    if region.rivers_vertical.active [x] [y] ~= 0 then
      return tostring (region.rivers_vertical.elevation [x] [y])
      
    elseif region.rivers_horizontal.active [x] [y] ~= 0 then
      return tostring (region.rivers_horizontal.elevation [x] [y])
      
    else
      return ""
    end
  end

  --============================================================

  function Make_Elevation (x, y)
    local end_x = #region.elevation - 1
    local end_y = #region.elevation [0] - 1
    local fg
    local bg
    local tile_color
         
    for k = 0, end_y do
      for i = 0, end_x do
        if i == x and k == y then
          fg = COLOR_BLACK
          bg = Range_Color (region.elevation [i] [k])
          tile_color = true

        else
          fg = Range_Color (region.elevation [i] [k])
          bg = COLOR_BLACK
          tile_color = false
        end        
          
        Main_Page.elevationGrid:set (i, k, {ch = tostring (math.abs (region.elevation [i] [k] % 10)),
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
  
  function Make_Biome (x, y)
    local end_x = #region.biome - 1
    local end_y = #region.biome [0] - 1
    local fg
    local bg
    local tile_color
    
    for k = 0, end_y do
      for i = 0, end_x do
        if i == x and k == y then
          fg = COLOR_BLACK
          bg = Range_Color (region.biome [i] [k] * 10 + 100)
          tile_color = true
          
        else
          fg = Range_Color (region.biome [i] [k] * 10 + 100)
          bg = COLOR_BLACK
          tile_color = false
        end
        
        Main_Page.biomeGrid:set (i, k, {ch = tostring (region.biome [i] [k]),
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

  function Fit (Item, Size)
    if string.len (Item) > Size then
      return string.rep ('#', Size)
    else
      return Item .. string.rep (' ', Size - string.len (Item))
    end
  end

  --===========================================================================

  function Fit_Right (Item, Size)
    if string.len (Item) > Size then
      return string.rep ('#', Size)
    else
      return string.rep (' ', Size - string.len (Item)) .. Item
    end
  end

  --===========================================================================

  function Make_Rivers (x, y)
    local last = #region.rivers_vertical.elevation - 1
    local ch
    local fg
    local bg
    local tile_color
         
    for k = 0, last do
      for i = 0, last do
        tile_color = (i == x and k == y)
        
        if region.rivers_vertical.active [i] [k] ~= 0 then
          ch = tostring (region.rivers_vertical.elevation [i] [k] % 10)
          
          if i == x and k == y then
            fg = COLOR_BLACK
            bg = Range_Color (region.rivers_vertical.elevation [i] [k])
                            
          else
            fg = Range_Color (region.rivers_vertical.elevation [i] [k])
            bg = COLOR_BLACK
          end    
          
        elseif region.rivers_horizontal.active [i] [k] ~= 0 then
          ch = tostring (region.rivers_horizontal.elevation [i] [k] % 10)
          
          if i == x and k == y then
            fg = COLOR_BLACK
            bg = Range_Color (region.rivers_horizontal.elevation [i] [k])
            
          else
            fg = Range_Color (region.rivers_horizontal.elevation [i] [k])
            bg = COLOR_BLACK
          end    
          
        else
          if i == x and k == y then
            ch = 'X'
            fg = COLOR_DARKGREY
            bg = COLOR_BLACK
            
          else
            ch = '.'
            fg = COLOR_BLACK
            bg = COLOR_DARKGREY
          end
        end
        
        Main_Page.riversGrid:set (i, k, {ch = ch,
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

  local hex_map = {[0] = '0',
                   [1] = '1',
                   [2] = '2',
                   [3] = '3',
                   [4] = '4',
                   [5] = '5',
                   [6] = '6',
                   [7] = '7',
                   [8] = '8',
                   [9] = '9',
                   [10] = 'A',
                   [11] = 'B',
                   [12] = 'C',
                   [13] = 'D',
                   [14] = 'E',
                   [15] = 'F'}
  
  --============================================================

  function Make_Caverns (x, y)
    local value
    local fg
    local bg
    local tile_color
    
    for i = 0, 15 do
      for k = 0, 15 do
        tile_color = (i == x and k == y)
        
        if i == x and k == y then
          fg = COLOR_BLACK
          bg = COLOR_LIGHTBLUE
            
        else
          fg = COLOR_LIGHTBLUE
          bg = COLOR_BLACK
        end    
        
        value = 0
        
        Main_Page.topCavernGrid:set (i, k, {ch = hex_map [value],
                                            fg = fg,
                                            bg = fg,
                                            bold = false,
                                            tile = nil,
                                            tile_color = tile_color,
                                            tile_fg = nil,
                                            tile_bg = nil})
                                            
        Main_Page.midCavernGrid:set (i, k, {ch = hex_map [value],
                                            fg = fg,
                                            bg = bg,
                                            bold = false,
                                            tile = nil,
                                            tile_color = tile_color,
                                            tile_fg = nil,
                                            tile_bg = nil})
                                            
        Main_Page.lowCavernGrid:set (i, k, {ch = hex_map [value],
                                            fg = fg,
                                            bg = bg,
                                            bold = false,
                                            tile = nil,
                                            tile_color = tile_color,
                                            tile_fg = nil,
                                            tile_bg = nil})
                                            
        for l, feature in ipairs (df.global.world.world_data.region_details [0].features [i] [k]) do
          if feature.layer >= 0 then
            value = 0
            
            if feature.unk_30 [0] then
              value = value + 1
            end

            if feature.unk_30 [1] then
              value = value + 2
            end

            if feature.unk_30 [2] then
              value = value + 4
            end

            if feature.unk_30 [3] then
              value = value + 8
            end

            if df.global.world.world_data.underground_regions [feature.layer].layer_depth == 0 then
          
              Main_Page.topCavernGrid:set (i, k, {ch = hex_map [value],
                                                  fg = fg,
                                                  bg = bg,
                                                  bold = false,
                                                  tile = nil,
                                                  tile_color = tile_color,
                                                  tile_fg = nil,
                                                  tile_bg = nil})                                            
              
            elseif df.global.world.world_data.underground_regions [feature.layer].layer_depth == 1 then
              Main_Page.midCavernGrid:set (i, k, {ch = hex_map [value],
                                                  fg = fg,
                                                  bg = bg,
                                                  bold = false,
                                                  tile = nil,
                                                  tile_color = tile_color,
                                                  tile_fg = nil,
                                                  tile_bg = nil})                                            
              
            elseif df.global.world.world_data.underground_regions [feature.layer].layer_depth == 2 then
              Main_Page.lowCavernGrid:set (i, k, {ch = hex_map [value],
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
      end
    end
    
    Main_Page.Top_Cavern_Water_Edit:setText (string.char (Main_Page.topCavernGrid:get (x, y).ch))
    Main_Page.Mid_Cavern_Water_Edit:setText (string.char (Main_Page.midCavernGrid:get (x, y).ch))
    Main_Page.Low_Cavern_Water_Edit:setText (string.char (Main_Page.lowCavernGrid:get (x, y).ch))
  end
  
  --============================================================

  function Set_Visibility (item, visible)
    for i, object in ipairs (Main_Page.Visibility_List [item]) do
      object.visible = visible
    end
  end
  
  --============================================================

  function Bool_Image (b)
    if b then
      return 'Y'
    else
      return 'N'
    end
  end
  
  --==============================================================
  
  function Update (x, y, pages)   
    Make_Elevation (x, y)
    Make_Biome (x, y)
    Make_Rivers (x, y)
    Make_Caverns (x, y)
    
    Main_Page.Heading_Label_X:setText (Fit_Right (tostring (x), 2))
    Main_Page.Heading_Label_Y:setText (Fit_Right (tostring (y), 2))
    
    Main_Page.Region_Elevation_Edit:setText (Fit_Right (region.elevation [x] [y], 4))
                                                      
    Main_Page.Region_Biome_Edit:setText (Fit_Right (region.biome [x] [y], 1))

    Main_Page.River_Elevation_Edit:setText (Fit_Right (River_Elevation_Image (x, y), 4))
    Set_Visibility ("River_Elevation", River_Elevation_Image (x, y) ~= "")
    
    Main_Page.Vertical_Edit:setText (Vertical_River_Image [region.rivers_vertical.active [x] [y]])    

    Main_Page.X_Min_Edit:setText (Fit_Right (region.rivers_vertical.x_min [x] [y], 2))
    Main_Page.X_Max_Edit:setText (Fit_Right (region.rivers_vertical.x_max [x] [y], 2))
    
    Set_Visibility ("Vertical", region.rivers_vertical.active [x] [y] ~= 0)

    Main_Page.Horizontal_Edit:setText (Horizontal_River_Image [region.rivers_horizontal.active [x] [y]])
                         
    Main_Page.Y_Min_Edit:setText (Fit_Right (region.rivers_horizontal.y_min [x] [y], 2))
    Main_Page.Y_Max_Edit:setText (Fit_Right (region.rivers_horizontal.y_max [x] [y], 2))
    
    Set_Visibility ("Horizontal", region.rivers_horizontal.active [x] [y] ~= 0)
    
    Main_Page.Is_Brook_Edit:setText (Bool_Image (df.global.world.world_data.region_map[region.pos.x]:_displace(region.pos.y).flags.is_brook))
  end
  
  --============================================================

  RegionManipulatorUi = defclass (RegionManipulatorUi, gui.FramedScreen)
  RegionManipulatorUi.ATTRS = {
    frame_style = gui.GREY_LINE_FRAME,
    frame_title = "Region Manipulator",
  }

  --============================================================

  function RegionManipulatorUi:onRenderFrame (dc, rect)
    local x1, y1, x2, y2 = rect.x1, rect.y1, rect.x2, rect.y2

    self:renderParent ()
    gui.paint_frame (x1, y1, x2, y2, self.frame_style, self.frame_title)
  end
  

  --============================================================

  function RegionManipulatorUi:onHelp ()
    self.subviews.pages:setSelected (2)
    Focus = "Help"
  end

  --============================================================

  function Disclaimer ()
    local helptext = {{text = "Help/Info"}, NEWLINE, NEWLINE}
     
    table.insert (helptext, NEWLINE)
    local dsc = 
      {"The Region Manipulator is used pre embark to manipulate the region where the embark", NEWLINE,
       "is intended to be performed. Due to the way DF works, any manipulation performed on", NEWLINE,
       "the region is lost/discarded once DF's focus is changed to another region and", NEWLINE,
       "absent when returned. Similarly, Embarking anew in the same region as a previous", NEWLINE,
       "fortress will have the region manipulations performed prior to the previous embark", NEWLINE,
       "reversed on the region level, but their effects are 'frozen' in the fortress itself.", NEWLINE,
       "However, manipulation and manipulation reversal can probably cause 'interesting' effects", NEWLINE,
       "if an adventurer was to visit such a fortress.", NEWLINE,
       "Manipulations are effected immediately in DF, but the 'erase' function inherent in DF", NEWLINE,
       "can be used to remove them (just swich the focus to a different region and back).", NEWLINE,
       "The Region Manipulator allows you to change region level elevations, biomes, rivers,", NEWLINE,
       "and a poorly understood cavern water parameter.", NEWLINE,
       "All commands are indicated on the UI itself, although some are context sensitive and", NEWLINE,
       "unavailable when their controlling property is missing, such as dependent river", NEWLINE,
       "parameters when there is no river at the tile.", NEWLINE,
       "Apart from the fields, the UI also contains a 'graphic' grid over the region which", NEWLINE,
       "starts showing the Elevation. ALT-b changes that to a reference to the Biome of the", NEWLINE,
       "region tile, while ALT-r changes it to display river elevation information, ALT-i shows", NEWLINE,
       "the native DF region 'underneath', and ALT-e changes back to the region Elevation", NEWLINE,
       "information.", NEWLINE,
       "Movement on this grid is performed using the numpad keys.", NEWLINE,
       "In addition to this, there is the ALT-f Flatten Embark command that changes the elevation", NEWLINE,
       "of all tiles to take on the elevation of the current tile. Note that this does NOT change", NEWLINE,
       "river elevations...", NEWLINE,
       "The 'Is Brook' field changes whether you'll embark at a brook or a stream. Note that this", NEWLINE,
       "field is persistent, as it is part of the world tile info, not the generated region data.", NEWLINE,
       "Manipulating rivers is ... messy, but can give rather spectacular results. The River", NEWLINE,
       "Elevation specifies the level at which the water flows, and DF will cut a sheer gorge", NEWLINE,
       "down to that level if below the Region Elevation, or make an 'aqueduct' if above it.", NEWLINE,
       "Waterfalls can be created by making the down river River Elevation lower than the upriver", NEWLINE,
       "one, while the reverse is ignored by DF (water won't jump up).", NEWLINE,
       "The messy part is making and changing river courses, and the author hasn't quite figured", NEWLINE,
       "out what the rules are: you need to experiment. However, it was possible to create a 3*3", NEWLINE,
       "embark where the center tile was surrounded by a bifurcating river that rejoined at the", NEWLINE,
       "other side, creating a natural moat with a waterfall one each side. The embark team was", NEWLINE,
       "spawned at the bottom of the gorge, however, so it was fortunate it was a brook...", NEWLINE,
       "Elevations are color coded. The color ranges are:", NEWLINE,
       {text = "WHITE        < 100, with the actual decile lost.", pen = dfhack.pen.parse {fg = COLOR_WHITE, bg = 0}}, NEWLINE,
       {text = "LIGHT CYAN     100 - 109", pen = dfhack.pen.parse {fg = COLOR_LIGHTCYAN, bg = 0}}, NEWLINE,
       {text = "CYAN           110 - 119", pen = dfhack.pen.parse {fg = COLOR_CYAN, bg = 0}}, NEWLINE,
       {text = "LIGHT BLUE     120 - 129", pen = dfhack.pen.parse {fg = COLOR_LIGHTBLUE, bg = 0}}, NEWLINE,
       {text = "BLUE           130 - 139", pen = dfhack.pen.parse {fg = COLOR_BLUE, bg = 0}}, NEWLINE,
       {text = "LIGHT GREEN    140 - 149", pen = dfhack.pen.parse {fg = COLOR_LIGHTGREEN, bg = 0}}, NEWLINE,
       {text = "GREEN          150 - 159", pen = dfhack.pen.parse {fg = COLOR_GREEN, bg = 0}}, NEWLINE,
       {text = "YELLOW         160 - 169", pen = dfhack.pen.parse {fg = COLOR_YELLOW, bg = 0}}, NEWLINE,
       {text = "LIGHT MAGENTA  170 - 179", pen = dfhack.pen.parse {fg = COLOR_LIGHTMAGENTA, bg = 0}}, NEWLINE,
       {text = "LIGHT RED      180 - 189", pen = dfhack.pen.parse {fg = COLOR_LIGHTRED, bg = 0}}, NEWLINE,
       {text = "RED            190 - 199", pen = dfhack.pen.parse {fg = COLOR_RED, bg = 0}}, NEWLINE,
       {text = "GREY           200 - 219", pen = dfhack.pen.parse {fg = COLOR_GREY, bg = 0}}, NEWLINE,
       {text = "DARK GREY    > 219, with the actual decile lost.", pen = dfhack.pen.parse {fg = COLOR_DARKGREY, bg = 0}}, NEWLINE, NEWLINE,
       "The Biome information refers to the world tile defining the biome of the region tile.", NEWLINE,
       "The Biome key is:", NEWLINE,
       "7: NW 8: N    9: NE", NEWLINE,
       "4:  W 5: Here 6: E", NEWLINE,
       "1: SW 2: S    3: SE", NEWLINE, NEWLINE,
       "The tool allows the modification of cavern lake abundance. This is specified as 4 bits", NEWLINE,
       "represented as a Hex value. It's unclear if the bits indicate geographic location of the", NEWLINE,
       "water or not (If so NW, NE, SW, SE for 1/2/4/8) and it's subject to other restrictions.", NEWLINE,
       "Version 0.11, 2017-12-14", NEWLINE,
       "Caveats: As indicated above, region manipulation has the potential to mess up adventure", NEWLINE,
       "mode seriously. Similarly, changing things in silly ways can result in any kind of", NEWLINE,
       "reaction from DF, so don't be surprised if DF crashes (no crashes have been noted so far)", NEWLINE,
       "or parts of the caverns caves in on embark because you've cut away the walls that should", NEWLINE,
       "have supported them.", NEWLINE
       }

    for i, v in pairs (dsc) do
      table.insert (helptext, v)
    end
    
    return helptext
  end

  --============================================================

  function RegionManipulatorUi:init ()
    self.stack = {}
    self.item_count = 0
    self.keys = {}
    
    Main_Page.Visibility_List =  {}
    
    Main_Page.Top_Mask = 
      widgets.Widget {frame_background = COLOR_BLACK,
                      frame = {l = 0, t = 0, r = 0, h = 1, yalign = 0}}

    Main_Page.Bottom_Mask = 
      widgets.Widget {frame_background = COLOR_BLACK,
                      frame = {l = 0, t = 17, r = 0, b = 0, yalign = 0}}

    Main_Page.Right_Mask = 
      widgets.Widget {frame_background = COLOR_BLACK,
                      frame = {l = 17, t = 1, r = 0, h = 17, yalign = 0}}
                     
    Main_Page.Heading_Label = 
      widgets.Label {text = {{text = "Help/Info",
                                      key = keybindings.help.key,
                                      key_sep = '()'},
                             " X =   , Y =   "},
                     frame = {l = 0, t = 0, y_align = 0}}
                     
    Main_Page.Body_Label = 
      widgets.Label {text = {{text = "",
                                      key = keybindings.command_region_elevation.key,
                                      key_sep = '()'},
                             {text = " Region Elevation:",
                              pen = COLOR_LIGHTBLUE}, NEWLINE,
                             {text = "",
                                      key = keybindings.command_biome.key,
                                      key_sep = '()'},
                             {text = " Region Biome:",
                              pen = COLOR_LIGHTBLUE},
                             "                        Cavern Water", NEWLINE,
                             NEWLINE,
                             {text = "",
                                      key = keybindings.command_vertical.key,
                                      key_sep = '()'},
                             {text = " Vertical:      ",
                              pen = COLOR_LIGHTBLUE},
                             {text = "",
                                      key = keybindings.command_horizontal.key,
                                      key_sep = '()'},
                             {text = " Horizontal:     ",
                              pen = COLOR_LIGHTBLUE},
                             {text = "",
                                      key = keybindings.command_top.key,
                                      key_sep = '()'},
                             {text = " Top:",
                              pen = COLOR_LIGHTBLUE}, NEWLINE,
                             "                                         ",
                             {text = "",
                                      key = keybindings.command_mid.key,
                                      key_sep = '()'},
                             {text = " Mid:",
                              pen = COLOR_LIGHTBLUE}, NEWLINE,
                             "                                         ",
                             {text = "",
                                      key = keybindings.command_low.key,
                                      key_sep = '()'},
                             {text = " Low:",
                              pen = COLOR_LIGHTBLUE}, NEWLINE,
                             {text = "",
                                      key = keybindings.command_is_brook.key,
                                      key_sep = '()'},
                             {text = " Is_Brook:",
                              pen = COLOR_LIGHTBLUE}},
                     frame = {l = 17, t = 1, y_align = 0}}
                     
    Main_Page.Heading_Label_X =
      widgets.Label {text = Fit_Right (tostring (x), 2),
                     frame = {l = 18, w = 2, t = 0, yalign = 0}}
                                          
    Main_Page.Heading_Label_Y = 
      widgets.Label {text = Fit_Right (tostring (y), 2),
                     frame = {l = 26,
                              w = 2,
                              t = 0,
                              yalign = 0}}
                                          
    Main_Page.Map_Label =
      widgets.Label {text = "Elevation",
                     frame = {l = 29, t = 0, yalign = 0}}    
    
    Main_Page.Region_Elevation_Edit =
      widgets.Label {text = Fit_Right (region.elevation [x] [y], 4),
                     text_pen = COLOR_LIGHTCYAN,
                     frame = {l = 40,
                               w = 5,
                               t = 1,
                               yalign = 0}}
                     
    Main_Page.Region_Biome_Edit = 
      widgets.Label {text = Fit_Right (region.biome [x] [y], 1),
                     text_pen = COLOR_LIGHTCYAN,
                     frame = {l = 43,
                              w = 2,
                              t = 2,
                              yalign = 0}}
                              
    Main_Page.River_Elevation_Label =
      widgets.Label {text = {{text = "",
                              key = keybindings.command_river_elevation.key,
                              key_sep = '()'},
                             {text = " River Elevation:",
                              pen = COLOR_LIGHTBLUE}},
                     frame = {l = 17, t = 3, yalign = 0},
                     visible = River_Elevation_Image (x, y) ~= ""}
                                             
    Main_Page.River_Elevation_Edit = 
      widgets.Label {text = Fit_Right (River_Elevation_Image (x, y), 4),
                     text_pen = COLOR_LIGHTCYAN,
                     frame = {l = 40, 
                              w = 5, 
                              t = 3, 
                              yalign = 0},
                     visible = River_Elevation_Image (x, y) ~= ""}
                        
    Main_Page.Visibility_List ["River_Elevation"] = {Main_Page.River_Elevation_Label,
                                                     Main_Page.River_Elevation_Edit}
                                                   
    Main_Page.Vertical_Edit =
      widgets.Label {text = Vertical_River_Image [region.rivers_vertical.active [x] [y]],
                     text_pen = COLOR_LIGHTCYAN,
                     frame = {l = 32, w = 6, t = 4, yalign = 0}}
                     
    Main_Page.X_Label =
      widgets.Label {text = {{text = "",
                              key = keybindings.command_river_x.key,
                              key_sep = '()'},
                             {text = " x min:",
                              pen = COLOR_LIGHTBLUE}, NEWLINE,
                             {text = "",
                              key = keybindings.command_river_X.key,
                              key_sep = '()'},
                             {text = " X Max:",
                              pen = COLOR_LIGHTBLUE}},
                     frame = {l = 21, t = 5, yalign = 0},
                     visible = region.rivers_vertical.active [x] [y] ~= 0}
                     
    Main_Page.X_Min_Edit =
      widgets.Label {text = Fit_Right (region.rivers_vertical.x_min [x] [y], 2),
                     text_pen = COLOR_LIGHTCYAN,
                     frame = {l = 33, w = 3, t = 5, yalign = 0},
                     visible = region.rivers_vertical.active [x] [y] ~= 0}
    
    Main_Page.X_Max_Edit =
      widgets.Label {text = Fit_Right (region.rivers_vertical.x_max [x] [y], 2),
                     text_pen = COLOR_LIGHTCYAN,
                     frame = {l = 33, w = 3, t = 6, yalign = 0},
                     visible = region.rivers_vertical.active [x] [y] ~= 0}
      
    Main_Page.Visibility_List ["Vertical"] = {Main_Page.X_Label,
                                              Main_Page.X_Min_Edit,
                                              Main_Page.X_Max_Edit} 
    Main_Page.Horizontal_Edit =
      widgets.Label {text = Horizontal_River_Image [region.rivers_horizontal.active [x] [y]],
                     text_pen = COLOR_LIGHTCYAN,
                     frame = {l = 54, w = 5, t = 4, yalign = 0}}
                         
    Main_Page.Y_Label =
      widgets.Label {text = {{text = "",
                              key = keybindings.command_river_y.key,
                              key_sep = '()'},
                             {text = " y min:",
                              pen = COLOR_LIGHTBLUE}, NEWLINE,
                             {text = "",
                              key = keybindings.command_river_Y.key,
                              key_sep = '()'},
                             {text = " Y Max:",
                              pen = COLOR_LIGHTBLUE}},
                     frame = {l = 37, t = 5, yalign = 0},
                     visible = region.rivers_vertical.active [x] [y] ~= 0}
                     
    Main_Page.Y_Min_Edit =
      widgets.Label {text = Fit_Right (region.rivers_horizontal.y_min [x] [y], 2),
                     text_pen = COLOR_LIGHTCYAN,
                     frame = {l = 49, w = 3, t = 5, yalign = 0},
                     visible = region.rivers_horizontal.active [x] [y] ~= 0}

    Main_Page.Y_Max_Edit =
      widgets.Label {text = Fit_Right (region.rivers_horizontal.y_max [x] [y], 2),
                     text_pen = COLOR_LIGHTCYAN,
                     frame = {l = 49, w = 3, t = 6, yalign = 0},
                     active = false,
                     visible = region.rivers_horizontal.active [x] [y] ~= 0}
                         
    Main_Page.Visibility_List ["Horizontal"] = {Main_Page.Y_Label,
                                                Main_Page.Y_Min_Edit,
                                                Main_Page.Y_Max_Edit}
    
    Main_Page.Is_Brook_Edit =
      widgets.Label {text = Bool_Image (df.global.world.world_data.region_map[region.pos.x]:_displace(region.pos.y).flags.is_brook),
                     text_pen = COLOR_LIGHTCYAN,
                     frame = {l = 32, w = 2, t = 7, yalign = 0}}
                     
    Main_Page.Top_Cavern_Water_Edit =
      widgets.Label {text = '0',
                     text_pen = COLOR_LIGHTCYAN,
                     frame = {l = 68, w = 2, t = 4, yalign = 0},
                     visible = df.global.world.worldgen.worldgen_parms.cavern_layer_count >= 1}
                         
    Main_Page.Mid_Cavern_Water_Edit =
      widgets.Label {text = '0',
                     text_pen = COLOR_LIGHTCYAN,
                     frame = {l = 68, w = 2, t = 5, yalign = 0},
                     visible = df.global.world.worldgen.worldgen_parms.cavern_layer_count >= 2}
                         
    Main_Page.Low_Cavern_Water_Edit =
      widgets.Label {text = '0',
                     text_pen = COLOR_LIGHTCYAN,
                     frame = {l = 68, w = 2, t = 6, yalign = 0},
                     visible = df.global.world.worldgen.worldgen_parms.cavern_layer_count >= 3}
                 
    if df.global.world.world_data.region_map[region.pos.x]:_displace(region.pos.y).flags.has_river then
      local r_entry = "None"
      local r_exit = "None"
      
      for i, river in ipairs (df.global.world.world_data.rivers) do
        for k, x_pos in ipairs (river.path.x) do
          if x_pos == region.pos.x and
             river.path.y [k] == region.pos.y then
            if k ~= 0 then
              if river.path.x [k - 1] < x_pos then
                r_entry = "West"
              
              elseif river.path.x [k - 1] > x_pos then
                r_entry = "East"
                
              elseif river.path.y [k - 1] < river.path.y [k] then
                r_entry = "North"
                
              else
                r_entry = "South"
              end
            end

            if k < #river.path.x - 1 then
              if river.path.x [k + 1] < x_pos then
                r_exit = "West"
                
              elseif river.path.x [k + 1] > x_pos then
                r_exit = "East"
                
              elseif river.path.y [k + 1] < river.path.y [k] then
                r_exit = "North"
                
              else
                r_exit = "South"
              end
              
            else
              if river.end_pos.x < x_pos then
                r_exit = "West"
                
              elseif river.end_pos.x > x_pos then
                r_exit = "East"
                
              elseif river.end_pos.y < river.path.y [k] then
                r_exit = "North"
                
              else
                r_exit = "South"
              end
            end
            
            break
          end
        end
      end
      
      Main_Page.River_Entry =
        widgets.Label {text = "River entry: " .. r_entry,
                       frame = {l = 22, t = 9, yalign = 0},
                       visible = r_entry ~= "None"}
    
      Main_Page.River_Exit =
        widgets.Label {text = "River exit: " .. r_exit,
                       frame = {l = 42, t = 9, yalign = 0}}
                       
    else
      Main_Page.River_Entry =
        widgets.Label {text = "River entry:",
                       frame = {l = 22, t = 9, yalign = 0},
                       visible = false}
    
      Main_Page.River_Exit =
        widgets.Label {text = "River exit:",
                       frame = {l = 42, t = 9, yalign = 0},
                       visible = false}    
    end
    
    Main_Page.elevationGrid = Grid {frame = {l = 1, t = 2, w = 17, h = 17},
                                    width = 17,
                                    height = 17,
                                    visible = true}
    
    Main_Page.biomeGrid = Grid {frame = {l = 1, t = 2, w = 17, h = 17},
                                width = 17,
                                height = 17,
                                visible = false}
    
    Main_Page.riversGrid = Grid {frame = {l = 1, t = 2, w = 16, h = 16},
                                 width = 16,
                                 height = 16,
                                 visible = false}

    Main_Page.topCavernGrid = Grid {frame = {l = 1, t = 2, w = 16, h = 16},
                                    width = 16,
                                    height = 16,
                                    visible = false}

    Main_Page.midCavernGrid = Grid {frame = {l = 1, t = 2, w = 16, h = 16},
                                    width = 16,
                                    height = 16,
                                    visible = false}

    Main_Page.lowCavernGrid = Grid {frame = {l = 1, t = 2, w = 16, h = 16},
                                    width = 16,
                                    height = 16,
                                    visible = false}
                                    
    Make_Elevation (x, y)
    Make_Biome (x, y)
    Make_Rivers (x, y)
    Make_Caverns (x, y)
    
    local Help_Page_Mask = 
      widgets.Widget {frame_background = COLOR_BLACK,
                      frame = {l = 0, t = 0, r = 0, b = 0, yalign = 0}}
                     
    helpPage = widgets.Panel {
        subviews = {Help_Page_Mask,
                    widgets.Label {text = Disclaimer (),
                    frame = {l = 1, t = 1, yalign = 0}}}}
                    
    local mainPage = widgets.Panel {
      subviews = {Main_Page.Top_Mask,
                  Main_Page.Bottom_Mask,
                  Main_Page.Right_Mask,
                  Main_Page.Heading_Label,
                  Main_Page.Heading_Label_X,
                  Main_Page.Heading_Label_Y,
                  Main_Page.Map_Label,                  
                  Main_Page.Body_Label,
                  Main_Page.Region_Elevation_Edit,
                  Main_Page.Region_Biome_Edit,
                  Main_Page.River_Elevation_Label,
                  Main_Page.River_Elevation_Edit,
                  Main_Page.Vertical_Edit,
                  Main_Page.X_Label,
                  Main_Page.X_Min_Edit,
                  Main_Page.X_Max_Edit,
                  Main_Page.Horizontal_Edit,
                  Main_Page.Y_Label,
                  Main_Page.Y_Min_Edit,
                  Main_Page.Y_Max_Edit,
                  Main_Page.Is_Brook_Edit,
                  Main_Page.Top_Cavern_Water_Edit,
                  Main_Page.Mid_Cavern_Water_Edit,
                  Main_Page.Low_Cavern_Water_Edit,
                  Main_Page.River_Entry,
                  Main_Page.River_Exit,
                  Main_Page.elevationGrid,
                  Main_Page.biomeGrid,
                  Main_Page.riversGrid,
                  Main_Page.topCavernGrid,
                  Main_Page.midCavernGrid,
                  Main_Page.lowCavernGrid}}
    
    local pages = widgets.Pages 
      {subviews = {mainPage,
                   helpPage},view_id = "pages",
                   }

    pages:setSelected (1)
    Focus = "Main"
      
    self:addviews {pages}
  end

  --============================================================

  function RegionManipulatorUi:updateElevation (value)
    if not tonumber (value) or 
       tonumber (value) < -999 or 
       tonumber (value) > 250 then
      dialog.showMessage ("Error!", "The Elevation legal range is -999 - 250", COLOR_RED)
    else
      region.elevation [x] [y] = tonumber (value)
    end
    
    Update (x, y, self.subviews.pages)      
  end
  
  --==============================================================
  
  function RegionManipulatorUi:updateBiome (value)
    if not tonumber (value) or 
       tonumber (value) < 1 or 
       tonumber (value) > 9 then
      dialog.showMessage ("Error!", "The Biome legal range is 1 - 9", COLOR_RED)
    else
      region.biome [x] [y] = tonumber (value)
    end
    
    Update (x, y, self.subviews.pages)      
  end
  
  --==============================================================

  function RegionManipulatorUi:flattenRegion ()
    for i = 0, #region.elevation - 1 do
      for k = 0, #region.elevation [0] -1 do
        region.elevation [i] [k] = region.elevation [x] [y]
      end
    end
    
    Make_Elevation (x, y)
    Update (x, y, self.subviews.pages)
  end
  
  --==============================================================
  
  function RegionManipulatorUi:updateRiversElevation (value)
    if not tonumber (value) or 
       tonumber (value) < -999 or 
       tonumber (value) > 250 then
      dialog.showMessage ("Error!", "The Elevation legal range is -999 - 250", COLOR_RED)

    else
      if region.rivers_horizontal.active [x] [y] ~= 0 then
        region.rivers_horizontal.elevation [x] [y] = tonumber (value)
      end

      if region.rivers_vertical.active [x] [y] ~= 0 then
        region.rivers_vertical.elevation [x] [y] = tonumber (value)
      end
    end
    
    Update (x, y, self.subviews.pages)
  end
  
  --==============================================================
  
  function RegionManipulatorUi:updateRiversVerticalActive (value)
    if string.upper (value) == "SOUTH" or
       string.upper (value) == "NORTH" then
      if region.rivers_vertical.active [x] [y] == 0 then
        region.rivers_vertical.x_min [x] [y] = 23
        region.rivers_vertical.x_max [x] [y] = 25

        if region.rivers_horizontal.active [x] [y] ~= 0 then
          region.rivers_vertical.elevation [x] [y] = region.rivers_horizontal.elevation [x] [y]
          
        else
          region.rivers_vertical.elevation [x] [y] = region.elevation [x] [y]
        end
      end      

      if string.upper (value) == "SOUTH" then
        region.rivers_vertical.active [x] [y] = 1
      else
        region.rivers_vertical.active [x] [y] = -1
      end
            
    elseif string.upper (value) == "NONE" then
      region.rivers_vertical.active [x] [y] = 0
      region.rivers_vertical.elevation [x] [y] = 100
      region.rivers_vertical.x_min [x] [y] = -30000
      region.rivers_vertical.x_max [x] [y] = -30000

    else
      dialog.showMessage ("Error!", "The legal values are 'None', 'North', and 'South'", COLOR_RED)          
    end
    
    Update (x, y, self.subviews.pages)
  end

  --==============================================================
  
  function RegionManipulatorUi:updateRiversVerticalXMin (value)
    if not tonumber (value) or
       tonumber (value) < 0 or
       tonumber (value) > 47 then
      dialog.showMessage ("Error!", "The X Min legal range is 0 - 47", COLOR_RED)
    
    elseif tonumber (value) > region.rivers_vertical.x_max [x] [y] then
      dialog.showMessage ("Error!", "The X Min value cannot be larger than X Max", COLOR_RED)
      
    else
      region.rivers_vertical.x_min [x] [y] = tonumber (value)
    end
    
    Update (x, y, self.subviews.pages)
  end
  
  --==============================================================
  
  function RegionManipulatorUi:updateRiversVerticalXMax (value)
    if not tonumber (value) or
       tonumber (value) < 0 or
       tonumber (value) > 47 then
      dialog.showMessage ("Error!", "The X Max legal range is 0 - 47", COLOR_RED)
    
    elseif tonumber (value) < region.rivers_vertical.x_min [x] [y] then
      dialog.showMessage ("Error!", "The X Max value cannot be smaller than X Min", COLOR_RED)
      
    else
      region.rivers_vertical.x_max [x] [y] = tonumber (value)
    end
    
    Update (x, y, self.subviews.pages)
  end
  
  --==============================================================
  
  function RegionManipulatorUi:updateRiversHorizontalActive (value)
    if string.upper (value) == "EAST" or
       string.upper (value) == "WEST" then
      if region.rivers_horizontal.active [x] [y] == 0 then
        region.rivers_horizontal.y_min [x] [y] = 23
        region.rivers_horizontal.y_max [x] [y] = 25

        if region.rivers_vertical.active [x] [y] ~= 0 then
          region.rivers_horizontal.elevation [x] [y] = region.rivers_vertical.elevation [x] [y]
          
        else
          region.rivers_horizontal.elevation [x] [y] = region.elevation [x] [y]
        end
      end      

      if string.upper (value) == "WEST" then
        region.rivers_horizontal.active [x] [y] = 1
      else
        region.rivers_horizontal.active [x] [y] = -1
      end
            
    elseif string.upper (value) == "NONE" then
      region.rivers_horizontal.active [x] [y] = 0
      region.rivers_horizontal.elevation [x] [y] = 100
      region.rivers_horizontal.y_min [x] [y] = -30000
      region.rivers_horizontal.y_max [x] [y] = -30000
    else
      dialog.showMessage ("Error!", "The legal values are 'None', 'East', and 'West'", COLOR_RED)      
    end
    
    Update (x, y, self.subviews.pages)
  end

  --==============================================================
  
  function RegionManipulatorUi:updateRiversHorizontalYMin (value)
    if not tonumber (value) or
       tonumber (value) < 0 or
       tonumber (value) > 47 then
      dialog.showMessage ("Error!", "The Y Min legal range is 0 - 47", COLOR_RED)
    
    elseif tonumber (value) > region.rivers_horizontal.y_max [x] [y] then
      dialog.showMessage ("Error!", "The Y Min value cannot be larger than Y Max", COLOR_RED)
      
    else
      region.rivers_horizontal.y_min [x] [y] = tonumber (value)
    end
    
    Update (x, y, self.subviews.pages)
  end
  
  --==============================================================
  
  function RegionManipulatorUi:updateRiversHorizontalYMax (value)
    if not tonumber (value) or
       tonumber (value) < 0 or
       tonumber (value) > 47 then
      dialog.showMessage ("Error!", "The Y Max legal range is 0 - 47", COLOR_RED)
    
    elseif tonumber (value) < region.rivers_horizontal.y_min [x] [y] then
      dialog.showMessage ("Error!", "The Y Max value cannot be smaller than Y Min", COLOR_RED)
      
    else
      region.rivers_horizontal.y_max [x] [y] = tonumber (value)
    end
    
    Update (x, y, self.subviews.pages)
  end

  --==============================================================

  function RegionManipulatorUi:updateTopCavernWater (value)
    local val
    if (tonumber (value) and (tonumber (value) < 0 or tonumber (value) > 9)) or
       (not tonumber (value) and
        (string.upper (value) ~= 'A' and
         string.upper (value) ~= 'B' and
         string.upper (value) ~= 'C' and
         string.upper (value) ~= 'D' and
         string.upper (value) ~= 'E' and
         string.upper (value) ~= 'F')) then
      dialog.showMessage ("Error!", "The legal values are hex values, i.e. 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D, E, and F", COLOR_RED)
      return
    end
    
    if tonumber (value) then
      val = tonumber (value)
    elseif string.upper (value) == 'A' then
      val = 10
    elseif string.upper (value) == 'B' then
      val = 11
    elseif string.upper (value) == 'C' then
      val = 12
    elseif string.upper (value) == 'D' then
      val = 13
    elseif string.upper (value) == 'E' then
      val = 14
    else
      val = 15     
    end
 
    for l, feature in ipairs (df.global.world.world_data.region_details [0].features [x] [y]) do
      if feature.layer >= 0 then
        if df.global.world.world_data.underground_regions [feature.layer].layer_depth == 0 then
          for m = 0, 3 do
            feature.unk_30 [m] = (val % 2 == 1)          
            val = math.floor (val / 2)
          end
          
          break
        end
      end
    end
   
    Update (x, y, self.subviews.pages)
  end

  --==============================================================
  
  function RegionManipulatorUi:updateMidCavernWater (value)
    local val
    if (tonumber (value) and (tonumber (value) < 0 or tonumber (value) > 9)) or
       (not tonumber (value) and
        (string.upper (value) ~= 'A' and
         string.upper (value) ~= 'B' and
         string.upper (value) ~= 'C' and
         string.upper (value) ~= 'D' and
         string.upper (value) ~= 'E' and
         string.upper (value) ~= 'F')) then
      dialog.showMessage ("Error!", "The legal values are hex values, i.e. 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D, E, and F", COLOR_RED)
      return
    end
    
    if tonumber (value) then
      val = tonumber (value)
    elseif string.upper (value) == 'A' then
      val = 10
    elseif string.upper (value) == 'B' then
      val = 11
    elseif string.upper (value) == 'C' then
      val = 12
    elseif string.upper (value) == 'D' then
      val = 13
    elseif string.upper (value) == 'E' then
      val = 14
    else
      val = 15     
    end
 
    for l, feature in ipairs (df.global.world.world_data.region_details [0].features [x] [y]) do
      if feature.layer >= 0 then
        if df.global.world.world_data.underground_regions [feature.layer].layer_depth == 1 then
          for m = 0, 3 do
            feature.unk_30 [m] = (val % 2 == 1)          
            val = math.floor (val / 2)
          end
          
          break
        end
      end
    end
   
    Update (x, y, self.subviews.pages)
  end

  --==============================================================
  
  function RegionManipulatorUi:updateLowCavernWater (value)
    local val
    if (tonumber (value) and (tonumber (value) < 0 or tonumber (value) > 9)) or
       (not tonumber (value) and
        (string.upper (value) ~= 'A' and
         string.upper (value) ~= 'B' and
         string.upper (value) ~= 'C' and
         string.upper (value) ~= 'D' and
         string.upper (value) ~= 'E' and
         string.upper (value) ~= 'F')) then
      dialog.showMessage ("Error!", "The legal values are hex values, i.e. 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D, E, and F", COLOR_RED)
      return
    end
    
    if tonumber (value) then
      val = tonumber (value)
    elseif string.upper (value) == 'A' then
      val = 10
    elseif string.upper (value) == 'B' then
      val = 11
    elseif string.upper (value) == 'C' then
      val = 12
    elseif string.upper (value) == 'D' then
      val = 13
    elseif string.upper (value) == 'E' then
      val = 14
    else
      val = 15     
    end
 
    for l, feature in ipairs (df.global.world.world_data.region_details [0].features [x] [y]) do
      if feature.layer >= 0 then
        if df.global.world.world_data.underground_regions [feature.layer].layer_depth == 2 then
          for m = 0, 3 do
            feature.unk_30 [m] = (val % 2 == 1)          
            val = math.floor (val / 2)
          end
          
          break
        end
      end
    end
   
    Update (x, y, self.subviews.pages)
  end

  --==============================================================
  
  function RegionManipulatorUi:onInput (keys)
    if keys.LEAVESCREEN_ALL  then
        self:dismiss ()
    end
    
    if keys.LEAVESCREEN then
      if Focus == "Help" then
        Focus = "Main"
        self.subviews.pages:setSelected (1)
        
      else
        self:dismiss ()
      end
    end
    
    if keys [keybindings.elevation.key] then
      Main_Page.Map_Label:setText ("Elevation")
      Main_Page.elevationGrid.visible = true
      Main_Page.biomeGrid.visible = false
      Main_Page.riversGrid.visible = false
      Main_Page.topCavernGrid.visible = false
      Main_Page.midCavernGrid.visible = false
      Main_Page.lowCavernGrid.visible = false
      
    elseif keys [keybindings.biome.key] then
      Main_Page.Map_Label:setText ("Biome")
      Main_Page.elevationGrid.visible = false
      Main_Page.biomeGrid.visible = true
      Main_Page.riversGrid.visible = false
      Main_Page.topCavernGrid.visible = false
      Main_Page.midCavernGrid.visible = false
      Main_Page.lowCavernGrid.visible = false

    elseif keys [keybindings.rivers.key] then
      Main_Page.Map_Label:setText ("Rivers")
      Main_Page.elevationGrid.visible = false
      Main_Page.biomeGrid.visible = false
      Main_Page.riversGrid.visible = true
      Main_Page.topCavernGrid.visible = false
      Main_Page.midCavernGrid.visible = false
      Main_Page.lowCavernGrid.visible = false

    elseif keys [keybindings.top_cavern.key] then
      if df.global.world.worldgen.worldgen_parms.cavern_layer_count >= 1 then
        Main_Page.Map_Label:setText ("Top Cavern Water")
        Main_Page.elevationGrid.visible = false
        Main_Page.biomeGrid.visible = false
        Main_Page.riversGrid.visible = false
        Main_Page.topCavernGrid.visible = true
        Main_Page.midCavernGrid.visible = false
        Main_Page.lowCavernGrid.visible = false
      end
      
    elseif keys [keybindings.mid_cavern.key] then
      if df.global.world.worldgen.worldgen_parms.cavern_layer_count >= 2 then
        Main_Page.Map_Label:setText ("Mid Cavern Water")
        Main_Page.elevationGrid.visible = false
        Main_Page.biomeGrid.visible = false
        Main_Page.riversGrid.visible = false
        Main_Page.topCavernGrid.visible = false
        Main_Page.midCavernGrid.visible = true
        Main_Page.lowCavernGrid.visible = false
      end
        
    elseif keys [keybindings.low_cavern.key] then
      if df.global.world.worldgen.worldgen_parms.cavern_layer_count >= 3 then
        Main_Page.Map_Label:setText ("Low Cavern Water")
        Main_Page.elevationGrid.visible = false
        Main_Page.biomeGrid.visible = false
        Main_Page.riversGrid.visible = false
        Main_Page.topCavernGrid.visible = false
        Main_Page.midCavernGrid.visible = false
        Main_Page.lowCavernGrid.visible = true
      end
      
    elseif keys [keybindings.invisible.key] then
      Main_Page.Map_Label:setText ("Native DF Region")
      Main_Page.elevationGrid.visible = false
      Main_Page.biomeGrid.visible = false
      Main_Page.riversGrid.visible = false
      Main_Page.topCavernGrid.visible = false
      Main_Page.midCavernGrid.visible = false
      Main_Page.lowCavernGrid.visible = false

    elseif keys [keybindings.flatten.key] then
      dialog.showYesNoPrompt ("Flatten Terrain?",
                              "The whole region will be set to an elevation of " .. tostring (region.elevation [x] [y]) .. " on Enter.",
                               COLOR_WHITE,
                              NIL,
                              self:callback ("flattenRegion"))
      
    elseif keys [keybindings.up.key] and not keys._STRING then
      if focus ~= "Help" then
        if y > 0 then
          y = y - 1
        end

        Update (x, y, self.subviews.pages)
      end
            
    elseif keys [keybindings.down.key] and not keys._STRING then
      if focus ~= "Help" then
        if y < max_y - 1 then
          y = y + 1
        end

        Update (x, y, self.subviews.pages)
      end
            
    elseif keys [keybindings.left.key] and not keys._STRING then
      if focus ~= "Help"  then
        if x > 0 then
          x = x - 1
        end
      
        Update (x, y, self.subviews.pages)
      end
      
    elseif keys [keybindings.command_region_elevation.key] and focus ~= "Help" then
      dialog.showInputPrompt ("Change elevation of region tile",
                              {{text = "Elevation value key:",
                                pen = COLOR_YELLOW}, NEWLINE,
                               "-999 -    0 is deep underground capped to the SMR", NEWLINE,
                               "   1 -   99 is ocean level", NEWLINE,
                               " 100 - 149 is normal terrain", NEWLINE,
                               " 150 - 250 is mountain"},
                              COLOR_WHITE,
                              "",
                              self:callback ("updateElevation"))
      
    elseif keys [keybindings.command_biome.key] and focus ~= "Help" then
      dialog.showInputPrompt ("Change biome reference of region tile",
                              {{text = "World tile reference key:",
                                pen = COLOR_YELLOW}, NEWLINE,
                               "7: NW 8: N   9: NE", NEWLINE,
                               "4: W  5: Own 6: E", NEWLINE,
                               "1: SW 2: S   3: SE"},
                              COLOR_WHITE,
                              "",
                              self:callback ("updateBiome"))
      
    elseif keys [keybindings.command_river_elevation.key] and 
           River_Elevation_Image (x, y) ~= "" and
           focus ~= "Help" then
      dialog.showInputPrompt ("Change river elevation of region tile",
                              {{text = "Elevation value key:",
                                pen = COLOR_YELLOW}, NEWLINE,
                               "-999 -    0 is deep underground capped to the SMR", NEWLINE,
                               "   1 -   99 is ocean level", NEWLINE,
                               " 100 - 149 is normal terrain", NEWLINE,
                               " 150 - 250 is mountain"},
                              COLOR_WHITE,
                              "",
                              self:callback ("updateRiversElevation"))
      
    elseif keys [keybindings.command_vertical.key] and focus ~= "Help" then
      dialog.showInputPrompt ("Set river course vertical component",
                              {{text = "Vertical river course key:",
                                pen = COLOR_YELLOW}, NEWLINE,
                               "None", NEWLINE,
                               "South", NEWLINE,
                               "North"},
                              COLOR_WHITE,
                              "",
                              self:callback ("updateRiversVerticalActive"))

    elseif keys [keybindings.command_river_x.key] and 
           region.rivers_vertical.active [x] [y] ~= 0 and
           focus ~= "Help" then
      dialog.showInputPrompt ("Set river vertical course min x value",
                              {{text = "Vertical river x min:",
                                pen = COLOR_YELLOW}, NEWLINE,
                               "0 - 47, but not greater than X Max"},
                              COLOR_WHITE,
                              "",
                              self:callback ("updateRiversVerticalXMin"))
                              
    elseif keys [keybindings.command_river_X.key] and
           region.rivers_vertical.active [x] [y] ~= 0 and
           focus ~= "Help" then
      dialog.showInputPrompt ("Set river vertical course Max X value",
                              {{text = "Vertical river X Max:",
                                pen = COLOR_YELLOW}, NEWLINE,
                               "0 - 47, but not less than x min"},
                              COLOR_WHITE,
                              "",
                              self:callback ("updateRiversVerticalXMax"))
                              
    elseif keys [keybindings.command_horizontal.key] and focus ~= "Help" then
      dialog.showInputPrompt ("Set river course horizontal component",
                              {{text = "Horizontal river course key:",
                                pen = COLOR_YELLOW}, NEWLINE,
                               "None", NEWLINE,
                               "East", NEWLINE,
                               "West"},
                              COLOR_WHITE,
                              "",
                              self:callback ("updateRiversHorizontalActive"))
       
    elseif keys [keybindings.command_river_y.key] and 
           region.rivers_horizontal.active [x] [y] ~= 0 and
           focus ~= "Help" then
      dialog.showInputPrompt ("Set river horizontal course min y value",
                              {{text = "Horizontal river y min:",
                                pen = COLOR_YELLOW}, NEWLINE,
                               "0 - 47, but not greater than Y Max"},
                              COLOR_WHITE,
                              "",
                              self:callback ("updateRiversHorizontalYMin"))
                              
    elseif keys [keybindings.command_river_Y.key] and
           region.rivers_horizontal.active [x] [y] ~= 0 and
           focus ~= "Help" then
      dialog.showInputPrompt ("Set river horizontal course Max Y value",
                              {{text = "Horizontal river Y Max:",
                                pen = COLOR_YELLOW}, NEWLINE,
                               "0 - 47, but not less than y min"},
                              COLOR_WHITE,
                              "",
                              self:callback ("updateRiversHorizontalYMax"))
                              
    elseif keys [keybindings.command_is_brook.key] and focus ~= "Help" then
      df.global.world.world_data.region_map[region.pos.x]:_displace(region.pos.y).flags.is_brook =
        not df.global.world.world_data.region_map[region.pos.x]:_displace(region.pos.y).flags.is_brook
        
      Update (x, y, self.subviews.pages)
                              
    elseif keys [keybindings.command_top.key] and
           df.global.world.worldgen.worldgen_parms.cavern_layer_count >= 1 and 
           focus ~= "Help" then
      dialog.showInputPrompt ("Set 1:st cavern water indicator",
                              {{text = "Hex value:",
                                pen = COLOR_YELLOW}, NEWLINE,
                               "0 - F"},
                              COLOR_WHITE,
                              "",
                              self:callback ("updateTopCavernWater"))
                              
    elseif keys [keybindings.command_mid.key] and 
           df.global.world.worldgen.worldgen_parms.cavern_layer_count >= 2 and
           focus ~= "Help" then
      dialog.showInputPrompt ("Set 2:nd cavern water indicator",
                              {{text = "Hex value:",
                                pen = COLOR_YELLOW}, NEWLINE,
                               "0 - F"},
                              COLOR_WHITE,
                              "",
                              self:callback ("updateMidCavernWater"))
                              
    elseif keys [keybindings.command_low.key] and
           df.global.world.worldgen.worldgen_parms.cavern_layer_count >= 3 and
           focus ~= "Help" then
      dialog.showInputPrompt ("Set 3:rd cavern water indicator",
                              {{text = "Hex value:",
                                pen = COLOR_YELLOW}, NEWLINE,
                               "0 - F"},
                              COLOR_WHITE,
                              "",
                              self:callback ("updateLowCavernWater"))
                              
    elseif keys [keybindings.right.key] and not keys._STRING then
      if focus ~= "Help" then
        if x < max_x - 1 then
          x = x + 1
        end
        
        Update (x, y, self.subviews.pages)
      end
      
    elseif keys [keybindings.upleft.key] and not keys._STRING then
      if focus ~= "Help" then
        if x > 0 then
          x = x - 1
        end
      
        if y > 0 then
          y = y - 1
        end
      
        Update (x, y, self.subviews.pages)
      end
      
    elseif keys [keybindings.upright.key] and not keys._STRING then
      if focus ~= "Help" then
        if x < max_x - 1 then
          x = x + 1
        end
      
        if y > 0 then
          y = y - 1
        end
      
        Update (x, y, self.subviews.pages)
      end
      
    elseif keys [keybindings.downleft.key] and not keys._STRING then
      if focus ~= "Help" then
        if x > 0 then
          x = x - 1
        end
      
        if y < max_y - 1 then
          y = y + 1
        end
      
        Update (x, y, self.subviews.pages)
      end
      
    elseif keys [keybindings.downright.key] and not keys._STRING then
      if focus ~= "Help" then
        if x < max_x - 1 then
          x = x + 1
        end
      
        if y < max_y - 1 then
          y = y + 1
        end
      
        Update (x, y, self.subviews.pages)
      end      
    end

    self.super.onInput (self, keys)
  end

  --============================================================

  function Show_Viewer ()
    local screen = RegionManipulatorUi {}
    persist_screen = screen
    screen:show ()
  end

  --============================================================

  Show_Viewer ()
end

regionmanipulator ()