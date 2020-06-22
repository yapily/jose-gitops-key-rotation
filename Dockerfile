FROM qcastel/docker-graalvm-mvn:0.1

WORKDIR /tmp

# Install essential packages
RUN apt-get install -y python curl git ssh vim wget zip

# Install gcloud
RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-296.0.1-linux-x86_64.tar.gz
RUN mkdir -p /usr/local/gcloud \
  && tar -C /usr/local/gcloud -xvf google-cloud-sdk* \
  && /usr/local/gcloud/google-cloud-sdk/install.sh --quiet
ENV PATH $PATH:/usr/local/gcloud/google-cloud-sdk/bin

# Install Kubectl
RUN apt-get install -y apt-transport-https gnupg2
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
RUN apt-get update
RUN apt-get install -y kubectl

# Install SOPS
RUN wget https://github.com/mozilla/sops/releases/download/v3.5.0/sops-v3.5.0.linux
RUN mv sops-v3.5.0.linux /usr/bin/sops
RUN chmod +x /usr/bin/sops

# Install JOSE CLI

ENV JOSE_CLI_VERSION=0.0.18
RUN cd /tmp
RUN wget https://github.com/yapily/jose-cli/releases/download/jose-cli-${JOSE_CLI_VERSION}/jose-cli-${JOSE_CLI_VERSION}.zip
RUN unzip jose-cli-${JOSE_CLI_VERSION}.zip
RUN cp -rf jose-${JOSE_CLI_VERSION}/* /usr/bin/
RUN chmod +x /usr/bin/jose
RUN cd -


# Copy scripts
COPY services/keyrotationjob/rotateKeys.sh /job/
RUN chmod +x /job/rotateKeys.sh

COPY services/keyrotationjob/add-ssh-key.sh /job/
RUN chmod +x /job/add-ssh-key.sh

# Prepare the ssh directory for the ssh keys
RUN mkdir /root/.ssh

WORKDIR /job

ENTRYPOINT ["./rotateKeys.sh"]
