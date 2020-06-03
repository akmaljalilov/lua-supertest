package = 'supertest'
version = '0.0.0-1'
source = {
  url = "//github.com/ajalilov/lua-supertest",
  branch = "master"
}
description = {
  summary = 'Lua super test',
  detailed = [[

  ]],
}

dependencies = {
  'lua >= 5.1',
  'luasocket'
}
build = {
  type = 'builtin',
  modules = {
    ['client']    = 'client.lua',
    ['supertest'] = 'supertest.lua',
    ['Test']      = 'Test.lua',
  }
}