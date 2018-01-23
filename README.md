This Docker Image is used with the OpenML database (obtainable here: https://github.com/ja-thomas/OMLbots/tree/master/snapshot_database). When optimizing parameters of learning algorithms (metaparameter), one has to try different metaparameter configurations on different datasets with a given learning algorithm (and learning task, eg. classification) in order to explore the optimization space. Because this is expensive, this project will allow to interpolate between already-computed performance values for the learning algorithm. By searching the OpenML database for the given learning algorithm and the closest metaparameters, we can approximate the performance of the algorithm.

#How To

In order to start the docker image, you have to clone this repo and then build it, as you would normally.

The image expects an externally mounted /mysqldata directory, so when ```run```ning the container, you should supply it with something like ```-v ~/lookup-server/externaldata:/mysqldata```. This directory currently contains the actual API the container exposes. But when finished, it should contain most of the data the container needs to access (some kind of stripped down version of the OpenML database mentioned above).

You should also expose the containers port 8000 with something like "-p 8000:8000", so you can access the api as ```localhost:8000```.

#License

This project is currently MIT licensed, see the LICENSE file, but this could change in the future.
