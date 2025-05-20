function printf(...)
    print(string.format(table.unpack({...})))
end


pat = ({...})[1]
pat = pat or '.*'

print('pattern:', pat)

print('SCRIPT NOT FINISHED.')