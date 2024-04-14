local M = {}

M.ns = vim.api.nvim_create_namespace 'telepath.nvim'
M.augroup = vim.api.nvim_create_augroup('telepath.nvim', {})

-- constants
M.reg = '"'

---@return number window_id
function M.get_win()
    return vim.api.nvim_get_current_win()
end

---@param mode string
---@return boolean
function M.is_insert(mode)
    return mode:sub(1, 1) == 'i'
end

---@param mode string
---@return string
function M.extract_forced_motion(mode)
    return mode:sub(3)
end

-- utility to exit from op-mode
function M.exit()
    -- go to normal mode (vim's internal mapping)
    M.feed('<C-\\><C-n>', 'nx')
    M.feed('<esc>', 'n')
end

---@param event string
---@param cb fun(opts: table<string, any>)
---@param pattern string?
function M.au_once(event, cb, pattern)
    return vim.api.nvim_create_autocmd(event, {
        once = true,
        group = M.augroup,
        pattern = pattern,
        callback = cb,
    })
end

---@param event string
---@param cb fun(opts: table<string, any>)
---@param pattern string?
function M.au(event, cb, pattern)
    return vim.api.nvim_create_autocmd(event, {
        group = M.augroup,
        callback = cb,
        pattern = pattern,
    })
end

---@param name string
---@param data table
function M.exec_au(name, data)
    vim.api.nvim_exec_autocmds('User', { pattern = 'Telepath' .. name, data = data })
end

function M.clear_aucmds()
    vim.cmd 'au! telepath.nvim'
end

---@param keys string
---@return string
function M.termcodes(keys)
    return vim.api.nvim_replace_termcodes(keys, true, true, true)
end

---@param input string
---@param mode? string
function M.feed(input, mode)
    vim.api.nvim_feedkeys(M.termcodes(input), mode or 'n', false)
end

---@param buf number
---@param position { [0]: number, [1]: number }
---@return number mark_id
function M.set_extmark(buf, position)
    return vim.api.nvim_buf_set_extmark(buf, M.ns, position[1] - 1, position[2], {
        end_col = position[2] + 1,
        strict = false,
    })
end

---@param id number
---@param buf number
---@return table<number>
function M.get_extmark(id, buf)
    local mark = vim.api.nvim_buf_get_extmark_by_id(buf, M.ns, id, {})
    -- in other case it will throw an error
    mark[1] = mark[1] + 1

    return mark
end

---@param buf number
---@param id number
---@return boolean found
function M.del_extmark(buf, id)
    return vim.api.nvim_buf_del_extmark(buf, M.ns, id)
end

---@param window number
---@return boolean
function M.is_focusable(window)
    return vim.api.nvim_win_get_config(window).focusable
end

return M
