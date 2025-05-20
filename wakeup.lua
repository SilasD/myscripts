
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


function main()
    local unit = dfhack.gui.getSelectedUnit()
    if unit and dfhack.units.isCitizen(unit) then
        wake_unit(unit)
	unit.counters2.sleepiness_timer = 1
    end
end

main()