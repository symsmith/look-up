.PHONY: build test app dist icon run preview install clean

build:
	swift build

test:
	swift test

app:
	scripts/build-app.sh

dist: app
	scripts/package.sh

icon:
	rm -rf build/AppIcon.iconset
	swift scripts/make-icon.swift build/AppIcon.iconset
	iconutil -c icns build/AppIcon.iconset -o Resources/AppIcon.icns

run: app
	open build/LookUp.app

preview: app
	build/LookUp.app/Contents/MacOS/LookUp --preview-break

install: app
	rm -rf /Applications/LookUp.app
	cp -R build/LookUp.app /Applications/LookUp.app

clean:
	rm -rf .build build
