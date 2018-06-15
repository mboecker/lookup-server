#!/bin/bash
docker run -it -p 8746:8746 --name=$USER-omlbotlookup omlbotlookup:$USER
