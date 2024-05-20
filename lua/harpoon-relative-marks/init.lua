local harpoon = require("harpoon")
local Extensions = require("harpoon.extensions")
local Path = require("pathlib")

local M = {}

M._current_dir = Path(vim.uv.cwd())

local function normalize_path(current_dir, root_dir, path)
    local p = Path(path)
    local c = Path(current_dir)
    local r = Path(root_dir)
    local idx = tostring(p):find(tostring(r), 1, true)
    if idx == 1 then
        return p:relative_to(c, true):tostring()
    end
    return p:tostring()
end

function M.create_list_item(config, item)
    if item == nil then
        item = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
    elseif type(item) == "string" then
        item = tostring(Path(M._current_dir / item):resolve())
    end

    if type(item) == "string" then
        local name = tostring(Path(item):absolute())
        local bufnr = vim.fn.bufnr(name, false)

        local pos = { 1, 0 }
        if bufnr ~= -1 then
            pos = vim.api.nvim_win_get_cursor(0)
        end
        item = {
            value = name,
            context = {
                row = pos[1],
                col = pos[2],
            },
        }
    end

    return item
end

function M.setup(config)
    config = config
        or {
            key = function()
                return vim.uv.cwd()
            end,
        }
    M._current_dir = Path(config.key())
    harpoon:extend({
        -- ctx is a table with the following keys (win_id, bufnr, current_file)
        [Extensions.event_names.UI_CREATE] = function(ctx)
            local ok, current_file = pcall(vim.uv.fs_realpath, ctx.current_file)
            local current_dir = nil
            if ok and type(current_file) == "string" then
                local p = Path(current_file)
                if p:is_dir() then
                    current_dir = p
                else
                    current_dir = p:parent()
                end
            else
                current_file = Path(vim.uv.cwd())
                current_dir = current_file
            end
            -- if there is no buffer open or the current buffer is not a file
            if current_dir == nil or current_dir == "" then
                current_dir = Path(vim.uv.cwd())
            end

            M._current_dir = current_dir

            local lines = vim.api.nvim_buf_get_lines(ctx.bufnr, 0, -1, false)
            local new_lines = {}
            for _, line in ipairs(lines) do
                local normal = normalize_path(current_dir, config.key(), line)
                table.insert(new_lines, normal)
            end
            vim.api.nvim_buf_set_lines(ctx.bufnr, 0, -1, false, new_lines)
        end,
    })
end

function M.display(list_item)
    return list_item.value
end

return M
