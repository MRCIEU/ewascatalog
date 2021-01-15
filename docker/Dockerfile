## Base installation on python
## see https://hub.docker.com/_/python
FROM python:3.8.6-buster as ewascatalog
ENV PYTHONUNBUFFERED 1

## Install libraries required for typical R packages
RUN apt-get update && \
    apt-get install -y libgit2-dev && \
    apt-get install -y libcurl4-openssl-dev && \
    apt-get install -y libxml2-dev && \
    apt-get install -y libssl-dev && \
    apt-get install -y libcairo2-dev && \
    apt-get install -y libxt-dev

## Install R
##  Note: 'buster-cran35' below should match the version found in /etc/apt/sources.list	
RUN apt-get update && \
    apt-get install -y dirmngr apt-transport-https ca-certificates software-properties-common gnupg2 && \
    apt-key adv --keyserver keys.gnupg.net --recv-key 'E19F5F87128899B192B1A2C2AD5F960A256A04AF' && \
    add-apt-repository 'deb https://cloud.r-project.org/bin/linux/debian buster-cran35/' && \
    apt update && \
    apt install -y r-base r-base-dev


## Create a user account in the container that matches current user
ARG USER_ID
ARG GROUP_ID
RUN addgroup --gid $GROUP_ID user
RUN adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID user

## Create a directory in container for running scripts
RUN mkdir /code

## Set working directory
WORKDIR /code

## Copy scripts to container
COPY . /code/

## Install python packages
RUN pip install -r python-requirements.txt

## Install R packages
RUN Rscript install-packages.r

## Pass ownership to the main user 
RUN chown -R user /code

## Switch to being 'user'
USER user
