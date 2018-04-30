#!/bin/bash
running=$(docker ps --filter "status=exited" --filter "name=$USER-omlbotlookup" --quiet)
if [ ! $running ];then
 echo "No stopped containers"
 exit 1
else
 echo $running
 exit 0
fi
