# Debugging X10 issues

The X10 accelerator backend can provide significantly higher throughput for graph-based parallel
computation, but its deferred tracing and just-in-time compilation can lead to non-obvious behavior
sometimes. This might include frequent recompilation of traces due to graph or tensor shape changes,
or huge graphs that lead to memory issues during compilation.

One way to diagnose issues is to use the execution metrics and counters provided by
X10. The first thing to check when a model is slow is to generate a metrics
report.

# Metrics

To print a metrics report, add a `PrintX10Metrics()` call to your program:

```swift
import TensorFlow

...
PrintX10Metrics()
...
```

This will log various metrics and counters at the `INFO` level.

## Understanding the metrics report

The report includes things like:

-   How many times we trigger XLA compilations and the total time spent on
    compilation.
-   How many times we launch an XLA computation and the total time spent on
    execution.
-   How many device data handles we create / destroy, etc.

This information is reported in terms of percentiles of the samples. An example
is:

```
Metric: CompileTime
  TotalSamples: 202
  Counter: 06m09s401ms746.001us
  ValueRate: 778ms572.062us / second
  Rate: 0.425201 / second
  Percentiles: 1%=001ms32.778us; 5%=001ms61.283us; 10%=001ms79.236us; 20%=001ms110.973us; 50%=001ms228.773us; 80%=001ms339.183us; 90%=001ms434.305us; 95%=002ms921.063us; 99%=21s102ms853.173us
```

We also provide counters, which are named integer variables which track internal
software status. For example:

```
Counter: CachedSyncTensors
  Value: 395
```

## Known caveats

`Tensor`s backed by X10 behave semantically like default eager mode`Tensor`s. However, there are 
some performance and completeness caveats:

1.  Degraded performance because of too many recompilations.

    XLA compilation is expensive. X10 automatically recompiles the graph every
    time new shapes are encountered, with no user intervention. Models need to
    see stabilized shapes within a few training steps and from that point no
    recompilation is needed. Additionally, the execution paths must stabilize
    quickly for the same reason: X10 recompiles when a new execution path is
    encountered. To sum up, in order to avoid recompilations:

    *   Avoid highly variable dynamic shapes. However, a low number of different
        shapes could be fine. Pad tensors to fixed sizes when possible.
    *   Avoid loops with different number of iterations between training steps.
        X10 currently unrolls loops, therefore different number of loop
        iterations translate into different (unrolled) execution paths.

2.  A small number of operations aren't supported by X10 yet.

    We currently have a handful of operations which aren't supported, either
    because there isn't a good way to express them via XLA and static shapes
    (currently just `nonZeroIndices`) or lack of known use cases (several linear
    algebra operations and multinomial initialization). While the second
    category is easy to address as needed, the first category can only be
    addressed through interoperability with the CPU, non-XLA implementation.
    Using interoperability too often has significant performance implications
    because of host round-trips and fragmenting a fully fused model in multiple
    traces. Users are therefore advised to avoid using such operations in their
    models.

    On Linux, use `XLA_SAVE_TENSORS_FILE` (documented in the next section) to
    get the Swift stack trace which called the unsupported operation. Function
    names can be manually demangled using `swift-demangle`.


# Obtaining and graphing traces

If you suspect there are problems with the way graphs are being traced, or want to understand the
tracing process, tools are provided to log out and visualize traces. You can have X10 log out the
traces it finds by setting the `XLA_SAVE_TENSORS_FILE` environment variable:

```sh
export XLA_SAVE_TENSORS_FILE=/home/person/TraceLog.txt
```

These trace logs come in three formats: `text`, `hlo`, and `dot`, with the format settable through
the environment variable XLA_SAVE_TENSORS_FMT:

```sh
export XLA_SAVE_TENSORS_FMT=text
```

When you run your application, the `text` representation that is logged out will show each 
individual trace in a high-level text notation used by X10. The `hlo` representation shows the 
intermediate representation that is passed to the XLA compiler. You may want to restrict the number 
of iterations within your training or calculation loops to prevent these logs from becoming too large. Also, each run of your application will append to this file, so you may wish to delete it
between runs.

Setting the variable `XLA_LOG_GRAPH_CHANGES` to 1 will also indicate within the trace log where
changes in the graph have occurred. This is extremely helpful in finding places where recompilation
will result.

For a visual representation of a trace, the `dot` option will log out Graphviz-compatible graphs. If
you extract the portion of a trace that looks like

```
digraph G {
	...
}
```

into its own file, Graphviz (assuming it is installed) can generate a visual diagram via

```sh
dot -Tpng trace.dot -o trace.png
```

Note that setting the `XLA_SAVE_TENSORS_FILE` environment variable, especially when used in 
combination with `XLA_LOG_GRAPH_CHANGES` will have a substantial negative impact on performance.
Only use these when debugging, and not for regular operation.

# Additional environment variables

Additional environment variables for debugging include:

*   `XLA_USE_BF16`: If set to 1, transforms all the `Float` values to BF16.
    Should only be used for debugging since we offer automatic mixed precision.

*   `XLA_USE_32BIT_LONG`: If set to 1, maps S4TF `Long` type to the XLA 32 bit
    integer type. On TPU, 64 bit integer computations are expensive, so setting
    this flag might help. Of course, the user needs to be certain that the
    values still fit in a 32 bit integer.
