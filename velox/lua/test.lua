----------------------------------------------------------------
---Test


local ltn12 = require 'ltn12'
local utils = require 'velox.lua.utils'
local push = table.insert
local type = type
local pcall = pcall
local pairs = pairs
local unpack = unpack or table.unpack
local setmetatable = setmetatable
local get_body_as_table = utils.get_body_as_table
local assert_status = utils.assert_status
local assert_body = utils.assert_body
local assert_header = utils.assert_header
local table_to_string = utils.table_to_string

local _M = {}
--- Initialize a new `Test` with the given `method` and `url`
-- @tparam string method
-- @tparam number url
-- @treturn Test
function _M.new(method, url)
    local mod = {
        method = method,
        url = url,
        headers = {},
        _headers = {},
        _certificate = nil,
        _key = nil,
        _ca = nil,
        _body = nil,
        _asserts = {},
    }
    return setmetatable(mod, { __index = _M })
end

--- Send `body` as the request body
--- Example:
---       request.post('/user')
---         .send({ name: 'tj' })
---         .end(callback)
-- @tparam table self Reference to module instance
-- @param body
-- @treturn table self
function _M.send(self, body)
    local type_body, table_body = get_body_as_table(body)
    body = table_body
    local is_table = type_body == 'table'
    local type_content = self._headers['content-type']
    if is_table and not self._body then
        self._body = {}
    end
    if is_table and type(self._body) == 'table' then
        for key, v in pairs(body) do
            self._body[key] = v
        end
    elseif type_body == 'string' then
        if type_content == 'application/x-www-form-urlencoded' then
            self._body = self._body and self._body .. '&' .. body or body
        else
            local _body = (self._body or '')
            _body = type(_body) == 'table' and utils.table_to_string(_body) or _body
            self._body = _body .. body
        end
    else
        self._body = body
    end
    return self
end

--- Set header `field` to `val`, or multiple fields with one object.
---Examples:
---
---      req.get('/')
---        .set('Accept', 'application/json')
---        .set('X-API-Key', 'foobar')
---        .end(callback);
---
---      req.get('/')
---        .set({ Accept: 'application/json', 'X-API-Key': 'foobar' })
---        .end(callback);
-- @tparam table self Reference to module instance
-- @param field
-- @tparam string value
-- @treturn table self
function _M.set(self, field, value)
    if type(field) == 'table' then
        for key, header in pairs(field) do
            self:set(key, header)
        end
        return self
    end
    self.headers[field] = value
    self._headers[field:lower()] = value
    return self
end

--- Set certificate file path
-- @tparam table self Reference to module instance
-- @tparam string certificate
-- @treturn table self
function _M.cert(self, certificate)
    self._certificate = certificate
    return self
end

--- Set key file path
-- @tparam table self Reference to module instance
-- @tparam string key
-- @treturn table self
function _M.key(self, key)
    self._key = key
    return self
end

--- Set ca file path
-- @tparam table self Reference to module instance
-- @tparam string ca
-- @treturn table self
function _M.ca(self, ca)
    self._ca = ca
    return self
end

--- Expectations
---Examples:
--- .expect(200)
--- .expect('Some body')
--- .expect('Content-Type', 'application/json')
-- @tparam table self Reference to module instance
-- @param a
-- @param b
-- @treturn self
function _M.expect(self, a, b)
    if type(a) == "number" then
        push(self._asserts, assert_status(a))
        if b then
            push(self._asserts, assert_body(b))
        end
        return self
    end
    if b and (type(b) == "string" or type(b) == "number") then
        push(self._asserts, assert_header({ name = a, value = b }))
        return self
    end
    push(self._asserts, assert_body(a))
    return self
end

-- @tparam table self Reference to module instance
-- @tparam table res
-- @treturn table error
function _M.assert(self, res)
    local e = {}
    for _, assert in pairs(self._asserts) do
        local ok, err = pcall(assert, res)
        if not ok then
            push(e, err)
        end
    end
    return e
end

--- End Request
-- @tparam table self Reference to module instance
-- @param  fn(res, err)
function _M.end_req(self, fn)
    local response_body = {}
    local str_body = table_to_string(self._body)
    local content_length = str_body:len()
    self._headers['content-length'] = content_length
    local request = {
        url = self.url,
        method = self.method,
        headers = self._headers,
        source = ltn12.source.string(str_body),
        sink = ltn12.sink.table(response_body),
        key = self._key,
        certificate = self._certificate,
        ca = self._ca
    }
    local is_https = self.url:find('^https:')
    local protocol = is_https and require("ssl.https") or require('socket.http')
    local r, c, h, s = protocol.request(request)
    local err = self:assert({ headers = h, status = c, body = response_body })
    err = unpack(err)
    fn({ code = c, headers = h, status = s }, err)
end
return _M