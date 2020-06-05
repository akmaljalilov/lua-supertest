lint:
	luacheck .

luarocks: lint
	sudo luarocks make supertest-*.rockspec
