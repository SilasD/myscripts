-- SWD
-- TODO are slab secrets relevant?


local translateName = dfhack.TranslateName or dfhack.translation.translateName


function print_book_details(book, improvement, written_content)
  local in_inventory = dfhack.items.getGeneralRef(book, df.general_ref_type.UNIT_HOLDER)
  local in_building = dfhack.items.getGeneralRef(book, df.general_ref_type.BUILDING_HOLDER)
  local on_display = dfhack.items.getGeneralRef(book, df.general_ref_type.BUILDING_DISPLAY_FURNITURE)
  local author = df.historical_figure.find(written_content.author)
  author = (author ~= nil) and translateName(author.name) or '(none)'
  print( 
	'Item ' .. book.id,
	(written_content ~= nil) and 'Content: ' .. written_content.id or 'NIL CONTENT',
	(book._type == df.item_bookst) and 'BOOK' or 'SCROLL',
	(in_inventory) and 'IN INVENTORY: ' .. in_inventory.unit_id    or '',
	(in_building)  and 'IN BUILDING: ' .. in_building.building_id  or '',
	(on_display)   and 'ON DISPLAY: ' .. on_display.building_id    or '',
	'POSITION: (' .. book.pos.x .. ',' .. book.pos.y .. ',' .. book.pos.z .. ')',
        'AUTHOR: ' .. author,
	(written_content ~= nil and written_content.title ~= '') and written_content.title or 'UNTITLED')
end


function do_book(book)
  local improvement = nil
  local written_content_id = -1
  for _, imp in ipairs(book.improvements) do
    --print(imp._type)
    if imp._type == df.itemimprovement_pagesst or imp._type == df.itemimprovement_writingst then
      --print('#imp.contents', #imp.contents)
      --print('imp.contents[0]', imp.contents[0])
      improvement = imp
      written_content_id = imp.contents[0]   -- TODO are there ever more than one item in this vector?
    end
  end
  --print('written_content_id', written_content_id)
  local written_content = df.written_content.find(written_content_id)
  if written_content then
    --print('written content.id', written_content.id)
    for _, ref in ipairs(written_content.refs) do
      --print(ref._type)
      if ref._type == df.general_ref_interactionst then
        if df.interaction.find(ref.interaction_id) == nil then 
          print('written_content interaction_id does not have a matching interaction', book.id, written_content.id)
          return
        end
        
        for _, source in ipairs(df.interaction.find(ref.interaction_id).sources) do
          if source._type == df.interaction_source_secretst then
            print_book_details(book, improvement, written_content)
          end
        end
      end
    end
  end
end


for _, book in ipairs(df.global.world.items.other.BOOK) do
  do_book(book)
end

-- really, there could be a new type of tool that also can contain written_content.
-- so maybe just process all the tools?
for _, book in ipairs(df.global.world.items.other.TOOL) do
  if book.subtype.id == 'ITEM_TOOL_SCROLL' then
    do_book(book)
  end
end

