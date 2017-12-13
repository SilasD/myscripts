--  Causes units to leave the map when they're no longer occupied. Can be used to get rid of
--  bugged overstaying visitors that no longer socialize. Those still socializing seem to take
--  up new socialization activiies before considering to act on this prompt, though. You'd have
--  to close the facilities they visit for it to take effect.
--[====[

getlost
=======
--
]====]
function getlost ()
   local unit = dfhack.gui.getSelectedUnit (true)
   unit.flags1.forest = true
end

getlost ()
