FROM ubuntu@sha256:66460d557b25769b102175144d538d88219c077c678a49af4afca6fbfc1b5252

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -q update \
    && apt-get -q install -y --no-install-recommends \
    build-essential \
    binutils \ 
    patchelf \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG USER=app
ARG UID=1001
ARG GID=1001
RUN groupadd -g $GID $USER && useradd -m -u $UID -g $GID -s /bin/bash $USER

WORKDIR /sig2hook
COPY . /sig2hook
RUN chown -R $UID:$GID /sig2hook && chmod +x /sig2hook/sig2hook.sh

USER $USER

CMD ["bash", "./sig2hook.sh"]
