install:
	ln -s $(realpath ./export-drawio.sh) /usr/local/bin/export-drawio

install_bats:
	git submodule add https://github.com/bats-core/bats-core.git test/bats
	git submodule add https://github.com/bats-core/bats-support.git test/test_helper/bats-support
	git submodule add https://github.com/bats-core/bats-assert.git test/test_helper/bats-assert

test:
	./test/bats/bin/bats --verbose-run test/*.bats