function allbutbinelf ()
  local blocked

  if df.global.gview.view.child.child == nil or
     df.global.gview.view.child.child._type ~= df.viewscreen_tradelistst or
     df.global.gview.view.child.child.child._type ~= df.viewscreen_tradegoodsst then
    dfhack.error ("This script must be run when the trade screen is open")
  end
  
  for i, item in ipairs (df.global.gview.view.child.child.child.broker_items) do
	if item._type == df.item_binst or
	  (item._type == df.item_pantsst and
	   item.wear == 0 and
	   item.subtype.props.layer == 0) or  --  underwear
      (dfhack.matinfo.decode (item.mat_type, item.mat_index).mode == "plant" and
	   df.global.world.raws.plants.all [item.mat_index].flags.TREE) then  --  Wooden item, but will also ban fruit
	  df.global.gview.view.child.child.child.broker_selected [i] = 0
	  
	else
	  blocked = false
	  
	  for k, improvement in ipairs (item.improvements) do
		if dfhack.matinfo.decode (improvement.mat_type, improvement.mat_index).mode == "plant" and
		   df.global.world.raws.plants.all [improvement.mat_index].flags.TREE then
	      df.global.gview.view.child.child.child.broker_selected [i] = 0
		  blocked = true
		  break
		end
	  end

	  if not blocked then
        df.global.gview.view.child.child.child.broker_selected [i] = 1
	  end
	end
  end
end

allbutbinelf ()