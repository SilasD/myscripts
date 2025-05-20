-- Fix occupancy flags at a given tile

--[====[

fix/tile-occupancy
==================
Clears bad occupancy flags at the selected tile. Useful for getting rid of
phantom "building present" messages. Currently only supports issues with
building and unit occupancy. Requires that a tile is selected with the in-game
cursor (``k``).

Can be used to fix problematic tiles caused by :issue:`1047`.

SWD Hacked to use current designation selection box if active, current layer if not.

]====]

if #{...} > 0 then
    qerror('This script takes no arguments.')
end


-- local _, plotinfo = pcall(function() return df.global.ui; end)
-- if not _ then _, plotinfo = pcall(function() return df.global.plotinfo; end) end


local function xyz2str(x,y,z)
    if not x or not y or not z then qerror('not enough parameters'); end
    x = tonumber(x); y = tonumber(y); z = tonumber(z)
    if not x or not y or not z then qerror('invalid number'); end
    return(("%d,%d,%d"):format(x,y,z))
end


--[[
function findUnit(x, y, z)
    for _, u in pairs(df.global.world.units.active) do
        if u.pos.x == x and u.pos.y == y and u.pos.z == z 
		and u.flags1.inactive == false 
		-- SWD it can happen that .inactive is true, when the unit is immigrating 
		--	or returning from a mission.
		-- SWD or leaving on a mission but not yet removed from .units.all .
		-- SWD TODO did I mean units.active?
	then
            return true
        end
    end
    return false
end
]]

function report(flag, x, y, z)
    print(('Cleared occupancy flag %s at (%s).'):format(flag, xyz2str(x,y,z)))
    changed = true
end


-- it's a table<strpos, true>.  If the key exists, a unit is on that tile.
---@type table<string, boolean>[]
local occupied = {}

for _, u in pairs(df.global.world.units.active) do
    if u.flags1.inactive and not u.flags2.killed then
	print(('Unit %d inactive.'):format(u.id))
    elseif dfhack.units.getGeneralRef(u, df.general_ref_type.CONTAINED_IN_ITEM) ~= nil then
	-- in a cage; do nothing.
    elseif u.pos.x == -30000 then
	print(('Unit %d not on map.'):format(u.id))
    else
	occupied[xyz2str(pos2xyz(u.pos))] = true
    end
end


local changed = false
local startx = 0; local endx = df.global.world.map.x_count-1
local starty = 0; local endy = df.global.world.map.y_count-1
local z = df.global.window_z

if df.global.selection_rect.start_x ~= -30000 then
    startx = df.global.selection_rect.start_x
    starty = df.global.selection_rect.start_y
    endx   = df.global.cursor.x
    endy   = df.global.cursor.y

    if endx < startx then startx, endx = endx, startx; end
    if endy < starty then starty, endy = endy, starty; end
end


for x = startx, endx do
    for y = starty, endy do

	-- TODO cache
	local occ = dfhack.maps.getTileBlock(x, y, z).occupancy[x % 16][y % 16]

	if occ.building ~= df.tile_building_occ.None and not dfhack.buildings.findAtTile(x, y, z) then
            occ.building = df.tile_building_occ.None
	    report('building', x, y, z)
	end

	for _, flag in pairs{'unit', 'unit_grounded'} do
	    if occ[flag] and not occupied[xyz2str(x,y,z)] then
	        occ[flag] = false
       		report(flag, x, y, z)
            end
	end

    end -- y
end -- x
