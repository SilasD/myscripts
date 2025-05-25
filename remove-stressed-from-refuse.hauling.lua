local utils = require('utils')

-- local translateName = dfhack.TranslateName or dfhack.translation.translateName

local long_term_stress_cutoff = 5000

local work_details = df.global.plotinfo.labor_info.work_details

local _, work_detail = utils.linear_index(work_details, 'Haulers', 'name')
if work_detail == nil then
    qerror("This script needs a Labor/Work Detail named 'Haulers'.")
end
work_detail.allowed_labors.HAUL_BODY = false		-- burial.  certain to be corpses/corpse_pieces.
work_detail.allowed_labors.HAUL_REFUSE = false		-- likely to be corpses/corpse_pieces.
work_detail.allowed_labors.CLEAN = false		-- likely to be nearby corpses/corpse_pieces.

-- TODO add one if it doesn't exist.
_, work_detail = utils.linear_index(work_details, 'Refuse', 'name')
if work_detail == nil then
    qerror("This script needs a Labor/Work Detail named 'Refuse'.")
end

work_detail.flags.mode = 3				-- 1 == everybody, 2 == nobody, 3 == selected
work_detail.icon = df.work_detail_icon_type.HAULERS
work_detail.allowed_labors.HAUL_BODY = true
work_detail.allowed_labors.HAUL_REFUSE = true
work_detail.allowed_labors.CLEAN = true
work_detail.allowed_labors.BUTCHER = true
work_detail.allowed_labors.TANNER = true
-- TODO Q: should we turn off all other labors?
-- TODO scan all other work details to see if any have BUTCHER or TANNER.  don't enable in that case.


work_detail.assigned_units:resize(0)
for _, unit in ipairs(dfhack.units.getCitizens()) do
    local stress = unit.status.current_soul.personality.longterm_stress
    if not (stress >= long_term_stress_cutoff) then
	utils.insert_sorted(work_detail.assigned_units, unit.id)
	-- DONT: concatenating all the ids, then sorting once, would probably be faster.
	--   OTOH, we don't care about performance in this script.
    else
	local name = string.match(dfhack.units.getReadableName(unit), "^([^,]*)")
	print(string.format("%s has long-term stress level %d; removed %s from refuse hauling work detail.",
		name, stress, dfhack.units.isFemale(unit) and 'her' or 'him'))
    end
end

