--- To use this module, load it in this nonstandard way:
--- `local dprintf = reqscript("dprintf").dprintf`
--- `local debugging = true`
--- or
--- `local dprintf = reqscript("dprintf").Dprintf`
---
--- If you are not sure if the dprintf module is available, load it like this:
--- `local dprintf = pcall(reqscript,"dprintf") and reqscript("dprintf").dprintf or function()end`
--- `local debugging = true`

--@module = true


-- local _ENV = mkmodule('dprintf')  -- testing require module
-- notes on making this a true require-able module:
--   it works, but ONLY if the module file is put into hack/lua/ or the DF directory.
--   not tested: putting it in a scripts_modactive directory.  error message:
--      [lua]# ~require("dprintf")
--      (interactive):1: module 'dprintf' not found:
--          no field package.preload['dprintf']
--          no file 'C:\GAMES\DWARF FORTRESS\Z5308\hack\lua\dprintf.lua'
--          no file 'C:\GAMES\DWARF FORTRESS\Z5308\hack\lua\dprintf\init.lua'
--          no file '.\dprintf.lua'
--          no file 'C:\GAMES\DWARF FORTRESS\Z5308\dprintf.dll'
--          no file '.\dprintf.dll'
-- what DOES work is adding the path to `package.path` .
--   not tested: whether that affects everything or just the require'ing script.

local function weak_key_table_factory()
    return setmetatable( {}, { __mode = "k", } )
end


-- these need to be weak-key tables so that they do not prevent GC of otherwise-discarded functions.
script_names_by_function      = script_names_by_function      or weak_key_table_factory()
debugging_setting_by_function = debugging_setting_by_function or weak_key_table_factory()


---@param level integer?  # level to start at.  0=getinfo, 1=this function, 2=caller, 3=caller's caller.  Default is 2.
function dump_all_vars_on_stack(level)
    local P = dfhack.printerr
    local function Pf(format, ...) P(string.format(format, ...)); end
    level = level or 2
    repeat
        local info = debug.getinfo(level)
        if not info then break; end
        if info.func == dfhack.run_script_with_env then info.name = "dfhack.run_script_with_env"; end
        info.namewhat = (type(info.namewhat) == "strring" and info.namewhat ~= "" and info.namewhat)
            or "UNKNOWN"
        info.name = (type(info.name) == "string" and info.name ~= "" and info.name)
            or (info.istailcall and "(tail call)" or "(no function)")
        Pf("======== level %d ========", level)
        Pf("%s %s %s %s, %d upvals %d, params%s%s", info.short_src:sub(-31), info.what,
                info.namewhat, info.name, info.nups, info.nparams,
                info.isvararg and ", VARARG" or "", info.istailcall and ", TAILCALL" or "")
        if info.nups > 0 then
            P("    --- upvals ---")
            for i = 1, info.nups do
                local name, val = debug.getupvalue(info.func, i)
                Pf("    %-20s    %s", name, val)
            end
        end
        if info.nparams > 0 then
            P("    --- params ---")
            for i = 1, info.nparams do
                local name, val = debug.getlocal(level, i)  -- name can be nil
                Pf("%-3d %-20s  %s", i, name, val)
            end
        end
        local i = info.nparams + 1
        repeat
            local name, val = debug.getlocal(level, i)
            if name then
                if i == info.nparams + 1 then
                    P("    --- locals ---")
                end
                Pf("%-3d %-20s  %s", i, name, val)
            end
            i = i + 1
        until not name
        -- TODO varargs
        level = level + 1
    until false
    P(string.rep('-',24))
end


--- This function searches the call stack to find a variable named "debugging", and returns true
---   if and only if the variable is true.  (It must be boolean true, not just truthy.)
---   If no "debugging" variable is found, it returns false.
---@return boolean
local function find_debugging_var_setting()
    local level = 3  -- 0=getinfo, 1=this func, 2=dprintf, 3=dprintf's caller
    repeat
        local info = debug.getinfo(level, "uf")
        -- ran out of stack?  fail.
        -- (this occurs on callbacks if you don't pull in _ENV by using a global.)
        if info == nil then return false; end
        -- ran into the standard spawn-script function?  fail.
        if info.func == dfhack.run_script_with_env then return false; end
        -- search all parameters and locals for debugging; it can be in any slot.
        local i = 1
        repeat
            local name, val = debug.getlocal(level, i)
            if name == "debugging" then
                --print("dprintf note: found local debugging at", level, i, (val == true))
                return (val == true)
            end
            i = i + 1
        until name == nil
        -- search all parameters and locals for _ENV; it can be in any slot.
        i = 1
        repeat
            local name, val = debug.getlocal(level, i)
            if name == "_ENV" and type(val) == "table"
                and val["dfhack_flags"] ~= nil and val["debugging"] ~= nil
            then
                --print("dprintf note: found local _ENV.debugging at", level, i, (val["debugging"] == true))
                return(val["debugging"] == true)
            end
            i = i + 1
        until name == nil
        -- search all upvalues for _ENV; it can be in any upvalue slot.
        for i = 1,info.nups do
            local name, val = debug.getupvalue(info.func, i)
            if name == nil then break; end  -- can't happen.
            if name == "_ENV" and type(val) == "table"
                and val["dfhack_flags"] ~= nil and val["debugging"] ~= nil
            then
                --print("dprintf note: found upvalue _ENV.debugging at", level, i, (val["debugging"] == true))
                return(val["debugging"] == true)
            end
        end
        level = level + 1
    until false
    -- NOTREACHED, even in the case of callbacks.
    return false
end


--- dprintf() parameters are the same as string.format() uses.
---
--- dprintf() conditionally prints the given formatted message to the
---   console (in bright cyan), and logs it to the stderr.log file.
--- Treat it as a dfhack.printerr() that can accept arguments.
---
--- dprintf() only outputs if some variable named 'debugging' is true,
---   at any level of the stack.  This variable can be local or global.
---   It must be boolean true, not just some truthy value.
---
--- Unfortunately, even if debugging is not enabled, your script wastes
---   time collecting all of the info that would be printed, to pass in
---   as parameters.  So don't do anything too slow.
---
--- Note: the value of the 'debugging' variable is cached per-function,
---   the first time that a function calls dprintf().
---   Therefore, you can't just arbitrarily toggle it on and off.
--
---@param format string  # as used by string.format()
---@param ... any
function dprintf(format, ...)
    --dump_all_vars_on_stack(3)

    -- get all caller's frame info.
    local info = assert(debug.getinfo(2))  -- 2 is caller's stack frame.
    assert(type(info.func) == "function")

    if debugging_setting_by_function[info.func] == nil then
        debugging_setting_by_function[info.func] = find_debugging_var_setting()
        --print("dprintf note: set cached debugging to", debugging_setting_by_function[info.func])
    else
        --print("dprintf note: found cached debugging", debugging_setting_by_function[info.func])
    end
    if debugging_setting_by_function[info.func] ~= true then
        return
    end

    return Dprintf(format, ...)  -- this ideally should be a tail call.
end


--- Dprintf() parameters are the same as string.format() uses.
---
--- Dprintf() prints the given formatted message to the console
---   (in bright cyan), and logs it to the stderr.log file.
--- Treat it as a dfhack.printerr() that can accept arguments.
--
---@param format string  # as used by string.format()
---@param ... any
function Dprintf(format, ...)
    -- get all caller's frame info.
    local info = assert(debug.getinfo(2))  -- 2 is caller's stack frame.
    assert(type(info) == "table" and type(info.func) == "function",
        "something went wrong with the debug.getinfo call")
    if info.func == dprintf then
        info = debug.getinfo(3)  -- 3 is dprintf's caller's stack frame.
        assert(type(info) == "table" and type(info.func) == "function",
            "something went wrong with the second debug.getinfo call")
    end

    -- Lua 5.3 Reference Manual 3.4.10:
    --   "However, a tail call erases any debug information about the calling function."
    info.name = (type(info.name) == "string" and info.name ~= "" and info.name)
        or (info.istailcall and "(tail call)" or "(no function)")
    info.currentline = math.tointeger(info.currentline) or -1

    -- derive script name from debug.getinfo("S").source, fallback to dfhack.current_script_name()
    script_names_by_function[info.func] = script_names_by_function[info.func]
        or (type(info.source) == "string" and info.source ~= ""
            and info.source:gsub('^.-([^\\/]*)$', '%1'):gsub('%.lua$', '') or nil)
        or dfhack.current_script_name()  -- note: this can return nil, e.g. in callbacks.
        or "NO SCRIPT NAME"

    local message = string.format("%s #%-3s %s(): " .. format,
        script_names_by_function[info.func], tostring(info.currentline), info.name, ...)
    local oldcolor = dfhack.color(COLOR_LIGHTCYAN)
    print(message)
    dfhack.color(oldcolor)
    io.stderr:write(message):write('\n')
end

-- return _ENV  -- testing require module
