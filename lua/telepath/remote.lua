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

local function save_next_view()
    S.save_view()

    -- if it's recursive, then we hang a listener (WinLeave) in the 'restore' method after the 'leap' is performed
    -- because in other case the window will be restored while typing a leap pattern (probably because how Leap plugin works)
    if not S.recursive then
        U.au_once('WinLeave', S.rest_view)
    end
end

---@param opts telepath.RemoteParams
function M.remote(opts)
    opts = opts or {}

    M.jump(function(params)
        S.init(opts)
        M.set_jumpmark()

        -- if we're going into another window with 'restore' or 'recursive' option
        -- then we'll save that window view to then restore it
        -- because when we jump to that window, we can possibly scroll it
        -- if the 'scrolloff' option is set and we're jumping to the top or bottom of the window
        if S.restore or S.recursive then
            if U.get_win() ~= params.win then
                U.au_once('WinEnter', save_next_view)
            else
                S.save_view()
            end
        end

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
        U.au_once('ModeChanged', M.seek_restoration, ('no%s:*'):format(S.forced_motion))
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
        -- if someone knows how I can pass a pattern that matches everything
        -- except niI mode, PRs are very welcome!
        U.au('ModeChanged', M.restore_from_insert, 'i*:*')
    else
        M.restore()
    end
end

function M.restore_from_insert()
    if vim.v.event.new_mode == 'niI' then
        return
    end

    vim.schedule(M.restore)
    --  delete autocmd
    return true
end

local function save_view_and_watch()
    S.save_view()
    M.watch()
end

function M.restore()
    local restore = false

    if S.recursive then
        M.jump(function(params)
            restore = true

            if params.win ~= S.last_win then
                U.au_once('WinLeave', S.rest_view)

                -- if we're going to another window, then we'll start observing
                -- after entering it and save its view
                U.au_once('WinEnter', save_view_and_watch)
            else
                M.watch()
            end

            M.set_cursor(params.win, params.pos)
            S.sync_win(params.win)
        end)
    end

    if not restore then
        if S.restore then
            -- if didn't jump to another window, then there won't be any event that tells us
            -- that we need to restore a win view. In this case we have to check it manually
            if U.get_win() == S.restore.source_win then
                -- it's important to restore window first and then set the cursor
                S.rest_view()
            elseif S.recursive then
                U.au_once('WinLeave', S.rest_view)
            end
            M.set_cursor(S.restore.source_win, U.get_extmark(S.restore.anchor_id, S.restore.anchor_buf))
        end

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
