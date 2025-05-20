-- TODO maybe suck in siren.lua and war-animals-send-on-raid.lua ?
--     is that done by dfhack.reqscript(name) ?

local utils = require('utils')

local verbose = false

local translateName = dfhack.TranslateName or dfhack.translation.translateName

--local name = dfhack.current_script_name()

function printf(...)
  print(dfhack.df2console(string.format(...)))
end

function vprintf(...)
  if verbose then
    printf(...)
  end
end


-- copy-pasted from siren.lua
function add_thought(unit, emotion, thought)
    unit.status.current_soul.personality.emotions:insert('#', { new = true,
    type = emotion,
--    unk2=1,
    relative_strength=1,    -- SWD 10/25/24 changed from unk2
    strength=1,
    thought=thought,
    subthought=0,
    severity=0,
    flags={},
--    unk7=0,
    next_overcome_timer=0,  -- SWD 10/25/24 changed from unk7
    year=df.global.cur_year,
    year_tick=df.global.cur_year_tick})
end

-- copy-pasted from siren.lua
function wake_unit(unit)
    local job = unit.job.current_job
    if not job or job.job_type ~= df.job_type.Sleep then
        return
    end

    if job.completion_timer > 0 then
        unit.counters.unconscious = 0
        add_thought(unit, df.emotion_type.Grouchiness, df.unit_thought_type.Drowsy)
    elseif job.completion_timer < 0 then
        add_thought(unit, df.emotion_type.Grumpiness, df.unit_thought_type.Drowsy)
    end

    job.pos:assign(unit.pos)

    job.completion_timer = 0

    unit.path.dest:assign(unit.pos)
    unit.path.path.x:resize(0)
    unit.path.path.y:resize(0)
    unit.path.path.z:resize(0)

    unit.counters.job_counter = 0
end


-- copy-pasted from send-war-animals-on-raid.lua
local squad_names = {}		-- sparse, maps squad_id to squad name or alias, cache for speed.
local raiding_units = {}	-- sparse, maps unit_id to squad_id.  also true/false 'is on a raid'.
local unit_names = {}		-- sparse, maps unit_id to (real) unit name, cache for speed.
				--   it would be nice to use getVisibleName(), but that 
				--   requires an existing unit, but raiding units do not exist
				--   in df.global.world.units.all after they leave the map.
				--   but it's okay, this is only for diagnostics.
				-- TODO wait what?  they MUST be in df.global.world.units.all !
				--   they are hf with associated unit !


-- copy-pasted from send-war-animals-on-raid.lua
-- TODO if you fix something, fix it in send-war-animals-on-raid.lua as well!
function find_raiders()
 for _, sq in ipairs(df.global.world.squads.all) do

  -- TODO is it true that order type squad_order_raid_sitest will always be the first and only order?
  -- maybe I should search every order?
  if sq.entity_id == df.global.plotinfo.group_id 
	and #sq.orders > 0 
	and sq.orders[0]:getType() == df.squad_order_type.RAID_SITE 
  then

    squad_names[sq.id] = (sq.alias ~= '') and sq.alias or translateName(sq.name, true)

    for _, position in ipairs(sq.positions) do
      local hf = df.historical_figure.find(position.occupant)
      if hf then
	local uid = hf.unit_id
	raiding_units[uid] = sq.id

	-- note that the 'uid' unit may not be in the units table.
	-- TODO they might not be in units.active, but they have to be in units.all
	-- TODO if the unit exists, it would be nice to use GetVisibleName() on it.
	unit_names[uid] = unit_names[uid] or translateName(hf.name, false)
      end
    end -- for all positions
  end -- if squad is ours and is on a mission
 end -- for all squads
end -- function


function main()
    find_raiders()
    for unit_id, squad_id in pairs(raiding_units) do
	local unit = df.unit.find(unit_id)
	if unit and dfhack.units.isCitizen(unit) then
	    vprintf('Waking up %d', unit_id)
            wake_unit(unit)
	    unit.counters2.sleepiness_timer = 1
	else vprintf('No unit %d', unit_id)
        end
    end
end

main()
