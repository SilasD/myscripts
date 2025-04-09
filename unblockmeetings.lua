--  Work around for blocked meetings where a change of position holder causes the meeting activities to
--  stall. The somewhat heavy handed approch wipes all meeting activities from the participants and the
--  internal store and relies on DF's ability to rebuild the ones that should actually be there.
--
--[====[

unblockmeetings
===============
--
]====]
function unblockmeetings ()
  if not dfhack.isWorldLoaded () or not dfhack.isMapLoaded () then
    dfhack.printerr ("Error: This script requires an embark to be loaded.")
	return
  end

  dfhack.println ("Deleting " .. tostring (#df.global.ui.meeting_requests) .. " meeting requests")
  for i = #df.global.ui.meeting_requests - 1, 0, -1 do
    df.global.ui.meeting_requests:erase (i)
  end
  
  dfhack.println ("Deleting " .. tostring (#df.global.ui.activities) .. " activities")
  for i = #df.global.ui.activities - 1, 0, -1 do
    for k = #df.global.ui.activities [i].unit_actor.specific_refs - 1, 0, -1 do
	  if df.global.ui.activities [i].unit_actor.specific_refs [k].type == 4 then  -- ACTIVITY
	    dfhack.println ("Removing actor ACTIVITY from " .. dfhack.TranslateName (df.global.ui.activities [i].unit_actor.name, true))
	    df.global.ui.activities [i].unit_actor.specific_refs:erase (k)
	  end
	end
	
    for k = #df.global.ui.activities [i].unit_noble.specific_refs - 1, 0, -1 do
	  if df.global.ui.activities [i].unit_noble.specific_refs [k].type == 4 then  -- ACTIVITY
	    dfhack.println ("Removing noble ACTIVITY from " .. dfhack.TranslateName (df.global.ui.activities [i].unit_noble.name, true))
	    df.global.ui.activities [i].unit_noble.specific_refs:erase (k)
	  end
	end
	
	df.global.ui.activities:erase (i)
  end
end

unblockmeetings ()