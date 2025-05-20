-- TODO safety checks.
-- TODO do all trade depots?  except forbidden ones?
-- TODO only run if there are active traders.

--[=[ library/modules/Items.cpp 

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
Note that markForTrade() does not consult canTrade().
Note that it does not special-case the case where the item is already in the depot.
Does DF deal with that gracefully?  Eh, work around it.

]=]


if #df.global.world.buildings.other.TRADE_DEPOT < 1 then qerror('No depot!'); end
local d = df.global.world.buildings.other.TRADE_DEPOT[0]


local marked = 0

for _,n in ipairs(d.contained_items) do 
  local m = n.item
  if n.use_mode == 0			-- loose item, not part of building.
	-- and dfhack.items.canTrade(m)	-- Wrong: I have to assume this does all of these checks:
					-- Well, no, it doesn't.


	-- m.flags.on_ground will always be false
	and not m.flags.in_job
	-- m.flags.hostile should always be false
	-- m.flags.in_inventory will always be false
	and not m.flags.removed
	and not m.flags.in_building		-- THIS IS THE KEY FLAG.
	-- m.flags.container don't care
	and not m.flags.dead_dwarf		-- better be false!
	and not m.flags.rotten
	-- m.flags.spider_web will always be false
	-- m.flags.construction will always be false
	-- m.flags.encased will always be false
	-- m.flags.murder will always be false if .dead_dwarf is false.
	and not m.flags.foreign 		-- did we previously purchase is?
	and not m.flags.trader 			-- does is belong to us?
	and not m.flags.owned			-- personal possession?
	-- m.flags.garbage_collect don't care
	-- m.flags.artifact don't care
	and not m.flags.forbid			-- forbidden for some reason?
	-- m.flags.already_uncategorized don't care
	and not m.flags.dump			-- dumping it?
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
    -- dfhack.items.markForTrade(m, d)
    -- do NOT use .markForTrade() !  it always adds a BringItemToDepot hauling job.

    -- just toggle the in_building flag.
    m.flags.in_building = true
    marked = marked + 1
  end
end

print(('%d %s in the (first) trade depot %s marked for trade.'):format(
	marked, (marked == 1 and 'item' or 'items'), (marked == 1 and 'was' or 'were') ))
