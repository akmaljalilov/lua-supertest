-------------------------------------------------
---Utils Super Test
local json = require("cjson")
local status_codes = require('velox.lua.status_codes')
local push = table.insert
local type = type
local pcall = pcall
local error = error
local pairs = pairs
local tostring = tostring

--- Get Table keys
--@tparam table table
--@treturn table keys
local function table_keys(table)
    local arr = {}
    for k in pairs(table) do
        push(arr, k)
    end
    return arr
end

--- Get type and table response body
--@tparam any data
--@treturn type and table
local function get_body_as_table (data)
    local table, ok
    if type(data) == 'table' then
        return 'table', data
    elseif type(data) == 'string' then
        ok, table = pcall(json.decode, data)
        if not ok then
            return 'string', data
        else
            return 'table', table
        end
    end
    return type(data), data
end

--- Parse table to string
--@tparam table table
--@treturn string
local function table_to_string (table)
    if type(table) == 'table' then
        return json.encode(table)
    end
    return table or '{}'
end

--- Perform assertions on the response status and return an Error upon failure.
--@tparam number status
--@treturn ?erorr
local function assert_status  (status)
    return function(res)
        if res.status ~= status then
            local st_code = status_codes[status] or ''
            local rs_st_code = status_codes[res.status] or ''
            error('expected ' .. status .. ' \'' .. st_code .. '\', got ' .. res.status .. ' \'' .. rs_st_code .. '\'')
        end
        return "success"
    end
end

--- Perform assertions on a response body and return an Error upon failure.
--@tparam table body
--@treturn ?erorr
local function assert_body (body)
    return function(res)
        local err
        local type_res_body, res_body = get_body_as_table(res.body[1])
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
        return err and error(err) or 'success'
    end
end


--- Perform assertions on a response header and return an Error upon failure.
--@tparam table header
--@treturn ?erorr
local function assert_header(header)
    return function(res)
        local res_headers = res.headers
        local field = header.name:lower()
        local actual = res_headers[field]
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

return {
    assert_header = assert_header,
    assert_status = assert_status,
    assert_body = assert_body,
    table_keys = table_keys,
    get_body_as_table = get_body_as_table,
    table_to_string = table_to_string
}