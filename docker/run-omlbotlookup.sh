 #!/bin/sh
 docker run -d --volume=$PWD/mysqldata:/mysqldata --name=$USER-omlbotlookup omlbotlookup:$USER