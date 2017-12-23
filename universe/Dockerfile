FROM alpine:latest

MAINTAINER Richard Shaw <rshaw@mesosphere.com>

RUN apk -U add alpine-sdk python3 bash docker

WORKDIR /tmp

COPY ./build.sh /tmp/

CMD ["/tmp/build.sh"]
