# Install Swift for TensorFlow

To install Swift for TensorFlow, download one of the packages below and follow the instructions for your operating system. After installation, you can use the full suite of Swift tools, including `swift` (Swift REPL/interpreter) and `swiftc` (Swift compiler). See [here](Usage.md) for more details about using Swift for TensorFlow.

**Note:**
- As a shortcut, see the [GCP section](#google-cloud-platform) for instructions
  on using a [Deep Learning VM image][dlvm] to spin up a pre-configured
  environment.
- If you want to modify the Swift for TensorFlow source code or build with a custom version of TensorFlow, see [here](https://github.com/apple/swift/blob/tensorflow/README.md) for instructions on building from source.
- Swift for TensorFlow is an early stage project. It has been released to enable open source development and is not yet ready for general use by machine learning developers.

## Releases

[Release notes for v0.11.0](https://docs.google.com/document/d/1aTP88ANmJoxpxHeMIdz7CskqSuDHIg3mVELjm0iBXXQ/edit?usp=sharing)

| Download | Version | Date |
|----------|---------|------|
| [Xcode 12](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.11/rc2/swift-tensorflow-RELEASE-0.11-osx.pkg) | v0.11 | August 11, 2020 |
| [Ubuntu 20.04 (CPU Only)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.11/rc2/swift-tensorflow-RELEASE-0.11-ubuntu20.04.tar.gz) | v0.11 | August 11, 2020 |
| [Ubuntu 18.04 (CPU Only)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.11/rc2/swift-tensorflow-RELEASE-0.11-ubuntu18.04.tar.gz) | v0.11 | August 11, 2020  |
| [Ubuntu 18.04 (CUDA 10.2)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.11/rc2/swift-tensorflow-RELEASE-0.11-cuda10.2-cudnn7-ubuntu18.04.tar.gz) | v0.11 | August 11, 2020  |
| [Ubuntu 18.04 (CUDA 10.1)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.11/rc2/swift-tensorflow-RELEASE-0.11-cuda10.1-cudnn7-ubuntu18.04.tar.gz) | v0.11 | August 11, 2020 |

<details>
  <summary>Older Packages</summary>

[Release notes for v0.10.0](https://docs.google.com/document/d/1_EeREdz8jZ44zGXY-5m2-1xcR9pOvMZf4kkHfUgNjD0/edit?usp=sharing)

| Download | Version | Date |
|----------|---------|------|
| [Xcode 11](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.10/rc1/swift-tensorflow-RELEASE-0.10-osx.pkg) | v0.10 | June 16, 2020 |
| [Ubuntu 18.04 (CPU Only)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.10/rc1/swift-tensorflow-RELEASE-0.10-ubuntu18.04.tar.gz) | v0.10 | June 16, 2020  |
| [Ubuntu 18.04 (CUDA 10.2)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.10/rc1/swift-tensorflow-RELEASE-0.10-cuda10.2-cudnn7-ubuntu18.04.tar.gz) | v0.10 | June 16, 2020  |
| [Ubuntu 18.04 (CUDA 10.1)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.10/rc1/swift-tensorflow-RELEASE-0.10-cuda10.1-cudnn7-ubuntu18.04.tar.gz) | v0.10 | June 16, 2020 |


[Release notes for v0.9.0](https://docs.google.com/document/d/1Sk3F_owEF0wAo26xO1RTbdSbQV9eb5tMKQX3EgLeD1o/edit?usp=sharing)

| Download | Version | Date |
|----------|---------|------|
| [Xcode 11](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.9/rc2/swift-tensorflow-RELEASE-0.9-osx.pkg) | v0.9 | May 08, 2020 |
| [Ubuntu 18.04 (CPU, TPU)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.9/rc1/swift-tensorflow-RELEASE-0.9-ubuntu18.04.tar.gz) | v0.9 | Apr 30, 2020  |
| [Ubuntu 18.04 (CPU, CUDA 10.2, TPU)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.9/rc1/swift-tensorflow-RELEASE-0.9-cuda10.2-cudnn7-ubuntu18.04.tar.gz) | v0.9 | Apr 30, 2020  |
| [Ubuntu 18.04 (CPU, CUDA 10.1, TPU)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.9/rc1/swift-tensorflow-RELEASE-0.9-cuda10.1-cudnn7-ubuntu18.04.tar.gz) | v0.9 | Apr 30, 2020 |

[Release notes for v0.8.0](https://docs.google.com/document/d/1zjDwHBvIstW5Fp_08xM1VV24Dvt86ajC/edit#heading=h.2et92p0)

| Download | Version | Date |
|----------|---------|------|
| [Xcode 11](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.8/rc1/swift-tensorflow-RELEASE-0.8-osx.pkg) | v0.8 | Mar 17, 2020 |
| [Ubuntu 18.04 (CPU Only)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.8/rc1/swift-tensorflow-RELEASE-0.8-ubuntu18.04.tar.gz) | v0.8 | Mar 17, 2020 |
| [Ubuntu 18.04 (CUDA 10.1)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.8/rc1/swift-tensorflow-RELEASE-0.8-cuda10.1-cudnn7-ubuntu18.04.tar.gz) | v0.8 | Mar 17, 2020 |
| [Ubuntu 18.04 (CUDA 10.0)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.8/rc1/swift-tensorflow-RELEASE-0.8-cuda10.0-cudnn7-ubuntu18.04.tar.gz) | v0.8 | Mar 17, 2020 |
| [Ubuntu 18.04 (CUDA 9.2)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.8/rc1/swift-tensorflow-RELEASE-0.8-cuda9.2-cudnn7-ubuntu18.04.tar.gz) | v0.8 | Mar 17, 2020 |


[Release notes for v0.7.0](https://drive.google.com/file/d/1QdBFCyS1RstReztwVEGNJsLY8fHAPfxv/view?usp)

| Download | Version | Date |
|----------|---------|------|
| [Xcode 11](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.7/rc2/swift-tensorflow-RELEASE-0.7-osx.pkg) | v0.7.0 | Feb 12, 2020 |
| [Ubuntu 18.04 (CPU Only)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.7/rc2/swift-tensorflow-RELEASE-0.7-ubuntu18.04.tar.gz) | v0.7.0 | Feb 12, 2020 |
| [Ubuntu 18.04 (CUDA 10.1)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.7/rc2/swift-tensorflow-RELEASE-0.7-cuda10.1-cudnn7-ubuntu18.04.tar.gz) | v0.7.0 | Feb 12, 2020 |
| [Ubuntu 18.04 (CUDA 10.0)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.7/rc2/swift-tensorflow-RELEASE-0.7-cuda10.0-cudnn7-ubuntu18.04.tar.gz) | v0.7.0 | Feb 12, 2020|
| [Ubuntu 18.04 (CUDA 9.2)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.7/rc2/swift-tensorflow-RELEASE-0.7-cuda9.2-cudnn7-ubuntu18.04.tar.gz) | v0.7.0 | Feb 12, 2020 |

[Release notes for v0.6.0](https://docs.google.com/document/d/1LihPvZRzbncMZtXnhhWzUNWzI_FOFee_RgcyjLjh6Cs/edit)

| Download | Version | Date |
|----------|---------|------|
| [Xcode 11](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.6/rc1/swift-tensorflow-RELEASE-0.6-osx.pkg) | v0.6.0 | Dec 10, 2019 |
| [Ubuntu 18.04 (CPU Only)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.6/rc2/deduped/swift-tensorflow-RELEASE-0.6-ubuntu18.04.tar.gz) | v0.6.0 | Dec 10, 2019 |
| [Ubuntu 18.04 (CUDA 10.1)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.6/rc2/deduped/swift-tensorflow-RELEASE-0.6-cuda10.1-cudnn7-ubuntu18.04.tar.gz) | v0.6.0 | Dec 10, 2019 |
| [Ubuntu 18.04 (CUDA 10.0)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.6/rc2/deduped/swift-tensorflow-RELEASE-0.6-cuda10.0-cudnn7-ubuntu18.04.tar.gz) | v0.6.0 | Dec 10, 2019 |
| [Ubuntu 18.04 (CUDA 9.2)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.6/rc2/swift-tensorflow-RELEASE-0.6-cuda9.2-cudnn7-ubuntu18.04.tar.gz) | v0.6.0 | Dec 10, 2019 |

[Release notes for v0.5.0](https://docs.google.com/document/d/1p8daaIFswkOwbhmdwLJ7NRWzX0uY9jMZYRfRH0EymV8/edit)

| Download | Version | Date |
|----------|---------|------|
| [Xcode 11](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.5/rc1/swift-tensorflow-RELEASE-0.5-osx.pkg) | v0.5.0 | Sep 19, 2019 |
| [Ubuntu 18.04 (CPU Only)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.5/rc1/swift-tensorflow-RELEASE-0.5-ubuntu18.04.tar.gz) | v0.5.0 | Sep 19, 2019 |
| [Ubuntu 18.04 (CUDA 10.0)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.5/rc1/swift-tensorflow-RELEASE-0.5-cuda10.0-cudnn7-ubuntu18.04.tar.gz) | v0.5.0 | Sep 19, 2019 |
| [Ubuntu 18.04 (CUDA 9.2)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.5/rc1/swift-tensorflow-RELEASE-0.5-cuda9.2-cudnn7-ubuntu18.04.tar.gz) | v0.5.0 | Sep 19, 2019 |

| Download | Version | Date |
|----------|---------|------|
| [Xcode 11 beta](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.4/rc4/swift-tensorflow-RELEASE-0.4-osx.pkg) | v0.4.0 | July 25, 2019 |
| [Ubuntu 18.04 (CPU Only)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.4/rc4/swift-tensorflow-RELEASE-0.4-ubuntu18.04.tar.gz) | v0.4.0 | July 25, 2019 |
| [Ubuntu 18.04 (CUDA 10.0)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.4/rc4/swift-tensorflow-RELEASE-0.4-cuda10.0-cudnn7-ubuntu18.04.tar.gz) | v0.4.0 | July 25, 2019 |
| [Ubuntu 18.04 (CUDA 9.2)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.4/rc4/swift-tensorflow-RELEASE-0.4-cuda9.2-cudnn7-ubuntu18.04.tar.gz) | v0.4.0 | July 25, 2019 |

| Download | Version | Date |
|----------|---------|------|
| [Xcode 10](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.3.1/rc1/swift-tensorflow-RELEASE-0.3.1-osx.pkg) | v0.3.1 | April 30, 2019 |
| [Ubuntu 18.04 (CPU Only)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.3.1/rc1/swift-tensorflow-RELEASE-0.3.1-ubuntu18.04.tar.gz) | v0.3.1 | April 30, 2019 |
| [Ubuntu 18.04 (CUDA 10.0)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.3.1/rc1/swift-tensorflow-RELEASE-0.3.1-cuda10.0-cudnn7-ubuntu18.04.tar.gz) | v0.3.1 | April 30, 2019 |
| [Ubuntu 18.04 (CUDA 9.2)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.3.1/rc1/swift-tensorflow-RELEASE-0.3.1-cuda9.2-cudnn7-ubuntu18.04.tar.gz) | v0.3.1 | April 30, 2019 |

| Download | Version | Date |
|----------|---------|------|
| [Xcode 10](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.3/rc1/swift-tensorflow-RELEASE-0.3-osx.pkg) | v0.3 | April 23, 2019 |
| [Ubuntu 18.04 (CPU Only)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.3/rc1/swift-tensorflow-RELEASE-0.3-ubuntu18.04.tar.gz) | v0.3 | April 23, 2019 |
| [Ubuntu 18.04 (CUDA 10.0)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.3/rc1/swift-tensorflow-RELEASE-0.3-cuda10.0-cudnn7-ubuntu18.04.tar.gz) | v0.3 | April 23, 2019 |
| [Ubuntu 18.04 (CUDA 9.2)](https://storage.googleapis.com/swift-tensorflow-artifacts/releases/v0.3/rc1/swift-tensorflow-RELEASE-0.3-cuda9.2-cudnn7-ubuntu18.04.tar.gz) | v0.3 | April 23, 2019 |

| Download | Version | Date |
|----------|---------|------|
| [Xcode 10](https://storage.googleapis.com/s4tf-kokoro-artifact-testing/versions/v0.2/rc3/swift-tensorflow-RELEASE-0.2-osx.pkg) | v0.2 | March 1, 2019 |
| [Ubuntu 18.04 (CPU Only)](https://storage.googleapis.com/s4tf-kokoro-artifact-testing/versions/v0.2/rc3/swift-tensorflow-RELEASE-0.2-ubuntu18.04.tar.gz) | v0.2 | March 1, 2019 |
| [Ubuntu 18.04 (CUDA 10.0)](https://storage.googleapis.com/s4tf-kokoro-artifact-testing/versions/v0.2/rc3/swift-tensorflow-RELEASE-0.2-cuda10.0-cudnn7-ubuntu18.04.tar.gz) | v0.2 | March 1, 2019 |
| [Ubuntu 18.04 (CUDA 9.2)](https://storage.googleapis.com/s4tf-kokoro-artifact-testing/versions/v0.2/rc3/swift-tensorflow-RELEASE-0.2-cuda9.2-cudnn7-ubuntu18.04.tar.gz) | v0.2 | March 1, 2019 |

</details>

**Note:** We cannot build Ubuntu 20.04 toolchains with CUDA support until
[Ubuntu 20.04 Docker images with CUDNN](https://gitlab.com/nvidia/container-images/cuda/-/issues/83) are ready. In
the meantime, you may be able to run Ubuntu 18.04 toolchains on Ubuntu 20.04 using the tips in
[#512](https://github.com/tensorflow/swift/issues/512).

## Development Snapshots

| Download |
|----------|
| [Xcode 12 (September 16, 2020)](https://storage.googleapis.com/swift-tensorflow-artifacts/macos-toolchains/swift-tensorflow-DEVELOPMENT-2020-09-16-a-osx.pkg) |
| [Ubuntu 20.04 (CPU) (Nightly)](https://storage.googleapis.com/swift-tensorflow-artifacts/nightlies/latest/swift-tensorflow-DEVELOPMENT-ubuntu20.04.tar.gz) |
| [Ubuntu 18.04 (CPU) (Nightly)](https://storage.googleapis.com/swift-tensorflow-artifacts/nightlies/latest/swift-tensorflow-DEVELOPMENT-ubuntu18.04.tar.gz) |
| [Ubuntu 18.04 (CPU, CUDA 11.0) (Nightly)](https://storage.googleapis.com/swift-tensorflow-artifacts/nightlies/latest/swift-tensorflow-DEVELOPMENT-cuda11.0-cudnn8-ubuntu18.04.tar.gz) |
| [Ubuntu 18.04 (CPU, CUDA 10.2) (Nightly)](https://storage.googleapis.com/swift-tensorflow-artifacts/nightlies/latest/swift-tensorflow-DEVELOPMENT-cuda10.2-cudnn7-ubuntu18.04.tar.gz) |
| [Ubuntu 18.04 (CPU, CUDA 10.1) (Nightly)](https://storage.googleapis.com/swift-tensorflow-artifacts/nightlies/latest/swift-tensorflow-DEVELOPMENT-cuda10.1-cudnn7-ubuntu18.04.tar.gz) |
| [Windows (October 29, 2020)](https://storage.googleapis.com/azure-pipelines-storage/Swift%20for%20TensorFlow/Windows/s4tf-windows-x64-41368-20201029.1.exe) |

<details>
  <summary>Older Packages</summary>

### Xcode

#### Xcode 12

| Download |
|----------|
| [September 3, 2020](https://storage.googleapis.com/swift-tensorflow-artifacts/macos-toolchains/swift-tensorflow-DEVELOPMENT-2020-09-03-a-osx.pkg) |
| [August 26, 2020](https://storage.googleapis.com/swift-tensorflow-artifacts/macos-toolchains/swift-tensorflow-DEVELOPMENT-2020-08-26-a-osx.pkg) |
| [August 19, 2020](https://storage.googleapis.com/swift-tensorflow-artifacts/macos-toolchains/swift-tensorflow-DEVELOPMENT-2020-08-19-a-osx.pkg) |
| [August 18, 2020](https://storage.googleapis.com/swift-tensorflow-artifacts/macos-toolchains/swift-tensorflow-DEVELOPMENT-2020-08-18-a-osx.pkg) |
| [August 13, 2020](https://storage.googleapis.com/swift-tensorflow-artifacts/macos-toolchains/swift-tensorflow-DEVELOPMENT-2020-08-13-a-osx.pkg) |
| [August 5, 2020](https://storage.googleapis.com/swift-tensorflow-artifacts/macos-toolchains/swift-tensorflow-DEVELOPMENT-2020-08-05-a-osx.pkg) |
| [July 29, 2020](https://storage.googleapis.com/swift-tensorflow-artifacts/macos-toolchains/swift-tensorflow-DEVELOPMENT-2020-07-29-a-osx.pkg) |
| [July 16, 2020](https://storage.googleapis.com/swift-tensorflow-artifacts/macos-toolchains/swift-tensorflow-DEVELOPMENT-2020-07-16-a-osx.pkg) |
| [July 11, 2020](https://storage.googleapis.com/swift-tensorflow-artifacts/macos-toolchains/swift-tensorflow-DEVELOPMENT-2020-07-11-a-osx.pkg) |
| [July 2, 2020](https://storage.googleapis.com/swift-tensorflow-artifacts/macos-toolchains/swift-tensorflow-DEVELOPMENT-2020-07-02-a-osx.pkg) |

</details>

<br/>

**Note:** Currently, the Xcode toolchains above only support macOS development. iOS/tvOS/watchOS are not supported.

# Using Downloads

## macOS

### Requirements

* macOS 10.15 or later
* Xcode 12 beta 2 or later

### Installation

1. Download the latest package release.

2. Run the package installer, which will install an Xcode toolchain into `/Library/Developer/Toolchains/`.

3. An Xcode toolchain (`.xctoolchain`) includes a copy of the compiler, lldb, and other related tools needed to provide a cohesive development experience for working in a specific version of Swift.

4. Open Xcode's `Preferences`, navigate to `Components > Toolchains`, and select the installed Swift for TensorFlow toolchain.

5. Xcode uses the selected toolchain for building Swift code, debugging, and even code completion and syntax coloring. You'll see a new toolchain indicator in Xcode's toolbar when Xcode is using a Swift toolchain. Select the Xcode toolchain to go back to Xcode's built-in tools.

<p align="center">
  <img src="docs/images/Installation-XcodePreferences.png?raw=true" alt="Select toolchain in Xcode preferences."/>
</p>

6. Selecting a Swift toolchain affects the Xcode IDE only. To use the Swift toolchain with command-line tools, use `xcrun --toolchain swift` and `xcodebuild -toolchain swift`, or add the Swift toolchain to your path as follows:

    ```console
    $ export PATH=/Library/Developer/Toolchains/swift-latest/usr/bin:"${PATH}"
    ```

7. **CUDA-only**: If you downloaded a CUDA GPU-enabled toolchain, add the library path(s) for CUDA and cuDNN to `$LD_LIBRARY_PATH`:

    ```console
    $ export LD_LIBRARY_PATH=/usr/local/cuda/lib:"${LD_LIBRARY_PATH}"
    ```

## Linux

Packages for Linux are tar archives including a copy of the Swift compiler, lldb, and related tools. You can install them anywhere as long as the extracted tools are in your PATH.
Note that nothing prevents Swift from being ported to other Linux distributions beyond the ones mentioned below. These are only the distributions where these binaries have been built and tested.

### Requirements

* Ubuntu 18.04 (64-bit)

### Supported Target Platforms

* Ubuntu 18.04 (64-bit)

### Additional Requirements

* For GPU toolchains:
  * CUDA Toolkit 10.1 or 10.2
  * CuDNN 7.6.0 onwards (CUDA 10.1)
  * An NVIDIA GPU with compute compatibility 3.5, 3.7, 6.0, 6.1, 7.0, or 7.5.

For detailed instructons on setting up CUDA and CuDNN, please see the [TensorFlow Docs](https://www.tensorflow.org/install/gpu#install_cuda_with_apt).

### Installation

1. Install required dependencies:

```console
$ sudo apt-get install clang libpython-dev libblocksruntime-dev
```
(**Note:** You _may_ also need to install other [dependencies](https://github.com/apple/swift#linux), if you are unable to run `swift` or other tools below.)

2. Download the latest binary release above.

The `swift-tensorflow-<VERSION>-<PLATFORM>.tar.gz` file is the toolchain itself.

3. Extract the archive with the following command:

```console
$ tar xzf swift-tensorflow-<VERSION>-<PLATFORM>.tar.gz
```

This creates a `usr/` directory in the location of the archive.

4. Add the Swift toolchain to your path as follows:

```console
$ export PATH=$(pwd)/usr/bin:"${PATH}"
```

You can now execute the `swiftc` command to build Swift projects.

**Note:** If you are using a CUDA build and you have an NVIDIA GPU with a compute capability other than 3.5 or 7.0, then you will experience a ~10 minute delay the first time you execute a TensorFlow operation, while TensorFlow compiles kernels for your GPU's compute capability. The program will not print anything out and it will appear to be frozen.

## Windows

### Requirements

* Windows 10 October 2018 Update (RedStone 5 - 10.0.17763.0) or later<sup>[1](#windows-os-vers)</sup>
* Visual Studio 2017 or later (Visual Studio 2019 is recommended)
* CMake 3.16 or later

### Installation

1. Install Visual Studio from [Microsoft](https://visualstudio.microsoft.com).

  The following table lists the **required** set of installed components:

| Component | ID |
|-----------|----|
| MSVC v142 - VS 2019 C++ x64/x86 build tools (v14.25) | Microsoft.VisualStudio.Component.VC.Tools.x86.x64 |
| Windows Univeral C Runtime | Microsoft.VisualStudio.Component.Windows10SDK |
| Windows 10 SDK (10.0.17763.0)<sup>[2](#windows-sdk-version)</sup> | Microsoft.VisualStudio.Component.Windows10SDK.17763 |

  The following table lists the additional **recommended** set of installed components:

| Component | ID |
|-----------|----|
| C++ ATL for latest v142 build tools (x86 & x64)<sup>[3](#windows-atl)</sup> | Microsoft.VisualStudio.Component.VC.ATL |
| C++ CMake tools for Windows<sup>[4](#windows-cmake)</sup> | Microsoft.VisualStudio.Component.VC.CMake.Project |
| Git for Windows<sup>[5](#windows-git)</sup> | Microsoft.VisualStudio.Component.Git |
| Python 3 64-bit (3.7.5)<sup>[6](#windows-python)</sup> | Component.CPython.x64 |

2. Install CMake from [cmake](https://www.cmake.org).

3. Download and run the latest release from [Swift for TensorFlow](https://storage.googleapis.com/azure-pipelines-storage/Swift%20for%20TensorFlow/Windows/s4tf-windows-x64-27604-20200306.1.exe). The installer will install a toolchain into `%SystemDrive%\Library\Developer\Toolchains`. The toolchain (`.xctoolchain`) includes a copy of the compiler, lldb, and other related tools needed to provide a cohesive development experience for working in a specific version of Swift.

4. Deploy the Windows SDK modulemaps from an (elevated) "Administrator" `x64 Native Tools for VS2019 Command Prompt` shell<sup>[7](#windows-sdk-deploy)</sup>:

```cmd
:: NOTE: the following additional command may be required for older snapshots:
:: set SDKROOT=%SystemDrive%\Library\Developer\Platforms\Windows.platform\Developer\SDKs\Windows.sdk
copy "%SDKROOT%\usr\share\ucrt.modulemap" "%UniversalCRTSdkDir%\Include\%UCRTVersion%\ucrt\module.modulemap"
copy "%SDKROOT%\usr\share\visualc.modulemap" "%VCToolsInstallDir%\include\module.modulemap"
copy "%SDKROOT%\usr\share\visualc.apinotes" "%VCToolsInstallDir%\include\visualc.apinotes"
copy "%SDKROOT%\usr\share\winsdk.modulemap" "%UniversalCRTSdkDir%\Include\%UCRTVersion%\um\module.modulemap"
```

  <sup><a name="windows-os-vers">1</a></sup> You can check which version of Windows you are currently running by opening command prompt and entering `winver`.<br/>
  <sup><a name="windows-sdk-version">2</a></sup> You may install a newer SDK if you desire. 17763 is listed here to match the minimum Windows release supported.<br/>
  <sup><a name="windows-atl">3</a></sup> Needed for parts of lldb.<br/>
  <sup><a name="windows-cmake">4</a></sup> Provides `ninja` which is needed for building projects. You may download it from [ninja-build](https://github.com/ninja-build/ninja) instead.<br/>
  <sup><a name="windows-git">5</a></sup> Provides `git` to clone projects from GitHub. You may download it from [git-scm](https://git-scm.com/) instead.<br/>
  <sup><a name="windows-python">6</a></sup> Provides `python` needed for Python integration. You may download it from [python](https://www.python.org/) instead.<br/>
  <sup><a name="windows-sdk-deploy">7</a></sup> This will need to be re-run every time Visual Studio is updated. <br/>

# Google Cloud Platform

***Experimental***

To save on setup time, you can leverage one of the Swift for Tensorflow
[Deep Learning VM][dlvm] images to quickly spin up a pre-configured Ubuntu
instance with an installed toolchain. To view the available images (currently
experimental):

```
gcloud compute images list \
  --project deeplearning-platform-release \
  --no-standard-images | \
  grep swift
```

## CPU Instance

To create a small CPU instance:

```
gcloud compute instances create s4tf-ubuntu \
  --image-project=deeplearning-platform-release \
  --image-family=swift-latest-cpu-ubuntu-1804 \
  --maintenance-policy=TERMINATE \
  --machine-type=n1-standard-2 \
  --boot-disk-size=256GB
```

This will create a single `n1-standard-2` instance with the Swift
toolchain installed. Once the instance is up, connect to it:

```
gcloud compute ssh s4tf-ubuntu \
  --zone ${ZONE}
```

## GPU Instance

To create a GPU instance, the first step is to identify a zone that contains
the type of GPU you'd like to use, since not all zones have availability:

```
export GPU_TYPE="v100"
gcloud compute accelerator-types list | grep ${GPU_TYPE}
```

Using these results, set your zone:

```
export ZONE="us-west1-b"
```

To create an instance with an attached V100 GPU:

```
gcloud compute instances create s4tf-ubuntu-${GPU_TYPE} \
  --zone=${ZONE} \
  --image-project=deeplearning-platform-release \
  --image-family=swift-latest-gpu-ubuntu-1804 \
  --maintenance-policy=TERMINATE \
  --accelerator="type=nvidia-tesla-${GPU_TYPE},count=1" \
  --metadata="install-nvidia-driver=True" \
  --machine-type=n1-highmem-2 \
  --boot-disk-size=256GB
```

This will create a single `n1-highmem-2` instance with an attached accelerator
and the Swift toolchain installed with all CUDA libraries.

***Note:*** *If this command fails due to lack of quota, you will need to find
a zone with available quota or request an increase. Using the search feature in
the [Quotas section of the GCP Console][gcp_quotas], you can view your current
usage and submit an increase request (e.g. search for "V100" or the value you
used in `$GPU_TYPE`).*

Once the instance is up, connect to it:

```
gcloud compute ssh s4tf-ubuntu-${GPU_TYPE} \
  --zone ${ZONE}
```

# Verify the Installation

Create a text file `test.swift` with the following contents:

```swift
import TensorFlow
var x = Tensor<Float>([[1, 2], [3, 4]])
print(x + x)
```

## Run [swift-models](https://github.com/tensorflow/swift-models)

```sh
git clone https://github.com/tensorflow/swift-models.git
cd swift-models
swift run
```

Swift will print an error with a list of executable names that exercise different models.
Issue `swift run` *executable-name* to select the model you're interested in.

## To build on Linux/MacOS

Run these commands to verify the installation.
```console
$ swiftc test.swift
$ test
```

## To build on Windows
Run these commands to verify the installation.
```console
$ set SDKROOT=%SystemDrive%/Library/Developer/Platforms/Windows.platform/Developer/SDKs/Windows.sdk
$ swiftc -sdk %SDKROOT% -I %SDKROOT%/usr/lib/swift -L %SDKROOT%/usr/lib/swift/windows -emit-executable -o test.exe test.swift
$ test.exe
```
N.B. Interpreter mode and direct invocation from VS 2019 are currently not supported on Windows.

## Verify Output
If you see this output, you have successfully installed Swift for TensorFlow!
```console
[[2.0, 4.0],
 [6.0, 8.0]]
```

[dlvm]: https://cloud.google.com/ai-platform/deep-learning-vm/docs
[gcp_quotas]: https://console.cloud.google.com/iam-admin/quotas
