--  This script attempts to recreate some of the contents of a unit's thought screen, primarily for usage with units whose
--  thought screen is unavailable (gremlins).
--  In addition to that screen, relations are attempted to be reproduced as well.
--
--  It is a work in progress, and things marked with ### are things that haven't been seen or have other outstanding issues.
--  Version 0.1 2018-01-21

--### At least the emotion thought enum has been extended since work on this script started. Remains to check if other things are missing/updated.
--    Should probably switch to a list style as the one with "values" plus a startup check to automatically flag any additional values for more items.

--### Cannot get the marked ones below to be displayed on dorfs, but DT picked them up.
--    The rest of them have been generated with DFHacking and verified against the DF display.
--
local goal = {[df.goal_type.STAY_ALIVE] = "**staying alive",  --###
              [df.goal_type.MAINTAIN_ENTITY_STATUS] = "**maintaining entity status",  --### unk1 = 1, unk3 = entity to be maintained? Matches own for necro, gobbo civ for gobbo invaders
              [df.goal_type.START_A_FAMILY] = "raising a family",
              [df.goal_type.RULE_THE_WORLD] = "ruling the world",
              [df.goal_type.CREATE_A_GREAT_WORK_OF_ART] = "creating a great work of art",
              [df.goal_type.CRAFT_A_MASTERWORK] = "crafting a masterwork someday",
              [df.goal_type.BRING_PEACE_TO_THE_WORLD] = "bringing lasting peace to the world",
              [df.goal_type.BECOME_A_LEGENDARY_WARRIOR] = "becoming a legendary warrior",
              [df.goal_type.MASTER_A_SKILL] = "mastering a skill",
              [df.goal_type.FALL_IN_LOVE] = "falling in love",
              [df.goal_type.SEE_THE_GREAT_NATURAL_SITES] = "seeing the great natural places of the world",
              [df.goal_type.IMMORTALITY] = "**immortality",  --###
              [df.goal_type.MAKE_A_GREAT_DISCOVERY] = "making a great discovery"}

--  These have all been copied by generating the corresponding values and checking the DF display. Since
--  values matching racial values are suppressed, dorfs were modified to have different values to get the
--  complete set.
--  ###Note that there are a couple of cases where two different texts are thought to have been seen for the
--  same value. DF might use RNG:ing to put together parts that follow a standard pattern or may have
--  several alternative strings.
--
--  ###Are values suppressed when they do not modify the default racial values? Or civ values?
--
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

--  {feeling_type, text, prefix} where:
--   "feeling_type" is:
--   - true = is/was
--   - false = feels/felt
--   - nil = <nothing printed>
--   "text" is the text DF prints for the feeling_type
--   "prefix" is an optional parameter that goes in between feeling_type and text, but is printed in the standard color, not the feeling color.
--     it turns out all instances of this parameter seems to be "in ", so it could have been a boolean instead (with only true or absent used).
--
local emotions = {[df.emotion_type.ANYTHING] = {false, "ANYTHING"},
                  [df.emotion_type.ACCEPTANCE] = {true, "accepting"},
                  [df.emotion_type.ADORATION] = {false, "adoration"},
                  [df.emotion_type.AFFECTION] = {false, "affection"},
                  [df.emotion_type.AGITATION] = {true, "agitated"},
                  [df.emotion_type.AGGRAVATION] = {true, "aggravated"},
                  [df.emotion_type.AGONY] = {true, "agony"},
                  [df.emotion_type.ALARM] = {true, "alarmed"},
                  [df.emotion_type.ALIENATION] = {false, "alienated"},
                  [df.emotion_type.AMAZEMENT] = {true, "amazed"},
                  [df.emotion_type.AMBIVALENCE] = {true, "ambivalent"},
                  [df.emotion_type.AMUSEMENT] = {true, "amused"},
                  [df.emotion_type.ANGER] = {true, "angry"},
                  [df.emotion_type.ANGST] = {true, "existential crisis", "in "},
                  [df.emotion_type.ANGUISH] = {true, "anguish", "in "},
                  [df.emotion_type.ANNOYANCE] = {true, "annoyed"},
                  [df.emotion_type.ANXIETY] = {false, "anxious"},
                  [df.emotion_type.APATHY] = {true, "apathetic"},
                  [df.emotion_type.AROUSAL] = {true, "aroused"},
                  [df.emotion_type.ASTONISHMENT] = {true, "astonished"},
                  [df.emotion_type.AVERSION] = {false, "aversion"},
                  [df.emotion_type.AWE] = {true, "awe", "in "},
                  [df.emotion_type.BITTERNESS] = {false, "bitter"},
                  [df.emotion_type.BLISS] = {true, "blissful"},
                  [df.emotion_type.BOREDOM] = {true, "bored"},
                  [df.emotion_type.CARING] = {false, "caring"},
                  [df.emotion_type.CONFUSION] = {true, "confused"},
                  [df.emotion_type.CONTEMPT] = {true, "contemptuous"},
                  [df.emotion_type.CONTENTMENT] = {true, "content"},
                  [df.emotion_type.DEFEAT] = {false, "defeated"},
                  [df.emotion_type.DEJECTION] = {true, "dejected"},
                  [df.emotion_type.DELIGHT] = {true, "delighted"},
                  [df.emotion_type.DESPAIR] = {true, "despair", "in "},
                  [df.emotion_type.DISAPPOINTMENT] = {false, "disappointed"},
                  [df.emotion_type.DISGUST] = {true, "disgusted"},
                  [df.emotion_type.DISILLUSIONMENT] = {true, "disillusioned"},
                  [df.emotion_type.DISLIKE] = {false, "dislike"},
                  [df.emotion_type.DISMAY] = {true, "dismayed"},
                  [df.emotion_type.DISPLEASURE] = {false, "displeasure"},
                  [df.emotion_type.DISTRESS] = {true, "distressed"},
                  [df.emotion_type.DOUBT] = {true, "doubt", "in "},
                  [df.emotion_type.EAGERNESS] = {true, "eager"},
                  [df.emotion_type.ELATION] = {true, "elated"},
                  [df.emotion_type.EMBARRASSMENT] = {true, "embarrassed"},
                  [df.emotion_type.EMPATHY] = {false, "empathy"},
                  [df.emotion_type.EMPTINESS] = {false, "empty"},
                  [df.emotion_type.ENJOYMENT] = {false, "enjoyment"},
                  [df.emotion_type.ENTHUSIASM] = {true, "enthusiastic"},
                  [df.emotion_type.EUPHORIA] = {false, "euphoric"},
                  [df.emotion_type.EXASPERATION] = {true, "exasperated"},
                  [df.emotion_type.EXCITEMENT] = {true, "excited"},
                  [df.emotion_type.EXHILARATION] = {true, "exhilarated"},
                  [df.emotion_type.EXPECTANCY] = {true, "expectant"},
                  [df.emotion_type.FEAR] = {true, "afraid"},
                  [df.emotion_type.FEROCITY] = {false, "ferocity"},
                  [df.emotion_type.FONDNESS] = {false, "fondness"},
                  [df.emotion_type.FREEDOM] = {false, "free"},
                  [df.emotion_type.FRIGHT] = {true, "frightened"},
                  [df.emotion_type.FRUSTRATION] = {true, "frustrated"},
                  [df.emotion_type.GAIETY] = {false, "gaiety"},
                  [df.emotion_type.GLEE] = {true, "gleeful"},
                  [df.emotion_type.GLOOM] = {true, "gloomy"},
                  [df.emotion_type.GLUMNESS] = {false, "glum"},
                  [df.emotion_type.GRATITUDE] = {false, "gratitude"},
                  [df.emotion_type.GRIEF] = {nil, "grieved"},
                  [df.emotion_type.GRIM_SATISFACTION] = {false, "grim satisfaction"},
                  [df.emotion_type.GROUCHINESS] = {true, "grouchy"},
                  [df.emotion_type.GRUMPINESS] = {true, "grumpy"},
                  [df.emotion_type.GUILT] = {false, "guilty"},
                  [df.emotion_type.HAPPINESS] = {false, "happy"},
                  [df.emotion_type.HATRED] = {false, "hateful"},
                  [df.emotion_type.HOPE] = {false, "hope"},
                  [df.emotion_type.HOPELESSNESS] = {false, "hopeless"},
                  [df.emotion_type.HORROR] = {true, "horrified"},
                  [df.emotion_type.HUMILIATION] = {false, "humiliated"},
                  [df.emotion_type.INSULT] = {false, "insulted"},
                  [df.emotion_type.INTEREST] = {true, "interested"},
                  [df.emotion_type.IRRITATION] = {true, "insulted"},
                  [df.emotion_type.ISOLATION] = {false, "isolated"},
                  [df.emotion_type.JOLLINESS] = {true, "jolly"},
                  [df.emotion_type.JOVIALITY] = {false, "jovial"},
                  [df.emotion_type.JOY] = {false, "joy"},
                  [df.emotion_type.JUBILATION] = {true, "jubilant"},
                  [df.emotion_type.LOATHING] = {false, "loathing"},
                  [df.emotion_type.LONELINESS] = {false, "lonely"},
                  [df.emotion_type.LOVE] = {false, "love"},
                  [df.emotion_type.LUST] = {false, "lustful"},
                  [df.emotion_type.MISERY] = {false, "miserable"},
                  [df.emotion_type.MORTIFICATION] = {true, "mortified"},
                  [df.emotion_type.NERVOUSNESS] = {false, "nervous"},
                  [df.emotion_type.NOSTALGIA] = {false, "nostalgic"},
                  [df.emotion_type.OPTIMISM] = {false, "optimistic"},
                  [df.emotion_type.OUTRAGE] = {true, "outraged"},
                  [df.emotion_type.PANIC] = {nil, "panicked"},
                  [df.emotion_type.PATIENCE] = {false, "patient"},
                  [df.emotion_type.PASSION] = {false, "passionate"},
                  [df.emotion_type.PESSIMISM] = {true, "pessimistic"},
                  [df.emotion_type.PLEASURE] = {false, "pleasure"},
                  [df.emotion_type.PRIDE] = {true, "proud"},
                  [df.emotion_type.RAGE] = {nil, "rages"},
                  [df.emotion_type.RAPTURE] = {is, "enraptured"},
                  [df.emotion_type.REJECTION] = {false, "rejected"},
                  [df.emotion_type.RELIEF] = {true, "relieved"},
                  [df.emotion_type.REGRET] = {false, "regretful"},
                  [df.emotion_type.REMORSE] = {false, "remorseful"},
                  [df.emotion_type.REPENTANCE] = {false, "repentant"},
                  [df.emotion_type.RESENTMENT] = {true, "resentful"},
                  [df.emotion_type.RIGHTEOUS_INDIGNATION] = {false, "indignant"},
                  [df.emotion_type.SADNESS] = {false, "sad"},
                  [df.emotion_type.SATISFACTION] = {false, "satisfied"},
                  [df.emotion_type.SELF_PITY] = {false, "self-pity"},
                  [df.emotion_type.SERVILE] = {false, "servile"},
                  [df.emotion_type.SHAKEN] = {true, "shaken"},
                  [df.emotion_type.SHAME] = {true, "ashamed"},
                  [df.emotion_type.SHOCK] = {true, "shocked"},
                  [df.emotion_type.SUSPICION] = {true, "suspicious"},
                  [df.emotion_type.SYMPATHY] = {false, "sympathy"},
                  [df.emotion_type.TENDERNESS] = {false, "tenderness"},
                  [df.emotion_type.TERROR] = {true, "terrified"},
                  [df.emotion_type.THRILL] = {true, "thrilled"},
                  [df.emotion_type.TRIUMPH] = {false, "triumph"},
                  [df.emotion_type.UNEASINESS] = {true, "uneasy"},
                  [df.emotion_type.UNHAPPINESS] = {false, "unhappy"},
                  [df.emotion_type.VENGEFULNESS] = {false, "vengeful"},
                  [df.emotion_type.WONDER] = {false, "wonder"},
                  [df.emotion_type.WORRY] = {true, "worried"},
                  [df.emotion_type.WRATH] = {false, "wrathful"},
                  [df.emotion_type.ZEAL] = {false, "zealous"},
                  [df.emotion_type.RESTLESS] = {false, "restless"},
                  [df.emotion_type.ADMIRATION] = {false, "admiration"}}

--------------------------------------------

local gender_translation = {["he"] = {[0] = "she", [1] = "he"},
                            ["his"] = {[0] = "her", [1] = "his"},
                            ["him"] = {[0] = "her", [1] = "him"}}
                            
--------------------------------------------

function token_extractor (str)
  local start = str:find ('[', 1, #str, true)
  local stop = str:find (']', 1, #str, true)
  
  if start then
    return str:sub (1, start - 1), str:sub (start + 1, stop - 1), str:sub (stop + 1, #str)
           
  else
    return str, nil, nil
  end
end

--------------------------------------------

function quality_of (emotion)
  if emotion.severity == df.item_quality.WellCrafted then
    return "well-crafted"
      
  elseif emotion.severity == df.item_quality.FinelyCrafted then
    return "finely-crafted"
      
  elseif emotion.severity == df.item_quality.Superior then
    return "superior" 
      
  elseif emotion.severity == df.item_quality.Exceptional then
    return "exceptional"
      
  else  --  df.item_quality.Ordinary
        --  df.item_quality.Masterful
        --  df.item_quality.Artifact
    return "truly splendid"
  end
end

--------------------------------------------

function food_quality_of (emotion)
  if emotion.severity == df.item_quality.Ordinary then
    return ""  --  Won't happen for food.
      
  elseif emotion.severity == df.item_quality.WellCrafted then
    return "pretty decent"   --  ###  meal for food
      
  elseif emotion.severity == df.item_quality.FinelyCrafted then
    return "fine"            --  ###  dish for food
      
  elseif emotion.severity == df.item_quality.Superior then
    return "wonderful"       --  ### dish for food
      
  elseif emotion.severity == df.item_quality.Exceptional then
    return "truly decadent"  --  ### dish for food
      
  elseif emotion.severity == df.item_quality.Masterful then
    return "legendary"       --  ###  meal for food
      
  elseif emotion.severity == df.item_quality.Artifact then
    return ""  -- Won't happen. "after having ." if DFHacked.
  
  else
    printerr ("Unknown quality severity found " ..  tostring (emotion.severity))
    return ""
  end
end

--------------------------------------------

function office_quality_of (emotion)  --### setting <-> office on meeting vs ...? DFHacking gave "setting", but earlier notes said "office". RNG?
  if emotion.severity == 0 then
    return " ."  --  Shouldn't happen. Matches DFHacked result...
    
  elseif emotion.severity == 1 then
    return "good setting."
    
  elseif emotion.severity == 2 then
    return "very good setting."
    
  elseif emotion.severity == 3 then
    return "great setting."
    
  elseif emotion.severity == 4 then
    return "fantastic setting." 
    
  elseif emotion.severity == 5 then
    return "room worthy of legends."
    
  else
    printerr ("Unknown quality severity found " ..  tostring (emotion.severity))
  end
end

--------------------------------------------

function bedroom_quality_of (emotion)
  if emotion.severity == 0 then
    return "**mundane bedroom."  --  ###Shouldn't happen
    
  elseif emotion.severity == 1 then
    return "good bedroom."
    
  elseif emotion.severity == 2 then
    return "very good bedroom."
    
  elseif emotion.severity == 3 then
    return "great bedroom."
    
  elseif emotion.severity == 4 then
    return "fantastic bedroom." 
    
  elseif emotion.severity == 5 then
    return "bedroom like a personal palace."
    
  else
    printerr ("Unknown quality severity found " ..  tostring (emotion.severity))
  end
end

--------------------------------------------

function dining_room_quality_of (emotion)
  if emotion.severity == 0 then
    return ""  --  ###Shouldn't happen
    
  elseif emotion.severity == 1 then
    return "good dining room."
    
  elseif emotion.severity == 2 then
    return "very good dining room."
    
  elseif emotion.severity == 3 then
    return "great dining room."
    
  elseif emotion.severity == 4 then
    return "fantastic dining room." 
    
  elseif emotion.severity == 5 then
    return "legendary dining room."
    
  else
    printerr ("Unknown quality severity found " ..  tostring (emotion.severity))
  end
end

--------------------------------------------

function tomb_quality_of (emotion)
  if emotion.severity == 0 then
    return ""  --  ###Shouldn't happen
    
  elseif emotion.severity == 1 then
    return "good "
    
  elseif emotion.severity == 2 then
    return "very good "
    
  elseif emotion.severity == 3 then
    return "great "
    
  elseif emotion.severity == 4 then
    return "fantastic " 
    
  elseif emotion.severity == 5 then
    return "legendary "
    
  else
    printerr ("Unknown quality severity found " ..  tostring (emotion.severity))
  end
end

--------------------------------------------

function building_quality_of (emotion)  --### Different scales for different buildings?  These are valid for Trade Depot and Bed
  if emotion.severity < 0 then
    return "" .. tostring (emotion.severity)
  
  elseif emotion.severity < 128 then
    return "fine " .. tostring (emotion.severity)
    
  elseif emotion.severity < 256 then
    return "very fine " .. tostring (emotion.severity)
    
  elseif emotion.severity < 384 then
    return "splendid " .. tostring (emotion.severity)
    
  elseif emotion.severity < 512 then
    return "wonderful " .. tostring (emotion.severity)
    
  else
    return "completely sublime " .. tostring (emotion.severity)
  end
end

--------------------------------------------

--### Could be replaced by a matrix with nicer looking names. DF itself uses nicer names, hidden away somewhere...
--
function get_topic (emotion)
  if emotion.subthought == 0 then
    return df.knowledge_scholar_flags_0 [emotion.severity]
    
  elseif emotion.subthought == 1 then
    return df.knowledge_scholar_flags_1 [emotion.severity]
    
  elseif emotion.subthought == 2 then
    return df.knowledge_scholar_flags_2 [emotion.severity]
    
  elseif emotion.subthought == 3 then
    return df.knowledge_scholar_flags_3 [emotion.severity]
    
  elseif emotion.subthought == 4 then
    return df.knowledge_scholar_flags_4 [emotion.severity]
    
  elseif emotion.subthought == 5 then
    return df.knowledge_scholar_flags_5 [emotion.severity]
    
  elseif emotion.subthought == 6 then
    return df.knowledge_scholar_flags_6 [emotion.severity]
    
  elseif emotion.subthought == 7 then
    return df.knowledge_scholar_flags_7 [emotion.severity]
    
  elseif emotion.subthought == 8 then
    return df.knowledge_scholar_flags_8 [emotion.severity]
    
  elseif emotion.subthought == 9 then
    return df.knowledge_scholar_flags_9 [emotion.severity]
    
  elseif emotion.subthought == 10 then
    return df.knowledge_scholar_flags_10 [emotion.severity]
    
  elseif emotion.subthought == 11 then
    return df.knowledge_scholar_flags_11 [emotion.severity]
    
  elseif emotion.subthought == 12 then
    return df.knowledge_scholar_flags_12 [emotion.severity]
    
  elseif emotion.subthought == 13 then
    return df.knowledge_scholar_flags_13 [emotion.severity]
    
  else
    dfhack.printerr ("Unknown topic subthought " .. tostring (emotion.subthought))
  end
end

--------------------------------------------

function add_subthought (caption, emotion, pronoun, possessive)
  if emotion.thought == -1 or
     (emotion.subthought == -1 and
      emotion.severity == -1) then
    return caption ..  "."
  end
  
  if emotion.thought == df.unit_thought_type.WitnessDeath then -- type: ANYTHING, unk2: 0, strength: 0, subthought: 364, severity: 0, flags: ffff, unk7: 0
    return caption .. "."  --###  There is a subthought (usually). Looks like a reference to an incident report.
                           --     The "victim_race" field of the report seems to be unit id, at least for a wild cavy killed,
                           --     and probably for a giant tortoise as well.
                           --     Try to resolve this when updated to the latest DF version, as the XML representation has changed.
    --  subthought = df.global.world.incidents.all id
  elseif emotion.thought == df.unit_thought_type.UnexpectedDeath then
    return caption  --### Find out how to get [somebody]
    
  elseif emotion.thought == df.unit_thought_type.MasterSkill then
    return "upon mastering " .. string.lower (df.job_skill [emotion.subthought]) .. "."  --###  Gets the job done, but skills could be printed nicely.
    
  elseif emotion.thought == df.unit_thought_type.Complained then
    --  Tested 0 .. 30. Results in blank string if not one below.
    if emotion.subthought == 25 then
      return "after bringing up job scarcity in a meeting."
    
    elseif emotion.subthought == 26 then
      return "after making suggestions about work allocation."
      
    elseif emotion.subthought == 27 then
      return "after requesting weapon production."
      
    elseif emotion.subthought == 28 then
      return "while yelling at somebody in charge."
      
    elseif emotion.subthought == 29 then
      return "while crying on somebody in charge."
      
    else
      dfhack.printerr ("Unhandled Complained subthought encountered " ..  tostring (emotion.subthought))
    end
    
  elseif emotion.thought == df.unit_thought_type.ReceivedComplaint then
    --  only tested 27 - 30
    if emotion.subthought == 28 then
      return "while being yelled at by an unhappy citizen."
      
    elseif emotion.subthought == 29 then
      return "while being cried on by an unhappy citizen."
      
    else
      dfhack.printerr ("Unhandled ReceivedComplaint subthought encountered " ..  tostring (emotion.subthought))
    end
    
  elseif emotion.thought == df.unit_thought_type.AdmireBuilding then -- DONE type: PLEASURE, unk2: 0, strength: 0, subthought: 6, severity: 15, flags: fftf, unk7: 0
    return "near a " .. building_quality_of (emotion) .. " " .. df.building_type [emotion.subthought] .. "."  --  Subthought = building type, severity = quality
  
  elseif emotion.thought == df.unit_thought_type.AdmireOwnBuilding then -- DONE type: PLEASURE, unk2: 0, strength: 0, subthought: 1, severity: 240, flags: fftf, unk7: 0
    return "near " .. possessive .. " own " .. building_quality_of (emotion) .. " " .. df.building_type [emotion.subthought] .. "."   --  Subthought = building type, severity = quality
    
  elseif emotion.thought == df.unit_thought_type.AdmireArrangedBuilding then
    return "near a " .. building_quality_of (emotion) .. " tastefully arranged " .. df.building_type [emotion.subthought] .. "."  --  DONE
    
  elseif emotion.thought == df.unit_thought_type.AdmireOwnArrangedBuilding then
    return "near " .. possessive .. " own " .. building_quality_of (emotion) .. " tastefully arranged " .. df.building_type [emotion.subthought] .. "."  --  DONE

  elseif emotion.thought == df.unit_thought_type.GhostNightmare then
    --### Note that the supposed value of 0 = Pet did not work. Tested 0 - 20.
    
    if emotion.subthought == 1 then
      return "after being tormented in nightmares by a dead spouse."

    elseif emotion.subthought == 2 then
      return "after being tormented in nightmares by " .. possessive .. " own dead mother."
    
    elseif emotion.subthought == 3 then
      return "after being tormented in nightmares by " .. possessive .. " own dead father."
    
    elseif emotion.subthought == 9 then
      return "after being tormented in nightmares by a dead lover."
    
    elseif emotion.subthought == 11 then
      return "after being tormented in nightmares by a dead sibling."
    
    elseif emotion.subthought == 12 then
      return "after being tormented in nightmares by " .. possessive .. " own dead child."
    
    elseif emotion.subthought == 13 then
      return "after being tormented in nightmares by a dead friend."
    
    elseif emotion.subthought == 14 then
      return "after being tormented in nightmares by a dead and still annoying acquaintance."
    
    elseif emotion.subthought == 18 then
      return "after being tormented in nightmares by a dead animal training partner."
    
    else
      dfhack.printerr ("Unhandled GhostNightmare subthought encountered " ..  tostring (emotion.subthought))
      return "after being tormented in nightmares by the dead."
     end
    
  elseif emotion.thought == df.unit_thought_type.GhostHaunt then
    --### Note that the supposed value of 0 = Pet did not work. Tested 0 plus the ones listed.
    local haunt_type = ""
    
    if emotion.severity == 0 then
      haunt_type = "haunted"
      
    elseif emotion.severity == 1 then
      haunt_type = "tormented"
      
    elseif emotion.severity == 2 then
      haunt_type = "possessed"
      
    elseif emotion.severity == 3 then
      haunt_type = "tortured"
      
    else
      dfhack.printerr ("Unhandled GhostNightmare severity encountered " ..  tostring (emotion.severity))
    end
    
    if emotion.subthought == 1 then
      return "after being " .. haunt_type .. " by a dead spouse."

    elseif emotion.subthought == 2 then
      return "after being " .. haunt_type .. " by " .. possessive .. " own dead mother."
    
    elseif emotion.subthought == 3 then
      return "after being " .. haunt_type .. " by " .. possessive .. " own dead father."
    
    elseif emotion.subthought == 9 then
      return "after being " .. haunt_type .. " by a dead lover."
    
    elseif emotion.subthought == 11 then
      return "after being " .. haunt_type .. " by a dead sibling."
    
    elseif emotion.subthought == 12 then
      return "after being " .. haunt_type .. " by " .. possessive .. " own dead child."
    
    elseif emotion.subthought == 13 then
      return "after being " .. haunt_type .. " by a dead friend."
    
    elseif emotion.subthought == 14 then
      return "after being " .. haunt_type .. " by a dead and still annoying acquaintance."
    
    elseif emotion.subthought == 18 then
      return "after being " .. haunt_type .. " by a dead animal training partner."
    
    else
      dfhack.printerr ("Unhandled GhostNightmare subthought encountered " ..  tostring (emotion.subthought))
      return "after being " .. haunt_type .. " by the dead."
    end
    
  elseif emotion.thought == df.unit_thought_type.UnableComplain then
    --### Only tested the ones listed.
    if emotion.subthought == 25 then
      return "after being unable to find somebody to complain to about job scarcity."
      
    elseif emotion.subthought == 26 then
      return "after being unable to make suggestions about work allocations."
      
    elseif emotion.subthought == 27 then
      return "after being unable to request weapon production."
      
    elseif emoton.subthought == 28 then
      return "after being unable to find somebody in charge to yell at."
      
    elseif emotion.subthought == 29 then
      return "after being unable to find somebody in charge to cry on."
      
    else
      dfhack.printerr ("Unhandled UnableComplain subthought encountered " ..  tostring (emotion.subthought))
    end
    
  elseif emotion.thought == df.unit_thought_type.SleepNoise then
    --### Only tested 0 - 4. Note mismatch with df.unit-thoughts.xml at the time of this writing (0 - 2 used, but same values)
    if emotion.severity == 1 then
      return "after sleeping uneasily due to noise."
      
    elseif emotion.severity == 2 then
      return "after being disturbed during sleep by loud noises."
      
    elseif emotion.severity == 3 then
      return "after loud noises made it impossible to sleep."
      
    else
      dfhack.printerr ("Unhandled SleepNoise severity encountered " ..  tostring (emotion.severity))
    end
    
  elseif emotion.thought == df.unit_thought_type.GoodMeal then  --  DONE
    return "after having a " ..  food_quality_of (emotion) .. " meal."   --  severity = food quality
    
  elseif emotion.thought == df.unit_thought_type.GoodDrink then -- DONE type: CONTENTMENT, unk2: 0, strength: 0, subthought: -1, severity: 1, flags: fftf, unk7: 0
    return "after having a " ..  food_quality_of (emotion) .. " drink."  --  severity = food quality
    
  elseif emotion.thought == df.unit_thought_type.RoomPretension then
    --###  Only tested -1 - 4. Severity doesn't seem to have any effect.
    local room = ""
    
    if emotion.subthought == 0 then
      room = "office "
      
    elseif emotion.subthought == 1 then
      room = "sleeping "
      
    elseif emotion.subthought == 2 then
      room = "dining "
      
    elseif emotion.subthought == 3 then
      room = "burial "
      
    else
       dfhack.printerr ("Unhandled RoomPretension subthought encountered " ..  tostring (emotion.subthought))
    end
    
    return "by a lesser's pretentious " .. room .. "arrangements."
    
  elseif emotion.thought == df.unit_thought_type.DiningQuality then
    return "dining in a " .. dining_room_quality_of (emotion)
    
  elseif emotion.thought == df.unit_thought_type.AnnoyedVermin then -- DONE type: ANNOYANCE, unk2: 0, strength: 0, subthought: 528, severity: 0, flags: fftf, unk7: 0
    return "after being accosted by " .. df.global.world.raws.creatures.all [emotion.subthought].name [1] .. "."  --  subthought = creature.all id

  elseif emotion.thought == df.unit_thought_type.NearVermin then
    return "after being near " .. df.global.world.raws.creatures.all [emotion.subthought].name [1] .. "."  --  subthought = creature.all id
    
  elseif emotion.thought == df.unit_thought_type.PesteredVermin then -- DONE type: DISTRESS, unk2: 0, strength: 0, subthought: 477, severity: 0, flags: fftf, unk7: 0
    return "after being pestered by " .. df.global.world.raws.creatures.all [emotion.subthought].name [1] .. "."  --  subthought = creature.all id
    
  elseif emotion.thought == df.unit_thought_type.AttackedByDead then
    return caption  --### [HF relative]
    
  elseif emotion.thought == df.unit_thought_type.NearCaged or
       emotion.thought == df.unit_thought_type.NearCagedHated then
    return "after being near to a " .. df.global.world.raws.creatures.all [emotion.subthought].name [0] .. " in a cage."  --  subthought = creature.all id
    
  elseif emotion.thought == df.unit_thought_type.BedroomQuality then -- DONE type: CONTENTMENT, unk2: 0, strength: 0, subthought: -1, severity: 5, flags: fftf, unk7: 0
    return "after sleeping in a " ..  bedroom_quality_of (emotion)  --  severity = bedroom quality

  elseif emotion.thought == df.unit_thought_type.GaveBirth then  -- DONE: type: ADORATION, unk2: 0, strength: 0, subthought: -1, severity: 3, flags: ffff, unk7: 0
                                                                 --  subthought = girl/boy, else child
                                                                 --  severity = #children. Boy/girl only for 1.
    local offspring = ""
    
    if emotion.severity == 1 then
      if emotion.subthought == 0 then
        offspring = "a girl"
      
      elseif emotion.subthought == 1 then
        offspring = "a boy"
      
      else
        offspring = "a child"
      end
    
    elseif emotion.severity == 2 then
      offspring = "twins"
    
    elseif emotion.severity == 3 then
      offspring = "triplets"
      
    elseif emotion.severity == 4 then
      offspring = "quadruplets"
      
    elseif emotion.severity == 5 then 
      offspring = "quintuplets"
      
    elseif emotion.severity == 6 then
      offspring = "sextuplets"
      
    elseif emotion.severity == 7 then
      offspring = "septuplets"
      
    elseif emotion.severity == 8 then
      offspring = "octuplets"
      
    elseif emotion.severity == 9 then
      offspring = "nonuplets"
      
    elseif emotion.severity == 10 then
      offspring = "decaplets"
      
    elseif emotion.severity == 11 then
      offspring = "undecaplets"
      
    elseif emotion.severity == 12 then
      offspring = "duodecaplets"
      
    elseif emotion.severity == 13 then
      offspring = "tredecaplets"
      
    elseif emotion.severity == 14 then
      offspring = "quattuodecaplets"
      
    elseif emotion.severity == 15 then
      offspring = "quindecaplets"
      
    else
      offspring = "many babies"
    end
    
    return "after giving birth to " .. offspring .. "."
    
  elseif emotion.thought == df.unit_thought_type.SpouseGaveBirth then -- DONE: type: LOVE, unk2: 0, strength: 0, subthought: 11, severity: 1, flags: ffff, unk7: 0
    if emotion.subthought == 1 then
      return "while getting married."  --### Different tense when the feeling grows older?
     
    elseif emotion.subthought == 11 then
      if emotion.severity == 1 then
        return "after gaining a sibling."
        
      else
        return "after gaining siblings."
      end
      
    elseif emotion.subthought == 12 then
      local offspring
      
      if emotion.severity == 1 then
        offspring = "a child"
    
      elseif emotion.severity == 2 then
        offspring = "twins"
    
      elseif emotion.severity == 3 then
        offspring = "triplets"
      
      elseif emotion.severity == 4 then
        offspring = "quadruplets"
      
      elseif emotion.severity == 5 then 
        offspring = "quintuplets"
      
      elseif emotion.severity == 6 then
        offspring = "sextuplets"
      
      elseif emotion.severity == 7 then
        offspring = "septuplets"
      
      elseif emotion.severity == 8 then
        offspring = "octuplets"
      
      elseif emotion.severity == 9 then
        offspring = "nonuplets"
      
      elseif emotion.severity == 10 then
        offspring = "decaplets"
      
      elseif emotion.severity == 11 then
        offspring = "undecaplets"
      
      elseif emotion.severity == 12 then
        offspring = "duodecaplets"
      
      elseif emotion.severity == 13 then
        offspring = "tredecaplets"
      
      elseif emotion.severity == 14 then
        offspring = "quattuodecaplets"
      
      elseif emotion.severity == 15 then
        offspring = "quindecaplets"
      
      else
        offspring = "many babies"
      end
      
      return "after becoming a parent of " .. offspring .. "."
    
    else
      dfhack.printerr ("Unhandled SpouseGaveBirth subthought encountered " ..  tostring (emotion.subthought))   
      return "."
    end    
    
  elseif emotion.thought == df.unit_thought_type.Talked then -- DONE type: FONDNESS, unk2: 0, strength: 0, subthought: 13, severity: 0, flags: fftf, unk7: 0
    return "talking with a " .. string.lower (df.unit_relationship_type [emotion.subthought]) .. "."  --  subthought = df.unit_relationship_type
    
  elseif emotion.thought == df.unit_thought_type.OfficeQuality then -- DONE type: SATISFACTION, unk2: 0, strength: 0, subthought: -1, severity: 5, flags: fftf, unk7: 0
    return "conducted a meeting in a " .. office_quality_of (emotion)  --  severity = office quality
    
  elseif emotion.thought == df.unit_thought_type.TombQuality then
    return "having a " .. tomb_quality_of (emotion) .. "tomb after gaining another year."
         
  elseif emotion.thought == df.unit_thought_type.WearItem then -- type: DONE CONTENTMENT, unk2: 0, strength: 0, subthought: -1, severity: 1, flags: fftf, unk7: 0
    return "after putting on a " ..  quality_of (emotion) .. " item."  --  severity = item quality
    
  elseif emotion.thought == df.unit_thought_type.Decay then
    --### Merge with the other cases of usage of the same type?
    local relation = ""
    if emotion.subthought == 1 then
      relation = "a spouse"
      
    elseif emotion.subthought == 2 then
      relation = "a mother"
      
    elseif emotion.subthought == 3 then
      relation = "a father"
      
    elseif emotion.subthought == 9 then
      relation = "a lover"
      
    elseif emotion.subthought == 11 then
      relation = "a sibling"
      
    elseif emotion.subthought == 12 then
      relation = "a child"
      
    elseif emotion.subthought == 13 then
      relation = "a friend"
      
    elseif emotion.subthought == 14 then
      relation = "an annoying acquaintance"
      
    elseif emotion.subthought == 18 then
      relation = "an animal training partner"
    end
    
    return "after being forced to endure the decay of " .. relation .. "."
     
  elseif emotion.thought == df.unit_thought_type.NeedsUnfulfilled then
    if emotion.subthought == df.need_type.Socialize then
      return "after being away from people for too long."
      
    elseif emotion.subthought == df.need_type.DrinkAlcohol then
      return "after being kept from alcohol for too long."
      
    elseif emotion.subthought == df.need_type.PrayOrMedidate then
      if emotion.severity ~= -1 then
        for i, hf in ipairs (df.global.world.history.figures) do
          if hf.id == emotion.severity then
            return "after being unable to pray to " .. dfhack.TranslateName (hf.name, true) .. " for too long."
          end
        end
        
      else
        return "after being unable to pray for too long."
      end
            
    elseif emotion.subthought == df.need_type.StayOccupied then
      return "after being unoccupied for too long."
      
    elseif emotion.subthought == df.need_type.BeCreative then
      return "after doing nothing creative for so long."
      
    elseif emotion.subthought == df.need_type.Excitement then
      return "after leading an unexciting life for so long."
      
    elseif emotion.subthought == df.need_type.LearnSomething then
      return "after not learning anything for so long."
      
    elseif emotion.subthought == df.need_type.BeWithFamily then
      return "after being away from family for too long."
      
    elseif emotion.subthought == df.need_type.BeWithFriends then
      return "after being away from friends for too long."
      
    elseif emotion.subthought == df.need_type.HearEloquence then
      return "after being unable to hear eloquent speech for so long."
      
    elseif emotion.subthought == df.need_type.UpholdTradition then
      return "after being away from traditions for too long."
      
    elseif emotion.subthought == df.need_type.SelfExamination then
      return "after a lack of introspection for too long."
      
    elseif emotion.subthought == df.need_type.MakeMerry then
      return "after being unable to make merry for son long."
      
    elseif emotion.subthought == df.need_type.CraftObject then
      return "after being unable to practice a craft for too long."
      
    elseif emotion.subthought == df.need_type.MartialTraining then
      return "after being unable to practice a martial art for too long."
      
    elseif emotion.subthought == df.need_type.PracticeSkill then
      return "after being unable to practice a skill for too long."
      
    elseif emotion.subthought == df.need_type.TakeItEasy then
      return "after being unable to take it easy for so long."
      
    elseif emotion.subthought == df.need_type.MakeRomance then
      return "after being unable to make romance for so long."
      
    elseif emotion.subthought == df.need_type.SeeAnimal then
      return "after being away from animals for so long."
      
     elseif emotion.subthought == df.need_type.SeeGreatBeast then
      return "after being away from great beasts for so long."
      
    elseif emotion.subthought == df.need_type.AcquireObject then
      return "after being unable to acquire something for too long."
      
    elseif emotion.subthought == df.need_type.EatGoodMeal then
      return "after a lack of decent meals for too long."
      
    elseif emotion.subthought == df.need_type.Fight then
      return "after being unable to fight for too long."
      
    elseif emotion.subthought == df.need_type.CauseTrouble then
      return "after a lack of trouble-making for too long."
      
    elseif emotion.subthought == df.need_type.Argue then
      return "after being unable to argue for too long."
      
    elseif emotion.subthought == df.need_type.BeExtravagant then
      return "after being unable to be extravagant for so long."
      
    elseif emotion.subthought == df.need_type.Wander then
      return "after being unable to wander for too long."
      
    elseif emotion.subthought == df.need_type.HelpSomebody then
      return "after being unable to help anybody for too long."
      
    elseif emotion.subthought == df.need_type.ThinkAbstractly then
      return "after a lack of abstract thinking for too long."
      
    elseif emotion.subthought == df.need_type.AdmireArt then
      return "after being unable to admire art for so long."
      
    else
      dfhack.printerr ("Unidentified Need subthought " .. tostring (emotion.subthought))
      return caption
    end
    
  elseif emotion.thought == df.unit_thought_type.Prayer then -- type: RAPTURE, unk2: 71, strength: 100, subthought: 266, severity: 0, flags: fftf, unk7: 0
    for i, hf in ipairs (df.global.world.history.figures) do
      if hf.id == emotion.subthought then
        return "after communing with " .. dfhack.TranslateName (hf.name, true) .. "."  --  subthought = hf. unk2 = TBD strength = TBD
      end
    end
    
  elseif emotion.thought == df.unit_thought_type.ResearchBreakthrough then
    return "after making a breakthrough concerning ".. get_topic (emotion) .. "."  --  subthought/severity = table lookup

  elseif emotion.thought == df.unit_thought_type.ResearchStalled then
    return "after being unable to advance the study of ".. get_topic (emotion) .. "."  --  subthought/severity = table lookup

  elseif emotion.thought == df.unit_thought_type.PonderTopic then  -- DONE type: INTEREST, unk2: 0, strength: 0, subthought: 12, severity: 10, flags: fftf, unk7: 0
    return "after pondering " .. get_topic (emotion) .. "."  --  subthought/severity = table lookup

  elseif emotion.thought == df.unit_thought_type.DiscussTopic then
    return "after discussing " .. get_topic (emotion) .. "."  --  subthought/severity = table lookup
    
  elseif emotion.thought == df.unit_thought_type.Syndrome then -- type: EUPHORIA, unk2: 0, strength: 0, subthought: 70, severity: 59, flags: fftf, unk7: 0
    return "due to " .. df.global.world.raws.syndromes.all [emotion.subthought].syn_name .. "."  --###  subthought = raw.syndrome.all reference, severity = TBD
      
  elseif emotion.thought == df.unit_thought_type.LearnTopic then -- DONE type: SATISFACTION, unk2: 0, strength: 0, subthought: 5, severity: 4, flags: fftf, unk7: 0
    return "after learning about " .. get_topic (emotion) .. "."  --  subthought/severity = table lookup
    
  elseif emotion.thought == df.unit_thought_type.TeachTopic then
    return "after teaching " .. get_topic (emotion) .. "."  --  subthought/severity = table lookup

  elseif emotion.thought == df.unit_thought_type.LearnSkill then
    return "after learning about " .. string.lower (df.job_skill [emotion.subthought]) .. "."
    
  elseif emotion.thought == df.unit_thought_type.TeachSkill then
    return "after teaching " .. string.lower (df.job_skill [emotion.subthought]) .. "."
    
  elseif emotion.thought == df.unit_thought_type.ImproveSkill then -- DONE type: SATISFACTION, unk2: 0, strength: 0, subthought: 10, severity: 0, flags: fftf, unk7: 0
    return "upon improving " .. string.lower (df.job_skill [emotion.subthought]) .. "."  --  subthought = df.job_skill
    
  elseif emotion.thought == df.unit_thought_type.LearnBook then -- DONE type: SATISFACTION, unk2: 0, strength: 0, subthought: 194395, severity: 0, flags: fftf, unk7: 0
    return "after learning " .. df.global.world.written_contents.all [emotion.subthought].title .. "."  --  subthought = written contents.all reference
    
  elseif emotion.thought == df.unit_thought_type.ReadBook then  -- DONE type: SATISFACTION, unk2: 0, strength: 0, subthought: 194395, severity: 0, flags: fftf, unk7: 0
    return "after reading " .. df.global.world.written_contents.all [emotion.subthought].title .. "."  --  subthought = written contents.all reference
    
  elseif emotion.thought == df.unit_thought_type.WriteBook then
    return "after writing " .. df.global.world.written_contents.all [emotion.subthought].title .. "."

  elseif emotion.thought == df.unit_thought_type.LearnInteraction then  -- Subthought = df.global.world.raws.interactions id
    if #df.global.world.raws.interactions [emotion.subthought].sources > 0 then
      return "after learning " .. df.global.world.raws.interactions [emotion.subthought].sources [0].name .."."
      
    else
      return "after learning powerful secrets."
    end
    
  elseif emotion.thought == df.unit_thought_type.LearnPoetry then  --  df.global.world.poetic_forms.all id
    return "after learning " .. dfhack.TranslateName (df.poetic_form.find (emotion.subthought).name, true) .. "."
    
  elseif emotion.thought == df.unit_thought_type.LearnMusic then  --  df.global.world.musical_form.all id
    return "after learning " .. dfhack.TranslateName (df.musical_form.find (emotion.subthought).name, true) .. "."
    
  elseif emotion.thought == df.unit_thought_type.LearnDance then
    return "after learning " .. dfhack.TranslateName (df.dance_form.find (emotion.subthought).name, true) .. "."
    
  elseif emotion.thought == df.unit_thought_type.PlayToy then -- DONE type: ENJOYMENT, unk2: 0, strength: 0, subthought: 0, severity: 0, flags: fftf, unk7: 0
    return "after playing with a " .. df.global.world.raws.itemdefs.toys [emotion.subthought].name .. "." --  subthought = raw.itemdefs.toys reference
    
  elseif emotion.thought == df.unit_thought_type.RealizeValue then  -- DONE type: SATISFACTION, unk2: 0, strength: 0, subthought: 6, severity: 29, flags: fftf, unk7: 0
    local level
    
    if emotion.severity < -10 then
      level = "the worthlessness"
      
    elseif emotion.severity > 10 then
      level = "the value"
    else
      level = "nuances"
    end
    
    return "after realizing " .. level .. " of " .. df.value_type [emotion.subthought]:lower ()  --  subthought = df.value_type, severity = strength of the value, (neg < -10 <= neut <= 10 > pos
    
  elseif emotion.thought == df.unit_thought_type.Conflict or -- type: TERROR, unk2: 100, strength: 100, subthought: -1, severity: 0, flags: ffff, unk7: 127
         emotion.thought == df.unit_thought_type.Trauma or -- type: FEAR, unk2: 100, strength: 100, subthought: -1, severity: 0, flags: tftf, unk7: 123
         emotion.thought == df.unit_thought_type.Death or -- type: GRIEF, unk2: 0, strength: 0, subthought: 94110, severity: 0, flags: fftf, unk7: 0. subthought = HF id?
         emotion.thought == df.unit_thought_type.Kill or  --###
         emotion.thought == df.unit_thought_type.LoveSeparated or --###
         emotion.thought == df.unit_thought_type.LoveReunited or --###
         emotion.thought == df.unit_thought_type.JoinConflict or -- type: VENGEFULNESS, unk2: 100, strength: 100, subthought: 62737, severity: 0, flags: fftf, unk7: 0. subthought = HF id?
         emotion.thought == df.unit_thought_type.MakeMasterwork or -- type: SATISFACTION, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fttf, unk7: 0
         emotion.thought == df.unit_thought_type.MadeArtifact or  --### Works without parameters
         emotion.thought == df.unit_thought_type.NewRomance or  --### Works without parameters
         emotion.thought == df.unit_thought_type.BecomeParent or -- type: BLISS, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: ffff, unk7: 0
         emotion.thought == df.unit_thought_type.NearConflict or  --### Works without parameters
         emotion.thought == df.unit_thought_type.CancelAgreement or  --### Works without parameters
         emotion.thought == df.unit_thought_type.JoinTravel or  --### ditto
         emotion.thought == df.unit_thought_type.SiteControlled or --### ditto
         emotion.thought == df.unit_thought_type.TributeCancel or --### ditto
         emotion.thought == df.unit_thought_type.Incident or  --### ditto
         emotion.thought == df.unit_thought_type.HearRumor or  --### ditto
         emotion.thought == df.unit_thought_type.MilitaryRemoved or  --### ditto
         emotion.thought == df.unit_thought_type.StrangerWeapon or  --### ditto
         emotion.thought == df.unit_thought_type.StrangerSneaking or  --### ditto
         emotion.thought == df.unit_thought_type.SawDrinkBlood or  --### ditto
         emotion.thought == df.unit_thought_type.LostPet or  --### ditto
         emotion.thought == df.unit_thought_type.ThrownStuff or  --### ditto
         emotion.thought == df.unit_thought_type.JailReleased or -- type: FREEDOM, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: ffff, unk7: 0
         emotion.thought == df.unit_thought_type.Miscarriage or  --### ditto
         emotion.thought == df.unit_thought_type.SpouseMiscarriage or  --### ditto
         emotion.thought == df.unit_thought_type.OldClothing or -- type: IRRITATION, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
         emotion.thought == df.unit_thought_type.TatteredClothing or -- type: BITTERNESS, unk2: 100, strength: 100, subthought: -1, severity: 0, flags: ffff, unk7: 0
         emotion.thought == df.unit_thought_type.RottedClothing or  --### ditto
         emotion.thought == df.unit_thought_type.Spar or --### ditto
         emotion.thought == df.unit_thought_type.LongPatrol or  --  ### ditto
         emotion.thought == df.unit_thought_type.SunNausea or -- type: HOPELESSNESS, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
         emotion.thought == df.unit_thought_type.SunIrritated or -- type: ANNOYANCE, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
         emotion.thought == df.unit_thought_type.Drowsy or -- type: IRRITATION, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
         emotion.thought == df.unit_thought_type.VeryDrowsy or  --### ditto
         emotion.thought == df.unit_thought_type.Thirsty or  --### ditto
         emotion.thought == df.unit_thought_type.Dehydrated or --###  ditto
         emotion.thought == df.unit_thought_type.Hungry or -- type: IRRITATION, unk2: 10, strength: 10, subthought: -1, severity: 0, flags: ffff, unk7: 0
         emotion.thought == df.unit_thought_type.Starving or -- type: PANIC, unk2: 100, strength: 100, subthought: -1, severity: 0, flags: ffff, unk7: 0
         emotion.thought == df.unit_thought_type.MajorInjuries or -- type: SHAKEN, unk2: 100, strength: 100, subthought: -1, severity: 0, flags: fftf, unk7: 68
         emotion.thought == df.unit_thought_type.MinorInjuries or -- type: ANNOYANCE, unk2: 10, strength: 10, subthought: -1, severity: 0, flags: fftf, unk7: 0
         emotion.thought == df.unit_thought_type.Rest or  --  ### Ditto
         emotion.thought == df.unit_thought_type.FreakishWeather or  --### ditto
         emotion.thought == df.unit_thought_type.Rain or -- type: DEJECTION, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
         emotion.thought == df.unit_thought_type.SnowStorm or --### ditto
         emotion.thought == df.unit_thought_type.Miasma or -- type: DISGUST, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: ffff, unk7: 0
         emotion.thought == df.unit_thought_type.Smoke or -- type: ANNOYANCE, unk2: 100, strength: 100, subthought: -1, severity: 0, flags: ffff, unk7: 0
         emotion.thought == df.unit_thought_type.Waterfall or  --### ditto
         emotion.thought == df.unit_thought_type.Dust or -- type: ANNOYANCE, unk2: 80, strength: 80, subthought: -1, severity: 0, flags: ffff, unk7: 0
         emotion.thought == df.unit_thought_type.Demands or  --### ditto
         emotion.thought == df.unit_thought_type.ImproperPunishment or  --### ditto
         emotion.thought == df.unit_thought_type.PunishmentReduced or --### ditto
         emotion.thought == df.unit_thought_type.Elected or  --### ditto
         emotion.thought == df.unit_thought_type.Reelected or --### ditto
         emotion.thought == df.unit_thought_type.RequestApproved or  --### ditto
         emotion.thought == df.unit_thought_type.RequestIgnored or  --### ditto
         emotion.thought == df.unit_thought_type.NoPunishment or  --### ditto
         emotion.thought == df.unit_thought_type.PunishmentDelayed or  --### ditto
         emotion.thought == df.unit_thought_type.DelayedPunishment or --### ditto
         emotion.thought == df.unit_thought_type.ScarceCageChain or  --### ditto
         emotion.thought == df.unit_thought_type.MandateIgnored or  --### ditto
         emotion.thought == df.unit_thought_type.MandateDeadlineMissed or --### ditto
         emotion.thought == df.unit_thought_type.LackWork or  --### ditto
         emotion.thought == df.unit_thought_type.SmashedBuilding or  --### ditto
         emotion.thought == df.unit_thought_type.ToppledStuff or  --### ditto
         emotion.thought == df.unit_thought_type.NoblePromotion or  --### ditto
         emotion.thought == df.unit_thought_type.BecomeNoble or  --### ditto
         emotion.thought == df.unit_thought_type.Cavein or  --### ditto
         emotion.thought == df.unit_thought_type.MandateDeadlineMet or  --### ditto
         emotion.thought == df.unit_thought_type.Uncovered or  --###  ditto
         emotion.thought == df.unit_thought_type.NoShirt or --### ditto
         emotion.thought == df.unit_thought_type.NoShoes or  --### ditto
         emotion.thought == df.unit_thought_type.EatPet or  --### ditto
         emotion.thought == df.unit_thought_type.EatLikedCreature or --### ditto
         emotion.thought == df.unit_thought_type.EatVermin or  --### ditto
         emotion.thought == df.unit_thought_type.FistFight or  --### ditto
         emotion.thought == df.unit_thought_type.GaveBeating or --### ditto
         emotion.thought == df.unit_thought_type.GotBeaten or  --### ditto
         emotion.thought == df.unit_thought_type.GaveHammering or --### ditto
         emotion.thought == df.unit_thought_type.GotHammered or  --### ditto
         emotion.thought == df.unit_thought_type.NoHammer or  --### ditto
         emotion.thought == df.unit_thought_type.SameFood or  --### ditto
         emotion.thought == df.unit_thought_type.AteRotten or  --### ditto
         emotion.thought == df.unit_thought_type.MoreChests or  --### ditto
         emotion.thought == df.unit_thought_type.MoreCabinets or --### ditto
         emotion.thought == df.unit_thought_type.MoreWeaponRacks or --### ditto
         emotion.thought == df.unit_thought_type.MoreArmorStands or  --### ditto
         emotion.thought == df.unit_thought_type.LackTables or  --### ditto
         emotion.thought == df.unit_thought_type.CrowdedTables or  --### ditto
         emotion.thought == df.unit_thought_type.NoDining or  -- ### Ditto
         emotion.thought == df.unit_thought_type.LackChairs or  --### ditto
         emotion.thought == df.unit_thought_type.TrainingBond or -- type: AFFECTION, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
         emotion.thought == df.unit_thought_type.Rescued or  --### ditto
         emotion.thought == df.unit_thought_type.RescuedOther or  --### ditto
         emotion.thought == df.unit_thought_type.SatisfiedAtWork or  --  subthought ignored mostly. Not "slaughter an animal" -- type: SATISFACTION, unk2: 0, strength: 0, subthought: 105, severity: 0, flags: fftf, unk7: 0
         emotion.thought == df.unit_thought_type.TaxedLostProperty or --###
         emotion.thought == df.unit_thought_type.Taxed or
         emotion.thought == df.unit_thought_type.LackProtection or
         emotion.thought == df.unit_thought_type.TaxRoomUnreachable or
         emotion.thought == df.unit_thought_type.TaxRoomMisinformed or
         emotion.thought == df.unit_thought_type.PleasedNoble or
         emotion.thought == df.unit_thought_type.TaxCollectionSmooth or
         emotion.thought == df.unit_thought_type.DisappointedNoble or
         emotion.thought == df.unit_thought_type.TaxCollectionRough or
         emotion.thought == df.unit_thought_type.MadeFriend or -- type: FONDNESS, unk2: 0, strength: 0, subthought: 102208, severity: 0, flags: fftf, unk7: 0. subthought = HF id?
         emotion.thought == df.unit_thought_type.FormedGrudge or
         emotion.thought == df.unit_thought_type.AcquiredItem or -- type: PLEASURE, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
         emotion.thought == df.unit_thought_type.AdoptedPet or
         emotion.thought == df.unit_thought_type.Jailed or -- type: ANGER, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: ffff, unk7: 0
         emotion.thought == df.unit_thought_type.Bath or -- type: BLISS, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: ffff, unk7: 0
         emotion.thought == df.unit_thought_type.SoapyBath or
         emotion.thought == df.unit_thought_type.SparringAccident or
         emotion.thought == df.unit_thought_type.Attacked or -- type: SHOCK, unk2: 50, strength: 50, subthought: -1, severity: 0, flags: ffff, unk7: 53
         emotion.thought == df.unit_thought_type.SameBooze or
         emotion.thought == df.unit_thought_type.DrinkBlood or
         emotion.thought == df.unit_thought_type.DrinkSlime or
         emotion.thought == df.unit_thought_type.DrinkVomit or
         emotion.thought == df.unit_thought_type.DrinkGoo or
         emotion.thought == df.unit_thought_type.DrinkIchor or
         emotion.thought == df.unit_thought_type.DrinkPus or
         emotion.thought == df.unit_thought_type.NastyWater or
         emotion.thought == df.unit_thought_type.DrankSpoiled or
         emotion.thought == df.unit_thought_type.LackWell or
         emotion.thought == df.unit_thought_type.LackBedroom or
         emotion.thought == df.unit_thought_type.SleptFloor or
         emotion.thought == df.unit_thought_type.SleptMud or
         emotion.thought == df.unit_thought_type.SleptGrass or
         emotion.thought == df.unit_thought_type.SleptRoughFloor or
         emotion.thought == df.unit_thought_type.SleptRocks or
         emotion.thought == df.unit_thought_type.SleptIce or
         emotion.thought == df.unit_thought_type.SleptDirt or
         emotion.thought == df.unit_thought_type.SleptDriftwood or
         emotion.thought == df.unit_thought_type.ArtDefacement or
         emotion.thought == df.unit_thought_type.Evicted or
         emotion.thought == df.unit_thought_type.ReceivedWater or
         emotion.thought == df.unit_thought_type.GaveWater or
         emotion.thought == df.unit_thought_type.ReceivedFood or -- type: SATISFACTION, unk2: 100, strength: 100, subthought: -1, severity: 0, flags: ffff, unk7: 0
         emotion.thought == df.unit_thought_type.GaveFood or
         emotion.thought == df.unit_thought_type.MeetingInBedroom or
         emotion.thought == df.unit_thought_type.MeetingInDiningRoom or
         emotion.thought == df.unit_thought_type.NoRooms or
         emotion.thought == df.unit_thought_type.TombLack or
         emotion.thought == df.unit_thought_type.TalkToNoble or
         emotion.thought == df.unit_thought_type.InteractPet or -- type: FONDNESS, unk2: 0, strength: 0, subthought: 171, severity: 0, flags: fftf, unk7: 0. subthought = creatures.all id?
         emotion.thought == df.unit_thought_type.ConvictionCorpse or
         emotion.thought == df.unit_thought_type.ConvictionAnimal or
         emotion.thought == df.unit_thought_type.ConvictionVictim or
         emotion.thought == df.unit_thought_type.ConvictionJusticeSelf or
         emotion.thought == df.unit_thought_type.ConvictionJusticeFamily or
         emotion.thought == df.unit_thought_type.DrinkWithoutCup or
         emotion.thought == df.unit_thought_type.Perform or -- type: ENJOYMENT, unk2: 0, strength: 0, subthought: 3815, severity: 0, flags: fftf, unk7: 0
         emotion.thought == df.unit_thought_type.WatchPerform or -- type: INTEREST, unk2: 0, strength: 0, subthought: 3723, severity: 0, flags: fftf, unk7: 0
         emotion.thought == df.unit_thought_type.RemoveTroupe or
         emotion.thought == df.unit_thought_type.BecomeResident or
         emotion.thought == df.unit_thought_type.BecomeCitizen or
         emotion.thought == df.unit_thought_type.DenyResident or
         emotion.thought == df.unit_thought_type.DenyCitizen or
         emotion.thought == df.unit_thought_type.LeaveTroupe or
         emotion.thought == df.unit_thought_type.MakeBelieve or -- type: ENJOYMENT, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
         emotion.thought == df.unit_thought_type.anon_1 or -- N/A
         emotion.thought == df.unit_thought_type.anon_2 or -- N/A
         emotion.thought == df.unit_thought_type.anon_3 or -- N/A
         emotion.thought == df.unit_thought_type.Argument or -- type: BITTERNESS, unk2: 0, strength: 0, subthought: 99640, severity: 0, flags: fftf, unk7: 0. subthought = HF id?
         emotion.thought == df.unit_thought_type.CombatDrills or
         emotion.thought == df.unit_thought_type.ArcheryPractice or
         emotion.thought == df.unit_thought_type.OpinionStoryteller or  --### Requires parameters?
         emotion.thought == df.unit_thought_type.OpinionRecitation or  --### Requires parameters?
         emotion.thought == df.unit_thought_type.OpinionInstrumentSimulation or  --### Requires parameters?
         emotion.thought == df.unit_thought_type.OpinionInstrumentPlayer or  --### Requires parameters?
         emotion.thought == df.unit_thought_type.OpinionSinger or  --### Requires parameters?
         emotion.thought == df.unit_thought_type.OpinionChanter or  --### Requires parameters?
         emotion.thought == df.unit_thought_type.OpinionDancer or  --### Requires parameters?
         emotion.thought == df.unit_thought_type.OpinionStory or  --### Requires parameters?
         emotion.thought == df.unit_thought_type.OpinionPoetry or  --### Requires parameters?
         emotion.thought == df.unit_thought_type.OpinionMusic or  --### Requires parameters?
         emotion.thought == df.unit_thought_type.OpinionDance or  --### Requires parameters?
         
         emotion.thought == df.unit_thought_type.FavoritePossession or  --### Requires parameters?
         
         emotion.thought == df.unit_thought_type.HistEventCollection then  --### Requires parameters?
    return caption .. "." --  These don't have any (known displayed) subthought parameters
  
  elseif emotion.thought == df.unit_thought_type.Defeated then
    return "after defeating somebody"  --### Parameters?

  elseif emotion.thought == df.unit_thought_type.Murdered then
    return "after murdering somebody"  --### Parameters?
  
  elseif emotion.thought == df.unit_thought_type.ViewOwnDisplay then
    local artifact = df.artifact_record.find (emotion.subthought)
    local item = df.item.find (emotion.subthought)
    
    if artifact then
      return "after viewing " .. dfhack.TranslateName (artifact.name, false) .. " in a personal museum."
      
    elseif item then  --### figure out how to get a/an in before the item when needed. Also, what does the "type" parameter in getDescription do? Doesn't seem to have any effect?
      return "after viewing " .. dfhack.items.getDescription (item, 0) .. " in a personal museum."
    
    else
      return "after viewing a piece in a personal museum."
    end

  elseif emotion.thought == df.unit_thought_type.ViewDisplay then
    local artifact = df.artifact_record.find (emotion.subthought)
    local item = df.item.find (emotion.subthought)
    
    if artifact then
      return "after viewing " .. dfhack.TranslateName (artifact.name, false) .. " on display."  --### Probably DF bug to display native name here...
      
    elseif item then  --### figure out how to get a/an in before the item when needed. Also, what does the "type" parameter in getDescription do? Doesn't seem to have any effect?
      return "after viewing " .. dfhack.items.getDescription (item, 0) .. " on display."
    
    else
      return "after viewing a piece on display."
    end

  elseif emotion.thought == df.unit_thought_type.AcquireArtifact then
    local artifact = df.artifact_record.find (emotion.subthought)
    
    if artifact then
      return "after acquiring" .. dfhack.TranslateName (artifact.name, true) .. "."
    
    else
      return "after acquiring an unknown artifact."
    end
    
  elseif emotion.thought == df.unit_thought_type.DenySanctuary then
    return "after a child was turned away from sanctuary." --### Can have parameters?

  elseif emotion.thought == df.unit_thought_type.CaughtSneaking then
    return "after being caught sneaking."  --### Parameters?

  elseif emotion.thought == df.unit_thought_type.GaveArtifact then
    local artifact = df.artifact_record.find (emotion.subthought)
    
    if artifact then
      return "after " .. dfhack.TranslateName (artifact.name, true) .. " was given away."
    
    else
      return "after an unknown artifact was given away."
    end
   
  elseif emotion.thought == df.unit_thought_type.Defeated then
    return "after defeating somebody."  --### Parameters?
  else
    dfhack.printerr ("Unhandled thought encountered " ..  tostring (emotion.thought))
  end
end

------------------------------------------

function is_tense (emotion)
  if emotion.strength > 0 then
    return "is "
  else
    return "was "
  end
end

------------------------------------------

function feel_tense (emotion)
  if emotion.strength  > 0 then
    return "feels "
  else
    return "felt "
  end
end

------------------------------------------

function print_emotion_value (gender, emotion)
  local pronoun
  local base_color
  
  if gender == 1 then
    pronoun = "He "
  elseif gender == 0 then
    pronoun = "She "
  else
    pronoun = "It "
  end
  
  if emotion.strength > 0 then
    base_color = COLOR_WHITE
  else
    base_color = COLOR_GREY
  end
    
  dfhack.color (base_color)
  dfhack.print (pronoun)
  
  if (emotion.flags.unk3 and emotions [emotion.type] [2] ~= emotions [emotion.type] [2]:upper()) or --### To allow identification of correct strings when encountered
     emotion.type == df.emotion_type.ANYTHING then
    if emotion.strength > 0 then
      dfhack.print ("doesn't feel anything ")
    else
      dfhack.print ("didn't feel anything ")
    end
    
  else
    if emotions [emotion.type] [1] == nil then
      --  suppress the tense
      
    elseif emotions [emotion.type] [1] then
      dfhack.print (is_tense (emotion))
      
    else
      dfhack.print (feel_tense (emotion))
    end
    
    if emotions [emotion.type] [3] then
      dfhack.print (emotions [emotion.type] [3])
    end
    
    dfhack.color (df.emotion_type.attrs [emotion.type].color)
    dfhack.print (emotions [emotion.type] [2] .. " ")
  end
end

------------------------------------------

function print_emotion (gender, emotion)
  local pronoun
  local possessive
  
  if gender == 1 then
    pronoun = "he"
    possessive = "his"
    
  elseif gender == 0 then
    pronoun = "she"
    possessive = "her"
    
  else
    pronoun = "it"
    possessive = "its"
  end
  
  local base_color
  local base_caption = df.unit_thought_type.attrs [emotion.thought].caption
  local he_pos
  if base_caption then
    he_ois = base_caption:find ("[he]", 1, true)
  end
  local he_caption
  local his_caption
  
  if he_pos == nil then
    he_caption = base_caption
  else
    he_caption = base_caption:sub (1, he_pos - 1) .. pronoun .. base_caption:sub (he_pos + 4, base_caption:len())
  end
  
  local his_pos
  if base_caption then
    his_pos = he_caption:find ("[his]", 1, true)
  end
  
  if his_pos == nil then
    his_caption = he_caption
  else
    his_caption = he_caption:sub (1, his_pos - 1) .. possessive .. he_caption:sub (his_pos + 5, he_caption:len())
  end
    
  if emotion.strength > 0 then
    base_color = COLOR_WHITE
  else
    base_color = COLOR_GREY
  end
    
  print_emotion_value (gender, emotion)
  dfhack.color (base_color)
  dfhack.println (add_subthought (his_caption, emotion, pronoun, possessive))
end

------------------------------------------

function get_hf_name (id)
  local hf = df.historical_figure.find (id)

  if hf ~= nil then
    if hf.name.has_name then
      return dfhack.TranslateName (hf.name, true) .. "/" .. dfhack.TranslateName (hf.name, false) .. "/" .. tostring (hf_index)
    else
      return df.global.world.raws.creatures.all [hf.race].name [0]
    end
  
  else  
    return ""
  end
end

------------------------------------------

--  Verified with DFHacking
--
function worship_strength (strength)
  if strength < 10 then
    return tostring (strength) .. " dubious "
  elseif strength < 25 then
    return tostring (strength) .. " casual "
  elseif strength >= 90 then
    return tostring (strength) .. " ardent "
  elseif strength >= 75 then
    return tostring (strength) .. " faithful "
  else 
    return tostring (strength) .. " "
  end
end

------------------------------------------
--  Seems to match the sorting order. Note that only the values noted have actually been seen to have an effect.
--  "Supplemental" values can appear, such as 23, and friends seem to have 7 as a supplemental value for citizens,
--  while visitors have been observed to have friends both with and without a supplemental 7 (even the same citizen).
--
function friend_lt (f1, f2)
  local f1_relation_level = 3   --  Passing Acquaintance
  local f2_relation_level = 3
  
  if #f1.anon_3 > 0 then
    if f1.anon_3 [0] == 1 or    --  Friend
       f1.anon_3 [0] == 2 or    --  Grudge
       f1.anon_3 [0] == 3 then  --  Bonded
      f1_relation_level = 1     --  Friend/Grudge/Bonded
    
    elseif f1.anon_3 [0] == 7 then
      f1_relation_level = 2     --  Friendly Terms
    end
  end
  
  if #f2.anon_3 > 0 then
    if f2.anon_3 [0] == 1 or    --  Friend
       f2.anon_3 [0] == 2 or    --  Grudge
       f2.anon_3 [0] == 3 then  --  Bonded
      f2_relation_level = 1     --  Friend/Grudge/Bonded
      
    elseif f2.anon_3 [0] == 7 then
      f2_relation_level = 2     --  Friendly Terms
    end
  end
  
  if f1_relation_level > f2_relation_level then
    return true
  
  elseif f1_relation_level < f2_relation_level then
    return false
  end
  
  if f1_relation_level == 1 then  --  Friend/Grudge/Bonded
    return f1.histfig_id > f2.histfig_id
  end
  
  if f1.anon_5 == f2.anon_5 then
    return f1.histfig_id > f2.histfig_id
    
  else
    return f1.anon_5 < f2.anon_5
  end
end
 
------------------------------------------

function thoughts ()
  --  Sanity checks to see all cases are covered in case enums are extended.
  --
  for index, val in pairs (df.goal_type) do
    if not goals [index] then
      dfhack.printerr ("Missing goals element " .. df.goal_type [index])
    end
  end
  
  for index, val in pairs (df.value_type) do
    if not values [index] then
      dfhack.printerr ("Missing values element " .. df.value_type [index])
    end
  end
  
  for i = df.emotion_type._first_item, df.emotion_type._last_item do
    if df.emotion_type [i] ~= nil and
       emotions [i] == nil then
      dfhack.printerr ("Missing emotions element " .. df.emotion_type [i])
    end
  end
  
  ------------------------------------------
  
  local unit = dfhack.gui.getSelectedUnit (true)
  local max_emotion = -30000
  local min_emotion = 30000
  local printed_something
  local base_color
  local emotions = {}
  local emo
  local death_count = 0
  local mentioned_death = false
  local mother
  local father
  local spouse
  local children = {}
  local deities = {}
  local master
  local apprentices = {}
  local pronoun
  local Pronoun
  local possessive
  local child_type
  local friends = {}
  local temp
  local hf
  
  if unit.sex == 0 then
    pronoun = "she"
    Pronoun = "She"
    possessive = "her"
    child_type = "daughter"
    
  elseif unit.sex == 1 then
    pronoun = "he"
    Pronoun = "He"
    possessive = "his"
    child_type = "son"
    
  else
    pronoun = "it"
    Pronoun = "It"
    possessive = "its"
    child_type = "offspring"
  end
 
  if unit.status.current_soul then
    for i, emotion in ipairs (unit.status.current_soul.personality.emotions) do
      table.insert (emotions, emotion)
      if emotion.strength > max_emotion then
        max_emotion = emotion.strength
      end
    
      if emotion.strength < min_emotion then
        min_emotion = emotion.strength
      end
    
      if emotion.thought == df.unit_thought_type.WitnessDeath then
        death_count = death_count + 1
      end
    end
  end
  
  for i = 1, #emotions - 1 do
    for k = i + 1, #emotions do
      if (emotions [i].strength < emotions [k].strength) or
         ((emotions [i].strength == emotions [k].strength) and
          (emotions [i].year < emotions [k].year) or
           ((emotions [i].year == emotions [k].year) and
            (emotions [i].year_tick < emotions [k].year_tick))) then
        emo = emotions [i]
        emotions [i] = emotions [k]
        emotions [k] = emo
      end
    end
  end
  
  for i, emotion in ipairs (emotions) do
    if emotion.thought ~= - 1 then  --  Filter out null cases. Suspect deaths which can no longer be tracked.    
      if emotion.thought ~= df.unit_thought_type.WitnessDeath then
        print_emotion (unit.sex, emotion)
      
      elseif not mentioned_death then
        dfhack.print (tostring (death_count) .. " X ")
        print_emotion (unit.sex, emotion)      
        mentioned_death = true
      end
    end
  end
 
  --  Relations section
  dfhack.color (COLOR_LIGHTBLUE)
  
  hf = df.historical_figure.find (unit.hist_figure_id)
  if hf ~= nil then
    dfhack.println (hf_index)
            
    for i, histfig_link in ipairs (hf.histfig_links) do
      if histfig_link._type == df.histfig_hf_link_motherst then
        mother = get_hf_name (histfig_link.target_hf)
        if mother == "" then
          mother = nil
        end
          
      elseif histfig_link._type == df.histfig_hf_link_fatherst then
        father = get_hf_name (histfig_link.target_hf)
        if father == "" then
          father = nil
        end
          
      elseif histfig_link._type == df.histfig_hf_link_spousest then
        spouse = get_hf_name (histfig_link.target_hf)
        if spose == "" then
          spouse = nil
        end
        
      elseif histfig_link._type == df.histfig_hf_link_childst then
        table.insert (children, get_hf_name (histfig_link.target_hf))
        if children [#children] == "" then  --  Presumed dead culled HF
          table.remove (children, #children)
        end
          
      elseif histfig_link._type == df.histfig_hf_link_deityst then
        table.insert (deities, {get_hf_name (histfig_link.target_hf), histfig_link.link_strength})
        
      elseif histfig_link._type == df.histfig_hf_link_masterst then
        master = get_hf_name (histfig_link.target_hf)
        if master == "" then
          master = nil
        end
          
      elseif histfig_link._type == df.histfig_hf_link_apprenticest then
        table.insert (apprentices, get_hf_name (histfig_link.target_hf))
        if apprentices [#apprentices] == "" then
          table.remove (apprentices, #apprentices)
        end
          
      elseif histfig_link._type == df.histfig_hf_link_pet_ownerst then
        --### Pet owner.
        
      elseif histfig_link._type == df.histfig_hf_link_former_masterst then
        --### bard
        
      elseif histfig_link._type == df.histfig_hf_link_former_apprenticest then
        --### bard
        
      elseif histfig_link._type == df.histfig_hf_link_loverst then
      else
        dfhack.printerr ("Found unknown histfig link type " .. tostring (histfig_link._type))--### Probably apprentice...
      end
    end

    if spouse then
      dfhack.print (Pronoun .. " is married to " .. spouse)
        
      if #children == 0 then
        dfhack.println (".")
        
      else
        dfhack.print (" and has " .. tostring (#children) .. " children: ")
        for l = 1, #children do
          if l == #children and
             l ~= 1 then
            dfhack.print (", and ")
              
          elseif l ~= 1 then
            dfhack.print (", ")
          end
           
          dfhack.print (children [l])
        end
        dfhack.println (".")
      end
      
    elseif #children ~= 0 then
      dfhack.print (Pronoun .. " has " .. tostring (#children) .. " children: ")
        for l = 1, #children do
          if l == #children and
             l ~= 1 then
            dfhack.print (", and ")
              
          elseif l ~= 1 then
            dfhack.print (", ")
          end
            
          dfhack.print (children [l])
        end
        dfhack.println (".")
    end
      
    if mother then
      dfhack.print (Pronoun .. " is the " .. child_type .. " of " .. mother)
        
      if father then
        dfhack.println (" and " .. father .. ".")
          
      else
        dfhack.println (".")
      end
      
    elseif father then
      dfhack.println (Pronoun .. " is the " .. child_type .. " of " .. father .. ".")
    end
      
    if #deities ~= 0 then
      dfhack.print (Pronoun .. " is")
        
      for l = 1, #deities do
        dfhack.print (" a " .. worship_strength (deities [l][2]) .. "worshiper of " .. deities [l] [1])
      end
        
      dfhack.println (".")
    end
      
    if master then
      dfhack.println (Pronoun .. " is an apprentice under " .. master .. ".")
    end
      
    if #apprentices ~= 0 then
      dfhack.print (Pronoun .. " is the master of ")
        
      for l = 1, #apprentices do
        if l == #apprentices and
           l ~= 1 then
          dfhack.print (", and ")
            
        elseif l ~= 1 then
          dfhack.print ", "
        end
          
        dfhack.print (apprentices [l])
      end
        
      dfhack.println (".")
    end

    --  Membership in various organizations  --  Blue
    --  Age & date of birth                  --  Yellow
    dfhack.color (COLOR_YELLOW)
    dfhack.println (Pronoun .. " is " .. 
                  tostring (df.global.cur_year - hf.born_year) .. 
                  " years old and was born in " .. 
                  tostring (hf.born_year))--### Should be "on the X:th of Month in Year" hf.born_seconds)
    --  Physical description                 --  White  --  unit.appearance
    --  Weaknesses                           --  Light Red
    
    --  Preferences                          --  Light Green
    dfhack.color (COLOR_LIGHTGREEN)
    if unit.status.current_soul then
      for i, preference in ipairs (unit.status.current_soul.preferences) do
        if preference.active then
          if preference.type == df.unit_preference.T_type.LikeMaterial then
            if preference.mattype == 0 then
              dfhack.println (Pronoun .. " likes " .. string.lower (df.global.world.raws.inorganics [preference.matindex].id) .. ".")
            else
              local material = dfhack.matinfo.decode (preference.mattype, preference.matindex)
              if material and material.mode == "plant" then   
                if preference.mat_state <= 0 then     
                  dfhack.println (Pronoun .. " likes " .. 
                                  string.lower (df.global.world.raws.plants.all [preference.matindex].id) .. " " .. 
                                  string.lower (material.material.id) .. ".")
                else
                  dfhack.println (Pronoun .. " likes " .. 
                                  material.material.state_name [preference.mat_state] .. ".")
                end
                              
              elseif material and material.mode == "creature" then
                dfhack.println (Pronoun .. " likes " .. 
                                material.material.prefix .. " " .. 
                                string.lower (material.material.id) .. ".")
                              
              else
                dfhack.println (Pronoun .. " likes " ..
                                df.global.world.raws.mat_table.builtin [preference.mattype].state_name [0] .. ".")
              end          
            end
          
          elseif preference.type == df.unit_preference.T_type.LikeCreature then
            dfhack.println (Pronoun .. " likes " .. df.global.world.raws.creatures.all [preference.creature_id].name [1] ..
                            " for their " .. df.global.world.raws.creatures.all [preference.creature_id].prefstring [0].value .. ".")
                          --### Weirdo. Seems there's an RNG seed for prefstring when there are multiple.
          
          elseif preference.type == df.unit_preference.T_type.LikeFood then
            local material = dfhack.matinfo.decode (preference.mattype, preference.matindex)
            if preference.matindex ~= -1 and 
               (material.mode == "plant" or
                material.mode == "creature") then
              dfhack.print (Pronoun .. " prefers to consume ")
              if preference.item_type == df.item_type.DRINK or 
                 preference.item_type == df.item_type.LIQUID_MISC then  --  The state in the preferences seems locked to Solid
                dfhack.println (material.material.state_name.Liquid .. ".")
              
              else
                if material.material.prefix == "" then
                  dfhack.println (material.material.state_name.Solid .. ".")
                
                else
                  dfhack.println (material.material.prefix .. ".")
                end
              end            
            
            else
              dfhack.println (Pronoun .. " prefers to consume " ..
                              df.global.world.raws.creatures.all [preference.mattype].name [0] .. ".")
            end
            
          elseif preference.type == df.unit_preference.T_type.HateCreature then
            dfhack.println (Pronoun .. " absolutely detests " .. df.global.world.raws.creatures.all [preference.creature_id].name [1] .. ".")
          
          elseif preference.type == df.unit_preference.T_type.LikeItem then
            if preference.item_subtype == -1 then
              dfhack.println (Pronoun .. " likes " .. string.lower (df.item_type [preference.item_type]) .."s.")
            else
              if preference.item_type == df.item_type.WEAPON then
                dfhack.println (Pronoun .. " likes " .. 
                                df.global.world.raws.itemdefs.weapons [preference.item_subtype].name_plural .. ".")
              
              elseif preference.item_type == df.item_type.TRAPCOMP then
                dfhack.println (Pronoun .. " likes " .. 
                                df.global.world.raws.itemdefs.trapcomps [preference.item_subtype].name_plural .. ".")
  
              elseif preference.item_type == df.item_type.TOY then
                dfhack.println (Pronoun .. " likes " .. 
                                df.global.world.raws.itemdefs.toys [preference.item_subtype].name_plural .. ".")
  
              elseif preference.item_type == df.item_type.TOOL then
                dfhack.println (Pronoun .. " likes " .. 
                                df.global.world.raws.itemdefs.tools [preference.item_subtype].name_plural .. ".")
  
              elseif preference.item_type == df.item_type.INSTRUMENT then
                dfhack.println (Pronoun .. " likes " .. 
                                df.global.world.raws.itemdefs.instruments [preference.item_subtype].name_plural .. ".")
  
              elseif preference.item_type == df.item_type.ARMOR then
                dfhack.println (Pronoun .. " likes " .. 
                                df.global.world.raws.itemdefs.armor [preference.item_subtype].name_plural .. ".")
  
              elseif preference.item_type == df.item_type.AMMO then
                dfhack.println (Pronoun .. " likes " .. 
                                df.global.world.raws.itemdefs.ammo [preference.item_subtype].name_plural .. ".")
  
              elseif preference.item_type == df.item_type.SIEGEAMMO then
                dfhack.println (Pronoun .. " likes " .. 
                                df.global.world.raws.itemdefs.siege_ammo [preference.item_subtype].name_plural .. ".")
  
              elseif preference.item_type == df.item_type.GLOVES then
                dfhack.println (Pronoun .. " likes " .. 
                                df.global.world.raws.itemdefs.gloves [preference.item_subtype].name_plural .. ".")
  
              elseif preference.item_type == df.item_type.SHOES then
                dfhack.println (Pronoun .. " likes " .. 
                                df.global.world.raws.itemdefs.shoes [preference.item_subtype].name_plural .. ".")
  
              elseif preference.item_type == df.item_type.SHIELD then
                dfhack.println (Pronoun .. " likes " .. 
                                df.global.world.raws.itemdefs.shields [preference.item_subtype].name_plural .. ".")
  
              elseif preference.item_type == df.item_type.HELM then
                dfhack.println (Pronoun .. " likes " .. 
                                df.global.world.raws.itemdefs.helms [preference.item_subtype].name_plural .. ".")
  
              elseif preference.item_type == df.item_type.PANTS then
                dfhack.println (Pronoun .. " likes " .. 
                                df.global.world.raws.itemdefs.pants [preference.item_subtype].name_plural .. ".")
  
              elseif preference.item_type == df.item_type.FOOD then
                dfhack.println (Pronoun .. " likes " .. 
                                df.global.world.raws.itemdefs.food [preference.item_subtype].name_plural .. ".")
  
              else
                dfhack.println (Pronoun .. " likes " .. string.lower (df.item_type [preference.item_type]) .."s.")
                --### Don't know how to process the subtype...
              end
            end
          
          elseif preference.type == df.unit_preference.T_type.LikePlant or
                 preference.type == df.unit_preference.T_type.LikeTree then
            dfhack.println (Pronoun .. " likes " ..
                            df.global.world.raws.plants.all [preference.plant_id].name_plural .. " for their " ..
                            df.global.world.raws.plants.all [preference.plant_id].prefstring [0].value .. ".")
          
          elseif preference.type == df.unit_preference.T_type.LikeColor then
            dfhack.println (Pronoun .. " likes the color " .. 
                            df.global.world.raws.language.colors [preference.color_id].name .. ".")
          
          elseif preference.type == df.unit_preference.T_type.LikeShape then
            dfhack.println (Pronoun .. " likes the shape of " .. 
                            df.global.world.raws.language.shapes [preference.shape_id].name_plural .. ".")
          
          elseif preference.type == df.unit_preference.T_type.LikePoeticForm then
            dfhack.println (Pronoun .. " likes the words of " .. 
                            dfhack.TranslateName (df.global.world.poetic_forms.all [preference.poetic_form_id].name, true) .. ".")
                    
          elseif preference.type == df.unit_preference.T_type.LikeMusicalForm then
            dfhack.println (Pronoun .. " likes the sound of " .. 
                            dfhack.TranslateName (df.global.world.musical_forms.all [preference.musical_form_id].name, true) .. ".")
          
          elseif preference.type == df.unit_preference.T_type.LikeDanceForm then
            dfhack.println (Pronoun .. " likes the sight of " .. 
                            dfhack.TranslateName (df.global.world.dance_forms.all [preference.dance_form_id].name, true) .. ".")
          else
            dfhack.error ("Unknown unit_preference found " .. tostring (preference.type))
          end
        end
      end
    end
    --  Mental strengths                     --  Green
    --  Mental weaknesses                    --  Light Red
    --  Culture related stuff                --  Grey
    --  Values                               --  Light Blue
    dfhack.color (COLOR_LIGHTBLUE)
    
    --### Sorted in absolute strength order in the display.
    --### Matches with race or civ values suppressed from display. Race or Civ?
  
    if unit.status.current_soul then
      for i, value in ipairs (unit.status.current_soul.personality.values) do
        local strength
        
        --  The ranges have been determined through DFHacking.
        --
        if value.strength < -40 then
          strength = -3
          
        elseif value.strength < -25 then
          strength = -2
        elseif value.strength < -10 then
          strength = -1
        
        elseif value.strength <= 10 then
          strength = 0
          
        elseif value.strength <= 25 then
          strength = 1
          
        elseif value.strength <= 40 then
          strength = 2
          
        else
          strength = 3
        end
        
        local first, token, last = token_extractor (values [value.type] [strength])
        
        if  token == nil then
          dfhack.println (Pronoun .. " personally " .. first .. ".")
          
        else
          dfhack.println (Pronoun .. " personally " .. first .. gender_translation [token] [unit.sex] .. last .. ".")
        end        
      end
    end
    
    --  Dreams (and success thereof)         --  Yellow
    dfhack.color (COLOR_YELLOW)
    
    if unit.status.current_soul then
      for i, dream in ipairs (unit.status.current_soul.personality.dreams) do
        dfhack.println (Pronoun .. " dreams of " .. goal [dream.type] .. ".")
      end
    end
    
    --  Personality with syndrome deviations, distractions, and stuff
      
    dfhack.color (COLOR_LIGHTGREY)
    
    --  Relations
    if hf.info.relationships ~= nil then
      for k, relation in ipairs (hf.info.relationships.list) do
        --### Ought to filter out parents from this list, as they sometimes appear here.
        --### Ought to filter out any spouse as well.
        table.insert (friends, relation)
      end
      
      for k = 1, #friends - 1 do
        for l = k + 1, #friends do
          if friend_lt (friends [k], friends [l]) then
            temp = friends [k]
            friends [k] = friends [l]
            friends [l] = temp
          end
        end
      end      
      
      for k, relation in ipairs (friends) do
        if relation.anon_5 > 0 then
          if #relation.anon_3 == 0 then
            dfhack.print ("Passing Acquaintance ")
          
          elseif relation.anon_3 [0] == 1 then
            dfhack.print ("Friend ")
          
          elseif relation.anon_3 [0] == 2 then
            dfhack.print ("Grudge ")
          
          elseif relation.anon_3 [0] == 3 then
            dfhack.print ("Bonded ")
          
          elseif relation.anon_3 [0] == 7 then
            dfhack.print ("Friendly Terms ")
        
          else
            dfhack.error ("Unknown primary relation found " .. tostring (relation.anon_3 [0]))
          end
                
          dfhack.println (get_hf_name (relation.histfig_id))
        end
      end
    end
  end
  
  dfhack.color (COLOR_RESET)
end

thoughts ()