#!/bin/bash
running=$(docker ps --filter "status=running" --filter "name=$USER-omlbotlookup" --quiet)
if [ ! $running ];then
  echo "No running containers"
 exit 1
else
 echo $running
 exit 0
fi
