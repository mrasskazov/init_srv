#!/bin/bash -e

function fatal() {
    local EXITCODE=$1
    shift
    echo $@
    exit $EXITCODE
}

[ -z "$1" ] && fatal 1 "Using: $0 <new_hostname>"

set -x

# install etckeeper and git
sudo apt-get -y install git
sudo apt-get -y install etckeeper
sudo sed -e 's|.*\(VCS="git"\)|\1|' -i /etc/etckeeper/etckeeper.conf
sudo sed -e 's|.*\(VCS="bzr"\)|#\1|' -i /etc/etckeeper/etckeeper.conf
sudo etckeeper init
sudo etckeeper commit "Initial: etckeeper and git"


# change hostname ($1)
sudo hostname $1
echo $1 | sudo tee /etc/hostname
sudo sed -e '/^127\.0\.0\.1.*/ d' -i /etc/hosts
sudo sed -e '1 i 127.0.0.1 localhost' -i /etc/hosts
sudo sed -e '1 a 127.0.0.1 '$1 -i /etc/hosts
sudo etckeeper commit "Hostname changed to $1"


#configure ssh
sudo dpkg-reconfigure openssh-server
sudo sed -e 's|.*\(GSSAPIAuthentication\).*|\1 no|' -i /etc/ssh/sshd_config
grep 'UseDNS' /etc/ssh/sshd_config && sudo sed -e 's|.*\(UseDNS\).*|\1 no|' -i /etc/ssh/sshd_config || sudo sed -e '$ a UseDNS no' -i /etc/ssh/sshd_config
sudo etckeeper commit "sshd reconfigured"

#configure vim
if [ ! -f ${HOME}/.vimrc ]; then
    wget https://raw.githubusercontent.com/mrasskazov/dotfiles/master/vimrc-base -O ${HOME}/.vimrc
    sed -e 's|^\(set cc=.*\)|"\1|' -i ${HOME}/.vimrc
fi

set +x
