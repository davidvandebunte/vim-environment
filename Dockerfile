# https://hub.docker.com/_/ubuntu
FROM ubuntu:bionic-20190424

# Non-root user
ARG INTERNAL_USER="internal"
ARG INTERNAL_UID="1000"
ARG INTERNAL_GID="100"

ENV DEBIAN_FRONTEND=noninteractive

# https://askubuntu.com/a/6903/612216
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    # Install certificates or wget fails to talk to github in hadolint download.
    # https://unix.stackexchange.com/a/445609
    ca-certificates \
    git \
    # Install -gtk3 version to get +clipboard
    vim-gtk3 \
    # hadolint is a linter detected by ALE
 && wget && wget https://github.com/hadolint/hadolint/releases/download/v1.16.3/hadolint-Linux-x86_64 \
 && chmod +x hadolint-Linux-x86_64 \
 && mv hadolint-Linux-x86_64 /usr/local/bin/hadolint \
 && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --uid $INTERNAL_UID $INTERNAL_USER

USER $INTERNAL_UID
ENV HOME=/home/$INTERNAL_USER
WORKDIR $HOME

RUN git clone --bare "https://github.com/davidvandebunte/dotfiles" "$HOME/.dotf" \
 && dotf() { /usr/bin/git --git-dir=$HOME/.dotf/ --work-tree=$HOME $@ ; } \
 && dotf checkout \
 && dotf submodule update --init --recursive
