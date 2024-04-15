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
    S.init(opts)
    local jumped = false

    M.run_hook 'Enter'
    M.jump(function(target)
        jumped = true

        -- if we're going into another window with 'restore' or 'recursive' option and we have any window restoration
        -- then we'll save that window view to then restore it
        if S.has_any_restoration() and (S.restore or S.recursive) then
            if S.current_win ~= target.win then
                U.au_once('WinEnter', function()
                    S.sync_win(target.win)

                    if S.has_specific_restoration 'rest' then
                        S.save_view()
                    end
                end)
            elseif S.has_specific_restoration 'source' then
                S.save_view()
            end
        end

        U.exit()
        -- setting a jumpmark before jumping
        M.set_jumpmark()

        M.run_hook 'JumpPre'
        M.set_cursor(target.win, target.pos)
        M.run_hook 'Jump'

        vim.schedule(M.watch)
    end)

    if not jumped then
        M.run_hook 'Leave'
        S.clear()
    end
end

function M.watch()
    -- restore operator, count, register, and forced motion if presented
    local input, mode = S.get_input()
    U.feed(input, mode)

    if S.restore or S.recursive then
        U.au_once('ModeChanged', M.seek_restoration, ('no%s:*'):format(S.forced_motion))
    else
        M.run_hook 'Leave'
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
                local win_type

                if S.current_win == S.source_win then
                    if S.has_specific_restoration 'source' then
                        win_type = 'source'
                    end
                elseif S.has_specific_restoration 'rest' then
                    win_type = 'rest'
                end

                if win_type then
                    U.au_once('WinLeave', function()
                        M.restore_winview(win_type)
                    end)
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

            M.run_hook 'JumpPre'
            M.set_cursor(target.win, target.pos)
            M.run_hook 'Jump'
        end)
    end

    if not jumped then
        if S.restore then
            local skipped = false

            M.run_hook('RestorePre', {
                cancel_restoration = function()
                    skipped = true
                end,
            })

            if not skipped then
                -- if didn't jump to another window, then there won't be any event that tells us
                -- that we need to restore a win view. In this case we have to check it manually
                if S.current_win == S.source_win then
                    if S.has_specific_restoration 'source' then
                        -- it's important to restore window first and then set the cursor
                        -- we don't call `WindowRestore` events when restoring a source window,
                        -- because we have `Restore` event instead and it can create confusions
                        M.restore_winview('source', true)
                    end
                elseif (S.recursive or S.restore) and S.has_specific_restoration 'rest' then
                    U.au_once('WinLeave', function()
                        M.restore_winview 'rest'
                    end)
                end

                M.set_cursor(S.source_win, U.get_extmark(S.restore.anchor_id, S.restore.anchor_buf))
                M.run_hook 'Restore'
            end
        end

        M.run_hook 'Leave'
        S.clear()
    end
end

---@param win_type 'source' | 'rest'
---@param force_skip? boolean
function M.restore_winview(win_type, force_skip)
    local skipped = false

    if not force_skip then
        M.run_hook('WindowRestorePre', {
            cancel_window_restoration = function()
                skipped = true
            end,
        })
    end

    if skipped then
        S.clear_view()
    else
        local restore_strategy = S.get_restoration_strategy(win_type)

        if restore_strategy == 'cursor' then
            vim.api.nvim_win_set_cursor(0, { S.winview.lnum, S.winview.col })
            S.clear_view()
        else
            S.restore_view()
        end

        if not force_skip then
            M.run_hook 'WindowRestore'
        end
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

---@param name string
---@param cbs table<string, fun()>?
function M.run_hook(name, cbs)
    local payload = {
        opts = {
            action = {
                count = S.action.count,
                register = S.action.register,
                operator = S.action.operator,
                remap = S.action.remap,
                regtype = S.action.regtype,
            },
            restore = type(S.restore) == 'table',
            window_restore = S.window_restore,
            recursive = S.recursive == true,
            jumplist = S.jumplist == true,
        },
        fn = cbs,
    }

    -- transform camel case into snake case
    local transformed = name:gsub('(%u%l*)', '_%1'):sub(2):lower()

    if S.hooks and S.hooks[transformed] then
        S.hooks[transformed](payload)
    end

    U.exec_au(name, payload)
end

return M
