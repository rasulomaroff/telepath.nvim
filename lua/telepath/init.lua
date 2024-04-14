local M = {}

---@alias telepath.WindowRestoreParams { source?: boolean, rest?: boolean }
---@alias telepath.RemoteParams { restore?: boolean, recursive?: boolean, jumplist?: boolean, window_restore?: boolean | telepath.WindowRestoreParams, remap?: table<string, boolean | string> }
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
