SOURCES := $(wildcard lib/*.bash) bin/entrypoint.bash
PASSED_TESTS := $(SOURCES:.bash=.bats.pass)

INSTALL_PREFIX := ./target

%.bats.pass: %.bats %.bash
	bats $< && touch $@

all: test

test: $(PASSED_TESTS)

install: all
	mkdir -p $(INSTALL_PREFIX)/bin
	mkdir -p $(INSTALL_PREFIX)/lib
	install bin/*.bash $(INSTALL_PREFIX)/bin
	install lib/*.bash $(INSTALL_PREFIX)/lib

clean:
	rm -rf $(PASSED_TESTS) $(INSTALL_PREFIX)
