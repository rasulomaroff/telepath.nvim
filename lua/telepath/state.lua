local U = require 'telepath.util'

local M = {
    default = {
        window_restore = { source = true, rest = true },
    },
}

---@param opts telepath.RemoteParams
function M.init(opts)
    -- if there's the input, it means that this function was evoked while the previous 'remote' call was active
    if M.input then
        U.clear_aucmds()
        M.clear()
    end

    M.forced_motion = U.extract_forced_motion(vim.fn.mode(true))

    M.input = (vim.v.count > 0 and vim.v.count or '') .. U.reg .. vim.v.register .. vim.v.operator .. M.forced_motion

    M.recursive = opts.recursive

    -- setting it to true if not passed
    M.jumplist = opts.jumplist == nil or opts.jumplist

    -- if window_restore wasn't passed or equals to true, then we consider it
    -- to be restoring all the windows
    if opts.window_restore == nil or opts.window_restore == true then
        M.window_restore = M.default.window_restore
    elseif opts.window_restore == false then
        M.window_restore = { source = false, rest = false }
    else
        M.window_restore = vim.tbl_extend('force', M.default.window_restore, opts.window_restore)
    end

    M.source_win = U.get_win()
    M.current_win = M.source_win

    if opts.restore then
        local anchor_buf = vim.api.nvim_get_current_buf()
        local anchor_id = U.set_extmark(anchor_buf, vim.api.nvim_win_get_cursor(M.source_win))

        M.restore = { anchor_buf = anchor_buf, anchor_id = anchor_id }
    end
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
    M.input = nil
    M.current_win = nil
    M.forced_motion = nil
    M.jumplist = nil
    M.window_restore = nil
    M.source_win = nil
    M.clear_view()
end

function M.save_view()
    M.winview = vim.fn.winsaveview()
end

--- @return boolean
function M.has_any_restoration()
    for _, restore in pairs(M.window_restore) do
        if restore then
            return true
        end
    end

    return false
end

--- @param type 'source' | 'rest'
--- @return boolean
function M.has_specific_restoration(type)
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
