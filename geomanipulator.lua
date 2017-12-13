--Manipulates the geo biome of a single world map tile to give it its own geo biome. Use ? for help. 
--Has to be used with a loaded world, but pre embark.
--[====[

geomanipulator
========
]====]
function geomanipulator ()
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

  local gui = require 'gui'
  local dialog = require 'gui.dialogs'
  local widgets =require 'gui.widgets'
  local guiScript = require 'gui.script'

  local map_width = df.global.world.world_data.world_width
  local map_height = df.global.world.world_data.world_height
  local geo_biome = df.world_geo_biome:new ()
  local geo_depth
  local layer_context = true
  local layer_index
  local vein_context = false
  local Excess_Soil_Warning = false
  local cursor_x = df.global.world.world_data.region_details [0].pos.x
  local cursor_y = df.global.world.world_data.region_details [0].pos.y  
  local biome = df.global.world.world_data.region_map [cursor_x]:_displace(cursor_y)

  local keybindings={
    delete = {key = "CUSTOM_D",
              desc = "Delete the currently highlighted layer/vein/cluster/inclusion. The layer below extends upwards to cover the gap."},
    split = {key = "CUSTOM_S",
             desc = "Splits the current layer into two."},
    expand = {key = "CUSTOM_E",
              desc = "Expands the current layer one level downwards. The layer below has to be able to donate levels. The lowest layer cannot be expanded."},
    contract = {key = "CUSTOM_C",
                desc = "Contracts the current layer, giving to the layer below. Cannot contract when size one or at the bottom."},
    morph = {key = "CUSTOM_M",
             desc = "Morph the current layer into something else. All clusters and veins inside are removed."},
    add = {key = "CUSTOM_A",
           desc = "Add a vein or cluster to the expanded layer."},
    rem = {key = "CUSTOM_R",
           desc = "Remove the currently selected vein/cluster. It will also remove everything nested inside of it."},
    nest = {key = "CUSTOM_N",
            desc = "Nest a cluster inside the currently selected vein/cluster."},
    writ = {key = "CUSTOM_W",
            desc = "Replace the embark geo biome with the manipulated one."},
    help = {key = "HELP",
            desc = "Show this help/info                                     "},
  }
 
  local Max_Layer_Name_Length = 0
  local Max_Type_Name_Length = string.len ("IGNEOUS_INTRUSIVE")
  
  for i, material in ipairs (df.global.world.raws.inorganics) do
    if material.flags.SEDIMENTARY or
       material.flags.IGNEOUS_INTRUSIVE or
       material.flags.IGNEOUS_EXTRUSIVE or
       material.flags.METAMORPHIC or
       material.flags.SOIL then
      if string.len (material.id) > Max_Layer_Name_Length then
        Max_Layer_Name_Length = string.len (material.id)
      end
    end       
  end
  
  local Max_Vein_Name_Length = 0
  
  for i, material in ipairs (df.global.world.raws.inorganics) do
    if #material.environment_spec.mat_index ~= 0 or
       #material.environment.location ~= 0 then
      if string.len (material.id) > Max_Vein_Name_Length then
        Max_Vein_Name_Length = string.len (material.id)
      end
    end
  end
   
  local Max_Cluster_Name_Length = string.len ("CLUSTER_LARGE")
  local Max_Soil_Depth = math.floor ((154 - biome.elevation) / 5)
  
  if Max_Soil_Depth < 1 then
    Max_Soil_Depth = 1
  end
  
  --===========================================================================

  function Fit (Item, Size)
    return Item .. string.rep (' ', Size - string.len (Item))
  end
   
  --===========================================================================

  function Fit_Right (Item, Size)
    return string.rep (' ', Size - string.len (Item)) .. Item
  end
   
  --===========================================================================

  function Layer_Image (Layer, Type, Start, Stop)
    return Fit (Layer, Max_Layer_Name_Length + 1) .. Fit (Type, Max_Type_Name_Length + 1) .. Fit_Right (tostring (Start), 5) .. Fit_Right (tostring (Stop), 5)
  end
  
  --===========================================================================

  function Generate_Layer_List (Geo_Biome)
    local Layer_List = {}
    
    for i, layer in ipairs (Geo_Biome.layers) do
    Layer_List [i + 1] = Layer_Image (df.global.world.raws.inorganics [layer.mat_index].id, df.geo_layer_type [layer.type], layer.top_height, layer.bottom_height)
    end
    
    return Layer_List
  end
  
  --===========================================================================

  function Nested_In_Image (Layer, Nested_In)
    if Nested_In == -1 then
      return string.rep (' ', Max_Vein_Name_Length + 1)
      
    else
      return Fit (df.global.world.raws.inorganics [Layer.vein_mat [Nested_In]].id, Max_Vein_Name_Length + 1)
    end
  end
  
  --===========================================================================

  function Vein_Image (Layer, index)
    return Fit (df.global.world.raws.inorganics [Layer.vein_mat [index]].id, Max_Vein_Name_Length + 1) ..
           Fit_Right (tostring (Layer.vein_unk_38 [index]), 5) .. " " .. 
           Fit (df.inclusion_type [Layer.vein_type [index]], Max_Cluster_Name_Length + 1) ..
           Nested_In_Image (Layer, Layer.vein_nested_in [index])
  end
  
  --===========================================================================

  function Generate_Vein_List (Geo_Biome, index)
    local Vein_List = {}
    
    for i, vein in ipairs (Geo_Biome.layers [index].vein_mat) do
      Vein_List [i + 1] = Vein_Image (Geo_Biome.layers [index], i)
    end
    
    return Vein_List
  end
  
  --===========================================================================

  function Check_Soil_Depth ()
    local soil_depth = 0
    
    for i, layer in ipairs (geo_biome.layers) do
      if layer.type == df.geo_layer_type.SOIL or
         layer.type == df.geo_layer_type.SOIL_SAND then
        soil_depth = soil_depth + layer.top_height - layer.bottom_height + 1
      end
    end
    
   if soil_depth > Max_Soil_Depth then
      if not Excess_Soil_Warning then
         dialog.showMessage ("Warning!", "Exceeding max number of soil levels (" .. 
                            tostring (Max_Soil_Depth) .."). DF will reduce it to at most that number. You currently have " .. 
                              tostring (soil_depth) .. " levels.\n",COLOR_LIGHTRED)
         Excess_Soil_Warning = true
      end
      
    else
       Excess_Soil_Warning = false
    end
  end
  
  --===========================================================================

  geo_biome.unk1 = df.global.world.world_data.geo_biomes [biome.geo_index].unk1
  geo_biome.index = df.global.world.world_data.geo_biomes [biome.geo_index].index  --  Change once we commit.

  for i, layer in ipairs (df.global.world.world_data.geo_biomes [biome.geo_index].layers) do
    geo_biome.layers:insert (i, df.world_geo_layer:new ())
    geo_biome.layers [i].type = layer.type
    geo_biome.layers [i].mat_index = layer.mat_index
    geo_biome.layers [i].top_height = layer.top_height
    geo_biome.layers [i].bottom_height = layer.bottom_height
    
    for k, vein in ipairs (layer.vein_mat) do
      geo_biome.layers [i].vein_mat:insert (k, vein)
      geo_biome.layers [i].vein_nested_in:insert (k, layer.vein_nested_in [k])
      geo_biome.layers [i].vein_type:insert (k, layer.vein_type [k])
      geo_biome.layers [i].vein_unk_38:insert (k, layer.vein_unk_38 [k])      
    end
    
    geo_depth = layer.bottom_height
  end
  
 --============================================================
 
   function Disclaimer (tlb)
    local disclaimer =
      {"Geo Manipulator allows you to manipulate a copy of the geo biome associated with the", NEWLINE,
       "world tile the embark view displays.The manipulated copy can then be written as a new", NEWLINE, 
       "geo biome and the world level tile is then associated with that geo biome instead.", NEWLINE,
       "Note that the replaced geo biome will affect only the embark tiles controlled by that", NEWLINE,
       "world tile's biome: any biomes 'borrowed' from surrounding world tiles will still be", NEWLINE,
       "controlled by those geo biomes. However, it is possible to edit those as well, one at", NEWLINE,
       "a time using this tool on those world level tiles by shifting the embark location to", NEWLINE,
       "those tiles.", NEWLINE,
       "Geo Manipulator allows you to delete, split, expand, contract and morpth geological", NEWLINE,
       "layers of the future embark to change them into the layer materials and thicknesses", NEWLINE,
       "you desire (limits apply). Once a layer has had its layer material determined, you", NEWLINE,
       "can add, remove, and nest veins and clusters in those layer. Geo Manipulator tries", NEWLINE,
       "to adhere to the rules DF uses for what veins/clusters and nested materials you can", NEWLINE,
       "add by using the RAW information for the materials.", NEWLINE,
       "Geo Manipulator does not provide any help regarding what materials are used for, so", NEWLINE,
       "you will have to consult the wiki to find out e.g. which materials contain iron,", NEWLINE,
       "as well as which layer materials those iron bearing ores can be found in.", NEWLINE,
       "In addition to the material rules, Geo Manipulator does not allow you to change the", NEWLINE,
       "Thickness of the embark: the total number of levels is kept at the value DF", NEWLINE,
       "generated for the geo biome. Similarly, DF has a rule for how many soil levels you", NEWLINE,
       "can have, with excess ones being 'eroded'. Geo Manipulator warns you when you", NEWLINE,
       "exceed the number, but it's your responsibility to scale it back, or DF will do it", NEWLINE,
       "for you. DF also seems to support a maximum of 16 layers, so Geo Manipulator does", NEWLINE,
       "not allow you to have more.", NEWLINE, NEWLINE,
       "Version 0.3 2017-09-24", NEWLINE,
       "Caveats: The testing has been limited, with all the associated risk of bugs.", NEWLINE,
       "'Alluvial' only materials cannot be added to layers, as I have found no useful", NEWLINE,
       "information on how to identify that environment (it appears to be emergent rather", NEWLINE,
       "than strictly dependent on material properties).", NEWLINE,
       "The soil depth checking is not complete, so the tool allows you to define soil for", NEWLINE,
       "a environments where it shouldn't be present. It is suspected DF will simply 'erode'", NEWLINE,
       "such soil layers.", NEWLINE,
       "According to 'prospector.cpp' the maximum soil depth is '(154 - elevation) / 5' or 1,", NEWLINE,
       "whichever is higher. The elevation is that of the embark tile, while Geo Manipulator", NEWLINE,
       "uses that of the world tile which might be different, since the embark tile elevation", NEWLINE,
       "can differ from that of the biome (in particular if there's a volcano there).", NEWLINE,
       "Also note that the elevation is the game play one (range 0 - 200), rather than the PSV", NEWLINE,
       "one (0-400).", NEWLINE}
      
    if tlb then
        for _, v in ipairs (disclaimer) do
            table.insert (tlb, v)
        end
    end
  end

  --============================================================
  
  GeoManipulatorUi = defclass (GeoManipulatorUi, gui.FramedScreen)
  GeoManipulatorUi.ATTRS = {
    frame_style = gui.GREY_LINE_FRAME,
    frame_title = "Geo Manipulator",
  }

  --============================================================

  function GeoManipulatorUi:onHelp ()
    self.subviews.pages:setSelected (2)
    Help_Context = true
    focus = "Help"
  end

  --============================================================

  function GeoManipulatorUi:init ()
    self.stack = {}
    self.item_count = 0
    self.keys = {}
    local helptext = {{text="Help"}, NEWLINE, NEWLINE}
    
    local move_key = {}
    local move_key_index = 0
    local normal_key = {}
    local normal_key_index = 0
    
    table.insert(helptext,NEWLINE)
    
    for i, v in pairs (keybindings) do
      table.insert (helptext, {text = v.desc, key = v.key, key_sep = ': '})
      table.insert (helptext, NEWLINE)
    end
    
    table.insert (helptext,NEWLINE)
    
    Disclaimer (helptext)
        
    local helpPage = widgets.Panel {
      subviews = {widgets.Label {text = helptext,
                                 frame = {l = 1, t = 1, yalign = 0}}}}

    local mainList = widgets.List {view_id = "list_main", choices = Generate_Layer_List (geo_biome), frame = {l = 1, t = 3, yalign = 0}, on_submit = self:callback ("editSelected"),
                                   text_pen = dfhack.pen.parse {fg = COLOR_DARKGRAY, bg = 0}, cursor_pen = dfhack.pen.parse {fg = COLOR_YELLOW, bg = 0}}

    local mainPage=widgets.Panel {
        subviews = {
            mainList,
            widgets.Label {text = {{text = "<no item>", id = "name"},
                                   {gap = 1, text = "Help", key = keybindings.help.key, key_sep = '()'}}, view_id = 'lbl_current_item', frame = {l = 1, t = 1, yalign = 0}},
        view_id = 'page_main'}}

    local pages = widgets.Pages 
       {subviews = {mainPage,
                    helpPage}, view_id = "pages"}

    self:addviews {
        pages
    }
  end
  
  --==============================================================

  function GeoManipulatorUi:editSelected (index, choice)
    local index, choice = self.subviews.pages.subviews [1].subviews [1]:getSelected ()

    if layer_context then
      layer_context = false
      layer_index = index
      vein_context = true
      self.subviews.pages.subviews [1].subviews [1]:setChoices (Generate_Vein_List (geo_biome, layer_index - 1))
    end
  end
  
  --==============================================================
  
  function GeoManipulatorUi:onInput (keys)
    if keys.LEAVESCREEN_ALL then
      self:dismiss()
    end
    
    if keys.LEAVESCREEN then
      if Help_Context then
        Help_Context = false
        self.subviews.pages:setSelected (1)
        return        
      end
      
      if layer_context then
        self:dismiss ()
        
      elseif vein_context then
        vein_context = false
        layer_context = true
        self.subviews.pages.subviews [1].subviews [1]:setChoices (Generate_Layer_List (geo_biome), layer_index)        
      end
    end
    
    if Help_Context then
      return
    end

    local index, choice = self.subviews.pages.subviews [1].subviews [1]:getSelected ()
    local selected = index
    if index == NIL then
      selected = 1
      index = 0
    else
      index = index - 1 --  C convention has 0 as the first index, while Lua uses 1...
    end
    
    if keys [keybindings.delete.key] then
      if layer_context then
        if #geo_biome.layers == 1 then
          dialog.showMessage ("Error!", "You have to retain at least one layer.\n",COLOR_LIGHTRED)
        
        else
          if selected == #geo_biome.layers then
            geo_biome.layers [index - 1].bottom_height = geo_biome.layers [index].bottom_height
            selected = selected - 1
          
          else
            geo_biome.layers [index + 1].top_height = geo_biome.layers [index].top_height
          end

          geo_biome.layers [index]:delete ()
          geo_biome.layers:erase (index)
          
          Check_Soil_Depth ()
          self.subviews.pages.subviews [1].subviews [1]:setChoices (Generate_Layer_List (geo_biome), selected)
        end
      end
      
    elseif keys [keybindings.split.key] then
      if layer_context then
        if #geo_biome.layers == 16 then
          dialog.showMessage ("Error!", "DF doesn't recognize more than at most 16 layers.\n",COLOR_LIGHTRED)
        
        elseif geo_biome.layers [index].top_height - geo_biome.layers [index].bottom_height == 0 then
          dialog.showMessage ("Error!", "A layer has to have a depth of at least two do donate space to a new layer.\n",COLOR_LIGHTRED)
        
        else
          geo_biome.layers:insert (index, df.world_geo_layer:new ())
          geo_biome.layers [index].type = geo_biome.layers [index + 1].type
          geo_biome.layers [index].mat_index = geo_biome.layers [index + 1].mat_index
          geo_biome.layers [index].top_height = geo_biome.layers [index + 1].top_height
          geo_biome.layers [index].bottom_height = math.ceil ((geo_biome.layers [index].top_height + geo_biome.layers [index + 1].bottom_height) / 2)
          geo_biome.layers [index + 1].top_height = geo_biome.layers [index].bottom_height - 1
          geo_biome.layers [index].vein_mat = {}
          geo_biome.layers [index].vein_nested_in = {}
          geo_biome.layers [index].vein_type = {}
          geo_biome.layers [index].vein_unk_38 = {}
          self.subviews.pages.subviews [1].subviews [1]:setChoices (Generate_Layer_List (geo_biome), selected)
        end
      end
      
    elseif keys [keybindings.expand.key] then
      if layer_context then
        if selected == #geo_biome.layers then
          dialog.showMessage ("Error!", "The lowest layer cannot be expanded.\n",COLOR_LIGHTRED)
        
        else
          if geo_biome.layers [index + 1].top_height - geo_biome.layers [index + 1].bottom_height == 0 then
            dialog.showMessage ("Error!", "A layer can be expanded only if the layer below has levels to spare.\n",COLOR_LIGHTRED)
          
          else
            geo_biome.layers [index].bottom_height = geo_biome.layers [index].bottom_height - 1
            geo_biome.layers [index + 1].top_height = geo_biome.layers [index + 1].top_height - 1
            Check_Soil_Depth ()
              self.subviews.pages.subviews [1].subviews [1]:setChoices (Generate_Layer_List (geo_biome), selected)
          end
        end
      end
        
    elseif keys [keybindings.contract.key] then
      if layer_context then
        if selected == #geo_biome.layers then
          dialog.showMessage ("Error!", "The lowest layer cannot be contracted.\n",COLOR_LIGHTRED)
        
        else
          if geo_biome.layers [index].top_height - geo_biome.layers [index].bottom_height == 0 then
            dialog.showMessage ("Error!", "A layer can be contracted only if it has levels to spare.\n",COLOR_LIGHTRED)
          
          else
            geo_biome.layers [index].bottom_height = geo_biome.layers [index].bottom_height + 1
            geo_biome.layers [index + 1].top_height = geo_biome.layers [index + 1].top_height + 1
              self.subviews.pages.subviews [1].subviews [1]:setChoices (Generate_Layer_List (geo_biome), selected)
          end
        end
      end
      
    elseif keys [keybindings.morph.key] then
      if layer_context then
        local List = {}
        
        for i, material in ipairs (df.global.world.raws.inorganics) do
          if material.flags.SEDIMENTARY or
             material.flags.IGNEOUS_INTRUSIVE or
             material.flags.IGNEOUS_EXTRUSIVE or
             material.flags.METAMORPHIC or
             material.flags.SOIL then
               table.insert (List, material.id)
            end       
        end

        guiScript.start (function ()
          local ret, idx, choice = guiScript.showListPrompt ("Choose layer material:", nil, 3, List, nil, true)
          if ret then
            for i, material in ipairs (df.global.world.raws.inorganics) do
              if material.id == List [idx].text then
                geo_biome.layers [index].mat_index = i
                if material.flags.SEDIMENTARY then
                  geo_biome.layers [index].type = df.geo_layer_type.SEDIMENTARY
                  
                elseif material.flags.IGNEOUS_INTRUSIVE then
                  geo_biome.layers [index].type = df.geo_layer_type.IGNEOUS_INTRUSIVE
                  
                elseif material.flags.IGNEOUS_EXTRUSIVE then
                  geo_biome.layers [index].type = df.geo_layer_type.IGNEOUS_EXTRUSIVE
                  
                elseif material.flags.METAMORPHIC then
                  geo_biome.layers [index].type = df.geo_layer_type.METAMORPHIC
                  
                elseif material.flags.SOIL_SAND then
                  geo_biome.layers [index].type = df.geo_layer_type.SOIL_SAND

                  elseif material.flags.SOIL then
                  geo_biome.layers [index].type = df.geo_layer_type.SOIL
                end
                
                if #geo_biome.layers [index].vein_mat > 0 then
                  for k = 0, #geo_biome.layers [index].vein_mat - 1, -1 do
                    geo_biome.layers [index].vein_mat:erase (k)
                    geo_biome.layers [index].vein_nested_in:erase (k)
                    geo_biome.layers [index].vein_type:erase (k)
                    geo_biome.layers [index].vein_unk_38:erase (k)                 
                  end
                end

                Check_Soil_Depth ()
                  self.subviews.pages.subviews [1].subviews [1]:setChoices (Generate_Layer_List (geo_biome), selected)
                break
              end
            end
            end       
        end)
      end
      
    elseif keys [keybindings.add.key] then
      if vein_context then
        local List = {}
        local Layer_Material = df.global.world.raws.inorganics [geo_biome.layers [layer_index - 1].mat_index]
        local Found
        
        for i, material in ipairs (df.global.world.raws.inorganics) do
          Found = false
          
          for k, mat in ipairs (geo_biome.layers [layer_index - 1].vein_mat) do
            if geo_biome.layers [layer_index - 1].vein_mat [k] == i then
              Found = true
              break
            end
          end
          
          if not Found then
            for k, location in ipairs (material.environment.location) do
              if (location == df.environment_type.SOIL and Layer_Material.flags.SOIL) or
                 (location == df.environment_type.SOIL_OCEAN and Layer_Material.flags.SOIL_OCEAN) or
                 (location == df.environment_type.SOIL_SAND and Layer_Material.flags.SOIL_SAND) or
                 (location == df.environment_type.METAMORPHIC and Layer_Material.flags.METAMORPHIC) or
                 (location == df.environment_type.SEDIMENTARY and Layer_Material.flags.SEDIMENTARY) or
                 (location == df.environment_type.IGNEOUS_INTRUSIVE and Layer_Material.flags.IGNEOUS_INTRUSIVE) or
                 (location == df.environment_type.IGNEOUS_EXTRUSIVE and Layer_Material.flags.IGNEOUS_EXTRUSIVE) then  -- or
                -- (location == df.environment_type.ALLUVIAL and Layer_Material.flags.ALLUVIAL) then  -- No Alluvial flag!
                Found = true
                table.insert (List, material.id)
              end
            end                     
          end
          
          if not Found then
            for k, mat_index in ipairs (material.environment_spec.mat_index) do
              if mat_index == geo_biome.layers [layer_index - 1].mat_index then
                table.insert (List, material.id)
                break
              end
            end
          end
        end
        
        guiScript.start (function ()
          local ret, idx, choice = guiScript.showListPrompt ("Choose vein/cluster material:", nil, 3, List, nil, true)
          if ret then
            for i, material in ipairs (df.global.world.raws.inorganics) do
              if material.id == List [idx].text then
                geo_biome.layers [layer_index - 1].vein_mat:insert ('#', i)
                geo_biome.layers [layer_index - 1].vein_nested_in:insert ('#', -1)
                
                Found = false
                for k, location in ipairs (material.environment.location) do
                  if (location == df.environment_type.SOIL and Layer_Material.flags.SOIL) or
                     (location == df.environment_type.SOIL_OCEAN and Layer_Material.flags.SOIL_OCEAN) or
                     (location == df.environment_type.SOIL_SAND and Layer_Material.flags.SOIL_SAND) or
                     (location == df.environment_type.METAMORPHIC and Layer_Material.flags.METAMORPHIC) or
                     (location == df.environment_type.SEDIMENTARY and Layer_Material.flags.SEDIMENTARY) or
                     (location == df.environment_type.IGNEOUS_INTRUSIVE and Layer_Material.flags.IGNEOUS_INTRUSIVE) or
                     (location == df.environment_type.IGNEOUS_EXTRUSIVE and Layer_Material.flags.IGNEOUS_EXTRUSIVE) then  -- or
                    -- (location == df.environment_type.ALLUVIAL and Layer_Material.flags.ALLUVIAL) then  -- No Alluvial flag!
                    geo_biome.layers [layer_index - 1].vein_type:insert ('#', material.environment.type [k])
                    Found = true
                    break
                  end
                end
                
                if not Found then
                  for k, mat_index in ipairs (material.environment_spec.mat_index) do
                    if mat_index == geo_biome.layers [layer_index - 1].mat_index then
                      geo_biome.layers [layer_index - 1].vein_type:insert ('#', material.environment_spec.inclusion_type [k])
                      break
                    end
                  end
                end
                
                geo_biome.layers [layer_index - 1].vein_unk_38:insert ('#', 50)  --  May want to allow editing of this in the future
                self.subviews.pages.subviews [1].subviews [1]:setChoices (Generate_Vein_List (geo_biome, layer_index - 1))
                break
              end
            end
          end
        end)
      end          
      
    elseif keys [keybindings.rem.key] then
      if vein_context then
        if #geo_biome.layers [layer_index - 1].vein_mat == 0 then
          dialog.showMessage ("Error!", "Cannot remove non existent entries.\n",COLOR_LIGHTRED)
        
        else
          local vein_nested_in_length = #geo_biome.layers [layer_index - 1].vein_nested_in - 1
          for i = 0, vein_nested_in_length do
            if geo_biome.layers [layer_index - 1].vein_nested_in [vein_nested_in_length - i] == index then
              geo_biome.layers [layer_index - 1].vein_mat:erase (vein_nested_in_length - i)
              geo_biome.layers [layer_index - 1].vein_nested_in:erase (vein_nested_in_length - i)
              geo_biome.layers [layer_index - 1].vein_type:erase (vein_nested_in_length - i)
              geo_biome.layers [layer_index - 1].vein_unk_38:erase (vein_nested_in_length - i)
            end
          end
          
          geo_biome.layers [layer_index - 1].vein_mat:erase (index)
          geo_biome.layers [layer_index - 1].vein_nested_in:erase (index)
          geo_biome.layers [layer_index - 1].vein_type:erase (index)
          geo_biome.layers [layer_index - 1].vein_unk_38:erase (index)
          
          self.subviews.pages.subviews [1].subviews [1]:setChoices (Generate_Vein_List (geo_biome, layer_index - 1))          
        end        
      end
      
    elseif keys [keybindings.nest.key] then
      if vein_context and 
         #geo_biome.layers [layer_index - 1].vein_mat ~= 0 then
        local List = {}
        local Found
        
        for i, material in ipairs (df.global.world.raws.inorganics) do
          for k, mat_index in ipairs (material.environment_spec.mat_index) do
            Found = false
            if mat_index == geo_biome.layers [layer_index - 1].vein_mat [index] then
              for l, nested_in in ipairs (geo_biome.layers [layer_index - 1].vein_nested_in) do
                if nested_in == index and
                   geo_biome.layers [layer_index - 1].vein_mat [l] == i then
                   Found = true
                   break
                end
              end              

               if not Found then
                table.insert (List, material.id)
              end
            end
          end
        end

        guiScript.start (function ()
          local ret, idx, choice = guiScript.showListPrompt ("Choose vein/cluster inclusion material:", nil, 3, List, nil, true)
          if ret then
            for i, material in ipairs (df.global.world.raws.inorganics) do
              if material.id == List [idx].text then
                geo_biome.layers [layer_index - 1].vein_mat:insert ('#', i)
                geo_biome.layers [layer_index - 1].vein_nested_in:insert ('#', index)
                
                for k, mat_index in ipairs (material.environment_spec.mat_index) do
                  if mat_index == geo_biome.layers [layer_index - 1].vein_mat [index] then                  
                    geo_biome.layers [layer_index - 1].vein_type:insert ('#', material.environment_spec.inclusion_type [k])
                    break
                  end
                end
                
                geo_biome.layers [layer_index - 1].vein_unk_38:insert ('#', 50)  --  May want to allow editing of this in the future
                self.subviews.pages.subviews [1].subviews [1]:setChoices (Generate_Vein_List (geo_biome, layer_index - 1))
                break
              end
            end
          end
        end)
       end
      
    elseif keys [keybindings.writ.key] then
      geo_biome.index = #df.global.world.world_data.geo_biomes
      df.global.world.world_data.geo_biomes:insert ('#', geo_biome)
      df.global.world.world_data.region_map [cursor_x]:_displace (cursor_y).geo_index = geo_biome.index
      self:dismiss()
    end
    
    self.super.onInput (self, keys)
  end

  --============================================================

  function show_viewer ()
    local screen = GeoManipulatorUi {}
    persist_screen = screen
    screen:show ()
  end

  show_viewer()
end

geomanipulator ()