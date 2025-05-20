
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

	--local iterations = 1 -- for debugging
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

	    --iterations = iterations + 1
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




test3 = df.global.world.items.other.SLAB
--[[
print('getmetatable(test3)', getmetatable(test3))
print(#getmetatable(test3)) -- 13
printall(getmetatable(test3)) -- no output
printall_ipairs(getmetatable(test3)) -- no output
print('debug.getmetatable(test3)', getmetatable(test3))
print(#debug.getmetatable(test3)) -- 0, for some crazy reason
printall(debug.getmetatable(test3))
--[ [
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
] ]  -- note that there is NOT a next() .
printall_ipairs(debug.getmetatable(test3)) -- no output
print('next(test1)', next(test1))
--print('next(test3)', next(test3)) -- errors because test3 is userdata and next needs a table.
]]


print('testing external function:')
print('filter unit.id % 100 in df.global.world.units.active')
local function unitid_mod_100(c) return(c.id % 100 == 0); end
for k,v in ipairsf(df.global.world.units.active, unitid_mod_100) do
    print(v.id, v.race, translateName(v.name))
end


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


print('testing DF type:')
print('filter df.item_slabst in df.global.world.items.other.IN_PLAY')
for k,v in ipairsf(df.global.world.items.other.IN_PLAY, df.item_slabst) do
    print(v.id, v.description)
end

