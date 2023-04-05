FROM --platform=linux/amd64 jenkins/inbound-agent:4.11-1-alpine-jdk11

USER root

RUN \
# Update
apk update && \
# add Unzip
apk add unzip && \
# need wget
apk add wget && \
# vim
apk add vim && \
# git
apk add git

# install terraform 1.4.4
RUN wget https://releases.hashicorp.com/terraform/1.4.4/terraform_1.4.4_linux_amd64.zip
RUN unzip terraform_1.4.4_linux_amd64.zip
RUN mv terraform /usr/local/bin/
