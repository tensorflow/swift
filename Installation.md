# Install Swift for TensorFlow

To install Swift for TensorFlow, download one of the packages below and follow the instructions for your operating system. After installation, you can use the full suite of Swift tools, including `swift` (Swift REPL/interpreter) and `swiftc` (Swift compiler). See [here](Usage.md) for more details about using Swift for TensorFlow.

**Note:** If you want to modify the Swift for TensorFlow source code or build with a custom version of TensorFlow, see [here](https://github.com/google/swift/blob/tensorflow/README.md) for instructions on building from source.

**Note:** Swift for TensorFlow is an early stage research project. It has been released to enable open source development and is not yet ready for general use by machine learning developers.

## Pre-built Packages

Packages will be released nightly after automated building is set up.

| Download | Date |
|---------------|--------|
| [Xcode](https://storage.googleapis.com/tensorflow/swift/mac/swift-tensorflow-DEVELOPMENT-2018-04-26-a-osx.pkg) | April 26, 2018  |
| [Ubuntu 16.04](https://storage.googleapis.com/tensorflow/swift/ubuntu16.04/swift-tensorflow-DEVELOPMENT-2018-04-26-a-ubuntu16.04.tar.gz) | April 26, 2018  |
| [Ubuntu 14.04](https://storage.googleapis.com/tensorflow/swift/ubuntu14.04/swift-tensorflow-DEVELOPMENT-2018-04-26-a-ubuntu14.04.tar.gz) | April 26, 2018 |

**Note:** Currently, the Xcode toolchains above only support macOS development. iOS/tvOS/watchOS are not supported.

# Using Downloads

## MacOS

### Requirements

* macOS 10.12.4 or later
* Xcode 9.0 beta or later

### Installation

1. Download the latest package release.

2. Run the package installer, which will install an Xcode toolchain into `/Library/Developer/Toolchains/`.

3. An Xcode toolchain (`.xctoolchain`) includes a copy of the compiler, lldb, and other related tools needed to provide a cohesive development experience for working in a specific version of Swift.

4. Open Xcode’s `Preferences`, navigate to `Components > Toolchains`, and select the installed Swift for TensorFlow toolchain.

5. Xcode uses the selected toolchain for building Swift code, debugging, and even code completion and syntax coloring. You’ll see a new toolchain indicator in Xcode’s toolbar when Xcode is using a Swift toolchain. Select the Xcode toolchain to go back to Xcode’s built-in tools.

<span align="center">
  <img src="docs/images/Installation-XcodePreferences.png?raw=true" alt="Select toolchain in Xcode preferences."/>
</span>

6. Selecting a Swift toolchain affects the Xcode IDE only. To use the Swift toolchain with command-line tools, add the Swift toolchain to your path as follows:

```
$ export PATH=/Library/Developer/Toolchains/swift-latest/usr/bin:"${PATH}"
```

## Linux

Packages for Linux are tar archives including a copy of the Swift compiler, lldb, and related tools. You can install them anywhere as long as the extracted tools are in your PATH.
Note that nothing prevents Swift from being ported to other Linux distributions beyond the ones mentioned below. These are only the distributions where these binaries have been built and tested.

### Requirements

* Ubuntu 14.04 or 16.04 (64-bit)

### Supported Target Platforms

* Ubuntu 14.04 or 16.04 (64-bit)

### Installation

1. Install required dependencies:

```
$ sudo apt-get install clang libicu-dev libpython-dev libncurses5-dev
```

2. Download the latest binary release above.

The `swift-tensorflow-<VERSION>-<PLATFORM>.tar.gz` file is the toolchain itself.

3. Extract the archive with the following command:

```
$ tar xzf swift-tensorflow-<VERSION>-<PLATFORM>.tar.gz
```

This creates a `usr/` directory in the location of the archive.

4. Add the Swift toolchain to your path as follows:

```
$ export PATH=$(pwd)/usr/bin:"${PATH}"
```

You can now execute the `swift` command to run the REPL or build Swift projects.

**Note**: when running the REPL on Ubuntu, you must manually specify the include path to `clang` headers:

```
swift -I/<path-to-toolchain>/usr/lib/swift/clang/include
```

This is a necessary workaround for [SR-5524](https://bugs.swift.org/browse/SR-5524), a bug causing modulemap imports to fail in the REPL.
