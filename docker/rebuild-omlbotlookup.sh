 #!/bin/sh
docker rmi omlbotlookup:$USER
docker build -t omlbotlookup:$USER omlbotlookup
