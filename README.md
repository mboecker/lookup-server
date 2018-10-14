[![Build Status](https://travis-ci.org/mboecker/lookup-server.svg?branch=master)](https://travis-ci.org/mboecker/lookup-server)

# OpenML TuneBench Server

When optimizing parameters of learning algorithms (hyperparameters), one has to try different hyperparameter configurations on different datasets with a given learning algorithm (and learning task, eg. classification) in order to explore the optimization space. 
Because this is expensive, this project will allow to interpolate between already-computed performance values for the learning algorithm. 
By searching the [OpenML](https://www.openml.org/) database for the given learning algorithm and the closest hyperparameters, we can approximate the performance of the algorithm.

# How To

In order to start the docker image, you have to clone this repo and then build it, as you would normally.

See `docker/rebuild-omlbotlookup.sh` and `docker/run-omlbotlookup.sh` for examples.

`docker/mysqldata` should contain the actual database as an .sql file, which the API looks into. `docker/mysqldata/README` gives instructions on how to obtain and pre-process the database.sql file to minimize startup time of the container.

Internally the container exposes the port `8000` but to not collide with other ports we map it to `8746` on the host in the examplary `run-omlbotlookup.sh` file.

## Example

An example can be found in `example/access_api.R`

# License

This project is MIT licensed, see the LICENSE file.
