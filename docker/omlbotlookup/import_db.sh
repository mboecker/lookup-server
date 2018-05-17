#!/bin/bash

# In a construct like "a | b", this causes "a | b" to fail, if a failed:
set -o pipefail

# Load the data from stdin.
cat | mysql openml

# Check if loading succeded.
if [ $? -eq 0 ]; then
    exit 0
else
	echo "Failed to load data!"
	exit 1
fi
