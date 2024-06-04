if [ -S "$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh" ] || systemctl --user is-enabled gpg-agent-ssh.socket -q &> /dev/null; then
  # forward ssh socket to gpg
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"
elif ! [ -v SSH_AUTH_SOCK ]; then
  PID_FILE="$HOME/.ssh/ssh_pid"
  SSH_AUTH_SOCK="$HOME/.ssh/ssh.sock"
  if [ -S "$SSH_AUTH_SOCK" ]; then
    # use existing ssh-agent
    export SSH_AUTH_SOCK
    if [ -f "$PID_FILE" ]; then
      SSH_AGENT_PID="`cat "$PID_FILE"`"
      export SSH_AGENT_PID
    fi
  else
    # start a new ssh-agent
    if ! [ -d "$HOME"/.ssh ]; then
      mkdir -p "$HOME/.ssh"
      chmod 700 "$HOME/.ssh"
    fi
    eval "`ssh-agent -s -a "$SSH_AUTH_SOCK"`" > /dev/null
    echo "$SSH_AGENT_PID" > "$PID_FILE"
  fi
fi
