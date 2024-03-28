local function file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else return false end
end

local query_func = function(self, query)
    return function()
        return self.db:eval(query)
    end
end
return {
    file_exists = file_exists,
    query_func = query_func
}
