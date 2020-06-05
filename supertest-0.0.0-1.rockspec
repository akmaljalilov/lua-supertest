package = 'supertest'
version = '0.0.0-1'
source = {
  branch = "master"
}
description = {
  summary = 'Lua super test',
  detailed = [[

  ]],
}

dependencies = {
  'lua >= 5.1',
  'luasec',
  'luasocket',
}
build = {
  type = 'builtin',
  modules = {
    ["vleox.lua.status_codes"]    = "vleox/lua/status_codes.lua",
    ["vleox.lua.supertest"]       = "vleox/lua/supertest.lua",
    ["vleox.lua.test"]            = "vleox/lua/test.lua",
    ["vleox.lua.utils"]           = "vleox/lua/utils.lua",
  }
}