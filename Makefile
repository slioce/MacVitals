APP := build/Build/Products/Release/MacVitals.app
XCODEBUILD := xcodebuild -project MacVitals.xcodeproj -scheme MacVitals -destination generic/platform=macOS -derivedDataPath build

.PHONY: build run install test icon archive clean

# Release build, signed to run locally unless Config/Local.xcconfig sets a team.
build:
	@$(XCODEBUILD) -configuration Release build -quiet
	@echo "Built $(APP) ($$(du -sh $(APP) | cut -f1))"

run: build
	@pkill -x MacVitals || true
	@open $(APP)

install: build
	@pkill -x MacVitals || true
	@rm -rf /Applications/MacVitals.app
	@cp -R $(APP) /Applications/
	@open /Applications/MacVitals.app
	@echo "Installed /Applications/MacVitals.app"

test:
	@swift test --package-path MacVitalsCore

icon:
	@swift scripts/make-icon.swift MacVitals/Resources/Assets.xcassets/AppIcon.appiconset

# App Store archive; needs DEVELOPMENT_TEAM in Config/Local.xcconfig. Upload from Xcode's Organizer.
archive:
	@$(XCODEBUILD) -configuration Release archive -archivePath build/MacVitals.xcarchive
	@open build/MacVitals.xcarchive

clean:
	@rm -rf build
