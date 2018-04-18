# Use builds from launchpad
FROM opencpu/base

# Install development tools
RUN apt-get update && apt-get install -y r-base-dev sudo curl git libcurl4-openssl-dev libssl-dev libxml2-dev libssh2-1-dev openssh-server mysql-server-5.7 libmariadb-client-lgpl-dev

RUN Rscript -e "chooseCRANmirror(ind=29); install.packages(c('stringi','plumber','RMySQL', 'checkmate', 'ParamHelpers','FNN','memoise'))"

# FIXME: add this line to above when use_travis is merged
RUN Rscript -e "chooseCRANmirror(ind=29); install.packages(c('httr'))"

COPY data_access.R helper.R parameter_ranges.Rds paramToJSONList.R rest_api.R rest_server.R startup.sh /root/

EXPOSE 8000

CMD /root/startup.sh
