# https://hub.docker.com/_/ubuntu
FROM ubuntu:bionic-20190424

# Non-root user
ARG INTERNAL_USER="internal"
ARG INTERNAL_UID="1000"
ARG INTERNAL_GID="100"

ENV DEBIAN_FRONTEND=noninteractive

# Install tools as administrator:
# https://askubuntu.com/a/6903/612216
#
# For the list of available ale linters, see :help ale-support.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    # Install certificates or wget fails to talk to github in hadolint download.
    # https://unix.stackexchange.com/a/445609
    ca-certificates \
    git \
    python3 python3-pip python3-setuptools \
    shellcheck \
    tree \
    # Install -gtk3 version to get +clipboard
    vim-gtk3 \
    wget \
    # hadolint is a linter detected by ALE
 && wget https://github.com/hadolint/hadolint/releases/download/v1.16.3/hadolint-Linux-x86_64 \
 && chmod +x hadolint-Linux-x86_64 \
 && mv hadolint-Linux-x86_64 /usr/local/bin/hadolint \
 && rm -rf /var/lib/apt/lists/*

# Advantages to builder pattern:
# - Remove wget (but you might want this anyways)

RUN useradd --create-home --shell /bin/bash --uid $INTERNAL_UID $INTERNAL_USER

USER $INTERNAL_UID
ENV HOME=/home/$INTERNAL_USER
WORKDIR $HOME

# 'pip3 install gitlint cmakelint --user' puts tools in .local/bin
ENV PATH="${HOME}/.local/bin:${PATH}"

# Install whatever can be installed as the non-root user.
#
# Install pip packages as the user:
# https://stackoverflow.com/a/42021993
# https://askubuntu.com/a/802594/612216
RUN git clone --bare "https://github.com/davidvandebunte/dotfiles" "$HOME/.dotf" \
 && dotf() { /usr/bin/git --git-dir=$HOME/.dotf/ --work-tree=$HOME $@ ; } \
 && dotf checkout \
 && dotf submodule update --init --recursive \
 && pip3 install wheel --user \
 && pip3 install gitlint cmakelint --user
