
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
-- tweaked to return boolean: was the unit awakened?
function wake_unit(unit)
    local job = unit.job.current_job
    if not job or job.job_type ~= df.job_type.Sleep then
        return false
    end

    if job.completion_timer > 0 then
        unit.counters.unconscious = 0
        add_thought(unit, df.emotion_type.Grouchiness, df.unit_thought_type.Drowsy)
    elseif job.completion_timer < 0 then
        add_thought(unit, df.emotion_type.Grumpiness, df.unit_thought_type.Drowsy)
    end
    unit.counters2.sleepiness_timer = 1
    unit.counters.job_counter = 0

    job.pos:assign(unit.pos)

    job.completion_timer = 0

    unit.path.dest:assign(unit.pos)
    unit.path.path.x:resize(0)
    unit.path.path.y:resize(0)
    unit.path.path.z:resize(0)
    return true
end


function main()
    local woke = 0
    for _,unit in ipairs(dfhack.units.getCitizens()) do
        woke = woke + (wake_unit(unit) and 1 or 0)
    end
    if woke > 0 then print("Woke up " .. woke .. (woke == 1 and " unit." or " units.")); end
end

main()