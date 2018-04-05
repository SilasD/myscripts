local detail_category =
  {[df.written_content_type.Manual] = true,                            --  This is the category where scientific knowledge is found
   [df.written_content_type.Guide] = false,                             --  Concerns sites
   [df.written_content_type.Chronicle] = false,                         --  Concerns entities
   [df.written_content_type.ShortStory] = false,
   [df.written_content_type.Novel] = false,
   [df.written_content_type.Biography] = false,                         --  Concerns hist figs
   [df.written_content_type.Autobiography] = false,
   [df.written_content_type.Poem] = true,
   [df.written_content_type.Play] = true,
   [df.written_content_type.Letter] = false,
   [df.written_content_type.Essay] = true,                             --  This is the category where value shifting books are found
                                                                       --    but it also contains historical events
   [df.written_content_type.Dialog] = true,
   [df.written_content_type.MusicalComposition] = true,
   [df.written_content_type.Choreography] = true,
   [df.written_content_type.ComparativeBiography] = true,
   [df.written_content_type.BiographicalDictionary] = true,
   [df.written_content_type.Genealogy] = true,
   [df.written_content_type.Encyclopedia] = true,
   [df.written_content_type.CulturalHistory] = false,                   --  One entity reference found here
   [df.written_content_type.CulturalComparison] = true,
   [df.written_content_type.AlternateHistory] = true,
   [df.written_content_type.TreatiseOnTechnologicalEvolution] = true,
   [df.written_content_type.Dictionary] = false,                        --  Language references
   [df.written_content_type.StarChart] = true,
   [df.written_content_type.StarCatalogue] = true,
   [df.written_content_type.Atlas] = true}
   
local suppress_science_titles = true
local suppress_no_contents = true
local only_show_value_changing_essays = true
local show_science_summary = true
local show_missing_science_books = true
local list_authors = false
local print_author_books = true

--=====================================

local accumulated_knowledge = {}
  accumulated_knowledge [0] = df.general_ref_knowledge_scholar_flagst:new()
  accumulated_knowledge [1] = df.general_ref_knowledge_scholar_flagst:new()
  accumulated_knowledge [2] = df.general_ref_knowledge_scholar_flagst:new()
  accumulated_knowledge [3] = df.general_ref_knowledge_scholar_flagst:new()
  accumulated_knowledge [4] = df.general_ref_knowledge_scholar_flagst:new()
  accumulated_knowledge [5] = df.general_ref_knowledge_scholar_flagst:new()
  accumulated_knowledge [6] = df.general_ref_knowledge_scholar_flagst:new()
  accumulated_knowledge [7] = df.general_ref_knowledge_scholar_flagst:new()
  accumulated_knowledge [8] = df.general_ref_knowledge_scholar_flagst:new()
  accumulated_knowledge [9] = df.general_ref_knowledge_scholar_flagst:new()
  accumulated_knowledge [10] = df.general_ref_knowledge_scholar_flagst:new()
  accumulated_knowledge [11] = df.general_ref_knowledge_scholar_flagst:new()
  accumulated_knowledge [12] = df.general_ref_knowledge_scholar_flagst:new()
  accumulated_knowledge [13] = df.general_ref_knowledge_scholar_flagst:new()

for i = 0, 13 do
  accumulated_knowledge [i].knowledge.category = i
end

local authors = {}
local civ_id = df.global.world.world_data.active_site [0].entity_links [0].entity_id

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
 
function value_books ()
  local count = 0
  local category_lists = {}  
  
  for i = df.written_content_type._first_item, df.written_content_type._last_item do
    if detail_category [i] ~= true and
       detail_category [i] ~= false then
      dfhack.error ("Script outdated. Missing entry for written_content_type value " .. df.written_content_type [i])
    end
    category_lists [i] = {}
  end
  
  for i, item in ipairs (df.global.world.items.all) do
    if (item._type == df.item_bookst or
        (item._type == df.item_toolst and
         item.flags.artifact and
         (item.subtype.id == "ITEM_TOOL_SCROLL" or
          item.subtype.id == "ITEM_TOOL_QUIRE"))) and
       (item.pos.x ~= -30000 or
        item.pos.y ~= -30000 or
        item.pos.z ~= -30000) then
      count = count + 1
      
      local category_found = {}
      for k = df.written_content_type._first_item, df.written_content_type._last_item do
        category_found [k] = false
      end
      
      for k, improvement in ipairs (item.improvements) do
        if improvement._type == df.itemimprovement_pagesst or
           improvement._type == df.itemimprovement_writingst then
          for l, content_id in ipairs (improvement.contents) do
            local content = df.written_content.find (content_id)
            
            if not category_found [content.type] then
              table.insert (category_lists [content.type], item)
              category_found [content.type] = true
            end
          end
        end
      end
    end
  end

  for i = df.written_content_type._first_item, df.written_content_type._last_item do
    if detail_category [i] and
       #category_lists [i] > 0 then
      dfhack.color (COLOR_LIGHTCYAN)
      dfhack.println ("Books in the " .. df.written_content_type [i] .. " category: ")    
      dfhack.color (COLOR_RESET)
    
      for k, item in ipairs (category_lists [i]) do
        for l, improvement in ipairs (item.improvements) do
          if improvement._type == df.itemimprovement_pagesst or
             improvement._type == df.itemimprovement_writingst then
            for m, content_id in ipairs (improvement.contents) do
              local content = df.written_content.find (content_id)
              local title_shown = false

              local hf = df.historical_figure.find (content.author)
              
              if hf and
                 hf.died_year == -1 and
                 hf.civ_id == civ_id and
                 hf.unit_id ~= -1 then
                local unit = df.unit.find (hf.unit_id)
                if unit then
                  if not authors [unit.id] then
                    authors [unit.id] = {}
                  end
                  
                  table.insert (authors [unit.id], content.title)
                end
              end
              
              for n, ref in ipairs (content.refs) do
                if content.ref_aux [n] == 0 then  --  XML comment claims non zero means ref should be ignored.               
                  if ref._type == df.general_ref_knowledge_scholar_flagst then
                    if not suppress_science_titles then
                      dfhack.print ("  " .. content.title .. " provides knowledge on ")
                    end
                    
                    title_shown = true
              
                    if ref.knowledge.category == 0 then
                      for m, flag in ipairs (ref.knowledge.flags.flags_0) do
                        if flag then
                          accumulated_knowledge [0].knowledge.flags.flags_0 [m] = true
                          
                          if not suppress_science_titles then
                            dfhack.println (df.knowledge_scholar_flags_0 [m])
                          end
                        end
                      end
                
                    elseif ref.knowledge.category == 1 then
                      for m, flag in ipairs (ref.knowledge.flags.flags_1) do
                        if flag then
                          accumulated_knowledge [1].knowledge.flags.flags_1 [m] = true
                          
                          if not suppress_science_titles then
                            dfhack.println (df.knowledge_scholar_flags_1 [m])
                          end
                        end
                      end
                 
                    elseif ref.knowledge.category == 2 then
                      for m, flag in ipairs (ref.knowledge.flags.flags_2) do
                        if flag then
                          accumulated_knowledge [2].knowledge.flags.flags_2 [m] = true
                          
                          if not suppress_science_titles then
                            dfhack.println (df.knowledge_scholar_flags_2 [m])
                          end
                        end
                      end
                
                    elseif ref.knowledge.category == 3 then
                      for m, flag in ipairs (ref.knowledge.flags.flags_3) do
                        if flag then
                          accumulated_knowledge [3].knowledge.flags.flags_3 [m] = true
                          
                          if not suppress_science_titles then
                            dfhack.println (df.knowledge_scholar_flags_3 [m])
                          end
                        end
                      end
                
                    elseif ref.knowledge.category == 4 then
                      for m, flag in ipairs (ref.knowledge.flags.flags_4) do
                        if flag then
                          accumulated_knowledge [4].knowledge.flags.flags_4 [m] = true
                          
                          if not suppress_science_titles then
                            dfhack.println (df.knowledge_scholar_flags_4 [m])
                          end
                        end
                      end
                
                    elseif ref.knowledge.category == 5 then
                      for m, flag in ipairs (ref.knowledge.flags.flags_5) do
                        if flag then
                          accumulated_knowledge [5].knowledge.flags.flags_5 [m] = true
                          
                          if not suppress_science_titles then
                            dfhack.println (df.knowledge_scholar_flags_5 [m])
                          end
                        end
                      end
                
                    elseif ref.knowledge.category == 6 then
                      for m, flag in ipairs (ref.knowledge.flags.flags_6) do
                        if flag then
                          accumulated_knowledge [6].knowledge.flags.flags_6 [m] = true
                          
                          if not suppress_science_titles then
                            dfhack.println (df.knowledge_scholar_flags_6 [m])
                          end
                        end
                      end
                
                    elseif ref.knowledge.category == 7 then
                      for m, flag in ipairs (ref.knowledge.flags.flags_7) do
                        if flag then
                          accumulated_knowledge [7].knowledge.flags.flags_7 [m] = true
                          
                          if not suppress_science_titles then
                            dfhack.println (df.knowledge_scholar_flags_7 [m])
                          end
                        end
                      end
                 
                    elseif ref.knowledge.category == 8 then
                      for m, flag in ipairs (ref.knowledge.flags.flags_8) do
                        if flag then
                          accumulated_knowledge [8].knowledge.flags.flags_8 [m] = true
                          
                          if not suppress_science_titles then
                            dfhack.println (df.knowledge_scholar_flags_8 [m])
                          end
                        end
                      end
                
                    elseif ref.knowledge.category == 9 then
                      for m, flag in ipairs (ref.knowledge.flags.flags_9) do
                        if flag then
                          accumulated_knowledge [9].knowledge.flags.flags_9 [m] = true
                          
                          if not suppress_science_titles then
                            dfhack.println (df.knowledge_scholar_flags_9 [m])
                          end
                        end
                      end
                
                    elseif ref.knowledge.category == 10 then
                      for m, flag in ipairs (ref.knowledge.flags.flags_10) do
                        if flag then
                          accumulated_knowledge [10].knowledge.flags.flags_10 [m] = true
                          
                          if not suppress_science_titles then
                            dfhack.println (df.knowledge_scholar_flags_10 [m])
                          end
                        end
                      end
                
                    elseif ref.knowledge.category == 11 then
                      for m, flag in ipairs (ref.knowledge.flags.flags_11) do
                        if flag then
                          accumulated_knowledge [11].knowledge.flags.flags_11 [m] = true
                          
                          if not suppress_science_titles then
                            dfhack.println (df.knowledge_scholar_flags_11 [m])
                          end
                        end
                    end
                
                    elseif ref.knowledge.category == 12 then
                      for m, flag in ipairs (ref.knowledge.flags.flags_12) do
                        if flag then
                          accumulated_knowledge [12].knowledge.flags.flags_12 [m] = true
                          
                          if not suppress_science_titles then
                            dfhack.println (df.knowledge_scholar_flags_12 [m])
                          end
                        end
                      end
                
                    elseif ref.knowledge.category == 13 then
                      for m, flag in ipairs (ref.knowledge.flags.flags_13) do
                        if flag then
                          accumulated_knowledge [13].knowledge.flags.flags_13 [m] = true
                          
                          if not suppress_science_titles then
                            dfhack.println (df.knowledge_scholar_flags_13 [m])
                          end
                        end
                      end                
                    end
              
                  elseif ref._type == df.general_ref_value_levelst then
                    local strength
                    local level
              
                    if ref.level < -40 then
                      strength = -3
                      level = "Hate"
            
                    elseif ref.level < -25 then
                      strength = -2
                      level = "Strong dislike"
                
                    elseif ref.level < -10 then
                      strength = -1
                      level = "Dislike"
        
                    elseif ref.level <= 10 then
                      strength = 0
                      level = "Indifference"
          
                    elseif ref.level <= 25 then
                      strength = 1
                      level = "Like"
          
                    elseif ref.level <= 40 then
                      strength = 2
                      level = "Strong liking"
          
                    else
                      strength = 3
                      level = "Love"
                    end
            
                    dfhack.println ("  " .. content.title .. ' moves views towards "' .. values [ref.value] [strength] .. '" =  ' .. level)
                    title_shown = true
                  
                  elseif ref._type == df.general_ref_artifact or
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
                         ref._type == df.general_ref_historical_eventst or
                         ref._type == df.general_ref_spherest or
                         ref._type == df.general_ref_sitest or
                         ref._type == df.general_ref_subregionst or
                         ref._type == df.general_ref_feature_layerst or
                         ref._type == df.general_ref_historical_figurest or
                         ref._type == df.general_ref_entity_popst or
                         ref._type == df.general_ref_creaturest or
                         --ref._type == df.general_ref_knowledge_scholar_flagst or
                         ref._type == df.general_ref_activity_eventst or
                         --ref._type == df.general_ref_value_levelst or
                         ref._type == df.general_ref_languagest or
                         ref._type == df.general_ref_written_contentst or
                         ref._type == df.general_ref_poetic_formst or
                         ref._type == df.general_ref_musical_formst or
                         ref._type == df.general_ref_dance_formst then
                    if not only_show_value_changing_essays or
                       content.type ~= df.written_content_type.Essay then
                      dfhack.println ("  " .. content.title .. "  concerns unresolved " .. tostring (ref._type) .. " information")
                    end
                       
                    title_shown = true  --  A lie in the case of suppression above...
                  else
                    dfhack.error ("Unaccounted for general ref type: " .. tostring (ref._type))
                  end                
                end
              end
            
              if not title_shown and
                 not suppress_no_contents then
                dfhack.println ("  " .. content.title)
              end
            end
          end
        end
      end
    end
  end
  
  for i = df.written_content_type._first_item, df.written_content_type._last_item do
    dfhack.println ("Number of books in the " .. df.written_content_type [i] .. " category: " .. tostring (#category_lists [i]))
  end
  
  dfhack.println ("Number of books total: " .. tostring (count))
  
  if show_science_summary then
    for i = 0, 13 do
      if i == 0 then
        for k = df.knowledge_scholar_flags_0._first_item, df.knowledge_scholar_flags_0._last_item do
          if accumulated_knowledge [0].knowledge.flags.flags_0 [k] then
            dfhack.color (COLOR_GREEN)
            
          else
            dfhack.color (COLOR_YELLOW)
          end
        
          if df.knowledge_scholar_flags_0 [k] then  --  For some reason _last_item gives 31 uniformly, rather than the last enum value.
            dfhack.println (df.knowledge_scholar_flags_0 [k])
          end
          
          dfhack.color (COLOR_RESET)
        end
      
      elseif i == 1 then
        for k = df.knowledge_scholar_flags_1._first_item, df.knowledge_scholar_flags_1._last_item do
          if accumulated_knowledge [1].knowledge.flags.flags_1 [k] then
            dfhack.color (COLOR_GREEN)
            
          else
            dfhack.color (COLOR_YELLOW)
          end
        
          if df.knowledge_scholar_flags_1 [k] then
            dfhack.println (df.knowledge_scholar_flags_1 [k])
          end
          
          dfhack.color (COLOR_RESET)
        end
      
      elseif i == 2 then
        for k = df.knowledge_scholar_flags_2._first_item, df.knowledge_scholar_flags_2._last_item do
          if accumulated_knowledge [2].knowledge.flags.flags_2 [k] then
            dfhack.color (COLOR_GREEN)
            
          else
            dfhack.color (COLOR_YELLOW)
          end
        
          if df.knowledge_scholar_flags_2 [k] then
            dfhack.println (df.knowledge_scholar_flags_2 [k])
          end
          
          dfhack.color (COLOR_RESET)
        end
      
      elseif i == 3 then
        for k = df.knowledge_scholar_flags_3._first_item, df.knowledge_scholar_flags_3._last_item do
          if accumulated_knowledge [3].knowledge.flags.flags_3 [k] then
            dfhack.color (COLOR_GREEN)
            
          else
            dfhack.color (COLOR_YELLOW)
          end
        
          if df.knowledge_scholar_flags_3 [k] then
            dfhack.println (df.knowledge_scholar_flags_3 [k])
          end
          
          dfhack.color (COLOR_RESET)
        end
      
      elseif i == 4 then
        for k = df.knowledge_scholar_flags_4._first_item, df.knowledge_scholar_flags_4._last_item do
          if accumulated_knowledge [4].knowledge.flags.flags_4 [k] then
            dfhack.color (COLOR_GREEN)
            
          else
            dfhack.color (COLOR_YELLOW)
          end
        
          if df.knowledge_scholar_flags_4 [k] then
            dfhack.println (df.knowledge_scholar_flags_4 [k])
          end
          
          dfhack.color (COLOR_RESET)
        end
      
      elseif i == 5 then
        for k = df.knowledge_scholar_flags_5._first_item, df.knowledge_scholar_flags_5._last_item do
          if accumulated_knowledge [5].knowledge.flags.flags_5 [k] then
            dfhack.color (COLOR_GREEN)
            
          else
            dfhack.color (COLOR_YELLOW)
          end
        
          if df.knowledge_scholar_flags_5 [k] then
            dfhack.println (df.knowledge_scholar_flags_5 [k])
          end
          dfhack.color (COLOR_RESET)
          
        end
      
      elseif i == 6 then
        for k = df.knowledge_scholar_flags_6._first_item, df.knowledge_scholar_flags_6._last_item do
          if accumulated_knowledge [6].knowledge.flags.flags_6 [k] then
            dfhack.color (COLOR_GREEN)
            
          else
            dfhack.color (COLOR_YELLOW)
          end
        
          if df.knowledge_scholar_flags_6 [k] then
            dfhack.println (df.knowledge_scholar_flags_6 [k])
          end
          dfhack.color (COLOR_RESET)
          
        end
      
      elseif i == 7 then
        for k = df.knowledge_scholar_flags_7._first_item, df.knowledge_scholar_flags_7._last_item do
          if accumulated_knowledge [7].knowledge.flags.flags_7 [k] then
            dfhack.color (COLOR_GREEN)
            
          else
            dfhack.color (COLOR_YELLOW)
          end
        
          if df.knowledge_scholar_flags_7 [k] then
            dfhack.println (df.knowledge_scholar_flags_7 [k])
          end
          dfhack.color (COLOR_RESET)
          
        end
      
      elseif i == 8 then
        for k = df.knowledge_scholar_flags_8._first_item, df.knowledge_scholar_flags_8._last_item do
           if accumulated_knowledge [8].knowledge.flags.flags_8 [k] then
             dfhack.color (COLOR_GREEN)
           
          else
            dfhack.color (COLOR_YELLOW)
          end
        
          if df.knowledge_scholar_flags_8 [k] then
            dfhack.println (df.knowledge_scholar_flags_8 [k])
          end
          dfhack.color (COLOR_RESET)
          
        end
      
      elseif i == 9 then
        for k = df.knowledge_scholar_flags_9._first_item, df.knowledge_scholar_flags_9._last_item do
          if accumulated_knowledge [9].knowledge.flags.flags_9 [k] then
            dfhack.color (COLOR_GREEN)
            
          else
            dfhack.color (COLOR_YELLOW)
          end
        
          if df.knowledge_scholar_flags_9 [k] then
            dfhack.println (df.knowledge_scholar_flags_9 [k])
          end
        
          dfhack.color (COLOR_RESET)
        end
      
      elseif i == 10 then
        for k = df.knowledge_scholar_flags_10._first_item, df.knowledge_scholar_flags_10._last_item do
          if accumulated_knowledge [10].knowledge.flags.flags_10 [k] then
            dfhack.color (COLOR_GREEN)
            
          else
            dfhack.color (COLOR_YELLOW)
          end
        
          if df.knowledge_scholar_flags_10 [k] then
            dfhack.println (df.knowledge_scholar_flags_10 [k])
          end
          
          dfhack.color (COLOR_RESET)
        end
      
      elseif i == 11 then
        for k = df.knowledge_scholar_flags_11._first_item, df.knowledge_scholar_flags_11._last_item do
          if accumulated_knowledge [11].knowledge.flags.flags_11 [k] then
            dfhack.color (COLOR_GREEN)
            
          else
            dfhack.color (COLOR_YELLOW)
          end
        
          if df.knowledge_scholar_flags_11 [k] then
            dfhack.println (df.knowledge_scholar_flags_11 [k])
          end
          
          dfhack.color (COLOR_RESET)
        end
      
      elseif i == 12 then
        for k = df.knowledge_scholar_flags_12._first_item, df.knowledge_scholar_flags_12._last_item do
          if accumulated_knowledge [12].knowledge.flags.flags_12 [k] then
            dfhack.color (COLOR_GREEN)
            
          else
            dfhack.color (COLOR_YELLOW)
          end
        
          if df.knowledge_scholar_flags_12 [k] then
            dfhack.println (df.knowledge_scholar_flags_12 [k])
          end
          
          dfhack.color (COLOR_RESET)
        end
      
      elseif i == 13 then
        for k = df.knowledge_scholar_flags_13._first_item, df.knowledge_scholar_flags_13._last_item do
          if accumulated_knowledge [13].knowledge.flags.flags_13 [k] then
            dfhack.color (COLOR_GREEN)
            
          else
            dfhack.color (COLOR_YELLOW)
          end
        
          if df.knowledge_scholar_flags_13 [k] then
            dfhack.println (df.knowledge_scholar_flags_13 [k])
          end
        
          dfhack.color (COLOR_RESET)
        end      
      end
    end
  end
  
  if show_missing_science_books then
    dfhack.println ("Books on missing science topics:")
    for i, content in ipairs (df.global.world.written_contents.all) do              
      for k, ref in ipairs (content.refs) do
        if content.ref_aux [k] == 0 then  --  XML comment claims non zero means ref should be ignored.  
          if ref._type == df.general_ref_knowledge_scholar_flagst then
            for l, flag in ipairs (ref.knowledge.flags.flags_0) do  --  It's a union, so it doesn't actually matter which alias we use.
              if flag and
                 not accumulated_knowledge [ref.knowledge.category].knowledge.flags.flags_0 [l] then  -- Again, a union
                dfhack.println (content.title, df.dfhack_knowledge_scholar_flag [ref.knowledge:value ()])
              end
            end
          end
        end
      end
    end
  end
  
  for i = 0, 13 do
    accumulated_knowledge [i]:delete ()
  end
  
  if list_authors then
    for unit_id, list in pairs (authors) do
      dfhack.println (dfhack.TranslateName (df.unit.find (unit_id).name, true), #list)
    
      if print_author_books then
        for i, title in ipairs (list) do
          dfhack.println ("  " .. title)
        end
      end
    end
  end
end

value_books ()