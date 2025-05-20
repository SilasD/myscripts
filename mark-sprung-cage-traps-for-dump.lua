-- mark for dumping (and un-forbids) all cages that are on top of a cage trap and have occupants.

-- TODO optionally mark them as .forbid to prepare for an 'autodump forbidden' ?
--   (command-line switch.)
local forbid_them = false
local verbose = false

-- TODO invoke autodump ?  command-line switch?  preset autodump location?

-- TODO verbose/quiet/silent options.


-- note: unlike normal printf, this ends the line even if '\n' is not used.
function printf(...)
    print(string.format(...))
end

function vprintf(...)
    if verbose then
	printf(...)
    end
end


-- Populate a Set keyed on the x,y,z of all cage traps.
--   Don't worry about whether they're loaded/unloaded,
--   forbidden, in a job, or other states.  We only care that they exist.
local cagetraps = {}
for _,trap in ipairs(df.global.world.buildings.other.TRAP) do
-- because we are only looking at .TRAP, we assume all buildings are type df.building_trapst .

    if trap.trap_type == df.trap_type.CageTrap then 
	cagetraps[string.format("%d,%d,%d", trap.centerx, trap.centery, trap.z)] = trap.id
	-- trap.id value is only used for non-nil trap-exists test.  the important part is the key.
    end
end


-- Test all cages for on-ground, occupied, and on top of a trap.
--	Also check certain other status flags.
local dumped_count = 0
for _,cage in ipairs(df.global.world.items.other.CAGE) do

    if  cage.flags.on_ground
        and not cage.flags.in_building          -- should be redundant.
        and not cage.flags.in_inventory         -- should be redundant.
        and not cage.flags.in_job
        and not cage.flags.dump                 -- don't mess with already dump-marked cages.
        -- TODO which other flags should be tested?
        and cage.pos.x ~= -30000		-- -30000 indicates off-map
        and cagetraps[string.format("%d,%d,%d", cage.pos.x, cage.pos.y, cage.pos.z)] ~= nil
                -- cage is on top of a trap (expensive test).
        and dfhack.items.getGeneralRef(cage, df.general_ref_type.CONTAINS_UNIT) 
                -- cage is occupied (expensive test).
                --    we only care that there's at least one occupant.
                -- note: cannot use dfhack.buildings.getCageOccupants(cage)
                --    because the cage is not a building.
    then 
	vprintf("%-7d %s", cage.id, dfhack.items.getReadableDescription(cage,0))
	cage.flags.dump = true
	cage.flags.forbid = forbid_them
	cage.flags.hidden = false
	dumped_count = dumped_count + 1
    end
end

printf("%d cage%s %sforbidden and marked for dump.", dumped_count, 
	(dumped_count == 1) and '' or 's', (forbid_them) and '' or 'un')
