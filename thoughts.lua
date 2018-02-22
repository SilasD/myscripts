--  This script attempts to recreate some of the contents of a unit's thought screen, primarily for usage with units whose
--  thought screen is unavailable (gremlins).
--  In addition to that screen, relations are attempted to be reproduced as well.
--
--  It is a work in progress, and things marked with ### are things that haven't been seen or have other outstanding issues.
--  Version 0.5 2018-02-22

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
                  [df.emotion_type.RAPTURE] = {true, "enraptured"},
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

function hf_name (id)
  local hf = df.historical_figure.find (id)
                                        
  if hf then
    return dfhack.TranslateName (hf.name, true)
  
  else
    return ""
  end
end

--------------------------------------------

function add_article (name)
  local ch = name.sub (1, 1):upper ()
  
  if ch == 'A' or
     ch == 'E' or
     ch == 'I' or
     ch == 'O' then
    return "an " .. name
  
  else
    return "a " .. name
  end
end

--------------------------------------------

function incident_victim (id)
  local incident = df.incident.find (id)
  
  if not incident then
    return ""
  end
  
  local victim_race = ""
  local victim_name = ""
  
  if incident.victim_race ~= -1 then
    if incident.victim_hf.hfid ~= -1 then
      victim_race = "the " .. df.global.world.raws.creatures.all [incident.victim_race].name [0]
    
    else
      victim_race = add_article (df.global.world.raws.creatures.all [incident.victim_race].name [0])
    end
  end

  if incident.victim_hf.hfid ~= -1 then
    victim_name = " " .. hf_name (incident.victim_hf.hfid)

    if victim_name == " " then
      victim_name = " an unknown creature"
    end
  end
  
  return victim_race .. victim_name
end

--------------------------------------------

function artifact_name (id)
  local artifact = df.artifact_record.find (emotion.subthought)
    
  if artifact then
    return dfhack.TranslateName (artifact.name, true)
  
  else
    return ""
  end
end

--------------------------------------------

function skill_name (id)
  return string.lower (df.job_skill [id])  --### Should be printed properly via a table lookup
end

--------------------------------------------

local request_enum =  --### Ought to be a new enum.
 {[25] = "job scarcity",
  [26] = "work allocation",
  [27] = "weapon production",
  [28] = "yelling at somebody in charge",
  [29] = "crying on somebody in charge",
  [48] = "petitioning for citizenship"}  -- Newly found...
  
function complained_thought (subthought)  --### Ought to use request_enum above, when defined
  if not request_enum [subthought] then
    dfhack.printerr ("Unhandled Complained subthought encountered " ..  tostring (subthought))
    return ""
  end
  
  if subthought == 25 then
    return "after bringing up job scarcity in a meeting"
    
  elseif subthought == 26 then
    return "after making suggestions about work allocation"
      
  elseif subthought == 27 then
    return "after requesting weapon production"
      
  elseif subthought == 28 then
    return "while yelling at somebody in charge"
      
  elseif subthought == 29 then
    return "while crying on somebody in charge"
    
  elseif subthought == 48 then
    return "after petitioning for citizenship"
  end
end

--------------------------------------------

function received_complaint_thought (subthought)  --### Ought to use request_enum above, when defined
  if subthought == 28 then
    return "yelled at"
      
  elseif subthought == 29 then
    return "cried on"
      
  else
    dfhack.printerr ("Unhandled ReceivedComplaint subthought encountered " ..  tostring (subthought))
    return ""
  end
end
    
--------------------------------------------

function unable_complain_thought (subthought)  --### Ought to use request_enum above, when defined
  --### Only tested the ones listed.
  if subthought == 25 then
    return "find somebody to complain to about job scarcity"
      
  elseif subthought == 26 then
    return "make suggestions about work allocations"
      
  elseif subthought == 27 then
    return "request weapon production"
      
  elseif subthought == 28 then
    return "find somebody in charge to yell at"
      
  elseif subthought == 29 then
    return "find somebody in charge to cry on"
      
  else
    dfhack.printerr ("Unhandled UnableComplain subthought encountered " ..  tostring (subthought))
    return ""
  end
end

--------------------------------------------

function building_of (value)  --###  Use map to print nicely
  return df.building_type [value]
end

--------------------------------------------

function quality_level_of (value)
  if value < 0 then
    return df.item_quality.Ordinary
    
  elseif value < 128 then
    return df.item_quality.WellCrafted
    
  elseif value < 256 then
    return df.item_quality.Superior
    
  elseif value < 384 then
    return df.item_quality.Exceptional
    
  elseif value < 512 then
    return df.item_quality.Masterful
    
  else
    return df.item_quality.Artifact
  end
end

--------------------------------------------

function building_quality_of (severity)  --### Different scales for different buildings?  These are valid for Trade Depot and Bed
  local level = quality_level_of (severity)
  
  if level == df.item_quality.Ordinary then
    return ""
  
  elseif level == df.item_quality.WellCrafted then
    return "fine "
    
  elseif level == df.item_quality.Superior then
    return "very fine "
    
  elseif level == df.item_quality.Exceptional then
    return "splendid "
    
  elseif level == df.item_quality.Masterful then
    return "wonderful "
    
  else
    return "completely sublime "
  end
end

--------------------------------------------

function unit_relationship_text_of (subthought)
    --### Note that the supposed value of 0 = Pet did not work. Tested 0 - 20. Need to test the rest of the enum...
  if subthought == df.unit_relationship_type.Spouse then
    return "a dead spouse"

  elseif subthought == df.unit_relationship_type.Mother then
    return "[his] own dead mother"
    
  elseif subthought == df.unit_relationship_type.Father then
    return "[his] own dead father"
    
  elseif subthought == df.unit_relationship_type.Lover then
    return "a dead lover"
    
  elseif subthought == df.unit_relationship_type.Sibling then
    return "a dead sibling"
    
  elseif subthought == df.unit_relationship_type.Child then
    return "[his] own dead child"
    
  elseif subthought == df.unit_relationship_type.Friend then
    return "a dead friend"
    
  elseif subthought == df.unit_relationship_type.Grudge then
    return "a dead and still annoying acquaintance"
    
  elseif subthought == df.unit_relationship_type.Bonded then
    return "a dead animal training partner"
    
  else
    dfhack.printerr ("Unhandled unit_relationship_type value" ..  tostring (subthought))
    return "the dead"
  end
end

--------------------------------------------

local haunt_enum_type =  --### Probably exists somewhere. Need to locate it.
  {[0] = "Haunted",
   [1] = "Tormented",
   [2] = "Possessed",
   [3] = "Tortured"}
   
function haunt_enum_text_of (severity)  --###  Should use real type when found
  if haunt_enum_type [severity] then
    return haunt_enum_type [severity]:lower ()
    
  else
    dfhack.printerr ("Unhandled haunt_enum_text_of severity encountered " ..  tostring (severity))
    return ""
  end
end

--------------------------------------------

local sleep_noise_type =  --### Probably exists somewhere. Need to locate it.
  {[1] = "Noise",
   [2] = "Loud_Noise",
   [3] = "Very_Loud_Noise"}
   
function sleep_noise_text (severity)  --###  Should use enum, once located
    --### Only tested 0 - 4. Note mismatch with df.unit-thoughts.xml at the time of this writing (0 - 2 used, but same values)
    if severity == 1 then
      return "sleeping uneasily due to noise"
      
    elseif severity == 2 then
      return "being disturbed during sleep by loud noises"
      
    elseif severity == 3 then
      return "loud noises made it impossible to sleep"
      
    else
      dfhack.printerr ("Unhandled SleepNoise severity encountered " ..  tostring (severity))
    end
end

--------------------------------------------

function food_quality_of (severity)
  if severity == df.item_quality.Ordinary then
    return ""  --  Won't happen for food.
      
  elseif severity == df.item_quality.WellCrafted then
    return "pretty decent meal"
      
  elseif severity == df.item_quality.FinelyCrafted then
    return "fine dish"
      
  elseif severity == df.item_quality.Superior then
    return "wonderful dish"
      
  elseif severity == df.item_quality.Exceptional then
    return "truly decadent dish"
      
  elseif severity == df.item_quality.Masterful then
    return "legendary meal"
      
  elseif severity == df.item_quality.Artifact then
    return ""  -- Won't happen. "after having ." if DFHacked.
  
  else
    printerr ("Unknown quality severity found " ..  tostring (severity))
    return ""
  end
end

--------------------------------------------

function drink_quality_of (severity)
  if severity == df.item_quality.Ordinary then
    return ""
      
  elseif severity == df.item_quality.WellCrafted then
    return "pretty decent"
      
  elseif severity == df.item_quality.FinelyCrafted then
    return "fine"
      
  elseif severity == df.item_quality.Superior then
    return "wonderful"
      
  elseif severity == df.item_quality.Exceptional then
    return "truly decadent"
      
  elseif severity == df.item_quality.Masterful then
    return "legendary"
      
  elseif severity == df.item_quality.Artifact then
    return ""  -- Won't happen. "after having ." if DFHacked.
  
  else
    printerr ("Unknown quality severity found " ..  tostring (severity))
    return ""
  end
end

--------------------------------------------

local room_type =  --### Can't find any such type in the XML files. Introduce?
  {[0] = "Office",
   [1] = "Bedroom",
   [2] = "Dining Room",
   [3] = "Tomb"}
   
function pretention_room_of (subthought) --###  Only tested -1 - 4. Severity doesn't seem to have any effect.
  if subthought == 0 then
    return "office"
    
  elseif subthought == 1 then
    return "sleeping"
    
  elseif subthought == 2 then
    return "dining"
    
  elseif subthought == 3 then
    return "burial"
    
  else
    dfhack.printerr ("Unhandled RoomPretension subthought encountered " ..  tostring (subthought))
    return ""
  end
end
    
--------------------------------------------

function dining_room_quality_of (severity)
  if severity == df.item_quality.Ordinary or
     severity == df.item_quality.Artifact then
    return ""  --  ###Shouldn't happen
    
  elseif severity == df.item_quality.WellCrafted then
    return "good"
    
  elseif severity == df.item_quality.FinelyCrafted then
    return "very good"
    
  elseif severity == df.item_quality.Superior then
    return "great"
    
  elseif severity == df.item_quality.Exceptional then
    return "fantastic" 
    
  elseif severity == df.item_quality.Masterful then
    return "legendary"
    
  else
    dfhack.printerr ("Unknown quality severity found " ..  tostring (severity))
    return ""
  end
end

--------------------------------------------

function bedroom_quality_of (severity)
  if severity == df.item_quality.Ordinary or
     severity == df.item_quality.Artifact then
    return "** bedroom"  --  ###Shouldn't happen
    
  elseif severity == df.item_quality.WellCrafted then
    return "good bedroom"
    
  elseif severity == df.item_quality.FinelyCrafted then
    return "very good bedroom"
    
  elseif severity == df.item_quality.Superior then
    return "great bedroom"
    
  elseif severity == df.item_quality.Exceptional then
    return "fantastic bedroom" 
    
  elseif severity == df.item_quality.Masterful then
    return "bedroom like a personal palace"
    
  else
    dfhack.printerr ("Unknown quality severity found " ..  tostring (severity))
    return "bedroom"
  end
end

--------------------------------------------

local child_count = 
  {[1] = "a child",
   [2] = "twins",
   [3] = "triplets",
   [4] = "quadruplets",
   [5] = "quintuplets",
   [6] = "sextuplets",
   [7] = "septuplets",
   [8] = "octuplets",
   [9] = "nonuplets",
   [10] = "decaplets",
   [11] = "undecaplets",
   [12] = "duodecaplets",
   [13] = "tredecaplets",
   [14] = "quattuodecaplets",
   [15] = "quindecaplets"}

function child_count_of (severity)
  if child_count [severity] then
    return child_count [severity]
    
  else
    return "many babies"
  end
end

--------------------------------------------

function child_birth_of (subthought, severity)
  local offspring = child_count_of (severity)
    
  if severity == 1 then
    if subthought == 0 then
      offspring = "a girl"
      
    elseif subthought == 1 then
      offspring = "a boy"
    end    
  end
    
  return offspring
end

--------------------------------------------

function spouse_birth_of (subthought, severity)
  if subthought == df.unit_relationship_type.Spouse then
    return "while getting married"  --### Different tense when the feeling grows older?
     
  elseif subthought == df.unit_relationship_type.Sibling then
    if severity == 1 then
      return "after gaining a sibling"
        
    else
      return "after gaining siblings"
    end
      
  elseif subthought == df.unit_relationship_type.Child then  --### Actually is "after becoming a parent"
    return "after becoming a parent of " .. child_count_of (severity)
    
  else
    dfhack.printerr ("Unhandled SpouseGaveBirth subthought encountered " ..  tostring (subthought))   
    return ""
  end    
end

--------------------------------------------

function office_quality_of (severity)  --### setting <-> office on meeting vs ...? DFHacking gave "setting", but earlier notes said "office". RNG?
  if severity == df.item_quality.Ordinary then
    return ""  --  Shouldn't happen. Matches DFHacked result...
    
  elseif severity == df.item_quality.WellCrafted or
         severity == df.item_quality.Artifact then
    return "good setting"
    
  elseif severity == df.item_quality.FinelyCrafted then
    return "very good setting"
    
  elseif severity == df.item_quality.Superior then
    return "great setting"
    
  elseif severity == df.item_quality.Exceptional then
    return "fantastic setting" 
    
  elseif severity == df.item_quality.Masterful then
    return "room worthy of legends"
    
  else
    printerr ("Unknown quality severity found " ..  tostring (severity))
    return ""
  end
end

--------------------------------------------

function tomb_quality_of (severity)
  if severity == df.item_quality.Ordinary or
     severity == df.item_quality.Artifact then
    return ""  --  ###Shouldn't happen
    
  elseif severity == df.item_quality.WellCrafted then
    return "good"
    
  elseif severity == df.item_quality.FinelyCrafted then
    return "very good"
    
  elseif severity == df.item_quality.Superior then
    return "great"
    
  elseif severity == df.item_quality.Exceptional then
    return "fantastic" 
    
  elseif severity == df.item_quality.Masterful then
    return "legendary"
    
  else
    printerr ("Unknown quality severity found " ..  tostring (severity))
    return ""
  end
end

--------------------------------------------

function decay_of (subthought)
  if subthought == df.unit_relationship_type.Spouse then
    return "a spouse"

  elseif subthought == df.unit_relationship_type.Mother then
    return "a mother"
    
  elseif subthought == df.unit_relationship_type.Father then
    return "a father"
    
  elseif subthought == df.unit_relationship_type.Lover then
    return "a lover"
    
  elseif subthought == df.unit_relationship_type.Sibling then
    return "a sibling"
    
  elseif subthought == df.unit_relationship_type.Child then
    return "a child"
    
  elseif subthought == df.unit_relationship_type.Friend then
    return "a friend"
    
  elseif subthought == df.unit_relationship_type.Grudge then
    return "an annoying acquaintance"
    
  elseif subthought == df.unit_relationship_type.Bonded then
    return "an animal training partner"
    
  else
    dfhack.printerr ("Unhandled unit_relationship_type value" ..  tostring (subthought))
    return ""
  end
end

--------------------------------------------

function unfulfulled_need_of (subthought, severity)
  if subthought == df.need_type.Socialize then
    return "being away from people for too long"
      
  elseif subthought == df.need_type.DrinkAlcohol then -- type: UNEASINESS, unk2: 1, strength: 1, subthought: 1, severity: -1, flags: fftf, unk7: 0
    return "being kept from alcohol for too long"
      
  elseif subthought == df.need_type.PrayOrMedidate then -- type: UNEASINESS, unk2: 1, strength: 1, subthought: 2, severity: 260, flags: fftf, unk7: 0
    local hf = df.historical_figure.find (severity)
    
    if hf then
      return "being unable to pray to " .. dfhack.TranslateName (hf.name, true) .. " for too long"
    else
      return "being unable to pray for too long"
    end
                
  elseif subthought == df.need_type.StayOccupied then -- type: BOREDOM, unk2: 0, strength: 0, subthought: 3, severity: -1, flags: fftf, unk7: 0
    return "being unoccupied for too long"
      
  elseif subthought == df.need_type.BeCreative then -- type: FRUSTRATION, unk2: 0, strength: 0, subthought: 4, severity: -1, flags: ffff, unk7: 0
    return "doing nothing creative for so long"
      
  elseif subthought == df.need_type.Excitement then -- type: BOREDOM, unk2: 0, strength: 0, subthought: 5, severity: -1, flags: fftf, unk7: 0
    return "leading an unexciting life for so long"
      
  elseif subthought == df.need_type.LearnSomething then -- type: FRUSTRATION, unk2: 0, strength: 0, subthought: 6, severity: -1, flags: fftf, unk7: 0
    return "not learning anything for so long"
      
  elseif subthought == df.need_type.BeWithFamily then -- type: LONELINESS, unk2: 1, strength: 1, subthought: 7, severity: -1, flags: fftf, unk7: 0
    return "being away from family for too long"
      
  elseif subthought == df.need_type.BeWithFriends then -- type: LONELINESS, unk2: 100, strength: 100, subthought: 8, severity: -1, flags: fftf, unk7: 0
    return "being away from friends for too long"
      
  elseif subthought == df.need_type.HearEloquence then -- type: RESTLESS, unk2: 100, strength: 100, subthought: 9, severity: -1, flags: fftf, unk7: 0
    return "being unable to hear eloquent speech for so long"
      
  elseif subthought == df.need_type.UpholdTradition then -- type: UNEASINESS, unk2: 0, strength: 0, subthought: 10, severity: -1, flags: fftf, unk7: 0
    return "being away from traditions for too long"
      
  elseif subthought == df.need_type.SelfExamination then -- type: UNEASINESS, unk2: 1, strength: 1, subthought: 11, severity: -1, flags: fftf, unk7: 0
    return "a lack of introspection for too long"
      
  elseif subthought == df.need_type.MakeMerry then -- type: LONELINESS, unk2: 100, strength: 100, subthought: 12, severity: -1, flags: fftf, unk7: 0
    return "being unable to make merry for son long"
      
  elseif subthought == df.need_type.CraftObject then -- type: RESTLESS, unk2: 100, strength: 100, subthought: 13, severity: -1, flags: fftf, unk7: 0
    return "being unable to practice a craft for too long"
      
  elseif subthought == df.need_type.MartialTraining then -- type: BOREDOM, unk2: 1, strength: 1, subthought: 14, severity: -1, flags: fftf, unk7: 0
    return "being unable to practice a martial art for too long"
      
  elseif subthought == df.need_type.PracticeSkill then -- type: BOREDOM, unk2: 0, strength: 0, subthought: 15, severity: -1, flags: fftf, unk7: 0
    return "being unable to practice a skill for too long"
      
  elseif subthought == df.need_type.TakeItEasy then -- type: UNEASINESS, unk2: 100, strength: 100, subthought: 16, severity: -1, flags: ffff, unk7: 0
    return "being unable to take it easy for so long"
      
  elseif subthought == df.need_type.MakeRomance then -- type: LONELINESS, unk2: 1, strength: 0, subthought: 17, severity: -1, flags: fftt, unk7: 0
    return "being unable to make romance for so long"
      
  elseif subthought == df.need_type.SeeAnimal then -- type: BOREDOM, unk2: 0, strength: 0, subthought: 18, severity: -1, flags: fftf, unk7: 0
    return "being away from animals for so long"
      
   elseif subthought == df.need_type.SeeGreatBeast then -- type: BOREDOM, unk2: 0, strength: 0, subthought: 19, severity: -1, flags: fftf, unk7: 0
    return "being away from great beasts for so long"
      
  elseif subthought == df.need_type.AcquireObject then -- type: UNEASINESS, unk2: 1, strength: 1, subthought: 20, severity: -1, flags: fftf, unk7: 0
    return "being unable to acquire something for too long"
      
  elseif subthought == df.need_type.EatGoodMeal then -- type: UNEASINESS, unk2: 1, strength: 1, subthought: 21, severity: -1, flags: fftf, unk7: 0
    return "a lack of decent meals for too long"
      
  elseif subthought == df.need_type.Fight then -- type: BOREDOM, unk2: 1, strength: 1, subthought: 22, severity: -1, flags: fftf, unk7: 0
    return "being unable to fight for too long"
      
  elseif subthought == df.need_type.CauseTrouble then -- type: FRUSTRATION, unk2: 0, strength: 0, subthought: 23, severity: -1, flags: ffff, unk7: 0
    return "a lack of trouble-making for too long"
      
  elseif subthought == df.need_type.Argue then -- type: FRUSTRATION, unk2: 0, strength: 0, subthought: 24, severity: -1, flags: ffff, unk7: 0
    return "being unable to argue for too long"
      
  elseif subthought == df.need_type.BeExtravagant then -- type: UNEASINESS, unk2: 1, strength: 1, subthought: 25, severity: -1, flags: fftf, unk7: 0
    return "being unable to be extravagant for so long"
      
  elseif subthought == df.need_type.Wander then -- type: BOREDOM, unk2: 1, strength: 1, subthought: 26, severity: -1, flags: fftf, unk7: 0
    return "being unable to wander for too long"
      
  elseif subthought == df.need_type.HelpSomebody then -- type: UNEASINESS, unk2: 1, strength: 1, subthought: 27, severity: -1, flags: fftf, unk7: 0
    return "being unable to help anybody for too long"
      
  elseif subthought == df.need_type.ThinkAbstractly then -- type: BOREDOM, unk2: 1, strength: 1, subthought: 28, severity: -1, flags: fftf, unk7: 0
    return "a lack of abstract thinking for too long"
      
  elseif subthought == df.need_type.AdmireArt then -- type: FRUSTRATION, unk2: 0, strength: 0, subthought: 29, severity: -1, flags: ffff, unk7: 0
    return "being unable to admire art for so long"
      
  else
    dfhack.printerr ("Unidentified Need subthought " .. tostring (subthought))
    return ""
  end
end                                        

--------------------------------------------

--### Could be replaced by a matrix with nicer looking names. DF itself uses nicer names, hidden away somewhere...
--
function get_topic (subthought, severity)
  if subthought == 0 then
    return df.knowledge_scholar_flags_0 [severity]
    
  elseif subthought == 1 then
    return df.knowledge_scholar_flags_1 [severity]
    
  elseif subthought == 2 then
    return df.knowledge_scholar_flags_2 [severity]
    
  elseif subthought == 3 then
    return df.knowledge_scholar_flags_3 [severity]
    
  elseif subthought == 4 then
    return df.knowledge_scholar_flags_4 [severity]
    
  elseif subthought == 5 then
    return df.knowledge_scholar_flags_5 [severity]
    
  elseif subthought == 6 then
    return df.knowledge_scholar_flags_6 [severity]
    
  elseif subthought == 7 then
    return df.knowledge_scholar_flags_7 [severity]
    
  elseif subthought == 8 then
    return df.knowledge_scholar_flags_8 [severity]
    
  elseif subthought == 9 then
    return df.knowledge_scholar_flags_9 [severity]
    
  elseif subthought == 10 then
    return df.knowledge_scholar_flags_10 [severity]
    
  elseif subthought == 11 then
    return df.knowledge_scholar_flags_11 [severity]
    
  elseif subthought == 12 then
    return df.knowledge_scholar_flags_12 [severity]
    
  elseif subthought == 13 then
    return df.knowledge_scholar_flags_13 [severity]
    
  else
    dfhack.printerr ("Unknown topic subthought " .. tostring (subthought))
    return ""
  end
end

--------------------------------------------

function item_quality_of (severity)
  if severity == df.item_quality.WellCrafted then
    return "well-crafted"
      
  elseif severity == df.item_quality.FinelyCrafted then
    return "finely-crafted"
      
  elseif severity == df.item_quality.Superior then
    return "superior" 
      
  elseif severity == df.item_quality.Exceptional then
    return "exceptional"
      
  else  --  df.item_quality.Ordinary
        --  df.item_quality.Masterful
        --  df.item_quality.Artifact
    return "truly splendid"
  end
end

--------------------------------------------

function realize_value_of (subthought, severity)
  local level
    
  if severity < -10 then
    level = "the worthlessness"
      
  elseif severity > 10 then
    level = "the value"
  else
    level = "nuances"
  end
  
  return level .. " of " .. df.value_type [emotion.subthought]:lower ()
end
    
--------------------------------------------

function display_name (subthought)
  local artifact = df.artifact_record.find (subthought)
  local item = df.item.find (subthought)
    
  if artifact then
    return dfhack.TranslateName (artifact.name, false)  --### Probably DF bug to display native name here...
      
  elseif item then  --### Wwhat does the "type" parameter in getDescription do? Doesn't seem to have any effect?
    return add_article (dfhack.items.getDescription (item, 0))
    
  else
    return "a piece"
  end
end

--------------------------------------------
--  {["caption"], ["extended_caption"], ["subthought"], ["severity"]}
--
--  Tokens so far:
--    [subthought]
--    [severity]
--    [subthought_severity]
--    [he]
--    [his]
--
-- ### Works without parameters comments below means the text has been DFHacked to display, but it's unknown if naturally generated instances have parameters.
--
local unit_thoughts =
  {[df.unit_thought_type.None] = {["caption"] = ""},
   [df.unit_thought_type.Conflict] = {["caption"] = "while in conflict"}, --###unk7? type: TERROR, unk2: 100, strength: 100, subthought: -1, severity: 0, flags: ffff, unk7: 127
   [df.unit_thought_type.Trauma] = {["caption"] = "after experiencing trauma"},   --###unk7? type: FEAR, unk2: 100, strength: 100, subthought: -1, severity: 0, flags: tftf, unk7: 123
   [df.unit_thought_type.WitnessDeath] = {["caption"] = "after seeing [subthought] die", -- type: ANYTHING, unk2: 0, strength: 0, subthought: 364, severity: 0, flags: ffff, unk7: 0
                                          ["subthought"] = {"df.global.world.incidents.all id",
                                                            (function (subthought) 
                                                               return incident_victim (subthought)
                                                             end)}},
   [df.unit_thought_type.UnexpectedDeath] = {["caption"] = "at the unexpected death of somebody",  -- type: SHOCK, unk2: 0, strength: 0, subthought: 134129, severity: 0, flags: fftf, unk7: 0
                                                                                                  -- subthought = hf id. Not printed except as the primary thought "I can't believe Jeha Ramwills the Wild Fog is dead. <emotion text>"
                                             ["extended_caption"] = "at the unexpected death of [subthought]",
                                             ["subthought"] = {"hf id",
                                                               (function (subthought)
                                                                  return hf_name (subthought)
                                                                end)}},
   [df.unit_thought_type.Death] = {["caption"] = "at somebody's death",  -- subthought = hf id. Not printed except as the primary thought "Jeha Ramwills the Wild Fog is really dead. <emotion text>"  -- type: GRIEF, unk2: 0, strength: 0, subthought: 94110, severity: 0, flags: fftf, unk7: 0
                                   ["extended_caption"] = "at [subthought]'s death",
                                   ["subthought"] = {"hf id",
                                                     (function (subthought)
                                                        return hf_name (subthought)
                                                      end)}},
   [df.unit_thought_type.Kill] = {["caption"] = "while killing somebody",  -- Not printed except as primary thought. "<Dorf> killed Seba Ironcombine. <emotion text>"
                                  ["extra_caption"] = "while killing [subthought]",
                                  ["subthought"] = {"df.global.world.incidents.all id",
                                                    (function (subthought) 
                                                       return incident_victim (subthought)
                                                     end)}},
   [df.unit_thought_type.LoveSeparated] = {["caption"] = "at being separated from a loved one"},  --### type: SADNESS, unk2: 50, strength: 50, subthought: 129684, severity: 0, flags: fftf, unk7: 0. ###subthought
   [df.unit_thought_type.LoveReunited] = {["caption"] = "after being reunited with a loved one"}, --### Failed to produce. hf id?
   [df.unit_thought_type.JoinConflict] = {["caption"] = "when joining an existing conflict"}, --### type: VENGEFULNESS, unk2: 100, strength: 100, subthought: 62737, severity: 0, flags: fftf, unk7: 0. ###subthought = incident id ? HF id?
   [df.unit_thought_type.MakeMasterwork] = {["caption"] = "after producing a masterwork"}, -- type: SATISFACTION, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fttf, unk7: 0
   [df.unit_thought_type.MadeArtifact] = {["caption"] = "after creating an artifact",  --  Not printed except as primary thought "I shall name you Oakenpools And More. <emotion text>".-- type: SATISFACTION, unk2: 0, strength: 0, subthought: 103702, severity: 0, flags: fttf, unk7: 0
                                          ["extended_caption"] = "after creating [subthought]",
                                          {"df.global.world.artifacts.all id",
                                           (function (subthought)
                                              return artifact_name (subthought)
                                            end)},
                                          nil},
   [df.unit_thought_type.MasterSkill] = {["caption"] = "upon mastering [subthought]",  -- type: SATISFACTION, unk2: 0, strength: 0, subthought: 35, severity: 0, flags: fftf, unk7: 0
                                         ["subthought"] = {"df.job_skill value",
                                                           (function (subthought)
                                                              return skill_name (subthought)
                                                            end)}},
   [df.unit_thought_type.NewRomance] = {["caption"] = "as [he] was caught up in a new romance"},  --### Works without parameters
   [df.unit_thought_type.BecomeParent] = {["caption"] = "after becoming a parent"}, -- type: BLISS, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: ffff, unk7: 0
   [df.unit_thought_type.NearConflict] = {["caption"] = "being near to a conflict"},  --### Works without parameters
   [df.unit_thought_type.CancelAgreement] = {["caption"] = "after an agreement was cancelled"},  --### Works without parameters. Spelling as in DF.
   [df.unit_thought_type.JoinTravel] = {["caption"] = "upon joining a traveling group"},  --### Works without parameters
   [df.unit_thought_type.SiteControlled] = {["caption"] = "after a site was controlled"},  --### Works without parameters
   [df.unit_thought_type.TributeCancel] = {["caption"] = "after a tribute cancellation"},  --### Works without parameters
   [df.unit_thought_type.Incident] = {["caption"] = "after an incident",                            --  Not printed except as primary thought.
                                       ["extra_caption"] = "after an incident with [subthought]",
                                      ["subthought"] = {"df.global.world.incidents.all id",
                                                        (function (subthought) 
                                                           return incident_victim (subthought)
                                                         end)}},
   [df.unit_thought_type.HearRumor] = {["caption"] = "after hearing a rumor"},  --### Works without parameters
   [df.unit_thought_type.MilitaryRemoved] = {["caption"] = "after being removed from a military group"},  --### Works without parameters
   [df.unit_thought_type.StrangerWeapon] = {["caption"] = "when a stranger advanced with a weapon"},  --### Works without parameters
   [df.unit_thought_type.StrangerSneaking] = {["caption"] = "after seeing a stranger sneaking around"},  --###
   [df.unit_thought_type.SawDrinkBlood] = {["caption"] = "after witnessing a night creature drinking blood"}, --###
   [df.unit_thought_type.Complained] = {["caption"] = "[subthought]",  -- type: SATISFACTION, unk2: 25, strength: 25, subthought: 48, severity: 0, flags: fftf, unk7: 0
                                        ["subthought"] = {"request enum",
                                                          (function (subthought)
                                                             return complained_thought (subthought)
                                                           end)}},
   [df.unit_thought_type.ReceivedComplaint] = {["caption"] = "while being [subthought] by an unhappy citizen",
                                               ["subthought"] = {"request enum",
                                                                 (function (subthought)
                                                                    return received_complaint_thought (subthought)
                                                                  end)}},
   [df.unit_thought_type.AdmireBuilding] = {["caption"] = "near a [severity][subthought]", -- type: PLEASURE, unk2: 0, strength: 0, subthought: 6, severity: 15, flags: fftf, unk7: 0
                                            ["subthought"] = {"df.building_type value",
                                                              (function (subthought)
                                                                 return building_of (subthought)
                                                               end)},
                                            ["severity"] = {"building quality value",
                                                            (function (severity)
                                                               return building_quality_of (severity)
                                                             end)}},
   
   [df.unit_thought_type.AdmireOwnBuilding] = {["caption"] = "near [his] own [severity][subthought]", -- type: PLEASURE, unk2: 0, strength: 0, subthought: 1, severity: 240, flags: fftf, unk7: 0
                                               ["subthought"] = {"df.building_type value",
                                                                 (function (subthought)
                                                                    return building_of (subthought)
                                                                  end)},
                                               ["severity"] = {"building quality value",
                                                               (function (severity)
                                                                  return building_quality_of (severity)
                                                                end)}},                                                 
   [df.unit_thought_type.AdmireArrangedBuilding] = {["caption"] = "near a [severity]tastefully arranged [subthought]", -- type: PLEASURE, unk2: 0, strength: 0, subthought: 53, severity: 100, flags: fftf, unk7: 0
                                                    ["subthought"] = {"df.building_type value",
                                                                      (function (subthought)
                                                                         return building_of (subthought)
                                                                       end)},
                                                    ["severity"] = {"building quality value",
                                                                    (function (severity)
                                                                       return building_quality_of (severity)
                                                                     end)}},

   [df.unit_thought_type.AdmireOwnArrangedBuilding] = {["caption"] = "near [his] own [severity]tastefully arranged [subthought]",
                                                       ["subthought"] = {"df.building_type value",
                                                                         (function (subthought)
                                                                            return building_of (subthought)
                                                                          end)},
                                                       ["severity"] = {"building quality value",
                                                                       (function (severity)
                                                                          return building_quality_of (severity)
                                                                        end)}},
   [df.unit_thought_type.LostPet] = {["caption"] = "after losing a pet"},  --### Works without parameters
   [df.unit_thought_type.ThrownStuff] = {["caption"] = "after throwing something"},  --### Works without parameters
   [df.unit_thought_type.JailReleased] = {["caption"] = "after being released from confinement"}, -- type: FREEDOM, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: ffff, unk7: 0
   [df.unit_thought_type.Miscarriage] = {["caption"] = "after a miscarriage"},  -- type: ANGUISH, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.SpouseMiscarriage] = {["caption"] = "after [his] spouse's miscarriage"},  -- type: ANGUISH, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.OldClothing] = {["caption"] = "to be wearing old clothing"}, -- type: IRRITATION, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.TatteredClothing] = {["caption"] = "to be wearing tattered clothing"}, -- type: BITTERNESS, unk2: 100, strength: 100, subthought: -1, severity: 0, flags: ffff, unk7: 0
   [df.unit_thought_type.RottedClothing] = {["caption"] = "to have clothes rot off of [his] body"},  -- type: IRRITATION, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.GhostNightmare] = {["caption"] = "after being tormented in nightmares by [subthought]",
                                            ["subthought"] = {"df.unit_relationship_type value",
                                                              (function (subthought)
                                                                 return unit_relationship_text_of (subthought)
                                                               end)}},
   [df.unit_thought_type.GhostHaunt] = {["caption"] = "after being [severity] by [subthought]",
                                        ["subthought"] = {"df.unit_relationship_type value",
                                                          (function (subthought)
                                                             return unit_relationship_text_of (subthought)
                                                           end)},
                                        ["severity"] = {"haunt enum value",
                                                        (function (severity)
                                                           return haunt_enum_text_of (severity)
                                                         end)}},
   [df.unit_thought_type.Spar] = {["caption"] = "after a sparring session"},  -- type: EXHILARATION, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.UnableComplain] = {["caption"] = "after being unable to [subthought]",
                                            ["subthought"] = {"request enum",
                                                              (function (subthought)
                                                                 return unable_complain_thought (subthought)
                                                               end)}},
   [df.unit_thought_type.LongPatrol] = {["caption"] = "during long patrol duty"},  --### Works without parameters
   [df.unit_thought_type.SunNausea] = {["caption"] = "after being nauseated by the sun"},  --### Annoying misspelling "bu" -- type: HOPELESSNESS, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.SunIrritated] = {["caption"] = "at being out in the sunshine again"}, -- type: ANNOYANCE, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.Drowsy] = {["caption"] = "when drowsy"}, -- type: IRRITATION, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.VeryDrowsy] = {["caption"] = "when utterly sleep-deprived"},  --### Works without parameters
   [df.unit_thought_type.Thirsty] = {["caption"] = "when thirsty"}, -- type: IRRITATION, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.Dehydrated] = {["caption"] = "when dehydrated"},  --### Works without parameters
   [df.unit_thought_type.Hungry] = {["caption"] = "when hungry"}, -- type: IRRITATION, unk2: 10, strength: 10, subthought: -1, severity: 0, flags: ffff, unk7: 0
   [df.unit_thought_type.Starving] = {["caption"] = "when starving"}, -- type: PANIC, unk2: 100, strength: 100, subthought: -1, severity: 0, flags: ffff, unk7: 0
   [df.unit_thought_type.MajorInjuries] = {["caption"] = "after suffering a major injury"}, -- type: SHAKEN, unk2: 100, strength: 100, subthought: -1, severity: 0, flags: fftf, unk7: 68
   [df.unit_thought_type.MinorInjuries] = {["caption"] = "after suffering a minor injury"}, -- type: ANNOYANCE, unk2: 10, strength: 10, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.SleepNoise] = {["caption"] = "after [severity]",
                                        ["severity"] = {"sleep noise enum",
                                                        (function (severity)
                                                           return sleep_noise_text (severity)
                                                         end)}},
   [df.unit_thought_type.Rest] = {["caption"] = "after being able to rest and recuperate"},  -- type: RESTLESS, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.FreakishWeather] = {["caption"] = "when caught in freakish weather"}, --  type: UNEASINESS, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.Rain] = {["caption"] = "when caught in the rain"}, -- type: DEJECTION, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.SnowStorm] = {["caption"] = "when caught in a snow storm"},  --### Works without parameters
   [df.unit_thought_type.Miasma] = {["caption"] = "after retching on a miasma"}, -- type: DISGUST, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: ffff, unk7: 0
   [df.unit_thought_type.Smoke] = {["caption"] = "after choking on smoke underground"}, -- type: ANNOYANCE, unk2: 100, strength: 100, subthought: -1, severity: 0, flags: ffff, unk7: 0
   [df.unit_thought_type.Waterfall] = {["caption"] = "being near to a waterfall"},  --  RELIEF, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.Dust] = {["caption"] = "after choking on dust underground"}, -- type: ANNOYANCE, unk2: 80, strength: 80, subthought: -1, severity: 0, flags: ffff, unk7: 0
   [df.unit_thought_type.Demands] = {["caption"] = "considering the state of demands"},  --### Works without parameters
   [df.unit_thought_type.ImproperPunishment] = {["caption"] = "that a criminal could not be properly punished"},  --### Works without parameters
   [df.unit_thought_type.PunishmentReduced] = {["caption"] = "to have [his] punishment reduced"},  --### Works without parameters
   [df.unit_thought_type.Elected] = {["caption"] = "to be elected"},  -- type: EAGERNESS, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.Reelected] = {["caption"] = "to be re-elected"},  --### Works without parameters
   [df.unit_thought_type.RequestApproved] = {["caption"] = "having a request approved"},  --### Works without parameters
   [df.unit_thought_type.RequestIgnored] = {["caption"] = "having a request ignored"},  --### Works without parameters
   [df.unit_thought_type.NoPunishment] = {["caption"] = "that nobody could be punished for a failure"},  --### Works without parameters
   [df.unit_thought_type.PunishmentDelayed] = {["caption"] = "to have [his] punishment delayed"},  --### Works without parameters
   [df.unit_thought_type.DelayedPunishment] = {["caption"] = "after the delayed punishment of a criminal"},  --### Works without parameters
   [df.unit_thought_type.ScarceCageChain] = {["caption"] = "considering the scarcity of cages and chains"},  --### Works without parameters
   [df.unit_thought_type.MandateIgnored] = {["caption"] = "having a mandate ignored"},  --### Works without parameters
   [df.unit_thought_type.MandateDeadlineMissed] = {["caption"] = "having a mandate deadline missed"},  --### Works without parameters
   [df.unit_thought_type.LackWork] = {["caption"] = "after the lack of work last season"},  --### Works without parameters
   [df.unit_thought_type.SmashedBuilding] = {["caption"] = "after smashing up a building"},  --### Works without parameters
   [df.unit_thought_type.ToppledStuff] = {["caption"] = "after toppling something over"},  --### Works without parameters
   [df.unit_thought_type.NoblePromotion] = {["caption"] = "after receiving a higher rank of nobility"},  --### Works without parameters
   [df.unit_thought_type.BecomeNoble] = {["caption"] = "after entering the nobility"},  --### Works without parameters
   [df.unit_thought_type.Cavein] = {["caption"] = "after being knocked out during a cave-in"}, -- type: CONFUSION, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.MandateDeadlineMet] = {["caption"] = "to have a mandate deadline met"},  --### Works without parameters
   [df.unit_thought_type.Uncovered] = {["caption"] = "to be uncovered"},  -- type: AMBIVALENCE, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftt, unk7: 0
   [df.unit_thought_type.NoShirt] = {["caption"] = "to have no shirt"},  -- type: AMBIVALENCE, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftt, unk7: 0
   [df.unit_thought_type.NoShoes] = {["caption"] = "to have no shoes"},  -- type: AMBIVALENCE, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftt, unk7: 0
   [df.unit_thought_type.EatPet] = {["caption"] = "after being forced to eat a treasured pet to survive"},  --### Works without parameters
   [df.unit_thought_type.EatLikedCreature] = {["caption"] = "after being forced to eat a beloved creature to survive"},  --### Works without parameters
   [df.unit_thought_type.EatVermin] = {["caption"] = "after being forced to eat vermin to survive",  -- type: RELIEF, unk2: 0, strength: 0, subthought: 49, severity: 0, flags: fftf, unk7: 0
                                       ["extended_caption"] = "after being forced to eat [subthought] to survive",
                                       ["subthought"] = {"df.global.world.raws.creatures.all index",
                                                         (function (subthought)
                                                            return df.global.world.raws.creatures.all [subthought].name [1]
                                                          end)}},
   [df.unit_thought_type.FistFight] = {["caption"] = "after starting a fist fight"},  --### Works without parameters
   [df.unit_thought_type.GaveBeating] = {["caption"] = "after punishing somebody with a beating"},  --### Works without parameters
   [df.unit_thought_type.GotBeaten] = {["caption"] = "punished by beating"},  --### Works without parameters
   [df.unit_thought_type.GaveHammering] = {["caption"] = "after beating somebody with a hammer"},  --### Works without parameters
   [df.unit_thought_type.GotHammered] = {["caption"] = "after being beaten with a hammer"},  --### Works without parameters
   [df.unit_thought_type.NoHammer] = {["caption"] = "after being unable to find a hammer"},  --### Works without parameters
   [df.unit_thought_type.SameFood] = {["caption"] = "eating the same old food"},  --### Works without parameters
   [df.unit_thought_type.AteRotten] = {["caption"] = "after eating rotten food"},  --### Works without parameters
   [df.unit_thought_type.GoodMeal] = {["caption"] = "after eating [severity]", -- type: CONTENTMENT, unk2: 0, strength: 0, subthought: -1, severity: 1, flags: fftf, unk7: 0
                                      ["severity"] = {"df.item_quality value",
                                                      (function (severity)
                                                         return food_quality_of (severity)
                                                       end)}},
   [df.unit_thought_type.GoodDrink] = {["caption"] = "after having [severity] drink", -- type: CONTENTMENT, unk2: 0, strength: 0, subthought: -1, severity: 1, flags: fftf, unk7: 0
                                       ["severity"] = {"df.item_quality value",
                                                       (function (severity)
                                                          return drink_quality_of (severity)
                                                       end)}},
   [df.unit_thought_type.MoreChests] = {["caption"] = "not having enough chests"},  --### Works without parameters
   [df.unit_thought_type.MoreCabinets] = {["caption"] = "not having enough cabinets"},  --### Works without parameters
   [df.unit_thought_type.MoreWeaponRacks] = {["caption"] = "not having enough weapon racks"},  --### Works without parameters
   [df.unit_thought_type.MoreArmorStands] = {["caption"] = "not having enough armor stands"},  --### Works without parameters
   [df.unit_thought_type.RoomPretension] = {["caption"] = "by a lesser's pretentious [subthought] arrangements", 
                                            ["subthought"] = {"undefined room_type enum",
                                                              (function (subthought)
                                                                 return pretention_room_of (subhtought)
                                                               end)}},
   [df.unit_thought_type.LackTables] = {["caption"] = "at the lack of dining tables"},  -- type: ANNOYANCE, unk2: 100, strength: 100, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.CrowdedTables] = {["caption"] = "eating at a crowded table"},  --### Works without parameters
   [df.unit_thought_type.DiningQuality] = {["caption"] = "dining in [severity] dining room",
                                           ["severity"] = {"df.item_quality value",
                                                           (function (severity)
                                                              return dining_room_quality_of (severity)
                                                            end)}},
   [df.unit_thought_type.NoDining] = {["caption"] = "being without a proper dining room"},  -- type: ANNOYANCE, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.LackChairs] = {["caption"] = "at the lack of chairs"},  -- type: ANNOYANCE, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.TrainingBond] = {["caption"] = "after forming a bond with an animal training partner"}, -- type: AFFECTION, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.Rescued] = {["caption"] = "after being rescued"},  -- type: GRATITUDE, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftt, unk7: 0
   [df.unit_thought_type.RescuedOther] = {["caption"] = "after bringing somebody to rest in bed"},  -- type: SYMPATHY, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.SatisfiedAtWork] = {["caption"] = "at work"},  --  ####subthought ignored mostly. Not "slaughter an animal" -- type: SATISFACTION, unk2: 0, strength: 0, subthought: 105, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.TaxedLostProperty] = {["caption"] = "after losing property to the tax collector's escorts"},  --### Works without parameters
   [df.unit_thought_type.Taxed] = {["caption"] = "after being taxed"},  --### Works without parameters
   [df.unit_thought_type.LackProtection] = {["caption"] = "not having adequate protection"},  --### Works without parameters
   [df.unit_thought_type.TaxRoomUnreachable] = {["caption"] = "after being unable to reach a room for tax collection"},  --### Works without parameters
   [df.unit_thought_type.TaxRoomMisinformed] = {["caption"] = "after being misinformed about a room for tax collection"},  --### Works without parameters
   [df.unit_thought_type.PleasedNoble] = {["caption"] = "having pleased a noble"},  --### Works without parameters
   [df.unit_thought_type.TaxCollectionSmooth] = {["caption"] = "that the tax collection went smoothly"},  --### Works without parameters
   [df.unit_thought_type.DisappointedNoble] = {["caption"] = "having disappointed a noble"},  --### Works without parameters
   [df.unit_thought_type.TaxCollectionRough] = {["caption"] = "that the tax collection didn't go smoothly"},  --### Works without parameters
   [df.unit_thought_type.MadeFriend] = {["caption"] = "after making a friend"}, --### type: FONDNESS, unk2: 0, strength: 0, subthought: 102208, severity: 0, flags: fftf, unk7: 0. subthought = HF id?
   [df.unit_thought_type.FormedGrudge] = {["caption"] = "after forming a grudge"},  --### type: DISLIKE, unk2: 0, strength: 0, subthought: 7648, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.AnnoyedVermin] = {["caption"] = "after being accosted by [subthought]", -- type: ANNOYANCE, unk2: 0, strength: 0, subthought: 528, severity: 0, flags: fftf, unk7: 0
                                           ["subthought"] = {"df.global.world.raws.creatures.all index",
                                                             (function (subthought)
                                                                return df.global.world.raws.creatures.all [subthought].name [1]
                                                              end)}},
   [df.unit_thought_type.NearVermin] = {["caption"] = "after being near [subthought]",  -- type: ENJOYMENT, unk2: 0, strength: 0, subthought: 215, severity: 0, flags: fftf, unk7: 0
                                        ["subthought"] = {"df.global.world.raws.creatures.all index",
                                                          (function (subthought)
                                                             return df.global.world.raws.creatures.all [subthought].name [1]
                                                           end)}},
   [df.unit_thought_type.PesteredVermin] = {["caption"] = "after being pestered by [subthought]", -- type: DISTRESS, unk2: 0, strength: 0, subthought: 477, severity: 0, flags: fftf, unk7: 0
                                            ["subthought"] = {"df.global.world.raws.creatures.all index",
                                                              (function (subthought)
                                                                 return df.global.world.raws.creatures.all [subthought].name [1]
                                                               end)}},
   [df.unit_thought_type.AcquiredItem] = {["caption"] = "after a satisfying acquisition"}, -- type: PLEASURE, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.AdoptedPet] = {["caption"] =  "after adopting a new pet",  -- type: HAPPINESS, unk2: 0, strength: 0, subthought: 171, severity: 0, flags: fftf, unk7: 0
                                        ["extended_caption"] = "after adopting a new pet [subthought]",
                                        ["subthought"] = {"df.global.world.raws.creatures.all index",
                                                          (function (subthought)
                                                             return df.global.world.raws.creatures.all [subthought].name [0]
                                                           end)}},
   [df.unit_thought_type.Jailed] = {["caption"] = "after being confined"}, -- type: ANGER, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: ffff, unk7: 0
   [df.unit_thought_type.Bath] = {["caption"] = "after a bath"}, -- type: BLISS, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: ffff, unk7: 0
   [df.unit_thought_type.SoapyBath] = {["caption"] = "after a soapy bath"},  -- type: BLISS, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.SparringAccident] = {["caption"] = "after killing somebody by accident while sparring"},  --### Works without parameters
   [df.unit_thought_type.Attacked] = {["caption"] = "after being attacked"}, -- type: SHOCK, unk2: 50, strength: 50, subthought: -1, severity: 0, flags: ffff, unk7: 53
   [df.unit_thought_type.AttackedByDead] = {["caption"] = "after being attacked by dead [HF relative]"},--### HF relative = subthought (or severity)?
   [df.unit_thought_type.SameBooze] = {["caption"] = "drinking the same old booze"},  -- type: GROUCHINESS, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.DrinkBlood] = {["caption"] = "while forced to drink bloody water"},  --### Works without parameters
   [df.unit_thought_type.DrinkSlime] = {["caption"] = "while forced to drink slime"},  --### Works without parameters
   [df.unit_thought_type.DrinkVomit] = {["caption"] = "while forced to drink vomit"},  --### Works without parameters
   [df.unit_thought_type.DrinkGoo] = {["caption"] = "while forced to drink gooey water"},  --### Works without parameters
   [df.unit_thought_type.DrinkIchor] = {["caption"] = "while forced to drink ichorous water"},  --### Works without parameters
   [df.unit_thought_type.DrinkPus] = {["caption"] = "while forced to drink purulent water"},  --### Works without parameters
   [df.unit_thought_type.NastyWater] = {["caption"] = "drinking nasty water"},  --### Works without parameters
   [df.unit_thought_type.DrankSpoiled] = {["caption"] = "after drinking something spoiled"},  --### Works without parameters
   [df.unit_thought_type.LackWell] = {["caption"] = "after drinking water without a well"},  --### Works without parameters
   [df.unit_thought_type.NearCaged] = {["caption"] = "after being near to a [subthought] in a cage",
                                       ["subthought"] = {"df.global.world.raws.creature.all index",
                                                         (function (subthought)
                                                            return df.global.world.raws.creatures.all [subthought].name [0]
                                                          end)}},
   [df.unit_thought_type.NearCagedHated] = {["caption"] = "after being near to a [animal] in a cage",
                                            ["subthought"] = {"df.global.world.raws.creature.all index",
                                                              (function (subthought)
                                                                 return df.global.world.raws.creatures.all [subthought].name [0]
                                                               end)}},
   [df.unit_thought_type.LackBedroom] = {["caption"] = "after sleeping without a proper room"},  -- type: EMBARRASSMENT, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftt, unk7: 0
   [df.unit_thought_type.BedroomQuality] = {["caption"] = "after sleeping in a [severity]", -- type: CONTENTMENT, unk2: 0, strength: 0, subthought: -1, severity: 5, flags: fftf, unk7: 0  --### Spelling fixed in original
                                            ["severity"] = {"df.item_quality value",
                                             (function (severity)
                                                return bedroom_quality_of (severity)
                                              end)}},
   [df.unit_thought_type.SleptFloor] = {["caption"] = "after sleeping on the floor"},  --### Works without parameters
   [df.unit_thought_type.SleptMud] = {["caption"] = "after sleeping in the mud"},  --### Works without parameters
   [df.unit_thought_type.SleptGrass] = {["caption"] = "after sleeping in the grass"},  -- type: ANNOYANCE, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.SleptRoughFloor] = {["caption"] = "after sleeping on a rough cave floor"},  --### Works without parameters
   [df.unit_thought_type.SleptRocks] = {["caption"] = "after sleeping on rocks"},  -- type: ANNOYANCE, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.SleptIce] = {["caption"] = "after sleeping on ice"},  --### Works without parameters
   [df.unit_thought_type.SleptDirt] = {["caption"] = "after sleeping in the dirt"},  -- type: ANNOYANCE, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.SleptDriftwood] = {["caption"] = "after sleeping on a pile of driftwood"},  --### Works without parameters
   [df.unit_thought_type.ArtDefacement] = {["caption"] = "after suffering the travesty of art defacement"},  -- type: EMPTINESS, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.Evicted] = {["caption"] = "after being evicted"},  --### Works without parameters
   [df.unit_thought_type.GaveBirth] = {["caption"] = "after giving birth to [subthought_severity]",  -- type: ADORATION, unk2: 0, strength: 0, subthought: -1, severity: 3, flags: ffff, unk7: 0
                                       ["subthought_severity"] = {"gender, child_count",
                                                                  (function (subthought, severity)
                                                                     return child_birth_of (subthought, severity)
                                                                   end)}},
   [df.unit_thought_type.SpouseGaveBirth] = {["caption"] = "[subthought_severity]",  --  type: LOVE, unk2: 0, strength: 0, subthought: 11, severity: 1, flags: ffff, unk7: 0
                                             ["subthought_severity"] = {"df.unit_relationship_type value, child_count",
                                                                        (function (subthought, severity)
                                                                           return spouse_birth_of (subthought, severity)
                                                                         end)}},
   [df.unit_thought_type.ReceivedWater] = {["caption"] = "after receiving water"}, -- type: SATISFACTION, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.GaveWater] = {["caption"] = "after giving somebody water"}, -- type: SYMPATHY, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.ReceivedFood] = {["caption"] = "after receiving food"}, -- type: SATISFACTION, unk2: 100, strength: 100, subthought: -1, severity: 0, flags: ffff, unk7: 0
   [df.unit_thought_type.GaveFood] = {["caption"] = "after giving somebody food"},  -- type: SYMPATHY, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.Talked] = {["caption"] = "talking with [subthought]", -- type: FONDNESS, unk2: 0, strength: 0, subthought: 13, severity: 0, flags: fftf, unk7: 0
                                    ["subthought"] = {"df.unit_relationship_type value",
                                                      (function (subthought)
                                                         local prefix = "a "
                                                         if subthought == df.unit_relationship_type.Spouse then  --### is Master singular?
                                                           prefix = "the "
                                                         end
                                                         
                                                         return prefix .. string.lower (df.unit_relationship_type [subthought])
                                                       end)}},
   [df.unit_thought_type.OfficeQuality] = {["caption"] = "conducted meeting in a [severity]", -- type: SATISFACTION, unk2: 0, strength: 0, subthought: -1, severity: 5, flags: fftf, unk7: 0
                                           ["severity"] = {"df.item_quality value",
                                                           (function (severity)
                                                              return office_quality_of (severity)
                                                            end)}},
   [df.unit_thought_type.MeetingInBedroom] = {["caption"] = "having to conduct an official meeting in a bedroom"},  -- type: EMBARRASSMENT, unk2: 25, strength: 0, subthought: -1, severity: 0, flags: fftt, unk7: 0
   [df.unit_thought_type.MeetingInDiningRoom] = {["caption"] = "having to conduct an official meeting in a dining room"},  -- type: EMBARRASSMENT, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftt, unk7: 0
   [df.unit_thought_type.NoRooms] = {["caption"] = "not having any rooms"},  --### Works without parameters
   [df.unit_thought_type.TombQuality] = {["caption"] = "having a [severity] tomb after gaining another year",
                                         ["severity"] = {"df.item_quality value",
                                                         (function (severity)
                                                            return tomb_quality_of (severity)
                                                          end)}},
   [df.unit_thought_type.TombLack] = {["caption"] = "about not having a tomb after gaining another year"},  --### Works without parameters
   [df.unit_thought_type.TalkToNoble] = {["caption"] = "after talking to a pillar of society"},  --### Works without parameters
   [df.unit_thought_type.InteractPet] = {["caption"] = "after interacting with a pet", --  type: FONDNESS, unk2: 0, strength: 0, subthought: 171, severity: 0, flags: fftf, unk7: 0
                                         ["extended_caption"] = "after interacting with a pet [subthought]",
                                         ["subthought"] = {"df.global.world.raws.creatures.all index",
                                                           (function (subthought)
                                                              return df.global.world.raws.creatures.all [subthought].name [0]
                                                            end)}},
   [df.unit_thought_type.ConvictionCorpse] = {["caption"] = "after a long-dead corpse was convicted of a crime"},  --### Works without parameters
   [df.unit_thought_type.ConvictionAnimal] = {["caption"] = "after an animal was convicted of a crime"},  --### Works without parameters
   [df.unit_thought_type.ConvictionVictim] = {["caption"] = "after the bizarre conviction against all reason of the victim of a crime"},  --### Works without parameters
   [df.unit_thought_type.ConvictionJusticeSelf] = {["caption"] = "upon receiving justice through a criminal's conviction"},  --### Works without parameters
   [df.unit_thought_type.ConvictionJusticeFamily] = {["caption"] = "when a family member received justice through a criminal's conviction"},  --### Works without parameters
   [df.unit_thought_type.Decay] = {["caption"] = "after being forced to endure the decay of [subthought]",  -- type: RIGHTEOUS_INDIGNATION, unk2: 0, strength: 0, subthought: 11, severity: 0, flags: ffff, unk7: 0
                                   ["subthought"] = {"df.unit_relationship_type value",
                                                     (function (subthought)
                                                        return decay_of (subthought)
                                                      end)}},
   [df.unit_thought_type.NeedsUnfulfilled] = {["caption"] = "after [subthought_severity]",
                                               ["subthought_severity"] = {"df.need_type value, (HF id)",
                                                                          (function (subthought, severity)
                                                                             return unfulfulled_need_of (subthought, severity)
                                                                           end)}},
   [df.unit_thought_type.Prayer] = {["caption"] = "after communing with [subthought]", -- type: RAPTURE, unk2: 71, strength: 100, subthought: 266, severity: 0, flags: fftf, unk7: 0
                                    ["subthought"] = {"HF id",
                                                      (function (subthought)
                                                         return hf_name (subthought)
                                                       end)}},
   [df.unit_thought_type.DrinkWithoutCup] = {["caption"] = "after having a drink without using a goblet, cup or mug"}, -- type: ANNOYANCE, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.ResearchBreakthrough] = {["caption"] = "after making a breakthrough concerning [subthought_severity]",
                                                  ["subthought_severity"] = {"knowledge_scholar_category_flag index, flag index",
                                                                             (function (subthought, severity)
                                                                                return get_topic (subthought, severity)
                                                                              end)}},
   [df.unit_thought_type.ResearchStalled] = {["caption"] = "after being unable to advance the study of [subthought_severity]",
                                             ["subthought_severity"] = {"knowledge_scholar_category_flag index, flag index",
                                                                        (function (subthought, severity)
                                                                           return get_topic (subthought, severity)
                                                                         end)}},
   [df.unit_thought_type.PonderTopic] = {["caption"] = "after pondering [subthought_severity]",  -- DONE type: INTEREST, unk2: 0, strength: 0, subthought: 12, severity: 10, flags: fftf, unk7: 0
                                         ["subthought_severity"] = {"knowledge_scholar_category_flag index, flag index",
                                                                    (function (subthought, severity)
                                                                       return get_topic (subthought, severity)
                                                                     end)}},
   [df.unit_thought_type.DiscussTopic] = {["caption"] = "after discussing [subthought_severity]",  -- type: CONTENTMENT, unk2: 0, strength: 0, subthought: 13, severity: 20, flags: fftf, unk7: 0
                                          ["subthought_severity"] = {"knowledge_scholar_category_flag index, flag index",
                                                                     (function (subthought, severity)
                                                                        return get_topic (subthought, severity)
                                                                      end)}},
   [df.unit_thought_type.Syndrome] = {["caption"] = "due to [subthought]", -- type: EUPHORIA, unk2: 0, strength: 0, subthought: 70, severity: 59, flags: fftf, unk7: 0 --### severity?
                                      ["subthought"] = {"df.global.world.raws.syndromes.all id",
                                                        (function (subthought)
                                                           return df.syndrome.find (subthought).syn_name
                                                         end)}},
   [df.unit_thought_type.Perform] = {["caption"] = "while performing"}, -- type: ENJOYMENT, unk2: 0, strength: 0, subthought: 3815, severity: 0, flags: fftf, unk7: 0  --### subthought = Incident id?
   [df.unit_thought_type.WatchPerform] = {["caption"] = "after watching a performance"},--### type: DELIGHT, unk2: 100 (0), strength 100 (0), subthought: 225, severity: 0, flags: fftf, unk7: 0 => "I saw a human recite Music Painful at the Eternal Breakfast of Lunch. How very delightful!"  --### Subthought?
   [df.unit_thought_type.RemoveTroupe] = {["caption"] = "after being removed from a performance troupe"},  --### Works without parameters
   [df.unit_thought_type.LearnTopic] = {["caption"] = "after learning about [subthought_severity]", -- type: SATISFACTION, unk2: 0, strength: 0, subthought: 5, severity: 4, flags: fftf, unk7: 0
                                        ["subthought_severity"] = {"knowledge_scholar_category_flag index, flag index",
                                                                   (function (subthought, severity)
                                                                      return get_topic (subthought, severity)
                                                                    end)}},
   [df.unit_thought_type.LearnSkill] = {["caption"] = "after learning about [subthought]", -- type: SATISFACTION, unk2: 0, strength: 0, subthought: 101, severity: 0, flags: fftf, unk7: 0
                                        ["subthought"] = {"df.job_skill value",
                                                          (function (subthought)
                                                             return string.lower (df.job_skill [subthought])
                                                           end)}},
   [df.unit_thought_type.LearnBook] = {["caption"] = "after learning [subthought]", -- type: SATISFACTION, unk2: 0, strength: 0, subthought: 194395, severity: 0, flags: fftf, unk7: 0
                                       ["subthought"] = {"df.global.world.written_contents.all id",
                                                         (function (subthought)
                                                            return df.written_content.find (subthought).title
                                                          end)}},
   [df.unit_thought_type.LearnInteraction] = {["caption"] = "after learning [subthought]",
                                              ["subthought"] = {"#df.global.world.raws.interactions id",
                                               (function (subthought)
                                                  if #df.global.world.raws.interactions [subthought].sources > 0 then
                                                    return df.global.world.raws.interactions [subthought].sources [0].name
      
                                                  else
                                                    return "after learning powerful secrets."
                                                  end
                                                end)}},
   [df.unit_thought_type.LearnPoetry] = {["caption"] = "after learning [subthought]",
                                         ["subthought"] = {"df.global.world.poetic_forms.all id",
                                                           (function (subthought)
                                                              return dfhack.TranslateName (df.poetic_form.find (subthought).name, true)
                                                            end)}},
   [df.unit_thought_type.LearnMusic] = {["caption"] = "after learning [subthought]",
                                        ["subthought"] = {"df.global.world.musical_forms.all id",
                                                          (function (subthought)
                                                             return dfhack.TranslateName (df.musical_form.find (subthought).name, true)
                                                           end)}},
   [df.unit_thought_type.LearnDance] = {["caption"] = "after learning [subthought]",
                                        ["subthought"] = {"df.global.world.dance_forms.all id",
                                                          function (subthought)
                                                            return dfhack.TranslateName (df.dance_form.find (emotion.subthought).name, true)
                                                          end}},
   [df.unit_thought_type.TeachTopic] = {["caption"] = "after teaching [subthought_severity]",
                                        ["subthought_severity"] = {"knowledge_scholar_category_flag index, flag index",
                                                                   (function (subthought, severity)
                                                                      return get_topic (subthought, severity)
                                                                    end)}},
   [df.unit_thought_type.TeachSkill] = {["caption"] = "after teaching [subthought]", -- type: SATISFACTION, unk2: 0, strength: 0, subthought: 103, severity: 0, flags: fftf, unk7: 0
                                        ["subthought"] = {"df.job_skill value",
                                                          (function (subthought)
                                                             return string.lower (df.job_skill [subthought])
                                                           end)}},
   [df.unit_thought_type.ReadBook] = {["caption"] = "after reading [subthought]",  -- type: SATISFACTION, unk2: 0, strength: 0, subthought: 194395, severity: 0, flags: fftf, unk7: 0
                                      ["subthought"] = {"written contents.all index",
                                                        (function (subthought)
                                                           return df.written_content.find (subthought).title
                                                         end)}},
   [df.unit_thought_type.WriteBook] = {["caption"] = "after writing [subthought]",-- type: SATISFACTION, unk2: 0, strength: 0, subthought: 582252, severity: 0, flags: fftf, unk7: 0
                                       ["subthought"] = {"written contents.all index",
                                                         (function (subthought)
                                                            return df.written_content.find (subthought).title
                                                          end)}},
   [df.unit_thought_type.BecomeResident] = {["caption"] = "after being granted residency",  -- type: SATISFACTION, unk2: 0, strength: 0, subthought: 1791, severity: 0, flags: fftf, unk7: 0 ###Caption spell correction.
                                            ["extended_caption"] = "after being granted residency at [subthought]",
                                            ["subthought"] = {"site id",
                                                              (function (subthought)
                                                                 return dfhack.TranslateName (df.world_site.find (subthought).name, true)
                                                               end)}},
   [df.unit_thought_type.BecomeCitizen] = {["caption"] = "after being granted citizenship",  -- type: SATISFACTION, unk2: 100, strength: 100, subthought: 8359, severity: 0, flags: ffff, unk7: 0
                                           ["extended_caption"] = "after becoming a citizen of [subthought]",
                                           ["subthought"] = {"df.historical_entity id",
                                                             (function (subthought)
                                                                return dfhack.TranslateName (df.historical_entity.find (subthought).name, true)
                                                              end)}},
   [df.unit_thought_type.DenyResident] = {["caption"] = "after being denied residency",  -- type: INSULT, unk2: 0, strength: 0, subthought: 1837, severity: 0, flags: fftf, unk7: 0
                                          ["extended_caption"] = "after being denied residency at [subthought]",
                                          ["subthought"] = {"site id",
                                                            (function (subthought)
                                                               return dfhack.TranslateName (df.world_site.find (subthought).name, true)
                                                             end)}},
   [df.unit_thought_type.DenyCitizen] = {["caption"] = "after being denied citizenship",  --### Works without parameters. The below is a guess based on BecomeCitizen
                                         ["extended_caption"] = "after being refused to become a citizen of [subthought]",
                                         ["subthought"] = {"df.historical_entity id",
                                                           (function (subthought)
                                                              return dfhack.TranslateName (df.historical_entity.find (subthought).name, true)
                                                            end)}},
   [df.unit_thought_type.LeaveTroupe] = {["caption"] = "after leaving a performance troupe"},  --### Works without parameters
   [df.unit_thought_type.MakeBelieve] = {["caption"] = "after playing make believe"}, -- type: ENJOYMENT, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.PlayToy] = {["caption"] = "after playing with [subthought]", -- type: ENJOYMENT, unk2: 0, strength: 0, subthought: 0, severity: 0, flags: fftf, unk7: 0
                                     ["subthought"] = {"df.global.world.raws.itemdefs.toys index",
                                                       (function (subthought)
                                                          return df.global.world.raws.itemdefs.toys [subthought].name
                                                        end)}},
   [df.unit_thought_type.DreamAbout] = {["caption"] = "*DREAMABOUT*"},  --### Looks like there should be parameters... Empty without Not HF id nor unit id.
   [df.unit_thought_type.Dream] = {["caption"] = "*DREAM*"},  --### Looks like there should be parameters... Empty without
   [df.unit_thought_type.Nightmare] = {["caption"] = "*NIGHTMARE*"},  --### Looks like there should be parameters... Empty without
   [df.unit_thought_type.Argument] = {["caption"] = "after getting into an argument", -- type: BITTERNESS, unk2: 0, strength: 0, subthought: 99640, severity: 0, flags: fftf, unk7: 0. "I got into an argument with Niri Matchedsaffron. <emotion>"
                                      ["extended_caption"] = "after getting into an argument with [subthought]",
                                      ["subthought"] = {"HF id",
                                                        (function (subthought)
                                                           return dfhack.TranslateName (df.historical_figure.find (subthought).name, true)
                                                         end)}},
   [df.unit_thought_type.CombatDrills] = {["caption"] = "after combat drills"},  -- type: PLEASURE, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.ArcheryPractice] = {["caption"] = "after practicing at the archery target"},  --### Works without parameters
   [df.unit_thought_type.ImproveSkill] = {["caption"] = "upon improving [subthought]", -- type: SATISFACTION, unk2: 0, strength: 0, subthought: 10, severity: 0, flags: fftf, unk7: 0
                                          ["subthought"] = {"df.job_skill value",
                                                            (function (subthought)
                                                               return string.lower (df.job_skill [subthought])
                                                             end)}},
   [df.unit_thought_type.WearItem] = {["caption"] = "after putting on a [severity] item",-- type: CONTENTMENT, unk2: 0, strength: 0, subthought: -1, severity: 1, flags: fftf, unk7: 0
                                      ["severity"] = {"df.item_quality value",
                                                      (function (severity)
                                                         return item_quality_of (severity)
                                                       end)}},
   [df.unit_thought_type.RealizeValue] = {["caption"] = "after realizing the [level] of [value]", -- type: SATISFACTION, unk2: 0, strength: 0, subthought: 6, severity: 29, flags: fftf, unk7: 0
                                          ["subthought_severity"] = {"df.value_type value, value strength",
                                                                     (function (subthought, severity)
                                                                        return realize_value_of (subthought, severity)
                                                                      end)}},
   [df.unit_thought_type.OpinionStoryteller] = {["caption"] = "*OPINIONSTORYTELLER*"},  --### Requires parameters?
   [df.unit_thought_type.OpinionRecitation] = {["caption"] = "*OPIOIONRECITATION*"},  --### Requires parameters?
   [df.unit_thought_type.OpinionInstrumentSimulation] = {["caption"] = "*OPINIONINSTRUMENTSIMULATION*"},  --### Requires parameters?
   [df.unit_thought_type.OpinionInstrumentPlayer] = {["caption"] = "*OPINIONINSTRUMENTPLAYER*"},  --### Requires parameters?
   [df.unit_thought_type.OpinionSinger] = {["caption"] = "*OPINIONSINGER*"},  --### Requires parameters?
   [df.unit_thought_type.OpinionChanter] = {["caption"] = "*OPINIONCHANTER*"},  --### Requires parameters?
   [df.unit_thought_type.OpinionDancer] = {["caption"] = "*OPINIONDANCER*"},  --### Requires parameters?
   [df.unit_thought_type.OpinionStory] = {["caption"] = "*OPINIONSTORY*"},  --### Requires parameters?
   [df.unit_thought_type.OpinionPoetry] = {["caption"] = "*OPINIONPOETRY*"},  --### Requires parameters?
   [df.unit_thought_type.OpinionMusic] = {["caption"] = "*OPINIONMUSIC*"},  --### Requires parameters?
   [df.unit_thought_type.OpinionDance] = {["caption"] = "*OPINIONDANCE*"},  --### Requires parameters?
   [df.unit_thought_type.Defeated] = {["caption"] = "after defeating somebody"},   --### Parameters?
   [df.unit_thought_type.FavoritePossession] = {["caption"] = "*FAVORITEPOSSESSION*"},  --### Requires parameters?
   [df.unit_thought_type.PreserveBody] = {["caption"] = "*PRESERVEBODY*"},  --### Requires parameters?
   [df.unit_thought_type.Murdered] = {["caption"] = "after murdering somebody"},  --### Parameters?
   [df.unit_thought_type.HistEventCollection] = {["caption"] = "*HISTEVENTCOLLECTION*"},  --### Requires parameters?
   [df.unit_thought_type.ViewOwnDisplay] = {["caption"] = "after viewing [subthought] in a personal museum",
                                            ["subthought"] = {"df.global.world.artifacts.all id ELSE df.global.world.items.all id",
                                                              (function (subthought)
                                                                 return display_name (subthought)
                                                               end)}},
   [df.unit_thought_type.ViewDisplay] = {["caption"] = "after viewing [subthought] on display", -- type: PLEASURE, unk2: 0, strength: 0, subthought: 11222, severity: 0, flags: fftf, unk7: 0
                                         ["subthought"] = {"df.global.world.artifacts.all id ELSE df.global.world.items.all id",
                                                           (function (subthought)
                                                              return display_name (subthought)
                                                            end)}},
   [df.unit_thought_type.AcquireArtifact] = {["caption"] = "after acquiring [subthought]",
                                             ["subthought"] = {"df.global.world.artifacts.all id",
                                                               (function (subthought)
                                                                  local artifact = df.artifact_record.find (subthought)
    
                                                                  if artifact then
                                                                    return dfhack.TranslateName (artifact.name, true)
    
                                                                  else
                                                                    return "an unknown artifact"
                                                                  end
                                                                end)}},
   [df.unit_thought_type.DenySanctuary] = {["caption"] = "after a child was turned away from sanctuary"},  --### Works without parameters
   [df.unit_thought_type.CaughtSneaking] = {["caption"] = "after being caught sneaking"},  -- type: FEROCITY, unk2: 0, strength: 0, subthought: -1, severity: 0, flags: fftf, unk7: 0
   [df.unit_thought_type.GaveArtifact] = {["caption"] = "after [subthought] was given away",
                                          ["subthought"] = {"df.global.world.artifacts.all id",
                                                            (function (subthought)
                                                               local artifact = df.artifact_record.find (subthought)
    
                                                               if artifact then
                                                                 return dfhack.TranslateName (artifact.name, true)
    
                                                               else
                                                                 return "an unknown artifact"
                                                               end
                                                             end)}}}
        
--------------------------------------------

local gender_translation = {["he"] = {[-1] = "it", [0] = "she", [1] = "he", [2] = "it"},
                            ["his"] = {[-1] = "its", [0] = "her", [1] = "his", [2] = "its"},
                            ["him"] = {[-1] = "it", [0] = "her", [1] = "him"}, [2] = "it"}
                            
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
  local pronoun = gender_translation.he [gender]
  local base_color
  
  if emotion.strength > 0 then
    base_color = COLOR_WHITE
  else
    base_color = COLOR_GREY
  end
    
  dfhack.color (base_color)
  dfhack.print (pronoun .. " ")
  
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
  local base_color
  local front
  local token
  local rear

  if unit_thoughts [emotion.thought].extended_caption then
    front, token, rear = token_extractor (unit_thoughts [emotion.thought].extended_caption)
    
  else
    front, token, rear = token_extractor (unit_thoughts [emotion.thought].caption)
  end
  
  while token do
    if token == "subthought" then
--     dfhack.println (df.unit_thought_type [emotion.thought])  --  Activate for debugging when it blows up...
      front = front .. unit_thoughts [emotion.thought].subthought [2] (emotion.subthought) .. rear
      
    elseif token == "severity" then
--     dfhack.println (df.unit_thought_type [emotion.thought])  --  Activate for debugging when it blows up...
      front = front .. unit_thoughts [emotion.thought].severity [2] (emotion.severity) .. rear
      
    elseif token == "subthought_severity" then
--     dfhack.println (df.unit_thought_type [emotion.thought])  --  Activate for debugging when it blows up...
      front = front .. unit_thoughts [emotion.thought].subthought_severity [2] (emotion.subthought, emotion.severity) .. rear
      
    elseif token == "he" then
--     dfhack.println (df.unit_thought_type [emotion.thought])  --  Activate for debugging when it blows up...
      front = front .. gender_translation.he [gender] .. rear
      
    elseif token == "his" then
--     dfhack.println (df.unit_thought_type [emotion.thought])  --  Activate for debugging when it blows up...
      front = front .. gender_translation.his [gender] .. rear
      
    elseif token == "him" then
--     dfhack.println (df.unit_thought_type [emotion.thought])  --  Activate for debugging when it blows up...
      front = front .. gender_translation.him [gender] .. rear
      
    else
      dfhack.printerr ("Unhandled token encountered [" ..  token .. "] for thought " .. df.unit_thought_type [emotion.thought])
      front = front .. token .. rear
    end

    front, token, rear = token_extractor (front)
  end
  
  if emotion.strength > 0 then
    base_color = COLOR_WHITE
  else
    base_color = COLOR_GREY
  end
    
  print_emotion_value (gender, emotion)
  dfhack.color (base_color)
  dfhack.println (front .. ".")
end

------------------------------------------

function get_hf_name (id)
  local hf = df.historical_figure.find (id)

  if hf ~= nil then
    if hf.name.has_name then
      return dfhack.TranslateName (hf.name, true) .. "/" .. dfhack.TranslateName (hf.name, false)
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
  
  if #f1.attitude > 0 then
    if f1.attitude [0] == 1 or    --  Friend
       f1.attitude [0] == 2 or    --  Grudge
       f1.attitude [0] == 3 then  --  Bonded
      f1_relation_level = 1      --  Friend/Grudge/Bonded
    
    elseif f1.attitude [0] == 7 then
      f1_relation_level = 2      --  Friendly Terms
    end
  end
  
  if #f2.attitude > 0 then
    if f2.attitude [0] == 1 or    --  Friend
       f2.attitude [0] == 2 or    --  Grudge
       f2.attitude [0] == 3 then  --  Bonded
      f2_relation_level = 1      --  Friend/Grudge/Bonded
      
    elseif f2.attitude [0] == 7 then
      f2_relation_level = 2      --  Friendly Terms
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
  
  if f1.rank == f2.rank then
    return f1.histfig_id > f2.histfig_id
    
  else
    return f1.rank < f2.rank
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
  
  for i = df.unit_thought_type._first_item, df.unit_thought_type._last_item do
    if df.unit_thought_type [i] ~= nil and
       unit_thoughts [i] == nil then
      dfhack.printerr ("Missing unit_thoughts element " .. df.unit_thought_type [i])
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
        if relation.rank > 0 then
          if #relation.attitude == 0 then
          --### "Long-term Acquaintance" is either determined based on the age of the relation or on the rank.
--            dfhack.print ("Passing Acquaintance ")
            dfhack.print ("Passing Acquaintance " .. tostring (relation.rank) .. " ")
          
          elseif relation.attitude [0] == 1 then
--            dfhack.print ("Friend ")
            dfhack.print ("Friend " .. tostring (relation.counter [0]) .. " " .. tostring (relation.rank) .. " ")
            if #relation.attitude >= 2 and
               relation.attitude [1] == 7 then
              dfhack.print (tostring (relation.counter [1]) .. " ")
            end
          
          elseif relation.attitude [0] == 2 then
            dfhack.print ("Grudge ")
          
          elseif relation.attitude [0] == 3 then
            dfhack.print ("Bonded ")
          
          elseif relation.attitude [0] == 7 then
--            dfhack.print ("Friendly Terms ")
            dfhack.print ("Friendly Terms " .. tostring (relation.counter [0]) .. " " .. tostring (relation.rank) .. " ")
        
          else
            dfhack.error ("Unknown primary relation found " .. tostring (relation.attitude [0]))
          end
                
          dfhack.println (get_hf_name (relation.histfig_id))
        end
      end
    end
  end
  
  dfhack.color (COLOR_RESET)
end

thoughts ()