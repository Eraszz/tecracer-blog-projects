FROM --platform=linux/amd64 jenkins/jenkins:2.398-jdk11

USER root

RUN \
# Update
apt-get update -y && \
# Install Unzip
apt-get install unzip -y && \
# need wget
apt-get install wget -y && \
# vim
apt-get install vim -y && \
# git
apt-get install git -y

# install terraform 1.4.4
RUN wget https://releases.hashicorp.com/terraform/1.4.4/terraform_1.4.4_linux_amd64.zip
RUN unzip terraform_1.4.4_linux_amd64.zip
RUN mv terraform /usr/local/bin/

# copy the list of plugins to install
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

# disable the setup wizard
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

# copy the config-as-code yaml file into the image
COPY jenkins.yaml /usr/share/jenkins/ref/jenkins.yaml

# tell the jenkins config-as-code plugin where to find the yaml file
ENV CASC_JENKINS_CONFIG /usr/share/jenkins/ref/jenkins.yaml

COPY initialConfig.groovy /usr/share/jenkins/ref/init.groovy.d/initialConfigs.groovy

# create a sample job via XML
COPY job.xml /usr/share/jenkins/ref/jobs/serverless-jenkins-on-ecs/config.xml