#!/bin/bash -e
################################################################################
##  File:  install-ms-repos.sh
##  Desc:  Install official Microsoft package repos for the distribution
################################################################################

os_label=$(lsb_release -rs)

# Install Microsoft repository
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb

# update
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common -y
sudo apt-get update -y
#apt-get dist-upgrade
