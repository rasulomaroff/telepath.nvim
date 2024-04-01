local U = require 'telepath.util'

local M = {}

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

    if opts.restore then
        local source_win = U.get_win()
        local anchor_buf = vim.api.nvim_get_current_buf()
        local anchor_id = U.set_extmark(anchor_buf, vim.api.nvim_win_get_cursor(source_win))

        M.restore = {
            anchor_buf = anchor_buf,
            anchor_id = anchor_id,
            source_win = source_win,
            win = vim.fn.winsaveview(),
        }
    end
end

--- sets last active window
---@param win number
function M.sync_win(win)
    M.last_win = win
end

function M.clear()
    if M.restore then
        U.del_extmark(M.restore.anchor_buf, M.restore.anchor_id)

        M.restore = nil
    end

    M.recursive = nil
    M.input = nil
    M.last_win = nil
    M.forced_motion = nil
    M.jumplist = nil
end
end

return M
