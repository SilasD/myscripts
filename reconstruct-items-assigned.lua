-- fully rebuild plotinfo.equipment.items.(un)assigned from uniform assigned equipment
local utils, dialogs = require('utils'), require('gui.dialogs')
local world, plotinfo = df.global.world, df.global.plotinfo

local function on_accept()
    local allocated = {}  -- sorted array of every item id assigned to squad-uniforms,miners,woodcutters,hunters.
    -- note: it would be faster to just append every item id to the list, then sort it afterwords.
    --     but the list would need to be deduplicated after sorting.
    -- TODO maybe: rewrite allocated as sparse: allocated[item_id] = true
    for _,id in ipairs(plotinfo.equipment.ammo_items)   do utils.insert_or_update(allocated, id); end
    for _,id in ipairs(plotinfo.equipment.work_weapons) do utils.insert_or_update(allocated, id); end
    for _,squad_id in ipairs(plotinfo.main.fortress_entity.squads) do
        local squad = df.squad.find(squad_id)
        for _,id in ipairs(squad.ammo.ammo_items) do utils.insert_or_update(allocated, id); end
        for _,pos in ipairs(squad.positions) do
            local E = pos.equipment
            utils.insert_or_update(allocated, E.quiver)    -- these can be -1
            utils.insert_or_update(allocated, E.backpack)
            utils.insert_or_update(allocated, E.flask)
            for _,bodypart in pairs(E.uniform) do
                for _,uniform_spec in ipairs(bodypart) do
                    for _,id in ipairs(uniform_spec.assigned) do
                        utils.insert_or_update(allocated, id)  -- five levels of nested for loops! crazy.
    end;end;end;end;end
    utils.erase_sorted(allocated, -1)  -- clean up "no item id" flag
    
    local itypes={"WEAPON","ARMOR","HELM","GLOVES","PANTS","SHOES","SHIELD","QUIVER","BACKPACK","FLASK","AMMO",}
    local item_exists, item_does_not_exist = {}, {}  -- table<item.id: true>
    for _,itype in ipairs(itypes) do
        --for _,id in ipairs(plotinfo.equipment.items_assigned[itype]) do TRACK STATS; end
        --for _,id in ipairs(plotinfo.equipment.items_unassigned[itype]) do TRACK STATS; end
        plotinfo.equipment.items_assigned[itype]:resize(0)    -- clobber this item itype's relevant lists
        plotinfo.equipment.items_unassigned[itype]:resize(0)
        -- ignore .unmanifested[], any such items should never be unassigned or assigned, or allocated either.
        for _,item in ipairs(world.items.other[itype]) do
            item_exists[item.id] = true
            if utils.binsearch(allocated, item.id) then  -- yeah, should rewrite allocated to be sparse.
                utils.insert_or_update(plotinfo.equipment.items_assigned[itype], item.id)
            else
                utils.insert_or_update(plotinfo.equipment.items_unassigned[itype], item.id)
            end
        end
--[[    for _,id in ipairs(allocated) do
            -- binsearch is not ideal here... all of these lists should be in sorted order,
            --   so we ought to walk up all the lists together in one go, but that's hard.
            if item_exists[id] and utils.binsearch(plotinfo.equipment.items_unassigned[itype], id) then
                utils.erase_sorted(plotinfo.equipment.items_unassigned[itype], id)
                utils.insert_or_update(plotinfo.equipment.items_assigned[itype], id)
        end;end ]]
    end
    for _,id in ipairs(allocated) do if not item_exists[id] then item_does_not_exist[id] = true; end; end
    -- TODO TRACK STATS
    print("either it worked or it didn't.  assign new uniforms to squads, and press the 'Update' button.")
end

dialogs.showYesNoPrompt("Rebuild assigned items lists", 
"Experimental!\n\nThis script fully rebuilds the lists\nthat control whether items are\n" ..
"available to be used in uniforms:\n\n* plotinfo.equipment.items_assigned\n* plotinfo.equipment.items_unassigned\n\n" ..
--"Items which are part of a uniform\nwill be added to the items_assigned\n" ..
--"list.  All other items which could\nbe used in uniforms will be added to\nthe items_unassigned list.\n\n" ..
"Only run this script if:\n\n* You have a savegame that you can\n  revert to.\n" ..
"* There are NO SQUADS on missions.\n\nIf you are sure, press 'Enter'.", nil, on_accept)