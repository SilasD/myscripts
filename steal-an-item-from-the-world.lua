-- TODO: artifact claims are also tracked in world.family_info.family[].claims[] (sorted by hfid)
-- TODO: entity claims are tracked in world.entities.all[].artifact_claims[]
-- TODO: chase down remote claims, if there is such a list.
-- TODO: also track down where df.artifact_claim are kept, if anywhere.
--   there's no associated .find() vector.
-- type df.family_artifact_claim is not a subclass of type df.artifact_claim .


-- 'item {item.id}'
-- 'book {item.id}
-- 'writing {written_content.id}
-- 'artifact {artifact.id}'
-- 'artifact {artifact name}'
--   can be in either the untranslated or translated form.
--   does not need the accent marks.
-- only the first letter of the command needs to be used.

local doit = true


local utils = require('utils')
local translateName = dfhack.TranslateName or dfhack.translation.translateName

local args = {...}

-- note: unlike normal printf, this ends the line even if '\n' is not used.
local function printf(...)
    print(string.format(...))
end

local function improvement_is_writing(improvement)
    if not df.itemimprovement:is_instance(improvement) then error(); end
    return (df.itemimprovement_pagesst:is_instance(improvement) 
	or df.itemimprovement_writingst:is_instance(improvement))
end

-- testing if any books have .world_data_id
if false then for _, i in ipairs(df.global.world.items.all) do
    if i:hasWriting() and i.world_data_id ~= -1 then print(i.id); return;
    end
end;print('none');return;end

-- probing for first book with author historical_figure holding it, by .written_content.author
if false then for _, i in ipairs(df.global.world.items.all) do
    local gref = (i.flags.artifact) and dfhack.items.getGeneralRef(i, df.general_ref_type.IS_ARTIFACT) or nil
    if gref and i:hasWriting() then
	for _,j in ipairs(i.improvements) do
	    if improvement_is_writing(j) then
		local wc = df.written_content.find(j.contents[0])
		local hfid = wc.author; local hf = df.historical_figure.find(hfid)
		if hf and hf.info and hf.info.books and #hf.info.books.artifacts_held > 0 then
		    local a = df.artifact_record.find(gref.artifact_id)
		    print(i.id, hfid, a.owner_hf, a.holder_hf, a.site, a.storage_site);

		    -- so when this happens, the artifact_record has
		    --   .owner_hf == hf, .holder_hf == hf, .site == -1, .storage_site == -1
		    -- or
		    --   .owner_hf == -1, .holder_hf == -1, .site == a site, .storage_site == the same site.
		end
	    end
	end
    end
end;return;end

-- probing for first artifact book with author historical_figure holding it, by general_ref
if false then for _, i in ipairs(df.global.world.items.all) do
    if i.flags.artifact and i:hasWriting() then
	local gref = dfhack.items.getGeneralRef(i, df.general_ref_type.IS_ARTIFACT)
	local art = (gref) and df.artifact_record.find(gref.artifact_id) or nil
	if art and art.holder_hf > -1 then
	    print(i.id)
	    return
	end
    end
end;print('none');return;end

-- probing for first artifact book that is in a site, by general_ref
if false then for _, i in ipairs(df.global.world.items.all) do
    if i.flags.artifact and i:hasWriting() and i:getType() ~= df.item_type.SLAB then
	local gref = dfhack.items.getGeneralRef(i, df.general_ref_type.IS_ARTIFACT)
	local art = (gref) and df.artifact_record.find(gref.artifact_id) or nil
	if art and art.site > -1 then
	    print(i.id)
	    return
	end
    end
end;print('none');return;end

-- probing for first artifact book with abs_tile_x set
if false then for _, i in ipairs(df.global.world.items.all) do
    if i.flags.artifact and i:hasWriting() then
	local gref = dfhack.items.getGeneralRef(i, df.general_ref_type.IS_ARTIFACT)
	local art = (gref) and df.artifact_record.find(gref.artifact_id) or nil
	if art and art.abs_tile_x ~= -1000000 then
	    print(i.id)
	    return
	end
    end
end;print('none');return;end

-- probing for first artifact book with feature_layer > -1
-- there weren't any in either of my test worlds.
if false then for _, i in ipairs(df.global.world.items.all) do
    if i.flags.artifact and i:hasWriting() then
	local gref = dfhack.items.getGeneralRef(i, df.general_ref_type.IS_ARTIFACT)
	local art = (gref) and df.artifact_record.find(gref.artifact_id) or nil
	if art and art.feature_layer > -1 then 
	    print(i.id)
	    return
	end
    end
end;print('none');return;end


local book_id, writing_id
local world = df.global.world
local plotinfo = (df.global._fields.plotinfo ~= nil) and df.global.plotinfo or df.global.ui
local translateName = dfhack.TranslateName or dfhack.translation.translateName


if #args < 2 then args[1] = "help"; end

if args[1]:startswith('b') or args[1]:startswith('i') then
    book_id = math.tointeger(args[2])

elseif args[1]:startswith('a') then
    local artifact_id = math.tointeger(args[2])
    if artifact_id ~= nil then
        local artifact = df.artifact_record.find(artifact_id)
        book_id = artifact.item.id

    else
	local artifact_name = table.concat(args, ' ', 2, #args)
	artifact_name = dfhack.toSearchNormalized(artifact_name)
	printf("Searching artifacts for %s", artifact_name)

	for i,art in ipairs(df.artifact_record.get_vector()) do
	    local aname1 = translateName(art.name, false)
	    aname1 = dfhack.toSearchNormalized(aname1)

	    local aname2 = (art.name.first_name == '') and translateName(art.name, true) or nil
	    aname2 = (aname2) and dfhack.toSearchNormalized(aname2) or nil
	    local anamep = aname1 .. ( (aname2) and (' (' .. aname2 .. ')') or '' )

	    -- print(anamep)

	    if aname1 == artifact_name or (aname2 and aname2 == artifact_name) then
		printf("Found artifact id %d item id %d name %s", art.id, art.item.id, anamep)
		book_id = art.item.id
		break
	    end

	    -- if i > 25 then return;end
	end
    end

elseif args[1]:startswith('w') then
    writing_id = math.tointeger(args[2])
    book_id = nil

    -- slow; find the first book (presumably the artifact book) with that written_contents_id.
    for _,i in ipairs(world.items.all) do

	if i:hasWriting() then
	    for _,j in ipairs(i.improvements) do
		-- if improvement_is_writing(j) then print(i.id, j.contents[0]); end
		if improvement_is_writing(j) and j.contents[0] == writing_id then
		    book_id = i.id
		    break
		end
	    end
	end

	-- if i.id > 999 then return;end

	if book_id ~= nil then break; end
    end
    if book_id == nil then qerror('could not find book with that written_contents id'); end
else
    print(([[
Usage:
    %s item <item id>
    %s book <item id>
    %s writing <written_contents id>
    %s artifact <artifact id>
    %s artifact <artifact name>
]]):trim():format
	(dfhack.current_script_name(), dfhack.current_script_name(), dfhack.current_script_name(),
	 dfhack.current_script_name(), dfhack.current_script_name()
    ))
    return
end


local item = (math.type(book_id) == "integer") and df.item.find(book_id) or nil     -- find the item again.
if not item then qerror("item does not exist"); end
if utils.binsearch(world.items.other.IN_PLAY, item.id, 'id') then qerror("that item is already on the map."); end

-- find the artifact again
local gref = dfhack.items.getGeneralRef(item, df.general_ref_type.IS_ARTIFACT)
local artifact_id = (gref) and gref.artifact_id or -1
local artifact = df.artifact_record.find(artifact_id)

if artifact and artifact.site == plotinfo.site_id then qerror('that item is somehow on-site but not on the map.'); end



printf("Retrieving item %d artifact %d %s from the world.", item.id, (artifact) and artifact.id or -1,
	dfhack.items.getReadableDescription(item))

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
	printf("The artifact was located in site %d %s", art_site.id, translateName(art_site.name))
	-- okay. populace.artifacts[] looks to be sorted by .id, but that may just be an
	--   artifact (no pun intended) caused by loading the savegame.  I don't trust it.
	local index, _ = utils.linear_index(art_site.populace.artifacts, artifact.id, 'id')
	if index then
	    art_site.populace.artifacts:erase(index)
	    index, _ = utils.linear_index(art_site.populace.artifacts, artifact.id, 'id')  -- verify deletion
	    if index then print("WARNING: didn't remove artifact from site"); end
	else
	    print("WARNING: didn't find artifact in site.")
	end
    end

    if art_holder_hf then
	printf("The artifact was being held by historical figure %d %s", art_holder_hf.id,
		dfhack.units.getReadableName(art_holder_hf) )
	local held = (art_holder_hf and art_holder_hf.info and art_holder_hf.info.books)
		and art_holder_hf.info.books.artifacts_held or nil
	if held then
	    local index, _ = utils.linear_index(held, artifact.id, 'id')
	    if index then 
		held:erase(index)
	    else
		print("WARNING: The artifact holder was not actually holding the artifact.")
	    end
	else
	    print("WARNING: The artifact holder was not actually holding the artifact.")
	end
    end

    if art_subregion then
	printf("The artifact was lost in subregion %d", artifact.subregion)
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
    artifact.site = plotinfo.site_id
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

    print('----')
    printall(utils.parse_bitfield_int(item.flags.whole,df.item_flags))
    printall(utils.parse_bitfield_int(item.flags2.whole,df.item_flags2))

    item.flags.removed = false
    item.flags2.utterly_destroyed = false

    item:categorize(true)

    print('----')
    printall(utils.parse_bitfield_int(item.flags.whole,df.item_flags))
    printall(utils.parse_bitfield_int(item.flags2.whole,df.item_flags2))

    item.flags.foreign = true  -- some artifacts are marked as .foreign, many are not.
    item.flags.trader = false  -- some artifacts are marked as .trader.  unknown why.
    item.flags.forbid = true

    local pos = xyz2pos(
	plotinfo.map_edge.surface_x[0],
	plotinfo.map_edge.surface_y[0],
	plotinfo.map_edge.surface_z[0]
    )
    local locstr = "The item should now be on the surface, at the top-left corner of the map."

    if #world.buildings.other.TRADE_DEPOT > 0 then
	local b = world.buildings.other.TRADE_DEPOT[0]
	pos = xyz2pos(b.centerx, b.centery, b.z)
	locstr = "The item should now be at the center of the (first) trade depot."
    end

    item.flags.on_ground = true  -- fake out .moveToGround().
    dfhack.items.moveToGround(item, pos)

    item:setTemperatureFromMap( --[[local=]] true, --[[contained=]] false)
    print(locstr)

    print('----')
    printall(utils.parse_bitfield_int(item.flags.whole,df.item_flags))
    printall(utils.parse_bitfield_int(item.flags2.whole,df.item_flags2))

end

