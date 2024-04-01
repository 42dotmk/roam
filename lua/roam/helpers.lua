local Helpers = {}

function Helpers:file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    end
    return false
end

function Helpers:query_func(query)
    return function()
        return self.db:eval(query)
    end
end

return Helpers
