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
test:
	mise exec -- tuist test <Scheme>
graph:
	mise exec -- tuist graph
debug:
	mise exec -- tuist build -- -configuration Debug
download_metadata:
	fastlane deliver download_metadata
download_screenshots:
	fastlane deliver download_screenshots
lint:
	swiftlint taskchamp/Sources
	swiftlint taskchampWidget/Sources
	swiftlint taskchampShared/Sources
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
