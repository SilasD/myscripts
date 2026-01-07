
-- TODO bugfix: walk the caller's locals in reverse order, to get the *most recently declared* _ENV
-- TODO bugfix: for *each* table in envs, check if it has a metamethod __index and call it.
-- TODO bugfix: as above, but check if just getting envs[i][k] normally (without rawget) works.
-- TODO syntax change: return _ENV instead of using debug.setlocal to coerce the caller's local _ENV.
-- TODO enhancement: would it work to glom _ENV directly instead of grabbing the caller's local _ENV?
--	with the above syntax change, that would be required anyway.
-- TODO syntax change: if the last item in the parameters is a function/closure, call it in the context of
--	the new _ENV instead of returning _ENV.  (no parameters, curry the parameters if needed.)


-- Implement a Javascript-like 'with' keyword in Lua
-- based on <http://lua-users.org/wiki/WithStatement> implementation "Lua 5.2" "DavidManura"
-- (no copyright was provided with that source code.)
---@param ... table  # tables or df structure types
local function with(...)
    local envs = {...}
    assert(#envs > 0, "error: with() called without any parameters.")
    for i,param in ipairs(envs) do
        assert(type(param) == "table"
            or (type(param) == "userdata" 
                and df.isvalid(param) == "ref"
                and (param._kind == "struct"
                    or param._kind == "container"
                    or param._kind == "bitfield")),
            "error: with() parameter #" .. i .. " is not a table." .. type(param) .. tostring(param._kind))
    end
    local info = debug.getinfo(2, 'u')
    local i = info.nparams + 1
    local _env
    repeat
        local name, val = debug.getlocal(2, i)
	if not name then break; end
        if name == "_ENV" then _env = val; break; end
        i = i + 1
    until false
    assert(_env ~= nil and type(_env) == "table",
        "error: with() did not find caller's local variable _ENV, or it is not a table.\n" ..
        "add 'local _ENV = _ENV' at the start of the function.")
    assert(getmetatable(_env) == debug.getmetatable(_env), "figure out what to do!")
    table.insert(envs, _env)
    local mt = {
        __index = function(t, k)  -- captures upvalue envs[]
            for i, env in ipairs(envs) do
                if type(env) == "table" then
                    local v = rawget(env, k) 
                    if v ~= nil then return v; end
                elseif type(env) == "userdata" then
                    local ok, v = pcall(function(t,k) return t[k];end,env,k)
                    if ok and v ~= nil then return v; end
                else
                    error("error: with() parameter " .. i .. " malformed?")
                end
            end
            local index = (getmetatable(envs[#envs]) or {}).__index
            if type(index) == "table" then return index[k]
            elseif type(index) == "function" then return index(t, k)
            elseif index == nil then return nil
            else error("error: what even is the caller's __index?  " .. type(index) .. tostring(index))
            end
        end
    }
    debug.setlocal(2, i, setmetatable({}, mt))
end

--[[
-- what about the syntax
do
    local _ENV = with(table, table2, table3)
    stuff()
    and
    things()
end
--]]


do
local plant = dfhack.matinfo.find("PLANT:APPLE").plant
do local _ENV = _ENV; with(plant, plant.flags, plant.material[2], plant.material[2].flags)
    print(id, index, name, SAPLING, BIOME_MOUNTAIN, solid_density, material_value, ALCOHOL, SILK, raws[2].value)
end
plant = require('utils').clone(plant, true)  -- coerce plant into a (nested) Lua table
do local _ENV = _ENV; with(plant, plant.flags, plant.material[3], plant.material[3].flags) -- note adjustments for 1-based indexing
    print(id, index, name, SAPLING, BIOME_MOUNTAIN, solid_density, material_value, ALCOHOL, SILK, raws[3].value)
end
local unit = dfhack.gui.getSelectedUnit()
do local _ENV = _ENV; with(dfhack.translation, dfhack.units, unit, unit.flags1, unit.body.physical_attrs)
    print(id, translateName(name), getProfessionName(unit), tame, STRENGTH.value)
end
end

creature_id = -1234

local function lf_leaky()
    assert(creature_id ~= "COW")
end

function gf_leaky()
    assert(creature_id ~= "COW")
end

assert(creature_id ~= "COW")
do
    assert(creature_id ~= "COW")
    local creature_raw = dfhack.matinfo.find("CREATURE:COW:LEATHER").creature
    assert(creature_id ~= "COW")
    lf_leaky()
    gf_leaky()
--    do with(creature_raw)  -- leaks
    do local _ENV = _ENV; with(creature_raw)  -- doesn't leak as long as there isn't a previous declaration of _ENV
        assert(creature_id == "COW")
        lf_leaky()
        gf_leaky()
    end
    assert(creature_id ~= "COW")
    lf_leaky()
    gf_leaky()
end
assert(creature_id ~= "COW")


--[[
local function with(...)
    local envs = {...}
    local info = debug.getinfo(2, 'u')
    local i = info.nparams + 1
    local _env
    repeat
        local name, val = debug.getlocal(2, i)
	if not name then break; end
        if name == "_ENV" then _env = val; break; end
        i = i + 1
    until false
    table.insert(envs, _env)
    local mt = {
        __index = function(t, k)  -- captures upvalue envs[]
            for i, env in ipairs(envs) do
                local v = rawget(env, k) 
                if v ~= nil then return v; end
            end
            local index = (getmetatable(envs[#envs]) or {}).__index
            if type(index) == "table" then return index[k]
            elseif type(index) == "function" then return index(t, k)
            elseif index == nil then return nil
            else error("error: what even is the caller's __index?  " .. type(index) .. index)
            end
        end
    }
    debug.setlocal(2, i, setmetatable({}, mt))
end

--]]
