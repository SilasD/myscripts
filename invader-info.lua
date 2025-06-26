
local world = df.global.world
local plotinfo = (df.global._fields.plotinfo ~= nil) and df.global.plotinfo or df.global.ui
local C = dfhack.df2console
local function X(name) return C(dfhack.translation.translateName(name, true)); end
local function Cname(unit) return C(X(dfhack.units.getVisibleName(unit))); end

-- note: unlike normal printf, this ends the line even if '\n' is not used.
local function printf(...)
    print(string.format(...))
end


-- collect info
local marauder, rider, forest, active_invader		= 0, 0, 0, 0
local invader_origin, coward, hidden_ambusher, ridden	= 0, 0, 0, 0
local prof, race, civ_id, cul_id		= {}, {}, {}, {}

for _,unit in ipairs(world.units.active) do
    if dfhack.units.isAlive(unit) and dfhack.units.isInvader(unit) then

	local f = unit.flags1
	marauder	= marauder	+ (f.marauder		and 1 or 0)
	rider 		= rider		+ (f.rider		and 1 or 0)
	forest		= forest	+ (f.forest		and 1 or 0)
	active_invader	= active_invader+ (f.active_invader	and 1 or 0)
	invader_origin	= invader_origin+ (f.invader_origin	and 1 or 0)
	coward		= coward	+ (f.coward		and 1 or 0)
	hidden_ambusher	= hidden_ambusher+(f.hidden_ambusher	and 1 or 0)
	ridden		= ridden	+ (f.ridden		and 1 or 0)

	prof[unit.profession]		= (prof[unit.profession]	or 0) + 1
	race[unit.race]			= (race[unit.race]		or 0) + 1
	civ_id[unit.civ_id]		= (civ_id[unit.civ_id]		or 0) + 1
	cul_id[unit.cultural_identity]	= (cul_id[unit.cultural_identity] or 0) + 1

	for _, gref in ipairs(unit.general_refs) do
	    if df.general_ref_is_nemesisst:is_instance(gref) then
		printf("unit %d %s has nemesis %d", unit.id, Cname(unit), gref.nemesis_id)
		local nid = gref.nemesis_id
		local n = df.nemesis_record.find(nid)
		local hf = (n) and n.figure or nil
		if n then
		    -- nemesis interesting?
		end
		for _, el in ipairs((hf) and hf.entity_links or {}) do
		    if df.histfig_entity_link_memberst:is_instance(el) then
			local e = df.historical_entity.find(el.entity_id)
			local en = (e) and X(e.name) or ""
			local et = (e) and df.historical_entity_type[e.type] or ""
			printf("    member: %d%% %d %s  %s", el.link_strength, el.entity_id, en, et)
			if (e) and e.type == df.historical_entity_type.SiteGovernment then
			    for _, sl in ipairs(e.site_links) do
				local ws = df.world_site.find(sl.target)
				local wsn = (ws) and X(ws.name) or ""
				print("        site link to : %d %s", sl.target, wsn)
			    end
			end
		    else
			printf("    unhandled entity link: %s", tostring(el._type))
		    end
		end
    		for _, sl in ipairs((hf) and hf.site_links or {}) do
		    if false then
			-- TODO fill in what types of links can occur, and relevant data.
		    else
			printf("    unhandled site link: %s", tostring(sl._type))
		    end
		end
		local ci = (hf) and df.cultural_identity.find(hf.cultural_identity) or nil
		if (ci) and ci.site_id > -1 then
		    printf("    cultural site: %d %s", ci.site_id, X(df.world_site.find(ci.site_id).name))
		end
		if (ci) and ci.civ_id > -1 then
		    printf("    cultural civ: %d %s", ci.civ_id, X(df.historical_entity.find(ci.civ_id).name))
		end
		for _,cie in ipairs((ci) and ci.group_log or {}) do
		    printf("    cultural group: %d %s %s", cie.group_id, 
			df.historical_entity_type[df.historical_entity.find(cie.group_id).type],
			X(df.historical_entity.find(cie.group_id).name))
		end
	    elseif df.general_ref_contained_in_itemst:is_instance(gref) then
		-- nothing
	    else
		printf("%d %s Unhandled gref %s", unit.id, Cname(unit), tostring(gref._type))
	    end
	end  -- general refs
    end  -- invading unit
end  -- collect data


print()
printf("%-20s%4d", ".marauder", marauder)
printf("%-20s%4d", ".rider", rider)
printf("%-20s%4d", ".forest", forest)
printf("%-20s%4d", ".active_invader", active_invader)
printf("%-20s%4d", ".invader_origin", invader_origin)
printf("%-20s%4d", ".coward", coward)
printf("%-20s%4d", ".hidden_ambusher", hidden_ambusher)
printf("%-20s%4d", ".ridden", ridden)

printf("Professions"); for k, v in pairs(prof) do printf("%-5d  %s", v, df.profession[k]); end
printf("Races"); for k, v in pairs(race) do printf("%-5d  %s", v, df.creature_raw.find(k).name[1]); end
printf("Historical Entities:")
for k, v in pairs(civ_id) do 
    local c = df.historical_entity.find(k)
    if (c) then
	printf("%-5d  %-15s  %s", v, df.historical_entity_type[c.type], X(c.name))
    end
end
printf("Cultural Identities")
for k,v in pairs(cul_id) do
    local c = df.cultural_identity.find(k)
    if (c) then
	printf("%-5d  ci %-5d  site %d %s  civ %d %s", v, k,
		c.site_id, X(df.world_site.find(c.site_id).name),
		c.civ_id, X(df.historical_entity.find(c.civ_id).name) )
    end
end
