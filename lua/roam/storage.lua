local sqlite = require "sqlite.db" --- for constructing sql databases
local helpers = require "roam.helpers"

local RoamStorage = {
    ready = false,
    db = nil,
}

--[[
    Returns all the nodes from the database as a table
    Returns:
    - table: A table of nodes :
]]
function RoamStorage:nodes()
    return self.db:eval("SELECT * from nodes")
end

--[[
    Returns all the files from the database as a table
    Returns:
    - table: A table of files
]]
function RoamStorage:files()
    return self.db:eval("SELECT * from files")
end

--[[
    Inserts a new node into the database
    Args:
    - id: string: The id of the node
    - title: string: The title of the node
    - file: string: The file path of the node
]]
function RoamStorage:insert_node(id, title, file)
    self.db:eval("INSERT INTO nodes (id, title, file) VALUES ('" .. id .. "', '" .. title .. "', '" .. file .. "')")
end

--[[
    Inserts a new file into the database
    Args:
    - id: string: The id of the node
    - title: string: The title of the node
    - file: string: The file path of the node
]]
function RoamStorage:insert_file(id, title, file)
    self.db:eval("INSERT INTO files (id, title, file) VALUES ('" .. id .. "', '" .. title .. "', '" .. file .. "')")
end

--[[
    Returns the file path for the given id
    Args:
    - id: string: The id of the node
    Returns:
    - string: The file path of the node
]]
function RoamStorage:get_by_id(id)
    local res = self.db:eval("SELECT * FROM 'nodes' WHERE id='\"" .. id .. "\"' LIMIT 1")
    if #res == 0 then
        return nil
    end
    return res[1].file
end

function RoamStorage:initialize_db(db_path)
    local db = sqlite:open(db_path)
    -- Create the nodes table if it does not exist
    db:eval("CREATE TABLE IF NOT EXISTS nodes (id TEXT PRIMARY KEY, title TEXT, file TEXT)")
    db:eval("CREATE INDEX IF NOT EXISTS title_index ON nodes(title)")
    db:eval("CREATE INDEX IF NOT EXISTS file_index ON nodes(file)")

    -- create the files table if it does not exist
    db:eval("CREATE TABLE IF NOT EXISTS files (id TEXT PRIMARY KEY, title TEXT, file TEXT)")
    db:eval("CREATE INDEX IF NOT EXISTS title_index ON files(title)")
    db:eval("CREATE INDEX IF NOT EXISTS file_index ON files(file)")

    return db
end

function RoamStorage:load(db_path)
    if (self.db ~= nil) then
        self.db:close()
    end
    if not helpers:file_exists(db_path) then
        print("Roam: Database file not found, initializing new database")
        self.db = RoamStorage.initialize_db(db_path)
        print("Roam: Database initialized on path: " .. db_path)
    else
        self.db = sqlite:open(db_path)
    end
    self.ready = true
end

return RoamStorage
