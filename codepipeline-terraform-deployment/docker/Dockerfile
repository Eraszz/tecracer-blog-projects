FROM --platform=linux/amd64 public.ecr.aws/ubuntu/ubuntu:22.04

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
apt-get install git -y && \
# curl
apt-get -y install curl && \
## jq
apt-get -y install jq && \
# python3
apt-get install python3 -y && \
# python3-pip
apt-get install python3-pip -y

# update python3
RUN python3 -m pip install --upgrade pip

# install terraform 1.4.4
RUN wget https://releases.hashicorp.com/terraform/1.4.4/terraform_1.4.4_linux_amd64.zip
RUN unzip terraform_1.4.4_linux_amd64.zip
RUN mv terraform /usr/local/bin/

# install TFLINT
RUN curl -L "$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | grep -o -E -m 1 "https://.+?_linux_amd64.zip")" > tflint.zip && \
unzip tflint.zip && \
rm tflint.zip
RUN mv tflint /usr/bin/

# install checkov
RUN pip3 install --no-cache-dir checkov

# install TFSEC
RUN curl -L "$(curl -s https://api.github.com/repos/aquasecurity/tfsec/releases/latest | grep -o -E -m 1 "https://.+?tfsec-linux-amd64")" > tfsec && \
chmod +x tfsec
RUN mv tfsec /usr/bin/

# install OPA
RUN curl -L -o opa https://openpolicyagent.org/downloads/v0.52.0/opa_linux_amd64_static
RUN chmod 755 ./opa
RUN mv opa /usr/bin/
