--  Display the contents of you library
--
--[====[

librarian
================
]====]
local dont_be_silly = false  --  'true' disables the "ook" part from the description of the return from hiding key.
local ook_start_x = 10       --  x position of where the "ook" key description appears, in case the script clashes with something else.

local gui = require 'gui'
local dialog = require 'gui.dialogs'
local widgets = require 'gui.widgets'
local guiScript = require 'gui.script'
local utils = require 'utils'

--=====================================

local values = {[df.value_type.LAW] =
                {[-3] = "finds the idea of law abhorrent",
                 [-2] = "disdains the law",
                 [-1] = "does not respect the law",
                 [0] = "doesn't feel strongly about the law",
                 [1] = "respects the law",
                 [2] = "has a great deal of respect for the law",
                 [3] = "is an absolute believer in the rule of law"},    
                [df.value_type.LOYALTY] =
                {[-3] = "is disgusted by the idea of loyalty",
                 [-2] = "disdains loyalty",
                 [-1] = "views loyalty unfavorably",
                 [0] = "doesn't particularly value loyalty",
                 [1] = "values loyalty",
                 [2] = "greatly prizes loyalty",
                 [3] = "has the highest regard for loyalty"},
                [df.value_type.FAMILY] =
                {[-3] = "finds the idea of family loathsome",
                 [-2] = "lacks any respect for family",
                 [-1] = "is put off by family",
                 [0] = "does not care about family one way or the other",
                 [1] = "values family",
                 [2] = "values family greatly",
                 [3] = "sees family as one of the most important things in life"},
                [df.value_type.FRIENDSHIP] =
                {[-3] = "finds the whole idea of friendship disgusting",
                 [-2] = "is completely put off by the idea of friends",
                 [-1] = "finds friendship burdensome",
                 [0] = "does not care about friendship",
                 [1] = "thinks friendship is important",
                 [2] = "sees friendship as one of the finer things in life",
                 [3] = "believes friendship is the key to the ideal life"},
                [df.value_type.POWER] =
                {[-3] = "finds the acquisition and use of power abhorrent and would have all masters toppled",
                 [-2] = "hates those who wield power over others",
                 [-1] = "has a negative view of those who exercise power over others",
                 [0] = "doesn't find power particularly praiseworthy",
                 [1] = "respects power",
                 [2] = "sees power over others as something to strive for",
                 [3] = "believes that the acquisition of power over others is the ideal goal in life and worthy of the highest respect"},
                [df.value_type.TRUTH] =
                {[-3] = "is repelled by the idea of honesty and lies without compunction",
                 [-2] = "sees lying as an important means to an end",
                 [-1] = "finds blind honesty foolish",
                 [0] = "does not particularly value the truth",
                 [1] = "values honesty",
                 [2] = "believes that honesty is a high ideal",
                 [3] = "believes the truth is inviolable regardless of the cost"},
                [df.value_type.CUNNING] =
                {[-3] = "is utterly disgusted by guile and cunning",
                 [-2] = "holds shrewd and crafty individuals in the lowest esteem",
                 [-1] = "sees guile and cunning as indirect and somewhat worthless",
                 [0] = "does not really value cunning and guile",
                 [1] = "values cunning",
                 [2] = "greatly respects the shrewd and guileful",
                 [3] = "holds well-laid plans and shrewd deceptions in the highest regard"},
                [df.value_type.ELOQUENCE] =
                {[-3] = "sees artful speech and eloquence as a wasteful form of deliberate deception and treats it as such",
                 [-2] = "finds [him]self somewhat disgusted with eloquent speakers",
                 [-1] = "finds eloquence and artful speech off-putting",
                 [0] = "doesn't value eloquence so much",
                 [1] = "values eloquence",
                 [2] = "deeply respects eloquent speakers",
                 [3] = "believes that artful speech and eloquent expression are of the highest ideals"},
                [df.value_type.FAIRNESS] =
                {[-3] = "is disgusted by the idea of fairness and will freely cheat anybody at any time",
                 [-2] = "finds the idea of fair-dealing foolish and cheats whenever [he] finds it profitable",
                 [-1] = "sees life as unfair and doesn't mind it that way",
                 [0] = "does not care about fairness",  -- one way or the other?
                 [1] = "respects fair-dealing and fair-play",
                 [2] = "has great respect for fairness",
                 [3] = "holds fairness as one of the highest ideals and despises cheating of any kind"},
                [df.value_type.DECORUM] =
                {[-3] = "is affronted of the whole notion of maintaining decorum and finds so-called dignified people disgusting",
                 [-2] = "sees those that attempt to maintain dignified and proper behavior as vain and offensive",
                 [-1] = "finds maintaining decorum a silly, fumbling waste of time",
                 [0] = "doesn't care very much about decorum",
                 [1] = "values decorum, dignity and proper behavior",
                 [2] = "greatly respects those that observe decorum and maintain their dignity",
                 [3] = "views decorum as a high ideal and is deeply offended by those that fail to maintain it"},
                [df.value_type.TRADITION] =
                {[-3] = "is disgusted by tradition and would flout any [he] encounters if given a chance",
                 [-2] = "find the following of tradition foolish and limiting",
                 [-1] = "disregards tradition",
                 [0] = "doesn't have any strong feelings about tradition",
                 [1] = "values tradition",
                 [2] = "is a firm believer in the value of tradition",
                 [3] = "holds the maintenance of tradition as one of the highest ideals"},
                [df.value_type.ARTWORK] =
                {[-3] = "finds art offensive and would have it destroyed whenever possible",
                 [-2] = "sees the whole pursuit of art as silly",
                 [-1] = "finds artwork boring",
                 [0] = "doesn't care about art one way or another",
                 [1] = "values artwork",
                 [2] = "greatly respects artists and their work",
                 [3] = "believes that the creation and appreciation of artwork is one of the highest ideals"},
                [df.value_type.COOPERATION] =
                {[-3] = "is thoroughly disgusted by cooperation",
                 [-2] = "views cooperation as a low ideal not worthy of any respect",
                 [-1] = "dislikes cooperation",
                 [0] = "doesn't see cooperation as valuable",
                 [1] = "values cooperation",
                 [2] = "sees cooperation as very important in life",
                 [3] = "places cooperation as one of the highest ideals"},
                [df.value_type.INDEPENDENCE] =
                {[-3] = "hates freedom and would crush the independent spirit wherever it is found",
                 [-2] = "sees freedom and independence as completely worthless",
                 [-1] = "finds the idea of independence and freedom somewhat foolish",
                 [0] = "doesn't really value independence one way or another",
                 [1] = "values independence",
                 [2] = "treasures independence",
                 [3] = "believes that freedom and independence are completely non-negotiable and would fight to defend them"},
                [df.value_type.STOICISM] =
                {[-3] = "sees concealment of emotions as a betrayal and tries [his] best never to associate with such secretive fools",
                 [-2] = "feels that those who attempt to conceal their emotions are vain and foolish",
                 [-1] = "sees no value in holding back complaints and concealing emotions",
                 [0] = "doesn't see much value in being stoic",
                 [1] = "believes it is important to conceal emotions and refrain from complaining",
                 [2] = "thinks it is of the utmost importance to present a bold face and never grouse, complain, and even show emotion",
                 [3] = "views any show of emotion as offensive"},
                [df.value_type.INTROSPECTION] =
                {[-3] = "finds the whole idea of introspection completely offensive and contrary to the ideals of a life well-lived",
                 [-2] = "thinks that introspection is valueless and those that waste time in self-examination are deluded fools",
                 [-1] = "finds introspection to be a waste of time",
                 [0] = "doesn't really see the value in self-examination",
                 [1] = "sees introspection as important",
                 [2] = "deeply values introspection",
                 [3] = "feels that introspection and all forms of self-examination are the keys to a good life and worthy of respect"},
                [df.value_type.SELF_CONTROL] =
                {[-3] = "has abandoned any attempt at self-control and finds the whole concept deeply offensive",
                 [-2] = "sees the denial of impulses as a vain and foolish pursuit",
                 [-1] = "finds those that deny their impulses somewhat stiff",
                 [0] = "doesn't particularly value self-control",
                 [1] = "values self-control",
                 [2] = "finds moderation and self-control to be very important",
                 [3] = "believes that self-mastery and the denial of impulses are of the highest ideals"},
                [df.value_type.TRANQUILITY] =
                {[-3] = "is disgusted by tranquility and would that the world would constantly churn with noise and activity",
                 [-2] = "is greatly disturbed by quiet and a peaceful existence",
                 [-1] = "prefers a noisy, bustling life to boring days without activity",
                 [0] = "doesn't have a preference between tranquility and tumult",
                 [1] = "values tranquility and a peaceful day",
                 [2] = "strongly values tranquility and quiet",
                 [3] = "views tranquility as one of the highest ideals"},
                [df.value_type.HARMONY] =
                {[-3] = "believes deeply that chaos and disorder are the truest expressions of life and would disrupt harmony wherever it is found",
                 [-2] = "can't fathom why anyone would want to live in an orderly and harmonious society",
                 [-1] = "doesn't respect a society that has settled into harmony without debate and strife",
                 [0] = "sees equal parts of harmony and discord as parts of life",
                 [1] = "values a harmonious existence",
                 [2] = "strongly believes that a peaceful and ordered society without dissent is best",
                 [3] = "would have the world operate in complete harmony without the least bit of strife and disorder"},
                [df.value_type.MERRIMENT] =
                {[-3] = "is appalled by merrymaking, parties and other such worthless activities",
                 [-2] = "is disgusted by merrymakers",
                 [-1] = "sees merrymaking as a waste",
                 [0] = "doesn't really value merrymaking",
                 [1] = "finds merrymaking and parying worthwhile activities",
                 [2] = "truly values merrymaking and parties",
                 [3] = "believes that little is better in life than a good party"},
                [df.value_type.CRAFTSMANSHIP] =
                {[-3] = "views craftdwarfship with disgust and would desecrate a so-called masterwork or two if [he] could get away with it",
                 [-2] = "sees the pursuit of good craftdwarfship as a total waste",
                 [-1] = "considers craftdwarfship to be relatively worthless",
                 [0] = "doesn't particularly care about crafdwarfship",
                 [1] = "values good craftdwarfship",
                 [2] = "has a great deal of respect for worthy craftdwarfship",
                 [3] = "holds craftdwarfship to be of the highest ideals and celebrates talented artisans and their masterworks"},
                [df.value_type.MARTIAL_PROWESS] =
                {[-3] = "abhors those who pursue the mastery of weapons and skill with fighting",
                 [-2] = "thinks that the pursuit of the skills of warfare and fighting is a low pursuit indeed",
                 [-1] = "finds those that develop skills with weapons and fighting distasteful",
                 [0] = "does not really value skills related to fighting",
                 [1] = "values martial prowess",
                 [2] = "deeply respects skill at arms",
                 [3] = "believes that martial prowess defines the good character of an individual"},
                [df.value_type.SKILL] =
                {[-3] = "sees the whole idea of taking time to master a skill as appalling",
                 [-2] = "believes that the time taken to master a skill is a horrible waste",
                 [-1] = "finds the pursuit of skill mastery off-putting",
                 [0] = "doesn't care if others take the time to master skills",
                 [1] = "respects the development of skill",
                 [2] = "really respects those that take the time to master a skill",
                 [3] = "believes that the mastery of a skill is one of the highest pursuits"},
                [df.value_type.HARD_WORK] =
                {[-3] = "finds the proposition that one should work hard in life utterly abhorrent",
                 [-2] = "thinks working hard is an abject idiocy",
                 [-1] = "sees working hard as a foolish waste of time",
                 [0] = "doesn't really see the point of working hard",
                 [1] = "values hard work",
                 [2] = "deeply respects those that work hard at their labors",
                 [3] = "believes that hard work is one of the highest ideals and a key to the good life"},
                [df.value_type.SACRIFICE] =
                {[-3] = "thinks that the whole concept of sacrifice for others is truly disgusting",
                 [-2] = "finds sacrifice to be the height of folly",
                 [-1] = "sees sacrifice as wasteful and foolish",
                 [0] = "doesn't particularly respect sacrifice as a virtue",
                 [1] = "values sacrifice",
                 [2] = "believes that those who sacrifice for others should be deeply respected",
                 [3] = "sacrifice to be one of the highest ideals"},
                [df.value_type.COMPETITION] =
                {[-3] = "finds the very idea of competition obscene",
                 [-2] = "deeply dislikes competition",
                 [-1] = "sees competition as wasteful and silly",
                 [0] = "doesn't have strong views on competition",
                 [1] = "sees competition as reasonably important",
                 [2] = "views competition as a crucial driving force of the world",
                 [3] = "holds the idea of competition among the most important and would encourage it whenever possible"},
                [df.value_type.PERSEVERENCE] =
                {[-3] = "finds the notion that one would persevere through adversity completely abhorrent",
                 [-2] = "thinks there is something deeply wrong with people the persevere through adversity",
                 [-1] = "sees perseverance in the face of adversity as bull-headed and foolish",
                 [0] = "doesn't think much about the idea of perseverance",
                 [1] = "respects perseverance",
                 [2] = "greatly respects individuals that persevere through their trials and labors",
                 [3] = "believes that perseverance is one of the greatest qualities somebody can have"},
                [df.value_type.LEISURE_TIME] =
                {[-3] = "believes that those that take leisure time are evil and finds the whole idea disgusting",
                 [-2] = "is offended by leisure time and leisurely living",
                 [-1] = "finds leisure time wasteful", --  also "prefers a noisy, bustling life to boring days without activity",?
                 [0] = "doesn't think one way or the other about leisure time",
                 [1] = "values leisure time",
                 [2] = "treasures leisure time and thinks it is very important in life",
                 [3] = "believes it would be a fine thing if all time were leisure time"},
                [df.value_type.COMMERCE] =
                {[-3] = "holds the view that commerce is a vile obscenity",
                 [-2] = "finds those that engage in trade and commerce to be fairly disgusting",
                 [-1] = "is somewhat put off by trade and commerce",
                 [0] = "doesn't particularly respect commerce",
                 [1] = "respects commerce",
                 [2] = "really respects commerce and those that engage in trade",
                 [3] = "sees engaging in commerce as a high ideal in life"},
                [df.value_type.ROMANCE] =
                {[-3] = "finds even the abstract idea of romance repellent",
                 [-2] = "is somewhat disgusted by romance",
                 [-1] = "finds romance distasteful",
                 [0] = "doesn't care one way or the other about romance",
                 [1] = "values romance",
                 [2] = "thinks romance is very important in life",
                 [3] = "sees romance as one of the highest ideals"},
                [df.value_type.NATURE] =
                {[-3] = "would just as soon have nature and the great outdoors burned to ashes and converted into a great mining pit",
                 [-2] = "has a deep dislike for the natural world",
                 [-1] = "finds nature somewhat disturbing",
                 [0] = "doesn't care about nature one way or another",
                 [1] = "values nature",
                 [2] = "has a deep respect for animals, plants and the natural world",
                 [3] = "holds nature to be of greater value than most aspects of civilization"},
                [df.value_type.PEACE] =
                {[-3] = "thinks that the world should be engaged into perpetual warfare",
                 [-2] = "believes war is preferable to peace in general",
                 [-1] = "sees was as a useful means to an end",
                 [0] = "doesn't particularly care between war and peace",
                 [1] = "values peace over war",
                 [2] = "believes that peace is always preferable to war",
                 [3] = "believes that the idea of war is utterly repellent and would have peace at all costs"},
                [df.value_type.KNOWLEDGE] =
                {[-3] = "sees the attainment and preservation of knowledge as an offensive enterprise engaged in by arrogant fools",
                 [-2] = "thinks the quest for knowledge is a delusional fantasy",
                 [-1] = "finds the pursuit of knowledge to be a waste of effort",
                 [0] = "doesn't see the attainment of knowledge as important",
                 [1] = "values knowledge",
                 [2] = "views the pursuit of knowledge as deeply important",
                 [3] = "finds the quest for knowledge to be of the very highest value"}}
 
--=====================================

function Librarian ()
  if not dfhack.isMapLoaded () then
    dfhack.printerr ("Error: This script requires a Fortress Mode embark to be loaded.")
    return
  end
  
  local Focus = "Main"
  local Pre_Help_Focus = "Main"
  local Pre_Hiding_Focus = "Main"
  local Main_Page = {}
  local Hidden_Page = {}
  local Science_Page = {}
  local Values_Page = {}
  local Authors_Page = {}
  local Help_Page = {}
  local persist_screen
  local civ_id = df.global.world.world_data.active_site [0].entity_links [0].entity_id
  
  local keybindings = {
    content_type = {key = "CUSTOM_C",
                desc = "Set Content Type filter"},
    reference_filter = {key = "CUSTOM_R",
                        desc = "Toggle Reference Filter"},
    hide = {key = "CUSTOM_SHIFT_H",
            desc = "Hide the Librarian"},
    ook = {key = "CUSTOM_SHIFT_O",
           desc = "Bring the Librarian out of hiding"},
    main = {key = "CUSTOM_M",
            desc = "Shift to the Main page"},
    science = {key = "CUSTOM_S",
               desc = "Shift to the Science page"},
    values = {key = "CUSTOM_V",
              desc = "Shift to the Values page"},
    authors = {key = "CUSTOM_A",
               desc = "Shift to the Authors page"},
    left = {key = "CURSOR_LEFT",
            desc = "Rotates to the next list"},
    right = {key = "CURSOR_RIGHT",
             desc = "Rotates to the previous list"},
    help = {key = "HELP",
            desc= "Show this help/info"}}
            
  local Content_Type_Selected = 1
  local Reference_Filter = false
  local Content_Type_Map = {}
  local ook_key_string = dfhack.screen.getKeyDisplay(df.interface_key.CUSTOM_SHIFT_O)

  table.insert (Content_Type_Map, {name = "All",
                                   index = -1})
  for i = df.written_content_type._first_item, df.written_content_type._last_item do
    table.insert (Content_Type_Map, {name = df.written_content_type [i],
                                     index = i})
  end

 --============================================================

  function Sort (list)
    local temp
    
    for i, dummy in ipairs (list) do
      for k = i + 1, #list do
        if df.written_content.find (list [k] [1]).title < df.written_content.find (list [i] [1]).title then
          temp = list [i]
          list [i] = list [k]
          list [k] = temp          
        end
      end
    end
  end
  
  --============================================================

  function Sort_Remote (list)
    local temp
    
    for i, dummy in ipairs (list) do
      for k = i + 1, #list do
        if list [k] < list [i] then
          temp = list [i]
          list [i] = list [k]
          list [k] = temp          
        end
      end
    end
  end
  
  --============================================================

  function Fit (Item, Size)
    return Item .. string.rep (' ', Size - string.len (Item))
  end
   
  --============================================================

  function Fit_Right (Item, Size)
    if string.len (Item) > Size then
      return string.rep ('#', Size)
    else
      return string.rep (' ', Size - string.len (Item)) .. Item
    end
  end

  --============================================================

  function Bool_To_YN (value)
    if value then
      return 'Y'
    else
      return 'N'
    end
  end
  
  --============================================================

  function Bool_To_Yes_No (value)
    if value then
      return 'Yes'
    else
      return 'No'
    end
  end
  
  --============================================================

  function check_flag (flag, index)
    return df [flag] [index] ~= nil
  end
  
  --============================================================

  function flag_image (flag, index)
    return df [flag] [index]
  end
  
  --============================================================

  function Make_List (List)
    local Result = {}
    
    for i, element in ipairs (List) do
      table.insert (Result, element.name)
    end
     
    return Result
  end
  
  --============================================================

  function value_strengh_of (ref_level)
    local strength
    local level
    
    if ref_level < -40 then
      strength = -3
      level = "Hate"
            
    elseif ref_level < -25 then
      strength = -2
      level = "Strong dislike"
                
    elseif ref_level < -10 then
      strength = -1
      level = "Dislike"
        
    elseif ref_level <= 10 then
      strength = 0
      level = "Indifference"
          
    elseif ref_level <= 25 then
      strength = 1
      level = "Like"
          
    elseif ref_level <= 40 then
      strength = 2
      level = "Strong liking"
          
    else
      strength = 3
      level = "Love"
    end
    
    return strength, level
  end
            
  --============================================================

  function Process_Item (Result, item)
    local found
    
    if item.flags2.has_written_content then  --### flags.artifact to separate original from copy?
      for i, improvement in ipairs (item.improvements) do
        if improvement._type == df.itemimprovement_pagesst or
           improvement._type == df.itemimprovement_writingst then
          for k, content_id in ipairs (improvement.contents) do
            found = false
            
            for l, existing_content in ipairs (Result) do
              if existing_content [1] == content_id then
                found = true
                table.insert (Result [l] [2], item)
                break
              end
            end
          
            if not found then
              table.insert (Result, {content_id, {}})
              table.insert (Result [#Result] [2], item)
            end
          end
        end
      end
    end
  end
  
  --============================================================

  function Take_Stock ()
    local Result = {}
    
    for i, item in ipairs (df.global.world.items.other.BOOK) do
      Process_Item (Result, item)
    end
    
    for i, item in ipairs (df.global.world.items.other.TOOL) do
      Process_Item (Result, item)
    end
    
    Sort (Result)
    
    return Result
  end
  
  --============================================================

  function Take_Science_Stock (Stock)
    local Result = {}
    
    for i = 0, 13 do  --  No content type enum known...
      Result [i] = {}
    end
    
    for i, element in ipairs (Stock) do
      local content = df.written_content.find (element [1])
      
      for k, ref in ipairs (content.refs) do
        if content.ref_aux [k] == 0 and  --  XML comment claims non zero means ref should be ignored.
           ref._type == df.general_ref_knowledge_scholar_flagst then 
          for l, flag in ipairs (ref.knowledge.flags.flags_0) do  --  Don't care which one, as they'll iterate of all bits regardless
            if flag then
              if not Result [ref.knowledge.category] [l] then
                Result [ref.knowledge.category] [l] = {}
              end
                
              table.insert (Result [ref.knowledge.category] [l], element)
            end
          end
        end
      end
    end
    
    return Result
  end
  
  --============================================================

  function Take_Values_Stock (Stock)
    local Result = {}
    
    for i, value in ipairs (df.value_type) do
      Result [i] = {}
    end
    
    for i, element in ipairs (Stock) do
      local content = df.written_content.find (element [1])
      
      for k, ref in ipairs (content.refs) do
        if content.ref_aux [k] == 0 and  --  XML comment claims non zero means ref should be ignored.
           ref._type == df.general_ref_value_levelst then 
          local strength, level = value_strengh_of (ref.level)           

          if not Result [ref.value] [strength] then
            Result [ref.value] [strength] = {}
          end
                
          table.insert (Result [ref.value] [strength], element)
        end
      end
    end
    
    return Result
  end
  
  --============================================================

  function Take_Authors_Stock (Stock)
    local Result = {}
    
    for i, element in ipairs (Stock) do
      local content = df.written_content.find (element [1])
      local hf = df.historical_figure.find (content.author)
      
      if hf then
        local unit = df.unit.find (hf.unit_id)
         
        if unit and
           unit.civ_id == civ_id and
           not unit.flags2.visitor then
          local author = dfhack.TranslateName (hf.name, true) .. "/" .. dfhack.TranslateName (hf.name, false)
          local found = false

          for k, res in ipairs (Result) do
            if res [1] == author then
              found = true
              table.insert (Result [k] [2], element)
              break
            end
          end
          
          if not found then
            table.insert (Result, {author, {element}})
          end
        end
      end
    end
    
    local temp
    
    for i, dummy in ipairs (Result) do
      for k = i + 1, #Result do
        if Result [k] [1] < Result [i] [1] then
          temp = Result [i]
          Result [i] = Result [k]
          Result [k] = temp          
        end
      end
    end
          
    return Result
  end
  
  --============================================================

  function Take_Remote_Stock ()
    local Science_Result = {}
    local Values_Result = {}
    
    for i = 0, 13 do  --  No content type enum known...
      Science_Result [i] = {}
    end
    
    for i, value in ipairs (df.value_type) do
      Values_Result [i] = {}
    end
    
    for i, content in ipairs (df.global.world.written_contents.all) do
      for k, ref in ipairs (content.refs) do
        if content.ref_aux [k] == 0 then  --  XML comment claims non zero means ref should be ignored.
          if ref._type == df.general_ref_knowledge_scholar_flagst then 
            for l, flag in ipairs (ref.knowledge.flags.flags_0) do  --  Don't care which one, as they'll iterate of all bits regardless
              if flag then
                local found = false
              
                if Science_Page.Data_Matrix [ref.knowledge.category] [l] then
                  for m, element in ipairs (Science_Page.Data_Matrix [ref.knowledge.category] [l]) do
                    if element [1] == content.id then
                      found = true
                      break
                    end
                  end
                end
              
                if not found then
                  if not Science_Result [ref.knowledge.category] [l] then
                    Science_Result [ref.knowledge.category] [l] = {}
                  end
                
                  table.insert (Science_Result [ref.knowledge.category] [l], content)
                end
              end
            end
          
          elseif ref._type == df.general_ref_value_levelst then
            local strength, level = value_strengh_of (ref.level)
            local found = false
              
            if Values_Page.Data_Matrix [ref.value] [strength] then
              for m, element in ipairs (Values_Page.Data_Matrix [ref.value] [strength]) do
                if element [1] == content.id then
                  found = true
                  break
                end
              end
            end
              
            if not found then
              if not Values_Result [ref.value] [strength] then
                Values_Result [ref.value] [strength] = {}
              end
                
              table.insert (Values_Result [ref.value] [strength], content)
            end            
          end
        end
      end
    end

    Science_Page.Remote_Data_Matrix = Science_Result
    Values_Page.Remote_Data_Matrix = Values_Result
  end
  
  --============================================================

  function Filter_Stock (Stock, Content_Type_Selected, Reference_Filter)
    local include
    local Result = {}
    
    for i, element in ipairs (Stock) do
      local content = df.written_content.find (element [1])
      
      if Content_Type_Selected == 1 or
         content.type == Content_Type_Selected - 2 then
        include = not Reference_Filter
        
        if Reference_Filter then
          for k, ref in ipairs (content.refs) do
            if content.ref_aux [k] == 0 then  --  XML comment claims non zero means ref should be ignored.
              include = true
              break
            end
          end
        end
        
        if include then
          if content.title == "" then
            table.insert (Result, {name =" <Untitled>", element = element})
          
          else
            table.insert (Result, {name = content.title, element = element})
          end
        end
      end
    end    
    
    return Result
  end
  
  --============================================================

  function Produce_Details (index)
    if not Main_Page.Filtered_Stock [index] then
      return ""
    end
    
    local content = df.written_content.find (Main_Page.Filtered_Stock [index].element [1])
    local title = content.title
    local copies = 0
    local original = false
    
    if title == "" then
      title = "<Untitled>"
    end
    
    local text = {"Title    : " .. title .. "\n",
                  "Category : " .. df.written_content_type [content.type] .. "\n"}
                  
    
    for i, ref in ipairs (content.refs) do
      if content.ref_aux [i] == 0 then  --  XML comment claims non zero means ref should be ignored.
        if ref._type == df.general_ref_artifact or
           ref._type == df.general_ref_nemesis or
           ref._type == df.general_ref_item or
           ref._type == df.general_ref_item_type or
           ref._type == df.general_ref_coinbatch or
           ref._type == df.general_ref_mapsquare or
           ref._type == df.general_ref_entity_art_image or
           ref._type == df.general_ref_projectile or
           ref._type == df.general_ref_unit or
           ref._type == df.general_ref_building or
           ref._type == df.general_ref_entity or
           ref._type == df.general_ref_locationst or
           ref._type == df.general_ref_interactionst or
           ref._type == df.general_ref_abstract_buildingst or
           --  ref._type == df.general_ref_historical_eventst or
           ref._type == df.general_ref_spherest or
           ref._type == df.general_ref_sitest or
           ref._type == df.general_ref_subregionst or
           ref._type == df.general_ref_feature_layerst or
           ref._type == df.general_ref_historical_figurest or
           ref._type == df.general_ref_entity_popst or
           ref._type == df.general_ref_creaturest or
           --  ref._type == df.general_ref_knowledge_scholar_flagst or
           ref._type == df.general_ref_activity_eventst or
           --  ref._type == df.general_ref_value_levelst or
           ref._type == df.general_ref_languagest or
           ref._type == df.general_ref_written_contentst or
           ref._type == df.general_ref_poetic_formst or
           ref._type == df.general_ref_musical_formst or
           ref._type == df.general_ref_dance_formst then
          table.insert (text, "Reference: Unresolved " .. tostring (ref._type) .. " information\n")
        
        elseif ref._type == df.general_ref_historical_eventst then
          local event = df.history_event.find (ref.event_id)
          if event then
            if event._type == df.history_event_add_hf_hf_linkst then
              local hf = df.historical_figure.find (event.hf)
              local hf_target = df.historical_figure.find (event.hf)
              local hf_name = "<Unknown histfig>"
              local hf_target_name = "<Unknown histfig>"
              
              if hf then
               hf_name = dfhack.TranslateName (hf.name, true)
              end
              
              if hf_target then
                hf_target_name = dfhack.TranslateName (hf_target.name, true)
              end
              
              table.insert (text, "Reference: " .. hf_name .. " " .. df.histfig_hf_link_type [event.type] .. " vs " .. hf_target_name .. "\n")
              
            else
              table.insert (text, "Reference: Unsupported " .. tostring (event._type) .. " historical event information\n")
            end
            
          else
            table.insert (text, "Reference: Unknown historical event information\n")
          end
          
        elseif ref._type == df.general_ref_knowledge_scholar_flagst then
          for k, flag in ipairs (ref.knowledge.flags.flags_0) do  --  Iterates over all 32 bits regardless of enum value existence, so which "enum" we use doesn't matter
            if flag then
              table.insert (text, "Reference: " .. flag_image ("knowledge_scholar_flags_" .. tostring (ref.knowledge.category), k) .. " knowledge\n")
            end
          end
        
        elseif ref._type == df.general_ref_value_levelst then
          local strength, level = value_strengh_of (ref.level)
          
          table.insert (text, 'Reference: Moves values towards "' .. values [ref.value] [strength] .. '" = ' .. level .. "\n")
        
        else
          table.insert (text, "Reference: *UNKNOWN TYPE* " .. tostring (ref._type) .. " information\n")
        end
      end
    end
    
    for i, element in ipairs (Main_Page.Filtered_Stock [index].element [2]) do
      if element.flags.artifact then
        original = true
        
      else
        copies = copies + 1
      end
    end
    
    table.insert (text, "Original : " .. tostring (Bool_To_Yes_No (original) .. "\n"))
    table.insert (text, "Copies   : " .. tostring (copies) .. "\n")
    
    local hf = df.historical_figure.find (content.author)
    local author = "<Unknown>"
    local Local = false
    
    if hf then
      author = dfhack.TranslateName (hf.name, true) .. "/" .. dfhack.TranslateName (hf.name, false)
      local unit = df.unit.find (hf.unit_id)
      
      if unit and
         unit.civ_id == civ_id and
         not unit.flags2.visitor then
        Local = true
      end
    end
    
    table.insert (text, "Author   : " .. author .. "\n")
    table.insert (text, "Local    : " .. tostring (Bool_To_Yes_No (Local) .. "\n"))

    return text
  end
  
  --============================================================

  function Science_Character_Of (Stock, category, index)
    if Stock [category] [index] == nil then
      return "?"
    
    else
      return "!"
    end
  end
  
  --============================================================

  function Science_Color_Of (Stock, category, index)
    if Stock [category] [index] == nil then
      return COLOR_LIGHTRED
    
    else
      return COLOR_GREEN
    end
  end
  
  --============================================================

  function Populate_Own_Remote_Science ()
    if not Science_Page.Category_List then
      return  --  Initiation. The list hasn't been defined yet.
    end
    
    local Own_List = {}
    local Remote_List = {}
    
    if Science_Page.Data_Matrix [Science_Page.Category_List.selected - 1] [Science_Page.Topic_List.selected - 1] then
      for i, element in ipairs (Science_Page.Data_Matrix [Science_Page.Category_List.selected - 1] [Science_Page.Topic_List.selected - 1]) do
        local content = df.written_content.find (element [1])
        local title = content.title
    
        if title == "" then
          title = "<Untitled>"
        end
      
        table.insert (Own_List, title)    
      end
    end
    
    Science_Page.Own_List:setChoices (Own_List, 1)

    if Science_Page.Remote_Data_Matrix [Science_Page.Category_List.selected - 1] [Science_Page.Topic_List.selected - 1] then
      for i, element in ipairs (Science_Page.Remote_Data_Matrix [Science_Page.Category_List.selected - 1] [Science_Page.Topic_List.selected - 1]) do
        local title = element.title
    
        if title == "" then
          title = "<Untitled>"
        end
      
        table.insert (Remote_List, title)
      end
    end
    
    Sort_Remote (Remote_List)
    Science_Page.Remote_List:setChoices (Remote_List, 1)
  end
  
  --============================================================

  function Populate_Own_Remote_Values ()
    if not Values_Page.Strength_List then
      return  --  Initiation. The list hasn't been defined yet.
    end
    
    local Own_List = {}
    local Remote_List = {}
    
    if Values_Page.Data_Matrix [Values_Page.Values_List.selected - 1] [Values_Page.Strength_List.selected - 4] then
      for i, element in ipairs (Values_Page.Data_Matrix [Values_Page.Values_List.selected - 1] [Values_Page.Strength_List.selected - 4]) do
        local content = df.written_content.find (element [1])
        local title = content.title
    
        if title == "" then
          title = "<Untitled>"
        end
      
        table.insert (Own_List, title)    
      end
    end
    
    Values_Page.Own_List:setChoices (Own_List)

    if Values_Page.Remote_Data_Matrix [Values_Page.Values_List.selected - 1] [Values_Page.Strength_List.selected - 4] then
      for i, element in ipairs (Values_Page.Remote_Data_Matrix [Values_Page.Values_List.selected - 1] [Values_Page.Strength_List.selected - 4]) do
        local title = element.title
    
        if title == "" then
          title = "<Untitled>"
        end
      
        table.insert (Remote_List, title)
      end
    end
    
    Sort_Remote (Remote_List)
    Values_Page.Remote_List:setChoices (Remote_List, 1)
  end
  
  --============================================================

  function Populate_Author_Works ()
    local selected = 1
    
    if Authors_Page.Authors_List then
      selected = Authors_Page.Authors_List.selected
    end
    
    local list = {}
    
    for i, element in ipairs (Authors_Page.Authors [selected] [2]) do
      local content = df.written_content.find (element [1])
      local title = content.title
    
      if title == "" then
        title = "<Untitled>"
      end
      
      table.insert (list, title)    
    end
    
    Sort_Remote (list)

    Authors_Page.Works_List:setChoices (list, 1)
  end
  
  --============================================================

  Ui = defclass (Ui, gui.FramedScreen)
  Ui.ATTRS = {
    frame_style = gui.GREY_LINE_FRAME,
    frame_title = "The Librarian",
    transparent = false
  }

  --============================================================
 
  function Ui:onRenderFrame (dc, rect)
    local x1, y1, x2, y2 = rect.x1, rect.y1, rect.x2, rect.y2

    if self.transparent then
      self:renderParent ()
      dfhack.screen.paintString (COLOR_LIGHTRED, ook_start_x, y2, ook_key_string)
      
      if dont_be_silly then
        dfhack.screen.paintString (COLOR_WHITE, ook_start_x + ook_key_string:len (), y2, ": Return to The Librarian")
      else
        dfhack.screen.paintString (COLOR_WHITE, ook_start_x + ook_key_string:len (), y2, ": Ook! Return to The Librarian")
      end
  
    else
      if rect.wgap <= 0 and rect.hgap <= 0 then
        dc:clear ()
      else
        self:renderParent ()
        dc:fill (rect, self.frame_background)
      end

      gui.paint_frame (x1, y1, x2, y2, self.frame_style, self.frame_title)
    end
  end
  
  --============================================================

  function Ui:onResize (w, h)
    self:updateLayout (gui.ViewRect {rect = gui.mkdims_wh (0, 0 , w, h)})
  end
  
  --============================================================

  function Ui:onHelp ()
    self.subviews.pages:setSelected (6)
    Pre_Help_Focus = Focus
    Focus = "Help"
  end

  --============================================================

  function Helptext_Main ()
    local helptext =
      {"Help/Info", NEWLINE,
       "The Librarian provides a few views on the literary works in your stock.", NEWLINE,
       "The Main page defaults to listing everything, but also provides a couple of means to reduce the number by", NEWLINE,
       "restricting the list to a Category and/or works that have any kind of reference. In addition to the list,", NEWLINE,
       "the page also provides some basic data on the currently selected work.", NEWLINE,
       "It should be noted that the only kind of references really supported by the script is scientific knowledge", NEWLINE,
       "and works that change values in the reader, while other kinds are just indicated.", NEWLINE,
       "In addition to the Main page, The Librarian also has Science pagem a Values page, and an Author's.", NEWLINE,
       "  The Science page provides an indicator matrix showing the science topics you have and do not have works", NEWLINE,
       "on, as well as a breakdown of which works you have on each topic, plus the ones existing in the world", NEWLINE,
       "outside of the fortress (the author does not know if everything is available for recovery through raids,", NEWLINE,
       "or if the rumors only provide access to some works).", NEWLINE,
       "  The Values page is similar to the Science page, and indicates the value changing properites of the works", NEWLINE,
       "available locally, as well as breakdowns on each value/strength combination. Like the Science page, there", NEWLINE,
       "is one list for works present locally and one for works out in the world at large.", NEWLINE,
       "  The Author's page lists the citizens who are also authors, and the works the currently selected author", NEWLINE,
       "has produced and which are available in the fortress.", NEWLINE,
       "  You move between lists on the Science and Values page using the left/right cursor keys.", NEWLINE,
       "The final functionality allows you to Hide The Librarian, providing access to the DF interface. The only", NEWLINE,
       "indication that The Librarian sits (passively) in the background is the addition of a return key at the", NEWLINE,
       "bottom of the DF frame. The only thing you're prevented from doing is escaping out from DF to the Save", NEWLINE,
       "menu: you have to return to The Librarian to exit it first, but escaping out of DF submodes work as normal.", NEWLINE, NEWLINE,
       "Version 0.2 2018-04-10", NEWLINE,
       "Comments:", NEWLINE,
       "- The term 'work' is used above for a reason. A 'work' is a unique piece of written information. Currently", NEWLINE,
       "  it seems DF is restricted to a single 'work' per book/codex/scroll/quire, but the data structures allow", NEWLINE,
       "  for compilations of multiple 'works' in a single volume, and there's nothing saying one volume could not", NEWLINE,
       "  have a different set than another one.", NEWLINE,
       "- Similar to the previous point, a single 'work' can technically contain references to multiple topics, and", NEWLINE,
       "  a scientific information reference can technically contain data on multiple topics within the same", NEWLINE,
       "  science category. Neither of these have been seen by the author, however.", NEWLINE,
       "- The reason the Author's page doesn't list all the works of the authors is that the author of this script", NEWLINE,
       "  hasn't been able to find it listed somewhere, and scouring the total list of works is expected to take too", NEWLINE,
       "  much time in worlds with many works", NEWLINE,
       "- Why is the default key to return to The Librarian from DF selected to be 'O'? Well, 'l' and 'L' are in use", NEWLINE,
       "  by DF, so the author decided to toss in a (obscure?) reference to The Librarian...", NEWLINE,
       "Caveats:", NEWLINE,
       "- The testing has been limited. While the logic *should* reload data once returning to a hidden Librarian,", NEWLINE,
       "  the author has not been in a position to test that it actually picks up changes."
       }
               
   return helptext
  end
  
  --============================================================

  function Ui:init ()
    self.stack = {}
    self.item_count = 0
    self.keys = {}
    
    local screen_width, screen_height = dfhack.screen.getWindowSize ()
    local ook = " Ook!"
    
    if dont_be_silly then
      ook = ""
    end
    
    Main_Page.Background = 
      widgets.Label {text = {{text = "Help/Info",
                                      key = keybindings.help.key,
                                      key_sep = '()'},
                             {text = "      Works total:        Works listed:"},NEWLINE,
                             {text = "",
                                     key = keybindings.science.key,
                                     key_sep = '()'},
                             {text = " Science Page ",
                              pen = COLOR_LIGHTBLUE},
                             {text = "",
                                     key = keybindings.values.key,
                                     key_sep = '()'},
                             {text = " Values Page ",
                              pen = COLOR_LIGHTBLUE}, 
                             {text = "",
                                     key = keybindings.authors.key,
                                     key_sep = '()'},
                             {text = " Authors Page ",
                              pen = COLOR_LIGHTBLUE}, 
                             {text = "",
                                     key = keybindings.hide.key,
                                     key_sep = '()'},
                             {text = " Hide The Librarian. Return from DF with",
                              pen = COLOR_LIGHTBLUE},                               
                             {text = "",
                                     key = keybindings.ook.key,
                                     key_sep = '()'},
                             {text = ook,
                              pen = COLOR_LIGHTBLUE}, NEWLINE,                            
                             {text = "",
                                     key = keybindings.content_type.key,
                                     key_sep = '()'},
                             {text = " Content Type:                                 ",
                              pen = COLOR_LIGHTBLUE},
                              {text = "",
                                     key = keybindings.reference_filter.key,
                                     key_sep = '()'},
                             {text = " Filter works without references:",
                              pen = COLOR_LIGHTBLUE}},
                     frame = {l = 0, t = 1, y_align = 0}}
    
    Main_Page.Works_Total =
      widgets.Label {text = "0",
                     frame = {l = 33, t = 1, y_align = 0},
                     text_pen = COLOR_WHITE}
                     
    Main_Page.Works_Listed =
      widgets.Label {text = "0",
                     frame = {l = 53, t = 1, y_align = 0},
                     text_pen = COLOR_WHITE}
    
    Main_Page.Content_Type =
      widgets.Label {text = Content_Type_Map [Content_Type_Selected].name,
                     frame = {l = 19, t = 3, y_align = 0},
                     text_pen = COLOR_YELLOW}
      
    Main_Page.Reference_Filter =
      widgets.Label {text = Bool_To_YN (Reference_Filter),
                     frame = {l = 89, w = 1, t = 3, y_align = 0},
                     text_pen = COLOR_YELLOW}
      
    Main_Page.Stock = Take_Stock ()
    Main_Page.Filtered_Stock = Filter_Stock (Main_Page.Stock, Content_Type_Selected, Reference_Filter)
    
    Main_Page.Details =
      widgets.Label {text = Produce_Details (1),
                     frame = {l = 54, t = 6, h = 20, y_align = 0},
                     auto_height = false,
                     text_pen = COLOR_WHITE}
    Main_Page.List =
      widgets.List {view_id = "Selected Written Contents",
                    choices = Make_List (Main_Page.Filtered_Stock),
                    frame = {l = 1, w = 53, t = 6, yalign = 0},
                    text_pen = COLOR_DARKGREY,
                    cursor_pen = COLOR_YELLOW,
                    inactive_pen = COLOR_GREY,
                    on_select = self:callback ("show_details")}
    
    Main_Page.Works_Total:setText (tostring (#Main_Page.Stock))
    Main_Page.Works_Listed:setText (tostring (#Main_Page.List.choices))
        
    local mainPage = widgets.Panel {
      subviews = {Main_Page.Background,
                  Main_Page.Works_Total,
                  Main_Page.Works_Listed,
                  Main_Page.Content_Type,
                  Main_Page.Reference_Filter,
                  Main_Page.List,
                  Main_Page.Details}}
                
    local hiddenPage = widgets.Panel {
      subviews = {}}
           
    local sciencePage = widgets.Panel {
      subviews = {}}
           
    Science_Page.Background =
      widgets.Label {text = {{text = "Help/Info",
                                      key = keybindings.help.key,
                                      key_sep = '()'},NEWLINE,
                             {text = "",
                                     key = keybindings.main.key,
                                     key_sep = '()'},
                             {text = " Main Page",
                              pen = COLOR_LIGHTBLUE},
                              {text = "",
                                     key = keybindings.values.key,
                                     key_sep = '()'},
                             {text = " Values Page",
                              pen = COLOR_LIGHTBLUE}, 
                             {text = "",
                                     key = keybindings.authors.key,
                                     key_sep = '()'},
                             {text = " Authors Page ",
                              pen = COLOR_LIGHTBLUE}, 
                             {text = "",
                                     key = keybindings.hide.key,
                                     key_sep = '()'},
                             {text = " Hide The Librarian. Return from DF with",
                              pen = COLOR_LIGHTBLUE},                               
                             {text = "",
                                     key = keybindings.ook.key,
                                     key_sep = '()'},
                             {text = ook,
                              pen = COLOR_LIGHTBLUE}},
                     frame = {l = 0, t = 1, y_align = 0}}
    
    table.insert (sciencePage.subviews, Science_Page.Background)
    
    Science_Page.Matrix = {}
    Science_Page.Data_Matrix = Take_Science_Stock (Main_Page.Stock)
    Science_Page.Remote_Data_Matrix = {}
    
    Values_Page.Matrix = {}
    Values_Page.Data_Matrix = Take_Values_Stock (Main_Page.Stock)
    Values_Page.Remote_Data_Matrix = {}
    
    Take_Remote_Stock ()
    
    for i = 0, 13 do  --  Haven't found an enum over the knowledge category range...
      Science_Page.Matrix [i] = {}
      
      for k = df.knowledge_scholar_flags_0._first_item, df.knowledge_scholar_flags_0._last_item do  --  Full bit range, rather than used bit range, but same for all...
        if check_flag ("knowledge_scholar_flags_" .. tostring (i), k) then
          Science_Page.Matrix [i] [k] =
            widgets.Label {text = Science_Character_Of (Science_Page.Data_Matrix, i, k),
                           frame = {l = 1 + k * 2, w = 1, t = 6 + i, y_align = 0},
                           text_pen = Science_Color_Of (Science_Page.Data_Matrix, i, k)}
          table.insert (sciencePage.subviews, Science_Page.Matrix [i] [k])
        end
      end
    end    
    
    Science_Page.Background_2 =
      widgets.Label {text = "Category  Scientific Topic                                                        Local Knowledge",
                     frame = {l = 0, t = 21, y_align = 0}}
                     
    table.insert (sciencePage.subviews, Science_Page.Background_2)

    Science_Page.Background_3 =
      widgets.Label {text = "Remote Knowledge",
                     frame = {l = 82, t = 38, y_align = 0}}
                     
    table.insert (sciencePage.subviews, Science_Page.Background_3)
    
    local category_list = {}
    for i = 0, 13 do
      table.insert (category_list, tostring (i))
    end
    
    Science_Page.Topic_List =
      widgets.List {view_id = "Topic",
                    choices = category_list,  --  Placeholder
                    frame = {l = 10, t = 23, yalign = 0},
                    text_pen = COLOR_DARKGREY,
                    cursor_pen = COLOR_YELLOW,
                    inactive_pen = COLOR_GREY,
                    active = false,
                    on_select = self:callback ("show_science_titles")}
    
    Science_Page.Category_List =
      widgets.List {view_id = "Category",
                    choices = category_list,
                    frame = {l = 4, w = 2, t = 23, yalign = 0},
                    text_pen = COLOR_DARKGREY,
                    cursor_pen = COLOR_YELLOW,
                    inactive_pen = COLOR_GREY,
                    on_select = self:callback ("show_science_topic")}

    Science_Page.Own_List =
      widgets.List {view_id = "Own",
                    choices = category_list,  --  Placeholder
                    frame = {l = 82, t = 23, h = 15, yalign = 0},
                    text_pen = COLOR_DARKGREY,
                    cursor_pen = COLOR_YELLOW,
                    inactive_pen = COLOR_GREY,
                    active = false}--,
--                    on_select = self:callback ("show_science_topic")}

    Science_Page.Remote_List =
      widgets.List {view_id = "Remote",
                    choices = category_list,  --  Placeholder
                    frame = {l = 82, t = 40, h = 15, yalign = 0},
                    text_pen = COLOR_DARKGREY,
                    cursor_pen = COLOR_YELLOW,
                    inactive_pen = COLOR_GREY,
                    active = false}--,
--                    on_select = self:callback ("show_science_topic")}

    table.insert (sciencePage.subviews, Science_Page.Category_List)
    table.insert (sciencePage.subviews, Science_Page.Topic_List)
    table.insert (sciencePage.subviews, Science_Page.Own_List)
    table.insert (sciencePage.subviews, Science_Page.Remote_List)
    
    Science_Page.Active_List = {}
    
    table.insert (Science_Page.Active_List, Science_Page.Category_List)
    table.insert (Science_Page.Active_List, Science_Page.Topic_List)
    table.insert (Science_Page.Active_List, Science_Page.Own_List)
    table.insert (Science_Page.Active_List, Science_Page.Remote_List)
    
    local valuesPage = widgets.Panel {
      subviews = {}}
      
    Values_Page.Background =    
      widgets.Label {text = {{text = "Help/Info",
                                      key = keybindings.help.key,
                                      key_sep = '()'},NEWLINE,
                             {text = "",
                                     key = keybindings.main.key,
                                     key_sep = '()'},
                             {text = " Main Page",
                              pen = COLOR_LIGHTBLUE},
                              {text = "",
                                     key = keybindings.science.key,
                                     key_sep = '()'},
                             {text = " Science Page",
                              pen = COLOR_LIGHTBLUE}, 
                             {text = "",
                                     key = keybindings.authors.key,
                                     key_sep = '()'},
                             {text = " Authors Page ",
                              pen = COLOR_LIGHTBLUE}, 
                             {text = "",
                                     key = keybindings.hide.key,
                                     key_sep = '()'},
                             {text = " Hide The Librarian. Return from DF with",
                              pen = COLOR_LIGHTBLUE},                               
                             {text = "",
                                     key = keybindings.ook.key,
                                     key_sep = '()'},
                             {text = ook,
                              pen = COLOR_LIGHTBLUE}, NEWLINE, NEWLINE,
                             {text = "Value           "},
                             {text = "3 2 1 ",
                              pen = COLOR_LIGHTRED},
                             {text = "0 ",
                              pen = COLOR_YELLOW},
                             {text = "1 2 3",
                              pen = COLOR_GREEN},
                             {text = "  Strength        Own"}},
                     frame = {l = 0, t = 1, y_align = 0}}
    
    table.insert (valuesPage.subviews, Values_Page.Background)
    
    Values_Page.Background_2 =
      widgets.Label {text = "Remote",
                     frame = {l = 47, t = 21, y_align = 0}}
                     
    table.insert (valuesPage.subviews, Values_Page.Background_2)
    
    local values_background = {}
    
    for i, value in ipairs (df.value_type) do    
      Values_Page.Matrix [i] = {}
      table.insert (values_background, df.value_type [i])
      
      for k = -3, 3 do
        Values_Page.Matrix [i] [k] =
          widgets.Label {text = Science_Character_Of (Values_Page.Data_Matrix, i, k),
                         frame = {l = 22 + k * 2, w = 1, t = 6 + i, y_align = 0},
                         text_pen = Science_Color_Of (Values_Page.Data_Matrix, i, k)}
        table.insert (valuesPage.subviews, Values_Page.Matrix [i] [k])
      end
    end
    
    Values_Page.Values_List =
      widgets.List {view_id = "Values",
                    choices = values_background,
                    frame = {l = 0, t = 6, yalign = 0},
                    text_pen = COLOR_DARKGREY,
                    cursor_pen = COLOR_YELLOW,
                    inactive_pen = COLOR_GREY,
                    on_select = self:callback ("show_values")}

    table.insert (valuesPage.subviews, Values_Page.Values_List)
    
    local values_strengths =
      {"Hate",
       "Strong Dislike",
       "Dislike",
       "Indifference",
       "Like",
       "Strong Liking",
       "Love"}

    Values_Page.Strength_List =
      widgets.List {view_id = "Strengths",
                    choices = values_strengths,
                    frame = {l = 31, t = 6, yalign = 0},
                    text_pen = COLOR_DARKGREY,
                    cursor_pen = COLOR_YELLOW,
                    inactive_pen = COLOR_GREY,
                    on_select = self:callback ("show_values"),
                    active = false}
    
    table.insert (valuesPage.subviews, Values_Page.Strength_List)
    
    Values_Page.Own_List =
      widgets.List {view_id = "Own",
                    choices = category_list,  --  Placeholder
                    frame = {l = 47, t = 6, h = 15, yalign = 0},
                    text_pen = COLOR_DARKGREY,
                    cursor_pen = COLOR_YELLOW,
                    inactive_pen = COLOR_GREY,
                    active = false}--,
--                    on_select = self:callback ("show_science_topic")}

    table.insert (valuesPage.subviews, Values_Page.Own_List)
    
    Values_Page.Remote_List =
      widgets.List {view_id = "Remote",
                    choices = category_list,  --  Placeholder
                    frame = {l = 47, t = 23, h = 15, yalign = 0},
                    text_pen = COLOR_DARKGREY,
                    cursor_pen = COLOR_YELLOW,
                    inactive_pen = COLOR_GREY,
                    active = false}--,
--                    on_select = self:callback ("show_science_topic")}

    table.insert (valuesPage.subviews, Values_Page.Remote_List)

    Values_Page.Active_List = {}
    
    table.insert (Values_Page.Active_List, Values_Page.Values_List)
    table.insert (Values_Page.Active_List, Values_Page.Strength_List)
    table.insert (Values_Page.Active_List, Values_Page.Own_List)
    table.insert (Values_Page.Active_List, Values_Page.Remote_List)
    
    local authorsPage = widgets.Panel {
      subviews = {}}
      
    Authors_Page.Background =
      widgets.Label {text = {{text = "Help/Info",
                                      key = keybindings.help.key,
                                      key_sep = '()'},NEWLINE,
                             {text = "",
                                     key = keybindings.main.key,
                                     key_sep = '()'},
                             {text = " Main Page",
                              pen = COLOR_LIGHTBLUE},
                              {text = "",
                                     key = keybindings.science.key,
                                     key_sep = '()'},
                             {text = " Science Page",
                              pen = COLOR_LIGHTBLUE}, 
                             {text = "",
                                     key = keybindings.values.key,
                                     key_sep = '()'},
                             {text = " Values Page ",
                              pen = COLOR_LIGHTBLUE}, 
                             {text = "",
                                     key = keybindings.hide.key,
                                     key_sep = '()'},
                             {text = " Hide The Librarian. Return from DF with",
                              pen = COLOR_LIGHTBLUE},                               
                             {text = "",
                                     key = keybindings.ook.key,
                                     key_sep = '()'},
                             {text = ook,
                              pen = COLOR_LIGHTBLUE}, NEWLINE, NEWLINE,
                             {text = "Authors"}},
                     frame = {l = 0, t = 1, y_align = 0}}
    
    table.insert (authorsPage.subviews, Authors_Page.Background)
    
    Authors_Page.Authors = Take_Authors_Stock (Main_Page.Stock)
    
    local authors_list = {}
    
    for i, element in ipairs (Authors_Page.Authors) do
      table.insert (authors_list, element [1])
    end
    
    Authors_Page.Works_List =
      widgets.List {view_id = "Works",
                    choices = {},
                    frame = {l = 1, t = 24, h = 15, yalign = 0},
                    text_pen = COLOR_DARKGREY,
                    cursor_pen = COLOR_YELLOW,
                    inactive_pen = COLOR_GREY,
                    active = false}--,
--                    on_select = self:callback ("show_authors_titles")}
    
    table.insert (authorsPage.subviews, Authors_Page.Works_List)
    
    Authors_Page.Authors_List =
      widgets.List {view_id = "Authors",
                    choices = authors_list,
                    frame = {l = 1, t = 6, h = 15, yalign = 0},
                    text_pen = COLOR_DARKGREY,
                    cursor_pen = COLOR_YELLOW,
                    inactive_pen = COLOR_GREY,
                    active = true,
                    on_select = self:callback ("show_authors_titles")}
    
    table.insert (authorsPage.subviews, Authors_Page.Authors_List)
    
    Authors_Page.Background_2 =
      widgets.Label {text = {{text = " Works"}},
                     frame = {l = 0, t = 22, y_align = 0}}
    
    table.insert (authorsPage.subviews, Authors_Page.Background_2)
    
    Authors_Page.Active_List = {}
    
    table.insert (Authors_Page.Active_List, Authors_Page.Authors_List)
    table.insert (Authors_Page.Active_List, Authors_Page.Works_List)

    Help_Page.Main = 
      widgets.Label
        {text = Helptext_Main (),
         frame = {l = 1, t = 1, yalign = 0},
         visible = true}
    
    helpPage = widgets.Panel
      {subviews = {Help_Page.Main}}
                   
    local pages = widgets.Pages 
      {subviews = {mainPage,
                   hiddenPage,
                   sciencePage,
                   valuesPage,
                   authorsPage,
                   helpPage},view_id = "pages",
                   }

    pages:setSelected (1)
    Focus = "Main"
      
    self:addviews {pages}
  end

  --==============================================================

  function Ui:show_details (index, choice)
    Main_Page.Details:setText (Produce_Details (index))
  end
  
  --==============================================================

  function Ui:show_science_topic (index, choice)
    local list = {}

    for i = df.knowledge_scholar_flags_0._first_item, df.knowledge_scholar_flags_0._last_item do  --  Don't care about the actual flag. Will iterate over all "bits" anyway.
      if check_flag ("knowledge_scholar_flags_" .. tostring (index - 1), i) then
        table.insert (list, flag_image ("knowledge_scholar_flags_" .. tostring (index - 1), i))
      end
    end
   
    Science_Page.Topic_List:setChoices (list, 1)
    
    Populate_Own_Remote_Science ()
  end
  
  --==============================================================

  function Ui:show_science_titles (index, choice)
    Populate_Own_Remote_Science ()
  end
  
  --==============================================================

  function Ui:show_authors_titles (index, choice)
    Populate_Author_Works ()
  end
  
  --==============================================================

  function Ui:on_select_content_type (index, choice)
    Content_Type_Selected = index
    Main_Page.Content_Type:setText (Content_Type_Map [Content_Type_Selected].name)
    Main_Page.Filtered_Stock = Filter_Stock (Main_Page.Stock, Content_Type_Selected, Reference_Filter)
    Main_Page.List:setChoices (Make_List (Main_Page.Filtered_Stock))
    Main_Page.Works_Listed:setText (tostring (#Main_Page.List.choices))
  end
  
  --==============================================================

  function Ui:show_values (index, choice)
    Populate_Own_Remote_Values ()
  end
  
  --==============================================================

  function Ui:onInput (keys)
    if keys.LEAVESCREEN_ALL then
        self:dismiss ()
    end
    
    if keys.LEAVESCREEN then
      if Focus == "Hidden" then
        persist_screen:sendInputToParent (keys)
      
      elseif Focus == "Help" then
        if Pre_Help_Focus == "Main" then
          self.subviews.pages:setSelected (1)
                
        elseif Pre_Help_Focus == "Science" then
          self.subviews.pages:setSelected (3)
          
        elseif Pre_Help_Focus == "Values" then
          self.subviews.pages:setSelected (4)
          
        elseif Pre_Help_Focus == "Authors" then
          self.subviews.pages:setSelected (5)
        end
        
        Focus = Pre_Help_Focus
        
      else  --###  Should add confirmation
        self:dismiss ()
      end
    end

    if keys [keybindings.content_type.key] and
       Focus == "Main" then
      dialog.showListPrompt ("Select Content Type filter",
                             "Filter the title list to show only the ones in the\n" ..
                              "specified Content Type category.", --### Add display of current selection
                              COLOR_WHITE,
                              Make_List (Content_Type_Map),
                              self:callback ("on_select_content_type"))
                              
    elseif keys [keybindings.reference_filter.key] and Focus == "Main" then
      Reference_Filter = not Reference_Filter
      Main_Page.Reference_Filter:setText (Bool_To_YN (Reference_Filter))
      Main_Page.Filtered_Stock = Filter_Stock (Main_Page.Stock, Content_Type_Selected, Reference_Filter)
      Main_Page.List:setChoices (Make_List (Main_Page.Filtered_Stock))
      Main_Page.Works_Listed:setText (tostring (#Main_Page.List.choices))
      
    elseif keys [keybindings.hide.key] and 
           (Focus == "Main" or
            Focus == "Science" or
            Focus == "Values" or
            Focus == "Authors") then
      Pre_Hiding_Focus = Focus
      Focus = "Hidden"
      self.subviews.pages:setSelected (2)
      self.transparent = true
      
    elseif keys [keybindings.ook.key] and Focus == "Hidden" then
      if Pre_Hiding_Focus == "Main" then
        self.subviews.pages:setSelected (1)
        
      elseif Pre_Hiding_Focus == "Science" then
        self.subviews.pages:setSelected (3)
      
      elseif Pre_Hiding_Focus == "Values" then
        self.subviews.pages:setSelected (4)
      
      elseif Pre_Hiding_Focus == "Authors" then
        self.subviews.pages:setSelected (5)
      end
      
      Focus = Pre_Hiding_Focus
      self.transparent = false
      Main_Page.Stock = Take_Stock ()
      Main_Page.Filtered_Stock = Filter_Stock (Main_Page.Stock, Content_Type_Selected, Reference_Filter)
      Main_Page.List:setChoices (Make_List (Main_Page.Filtered_Stock))
      Main_Page.Works_Total:setText (tostring (#Main_Page.List.choices))
      Main_Page.Works_Listed:setText (tostring (#Main_Page.List.choices))
      
      Science_Page.Data_Matrix = Take_Science_Stock (Main_Page.Stock)
    
      for i = 0, 13 do  --  Haven't found an enum over the knowledge category range...      
        for k = df.knowledge_scholar_flags_0._first_item, df.knowledge_scholar_flags_0._last_item do  --  Full bit range, rather than used bit range, but same for all...
          if check_flag ("knowledge_scholar_flags_" .. tostring (i), k) then
            Science_Page.Matrix [i] [k]:setText (Science_Character_Of (Science_Page.Data_Matrix, i, k))
            Science_Page.Matrix [i] [k].text_pen = Science_Color_Of (Science_Page.Data_Matrix, i, k)
          end
        end
      end    
      
      Take_Remote_Stock ()
      
      Values_Page.Data_Matrix = Take_Values_Stock (Main_Page.Stock)
      Populate_Own_Remote_Science ()
      Authors_Page.Authors = Take_Authors_Stock (Main_Page.Stock)
    
      local authors_list = {}
    
      for i, element in ipairs (Authors_Page.Authors) do
        table.insert (authors_list, element [1])
      end
      
      Authors_Page.Authors_List:setChoices (authors_list, 1)
      Populate_Author_Works ()
    
    elseif keys [keybindings.main.key] and 
           (Focus == "Science" or
            Focus == "Values" or
            Focus == "Authors") then
      Focus = "Main"
      self.subviews.pages:setSelected (1)
            
    elseif keys [keybindings.science.key] and 
           (Focus == "Main" or
            Focus == "Values" or
            Focus == "Authors") then
      Focus = "Science"
      Populate_Own_Remote_Science ()
      self.subviews.pages:setSelected (3)
            
    elseif keys [keybindings.values.key] and 
           (Focus == "Main" or
            Focus == "Science" or
            Focus == "Authors") then
      Focus = "Values"
      Populate_Own_Remote_Values ()
      self.subviews.pages:setSelected (4)
            
    elseif keys [keybindings.authors.key] and 
           (Focus == "Main" or
            Focus == "Science" or
            Focus == "Values") then
      Focus = "Authors"
      self.subviews.pages:setSelected (5)
            
    elseif keys [keybindings.left.key] and 
           Focus == "Science" then
      local active = 1
      
      for i, list in ipairs (Science_Page.Active_List) do
        if list.active then
          active = i - 1
          
          if active == 0 then
            active = #Science_Page.Active_List
          end
          
          break
        end
      end
      
      for i, list in ipairs (Science_Page.Active_List) do
        list.active = (i == active)
      end
           
    elseif keys [keybindings.right.key] and 
           Focus == "Science" then
      local active = 1
      
      for i, list in ipairs (Science_Page.Active_List) do
        if list.active then
          active = i + 1
          
          if active > #Science_Page.Active_List then
            active = 1
          end
          
          break
        end
      end
      
      for i, list in ipairs (Science_Page.Active_List) do
        list.active = (i == active)
      end
           
    elseif keys [keybindings.left.key] and 
           Focus == "Values" then
      local active = 1
      
      for i, list in ipairs (Values_Page.Active_List) do
        if list.active then
          active = i - 1
          
          if active == 0 then
            active = #Values_Page.Active_List
          end
          
          break
        end
      end
      
      for i, list in ipairs (Values_Page.Active_List) do
        list.active = (i == active)
      end
           
    elseif keys [keybindings.right.key] and 
           Focus == "Values" then
      local active = 1
      
      for i, list in ipairs (Values_Page.Active_List) do
        if list.active then
          active = i + 1
          
          if active > #Values_Page.Active_List then
            active = 1
          end
          
          break
        end
      end
      
      for i, list in ipairs (Values_Page.Active_List) do
        list.active = (i == active)
      end
           
    elseif keys [keybindings.left.key] and 
           Focus == "Authors" then
      local active = 1
      
      for i, list in ipairs (Authors_Page.Active_List) do
        if list.active then
          active = i - 1
          
          if active == 0 then
            active = #Authors_Page.Active_List
          end
          
          break
        end
      end
      
      for i, list in ipairs (Authors_Page.Active_List) do
        list.active = (i == active)
      end
           
    elseif keys [keybindings.right.key] and 
           Focus == "Authors" then
      local active = 1
      
      for i, list in ipairs (Authors_Page.Active_List) do
        if list.active then
          active = i + 1
          
          if active > #Authors_Page.Active_List then
            active = 1
          end
          
          break
        end
      end
      
      for i, list in ipairs (Authors_Page.Active_List) do
        list.active = (i == active)
      end
           
    elseif Focus == "Hidden" then
      persist_screen:sendInputToParent (keys)
    end

    self.super.onInput (self, keys)
  end

  --============================================================

  function Show_Viewer ()
    local screen = Ui {}
    persist_screen = screen
    screen:show ()
  end

  --============================================================

  Show_Viewer ()  
end

Librarian ()