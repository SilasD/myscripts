--[====[
(name)
=============================================
This command changes the way soldiers use ammunition:
    * metal ammunition will be used exclusively for combat.
    * wood and bone ammunition will be used exclusively for archery training.

The intent is to replicate the old default behavior before the Steam release.

Note: This change is only made for soldiers.  Hunters still use any ammunition.

Note: This should work for all ranged weapons / ammunition types, but has only been
    tested with crossbows / bolts.
]====]


-- TODO: look, instead of dropping all items, probably just split the old ammo into the new types.
-- TODO pull in the drop-all-ammo script.


local utils = require('utils')

local plotinfo = df.global.plotinfo or df.global.ui
local translateName = dfhack.TranslateName or dfhack.translation.translateName


---@type df.squad.id[]
local squad_ids = df.historical_entity.find(plotinfo.group_id).squads


local function printf(...)
    print(string.format(...))
end


------------------------------------------------------------------------------------------------


-- Change/add ammo specs as necessary.
--
---@param squad df.squad
---@param ammo_subtype df.squad_ammo_spec.item_subtype|df.itemdef_ammost.subtype|integer|nil
---@return boolean   -- were changes made?
local function squad_modify_ammunition_types(squad, ammo_subtype)
    if not df.squad:is_instance(squad) then
        qerror("parameter squad did not recieve a df.squad")
    end

    -- this is the normal case when the routine is passed a squad without ranged weapons.
    if ammo_subtype == nil and #squad.ammo.ammunition == 0 then
        return false;
    end

    ammo_subtype = ammo_subtype or squad.ammo.ammunition[0].item_subtype

    local sqdesc = string.format("Squad %s", 
            (squad.alias ~= "") and squad.alias or translateName(squad.name, true) )

    printf("%s: %d ammo specs found.  Processing.", sqdesc, #squad.ammo.ammunition)

    local foundmetal, foundwood, foundbone = false, false, false
    local modified = false

    ---@type df.itemdef_ammost
    local base_raw = dfhack.items.getSubtypeDef(df.item_type.AMMO, ammo_subtype)

    -- don't consider this a crash error.
    if (base_raw == nil) then
        printf("WARNING: could not find the raws for ammo subtype %d", ammo_subtype)
        return false;
    end

    if base_raw.id ~= "ITEM_AMMO_BOLTS" then
        printf("WARNING: This squad's base ammo type is %s, not ITEM_AMMO_BOLTS.", base_raw.id )
        printf("Continuing processing, but this may have odd effects.")
    end

    local subtypename = string.format("%s%s%s",
            base_raw.adjective, (base_raw.adjective ~= '') and ' ' or '', base_raw.name_plural )

    for i, ammo in ipairs (squad.ammo.ammunition) do

        if ammo.item_type ~= df.item_type.AMMO then   -- shouldn't ever happen.
            qerror("ammo.item_type ~= df.item_type.AMMO")
        end

        ---@type df.itemdef_ammost
        local raw = dfhack.items.getSubtypeDef(ammo.item_type, ammo.item_subtype)

        local desc = string.format("Ammo subtype #%d (%s%s%s)", i,
                raw.adjective, (raw.adjective ~= '') and ' ' or '', raw.name_plural )

        -- test all the reasons why we shouldn't change this entry to metal/combat.
        if raw.raw_strings[0].value == "[GENERATED]" then
            printf("%s is a procedurally-generated ammo type, skipping.", desc)

        elseif ammo.item_subtype ~= ammo_subtype then
            printf("%s does not match base subtype %d (%s), skipping.", 
                    desc, ammo_subtype, subtypename)

        elseif ammo.material_class == df.entity_material_category.AmmoMetal then
            foundmetal = true
            printf("%s is already set to metal, skipping.", desc)

        elseif ammo.material_class == df.entity_material_category.Wood then
            foundwood = true
            printf("%s is already set to wood, skipping.", desc)

        elseif ammo.material_class == df.entity_material_category.Bone then
            foundbone = true
            printf("%s is already set to bone, skipping.", desc)

        elseif ammo.material_class ~= -1 then
            printf("%s material class is already set, skipping", desc)

        elseif ammo.mattype ~= -1 then
            printf("%s material type is already set, skipping", desc)

        elseif true then
            printf("%s is now set for metal, combat-only.", desc)
            ammo:assign{ material_class=df.entity_material_category.AmmoMetal,
                    mattype=-1, matindex=-1, flags={ use_combat=true, use_training=false } }
            foundmetal = true
            modified = true
        end

    end  -- foreach ammunition


    -- an empty ammunition array will be handled by adding an entry for metal.

    if not foundmetal then
        printf("Adding a new ammo spec entry for %s, metal, combat-only.", subtypename)

        squad.ammo.ammunition:insert('#', { new=df.squad_ammo_spec, item_type=df.item_type.AMMO,
                item_subtype=ammo_subtype, material_class=df.entity_material_category.AmmoMetal, 
                mattype=-1, matindex=-1, amount=250, flags={ use_combat=true, use_training=false } } )

        modified = true
    end

    if not foundwood then
        printf("Adding a new ammo spec entry for %s, wood, training-only.", subtypename)

        squad.ammo.ammunition:insert('#', { new=df.squad_ammo_spec, item_type=df.item_type.AMMO,
                item_subtype=ammo_subtype, material_class=df.entity_material_category.Wood, 
                mattype=-1, matindex=-1, amount=250, flags={ use_combat=false, use_training=true } } )

        modified = true
    end

    if not foundbone then
        printf("Adding a new ammo spec entry for %s, bone, training-only.", subtypename)

        squad.ammo.ammunition:insert('#', { new=df.squad_ammo_spec, item_type=df.item_type.AMMO,
                item_subtype=ammo_subtype, material_class=df.entity_material_category.Bone,
                mattype=-1, matindex=-1, amount=250, flags={ use_combat=false, use_training=true } } )
        modified = true
    end

    return modified
end


------------------------------------------------------------------------------------------------


-- Note: if you modify this function, propigate the changes into drop-all-ammo.lua as well.
--
---@param sq df.squad
---@return boolean
---@return integer
local function squad_drop_all_ammo(squad)
    local squad_changed = false   -- did we modify the squad?
    local units_changed = 0

    ---@type df.item.id[]
    local unassign_item_ids = {}


    -- OKAY, lots to do.  First we're going to process the SQUAD.

    -- record and delete all currently assigned ammo from the squad.ammo.ammunition[].assigned lists.
    for _, ammotype in ipairs(squad.ammo.ammunition) do

        -- remember the ammo id's.
        for _, item_id in ipairs(ammotype.assigned) do
            utils.insert_or_update(unassign_item_ids, item_id)
        end
        squad_changed = (#ammotype.assigned > 0) or squad_changed
        ammotype.assigned:resize(0)     -- just erase it all.
        squad.ammo.update.ammo = true   -- should always be true anyway.
    end

    -- record and delete all currently assigned ammo from the master squad.ammo.ammo_items[] list.
    for _, item_id in ipairs(squad.ammo.ammo_items) do
        utils.insert_or_update(unassign_item_ids, item_id)   -- this ought to be redundant, but....
    end
    squad_changed = (#squad.ammo.ammo_items > 0) or squad_changed
    squad.ammo.ammo_items:resize(0)   -- and erase it all.
    squad.ammo.ammo_units:resize(0)
    squad.ammo.update.ammo = true     -- should always be true anyway.

    -- note: ammo is not tracked in each squaddie's assigned .equipment, so that makes life easier.


    -- We're done with the SQUAD.  Now we process the SQUADDIES.

    -- drop everything in the squaddies' assigned quivers (for valid units in the fort only).
    --   we are ASSUMING that anything in a quiver is ammunition (and it was just unassigned).
    --   note that this runs for all squaddies, not just for ranged squaddies.  that's ok.
    for _, position in ipairs(squad.positions) do

        if not squad_changed then break; end
        -- if we didn't change the squad structure, don't change any units either.
        --   (Using a break lets me not indent the code further with an if, and not use a goto.)


        local changed = false    -- track if we modified the unit.
        local hf, unit, quiver   -- pre-declare variables so the gotos don't cross scope.

        if position.occupant == -1 then goto CONTINUE; end
        hf = df.historical_figure.find(position.occupant)
        if not hf then goto CONTINUE; end
        unit = (hf) and df.unit.find(hf.unit_id)
        if not unit then goto CONTINUE; end
        if not dfhack.units.isCitizen(unit) then goto CONTINUE; end   -- can't happen, but....
        if not dfhack.units.isActive(unit) then goto CONTINUE; end

        -- drop everything in the assigned quiver.
        --   (this should work even if the quiver is not in the unit's inventory.  not tested.)
        quiver = df.item.find(position.equipment.quiver)
        if (quiver) and df.item_quiverst:is_instance(quiver) then

            -- walk the quiver's general refs, backwards so we can delete them.
            --   we're looking for any items contained in the quiver.
            --   we can't use .getGeneralRef() because there may be multiple items.
            for i = (#quiver.general_refs-1), 0, -1 do

                local gref = quiver.general_refs[i]
                if df.general_ref_contains_itemst:is_instance(gref) then

                    -- it's in the quiver, assume it's ammo.
                    -- add it to the unassign_item_ids list (it ought to already be in there, but...).
                    utils.insert_or_update(unassign_item_ids, gref.item_id)

                    -- df.item.find() could potentially return nil,
                    --   but we'll assume .moveToGround() can deal with that.
                    --   we'll also assume .moveToGround() deals with item.flags.in_job, etc.
                    local success = dfhack.items.moveToGround(df.item.find(gref.item_id), unit.pos)
                    gref = nil  -- this general ref presumably was just deleted.  don't use it.

                    if not success then 
                        printf('Unable to remove item %d from quiver %d', gref.item_id, quiver.id)
                    end

                    changed = success or changed
                end
            end
        end  -- quiver


        -- the unit's inventory was potentially updated by .moveToGround().  
        -- now update the squaddie's uniforms.
        --   remove all references to each unassigned ammo in the unit's uniform lists.
        --     note that we do not care whether the ammo was assigned to the squaddie, 
        --     or whether it was in their quiver.  we just brute-force it no matter what.
        --   assumes that all the uniform lists are sorted.
        for _, item_id in ipairs(unassign_item_ids) do
            changed = utils.erase_sorted(unit.uniform.uniforms.CLOTHING,        item_id) or changed
            changed = utils.erase_sorted(unit.uniform.uniforms.REGULAR,         item_id) or changed
            changed = utils.erase_sorted(unit.uniform.uniforms.TRAINING,        item_id) or changed
            changed = utils.erase_sorted(unit.uniform.uniforms.TRAINING_RANGED, item_id) or changed
            changed = utils.erase_sorted(unit.uniform.uniform_pickup,           item_id) or changed
            changed = utils.erase_sorted(unit.uniform.uniform_drop,             item_id) or changed
        end


        -- we could walk the unit's .inventory[], and check if any items are ammo.
        -- we could also do that for all of the uniforms.
        --   but this way is good enough.
        -- also we don't want to deal with off-duty units who happen to be hauling ammo.
        --   or other corner cases.

        ::CONTINUE::

        units_changed = units_changed + ((changed) and 1 or 0)

    end  -- foreach position


    -- FINALLY, maintain the assigned equipment lists.

    -- any item_id we removed from .ammo.ammo_items[],
    --     or from .ammunition[].assigned[],
    --     or dropped from a uniform,
    --   remove it from assigned equipment, add it to unassigned equipment.
    for _, item_id in ipairs(unassign_item_ids) do

        -- don't worry if it wasn't in there.
        utils.erase_sorted(plotinfo.equipment.items_assigned.AMMO, item_id)

        if (df.item.find(item_id) ~= nil) then  -- only if the item exists!
            utils.insert_or_update(plotinfo.equipment.items_unassigned.AMMO, item_id)
        end

    end

    -- and we're DONE.  what a pain.
    return squad_changed, units_changed
end


------------------------------------------------------------------------------------------------


-- NOTE: I decided not to use this method, but I wrote and tested it all so it stays in.
--
-- tries to figure out what type (and class) of ammo the squad uses.
-- returns the subtype and class of the ammo used by the first-found uniform ranged weapon uniform spec,
--     or  the subtype and class of the ammo used by the first-found explicitly assigned ranged weapon.
-- returns -1, "" if it didn't find any ranged weapons.
--
---@param squad df.squad
---@return df.itemdef_ammost.subtype|df.squad_ammo_spec.item_subtype|integer     -- normally 0 or -1
---@return df.itemdef_ammost.ammo_class|df.itemdef_weaponst.ranged_ammo|string   -- normally BOLT or ""
local function get_squad_ammo_subtype(squad)

    -------------
    -- returns the class of ammo used by subtype of the first-found uniform ranged weapon uniform spec,
    --   or the class of ammo used by the subtype of the first-found explicitly assigned ranged weapon.
    -- returns "" if it didn't find any.
    --
    -- this is a subfunction so that it can early-out of the nested loops via return.
    -- this is terrible code and I hate it.  and I hate the triple-nested uniform specs.
    --
    ---@param squad df.squad
    ---@return df.itemdef_ammost.ammo_class|df.itemdef_weaponst.ranged_ammo|string   -- normally BOLT or ""
    local function get_first_squad_ranged_weapon_ammo_class(squad)

        for i, position in ipairs(squad.positions) do

            -- note: unoccupied positions still have a valid equipment structure,
            --   which may have valid equipment specs, so we won't skip them.

            ---@type integer
            ---@type df.squad_uniform_spec
            for j, spec in ipairs(position.equipment.uniform.weapon) do

                -- 1) is a valid weapon type with a defined ammo class specified?
                if spec.item_type == df.item_type.WEAPON and spec.item_subtype ~= -1 then

                    ---@type df.itemdef_weaponst
                    local raw = dfhack.items.getSubtypeDef(spec.item_type, spec.item_subtype)
                    if raw ~= nil and df.itemdef_weaponst:is_instance(raw) then
                        local class = raw.ranged_ammo
                        if class ~= "" then return class; end
                    end
                end

                -- 2) is there a user-assigned weapon item that has ranged ammo?
                if spec.item ~= -1 then
                    ---@type df.item_weaponst
                    local item = df.item.find(spec.item)
                    if item ~= nil and df.item_weaponst:is_instance(item) then
                        local class = item.subtype.ranged_ammo
                        if class ~= "" then return class; end
                    end
                end

                -- 3) is there a game-assigned existing weapon item that has ranged ammo?
                --   (there should be 0 or 1 weapons, but who knows?)
                for _, item_id in ipairs(spec.assigned) do
                    ---@type df.item_weaponst
                    local item = df.item.find(item_id)
                    if item ~= nil and df.item_weaponst:is_instance(item) then
                        local class = item.subtype.ranged_ammo
                        if class ~= "" then return class; end
                    end
                end

            end   -- foreach weapon
        end   -- foreach position

        return ""   -- didn't find any ranged weapons, so didn't find a class
    end

    ----------------

    if not df.squad:is_instance(squad) then
        qerror("parameter squad did not recieve a df.squad")
    end

    -- I guess we'll just check that a weapon has ranged ammo, because that's all we really care about.

    local class = get_first_squad_ranged_weapon_ammo_class(squad)

    -- at this point, we MIGHT have an ammo class, e.g. BOLT.
    -- if we do, we need to scan through all of the raws ammo types, looking for it.
    --   (there may be more than one matching ammo type; we return the first one.)

    local subtype = -1
    for i = 0,999 do   -- we'll never have more than 1000 ammo types, right?  right?
        if class == "" then
            subtype = -1   -- if we never found an ammo class, early-out on first iteration.
            break
        end

        ---@type df.itemdef_ammost?
        local raw = dfhack.items.getSubtypeDef(df.item_type.AMMO, i)

        if raw == nil then
            subtype = -1   -- didn't find it
            break
        end

        if raw.ammo_class == class then
            subtype = i   -- found it.
            break
        end
    end

    return subtype, class
end


-- does the squad have a raid order?
--
---@param squad df.squad
---@return boolean
local function is_squad_raiding(squad)
    local raiding = false

    -- check for a raid order.
    for _, order in ipairs(squad.orders) do
        if df.squad_order_raid_sitest:is_instance(order) then raiding = true; break; end
    end
    return raiding
end


-- is any squad member not physically present on the map?
--
---@param squad df.squad
---@return boolean
local function is_squad_off_site(squad)
    local ok = true

    for i, position in ipairs(squad.positions) do
        if not ok then break; end

--        local hf, unit          -- pre-declare variables so the goto doesn't cross context.

        if position.occupant == -1 then goto CONTINUE; end

        local hf = df.historical_figure.find(position.occupant)
        if hf == nil then ok = false; break; end
        local unit = df.unit.find(hf.unit_id)
        if unit == nil then ok = false; break; end

        if not dfhack.units.isActive(unit) then ok = false; break; end
        -- TODO are there other possibilities?

        ::CONTINUE::
    end

    return not ok
end


------------------------------------------------------------------------------------------------


-- Note: turns out this doesn't matter.  The game is robust enough to deal with disappearing ammo.
--
-- is any squad member practicing archery?
--
---@param squad df.squad
---@return boolean
local function is_squad_doing_archery_practice(squad)
    local practice = false

    -- finally found this.  not in the jobs list, not in the unit, it's in the squad.
    ---@type df.activity_entry
    local activity = df.activity_entry.find(squad.activity)
    if activity then
        for _, event in ipairs(activity.events) do
            if df.activity_event_ranged_practicest:is_instance(event) then
                practice = true
                break
            end
        end
    end
    return practice
end


------------------------------------------------------------------------------------------------


print()
print(is_squad_raiding(df.squad.find(265)))
print(is_squad_raiding(df.squad.find(266)))
print(is_squad_raiding(df.squad.find(267)))
print(is_squad_raiding(df.squad.find(281)))

print()
print(is_squad_off_site(df.squad.find(265)))
print(is_squad_off_site(df.squad.find(266)))
print(is_squad_off_site(df.squad.find(267)))
print(is_squad_off_site(df.squad.find(281)))

print()
print(is_squad_doing_archery_practice(df.squad.find(265)))
print(is_squad_doing_archery_practice(df.squad.find(266)))
print(is_squad_doing_archery_practice(df.squad.find(267)))
print(is_squad_doing_archery_practice(df.squad.find(281)))

print()

local squad = df.squad.find(266)
local modified = squad_modify_ammunition_types(squad)
print('modified', modified)
local squad = df.squad.find(267)
local modified = squad_modify_ammunition_types(squad)
print('modified', modified)
if modified then
    squad_drop_all_ammo(squad)
end


