
local translateName = dfhack.TranslateName or dfhack.translation.translateName

local test1 = {}

for i = 1,10 do
    test1[i] = i*5
end

local test2 = {
    a = 5,
    b = 10,
    c = 15,
    d = 20,
    e = 25,
    f = 30,
    g = 35,
    h = 40,
    i = 45,
    j = 50,
}


local function zzipairsfiltered_next(t, k, cmp)

    print("ipairsfiltered_next parameters: ", t, k, cmp)
    local k2, v
    local i = 1
    while true do
	k2, v = next(t, k)
        print("ipairsfiltered_next iteration ", i, k2, v)

--	if true then break; end
--	if v % 10 == 0 then break; end  -- infinite loop
--	next() is always returning the same thing.
--	okay, try setting k = k2 after the cmp.

	if v % 10 == 0 then print('ipairsfiltered_next match, returning', k2, v); return k2,v; end; k = k2;

        i = i + 1
    end

    print("SHOULDNOTREACH ipairsfiltered_next: returning", k2, v)
    return k2, v
end

local function zipairsfilter(tt, test)
    print("ipairsfilter parameters:", type(tt), tt, type(test), test)


-- @@@ look at df.isvalid(object)
    -- is it a DF type?
    if type(test) == "table" then
	local success, kind = safecall(function() return test._kind; end)
	if success and kind == "class-type" then
print("DF type detected:", kind, "generating a test function.")
	    local testcopy = test
	    test = function(c) print("anon function(c): c = ", c, "type(c) = ", type(c), "c._type = ", c._type, "testcopy = ", testcopy); return (c._type == testcopy); end
	end
    end

    if type(test) ~= "function" then
	qerror("error in ipairsfilter: test is not a function; type(test) = " .. type(test))
    end

    -- implicitly uses 'test' from the outer function.
    local F = function(t, k)

	--print("entering F:", t, k, test)
	local k2, v
	local i = 1
	while true do
	    k2, v = next(t, k)
	    --print("F iteration ", i, k2, v)
	    if k2 == nil then 
		--print('F k2 == nil, returning', k2, v)
		return k2, v
	    end
	    if test(v) then
		--print("F match, returning", k2, v)
		return k2,v
	    end
	    k = k2
	    i = i + 1
	end
    end

    return F, tt, nil

end

local function ipairsfilter(tt, test)
    print("ipairsfilter parameters:", type(tt), tt, type(test), test)

    if type(test) ~= "function" then
	qerror("error in ipairsfilter: test is not a function; type(test) = " .. type(test))
    end

    -- implicitly uses 'test' from the outer function.
    local F = function(t, k)

	--print("entering F:", t, k, test)
	local k2, v
	local i = 1
	while true do
	    k2, v = next(t, k)
	    --print("F iteration ", i, k2, v)
	    if k2 == nil then 
		--print('F k2 == nil, returning', k2, v)
		return k2, v
	    end
	    if test(v) then
		--print("F match, returning", k2, v)
		return k2,v
	    end
	    k = k2
	    i = i + 1
	end
    end

    return F, tt, nil		-- iterator, table(array), starting index.

end



--[[
-- works
for k,v in ipairsfilter(test1, function(c) return (c % 10 == 0); end) do
    print("RESULT", k,v)
end
print()

-- works
for k,v in ipairsfilter(test1, function(c) return (c % 10 == 5); end) do
    print("RESULT", k,v)
end
print()
]]

--[[
for k,v in ipairs(df.item.get_vector()[72].improvements) do 
    print(k,v._type)
end
]]


--[[
-- okay, big problem. ipairs must have special handling to let it deal with a userdata vector.
-- this gives an error:
--	bad argument #1 to 'next' (table expected, got userdata)
-- which is correct.  so DFHack must overload next() for pairs() and ipairs() specifically.
for k,v in ipairsfilter(df.item.get_vector()[72].improvements, df.itemimprovement_writingst) do 
    print(k,v._type)
end

-- look into coroutines then?

-- NO, it turns out that the problem is that next() isn't defined for DF vectors.
-- implementing coroutines wouldn't help that.  iterators already work a bit like coroutines.

]]



local function Zpairsf(T, match)

    -- uses upvalue match, which must be a function returning a boolean.
    local function mynext(T, index)
	--print('mynext called with', T, index)
	--print('mynext match is', match)

	local value
	while true do

	    --print ('mynext calling next() with ', T, index)
	    index, value = next(T, index)
	    --print ('mynext next() returned', index, value)

	    if index == nil then
		--print('mynext index nil, returning nil, nil')
		return nil, nil
	    end
            if match(value) then
		--print('mynext match() true, returning', index, value)
		return index, value
	    else
		--print('mynext match() false, iterating')
            end

	end  -- while true
    end  -- nested function mynext


    --print('pairsf returning', mynext, T, nil)
    return mynext, T, nil
    
end
local Zipairsf = Zpairsf


--[[

print()
print('my working Zpairsf()')
print('trying true')
for k,v in Zpairsf(test2, function(c) return true; end) do
    print('myresult', k, v)
end

print()
print('trying modulus')
for k,v in Zpairsf(test2, function(c) return (c % 10 == 0); end) do
    print('myresult', k, v)
end

print()
print('my working Zipairsf()')
print('trying true')
for k,v in Zipairsf(test1, function(c) return true; end) do
    print('myresult', k, v)
end

print()
print('trying modulus')
for k,v in Zipairsf(test1, function(c) return (c % 10 == 0); end) do
    print('myresult', k, v)
end

print()
print('trying empty set')
for k,v in Zipairsf({}, function(c) return (c % 10 == 0); end) do
    print('myresult', k, v)
end

]]






local function ipairsf(tt, match)
    -- TODO Q: what happens with nested ipairsf calls?  are the upvalues handled properly?

    -- allow for 0-based DF vectors.
    local arraymin, arraymax = (df.isvalid(tt) and 0 or 1), (df.isvalid(tt) and #tt-1 or #tt)

    -- emulate next(T, index)
    -- implicitly uses upvalues arraymin, arraymax.
    -- they could be local, but it's probably faster to reference the upvalue 
    --   than to recalculate on every iteration.  (because two calls to df.isvalid().)
    local function mynext(T, index)
	index = (index) and index + 1 or arraymin
	index = (index <= arraymax) and index or nil
	return index, (index) and T[index] or nil
    end

    -- implicitly uses upvalue match.
    local function myfilter(T, index)
	--print('myfilter called with', T, index)
	--print('myfilter match is', match)

	--local iterations = 1  -- debugging
	while true do
	    --print('iterations', iterations)

	    local value
	    index, value = mynext(T, index)

	    if index == nil then
		--print('myfilter: index nil, returning nil, nil')
		return nil, nil
	    end
            if match(value) then
		--print('myfilter: match() true, returning', index, value)
		return index, value
	    else
		--print('myfilter match() false, iterating')
            end

	    --iterations = iterations + 1  -- debugging
	end
    end

    --print("ipairsf called with", type(tt), tt, type(match), match)

    if df.isvalid(match) == "type" then
	--print("ipairsf: making test funtion from type", tostring(match))
	local z = match
	match = function(c) return z:is_instance(c); end
    end

    return myfilter, tt, nil

end


--[[
print()
print('my ipairsf()')
print('trying true')
for k,v in ipairsf(test1, function(c) return true; end) do
    print('myresult', k, v)
end

print()
print('trying modulus')
for k,v in ipairsf(test1, function(c) return (c % 10 == 0); end) do
    print('myresult', k, v)
end

print()
print('trying empty set')
for k,v in ipairsf({}, function(c) return (c % 10 == 0); end) do
    print('myresult', k, v)
end
]]



--[=[
test3 = df.global.world.items.other.SLAB
print('getmetatable(test3)', getmetatable(test3))
print(#getmetatable(test3)) -- 13
printall(getmetatable(test3)) -- no output
printall_ipairs(getmetatable(test3)) -- no output
print('debug.getmetatable(test3)', getmetatable(test3))
print(#debug.getmetatable(test3)) -- 0, for some crazy reason
printall(debug.getmetatable(test3))
--[[
__tostring               = function: 000001D1606467C0
userdata: 00007FFA56E35F8C       = userdata: 00007FFA56D40300
resize                   = function: 000001D12C9BF580
_type                    = vector<item*>
__index                  = function: 000001D12C9BEC80
delete                   = function: 000001D128C67F00
__metatable              = vector<item*>
_field_identity          = userdata: 00007FFA56E8D760
new                      = function: 000001D128C68140
_field                   = function: 000001D12C9BF220
erase                    = function: 000001D12C9BE410
__ipairs                 = function: 000001D132AEC6A0
_index_table             = table: 000001D129066020
__len                    = function: 000001D12C9BEBF0
insert                   = function: 000001D12C9BF100
_displace                = function: 000001D129066860
__newindex               = function: 000001D12C9BED10
assign                   = function: 000001D128C68780
__pairs                  = function: 000001D132AEC5E0
__eq                     = function: 00007FFA5618BAA0
_kind                    = container
sizeof                   = function: 000001D129066560
]]  -- note that there is NOT a next() .
printall_ipairs(debug.getmetatable(test3)) -- no output
print('next(test1)', next(test1))
--print('next(test3)', next(test3)) -- errors because test3 is userdata and next needs a table.
]=]


--[[
print('testing external function:')
print('filter unit.id % 100 in df.global.world.units.active')
local function unitid_mod_100(c) return(c.id % 100 == 0); end
for k,v in ipairsf(df.global.world.units.active, unitid_mod_100) do
    print(v.id, v.race, translateName(v.name))
end
]]


--[[
print('testing anonymous function:')
print('filter books and scrolls in df.global.world.items.other.IN_PLAY')
for k,v in ipairsf(df.global.world.items.other.IN_PLAY, 
	function(c) 
	    return(df.item_bookst:is_instance(c) 
		or (df.item_toolst:is_instance(c) and c.subtype.id == "ITEM_TOOL_SCROLL") )
	end
) do
    local title = "(untitled, no writing itemimprovement)"
    for k2, v2 in ipairsf(v.improvements, 
	function(c) 
	    return df.itemimprovement_pagesst:is_instance(c)
		    or df.itemimprovement_writingst:is_instance(c)
	end
    ) do
	local wc = df.written_content.find(v2.contents[0])
	title = (wc) and wc.title or "(untitled, invalid df.written_content index)"
    end
    print(v.id, title)
end
]]


--[[
print('testing DF type:')
print('filter df.item_slabst in df.global.world.items.other.IN_PLAY')
for k,v in ipairsf(df.global.world.items.other.IN_PLAY, df.item_slabst) do
    print(v.id, v.description)
end
]]
ipairsf = nil


-- ipairsF() is ipairs with a filter, so you don't have to nest an if/then/end inside your for/do/end.
-- the intent is to reduce indentation overall, and to focus attention on the loop logic.
--
-- implementation difference: this returns iterator, array, nil unlike ipairs() which returns iterator, array, 0.
-- (this is because 0 is a valid index for DF vectors.)
--
-- TODO Q: what happens with nested ipairsF calls?  are the upvalues handled properly?  test.
--   Hmm, nested ipairsF implies nested data structures.
--
---@alias array table  # a table that is (or has) a list, or a DF vector.
--
---@param array array  # a table that is (or has) a list, or a DF vector.  ipairs semantics.
---@param match fun(any):boolean|any_DF_type
---@return fun(array, integer?) integer, T  # basically a filtered ipairs-like next-element iterator, expected to be used by generic for
---@return table  # the array or vector being iterated over.
---@return nil  # signals the start of the iteration, per ipairs semantics.
local function ipairsF(array, match)
    assert(type(array) == "table" or (df.isvalid(array) == "ref" and array._kind == "container"))
    assert(type(match) == "function" or df.isvalid(match) == "type")
    local debugging_verify_arraysize = #array

    ---@param Array array|any_DF_type
    ---@param index integer?
    ---@return integer?
    ---@return any
    -- note: uses upvalue match to maintain ipairs-like semantics.
    -- note: uses upvalues array and debugging_verify_arraysize in assertions.
    local function iterator(Array, index)
        assert(type(Array) == "table" or (df.isvalid(Array) == "ref" and Array._kind == "container"))
        assert(index == nil or math.type(index) == "integer")
        assert(Array == array)
        assert(#Array == debugging_verify_arraysize)
        assert(type(match) == "function")

        local min = df.isvalid(Array) and 0 or 1
        local max = df.isvalid(Array) and #Array-1 or #Array
        while true do
            index = (index) and index + 1 or min
            index = (index <= max) and index or nil
            local value = (index) and Array[index] or nil

            if index == nil then return nil, nil; end
            if match(value) then return index, value; end
        end
    end

    -- if given a DF type, create a closure to test for matching that type.
    if df.isvalid(match) == "type" then
        local _match = match  -- this local variable is required to retain knowledge of the DF type.
        match = function(Type) return _match:is_instance(Type); end
    end
    assert(type(match) == "function")

    return iterator, array, nil
end


---------------------------------


local function test(name, testfunc)
    local tests = {
	{"array110", { 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, }},
	{"set",      { a=5, b=10, c=15, d=20, e=25, f=30, g=35, h=40, i=45, j=50, }},
	{"empty",    {}},
	{"mixed1",   { 5, 10, 15, 20, 25, f=30, g=35, h=40, i=45, j=50, }},
	{"mixed2",   { a=5, b=10, c=15, d=20, e=25, 30, 35, 40, 45, 50, }},
	{"bracket1", { 5, 10, 15, 20, 25, [6]=30, [7]=35, [8]=40, [9]=45, [10]=50, }},
	{"bracket2", { [1]=5, [2]=10, [3]=15, [4]=20, [5]=25, [6]=30, [7]=35, [8]=40, [9]=45, [10]=50, }},
	{"bracket3", { 5, 10, 15, 20, 25, [6]=30, [7]=35, [8]=40, [9]=45, [10]=50, }},
	{"bracket4", { [1]=5, [2]=10, [3]=15, [4]=20, [5]=25, 30, 35, 40, 45, 50, }},
--	{"array610", { 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, }},
    }
    for _,v in ipairs(tests) do if v[1]=="array610" then for ii = 1,5 do v[2][ii] = nil;end;end;end
    -- so it turns out this keeps the array elements 1..5, setting their values to nil.

    print("trying function " .. name)
    for _, test in ipairs(tests) do
        local testname, testset = test[1], test[2]
        dfhack.print(string.format("%-10s", testname))
	for i,v in ipairsF(testset, testfunc) do
            dfhack.print(string.format("%2s -> %2s%2s", i, v, ''))
        end
        print()
    end
end

local function True(c) return true; end
local function False(c) return false; end
local function mod0(c) return (c % 10 == 0); end
local function mod5(c) return (c % 10 == 5); end
local function mod9(c) return (c % 10 == 9); end

test('true', True)
test('false', False)
test('mod0', mod0)
test('mod5', mod5)
test('mod9', mod9)
--do return end

local function X(n)if df.unit:is_instance(n) then n=n.name; return dfhack.translation.translateName(n,false);end;end
print("finding active units with unit.id mod100==0")
for _,unit in ipairsF(df.global.world.units.active, function(u)return u.id % 100 == 0; end) do
    print(dfhack.units.getRaceName(unit),X(unit))
end

print("finding slabs by type in IN_PLAY items")
for _,item in ipairsF(df.global.world.items.other.IN_PLAY, df.item_slabst) do
    print(dfhack.items.getReadableDescription(item))
end

print("finding slabs by type in active units")
for _,item in ipairsF(df.global.world.units.active, df.item_slabst) do
    print(dfhack.items.getReadableDescription(item))
end

print("counting seeds")
local seeds = {}
for _, seed in ipairsF(df.global.world.items.other.IN_PLAY, df.item_seedsst) do
    table.insert(seeds, seed)
end
print(string.format("found %d seeds.  That is %.1f%% of all in-play items.", #seeds, 
    math.floor(0.5 + 100.0 * #seeds / #df.global.world.items.other.IN_PLAY)) )
seeds = nil

