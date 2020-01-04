#############
### build ###
#############

# base image
FROM node:12.10.0 as build

# install chrome for protractor tests
RUN apt-get update && apt-get install

# set working directory
WORKDIR /app

# add `/app/node_modules/.bin` to $PATH
ENV PATH /app/node_modules/.bin:$PATH

# install and cache app dependencies
COPY ./clients/html/package.json /app/package.json
RUN npm install
RUN npm install -g @angular/cli

# add app
COPY ./clients/html/ /app

