-- quick and _very_ dirty start a fight betweeen two fort units.  no guarantee that this will be maintained.
-- https://raw.githubusercontent.com/SilasD/myscripts/refs/heads/master/gladiator.lua
local conflict_level=df.conflict_level.NoQuarter  -- useful: Brawl, Nonlethal, Lethal, NoQuarter
--
u0,u1=(u0 or nil),(u1 or nil);if u0 and u1 then u0,u1=nil,nil;end  -- global, persistent, stateful.
local GSU,DGA,WAA=dfhack.gui.getSelectedUnit,df.global.activity_next_id,df.global.world.activities.all
local function click1()qerror("click on the first unit and rerun this script");end
local function click2()qerror("click on the second unit and rerun this script");end
if not u0 then u0=GSU(true);if not u0 then click1();end;click2();else u1=GSU(true);if not u1 or u1==u0 then u1=nil;click2();end;end
local enemies0={new=true,id=1,conflict_level=conflict_level}  -- id=1 is correct
local side0={new=true,id=0,histfig_ids=((u0.hist_figure_id~=-1)and{u0.hist_figure_id}or{}),unit_ids={u0.id},
 enemies={enemies0},peak_strength=9999,current_strength=9999}
local enemies1={new=true,id=0,conflict_level=conflict_level}  -- id=0 is correct
local side1={new=true,id=1,histfig_ids=((u1.hist_figure_id~=-1)and{u1.hist_figure_id}or{}),unit_ids={u1.id},
 enemies={enemies1},peak_strength=9998,current_strength=9998}
local event={new=df.activity_event_conflictst,event_id=0,activity_id=DGA,parent_event_id=-1,flags={dismissed=false,squad=false},
 sides={side0,side1},next_side_local_id=2,eventcol=-1,inactivity_timer=0,attack_inactivity_timer=0,stop_fort_fights_timer=999999}
local entry={new=df.activity_entry,id=DGA,type=df.activity_entry_type.Conflict,events={event},next_event_id=1,army_controller=-1}
WAA:insert('#',entry)  -- see: DFHack Lua API: Recursive table assignment; it's very cool.
u0.activities:insert('#',DGA);u0.opponent.unit_id=u1.id;u0.opponent.unit_pos:assign(u1.pos);u0.opponent.timer=9999;u0.job.hunt_target=u1
u1.activities:insert('#',DGA);u1.opponent.unit_id=u0.id;u1.opponent.unit_pos:assign(u0.pos);u1.opponent.timer=9999;u1.job.hunt_target=u0
df.global.activity_next_id=DGA+1
qerror(df.conflict_level[conflict_level].." fight started")
