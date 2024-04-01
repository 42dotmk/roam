local pickers = require "telescope.pickers"
local sorters = require "telescope.sorters"
local finders = require "telescope.finders"
local actions_state = require "telescope.actions.state"
local actions = require "telescope.actions"

local strip_quotes = function(obj) return string.gsub(obj, "\"", "") end

local storage = require("roam.storage")
local Roam = {
    db = nil,
    config = {
        roam_dir = vim.fn.expand("~/org"),
        db_path = vim.fn.expand("~/.config/emacs/.local/cache/org-roam.db")
    }
}

--[[
  Setup the pluing with the given options
  and registers the commands
    Args:
    - opts: table: The options for the plugin
        - db_path: string: The path to the sqlite database

]]
Roam.setup = function(opts)
    opts = opts or {}
    Roam.config = vim.tbl_extend("force", Roam.config, opts)
    storage:load(Roam.config.db_path)
    vim.cmd [[command! RoamSearch lua require('roam').search()]]
    vim.cmd [[command! RoamOpenId lua require('roam').goto_id_under_cursor()]]
end


--[[
    Opens a new telescope picker with the results from the database
]]
Roam.search = function(opts)
    opts = opts or {}
    pickers.new(opts, {
        prompt_title = "Roam Search",
        finder = finders.new_table {
            results = storage:nodes(),
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = strip_quotes(entry.title),--entry.title,
                    ordinal = strip_quotes(entry.title .. " " .. entry.file),
                    filename = strip_quotes(entry.file)
                }
            end
        },
        sorter = sorters.get_generic_fuzzy_sorter(),
        attach_mappings = function(prompt_bufnr, map)
            map({"i", "n"}, "<C-k>", function()
                local entry = actions_state.get_selected_entry(prompt_bufnr).value
                actions.close(prompt_bufnr)
                local val = "[[id:".. strip_quotes(entry.id) .. "][" .. strip_quotes(entry.title) .."]]"
                vim.api.nvim_put({val}, "c", true, true)
                -- print(entry)
            end)
            return true
        end,
    }):find()
end

--[[
    Opens the file for the given id in a new buffer
    Args:
    - id: string: The id of the node
]]
Roam.open_id = function(id)
    local file = storage:get_by_id(id)
    if file == nil then
        print("No file found for id: " .. id)
        return
    end
    local cmd = "e " .. strip_quotes(file)
    vim.cmd(cmd)
end

--[[
    Opens the file for the id under the cursor in a new buffer
]]
Roam.goto_id_under_cursor = function()
    local str = vim.fn.expand('<cWORD>')
    local id = string.match(str, "id:([%w%-]+)")
    if id == nil then
        print("No id found")
        return
    end
    Roam.open_id(id)
end


Roam.setup()
return Roam
