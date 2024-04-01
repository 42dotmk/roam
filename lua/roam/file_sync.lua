local FileSync = {}

function FileSync:list_files(dir, pattern)
    local files = {}
    dir = vim.fn.expand(dir)
    if pattern == nil then
        pattern = "%.org$"
    end
    for _, file in ipairs(vim.fn.readdir(dir)) do
        if file ~= "." and file ~= ".."  then
            if vim.fn.isdirectory(dir .. "/" .. file) == 1 then
                local sub_files = FileSync:list_files(dir .. "/" .. file)
                for _, sub_file in ipairs(sub_files) do
                    table.insert(files, sub_file)
                end
            else
                if string.match(file, pattern) then
                    table.insert(files, dir .. "/" .. file)
                end
            end
        end
    end
    return files
end

return FileSync
