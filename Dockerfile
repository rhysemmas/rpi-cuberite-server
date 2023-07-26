FROM --platform=linux/amd64 debian:stable as builder

RUN apt-get update && \
    apt-get install -y git python3 make cmake g++-arm-linux-gnueabihf

WORKDIR /build

RUN git clone --recursive https://github.com/cuberite/cuberite.git

WORKDIR /build/cuberite

RUN git reset 8a763d3bedac3eabee9c1ca022be53038ba3fc54 --hard

WORKDIR /build/cuberite/Release

# GCC compiler flags for ARM CPUs: https://gist.github.com/fm4dd/c663217935dc17f0fc73c9c81b0aa845
# flags below are compatible with RPi 3 & 4
RUN cmake -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc \
          -DCMAKE_CXX_COMPILER=arm-linux-gnueabihf-g++ \
          -DCMAKE_C_FLAGS="-march=armv7-a+fp -mfpu=neon-fp-armv8 -mfloat-abi=hard" \
          -DCMAKE_CXX_FLAGS="-march=armv7-a+fp -mfpu=neon-fp-armv8 -mfloat-abi=hard" \
          -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
          -DBUILD_SHARED_LIBS=OFF \
          -DCMAKE_EXE_LINKER_FLAGS=-static \
          -DNO_NATIVE_OPTIMIZATION=1 \
          -DCMAKE_BUILD_TYPE=RELEASE ..

RUN make -j`nproc`

# Install Plugins here (need to be enabled in settings.ini)
WORKDIR /build/cuberite/Release/Server/Plugins

RUN git clone https://github.com/bennasar99/ClearLagg.git



FROM arm32v7/debian:stable-slim

WORKDIR /app

COPY --from=builder /build/cuberite/Server/ .
COPY --from=builder /build/cuberite/Release/Server/lua .
COPY --from=builder /build/cuberite/Release/Server/Cuberite .

COPY ./config/* .

RUN useradd -ms /bin/bash cuberite && \
    chown -R cuberite:cuberite /app

USER cuberite

CMD ./Cuberite

EXPOSE 25565 8080
