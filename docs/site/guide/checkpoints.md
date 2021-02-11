# Model checkpoints

The ability to save and restore the state of a model is vital for a number of applications, such
as in transfer learning or for performing inference using pretrained models. Saving the
parameters of a model (weights, biases, etc.) in a checkpoint file or directory is one way to 
accomplish this.

This module provides a high-level interface for loading and saving
[TensorFlow v2 format](https://github.com/tensorflow/tensorflow/blob/master/tensorflow/core/util/tensor_bundle/tensor_bundle.h)
checkpoints, as well as lower-level components that write to and read from this file format. 


## Loading and saving simple models

By conforming to the `Checkpointable` protocol, many simple models can be serialized to
checkpoints without any additional code:

```swift
import Checkpoints
import ImageClassificationModels

extension LeNet: Checkpointable {}

var model = LeNet()

...

try model.writeCheckpoint(to: directory, name: "LeNet")
```
and then that same checkpoint can be read by using:

```swift
try model.readCheckpoint(from: directory, name: "LeNet")
```
This default implementation for model loading and saving will use a path-based naming
scheme for each tensor in the model that is based on the names of the properties within the
model structs. For example, the weights and biases within the first convolution in 
[the LeNet-5 model](https://github.com/tensorflow/swift-models/blob/main/Models/ImageClassification/LeNet-5.swift#L26)
will be saved with the names `conv1/filter` and `conv1/bias`, respectively. When loading, 
the checkpoint reader will search for tensors with these names.

## Customizing model loading and saving

If you want to have greater control over which tensors are saved and loaded, or the naming
of those tensors, the `Checkpointable` protocol offers a few points of customization.

To ignore properties on certain types, you can provide an implementation of
`ignoredTensorPaths` on your model that returns a Set of strings in the form of
`Type.property`. For example, to ignore the `scale` property on every Attention layer, you
could return  `["Attention.scale"]`.

By default, a forward slash is used to separate each deeper level in a model. This can be
customized by implementing `checkpointSeparator` on your model and providing a new
string to use for this separator. 

Finally, for the greatest degree of customization in tensor naming, you can implement 
`tensorNameMap` and provide a function that maps from the default string name generated
for a tensor in the model to a desired string name in the checkpoint. Most commonly, this
will be used to interoperate with checkpoints generated with other frameworks, each of which
have their own naming conventions and model structures. A custom mapping function gives
the greatest degree of customization for how these tensors are named.

Some standard helper functions are provided, like the default
`CheckpointWriter.identityMap` (which simply uses the automatically generated tensor
path name for checkpoints), or the `CheckpointWriter.lookupMap(table:)` function,
which can build a mapping from a dictionary.

For an example of how custom mapping can be accomplished, please see
[the GPT-2 model](https://github.com/tensorflow/swift-models/blob/main/Models/Text/GPT2/CheckpointWriter.swift), 
which uses a mapping function to match the exact naming scheme used for OpenAI's
checkpoints.

## The CheckpointReader and CheckpointWriter components

For checkpoint writing, the extension provided by the `Checkpointable` protocol
uses reflection and keypaths to iterate over a model's properties and generate a dictionary
that maps string tensor paths to Tensor values. This dictionary is provided to an underlying
`CheckpointWriter`, along with a directory in which to write the checkpoint. That
`CheckpointWriter` handles the task of generating the on-disk checkpoint from that
dictionary.

The reverse of this process is reading, where a `CheckpointReader` is given the location of 
an on-disk checkpoint directory. It then reads from that checkpoint and forms a dictionary that
maps the names of tensors within the checkpoint with their saved values. This dictionary is
used to replace the current tensors in a model with the ones in this dictionary.

For both loading and saving, the `Checkpointable` protocol maps the string paths to tensors
to corresponding on-disk tensor names using the above-described mapping function.

If the `Checkpointable` protocol lacks needed functionality, or more control is desired over
the checkpoint loading and saving process, the `CheckpointReader` and
`CheckpointWriter` classes can be used by themselves.

## The TensorFlow v2 checkpoint format

The TensorFlow v2 checkpoint format, as briefly described in
[this header](https://github.com/tensorflow/tensorflow/blob/master/tensorflow/core/util/tensor_bundle/tensor_bundle.h),
is the second generation format for TensorFlow model checkpoints. This second-generation
format has been in use since late 2016, and has a number of improvements over the v1
checkpoint format. TensorFlow SavedModels use v2 checkpoints within them to save model
parameters.

A TensorFlow v2 checkpoint consists of a directory with a structure like the following:

```
checkpoint/modelname.index
checkpoint/modelname.data-00000-of-00002
checkpoint/modelname.data-00001-of-00002
```

where the first file stores the metadata for the checkpoint and the remaining files are binary
shards holding the serialized parameters for the model.

The index metadata file contains the types, sizes, locations, and string names of all serialized
tensors contained in the shards. That index file is the most structurally complex part of the
checkpoint, and is based on `tensorflow::table`, which is itself based on SSTable / LevelDB. 
This index file is composed of a series of key-value pairs, where the keys are strings and the
values are protocol buffers. The strings are sorted and prefix-compressed. For example: if 
the first entry is `conv1/weight` and next `conv1/bias`, the second entry only uses the
`bias` part.

This overall index file is sometimes compressed using
[Snappy compression](https://github.com/google/snappy). The
`SnappyDecompression.swift` file provides a native Swift implementation of Snappy
decompression from a compressed Data instance. 

The index header metadata and tensor metadata are encoded as protocol buffers and
encoded / decoded directly via [Swift Protobuf](https://github.com/apple/swift-protobuf). 

The `CheckpointIndexReader` and `CheckpointIndexWriter` classes handle loading
and saving these index files as part of the overarching `CheckpointReader` and
`CheckpointWriter` classes. The latter use the index files as basis for determining what to
read from and write to the structurally simpler binary shards that contain the tensor data.
