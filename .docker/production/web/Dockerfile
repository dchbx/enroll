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

# run tests
#RUN ng test --watch=false
#RUN ng e2e --port 4202

ARG API_URL
RUN sed -i -r "s/API_URL/$API_URL/g" /app/src/environments/environment.prod.ts

# generate build
RUN ng build --prod --output-path=dist

############
### prod ###
############

# base image
FROM nginx:1.16.0-alpine

# copy artifact build from the 'build environment'
COPY --from=build /app/dist /usr/share/nginx/html

# copy nginx configuration
ARG API_URL
COPY ./.docker/production/web/nginx.conf /etc/nginx/conf.d/$API_URL.conf
RUN sed -i -r "s/API_URL/$API_URL/g" /etc/nginx/conf.d/$API_URL.conf 

# expose port 80
#EXPOSE 80

# run nginx
#CMD ["nginx", "-g", "daemon off;"]
