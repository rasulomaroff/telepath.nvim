local M = {}

---@class telepath.HookPayload
---@field action { register: string, count: number, operator: string, regtype: string, remap?: string }
---@field restore boolean
---@field recursive boolean
---@field jumplist boolean
---@field window_restore telepath.WindowRestoreParams

---@class telepath.Hooks
---@field enter? fun(payload: { opts: telepath.HookPayload })
---@field leave? fun(payload: { opts: telepath.HookPayload })
---@field jump_pre? fun(payload: { opts: telepath.HookPayload })
---@field jump? fun(payload: { opts: telepath.HookPayload })
---@field window_restore_pre? fun(payload: { opts: telepath.HookPayload, fn: { cancel_window_restoration: fun() } })
---@field window_restore? fun(payload: { opts: telepath.HookPayload })
---@field restore_pre? fun(payload: { opts: telepath.HookPayload, fn: { cancel_restoration: fun() } })
---@field restore? fun(payload: { opts: telepath.HookPayload })

---@alias telepath.WindowRestoreStrategy 'view' | 'cursor'
---@alias telepath.WindowRestoreParams { source?: telepath.WindowRestoreStrategy, rest?: telepath.WindowRestoreStrategy }
---@alias telepath.RemoteParams { restore?: boolean, recursive?: boolean, jumplist?: boolean, window_restore?: boolean | telepath.WindowRestoreParams, remap?: table<string, boolean | string>, hooks?: telepath.Hooks }
---@alias telepath.MappingsParams { keys?: table<string>, overwrite?: boolean }

---@param ... telepath.RemoteParams
function M.remote(...)
    require('telepath.remote').remote(...)
end

---@param ... telepath.MappingsParams
function M.use_default_mappings(...)
    require('telepath.mappings').init(...)
end

return M
