## Contributing to Taskchamp

Thank you for considering contributing to Taskchamp! Please read the following guidelines before contributing.

Assign yourself to any issue that you would like to work on, or create a new one! If you have any questions, feel free to ask in the issue itself.

### Getting the code

> [!IMPORTANT]
> Taskchamp depends on the [taskchampion-swift](https://github.com/marriagav/task-champion-swift) rust library for interacting with the taskchampion backend and syncing services. Contribute there if you want to make changes to the sync/database part of the app.

1. Clone the repo: Clone the repo to your local machine and checkout the `dev` branch.

2. Create a new branch: You should always work on a new branch on your fork, that **should be branched off from the `dev` branch**.

3. Before being able to install the dependencies, you need to have a couple of things installed on your system:

This project is built using Swift, Rust for the taskchampion-swift binary, and Mise + [Tuist](https://tuist.dev/). You can install the dependencies by running the following commands:

```
brew install swiftlint
brew install swiftformat
brew install mise
curl https://sh.rustup.rs -sSf | sh -s -- -y
```

5. To start working on the project:
   1. Navigate to the root of the project and run `mise install`
   2. Run `make up`:
   - This will install the [taskchampion-swift](https://github.com/marriagav/task-champion-swift) rust binary
   - It will also install all the swift/xcode dependencies
   - Finally, it will generate the xcode project and open it in xcode.

6. Make your changes: Make your changes to the codebase. Make sure that the project builds correctly and does not have any lint warnings.

7. Run the tests: Make sure that the tests pass by running `make test`.

   > We currently do not have any tests, but we are working on adding them. Or you can add some yourself under `taskchamp/Tests` :)

8. Commit your changes: Commit your changes to your branch and make a pull request to the `dev` branch of the upstream repository.

   > Any changes to the `main` or any other branch will be rejected. All changes should be made to the `dev` branch.

9. Code review: Your pull request will be reviewed by the maintainers. Make sure to address any comments that are made on your pull request.

10. Merge: Once your pull request is approved, it will be merged into the `dev` branch. The `release` branch will be updated with the `dev` branch and it will be released for beta testing.

11. Beta testing: The beta version will be released for testing. Make sure to test the beta version and report any issues that you find.

    > You can join the beta by going to the [TestFlight page](https://testflight.apple.com/join/K4wrKrzg).

12. Release: Once the beta version is stable, it will be merged into `main` and released to the App Store.
