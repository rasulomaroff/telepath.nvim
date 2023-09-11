local mappings = {
    r = {
        function()
            require('telepath').remote { restore = true }
        end,
        'Remote action with cursor restoration',
    },
    m = {
        function()
            require('telepath').remote()
        end,
        'Remote action',
    },
    R = {
        function()
            require('telepath').remote { restore = true, recursive = true }
        end,
        'Recursive remote action with cursor restoration',
    },
    M = {
        function()
            require('telepath').remote { recursive = true }
        end,
        'Recursive remote action',
    },
}

---@param keys table<string>
---@param overwrite boolean | nil
local function set_mappings(keys, overwrite)
    for _, lhs in ipairs(keys) do
        local rhs, desc = unpack(mappings[lhs])

        if overwrite then
            vim.keymap.set('o', lhs, rhs, { silent = true, desc = desc })
        else
            if vim.fn.maparg(lhs, 'o') == '' then
                vim.keymap.set('o', lhs, rhs, { silent = true, desc = desc })
            end
        end
    end
end

---@param opts telepath.MappingsParams
local function init(opts)
    if not opts or vim.tbl_isempty(opts) or not opts.keys or vim.tbl_isempty(opts.keys) then
        set_mappings(vim.tbl_keys(mappings), opts and opts.overwrite or false)
    else
        set_mappings(opts.keys, opts.overwrite)
    end
end

return { init = init }
