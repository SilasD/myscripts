local utils = require('utils')

local TRIGGER = -5000


local translateName = dfhack.TranslateName or dfhack.translation.translateName


local _, work_detail = utils.linear_index( 
	df.global.plotinfo.labor_info.work_details, 'Plant gatherers', 'name')
if work_detail == nil then
  print("No work detail named 'Plant gatherers'")
  return
end

work_detail.flags.cannot_be_everybody = true

for k,u in ipairs(df.global.world.units.active) do
  if ( dfhack.units.isCitizen(u) )
	and (u.status)
	and (u.status.current_soul)
	and (u.status.current_soul.personality)
	and (u.status.current_soul.personality.needs)
  then

    -- local name = dfhack.df2utf(translateName(dfhack.units.getVisibleName(u))) .. ", " .. dfhack.units.getProfessionName(u, false)
    local name = dfhack.units.getReadableName(u)   -- returned in in utf.

    for _, need in ipairs(u.status.current_soul.personality.needs) do
      local enable_herbalism = false
      local disable_herbalism = false
      --local is_herbalist = false

      if need.id == df.need_type.Wander then

	if (u.job.current_job) and u.job.current_job.job_type == df.job_type.GatherPlants then
	  dfhack.println( name .. ": is wandering." )
          disable_herbalism = true
	elseif need.focus_level < TRIGGER then
	  dfhack.println(name .. " needs to wander (" .. need.focus_level .. ").")
	  enable_herbalism = true
	else
          disable_herbalism = true
	end

	if disable_herbalism then
	  u.status.labors[df.unit_labor.HERBALIST] = false
	  utils.erase_sorted(work_detail.assigned_units, u.id)
	elseif enable_herbalism then
	  u.status.labors[df.unit_labor.HERBALIST] = true
	  utils.insert_sorted(work_detail.assigned_units, u.id)
	end
      end
    end
  end
end
