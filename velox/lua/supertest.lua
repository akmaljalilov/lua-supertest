-------------------------------------------------------------
--- Super Test
local test = require("velox.lua.test")
local setmetatable = setmetatable
local pairs = pairs
local methods = {
    'get',
    'post',
    'put',
    'head',
    'delete',
    'options',
    'trace',
    'copy',
    'lock',
    'mkcol',
    'move',
    'purge',
    'propfind',
    'proppatch',
    'unlock',
    'report',
    'mkactivity',
    'checkout',
    'merge',
    'm-search',
    'notify',
    'subscribe',
    'unsubscribe',
    'patch',
    'search',
    'connect'
}

---
-- @tparam string method
-- @tparam string URL
-- @treturn test
local function method_func(method, URL)
    return function(_, url)
        URL = URL .. url
        return test.new(method:upper(), URL)
    end
end

local _M = {}

--- New Super Test
-- @tparam string host
-- @tparam number port
-- @treturn supertest
function _M.new(host, port)
    port = port and ':' .. port or ''
    local url = host .. port
    local mod = {}
    for _, method in pairs(methods) do
        mod[method] = method_func(method, url)
    end
    return setmetatable(mod, { __index = _M })
end
return _M