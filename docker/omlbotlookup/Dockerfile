# Use builds from launchpad
FROM ubuntu:latest

# Set timezone, important for installation step
ENV TZ=Europe/Berlin
RUN ln -s /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install development tools
RUN apt-get update && apt-get install --no-install-recommends -y r-base-dev sudo curl git libcurl4-openssl-dev libssl-dev libxml2-dev libssh2-1-dev openssh-server mariadb-server libmariadb-client-lgpl-dev

# Install R packages
RUN Rscript -e "chooseCRANmirror(ind=29); install.packages(c('stringi','plumber','RMySQL', 'checkmate', 'ParamHelpers','FNN','memoise', 'httr'))"

# Copy server files
COPY data_access.R helper.R parameter_ranges.Rds paramToJSONList.R rest_api.R rest_server.R startup.sh import_db.sh wait_for_mysqld.sh /root/

# Run server on startup
CMD /root/startup.sh
