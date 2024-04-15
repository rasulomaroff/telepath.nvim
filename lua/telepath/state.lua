local U = require 'telepath.util'

local M = {
    default = {
        window_restore = {
            source = 'view',
            rest = 'view',
        },
    },
}

---@param opts telepath.RemoteParams
function M.init(opts)
    -- if there's an action, it means that this function was evoked while the previous 'remote' call was active
    if M.action then
        U.clear_aucmds()
        M.clear()
    end

    M.forced_motion = U.extract_forced_motion(vim.fn.mode(true))

    M.action = {
        feed_mode = 'n',
        count = vim.v.count,
        register = vim.v.register,
        operator = vim.v.operator,
        regtype = U.extract_forced_motion(vim.fn.mode(true)),
    }

    if opts.remap and opts.remap[M.action.operator] then
        M.action.feed_mode = 'm'

        M.action.remap = type(opts.remap[M.action.operator]) == 'string' and opts.remap[M.action.operator]
            or M.action.operator
    end

    M.recursive = opts.recursive

    -- setting it to true if not passed
    M.jumplist = opts.jumplist == nil or opts.jumplist

    if opts.window_restore == nil or opts.window_restore == 'view' then
        M.window_restore = M.default.window_restore
    elseif type(opts.window_restore) == 'table' then
        M.window_restore = vim.tbl_extend('force', M.default.window_restore, opts.window_restore)
    else
        M.window_restore = { source = opts.window_restore, rest = opts.window_restore }
    end

    M.source_win = U.get_win()
    M.current_win = M.source_win

    if opts.restore then
        local anchor_buf = vim.api.nvim_get_current_buf()
        local anchor_id = U.set_extmark(anchor_buf, vim.api.nvim_win_get_cursor(M.source_win))

        M.restore = { anchor_buf = anchor_buf, anchor_id = anchor_id }
    end

    M.hooks = opts.hooks
end

---@return string input
---@return string feed_mode
function M.get_input()
    return (M.action.count > 0 and M.action.count or '')
        .. U.reg
        .. M.action.register
        .. (M.action.remap or M.action.operator)
        .. M.action.regtype,
        M.action.feed_mode
end

---@param win number
function M.sync_win(win)
    M.current_win = win
end

function M.clear()
    if M.restore then
        U.del_extmark(M.restore.anchor_buf, M.restore.anchor_id)
    end

    M.recursive = nil
    M.restore = nil
    M.current_win = nil
    M.forced_motion = nil
    M.jumplist = nil
    M.window_restore = nil
    M.source_win = nil
    M.action = nil
    M.hooks = nil
    M.clear_view()
end

function M.save_view()
    M.winview = vim.fn.winsaveview()
end

--- @return boolean
function M.has_any_restoration()
    for type in pairs(M.window_restore) do
        if M.has_specific_restoration(type) then
            return true
        end
    end

    return false
end

--- @param type 'source' | 'rest'
--- @return boolean
function M.has_specific_restoration(type)
    return M.get_restoration_strategy(type) ~= nil
end

--- @param type 'source' | 'rest' | false
function M.get_restoration_strategy(type)
    return M.window_restore[type]
end

function M.restore_view()
    vim.fn.winrestview(M.winview)
    M.clear_view()
end

function M.clear_view()
    M.winview = nil
end

return M
