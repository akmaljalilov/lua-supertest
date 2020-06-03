local http = require 'socket.http'
local ltn12 = require 'ltn12'
local json = require("cjson")
local push = table.insert
local type = type
local pcall = pcall
local error = error
local pairs = pairs
local unpack = unpack or table.unpack
local setmetatable = setmetatable
local status_code = { [100] = "Continue", [101] = "Switching Protocols", [102] = "Processing", [103] = "Early Hints", [200] = "OK", [201] = "Created", [202] = "Accepted", [203] = "Non-Authoritative Information", [204] = "No Content", [205] = "Reset Content", [206] = "Partial Content", [207] = "Multi-Status", [208] = "Already Reported", [226] = "IM Used", [300] = "Multiple Choices", [301] = "Moved Permanently", [302] = "Found", [303] = "See Other", [304] = "Not Modified", [305] = "Use Proxy", [307] = "Temporary Redirect", [308] = "Permanent Redirect", [400] = "Bad Request", [401] = "Unauthorized", [402] = "Payment Required", [403] = "Forbidden", [404] = "Not Found", [405] = "Method Not Allowed", [406] = "Not Acceptable", [407] = "Proxy Authentication Required", [408] = "Request Timeout", [409] = "Conflict", [410] = "Gone", [411] = "Length Required", [412] = "Precondition Failed", [413] = "Payload Too Large", [414] = "URI Too Long", [415] = "Unsupported Media Type", [416] = "Range Not Satisfiable", [417] = "Expectation Failed", [418] = "I'm a Teapot", [421] = "Misdirected Request", [422] = "Unprocessable Entity", [423] = "Locked", [424] = "Failed Dependency", [425] = "Too Early", [426] = "Upgrade Required", [428] = "Precondition Required", [429] = "Too Many Requests", [431] = "Request Header Fields Too Large", [451] = "Unavailable For Legal Reasons", [500] = "Internal Server Error", [501] = "Not Implemented", [502] = "Bad Gateway", [503] = "Service Unavailable", [504] = "Gateway Timeout", [505] = "HTTP Version Not Supported", [506] = "Variant Also Negotiates", [507] = "Insufficient Storage", [508] = "Loop Detected", [509] = "Bandwidth Limit Exceeded", [510] = "Not Extended", [511] = "Network Authentication Required" }
local function table_keys(table)
    local arr = {}
    for k in pairs(table) do
        push(arr, k)
    end
    return arr
end
local function get_type_body_and_table(str)
    local table, ok
    if type(str) == 'table' then
        return 'table', str
    elseif type(str) == 'string' then
        ok, table = pcall(json.decode, str)
        if not ok then
            return 'string', str
        else
            return 'table', table
        end
    end
    return '', {}
end

local function table_to_string(table)
    if type(table) == 'table' then
        return json.encode(table)
    end
    return table or '{}'
end

local function _assert_status(status)
    return function(res)
        if res.status ~= status then
            local st_code = status_code[status] or ''
            local rs_st_code = status_code[res.status] or ''
            error('expected ' .. status .. ' \'' .. st_code .. '\', got ' .. res.status .. ' \'' .. rs_st_code .. '\'')
        end
        return "success"
    end
end
local function _assert_body(body)
    return function(res)
        local err
        local type_res_body, res_body = get_type_body_and_table(res.body[1])
        if type_res_body == 'string' then
            if res_body ~= body then
                body = type(body) == 'table' and json.encode(body) or body
                err = 'expected body ' .. body .. ' to match ' .. res_body
            end
        elseif type_res_body == 'table' and type(body) == 'table' then
            if #table_keys(res_body) ~= #table_keys(body) then
                err = 'expected ' .. json.encode(body) .. ' response body, got ' .. json.encode(res_body)
            else
                for k, value in pairs(res_body) do
                    if body[k] ~= value then
                        err = 'expected ' .. json.encode(body) .. ' response body, got ' .. json.encode(res_body)
                        break
                    end
                end
            end
        else
            body = type(body) == 'table' and json.encode(body) or body
            res_body = type(res_body) == 'table' and json.encode(res_body) or res_body
            err = 'expected ' .. body .. ' response body, got ' .. res_body
        end
        return error(err)
    end
end
local function _assert_header(header)
    return function(res)
        local res_header = res.header
        local field = header.name:lower()
        local actual = res_header[field]
        if not actual then
            error('expected "' .. field .. '" header field')
        end
        if tostring(actual) == tostring(header.value) or actual == header.value then
            return 'success'
        else
            error('expected "' .. field .. '" of "' .. header.value .. '", got "' .. actual .. '"')
        end
    end
end
local _M = {}
function _M.new(method, url)
    local mod = {
        method = method,
        url = url,
        headers = {},
        _body = nil,
        _asserts = {},
    }
    return setmetatable(mod, { __index = _M })
end

function _M.send(self, body)
    local type_body, table_body = get_type_body_and_table(body)
    body = table_body
    local is_table = type_body == 'table'
    local type_content = self.headers['content-type']
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
            self._body = (self._body or '') .. body
        end
    else
        self._body = body
    end
    return self
end

function _M.set(self, field, value)
    if type(field) == 'table' then
        for key, header in pairs(field) do
            self:set(key, header)
        end
        return self
    end
    self.headers[field:lower()] = value
    return self
end

function _M.expect(self, a, b)
    if type(a) == "number" then
        push(self._asserts, _assert_status(a))
        if b then
            push(self._asserts, _assert_body(b))
        end
        return self
    end
    if b and (type(b) == "string" or type(b) == "number") then
        push(self._asserts, _assert_header({ name = a, value = b }))
        return self
    end
    push(self._asserts, _assert_body(a))
    return self
end
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
function _M.end_req(self, fn)
    local response_body = {}
    local str_body = table_to_string(self._body)
    local content_length = str_body:len()
    self.headers['Content-Length'] = content_length
    local r, c, h, s = http.request {
        url = self.url,
        method = self.method,
        headers = self.headers,
        source = ltn12.source.string(str_body),
        sink = ltn12.sink.table(response_body)
    }
    local err = self:assert({ header = h, status = c, body = response_body })
    err = unpack(err)
    fn({ code = c, header = h, status = s }, err)
end
return _M