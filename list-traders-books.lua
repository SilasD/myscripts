--[====[
list-traders-books
==================
Mostly OBSOLETE.  DFHack now prints the name of books and scrolls when listing
building contents or viewing an item sheet.

Does what is says.
--]====]

-- TODO are slab secrets relevant?  i.e. are they ever sold?


local translateName = dfhack.TranslateName or dfhack.translation.translateName


function print_book_details(book, improvement, written_content)
  local in_inventory = dfhack.items.getGeneralRef(book, df.general_ref_type.UNIT_HOLDER)
  local in_building = dfhack.items.getGeneralRef(book, df.general_ref_type.BUILDING_HOLDER)
  local on_display = dfhack.items.getGeneralRef(book, df.general_ref_type.BUILDING_DISPLAY_FURNITURE)
  local author = (written_content ~= nil) and df.historical_figure.find(written_content.author) or nil
  author = (author ~= nil) and translateName(author.name, true) or '(none)'
  title = (written_content ~= nil and written_content.title ~= '') and written_content.title or 'UNTITLED'
  print(string.format( "item %7d  %-36s  written_content %7d %-6s author %-24s  %s",
	book.id,
	dfhack.items.getDescription(book, 0, true),
	(written_content ~= nil) and written_content.id or -1,
	(book._type == df.item_bookst) and 'BOOK' or 'SCROLL',
	author,
	title
  ))
  --[[
  print( 
	'item ' .. book.id,
	dfhack.items.getDescription(book, 0, true),
	(written_content ~= nil) and 'written_content ' .. written_content.id or 'NIL CONTENT',
	(book._type == df.item_bookst) and 'BOOK' or 'SCROLL',
	(in_inventory) and 'IN INVENTORY: ' .. in_inventory.unit_id    or '',
	(in_building)  and 'IN BUILDING: ' .. in_building.building_id  or '',
	(on_display)   and 'ON DISPLAY: ' .. on_display.building_id    or '',
	'POSITION: (' .. book.pos.x .. ',' .. book.pos.y .. ',' .. book.pos.z .. ')',
        'AUTHOR: ' .. author or '',
	(written_content ~= nil and written_content.title ~= '') and written_content.title or 'UNTITLED'
  )
  ]]
end


function do_book(book)
  if not book.flags.trader then return; end

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
          print('written_content interaction_id has matching interaction', book.id, written_content.id)
          return
        end

        for _, source in ipairs(df.interaction.find(ref.interaction_id).sources) do
          if source._type == df.interaction_source_secretst then
            print("TRADER'S BOOK HAS A SECRET!")
          end
        end
      end
    end
  end
  print_book_details(book, improvement, written_content)
end


for _, book in ipairs(df.global.world.items.other.BOOK) do
  do_book(book)
end
for _, book in ipairs(df.global.world.items.other.TOOL) do
  -- TODO maybe: check for the flag for ability to have written contents.
  -- TODO maybe: or filter all tools on the existance of written-contents improvements.
  if book.subtype.id == 'ITEM_TOOL_SCROLL' then
    do_book(book)
  end
end

