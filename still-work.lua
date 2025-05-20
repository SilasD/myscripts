--@ module=false

local utils = require('utils')
local gui = require('gui')
local overlay = require('plugins.overlay')
local widgets = require('gui.widgets')



if dfhack_flags.module then
    return
end

main({...})


--[=[

advtools.* no
autolabor overlay  'work details screen' still don't know that this is.
buildingplan.* no
burrow.designation  maybe?  look at it?
caravan.assigntrade  single line, no
caravan.displayitemselector single line, no, (why is this here anyway)
caravan.movegoods  single line, no.
caravan.movegoods_hider  hides a DF button, interesting for other scripts.
caravan.trade  deal with bins, ... maybe?
caravan.tradeagreement  ?
caravan.tradebanner  single line, no.
caravan.tradeethics  popup, no.
confirm.overlay  popup, no.
dig.asciicarve  map overlay, no, maybe obsolete?
dig.warmdamp  map overlay, no.
dig.warmdamptoolbar  toolbar new button, no.
exportlegends.*  dunno.
civ-alert.big_red_button  multi-line popup, no.
design.dimensions  multi-line popup, no.
notify-panel  multi-line overlay, no.
settings-manager.*  several single-line and multi-line overlays, no.
unit-info-viewer  YES YES YES this is relevant, LOOK AT THIS, LOOK AT THIS, LOOK AT THIS.
hotkeys.*menu  buttons, no.
idle-crafting  YES maybe relevant LOOK AT THIS.
logistics.autoretrain  multi-line overlay/button, no.
notes.map-notes  probably related to map drawing, no.
orders.importexport  multi-line overlay/buttons, no.
orders.laborrestrictions  workshop work details, large overlay, on workers tab only. YES LOOK AT.
orders.recheck  button. no.
orders.skillrestrictions  workshop work details, large overlay, on workers tab only. YES LOOK AT.
overlay.title-version  single-line overlay. no.
preserve-rooms.reserved  multi-line popup. no.
prioritize.enroute  overlay. maybe, but no.
settings-manager.work_details save/load/apply-to-new-fort in Standing Orders/Automated Workshops
sort.*  no.
sort.workanimals  maybe...?
spectate.*  main map overlays.  no.
startdwarf.overlay.  I thought that was in Vanilla.  no, but notable for adding a scrollbar.
stockpiles.overlay  no
stocks.overlay  no
suspendmanager.overlay  main map, no.
suspendmanager.status  building info panel overlay, maybe but no.
suspendmanager.toggle  building info panel single-line overlay, no
trackstop.rollers  no.
trackstop.trackstop  no.
uniform-unstick.overlay  no.
zone.*  no. not really.

--]=]



--[==[

dfhack.gui.getFocusStrings(viewscreen)
Returns a table of string representations of the current UI focuses. The strings have a “screen/foo/bar/baz…” format e.g.:
[1] = "dwarfmode/Info/CREATURES/CITIZEN"
[2] = "dwarfmode/Squads"

[lua]# ~ dfhack.gui.getFocusStrings(dfhack.gui.getDFViewscreen())
table: 0000026669AC4120
1                        = dwarfmode/ViewSheets/BUILDING/Workshop/Still/Tasks
2                        = dwarfmode/ViewSheets/BUILDING/Workshop/Still/Items

dfhack.gui.getCurFocus([skip_dismissed])
Returns the focus string of the current viewscreen.

~ dfhack.gui.getCurFocus()
table: 0000026669ACC960
1                        = dwarfmode/ViewSheets/BUILDING/Workshop/Still/Tasks
2                        = dwarfmode/ViewSheets/BUILDING/Workshop/Still/Items

I care about dwarfmode/ViewSheets/BUILDING/Workshop/Still/Tasks

dfhack.gui.matchFocusString(focus_string[, viewscreen])
Returns true if the given focus_string is found in the current focus strings, or as a prefix to any of the focus strings, or false if no match is found. Matching is case insensitive. If viewscreen is specified, gets the focus strings to match from the given viewscreen.

~ dfhack.gui.matchFocusString("dwarfmode/ViewSheets/BUILDING/Workshop/Still/Tasks")
true



--]==]


--[=[
Notes about gui.dwarfmode.
There was nothing super-relevant in here;
it's mostly about map drawing.


SIDEBAR_MODE_KEYS obsolete (?)

function getPanelLayout()
function getCursorPos()
function setCursorPos(cursor)
function clearCursorPos()
function getSelection()			useful for other scripts.
function setSelectionStart(pos)
function setSelectionEnd(pos)
function clearSelection()
function getSelectionRange(p1, p2)	clever use of math.min/math.max, I should emulate.

Viewport = defclass(Viewport)
function Viewport.get(layout)
function Viewport:resize(layout)
function Viewport:set()
function Viewport:getPos()
function Viewport:getSize()
function Viewport:clip(x,y,z)
function Viewport:isVisibleXY(target,gap)
function Viewport:isVisible(target,gap)
function Viewport:tileToScreen(coord)
function Viewport:getCenter()
function Viewport:centerOn(target)
function Viewport:scrollTo(target,gap)
function Viewport:reveal(target,gap,max_scroll,scroll_gap,scroll_z)

MOVEMENT_KEYS	obsolete ?
function get_movement_delta(key, delta, big_step)	uses MOVEMENT_KEYS

HOTKEY_KEYS
function get_hotkey_target(key)		these are the builtin hotkeys F1-8, SF1-8.
function getMapKey(keys)
function Viewport:scrollByKey(key)


DwarfOverlay = defclass(DwarfOverlay, gui.Screen)
function DwarfOverlay:getViewport(old_vp)
function DwarfOverlay:moveCursorTo(cursor,viewport,gap)
function DwarfOverlay:zoomViewportTo(target, viewport, gap)
function DwarfOverlay:selectBuilding(building,cursor,viewport,gap)
function DwarfOverlay:propagateMoveKeys(keys)
function DwarfOverlay:simulateViewScroll(keys, anchor, no_clip_cursor)
function DwarfOverlay:simulateCursorMovement(keys, anchor)
function DwarfOverlay:onAboutToShow(parent)
function renderMapOverlay(get_overlay_pen_fn, bounds_rect)	has a documentation comment block.

--]=]

--[==[  UNIT-INFO-VIEWER

 --@xodule = true

local gui = require('gui')
local widgets = require('gui.widgets')

local skills_progress = reqscript('internal/unit-info-viewer/skills-progress')

--------------------------------------------------
---------------------- Time ----------------------
--------------------------------------------------
local TU_PER_DAY = 1200
--[[
if advmode then TU_PER_DAY = 86400 ? or only for cur_year_tick?
advmod_TU / 72 = ticks
--]]
local TU_PER_MONTH = TU_PER_DAY * 28
local TU_PER_YEAR = TU_PER_MONTH * 12

local MONTHS = {
    'Granite',
    'Slate',
    'Felsite',
    'Hematite',
    'Malachite',
    'Galena',
    'Limestone',
    'Sandstone',
    'Timber',
    'Moonstone',
    'Opal',
    'Obsidian',
}
Time = defclass(Time)
function Time:init(args)
    self.year = args.year or 0
    self.ticks = args.ticks or 0
end

function Time:getDays() -- >>float<< Days as age (including years)
    return self.year * 336 + (self.ticks / TU_PER_DAY)
end

function Time:getMonths() -- >>int<< Months as age (not including years)
    return self.ticks // TU_PER_MONTH
end

function Time:getMonthStr() -- Month as date
    return MONTHS[self:getMonths() + 1] or 'error'
end

function Time:getDayStr() -- Day as date
    local d = ((self.ticks % TU_PER_MONTH) // TU_PER_DAY) + 1
    if d == 11 or d == 12 or d == 13 then
        d = tostring(d) .. 'th'
    elseif d % 10 == 1 then
        d = tostring(d) .. 'st'
    elseif d % 10 == 2 then
        d = tostring(d) .. 'nd'
    elseif d % 10 == 3 then
        d = tostring(d) .. 'rd'
    else
        d = tostring(d) .. 'th'
    end
    return d
end

--function Time:__add()
--end
function Time:__sub(other)
    if self.ticks < other.ticks then
        return Time{year=(self.year-other.year-1), ticks=(TU_PER_YEAR+self.ticks-other.ticks)}
    else
        return Time{year=(self.year-other.year), ticks=(self.ticks-other.ticks)}
    end
end

--------------------------------------------------
--------------------------------------------------

-- used in getting race/caste description strings
local PLURAL = 1

local PRONOUNS = {
    [df.pronoun_type.she] = 'She',
    [df.pronoun_type.he] = 'He',
    [df.pronoun_type.it] = 'It',
}

local function get_pronoun(unit)
    return PRONOUNS[unit.sex] or 'It'
end

local GHOST_TYPES = {
    [0] = 'A murderous ghost.',
    'A sadistic ghost.',
    'A secretive ghost.',
    'An energetic poltergeist.',
    'An angry ghost.',
    'A violent ghost.',
    'A moaning spirit returned from the dead.  It will generally trouble one unfortunate at a time.',
    'A howling spirit.  The ceaseless noise is making sleep difficult.',
    'A troublesome poltergeist.',
    'A restless haunt, generally troubling past acquaintances and relatives.',
    'A forlorn haunt, seeking out known locations or drifting around the place of death.',
}

local function get_ghost_type(unit)
    return GHOST_TYPES[unit.ghost_info.type] or 'A mysterious ghost.'
end

-- non-local since it is used by deathcause
DEATH_TYPES = {
    [0] = ' died of old age',                 -- OLD_AGE
    ' starved to death',                      -- HUNGER
    ' died of dehydration',                   -- THIRST
    ' was shot and killed',                   -- SHOT
    ' bled to death',                         -- BLEED
    ' drowned',                               -- DROWN
    ' suffocated',                            -- SUFFOCATE
    ' was struck down',                       -- STRUCK_DOWN
    ' was scuttled',                          -- SCUTTLE
    " didn't survive a collision",            -- COLLISION
    ' took a magma bath',                     -- MAGMA
    ' took a magma shower',                   -- MAGMA_MIST
    ' was incinerated by dragon fire',        -- DRAGONFIRE
    ' was killed by fire',                    -- FIRE
    ' experienced death by SCALD',            -- SCALD
    ' was crushed by cavein',                 -- CAVEIN
    ' was smashed by a drawbridge',           -- DRAWBRIDGE
    ' was killed by falling rocks',           -- FALLING_ROCKS
    ' experienced death by CHASM',            -- CHASM
    ' experienced death by CAGE',             -- CAGE
    ' was murdered',                          -- MURDER
    ' was killed by a trap',                  -- TRAP
    ' vanished',                              -- VANISH
    ' experienced death by QUIT',             -- QUIT
    ' experienced death by ABANDON',          -- ABANDON
    ' suffered heat stroke',                  -- HEAT
    ' died of hypothermia',                   -- COLD
    ' experienced death by SPIKE',            -- SPIKE
    ' experienced death by ENCASE_LAVA',      -- ENCASE_LAVA
    ' experienced death by ENCASE_MAGMA',     -- ENCASE_MAGMA
    ' was preserved in ice',                  -- ENCASE_ICE
    ' became headless',                       -- BEHEAD
    ' was crucified',                         -- CRUCIFY
    ' experienced death by BURY_ALIVE',       -- BURY_ALIVE
    ' experienced death by DROWN_ALT',        -- DROWN_ALT
    ' experienced death by BURN_ALIVE',       -- BURN_ALIVE
    ' experienced death by FEED_TO_BEASTS',   -- FEED_TO_BEASTS
    ' experienced death by HACK_TO_PIECES',   -- HACK_TO_PIECES
    ' choked on air',                         -- LEAVE_OUT_IN_AIR
    ' experienced death by BOIL',             -- BOIL
    ' melted',                                -- MELT
    ' experienced death by CONDENSE',         -- CONDENSE
    ' experienced death by SOLIDIFY',         -- SOLIDIFY
    ' succumbed to infection',                -- INFECTION
    "'s ghost was put to rest with a memorial", -- MEMORIALIZE
    ' scared to death',                       -- SCARE
    ' experienced death by DARKNESS',         -- DARKNESS
    ' experienced death by COLLAPSE',         -- COLLAPSE
    ' was drained of blood',                  -- DRAIN_BLOOD
    ' was slaughtered',                       -- SLAUGHTER
    ' became roadkill',                       -- VEHICLE
    ' killed by a falling object',            -- FALLING_OBJECT
}

local function get_death_type(death_cause)
    return DEATH_TYPES[death_cause] or ' died of unknown causes'
end

local function get_creature_data(unit)
    return df.global.world.raws.creatures.all[unit.race]
end

local function get_name_chunk(unit)
    return {
        text=dfhack.units.getReadableName(unit),
        pen=dfhack.units.getProfessionColor(unit)
    }
end

local function get_translated_name_chunk(unit)
    local tname = dfhack.translation.translateName(dfhack.units.getVisibleName(unit), true)
    if #tname == 0 then return '' end
    return ('"%s"'):format(tname)
end

local function get_description_chunk(unit)
    local desc = dfhack.units.getCasteRaw(unit).description
    if #desc == 0 then return end
    return {text=desc, pen=COLOR_WHITE}
end

-- dead-dead not undead-dead
local function get_death_event(unit)
    if not dfhack.units.isKilled(unit) or unit.hist_figure_id == -1 then return end
    local events = df.global.world.history.events2
    for idx = #events - 1, 0, -1 do
        local e = events[idx]
        if df.history_event_hist_figure_diedst:is_instance(e) and e.victim_hf == unit.hist_figure_id then
            return e
        end
    end
end

-- if undead/ghostly dead or dead-dead
local function get_death_incident(unit)
    if unit.counters.death_id > -1 then
        return df.global.world.incidents.all[unit.counters.death_id]
    end
end

local function get_age_chunk(unit)
    if not dfhack.units.isAlive(unit) then return end

    local ident = dfhack.units.getIdentity(unit)
    local birth_date = ident and Time{year=ident.birth_year, ticks=ident.birth_second} or
        Time{year=unit.birth_year, ticks=unit.birth_time}

    local death_date
    local event = get_death_event(unit)
    if event then
        death_date = Time{year=e.year, ticks=e.seconds}
    end
    local incident = get_death_incident(unit)
    if not death_date and incident then
        death_date = Time{year=incident.event_year, ticks=incident.event_time}
    end

    local age
    if death_date then
        age = death_date - birth_date
    else
        local cur_date = Time{year=df.global.cur_year, ticks=df.global.cur_year_tick}
        age = cur_date - birth_date
    end

    local age_str
    if age.year > 1 then
        age_str = tostring(age.year) .. ' years old'
    elseif age.year > 0 then
        age_str = '1 year old'
    else
        local age_m = age:getMonths()
        if age_m > 1 then
            age_str = tostring(age_m) .. ' months old'
        elseif age_m > 0 then
            age_str = '1 month old'
        else
            age_str = 'a newborn'
        end
    end

    local blurb = ('%s is %s, born'):format(get_pronoun(unit), age_str)

    if birth_date.year < 0 then
        blurb = blurb .. ' before the dawn of time.'
    elseif birth_date.ticks < 0 then
        blurb = ('%s in the year %d.'):format(blurb, birth_date.year)
    else
        blurb = ('%s on the %s of %s in the year %d.'):format(blurb,
            birth_date:getDayStr(), birth_date:getMonthStr(), birth_date.year)
    end

    return {text=blurb, pen=COLOR_YELLOW}
end

local function get_max_age_chunk(unit)
    if not dfhack.units.isAlive(unit) then return end
    local caste = dfhack.units.getCasteRaw(unit)
    local blurb
    if caste.misc.maxage_min == -1 then
        blurb = ' only die of unnatural causes.'
    else
        local avg_age = math.floor((caste.misc.maxage_max + caste.misc.maxage_min) // 2)
        if avg_age == 0 then
            blurb = ' usually die at a very young age.'
        elseif avg_age == 1 then
            blurb = ' live about 1 year.'
        else
            blurb = ' live about ' .. tostring(avg_age) .. ' years.'
        end
    end
    blurb = caste.caste_name[PLURAL]:gsub("^%l", string.upper) .. blurb
    return {text=blurb, pen=COLOR_DARKGREY}
end

local function get_ghostly_chunk(unit)
    if not dfhack.units.isGhost(unit) then return end
    -- TODO: Arose in curse_year curse_time
    local blurb = get_ghost_type(unit) ..
        " This spirit has not been properly memorialized or buried."
    return {text=blurb, pen=COLOR_LIGHTMAGENTA}
end

local function get_dead_str(unit)
    local incident = get_death_incident(unit)
    if incident and incident.missing then
        return ' is missing.', COLOR_WHITE
    end

    local event = get_death_event(unit)
    if event then
        --str = "The Caste_name Unit_Name died in year #{e.year}"
        --str << " (cause: #{e.death_cause.to_s.downcase}),"
        --str << " killed by the #{e.slayer_race_tg.name[0]} #{e.slayer_hf_tg.name}" if e.slayer_hf != -1
        --str << " using a #{df.world.raws.itemdefs.weapons[e.weapon.item_subtype].name}" if e.weapon.item_type == :WEAPON
        --str << ", shot by a #{df.world.raws.itemdefs.weapons[e.weapon.bow_item_subtype].name}" if e.weapon.bow_item_type == :WEAPON
        return get_death_type(event.death_cause) .. PERIOD, COLOR_MAGENTA
    elseif incident then
        --str = "The #{u.race_tg.name[0]}"
        --str << " #{u.name}" if u.name.has_name
        --str << " died"
        --str << " in year #{incident.event_year}" if incident
        --str << " (cause: #{u.counters.death_cause.to_s.downcase})," if u.counters.death_cause != -1
        --str << " killed by the #{killer.race_tg.name[0]} #{killer.name}" if killer
        return get_death_type(incident.death_cause) .. PERIOD, COLOR_MAGENTA
    elseif dfhack.units.isMarkedForSlaughter(unit) and dfhack.units.isKilled(unit) then
        return ' was slaughtered.', COLOR_MAGENTA
    elseif dfhack.units.isUndead(unit) then
        return ' is undead.', COLOR_GREY
    else
        return ' is dead.', COLOR_MAGENTA
    end
end

local function get_dead_chunk(unit)
    if dfhack.units.isAlive(unit) then return end
    local str, pen = get_dead_str(unit)
    return {text=dfhack.units.getReadableName(unit)..str, pen=pen}
end

-- the metrics of the universe
local ELEPHANT_SIZE = 500000
local DWARF_SIZE = 6000
local CAT_SIZE = 500

local function get_conceivable_comparison(unit)
    --[[ the objective here is to get a (resaonably) small number to help concieve
    how large a thing is. "83 dwarves" doesn't really help convey the size of an
    elephant much better than 5m cc, so at certain breakpoints we will use
    different animals --]]
    local size = unit.body.size_info.size_cur
    local comparison_name, comparison_name_plural, comparison_size
    if size > DWARF_SIZE*20 and get_creature_data(unit).creature_id ~= "ELEPHANT" then
        comparison_name, comparison_name_plural, comparison_size = 'elephant', 'elephants', ELEPHANT_SIZE
    elseif size <= DWARF_SIZE*0.25 and get_creature_data(unit).creature_id ~= "CAT" then
        comparison_name, comparison_name_plural, comparison_size = 'cat', 'cats', CAT_SIZE
    else
        comparison_name, comparison_name_plural, comparison_size = 'dwarf', 'dwarves', DWARF_SIZE
    end
    local ratio = size / comparison_size
    if ratio == 1 then
        return ('1 average %s'):format(comparison_name)
    end
    for precision=1,4 do
        if ratio >= 1/(10^precision) then
            return ('%%.%df average %%s'):format(precision):format(ratio, comparison_name_plural)
        end
    end
    return string.format('a miniscule part of an %s', comparison_name)
end

local function get_size_compared_to_median(unit)
    local size_modifier = unit.appearance.size_modifier
    if size_modifier >= 110 then
        return "larger than average"
    elseif size_modifier <= 90 then
        return "smaller than average"
    else
        return "about average"
    end
end

local function get_body_chunk(unit)
    local blurb = ('%s weighs about as much as %s'):format(get_pronoun(unit), get_conceivable_comparison(unit))
    return {text=blurb, pen=COLOR_LIGHTBLUE}
end

local function format_size_in_cc(unit)
    -- internal measure is cubic centimeters divided by 10
    local cc = unit.body.size_info.size_cur * 10
    return dfhack.formatInt(cc)
end

local function get_average_size(unit)
    local blurb = ('%s is %s cc, which is %s in size.')
        :format(get_pronoun(unit), format_size_in_cc(unit), get_size_compared_to_median(unit))
    return{text=blurb, pen=COLOR_LIGHTCYAN}
end

local function get_grazer_chunk(unit)
    if not dfhack.units.isGrazer(unit) then return end
    local caste = dfhack.units.getCasteRaw(unit)
    local blurb = 'Grazing satisfies ' .. tostring(caste.misc.grazer) .. ' units of hunger.'
    return {text=blurb, pen=COLOR_LIGHTGREEN}
end

local function get_milkable_chunk(unit)
    if not dfhack.units.isAlive(unit) or not dfhack.units.isMilkable(unit) then return end
    if not dfhack.units.isAnimal(unit) then return end
    local caste = dfhack.units.getCasteRaw(unit)
    local milk = dfhack.matinfo.decode(caste.extracts.milkable_mat, caste.extracts.milkable_matidx)
    if not milk then return end
    local days, seconds = math.modf(caste.misc.milkable / TU_PER_DAY)
    local blurb = (seconds > 0) and (tostring(days) .. ' to ' .. tostring(days + 1)) or tostring(days)
    if dfhack.units.isAdult(unit) then
        blurb = ('%s secretes %s every %s days.'):format(get_pronoun(unit), milk:toString(), blurb)
    else
        blurb = ('%s secrete %s every %s days.'):format(caste.caste_name[PLURAL], milk:toString(), blurb)
    end
    return {text=blurb, pen=COLOR_LIGHTCYAN}
end

local function get_shearable_chunk(unit)
    if not dfhack.units.isAlive(unit) then return end
    if not dfhack.units.isAnimal(unit) then return end
    local caste = dfhack.units.getCasteRaw(unit)
    local mat_types = caste.body_info.materials.mat_type
    local mat_idxs = caste.body_info.materials.mat_index
    for idx, mat_type in ipairs(mat_types) do
        local mat_info = dfhack.matinfo.decode(mat_type, mat_idxs[idx])
        if mat_info and mat_info.material.flags.YARN then
            local blurb
            if dfhack.units.isAdult(unit) then
                blurb = ('%s produces %s.'):format(get_pronoun(unit), mat_info:toString())
            else
                blurb = ('%s produce %s.'):format(caste.caste_name[PLURAL], mat_info:toString())
            end
            return {text=blurb, pen=COLOR_BROWN}
        end
    end
end

local function get_egg_layer_chunk(unit)
    if not dfhack.units.isAlive(unit) or not dfhack.units.isEggLayer(unit) then return end
    local caste = dfhack.units.getCasteRaw(unit)
    local clutch = (caste.misc.clutch_size_max + caste.misc.clutch_size_min) // 2
    local blurb = ('She lays clutches of about %d egg%s.'):format(clutch, clutch == 1 and '' or 's')
    return {text=blurb, pen=COLOR_GREEN}
end

----------------------------
-- UnitInfo
--

UnitInfo = defclass(UnitInfo, widgets.Window)
UnitInfo.ATTRS {
    frame_title='Unit info',
    frame={w=50, h=25},
    resizable=true,
    resize_min={w=40, h=10},
}

function UnitInfo:init()
    self.unit_id = nil

    self:addviews{
        widgets.Label{
            view_id='nameprof',
            frame={t=0, l=0},
        },
        widgets.Label{
            view_id='translated_name',
            frame={t=1, l=0},
        },
        widgets.Label{
            view_id='chunks',
            frame={t=3, l=0, b=0, r=0},
            auto_height=false,
            text='Please select a unit.',
        },
    }
end

local function add_chunk(chunks, chunk, width)
    if not chunk then return end
    if type(chunk) == 'string' then
        table.insert(chunks, chunk:wrap(width))
        table.insert(chunks, NEWLINE)
    else
        for _, line in ipairs(chunk.text:wrap(width):split(NEWLINE)) do
            local newchunk = copyall(chunk)
            newchunk.text = line
            table.insert(chunks, newchunk)
            table.insert(chunks, NEWLINE)
        end
    end
    table.insert(chunks, NEWLINE)
end

function UnitInfo:refresh(unit, width)
    self.unit_id = unit.id
    self.subviews.nameprof:setText{get_name_chunk(unit)}
    self.subviews.translated_name:setText{get_translated_name_chunk(unit)}

    local chunks = {}
    add_chunk(chunks, get_description_chunk(unit), width)
    add_chunk(chunks, get_age_chunk(unit), width)
    add_chunk(chunks, get_max_age_chunk(unit), width)
    add_chunk(chunks, get_ghostly_chunk(unit), width)
    add_chunk(chunks, get_dead_chunk(unit), width)
    add_chunk(chunks, get_average_size(unit), width)
    if get_creature_data(unit).creature_id ~= "DWARF" then
        add_chunk(chunks, get_body_chunk(unit), width)
    end
    add_chunk(chunks, get_grazer_chunk(unit), width)
    add_chunk(chunks, get_milkable_chunk(unit), width)
    add_chunk(chunks, get_shearable_chunk(unit), width)
    add_chunk(chunks, get_egg_layer_chunk(unit), width)
    self.subviews.chunks:setText(chunks)
end

function UnitInfo:check_refresh(force)
    local unit = dfhack.gui.getSelectedUnit(true)
    if unit and (force or unit.id ~= self.unit_id) then
        self:refresh(unit, self.frame_body.width-3)
    end
end

function UnitInfo:postComputeFrame()
    -- re-wrap
    self:check_refresh(true)
end

function UnitInfo:render(dc)
    self:check_refresh()
    UnitInfo.super.render(self, dc)
end

----------------------------
-- UnitInfoScreen
--

UnitInfoScreen = defclass(UnitInfoScreen, gui.ZScreen)
UnitInfoScreen.ATTRS {
    focus_path='unit-info-viewer',
}

function UnitInfoScreen:init()
    self:addviews{UnitInfo{}}
end

function UnitInfoScreen:onDismiss()
    view = nil
end

OVERLAY_WIDGETS = {
    skillprogress=skills_progress.SkillProgressOverlay,
}

if dfhack_flags.module then
    return
end

view = view and view:raise() or UnitInfoScreen{}:show()

--]==]

--[=[   SKILLS-PROGRESS

--@ xodule=true

local utils = require("utils")
local widgets = require('gui.widgets')
local overlay = require('plugins.overlay')

local view_sheets = df.global.game.main_interface.view_sheets

local function get_skill(id, unit)
    if not unit then return nil end
    local soul = unit.status.current_soul
    if not soul then return nil end
    return utils.binsearch(
        soul.skills,					-- okay, so THIS is grabbing the raw data from the
        view_sheets.unit_skill[id],			-- actual unit instead of the view_sheet data.
        "id"
    )
end

SkillProgressOverlay=defclass(SkillProgressOverlay, overlay.OverlayWidget)
SkillProgressOverlay.ATTRS {
    desc="Display progress bars for learning skills on unit viewsheets.",
    default_pos={x=-43,y=18},				-- what does a negative x mean?  what is this relative to?
    default_enabled=true,
    viewscreens= {
        'dwarfmode/ViewSheets/UNIT/Skills/Labor',
        'dwarfmode/ViewSheets/UNIT/Skills/Combat',
        'dwarfmode/ViewSheets/UNIT/Skills/Social',
        'dwarfmode/ViewSheets/UNIT/Skills/Other',
        'dungeonmode/ViewSheets/UNIT/Skills/Labor',
        'dungeonmode/ViewSheets/UNIT/Skills/Combat',
        'dungeonmode/ViewSheets/UNIT/Skills/Social',
        'dungeonmode/ViewSheets/UNIT/Skills/Other',

	-- so for the still we would want:
	-- dwarfmode/ViewSheets/BUILDING/Workshop/Still/Tasks

    },
    frame={w=54, h=20},
}

function SkillProgressOverlay:init()
    self:addviews{
        widgets.Label{					-- not very relevant
            view_id='annotations',
            frame={t=0, r=0, w=16, b=0},
            auto_height=false,
            text='',
            text_pen=COLOR_GRAY,
        },
        widgets.BannerPanel{				-- not very relevant
            frame={b=0, l=1, h=1},
            subviews={
                widgets.ToggleHotkeyLabel{		-- not very relevant
                    frame={l=1, w=25},
                    label='Progress Bar:',
                    key='CUSTOM_CTRL_B',
                    options={
                        {label='No', value=false, pen=COLOR_WHITE},
                        {label='Yes', value=true, pen=COLOR_YELLOW},
                    },
                    view_id='toggle_progress',
                    initial_option=true
                },
                widgets.ToggleHotkeyLabel{		-- not very relevant
                    frame={l=29, w=23},
                    label='Experience:',
                    key='CUSTOM_CTRL_E',
                    options={
                        {label='No', value=false, pen=COLOR_WHITE},
                        {label='Yes', value=true, pen=COLOR_YELLOW},
                    },
                    view_id='toggle_experience',
                    initial_option=true
                },
            },
        },
    }
end

function SkillProgressOverlay:preUpdateLayout(parent_rect)	-- Where does parent_rect come from?  API?
    self.frame.h = parent_rect.height - 21			-- mmm... -21 may restrict this overlay to 
								-- the skills section of the viewsheet tabs.
								-- it's about right to do that.
end

local function get_threshold(lvl)
    return 500 + lvl * 100
end

function SkillProgressOverlay:onRenderFrame(dc, rect)		-- so I guess we only get here for our viewscreens
    local annotations = {}
    local current_unit = df.unit.find(view_sheets.active_id)
    if current_unit and current_unit.portrait_texpos > 0 then
        -- If a portrait is present, displace the bars down 2 tiles
        table.insert(annotations, "\n\n")
    end

    local progress_bar_needed = not dfhack.world.isAdventureMode() or not dfhack.screen.inGraphicsMode()
    self.subviews.toggle_progress.visible = progress_bar_needed
    local progress_bar = self.subviews.toggle_progress:getOptionValue() and progress_bar_needed
    local experience = self.subviews.toggle_experience:getOptionValue()

    local margin = self.subviews.annotations.frame.w
    local num_elems = self.frame.h // 3 - 1			-- I think the -1 is an off-by-1 error.
    local start = math.min(view_sheets.scroll_position_unit_skill,   -- scrolling math
        math.max(0,#view_sheets.unit_skill-num_elems))
    local max_elem = math.min(#view_sheets.unit_skill-1,	-- more scrolling math
        view_sheets.scroll_position_unit_skill+num_elems-1)
    for idx = start, max_elem do
        local skill = get_skill(idx, current_unit)
        if not skill then
            table.insert(annotations, "\n\n\n\n")		-- skip to next data? why 4? I would think 3.
            goto continue					-- and abort.  so this is just for safety?
        end
        local xp_threshold = get_threshold(skill.rating)
        if experience then
            if not progress_bar then
                table.insert(annotations, NEWLINE)		-- use the middle instead of the top line? YES.
            end
            local level_color = COLOR_WHITE
            local rating_val = math.max(0, skill.rating - skill.rusty)
            if skill.rusty > 0 then
                level_color = COLOR_LIGHTRED
            elseif skill.rating >= df.skill_rating.Legendary then
                level_color = COLOR_LIGHTCYAN
            end
            table.insert(annotations, {
                text=('Lv%s'):format(rating_val >= 100 and '++' or tostring(rating_val)),
                width=7,					-- so from observation, despite the width, 
								-- this only overwrites the 4 characters.
                pen=level_color,
            })
            table.insert(annotations, {
                text=('%4d/%4d'):format(skill.experience, xp_threshold),
                pen=level_color,
                width=9,
                rjustify=true,					-- don't think this is needed.
            })
        end

        -- 3rd line (last)

        -- Progress Bar
        if progress_bar then
            table.insert(annotations, NEWLINE)
            local percentage = skill.experience / xp_threshold
            local barstop = math.floor((margin * percentage) + 0.5)
            for i = 0, margin-1 do
                local color = COLOR_LIGHTCYAN
                local char = 219
                -- start with the filled middle progress bar
                local tex_idx = 1					-- graphics I guess? index into .load_bar_texpos[]
                -- at the beginning, use the left rounded corner
                if i == 0 then
                    tex_idx = 0
                end
                -- at the end, use the right rounded corner
                if i == margin-1 then
                    tex_idx = 2
                end
                if i >= barstop then
                    -- offset it to the hollow graphic
                    tex_idx = tex_idx + 3				-- the rest of the line I guess.
                    color = COLOR_DARKGRAY
                    char = 177
                end
                table.insert(annotations, { width = 1, tile={tile=df.global.init.load_bar_texpos[tex_idx], ch=char, fg=color}})
            end
        end								-- probably want a newline here?
        -- End!
        table.insert(annotations, NEWLINE)				-- why bother?
        table.insert(annotations, NEWLINE)

        ::continue::
    end
    self.subviews.annotations:setText(annotations)

    SkillProgressOverlay.super.onRenderFrame(self, dc, rect)
end



--]=]

--[==[

interpreting DF's view_sheets for STILL building.

main_interface.view_sheets:

open		true, not relevant because we will only trigger on the right view_sheet.
context		0, not relevant because we will only trigger on the right view_sheet.
active_sheet	2 BUILDING, not relevant because we will only trigger on the right view_sheet.
active_id	the still's building id, not relevant
viewing_bldid	the still's building id, not relevant
viewing_x,y,z	where was clicked, not relevant
scroll*		not relevant, probably for unit.
tab		not relevant?
tab_id		not relevant if tab is not relevant.
active_sub_tab	relevant, only draw if 0
		but this will be filtered by triggering on
		dwarfmode/ViewSheets/BUILDING/Workshop/Still/Tasks

trait 		not relevant
(...)		all not relevant
*thought*	not relevant
*item		not relevant

scroll_position_building_job  VERY RELEVANT, start position for our element drawing.
scrolling_building_job    MAYBE relevant, why is this false even when we are scrolling?

building_job_filter_str   not relevant
entering_building_job_filter not relevant
*cage*		not relevant
*displayed*	not relevant
*lever*		not relevant
*entering*	not relevant
*work_order*	not relevant, this seems to be for already-existing work orders.
*gen_work*	not relevant
*wq_number*	not relevant, dunno
(...)		all not relevant

the possible job list wasn't anywhere in there.

main_interface.building:

button[]	VERY RELEVANT, all the possible still jobs.
		if #button == 0, we are NOT DISPLAYING the possible jobs list.
press_button[]	VERY RELEVANT, also has all the possible still jobs.
		if #press_button == 0, we are NOT DISPLAYING the possible jobs list.
filtered_button[]  EXTREMELY RELEVANT, has the displayed (filtered) still jobs.
		we will probably walk this.
		this still contains (garbage) data when not displaying the possible jobs list.
		DO NOT inspect this when the data might not be valid.  immediate crash.

selected	probably not relevant, I don't see how it ever becomes non-zero.
(...)		remaining stuff not relevant.



NOTE: when entering a work order, the main_interface.building seems to not be active.
	(base on #button being 0.)

Ah ha, it's in main_interface.create_work_order,
triggered by dwarfmode/ViewSheets/BUILDING/Workshop/Still/WorkOrders
so this will be a different code path.
the build-our-data-string stuff will be shared.

main_interface.create_work_order:
open		true, RELEVANT, only do display overrides if this is true.
forced_bld_id	the still building id, not relevant
jminfo_master	not relevant?
building[]	RELEVANT, should have 1 element.
    .type	not relevant?
    .subtype	not relevant?
    .custom_id	not relevant?
    .jminfo	RELEVANT, contains the (non-filtered) list of possible still jobs.
    .name	not relevant.
scroll_position_building  not relevant, we will only have one
scrolling_building  not relevant
selected_building_index  don't know
scroll_position_job  RELEVANT !  position in the (filtered) job list to start at.
scrolling_job	not relevant?  when is this not false?  (if forced true, it changes back to false.)
job_filter	probably not relevant, but I haven't found the filtered job list.
entering_job_filter  not relevant


--]==]