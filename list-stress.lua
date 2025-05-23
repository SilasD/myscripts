--[====[

list-stress
===========
Lists citizens who are stressed.

If a unit is selected, lists only that unit's stress.
Otherwise lists all units with some stress.

TODO also should add/remove from orderlies, give food, give water.
]====]

local Level1 = 10000
local Level2 = 20000
local Level3 = 40000

local TicksPerDay  = 1200
local TicksPerYear = 403200
local currentTick = dfhack.world.ReadCurrentYear() * TicksPerYear + dfhack.world.ReadCurrentTick()
local deltaTick = 3 * TicksPerDay	-- time period to NOT update the old stress record.

oldList = oldList or {}		-- global, persistant
oldLong = oldLong or {}		-- global, persistant
oldTick = oldTick or 0		-- global, persistant


local unitList
if dfhack.gui.getSelectedUnit(true) then
    unitList = { dfhack.gui.getSelectedUnit(true) }
else
    unitList = dfhack.units.getCitizens()
end

for k,u in ipairs(unitList) do

    local stress = u.status.current_soul.personality.stress
    oldList[u.id] = oldList[u.id] or stress
    local deltaStress = (stress - oldList[u.id])

    local longtermStress = u.status.current_soul.personality.longterm_stress
    oldLong[u.id] = oldLong[u.id] or longtermStress
    local deltaLong = (longtermStress - oldLong[u.id])

    if longtermStress >= Level3 then
	dfhack.color(COLOR_LIGHTRED)
    elseif longtermStress >= Level2 then
	dfhack.color(COLOR_YELLOW)
    elseif longtermStress >= Level1 then
	dfhack.color(COLOR_WHITE)
    elseif #unitList == 1 then
	dfhack.color(COLOR_GREY)
    else
	goto CONTINUE
    end

    dfhack.println(string.format("%-8d%s%-7d%-8d%s%-7d%s", longtermStress,
	deltaLong < 0 and '-' or (deltaLong > 0 and '+' or ' '), math.abs(deltaLong),
	stress, deltaStress < 0 and '-' or (deltaStress > 0 and '+' or ' '),
	math.abs(deltaStress), dfhack.units.getReadableName(u) ))

    -- update?
    if (oldTick + deltaTick) < currentTick then
	oldList[u.id] = stress
	oldLong[u.id] = longtermStress
    end

    ::CONTINUE::
    dfhack.color(COLOR_RESET)
end

oldTick = currentTick
