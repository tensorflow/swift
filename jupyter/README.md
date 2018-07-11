# Jupyter Kernel

This is a Jupyter Kernel for Swift that is implemented using LLDB's Python APIs.

# Installation Instructions

Create a virtualenv and install jupyter in it.
```
virtualenv venv
. venv/bin/activate
pip -V # Make sure this says python 2.7. LLDB doesn't support python 3.
pip install jupyter
```

Install a Swift toolchain ([see instructions here](https://github.com/tensorflow/swift/blob/master/Installation.md)).

Register the kernel with jupyter.
```
python register.py --sys-prefix --swift-toolchain <path to swift toolchain>
```

Now run `jupyter notebook`, and it should have a Swift kernel.
