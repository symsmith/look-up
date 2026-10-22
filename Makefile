.PHONY: build test app run preview install clean

build:
	swift build

test:
	swift test

app:
	scripts/build-app.sh

run: app
	open build/LookUp.app

preview: app
	build/LookUp.app/Contents/MacOS/LookUp --preview-break

install: app
	rm -rf /Applications/LookUp.app
	cp -R build/LookUp.app /Applications/LookUp.app

clean:
	rm -rf .build build
