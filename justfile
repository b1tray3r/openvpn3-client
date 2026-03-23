set shell := ["bash", "-c"]

IMAGE_NAME := "openvpn3:latest"
CONTAINER_NAME := "openvpn3"
DOCKERFILE_PATH := "Dockerfile"

build:
    cd docker && \
    docker build -t {{IMAGE_NAME}} -f {{DOCKERFILE_PATH}} .

start:
    docker run -d \
        --name openvpn3 \
        --cap-add=NET_ADMIN \
        -v $(pwd)/config.ovpn:/app/config.ovpn \
        --env-file .env \
        {{IMAGE_NAME}}

stop:
    docker stop -f openvpn3
    docker rm -f openvpn3
