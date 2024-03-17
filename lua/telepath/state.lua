local Util = require 'telepath.util'

local M = {}

---@param opts telepath.RemoteParams
function M:init(opts)
    -- if there's the input, it means that this function was evoked while the previous 'remote' call was active
    if self.input then
        Util.clear_aucmds()
        self:clear()
    end

    self.forced_motion = Util.extract_forced_motion(vim.fn.mode(true))

    self.input = (vim.v.count > 0 and vim.v.count or '')
        .. '"'
        .. vim.v.register
        .. vim.v.operator
        .. self.forced_motion

    self.recursive = opts.recursive
    -- setting it to true if not passed
    self.jumplist = opts.jumplist == nil or opts.jumplist

    if opts.restore then
        local source_win = vim.api.nvim_get_current_win()
        local anchor_buf = vim.api.nvim_get_current_buf()
        local anchor_id = Util.set_extmark(anchor_buf, vim.api.nvim_win_get_cursor(source_win))

        self.restore = {
            anchor_buf = anchor_buf,
            anchor_id = anchor_id,
            source_win = source_win,
        }
    end
end

--- sets last active window
---@param win number
function M:sync_win(win)
    self.last_win = win
end

function M:clear()
    if self.restore then
        Util.del_extmark(self.restore.anchor_buf, self.restore.anchor_id)

        self.restore = nil
    end

    self.recursive = nil
    self.input = nil
    self.last_win = nil
    self.forced_motion = nil
    self.jumplist = nil
end

return M
