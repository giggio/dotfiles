FROM ubuntu:22.04
ARG USER=user
ARG PASSWORD=p
RUN apt-get update && \
    apt-get install -y git sudo whois vim
RUN useradd -ms /bin/bash $USER -p `mkpasswd $PASSWORD`
RUN usermod -aG sudo $USER
USER $USER
WORKDIR /home/$USER/
COPY --chown=$USER:$USER .git /home/$USER/.dotfiles/.git/
WORKDIR /home/$USER/.dotfiles/
RUN git checkout main && git checkout -- . && git submodule update --init --recursive
