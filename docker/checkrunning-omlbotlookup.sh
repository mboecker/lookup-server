#!/bin/sh
running=$(docker ps --filter "status=running" --filter "name=$USER-omlbotlookup" --quiet)
if [ ! $running ];then
  echo "No running containers"
 return 1
else
 echo $running
 return 0
fi
