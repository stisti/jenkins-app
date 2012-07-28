# -*- makefile-gmake -*-
# Makefile for Jenkins.app

ifeq ($(BUILD_NUMBER),)
BUILD_NUMBER = 0
$(warning No BUILD_NUMBER defined in environment, using 0)
endif
ifeq ($(CODESIGNCERT),)
$(warning No CODESIGNCERT defined in environment, codesign will be skipped)
CODESIGN = :
else
CODESIGN = codesign
endif
.PHONY: zip app

all: zip

zip: Jenkins_$(BUILD_NUMBER).zip

Jenkins_$(BUILD_NUMBER).zip: Jenkins.app
	zip -r $@ $^

app: Jenkins.app

Jenkins.app: .skeleton_copied \
     Jenkins.app/Contents/Info.plist \
     Jenkins.app/Contents/Resources/Scripts/main.scpt \
     Jenkins.app/Contents/Resources/utils.scpt
	$(CODESIGN) -fs "$(CODESIGNCERT)" Jenkins.app
     
Jenkins.app/Contents/Info.plist: .skeleton_copied Info.plist
	sed -e 's/@BUILD_NUMBER@/$(BUILD_NUMBER)/' Info.plist > $@

Jenkins.app/Contents/Resources/Scripts/main.scpt: .skeleton_copied main.applescript
	mkdir -p Jenkins.app/Contents/Resources/Scripts
	osacompile -o $@ main.applescript

Jenkins.app/Contents/Resources/utils.scpt: .skeleton_copied utils.applescript
	osacompile -o $@ utils.applescript

.skeleton_copied:
	cp -r Jenkins.app-skeleton Jenkins.app
	touch $@
	
clean:
	rm -f .skeleton_copied
	rm -rf Jenkins.app
	rm -f Jenkins*.zip

UNZIP = unzip

test: test-main test-codesign
	@echo
	@echo "*** ALL TESTS PASSED"

test-main:
	$(UNZIP) -l Jenkins_*.zip | grep main.scpt
	
test-codesign:
	codesign -vv Jenkins.app

