edit:
	mise exec -- tuist edit
install:
	mise exec -- tuist install
generate:
	./scripts/build_taskchampion_swift.sh
	mise exec -- tuist generate
generate-ci:
	./scripts/build_taskchampion_swift.sh --skip-sim
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
