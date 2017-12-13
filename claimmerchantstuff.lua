function claimmerchantstuff ()
  for i = 0, #df.global.world.units.all - 1 do
    if df.global.world.units.all [i].flags1.merchant and
	   df.global.world.units.all [i].flags1.dead and
	   df.global.world.units.all [i].flags3.scuttle then
	   dfhack.println ("Scuttling merchant: " ..  tostring (i))
	   
	   for _, v in ipairs (df.global.world.units.all [i].inventory) do
	     if v.mode == 0 then  --  hauled
--		   v.item.pos.x = df.global.world.units.all [i].pos.x
--		   v.item.pos.y = df.global.world.units.all [i].pos.y
--		   v.item.pos.z = df.global.world.units.all [i].pos.z
--		   v.item.flags.on_ground = true
--		   v.item.flags.in_inventory = false
--		   v.item.flags.removed = false
		   v.item.flags.dump = true
--		   v.item.flags.trader = false
		 end
	   end
	end
  end  
end

claimmerchantstuff()