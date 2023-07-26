FROM arm32v7/debian:latest as builder

WORKDIR /build

RUN apt-get update && \
    apt-get install -y git gcc g++ make cmake

RUN git clone --recursive https://github.com/cuberite/cuberite.git

WORKDIR /build/cuberite

RUN git reset 8a763d3bedac3eabee9c1ca022be53038ba3fc54 --hard

WORKDIR /build/cuberite/Release

RUN cmake -DCMAKE_BUILD_TYPE=RELEASE .. && \
    make -j`nproc`

# Install Plugins here (need to be enabled in settings.ini)
WORKDIR /build/cuberite/Release/Server/Plugins

RUN git clone https://github.com/bennasar99/ClearLagg.git



FROM arm32v7/debian:stable-slim

WORKDIR /app

COPY --from=builder /build/cuberite/Release/Server/* .

COPY ./config/* .

RUN useradd -ms /bin/bash cuberite && \
    chown -R cuberite:cuberite /app

USER cuberite

CMD ./Cuberite

EXPOSE 25565 8080
