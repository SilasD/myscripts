local utils = require('utils')
--[[=begin

stats
======
Based on gaydar.
Shows the sexual orientation of units, useful for social engineering or checking
the viability of livestock breeding programs. Also adds pregnancy and existence of a spouse.  Use ``stats -help`` for information
on available filters for orientation, citizenship, species, etc.

=end]]

validArgs = utils.invert({
  'all',
  'citizens',
  'named',
  'notStraight',
  'gayOnly',
  'biOnly',
  'straightOnly',
  'asexualOnly',
  'help'
})


local args = utils.processArgs({...}, validArgs)

if args.help then
 print(
[[stats.lua
arguments:
    -help
        print this help message
unit filters:
    -all
        shows orientation of every creature
    -citizens
        shows only orientation of citizens in fort mode
    -named
        shows orientation of all named units on map
orientation filters:
    -notStraight
        shows only creatures who are not strictly straight
    -gayOnly
        shows only creatures who are strictly gay
    -biOnly
        shows only creatures who can get into romances with
        both sexes
    -straightOnly
        shows only creatures who are strictly straight.
    -asexualOnly
        shows only creatures who are strictly asexual.

    No argument will show the orientation of the unit
    under the cursor.
]])
 return
end

function getSexString(sex)
 local sexStr
 if sex==0 then
  sexStr=string.char(12)
 elseif sex==1 then
  sexStr=string.char(11)
 else
  return ""
 end
 return string.char(40)..sexStr..string.char(41)
end

local function determineorientation(unit)
 if unit.sex~=-1 then
  local return_string=''
  local orientation=unit.status.current_soul.orientation_flags
  if orientation.indeterminate then
   return 'indeterminate (probably adventurer)'
  end
  local male_interested,asexual=false,true
  if orientation.romance_male then
   return_string=return_string..' likes males'
   male_interested=true
   asexual=false
  elseif orientation.marry_male then
   return_string=return_string..' will marry males'
   male_interested=true
   asexual=false
  end
  if orientation.romance_female then
   if male_interested then
 return_string=return_string..' and likes females'
   else
    return_string=return_string..' likes females'
   end
   asexual=false
  elseif orientation.marry_female then
   if male_interested then
 return_string=return_string..' and will marry females'
   else
    return_string=return_string..' will marry females'
   end
   asexual=false
  end
  if asexual then
   return_string=' is asexual'
  end
  return return_string
 else
  return "is not biologically capable of sex"
 end
end

local function determinepregnancy (unit)
  if unit.pregnancy_genes ~= nil then
    return ' and is pregnant'
    
  elseif unit.sex == 0 then
    return ' and is not pregnant'
  
  else
    return ""
  end
end

local function nameOrSpeciesAndNumber(unit)
 if unit.name.has_name then
  return dfhack.TranslateName(dfhack.units.getVisibleName(unit), true)..' '..getSexString(unit.sex),true
 else
  return 'Unit #'..unit.id..' ('..df.creature_raw.find(unit.race).caste[unit.caste].caste_name[0]..' '..getSexString(unit.sex)..')',false
 end
end

local function determinespouse (unit)
  if unit.relationship_ids.Spouse ~= -1 then
    if df.unit.find (unit.relationship_ids.Spouse) then
      local dead = ""
      
      if df.unit.find (unit.relationship_ids.Spouse).flags2.killed then
        dead = "dead "
      end
      
      return ', is married to ' .. dead .. dfhack.TranslateName (dfhack.units.getVisibleName (df.unit.find(unit.relationship_ids.Spouse)), true)
      
    else
      local hf = df.historical_figure.find (unit.hist_figure_id)
      local spouse = ""
      local dead = ""
      
      for i, histfig_link in ipairs (hf.histfig_links) do
        if histfig_link._type == df.histfig_hf_link_spousest then
          spouse = df.historical_figure.find (histfig_link.target_hf)
          break
        end        
      end

      if spouse and
         spouse.died_year ~= -1 then
        dead = "dead "
      end        
      
      return ', is married to ' .. dead .. 'offsite partner ' .. dfhack.TranslateName (spouse.name, true)
    end
    
  else
    return ', is not married'
  end
end

local orientations={}

if args.citizens then
 for k,v in ipairs(df.global.world.units.active) do
  if dfhack.units.isCitizen(v) then
   table.insert(orientations,nameOrSpeciesAndNumber(v) .. determineorientation(v)..determinespouse(v)..determinepregnancy(v))
  end
 end
elseif args.all then
 for k,v in ipairs(df.global.world.units.active) do
  table.insert(orientations,nameOrSpeciesAndNumber(v)..determineorientation(v)..determinespouse(v)..determinepregnancy(v))
 end
elseif args.named then
 for k,v in ipairs(df.global.world.units.active) do
  local name,ok=nameOrSpeciesAndNumber(v)
  if ok then
   table.insert(orientations,name..determineorientation(v)..determinespouse(v)..determinepregnancy(v))
  end
 end
else
 local unit=dfhack.gui.getSelectedUnit(true)
 local name,ok=nameOrSpeciesAndNumber(unit)
 print(name..determineorientation(unit)..determinespouse(unit)..determinepregnancy(unit))
 return
end

function isNotStraight(v)
 if v:find(string.char(12)) and v:find(' female') then return true end
 if v:find(string.char(11)) and v:find(' male') then return true end
 if v:find('asexual') then return true end
 if v:find('indeterminate') then return true end
 return false
end

function isGay(v)
 if v:find('asexual') then return false end
 if v:find(string.char(12)) and not v:find(' male') then return true end
 if v:find(string.char(11)) and not v:find(' female') then return true end
 return false
end

function isAsexual(v)
 if v:find('asexual') or v:find('indeterminate') then return true else return false end
end

function isBi(v)
 if v:find(' female') and v:find(' male') then return true else return false end
end

if args.notStraight then
 local totalNotShown=0
 for k,v in ipairs(orientations) do
  if isNotStraight(v) then print(v) else totalNotShown=totalNotShown+1 end
 end
 print('Total not shown: '..totalNotShown)
elseif args.gayOnly then
 local totalNotShown=0
 for k,v in ipairs(orientations) do
  if isGay(v) then print(v) else totalNotShown=totalNotShown+1 end
 end
 print('Total not shown: '..totalNotShown)
elseif args.asexualOnly then
 local totalNotShown=0
 for k,v in ipairs(orientations) do
  if isAsexual(v) then print(v) else totalNotShown=totalNotShown+1 end
 end
 print('Total not shown: '..totalNotShown)
elseif args.straightOnly then
 local totalNotShown=0
 for k,v in ipairs(orientations) do
  if not isNotStraight(v) then print(v) else totalNotShown=totalNotShown+1 end
 end
 print('Total not shown: '..totalNotShown)
elseif args.biOnly then
 local totalNotShown=0
 for k,v in ipairs(orientations) do
  if isBi(v) then print(v) else totalNotShown=totalNotShown+1 end
 end
 print('Total not shown: '..totalNotShown)
else
 for k,v in ipairs(orientations) do
  print(v)
 end
end
