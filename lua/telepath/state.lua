local Util = require 'telepath.util'

local M = {}

---@param opts telepath.RemoteParams
function M:init(opts)
    self.forced_motion = self.forced_motion or Util.extract_forced_motion(vim.fn.mode(true))

    self.input = self.input
        or (vim.v.count > 0 and vim.v.count or '') .. '"' .. vim.v.register .. vim.v.operator .. self.forced_motion

    self.recursive = opts and opts.recursive

    if not opts.restore then
        -- this can happen if after 'restore' keybinding another one without 'restore' field was used
        if self.restore then
            Util.del_extmark(self.restore.anchor_buf, self.restore.anchor_id)

            self.restore = nil
        end
    -- only creating anchor if there's no such
    elseif not self.restore then
        local source_win = vim.api.nvim_get_current_win()
        local anchor_buf = vim.api.nvim_get_current_buf()
        local anchor_id = Util.set_extmark(anchor_buf, vim.api.nvim_win_get_cursor(source_win))

        self.restore = { anchor_buf = anchor_buf, anchor_id = anchor_id, source_win = source_win }
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
end

return M
