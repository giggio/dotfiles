#!/usr/bin/env bash

# todo: remove when fixed: https://github.com/jstaf/onedriver/issues/293
# todo: move to system-manager when this is fixed: https://github.com/numtide/system-manager/issues/301

my_user=giggio
my_uid=$(id -u $my_user)
instance=home-giggio-onedrive

case "$1" in
  pre)
    # about to suspend
    if XDG_RUNTIME_DIR=/run/user/$my_uid runuser -u $my_user -- systemctl --user list-units onedriver@$instance.service | grep onedriver@$instance.service > /dev/null; then
      echo "Stopping service onedriver@$instance.service"
      XDG_RUNTIME_DIR=/run/user/$my_uid runuser -u $my_user -- systemctl --user stop onedriver@"$instance".service
    else
      echo "Service onedriver@$instance.service does not exist, nothing to stop."
    fi
    ;;
  post)
    # just resumed
    if XDG_RUNTIME_DIR=/run/user/$my_uid runuser -u $my_user -- systemctl --user list-units onedriver@$instance.service | grep onedriver@$instance.service > /dev/null; then
      echo "Starting service onedriver@$instance.service"
      XDG_RUNTIME_DIR=/run/user/$my_uid runuser -u $my_user -- systemctl --user start onedriver@"$instance".service
    else
      echo "Service onedriver@$instance.service does not exist, nothing to start."
    fi
    ;;
esac
