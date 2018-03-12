#!/bin/sh
running=$(docker ps --filter "status=exited" --filter "name=$USER-omlbotlookup" --quiet)
if [ ! $running ];then
 echo "No stopped containers"
 return 1
else
 echo $running
 return 0
fi
