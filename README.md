# Harpoon Relative Marks

This extension for [ThePrimeagen/harpoon](https://github.com/ThePrimeagen/harpoon)
is an extremely hacky way to display marks relative to your current file.

I currently use it with my fork of harpoon, although I don't think that is
required as I have overriden the implementation here anyways.

This is my harpoon config:

```lua
local find_project_root = function()
    local current_dir = vim.loop.cwd()
    local marker_files = { ".git", "package.json", ".sln" }

    -- Check each parent directory for the existence of a marker file or directory
    while current_dir ~= "/" do
        for _, marker in ipairs(marker_files) do
            local marker_path = current_dir .. "/" .. marker
            if vim.fn.isdirectory(marker_path) == 1 or vim.fn.filereadable(marker_path) == 1 then
                return current_dir
            end
        end
        current_dir = vim.fn.resolve(current_dir .. "/..")
    end
    -- If no marker file or directory is found, return the original directory
    return vim.loop.cwd()
end

return {
    -- "ThePrimeagen/harpoon",
    -- branch = "harpoon2",
    "maxrzaw/harpoon",
    branch = "harpoon3",
    lazy = false,
    dependencies = {
        "nvim-lua/plenary.nvim",
        {
            "maxrzaw/harpoon-relative-marks",
            dependencies = { "pysan3/pathlib.nvim" },
        },
    },
    config = function()
        local Harpoon = require("harpoon")
        local relative_marks = require("harpoon-relative-marks")

        Harpoon:setup({
            settings = {
                save_on_toggle = true,
                sync_on_ui_close = true,
                key = function()
                    -- return vim.uv.cwd() -- This is the default
                    return find_project_root()
                end,
            },
            default = {
                display = relative_marks.display,
                create_list_item = relative_marks.create_list_item,
            },
        })

        relative_marks.setup({
            key = function()
                return find_project_root()
            end,
        })

        vim.keymap.set("n", "<leader>m", function()
            Harpoon:list():add()
        end)
        vim.keymap.set("n", "<leader>h", function()
            Harpoon.ui:toggle_quick_menu(Harpoon:list(), {
                border = "rounded",
                title_pos = "center",
                title = " >-> Harpoon <-< ",
                ui_max_width = 80,
            })
        end)
    end,
}
```

## TODO

-   There was a wierd bug when I went to a mark outside of the cwd as well.
-   Need to properly expand ~/
