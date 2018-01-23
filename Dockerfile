# Use builds from launchpad
FROM opencpu/base

# Install development tools
RUN apt-get update
RUN apt-get install -y rstudio-server r-base-dev sudo curl git libcurl4-openssl-dev libssl-dev libxml2-dev libssh2-1-dev openssh-server mysql-server libmariadb-client-lgpl-dev

RUN Rscript -e "chooseCRANmirror(ind=29); install.packages('stringi'); install.packages('plumber'); install.packages('RMySQL');"

#COPY rest_api_handling.R rest_server.R startup.sh /root/
COPY rest_server.R startup.sh /root/

EXPOSE 8000

CMD /root/startup.sh
