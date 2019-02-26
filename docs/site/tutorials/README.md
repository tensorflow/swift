# Swift Tutorials

This repository contains Jupyter notebooks demonstrating TensorFlow in Swift.

# How to run

## Docker

Follow the [Using the Docker Container](https://github.com/google/swift-jupyter#using-the-docker-container) instructions to launch swift-jupyter using the docker container, with the following modifications:

* In the `docker build` command, add the flag `--build-arg swift_tf_url=https://storage.googleapis.com/s4tf-kokoro-artifact-testing/release/swift_for_tensorflow_release_2019-01-30_06-00-00_RC00/swift-tensorflow-DEVELOPMENT-ubuntu18.04.tar.gz`, to use a build that is known to work with the tutorial.
* In the `docker run` command, use `-v /path/to/tutorial/repo/:/notebooks` to so that the Jupyter in the container can see the tutorials.

Open Jupyter and navigate to the tutorial that you want to use.
