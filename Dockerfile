FROM centos:latest

LABEL maintainer "777aws"
LABEL title="webApp"
LABEL version="1.0"

RUN mkdir /home/volume
RUN echo test >> /home/volume/testfile
VOLUME /home/volume
