local U = require 'telepath.util'
local S = require 'telepath.state'

local M = {}

---@param action fun(target: { win: number, pos: table<number> })
function M.jump(action)
    require('leap').leap {
        action = function(target)
            -- jump to the first typed letter
            target.pos[2] = target.pos[2] - 1

            action { win = target.wininfo.winid, pos = target.pos }
        end,
        target_windows = vim.tbl_filter(U.is_focusable, vim.api.nvim_tabpage_list_wins(0)),
    }
end

---@param opts telepath.RemoteParams
function M.remote(opts)
    opts = opts or {}

    M.jump(function(params)
        S.init(opts)
        M.set_jumpmark()
        U.exit()
        S.sync_win(params.win)
        M.set_cursor(params.win, params.pos)
        vim.schedule(M.watch)
    end)
end

function M.watch()
    -- restore operator, count, register, and forced motion if presented
    U.feed(S.input)

    if S.restore or S.recursive then
        U.aucmd_once('ModeChanged', M.seek_restoration, ('no%s:*'):format(S.forced_motion))
    else
        S.clear()
    end
end

function M.seek_restoration()
    -- WARN: we use vim.schedule here and not an event from the autocmd options just because
    -- some plugins, such as mini.ai (and targets.vim probably) define their own textobjects, like 'a' for argument.
    -- They do it by going to the visual mode first, selecting the range and operate on them.
    -- Because of that, we can't properly say here which mode we're actually going into, therefore,
    -- we use scheduling and manually check later which mode we're in.
    -- I know this is not the best solution to this kind of problems, but if you know how this can be fixed
    -- the other way, please open an issue and describe everything there.
    vim.schedule(M._seek_restoration)
end

function M._seek_restoration()
    local to = vim.fn.mode(true)

    -- waiting for exiting insert mode, this can happen with 'c' operator
    if U.is_insert(to) then
        U.aucmd_once('ModeChanged', M.restore, 'i*:*')
    else
        M.restore()
    end
end

function M.restore()
    local restore = false

    if S.recursive then
        M.jump(function(params)
            restore = true

            if params.win ~= S.last_win then
                vim.schedule(M.watch)
            else
                M.watch()
            end

            M.set_cursor(params.win, params.pos)
            S.sync_win(params.win)
        end)
    end

    if not restore and S.restore then
            -- it's important to restore window first and then set the cursor
            vim.fn.winrestview(S.restore.win)
        M.set_cursor(S.restore.source_win, U.get_extmark(S.restore.anchor_id, S.restore.anchor_buf))
        S.clear()
    end
end

---@param win number
---@param pos table<number>
function M.set_cursor(win, pos)
    vim.api.nvim_set_current_win(win)
    -- Since the previous cursor position can be deleted from the buffer after performing an operation
    -- we need to call this method with 'pcall' not to cause an error
    pcall(vim.api.nvim_win_set_cursor, win, pos)
    M.set_jumpmark()
end

function M.set_jumpmark()
    if S.jumplist then
        -- setting a jumplist mark
        vim.cmd 'normal! m`'
    end
end

return M
