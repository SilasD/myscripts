-- Dismisses bugged merchants.
--[====[

dismissmerchants
=================

]====]

function dismissmerchants ()
  for i = 0, #df.global.world.units.active - 1 do
    if df.global.world.units.active [i].flags1.merchant then
	   if df.global.world.units.active [i].flags1.dead and
	   not df.global.world.units.active [i].flags1.left then
	   	dfhack.println ("Dismissing merchant ")
		df.global.world.units.active [i].flags1.left = true	     
	   end
	end
  end
end

dismissmerchants ()