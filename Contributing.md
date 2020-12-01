# Contributing

Everyone is welcome to contribute to Swift for TensorFlow. Contributing doesn't just mean submitting code - there are many different ways to get involved, including reporting bugs, improving documentation, writing models or tutorials, submitting deep learning building blocks, or participating in API and infrastructure design discussions.

The Swift for TensorFlow community is guided by our [Code of Conduct](https://github.com/tensorflow/swift/blob/main/CODE_OF_CONDUCT.md), which we encourage everybody to read before participating.

## Report bugs

Reporting bugs is a great way for anyone to help improve Swift for TensorFlow. Swift for TensorFlow has a JIRA project on the [bugs.swift.org](https://bugs.swift.org) JIRA instance. To report a bug, [use this issue template](https://bugs.swift.org/secure/CreateIssue.jspa?issuetype=10006&pid=10100).

Please follow the [Swift project's bug reporting guidelines](https://swift.org/contributing/#reporting-bugs) while reporting bugs.

## Improve documentation

Improving documentation is another great way for anyone to contribute to Swift for TensorFlow. Documentation is located in a few different places:

* Tutorials and design documents are located at https://github.com/tensorflow/swift.
* API documentation is located at https://www.tensorflow.org/swift/api_docs. Documentation is generated from source code comments in the [TensorFlow standard library](https://github.com/apple/swift/tree/tensorflow/stdlib/public/TensorFlow) and the [deep learning library](https://github.com/tensorflow/swift-apis).

For small documentation improvements, feel free to send a PR directly to the relevant repository. For bigger changes, you might want to file a JIRA issue or ask on the mailing list before starting, as described in the [code contribution workflow](#code-contribution-workflow).

## Starter bugs

If you are interested in contributing code, but are not sure how to get started, take a look at the [Swift for TensorFlow Starter Bugs](https://bugs.swift.org/issues/?filter=11323). It's a curated list of small, self-contained bugs that are great for diving in and getting a sense of how everything works. If you have any questions about these bugs, feel free to ask in a comment on JIRA or on the [mailing list](https://groups.google.com/a/tensorflow.org/forum/#!forum/swift)!

Once you are ready to start working on a starter issue, assign it to yourself in JIRA and follow the [code contribution workflow](#code-contribution-workflow).

## Add deep learning building blocks

The [Swift for TensorFlow Deep Learning Library](https://github.com/tensorflow/swift-apis) contains building blocks for deep learning, like layers, loss functions, and optimizers. It's very new, so it's some of standard building blocks. We welcome contributions!

Follow the [code contribution workflow](#code-contribution-workflow) when contributing building blocks.

## Participate in design discussions

We discuss preliminary feature requests and ideas on the [mailing list](https://groups.google.com/a/tensorflow.org/forum/#!forum/swift). You can participate by sending your own feature requests and ideas to the mailing list, or by commenting on others' feature requests and ideas.

Once an idea has been fleshed out, the person or people driving it write a proposal and send it as a PR to the [proposals directory](https://github.com/tensorflow/swift/tree/main/proposals). Further discussion happens on that PR, and the PR gets merged if the design gets accepted. You can participate by proposing your own proposals, or by commenting on others' proposals.


## Code contribution workflow

Before contributing code, make sure you know how to compile and test the repository that you want to contribute to:

* Swift for TensorFlow Deep Learning Library: [development instructions](https://github.com/tensorflow/swift-apis#development)
* Swift for TensorFlow Compiler: [development instructions](https://github.com/apple/swift/tree/tensorflow#building-swift-for-tensorflow)

Here is the standard workflow for contributing code to Swift for TensorFlow:

1. Coordinate with the community to make sure you're not duplicating work or building something that conflicts with something else. There are a few ways to do this, depending on the size and scope of the change:
    - For tiny changes (e.g. fixing typos, clarifying documentation), you can skip this step and jump straight to sending a PR.
    - For straightforward changes (e.g. fixing known bugs, adding deep learning building blocks, or implementing features that have already been designed), find an issue in the [Swift for TensorFlow JIRA project](https://bugs.swift.org/projects/TF/issues) and assign it to yourself. This lets others know that you are working on the change, so that they don't waste effort working on the same change. If there is no issue for your change, [file one](#report-bugs). If you decide not to work on a change, please unassign the issue from yourself to give others a chance to work on it.
    - For large changes, or changes that affect others (e.g. adding a new feature, or changing an existing API), start a discussion on the [mailing list](https://groups.google.com/a/tensorflow.org/forum/#!forum/swift) before you start working on it. If the change has a large design space, we might recommend having a [design discussion](#participate-in-design-discussions).
2. Start working on your code, and send a PR to the relevant repository when it's ready for review. Take a look at the [Swift project code contribution guidelines](https://swift.org/contributing/#contributing-code) for tips on how to structure your code and PRs.
3. A reviewer will take a look at your PR and might ask for some changes. This is an iterative process that continues until the code is ready to be merged.
4. Once the code is ready to be merged, someone with commit access to the repository will merge it.
5. Remember to close any JIRA issues related to the change.
