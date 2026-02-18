FROM jenkins/jenkins:lts-jdk17

USER root

# Paquetes base + deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg lsb-release git unzip jq \
    python3 python3-pip python3-venv \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------- Docker CLI ----------
RUN mkdir -p /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list \
 && apt-get update && apt-get install -y --no-install-recommends docker-ce-cli \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------- Terraform ----------
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo "$VERSION_CODENAME") main" \
    > /etc/apt/sources.list.d/hashicorp.list \
 && apt-get update && apt-get install -y --no-install-recommends terraform \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------- Ansible ----------
# Opción simple: ansible-core desde pip (estable para pipelines)
RUN pip3 install --no-cache-dir ansible==9.2.0

# Plugins (instalación offline reproducible)
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

USER jenkins
