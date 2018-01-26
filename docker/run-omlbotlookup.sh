 #!/bin/sh
 docker run -d --volume=$PWD/mysqldata:/mysqldata --name=$USER-omlbotlookup omlbotlookup:$USER -p 8746:8000
