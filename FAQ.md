# Frequently Asked Questions

This is a list of questions we frequently get and problems that are often encountered. 
Because this project is still in development, we have missing pieces that are commonly
encountered and prefer not to get new issues filed in our bug tracker.

* [Why Swift?](#why-swift)
* [How can I use Python 3 with the Python module?](#how-can-i-use-python-3-with-the-python-module)
* [\[Mac\] I wrote some code in an Xcode Playground. Why is it frozen/hanging?](https://github.com/tensorflow/swift/blob/master/FAQ.md#mac-i-wrote-some-code-in-an-xcode-playground-why-is-it-frozenhanging)

## Why Swift?

The short answer is that our decision was driven by the needs of the core [Graph Program
Extraction](docs/GraphProgramExtraction.md) compiler transformation that started the whole
project.  We have a long document that explains all of this rationale in depth named "[Why 
*Swift* for TensorFlow?](docs/WhySwiftForTensorFlow.md)".

Separate from that, Swift really is a great fit for our purposes, and a very nice language.

## How can I use Python 3 with the `Python` module?

By default, Swift will use the highest version of Python available on your system.
You can dynamically switch Python versions by calling:

```swift
PythonLibrary.useVersion(2, 7)
```

On macOS, Python 2.7 comes pre-installed and cannot be modified without disabling SIP.
You can, however, install Python 3 from [Python.org](https://docs.python.org/3/using/mac.html).

## [Mac] I wrote some code in an Xcode Playground. Why is it frozen/hanging?

Xcode Playgrounds are known to be somewhat unstable, unfortunately.
If your Playground appears to hang, please try restarting Xcode or creating a new Playground.
