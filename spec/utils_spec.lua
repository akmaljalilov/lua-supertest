require("busted.runner")()
local utils = require('velox.lua.utils')
describe('Spec util', function()
    it('table_keys', function()
        local table = {
            name = "Name User",
            age = "10"
        }
        local arr = utils.table_keys(table)
        assert.same(#arr, 2)
    end)
    it('get_body_as_table', function()
        local str = '{"name": "Name User","age": "10"}'
        local type, table_b = utils.get_body_as_table(str)
        assert.same(type, 'table')
        assert.same(table_b.name, 'Name User')
        assert.same(table_b.age, '10')
        str = "Hello Lua"
        type, table_b = utils.get_body_as_table(str)
        assert.same(type, 'string')
        assert.same(table_b, 'Hello Lua')
        str = {
            name = "Name User",
            age = "10"
        }
        type, table_b = utils.get_body_as_table(str)
        assert.same(type, 'table')
        assert.same(table_b.name, 'Name User')
        assert.same(table_b.age, '10')
    end)
    it('table_to_string', function()
        local table = {
            name = "Name User"
        }
        local arr = utils.table_to_string(table)
        assert.same(arr, '{"name":"Name User"}')
    end)
    it('assert_status', function()
        local fn = utils.assert_status(200)
        local res = { status = 200 }
        local ok = pcall(fn, res)
        assert.is_true(ok)
        res = { status = 400 }
        ok = pcall(fn, res)
        assert.is_false(ok)
    end)
    it('assert_body', function()
        local fn = utils.assert_body({name = "Name User" })
        local res = { body = { '{"name":"Name User"}' } }
        local ok = pcall(fn, res)
        local err = ''
        assert.is_true(ok)
        res = { body = { '{"name":"Name"}' } }
        ok, err = pcall(fn, res)
        assert.is_false(ok)
        assert.same(err:match('expected {"name":"Name User"} response body, got {"name":"Name"}'),
                'expected {"name":"Name User"} response body, got {"name":"Name"}')
        res = { body = { '{"age":"10"}' } }
        ok, err = pcall(fn, res)
        assert.same(err:match('expected {"name":"Name User"} response body, got {"age":"10"}'),
                'expected {"name":"Name User"} response body, got {"age":"10"}')
        assert.is_false(ok)
        fn = utils.assert_body("body")
        res = { body = { 'body' } }
        ok = pcall(fn, res)
        assert.is_true(ok)
        res = { body = { 'body 1' } }
        ok, err = pcall(fn, res)
        assert.is_false(ok)
        assert.same(err:match('expected body body to match body 1'),
                'expected body body to match body 1')
    end)
    it('assert_header', function()
        local header = { name = 'Content-Type', value = 'application/json; charset=utf-8' }
        local res = {headers = { ['content-type'] = 'application/json; charset=utf-8' }}
        local fn = utils.assert_header(header)
        local ok = pcall(fn, res)
        assert.is_true(ok)
        header = { name = 'Content-Type', value = 'application/json; charset=utf-8' }
        res = {headers = { ['content-type'] = 'application/xml; charset=utf-8' }}
        fn = utils.assert_header(header)
        ok = pcall(fn, res)
        assert.is_false(ok)
        res = {headers = { ['content'] = 'application/xml; charset=utf-8' }}
        fn = utils.assert_header(header)
        ok = pcall(fn, res)
        assert.is_false(ok)
    end)
end)