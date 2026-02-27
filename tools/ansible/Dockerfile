FROM python:3.12-slim

ARG ANSIBLE_VERSION=10.7.0
ARG TERRAFORM_VERSION=1.8.5
ARG AWSCLI_VERSION=2.15.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl unzip jq git openssh-client \
 && pip install --no-cache-dir "ansible==${ANSIBLE_VERSION}" boto3 botocore \
 && curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o /tmp/terraform.zip \
 && unzip /tmp/terraform.zip -d /usr/local/bin \
 && rm -f /tmp/terraform.zip \
 && curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip" -o /tmp/awscliv2.zip \
 && unzip /tmp/awscliv2.zip -d /tmp \
 && /tmp/aws/install \
 && rm -rf /tmp/aws /tmp/awscliv2.zip \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
ENTRYPOINT ["bash","-lc"]
