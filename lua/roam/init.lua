local sqlite = require "sqlite.db" --- for constructing sql databases
local pickers = require "telescope.pickers"
local sorters = require "telescope.sorters"
local finders = require "telescope.finders"
local actions_state = require "telescope.actions.state"
local actions = require "telescope.actions"
local strip = function(obj) return string.gsub(obj, "\"", "") end

local M = {
    db = nil,
    config = {
        roam_dir = vim.fn.expand("~/org"),
        db_path = vim.fn.expand("~/.config/emacs/.local/cache/org-roam.db")
    }
}

M.initialize_db = function()
    if (M.db ~= nil) then
        M.db:close()
    end
    local db = sqlite:open(M.config.db_path)
    -- Create the nodes table if it does not exist
    db:eval("CREATE TABLE IF NOT EXISTS nodes (id TEXT PRIMARY KEY, title TEXT, file TEXT)")
    db:eval("CREATE INDEX IF NOT EXISTS title_index ON nodes(title)")
    db:eval("CREATE INDEX IF NOT EXISTS file_index ON nodes(file)")
    -- create the files table if it does not exist
    db:eval("CREATE TABLE IF NOT EXISTS files (id TEXT PRIMARY KEY, title TEXT, file TEXT)")
    db:eval("CREATE INDEX IF NOT EXISTS title_index ON files(title)")
    db:eval("CREATE INDEX IF NOT EXISTS file_index ON files(file)")
end
--[[
  Setup the pluing with the given options
  and registers the commands
    Args:
    - opts: table: The options for the plugin
        - db_path: string: The path to the sqlite database

]]
M.setup = function(opts)
    opts = opts or {}
    M.config = vim.tbl_extend("force", M.config, opts)

    -- check if file exists
    if vim.fn.filereadable(M.config.db_path) == 0 then
        print("Database file not found, creating a new one")
        M.initialize_db()
    end
    M.db = sqlite:open(M.config.db_path)
    vim.cmd [[command! RoamSearch lua require('roam').search()]]
    vim.cmd [[command! RoamOpenId lua require('roam').goto_id_under_cursor()]]
end


--[[
    Returns all the nodes from the database as a table
    Returns: 
    - table: A table of nodes :
]]
M.get_db_data = function()
    local res = M.db:eval("SELECT * from nodes")
    return res
end
--[[
    Opens a new telescope picker with the results from the database
]]
M.search = function(opts)
    opts = opts or {}
    pickers.new(opts, {
        prompt_title = "Roam Search",
        finder = finders.new_table {
            results = M.get_db_data() ,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = strip(entry.title),--entry.title,
                    ordinal = strip(entry.title .. " " .. entry.file),
                    filename = strip(entry.file)
                }
            end
        },
        sorter = sorters.get_generic_fuzzy_sorter(),
        attach_mappings = function(prompt_bufnr, map)
            map({"i", "n"}, "<C-k>", function()
                local entry = actions_state.get_selected_entry(prompt_bufnr).value
                actions.close(prompt_bufnr)
                local val = "[[id:".. strip(entry.id) .. "][" .. strip(entry.title) .."]]"
                vim.api.nvim_put({val}, "c", true, true)
                -- print(entry)
            end)
            return true
        end,
    }):find()
end

--[[
    Returns the file path for the given id
    Args:
    - id: string: The id of the node
    Returns:
    - string: The file path of the node
]]
M.get_by_id = function(id)
    local res = M.db:eval("SELECT * FROM 'nodes' WHERE id='\"" .. id .. "\"' LIMIT 1")
    if #res == 0 then
        return nil
    end
    return res[1].file
end

--[[
    Opens the file for the given id in a new buffer
    Args:
    - id: string: The id of the node
]]
M.open_id = function(id)
    local file = M.get_by_id(id)
    if file == nil then
        print("No file found for id: " .. id)
        return
    end
    local cmd = "e " .. strip(file)
    vim.cmd(cmd)
end

--[[
    Opens the file for the id under the cursor in a new buffer
]]
M.goto_id_under_cursor = function()
    local str = vim.fn.expand('<cWORD>')
    local id = string.match(str, "id:([%w%-]+)")
    if id == nil then
        print("No id found")
        return
    end
    M.open_id(id)
end


M.setup()
return M
