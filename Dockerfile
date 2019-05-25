# https://hub.docker.com/_/ubuntu
FROM ubuntu:bionic-20190424

# Non-root user
ARG INTERNAL_USER="internal"
ARG INTERNAL_UID="1000"

ENV DEBIAN_FRONTEND=noninteractive

# Required by proselint
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Install tools as administrator:
# https://askubuntu.com/a/6903/612216
#
# For the list of available ale linters, see :help ale-support.
RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
    build-essential \
    # Install certificates or wget fails to talk to github in hadolint download.
    # https://unix.stackexchange.com/a/445609
    ca-certificates \
    ccache \
    clang-6.0 \
    clang-format-6.0 \
    clang-tidy-6.0 \
    # Primarily for clang-tidy
    clang-tools-6.0 \
    curl \
    git \
    # OpenMP is required for many C++ programs
    # https://askubuntu.com/a/903982/612216
    libomp-dev \
    # SSL is required to compile many C++ programs
    libssl-dev \
    openjdk-8-jre \
    python3 python3-pip python3-setuptools \
    # https://github.com/amperser/proselint
    python3-proselint \
    shellcheck \
    tree \
    unzip \
    # Install -gtk3 version to get +clipboard
    # https://stackoverflow.com/a/11489440/622049
    vim-gtk3 \
    wget \
 && wget https://github.com/redpen-cc/redpen/releases/download/redpen-1.10.1/redpen-1.10.1.tar.gz \
 && tar xvf redpen-1.10.1.tar.gz \
    # hadolint is a linter detected by ALE
 && wget https://github.com/hadolint/hadolint/releases/download/v1.16.3/hadolint-Linux-x86_64 \
 && chmod +x hadolint-Linux-x86_64 \
 && mv hadolint-Linux-x86_64 /usr/local/bin/hadolint \
    # The package clang-tools-6.0 installs an executable named clang-tidy-6.0 and puts
    # it on the PATH. ALE looks for an executable named "clang-tidy" (without the
    # version on the end). Add this mapping so ALE finds clang-tidy; similarly for
    # clang-check.
 && update-alternatives --install /usr/bin/clang-check clang-check /usr/bin/clang-check-6.0 100 \
 && update-alternatives --install /usr/bin/clang-tidy  clang-tidy  /usr/bin/clang-tidy-6.0  100 \
    # https://www.digitalocean.com/community/tutorials/how-to-install-node-js-on-ubuntu-18-04#installing-using-a-ppa
 && curl -sL https://deb.nodesource.com/setup_10.x -o nodesource_setup.sh \
 && bash nodesource_setup.sh \
 && apt-get install --yes --no-install-recommends nodejs \
    # https://github.com/w0rp/ale/blob/master/ale_linters/markdown/markdownlint.vim
    # https://github.com/DavidAnson/markdownlint
    # https://github.com/igorshubovych/markdownlint-cli
 && npm install markdownlint --save-dev \
 && npm install -g markdownlint-cli \
 && wget https://releases.hashicorp.com/terraform/0.11.14/terraform_0.11.14_linux_amd64.zip \
 && unzip terraform_0.11.14_linux_amd64.zip \
 && mv terraform /usr/local/bin/ \
 && rm -rf /var/lib/apt/lists/*

ENV PATH="/redpen-distribution-1.10.1/bin/:${PATH}"

# Advantages to builder pattern:
# - Remove wget (but you might want this anyways)
# - More build stages so you bust the cache less

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
#
# We must install the dotfiles to a ".cfg" directory because ".cfg"
# is hard-coded into the .bash_aliases file in the dotfiles we check
# out.
RUN git clone --bare "https://github.com/davidvandebunte/dotfiles" "$HOME/.cfg" \
 && dotf() { /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@ ; } \
 && dotf checkout \
 && dotf submodule update --init --recursive \
 # See: https://stackoverflow.com/a/36410649/622049
 && dotf config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' \
 && dotf fetch \
 # Set the upstream of the branch you checked out so "dotf rpull" works
 # as expected. Run "dotf branch -vv" to verify your upstream branch.
 && dotf branch -u origin/master \
 && pip3 install wheel --user \
 && pip3 install gitlint cmakelint --user
