--[====[
mark-items-in-this-building-for-trade
=====================================

Run this script while a building is selected.


]====]

-- TODO safety checks.
-- TODO how does this interact with stockpiles.
-- TODO   and how to handle containers.
-- TODO only run if there are active traders.
-- TODO don't trade intermediate items: logs, bars, blocks.
-- TODO don't trade items worth 0 dwarfbucks.
-- TODO allow typeof item selections: goblets, all crafts, etc.


--[=[ 
Important things about the C++ source code:
canTrade() thinks that items in a building are not tradeable.
markForTrade() does not consult canTrade() .
markForTrade() does not handle the special-case where the item is already in the depot.
markForTrade() does not check for forbidden depots.


library/modules/Items.cpp 

bool Items::canTrade(df::item *item) {
    CHECK_NULL_POINTER(item);
    if (item->flags.bits.owned || item->flags.bits.artifact ||
        item->flags.bits.spider_web || item->flags.bits.in_job
    )
        return false;

    for (auto gref : item->general_refs) {
        switch (gref->getType())
        {
            case general_ref_type::UNIT_HOLDER:
            case general_ref_type::BUILDING_HOLDER:
                return false;
            default:
                break;
        }
    }

    if (getSpecificRef(item, specific_ref_type::JOB))
        return false; // Ignore any items assigned to a job
    return checkMandates(item);
}
Note that being in a building is enough to fail the tests.


bool Items::markForTrade(df::item *item, df::building_tradedepotst *depot) {
    CHECK_NULL_POINTER(item);
    CHECK_NULL_POINTER(depot);
    // Validate that the depot is in a good state
    if ((depot->getBuildStage() < depot->getMaxBuildStage()) ||
        (!depot->jobs.empty() && depot->jobs[0]->job_type == job_type::DestroyBuilding)
    )
        return false;

    auto href = df::allocate<df::general_ref_building_holderst>();
    if (!href)
        return false;

    auto job = new df::job();
    job->job_type = job_type::BringItemToDepot;
    job->pos = df::coord(depot->centerx, depot->centery, depot->z);

    // job <-> item link
    if (!Job::attachJobItem(job, item, df::job_role_type::Hauled)) {
        delete job;
        delete href;
        return false;
    }

    // job <-> building link
    href->building_id = depot->id;
    depot->jobs.push_back(job);
    job->general_refs.push_back(href);

    // Add to job list
    Job::linkIntoWorld(job);
    return true;
}

]=]


local d = nil
for i, dd in ipairs(df.global.world.buildings.other.TRADE_DEPOT) do
    if	    not dd.contained_items[0].item.flags.forbid
	and not dd.contained_items[1].item.flags.forbid
	and not dd.contained_items[2].item.flags.forbid
	-- TODO other safety checks
    then
	d = dd
	break
    end
end
if d == nil then qerror('No (unforbidden) depot!'); end
local desc = (d.name ~= "") and d.name or dfhack.items.getReadableDescription(d.contained_items[0].item)
print('Targetting the ' .. desc .. ' Trade Depot.')


local b = dfhack.gui.getSelectedBuilding()

if not b then qerror('No building selected!'); end

if b == d then qerror('Use the mark-items-in-trade-depot-for-trade script instead!'); end

local p = xyz2pos(b.centerx, b.centery, b.z)

local marked = 0

for i=(#b.contained_items-1), 0, -1 do
    local n = b.contained_items[i]
    local m = n.item
    if m ~= nil
	and n.use_mode == 0

	-- TODO check item types?
	-- TODO lots of safety checks, like being an actual building.

	-- m.flags.on_ground will always be false
	and not m.flags.in_job
	-- m.flags.hostile should always be false
	-- m.flags.in_inventory will always be false
	and not m.flags.removed
	and not m.flags.in_building		-- should be false for loose items (in most circumstances)
	-- m.flags.container don't care
	and not m.flags.dead_dwarf		-- better be false!
	and not m.flags.rotten
	-- m.flags.spider_web will always be false
	-- m.flags.construction will always be false
	-- m.flags.encased will always be false
	-- m.flags.murder will always be false if .dead_dwarf is false.
	and not m.flags.foreign 		-- did we previously purchase it?
	and not m.flags.trader 			-- does it not belong to us?
	and not m.flags.owned			-- personal possession?
	-- m.flags.garbage_collect don't care
	-- m.flags.artifact don't care
	and not m.flags.forbid			-- forbidden for some reason?
	-- m.flags.already_uncategorized don't care
	and not m.flags.dump			-- marked for dump?
	-- m.flags.on_fire don't care
	-- m.flags.melt don't care
	-- m.flags.hidden don't care
	-- m.flags.use_recorded don't care
	-- m.flags.artifact_mood don't care
	-- m.flags.temps_computed don't care
	-- m.flags.weight_computed don't care
	-- m.flags.top_open don't care
	-- m.flags.from_worldgen don't care
	-- m.flags2.has_rider don't care
	-- m.flags2.forbid_on_unretire don't care
	-- m.flags2.grown don't care
	-- m.flags2.location_reserved don't care
	-- m.flags2.utterly_destroyed don't care
	-- m.flags2.might_contain_artifact don't care

    then
	if not (dfhack.items.markForTrade(m, d)) then
	    print (('Problem with item #%d %s, failed to mark for trade.')
		:format(i, dfhack.items.getReadableDescription(m) ))
	end
	n = nil		-- no longer valid after .moveToGround()
	marked = marked + 1
    end
end

print(('%d %s was marked for trade in the (first) trade depot.'):format(
	marked, (marked == 1 and 'item' or 'items'), (marked == 1 and 'was' or 'were') ))
