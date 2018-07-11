# Jupyter Kernel

This is a Jupyter Kernel for Swift that is implemented using LLDB's Python APIs.

This kernel is very barebones and experimental. I plan to move it to its own repository if/when it becomes a bit more fleshed out.

# Installation Instructions

Create a virtualenv and install jupyter in it.
```
virtualenv venv
. venv/bin/activate
pip2 install jupyter # Must use python2, because LLDB doesn't support python3.
```

Install a Swift toolchain ([see instructions here](https://github.com/tensorflow/swift/blob/master/Installation.md)).

Register the kernel with jupyter.
```
python2 register.py --sys-prefix --swift-toolchain <path to swift toolchain>
```

Now run `jupyter notebook`, and it should have a Swift kernel.
