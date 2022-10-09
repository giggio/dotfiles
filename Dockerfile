FROM ubuntu:22.04
ARG USER=user
ARG PASSWORD=p
RUN apt-get update && \
    apt-get install -y git sudo whois vim
RUN useradd -ms /bin/bash $USER -p `mkpasswd $PASSWORD`
RUN usermod -aG sudo $USER
# as per https://github.com/sudo-project/sudo/issues/42#issuecomment-609079906
RUN echo "Set disable_coredump false" >> /etc/sudo.conf
USER $USER
WORKDIR /home/$USER/
COPY --chown=$USER:$USER .gitmodules .gitignore /home/$USER/.dotfiles/
COPY --chown=$USER:$USER .git /home/$USER/.dotfiles/.git/
RUN cd $HOME/.dotfiles/ && git submodule update --init --recursive
COPY --chown=$USER:$USER . /home/$USER/.dotfiles/
