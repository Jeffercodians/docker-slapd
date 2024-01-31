SOURCES := bin/entrypoint.bash $(wildcard lib/*.bash)
PASSED_TESTS := $(SOURCES:.bash=.bats.pass)

INSTALL_PREFIX := ./target

%.bats.pass: %.bats %.bash
	bats $< && touch $@

all: test

test: $(PASSED_TESTS)

install: all
	mkdir -p $(INSTALL_PREFIX)/bin
	mkdir -p $(INSTALL_PREFIX)/lib
	mkdir -p $(INSTALL_PREFIX)/config
	install bin/*.bash $(INSTALL_PREFIX)/bin
	install lib/*.bash $(INSTALL_PREFIX)/lib
	install config/* $(INSTALL_PREFIX)/config

clean:
	rm -rf $(PASSED_TESTS) $(INSTALL_PREFIX)
