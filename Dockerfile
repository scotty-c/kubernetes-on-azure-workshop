FROM docker:dind

RUN apk add bash \
            git \
            tmux \
            curl \ 
            bash-completion \ 
            jq \
            python \
            py-pip \
            gcc \
            libffi-dev \
            musl-dev \
            openssl \
            openssl-dev \
            python-dev \
            make \
            coreutils \
            ca-certificates && \
    curl -o kubectl https://storage.googleapis.com/kubernetes-release/release/v1.15.7/bin/linux/amd64/kubectl && \
    mv kubectl /usr/local/bin && \
    chmod a+x /usr/local/bin/kubectl && \
    curl -o helm.tgz https://get.helm.sh/helm-v3.0.2-linux-amd64.tar.gz && \
    tar -xzf helm.tgz && \
    mv linux-amd64/helm /usr/local/bin && \
    rm helm.tgz && \
    #helm init --client-only && \
    curl https://deislabs.blob.core.windows.net/porter/latest/install-linux.sh | bash && \
    pip --no-cache-dir install -U pip && \
    pip --no-cache-dir install azure-cli && \
    curl -L -o /usr/local/bin/kubectx https://raw.githubusercontent.com/ahmetb/kubectx/v0.6.3/kubectx && \
    chmod +x /usr/local/bin/kubectx && \
    curl -sL https://run.linkerd.io/install | sh && \
    curl -sL https://run.solo.io/supergloo/install | sh && \
    mkdir -p /workshop

ENV PATH="$PATH:/root/.porter"
ENV PATH="$PATH:/root/.linkerd2/bin"   
ENV PATH="$PATH:/root/.supergloo/bin"  

ADD .bashrc /root/.bashrc

WORKDIR /workshop

