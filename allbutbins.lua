function allbutbins ()
  if df.global.gview.view.child.child == nil or
     df.global.gview.view.child.child._type ~= df.viewscreen_tradelistst or
     df.global.gview.view.child.child.child._type ~= df.viewscreen_tradegoodsst then
    dfhack.error ("This script must be run when the trade screen is open")
  end
  
  for i, item in ipairs (df.global.gview.view.child.child.child.broker_items) do
	if item._type == df.item_binst or
	  (item._type == df.item_pantsst and
	   item.wear == 0 and
	   item.subtype.props.layer == 0) then  --  underwear
      df.global.gview.view.child.child.child.broker_selected [i] = 0
	else
      df.global.gview.view.child.child.child.broker_selected [i] = 1
	end
  end
end

allbutbins ()