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

    M.jump(function(target)
        S.init(opts)

        -- if we're going into another window with 'restore' or 'recursive' option and we have any window restoration
        -- then we'll save that window view to then restore it
        if S.has_any_restoration() and (S.restore or S.recursive) then
            if S.current_win ~= target.win then
                U.au_once('WinEnter', function()
                    S.sync_win(target.win)

                    if S.has_specific_restoration 'rest' then
                        S.save_view()

                        -- if it's recursive, then we hang a listener (WinLeave) in the 'restore' method after the 'leap' is performed
                        -- because in other case the window will be restored while typing a leap pattern (probably because how Leap plugin works)
                        if not S.recursive then
                            U.au_once('WinLeave', S.restore_view)
                        end
                    end
                end)
            elseif S.has_specific_restoration 'source' then
                S.save_view()
            end
        end

        U.exit()
        -- setting a jumpmark before jumping
        M.set_jumpmark()

        M.set_cursor(target.win, target.pos)

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
    -- They do it by going to the visual mode first, selecting the range and operate on it.
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
        U.au('ModeChanged', M.restore_from_insert, 'i*:[^i]*')
    else
        M.restore()
    end
end

function M.restore_from_insert()
    if vim.v.event.new_mode == 'niI' then
        return
    end

    vim.schedule(M.restore)
    -- delete autocmd
    return true
end

function M.restore()
    local jumped = false

    if S.recursive then
        M.jump(function(target)
            jumped = true

            if target.win ~= S.current_win then
                if
                    S.current_win == S.source_win and S.has_specific_restoration 'source'
                    or S.current_win ~= S.source_win and S.has_specific_restoration 'rest'
                then
                    U.au_once('WinLeave', S.restore_view)
                end

                -- if we're going to another window, then we'll start observing
                -- after entering it and save its view
                U.au_once('WinEnter', function()
                    S.sync_win(target.win)

                    if
                        target.win == S.source_win and S.has_specific_restoration 'source'
                        or target.win ~= S.source_win and S.has_specific_restoration 'rest'
                    then
                        S.save_view()
                    end

                    M.watch()
                end)
            else
                M.watch()
            end

            M.set_cursor(target.win, target.pos)
        end)
    end

    if not jumped then
        if S.restore then
            -- if didn't jump to another window, then there won't be any event that tells us
            -- that we need to restore a win view. In this case we have to check it manually
            if S.current_win == S.source_win then
                if S.has_specific_restoration 'source' then
                    -- it's important to restore window first and then set the cursor
                    S.restore_view()
                end
            elseif S.recursive and S.has_specific_restoration 'rest' then
                U.au_once('WinLeave', S.restore_view)
            end
            M.set_cursor(S.source_win, U.get_extmark(S.restore.anchor_id, S.restore.anchor_buf))
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
        vim.cmd.normal { 'm`', bang = true }
    end
end

return M
