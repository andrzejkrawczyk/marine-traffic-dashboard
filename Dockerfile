FROM rocker/shiny:latest 

    
# install additional packages
RUN R -e "install.packages(c('leaflet', 'dplyr', 'geosphere'), repos='https://cran.rstudio.com/')"
RUN rm -rf /tmp/downloaded_packages/ /tmp/*.rds

EXPOSE 8080

## copy configuration file
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf

## assume shiny app is in build folder /shiny
COPY ./shiny/ /srv/shiny-server/shiny/