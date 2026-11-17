edit:
	mise exec -- tuist edit
install:
	mise exec -- tuist install
generate:
	mise exec -- tuist generate
build:
	mise exec -- tuist build
run:
	mise exec -- tuist run <App>
clean:
	mise exec -- tuist clean
# Generates the normal workspace and runs the tests with xcodebuild. `tuist test` is avoided because it
# rewrites taskchamp.xcworkspace for testing, which can leave Xcode without a runnable scheme.
# Override the simulator with e.g. `make test TEST_DESTINATION="platform=iOS Simulator,name=iPhone 17"`.
TEST_DESTINATION ?= platform=iOS Simulator,name=iPhone 17 Pro
test:
	mise exec -- tuist generate --no-open
	xcodebuild test -workspace taskchamp.xcworkspace -scheme taskchamp -destination "$(TEST_DESTINATION)" -quiet
graph:
	mise exec -- tuist graph
debug:
	mise exec -- tuist build -- -configuration Debug
download_metadata:
	fastlane deliver download_metadata
download_screenshots:
	fastlane deliver download_screenshots
lint:
	swiftlint taskchamp/Sources --quiet
	swiftlint taskchampWidget/Sources --quiet
	swiftlint taskchampShared/Sources --quiet
format:
	swiftformat taskchamp/Sources
	swiftformat taskchampWidget/Sources
	swiftformat taskchampShared/Sources
clone_taskchampion:
	git clone https://github.com/marriagav/task-champion-swift.git
build_taskchampion:
	./scripts/build_taskchampion_swift.sh
build_taskchampion_ci:
	./scripts/build_taskchampion_swift.sh --skip-sim
up:
	make build_taskchampion
	make install
	make generate
