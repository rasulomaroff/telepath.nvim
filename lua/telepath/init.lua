local M = {}

---@alias telepath.RemoteParams { restore?: boolean, recursive?: boolean }
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
