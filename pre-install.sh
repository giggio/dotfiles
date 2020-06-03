#!/usr/bin/env bash

set -euo pipefail

echo -e "\e[34mInstalling Python 2 and 3 Setting the default Python to version 3.\e[0m"
sudo apt-get update
sudo apt-get install -y python2.7 python3.8
sudo update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.8 2
sudo update-alternatives  --set python /usr/bin/python3.8

echo -e "\e[34mUpgrading all packages.\e[0m"
sudo apt-get upgrade -y

echo -e "\e[34mSetting default time zone to São Paulo.\e[0m"
sudo ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
