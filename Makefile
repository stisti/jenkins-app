# -*- makefile-gmake -*-

UNZIP = unzip

test: test-main
	@echo
	@echo "*** ALL TESTS PASSED"

test-main:
	$(UNZIP) -l Jenkins.zip | grep main.scpt
