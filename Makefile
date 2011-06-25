# -*- makefile-gmake -*-

UNZIP = unzip

test: test-main test-codesign
	@echo
	@echo "*** ALL TESTS PASSED"

test-main:
	$(UNZIP) -l Jenkins.zip | grep main.scpt

test-codesign:
	codesign -v Jenkins.app
