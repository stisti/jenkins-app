# -*- makefile-gmake -*-

UNZIP = unzip

test: test-main
	@echo
	@echo "*** ALL TESTS PASSED"

test-main:
	$(UNZIP) -l Jenkins_*.zip | grep main.scpt
