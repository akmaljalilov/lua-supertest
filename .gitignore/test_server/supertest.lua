local test = require("Test")
local methods = { 'get',
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
                  'connect' }

local function method_func(method, URL)
    return function(_, url)
        URL = URL .. url
        return test.new(method:upper(), URL)
    end
end

local _M = {}
function _M.new(host, port)
    port = port and ':' .. port or ''
    local url = host .. port
    for _, method in pairs(methods) do
        _M[method] = method_func(method, url)
    end
    return setmetatable({}, {
        __index = _M,
    })
end
return _M