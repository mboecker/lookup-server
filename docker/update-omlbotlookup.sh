#!/bin/bash
echo "Stopping docker container..."
./stop-omlbotlookup.sh
sleep 3
echo "Copying new app files..."
docker cp omlbotlookup/app/. $USER-omlbotlookup:/root
sleep 3
echo "Starting docker container again..."
./start-omlbotlookup.sh
