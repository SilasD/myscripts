--[====[

list-helping-others
===================
lists all citizens who like (or don't like) helping others.

TODO also should add/remove from orderlies, give food, give water.
]====]

for k,u in ipairs(dfhack.units.getCitizens()) do

    if u.status.current_soul.personality.traits.ALTRUISM <= 40 then
	dfhack.print(dfhack.df2console(dfhack.units.getReadableName(u)))
	if u.status.current_soul.personality.traits.ALTRUISM <= 25 then
	    dfhack.color(COLOR_RED)
	    dfhack.print(" really")
	end
	dfhack.color(COLOR_LIGHTRED)
	dfhack.print(" doesn't like")
	dfhack.color(COLOR_RESET)
	dfhack.println(" helping others (" .. u.status.current_soul.personality.traits.ALTRUISM .. ").")

    elseif u.status.current_soul.personality.traits.ALTRUISM >= 60 then
	dfhack.print(dfhack.df2console(dfhack.units.getReadableName(u)))
	if u.status.current_soul.personality.traits.ALTRUISM >= 75 then
	    dfhack.color(COLOR_LIGHTBLUE)
	    dfhack.print(" really")
	end
	dfhack.color(COLOR_LIGHTGREEN)
	dfhack.print(" likes")
	dfhack.color(COLOR_RESET)
	dfhack.println(" helping others (" .. u.status.current_soul.personality.traits.ALTRUISM .. ").")
    end
end
