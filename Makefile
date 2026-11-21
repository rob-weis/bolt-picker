# Bolt Picker: build helpers. Requires Xcode and XcodeGen (brew install xcodegen).
APP_NAME := Bolt Picker
BUILD_DIR := build
APP := $(BUILD_DIR)/Build/Products/Release/$(APP_NAME).app

.PHONY: generate test build install run clean

generate:
	xcodegen generate

test: generate
	xcodebuild -project BoltPicker.xcodeproj -scheme BoltPicker -derivedDataPath $(BUILD_DIR) test

build: generate
	xcodebuild -project BoltPicker.xcodeproj -scheme BoltPicker -configuration Release -derivedDataPath $(BUILD_DIR) build

install: build
	-osascript -e 'quit app "$(APP_NAME)"'
	rm -rf "/Applications/$(APP_NAME).app"
	cp -R "$(APP)" /Applications/
	open "/Applications/$(APP_NAME).app"

run: build
	open "$(APP)"

clean:
	rm -rf $(BUILD_DIR) BoltPicker.xcodeproj
