FROM ubuntu:24.04
ARG USER=user
ARG PASSWORD=p
RUN apt-get update
RUN apt-get install -y git sudo whois vim
RUN useradd -ms /bin/bash $USER -p `mkpasswd $PASSWORD` --home-dir /home/$USER && usermod -aG sudo $USER
USER $USER
# WORDIR is after USER to avoid permission issues
WORKDIR /home/$USER/
COPY --chown=$USER:$USER .git /home/$USER/.dotfiles/.git/
RUN cd .dotfiles && git checkout main && git checkout -- . && git submodule update --init --recursive
