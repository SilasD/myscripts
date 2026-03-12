--[====[
list-traders-books
==================
Mostly OBSOLETE.  DFHack now prints the name of books and scrolls when listing
building contents or viewing an item sheet.

Does what is says.
--]====]

-- TODO are slab secrets relevant?  i.e. are they ever sold?

local X = dfhack.TranslateName or dfhack.translation.translateName
local debugging = false

local function printf(...) print(string.format(...)); end
local function dprintf(...) if debugging == true then dfhack.printerr(string.format(...)); end; end


local function foreach_book(action, filter)
    if type(action) ~= "function" then
        qerror("action param is not a valid action: pass a function that accepts df.item_bookst and df.item_toolst\n")
    end
    if type(filter) == "nil" then
        filter = function(book) return true; end
    elseif type(filter) == "string" then
        dprintf("filter string: %s", filter)
        if not filter:find("^function") then
            filter = string.format("function(book) return(%s); end;", filter)
        end
        dprintf("filter function: %s", filter)
        local code, err = dfhack.pcall(load, filter, 't')
        if err then dprintf("%s", err); end
        assert(type(code) == "function",
            "filter string is not a valid filter; test the df.item named 'book' and return boolean.")
        filter = code
    end
    if type(filter) ~= "function" then
        qerror("filter param is not a valid filter: pass\n"
            .. "a function that tests the df.item named 'book' and returns a boolean,\n"
            .. "a string that tests the df.item named 'book' and returns a boolean,\n,"
            .. "or nil."
        )
    end
    for _, book in ipairs(df.global.world.items.other.BOOK) do
        if book:hasWriting() and filter(book) then action(book); end
    end
    for _, scroll in ipairs(df.global.world.items.other.TOOL) do
        if scroll:hasWriting() and filter(scroll) then action(scroll); end
    end
end


local item_id_to_wc = {}  -- nil wc is mapped as false
local wc_id_to_wc = {}    -- nil wc is mapped as false


local function get_written_content(item)
    assert(df.item:is_instance(item))
    if item_id_to_wc[item.id] ~= nil then return item_id_to_wc[item.id] or nil; end
    if not item:hasImprovements() then
        item_id_to_wc[item.id] = false
        return nil
    end
    -- TODO maybe: it is possible for items (scrolls) to hold multiple written contents,
    --   but that doesn't currently happen in practice.  currently we return the first one.
    for _, imp in ipairs(item.improvements) do
        if      imp:getType() == df.improvement_type.PAGES
            or  imp:getType() == df.improvement_type.WRITING
        then
            assert( df.itemimprovement_pagesst  :is_instance(imp)
                or  df.itemimprovement_writingst:is_instance(imp) )
            for _, wc_id in ipairs(imp.contents) do
--print(type(wc_id), math.type(wc_id), wc_id)
                wc_id_to_wc[wc_id] = wc_id_to_wc[wc_id] or df.written_content.find(wc_id)
                local wc = wc_id_to_wc[wc_id]
                assert(wc == nil or wc._type == df.written_content)
                item_id_to_wc[item.id] = (wc ~= nil) and wc or false
                return(wc)
            end
        end
    end
    return nil
end


local wc_id_to_fort_wc_count = {}
local function gather_fort_written_content_count()
    foreach_book(
        function(book)
            local wc = get_written_content(book)
            if wc then 
                wc_id_to_fort_wc_count[wc.id] = (wc_id_to_fort_wc_count[wc.id] or 0) + 1
            end
        end,

        function(book)
            return not book.flags.trader
        end
    )
end


function print_book_details(book)
    local in_inventory = dfhack.items.getGeneralRef(book, df.general_ref_type.UNIT_HOLDER)
    local in_building = dfhack.items.getGeneralRef(book, df.general_ref_type.BUILDING_HOLDER)
    local on_display = dfhack.items.getGeneralRef(book, df.general_ref_type.BUILDING_DISPLAY_FURNITURE)
    local wc = get_written_content(book)
    local wc_id = (wc) and wc.id or -1
    local author_hf = (wc) and df.historical_figure.find(wc.author) or nil
    author = author_hf and X(author_hf.name, true) or "(no author)"
    --wc_id_to_fort_wc_count[wc_id] = (wc_id_to_fort_wc_count[wc_id] or 0)
    title = (wc ~= nil and wc.title ~= '') and wc.title or "UNTITLED"

    printf("item %-8d%-44s\n    %s\n    wcid %7d %-6s fort count %d\n    author %-24s",
            book.id,
            title,
            dfhack.items.getDescription(book, 1, false),
            wc_id,
            (book._type == df.item_bookst) and 'book' or 'scroll',
                (wc_id ~= -1) and  wc_id_to_fort_wc_count[wc_id] or 0,
            author
    )
  --[[
  print( 
	'item ' .. book.id,
	dfhack.items.getDescription(book, 0, true),
	(wc ~= nil) and 'written_content ' .. wc.id or 'NIL CONTENT',
	(book._type == df.item_bookst) and 'BOOK' or 'SCROLL',
	(in_inventory) and 'IN INVENTORY: ' .. in_inventory.unit_id    or '',
	(in_building)  and 'IN BUILDING: ' .. in_building.building_id  or '',
	(on_display)   and 'ON DISPLAY: ' .. on_display.building_id    or '',
	'POSITION: (' .. book.pos.x .. ',' .. book.pos.y .. ',' .. book.pos.z .. ')',
        'AUTHOR: ' .. author or '',
	(wc ~= nil and wc.title ~= '') and wc.title or 'UNTITLED'
  )
  ]]
end


--- TODO merge in the helper functions
---@param book df.item_bookst | df.item_toolst
local function do_book(book)
    if not book:hasWriting() then return; end
    local improvement = nil
    local written_content_id = -1
    for _, imp in ipairs(book.improvements) do
        dprintf("%s", imp._type)
        if imp._type == df.itemimprovement_pagesst or imp._type == df.itemimprovement_writingst then
            ---@cast imp df.itemimprovement_pagesst | df.itemimprovement_writingst
            --print('#imp.contents', #imp.contents)
            --print('imp.contents[0]', imp.contents[0])
            improvement = imp
            written_content_id = imp.contents[0]   -- TODO are there ever more than one item in this vector?
        end
    end
    dprintf('written_content_id %d', written_content_id)
    local written_content = df.written_content.find(written_content_id)
    if not written_content then
        printf('did not find written content for item %d written_content_id %d', book.id, written_content_id)
        return
    end
    dprintf('written content.id %d', written_content.id)
    for _, ref in ipairs(written_content.refs) do
        dprintf("%s", ref._type)
        if ref._type == df.general_ref_interactionst then
            ---@cast ref df.general_ref_interactionst
            if df.interaction.find(ref.interaction_id) == nil then 
                print('item %d %d %d interaction does not exist', book.id, written_content.id, ref.interaction_id)
                return
            end

            for _, source in ipairs(df.interaction.find(ref.interaction_id).sources) do
                if source._type == df.interaction_source_secretst then
                    print("TRADER'S BOOK HAS A SECRET!")
                end
            end
        end
    end
    print_book_details(book)
end

function main()
    gather_fort_written_content_count()

    -- TODO if the trade screen is open and there is a current trader, only list their books.
    for _, book in ipairs(df.global.world.items.other.BOOK) do
        if book:hasWriting() and book.flags.trader then
            do_book(book)
        end
    end
    for _, scroll in ipairs(df.global.world.items.other.TOOL) do
        if scroll:hasWriting() and scroll.flags.trader then
            do_book(scroll)
        end
    end
end

main()