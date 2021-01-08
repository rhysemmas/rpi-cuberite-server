FROM arm32v7/debian:buster-slim
#arm Cuberite is dynamically linked to some armhf deps which we need in the container 

ENV WEB_ADMIN_USER=admin
ENV WEB_ADMIN_PASS=password

RUN apt-get update && \
    apt-get install -y curl rsync git

WORKDIR /app

RUN curl -sSfL https://download.cuberite.org | sh

COPY ./config/* /app/

# Install Plugins here (need to be enabled in settings.ini)
RUN git clone https://github.com/bennasar99/ClearLagg.git ./Plugins/

RUN sed -i s/WEB_ADMIN_USER/$WEB_ADMIN_USER/g webadmin.ini && \
    sed -i s/WEB_ADMIN_PASS/$WEB_ADMIN_PASS/g webadmin.ini

RUN useradd -ms /bin/bash cuberite
RUN chown -R cuberite:cuberite /app
USER cuberite

CMD ./Cuberite 

EXPOSE 25565 8080
