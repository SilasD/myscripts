local args = {...}

local utils = require('utils')

local doit = true

--testing if any books have .world_data_id
if false then for _, i in ipairs(df.global.world.items.all) do
    if (df.item_bookst:is_instance(i) or df.item_toolst:is_instance(i))
	and i.world_data_id ~= -1 then print(i.id); return;
    end
end;print('none');return;end

-- probing for first book with author historical_figure holding it, by .written_content.author
if false then for _, i in ipairs(df.global.world.items.all) do
    if (df.item_bookst:is_instance(i) or df.item_toolst:is_instance(i)) then
	for _,j in ipairs(i.improvements) do
	    if df.itemimprovement_pagesst:is_instance(j) or df.itemimprovement_writingst:is_instance(j) then
		local wc = df.written_content.find(j.contents[0])
		local hfid = wc.author; local hf = df.historical_figure.find(hfid)
		if hf and hf.info and hf.info.books and #hf.info.books.artifacts_held > 0 then 
		    print(i.id, hfid);
		    return
		end
		-- so when this happens, the artifact_record
		-- .owner_hf == hf, .holder_hf == hf, .site == -1, .storage_site == -1
	    end
	end
    end
end;print('none');return;end

-- probing for first artifact book with author historical_figure holding it, by general_ref
if false then for _, i in ipairs(df.global.world.items.all) do
    if (df.item_bookst:is_instance(i) or df.item_toolst:is_instance(i)) and i.flags.artifact then
	for _,gref in ipairs(i.general_refs) do if df.general_ref_is_artifactst:is_instance(gref) then
	    local art = df.artifact_record.find(gref.artifact_id)
	    if art and art.holder_hf > -1 then print(i.id); return; end
	end;end
    end
end;print('none');return;end

-- probing for first artifact book that is in a site
if false then for _, i in ipairs(df.global.world.items.all) do
    if (df.item_bookst:is_instance(i) or df.item_toolst:is_instance(i)) and i.flags.artifact then
	for _,gref in ipairs(i.general_refs) do if df.general_ref_is_artifactst:is_instance(gref) then
	    local art = df.artifact_record.find(gref.artifact_id)
	    if art and art.site > -1 then print(i.id); return; end
	end;end
    end
end;print('none');return;end

-- probing for first artifact book with abs_tile_x set
if false then for _, i in ipairs(df.global.world.items.all) do
    if (df.item_bookst:is_instance(i) or df.item_toolst:is_instance(i)) and i.flags.artifact then
	for _,gref in ipairs(i.general_refs) do if df.general_ref_is_artifactst:is_instance(gref) then
	    local art = df.artifact_record.find(gref.artifact_id)
	    if art and art.abs_tile_x ~= -1000000 then print(i.id); return; end
	end;end
    end
end;print('none');return;end

-- probing for first artifact book with feature_layer > -1
-- there weren't any in either of my test worlds.
if false then for _, i in ipairs(df.global.world.items.all) do
    if (df.item_bookst:is_instance(i) or df.item_toolst:is_instance(i)) and i.flags.artifact then
	for _,gref in ipairs(i.general_refs) do if df.general_ref_is_artifactst:is_instance(gref) then
	    local art = df.artifact_record.find(gref.artifact_id)
	    if art and art.feature_layer > -1 then print(i.id); return; end
	end;end
    end
end;print('none');return;end


local book_id, writing_id
local plotinfo = ({dfhack.safecall(function() return df.global.plotinfo; end)})[2]
	or ({dfhack.safecall(function() return df.global.ui; end)})[2]
local our_site_id = plotinfo.site_id


if #args < 2 then args[1] = "help"; end

if args[1]:startswith('b') then
    book_id = tonumber(args[2])

elseif args[1]:startswith('w') then
    writing_id = tonumber(args[2])
    book_id = nil

    -- slow; find the first book (presumably the artifact book) with that written_contents_id.
    for _,i in ipairs(df.global.world.items.all) do

	if df.item_bookst:is_instance(i) or df.item_toolst:is_instance(i) then
	    for _,j in ipairs(i.improvements) do 
		--if i.id < 100 and df.itemimprovement_pagesst:is_instance(j) then dfhack.print(i.id .. ":" .. j.contents[0], '');end
		--if df.itemimprovement_pagesst:is_instance(j) and #j.contents > 1 then dfhack.print(i.id,'');end
		if df.itemimprovement_pagesst:is_instance(j) and j.contents[0] == writing_id then
		    book_id = i.id
		    break
		end
	    end
	end

	if book_id ~= nil then break; end
    end
    if book_id == nil then qerror('could not find book with that written_contents id'); end
else
    print(("Usage:\n    %s book <item_id>\nor\n    %s writing <written_contents_id>\n"):format
	(dfhack.current_script_name(), dfhack.current_script_name()))
    return
end

local item = (type(book_id) == "number") and df.item.find(book_id) or nil
local artifact = nil

if not item then qerror('could not find book'); end

-- test with book 4473
local _, in_play, _ = utils.binsearch(df.global.world.items.other.IN_PLAY, item.id, 'id')
if in_play then qerror('that book is already on the map.'); end
if artifact and artifact.site == our_site_id then qerror('that book is on-site but not on the map.'); end


for _, gref in ipairs(item.general_refs) do
    if df.general_ref_is_artifactst:is_instance(gref) then
	artifact = df.artifact_record.find(gref.artifact_id)
    end
end


-- print('book_id', book_id, 'item', item.id, 'artifact', artifact.id)


if doit and artifact then

    local art_site, art_holder_hf, art_subregion

    art_site = df.world_site.find(artifact.site)
    art_holder_hf = df.historical_figure.find(artifact.holder_hf)
    art_subregion = df.world_region.find(artifact.subregion)
	-- nothing in a subregion tracks artifacts.
	-- not sure what to do except clearing artifact's abs_tile_xyz, subregion, and loss_region.


    -- okay, item 9 is artifact 9 is in site 80 abstract building 0, a spire.
    --   the spire does not contain any items.
    --	 one inhabitant, a goblin.  that goblin is not carrying any artifacts.
    -- the artifact storage info matches the site info.
    -- the site's property_ownership is empty.  (is that for buildings, though?)
    -- the site has 21 buildings, none of which contain any items.
    -- oh.  the artifact is in .populace.artifacts[]. good.
    if art_site then
	-- okay. populace.artifacts[] looks to be sorted by .id, but that may just be an
	--   artifact (no pun intended) caused by loading the savegame.  I don't trust it.
	local index, _ = utils.linear_index(art_site.populace.artifacts, artifact.id, 'id')
	print( (index) and "artifact found in site, index " .. index or "artifact not found in site" )
	if index then
	    art_site.populace.artifacts:erase(index)
	    index, _ = utils.linear_index(art_site.populace.artifacts, artifact.id, 'id')  -- verify deletion
	    if index then qerror("didn't delete artifact from site"); end
	end
    end

    if art_holder_hf then
	local held = (art_holder_hf and art_holder_hf.info and art_holder_hf.info.books)
		and art_holder_hf.info.books.artifacts_held or nil
	if held then
	    local index, _ = utils.linear_index(held, artifact.id, 'id')
	    if index then 
		held:erase(index)
	    end
	end
    end

    if art_subregion then
	-- nothing in a subregion tracks artifacts.
	-- not sure what to do except clearing artifact's abs_tile_xyz, subregion, and loss_region.
    end

    artifact.flags.ART_REVEALED = false
    artifact.flags.LAST_SITE_PLACEMENT_WAS_BEING_LOST = false
    artifact.flags.LAST_GLOBALLY_KNOWN_LOCATION_WAS_BEING_LOST = false
    artifact.abs_tile_x = -1000000
    artifact.abs_tile_y = -1000000
    artifact.abs_tile_z = -1000000
    artifact.last_local_bld_id = -1
    artifact.site = our_site_id
    artifact.structure_local = -1
    artifact.site_building_profile = -1
    artifact.subregion = -1
    artifact.feature_layer = -1
    artifact.owner_hf = -1
    artifact.remote_claims:resize(0)
    artifact.entity_claims:resize(0)
    artifact.family_claims:resize(0)
    artifact.storage_site = -1
    artifact.storage_structure_local = -1
    artifact.loss_region = -1
    artifact.last_layer = -1
    artifact.holder_hf = -1
end

if doit then
    local O = df.global.world.items.other

    if df.item_bookst:is_instance(item) then
	if not utils.insert_sorted(O.BOOK, item, 'id') then
	    qerror('failed to insert into BOOK')
	end
    elseif df.item_toolst:is_instance(item) then
	if not utils.insert_sorted(O.TOOL, item, 'id') then
	    qerror('failed to insert into TOOL')
	end
    else 
	qerror('this is not an item I know how to insert into the items.other arrays.')
    end

    if artifact and not utils.insert_sorted(O.ANY_ARTIFACT, item, 'id') then
	qerror('failed to insert into ANY_ARTIFACT')
    end

    if not utils.insert_sorted(O.IN_PLAY, item, 'id') then
	qerror('failed to insert into IN_PLAY')
    end

    item.flags.foreign = true
    item.flags.trader = false
    item.flags.forbid = true
    item.temperature.whole = 10025	-- reasonable value
    item.temperature.fraction = 0

    local pos = xyz2pos(
	plotinfo.map_edge.surface_x[0],
	plotinfo.map_edge.surface_y[0],
	plotinfo.map_edge.surface_z[0]
    )
    item.pos = pos
    local map_block = dfhack.maps.getTileBlock(pos)
    utils.insert_or_update(map_block.items, item.id)
    item.flags.on_ground = true

    print('The book should now be on the surface, at the top-left corner of the map.')
    
end

