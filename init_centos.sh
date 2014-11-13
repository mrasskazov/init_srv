#!/bin/bash -e

function fatal() {
    local EXITCODE=$1
    shift
    echo $@
    exit $EXITCODE
}

[ -z "$1" ] && fatal 1 "Using: $0 <new_hostname>"

set -x

if [ "$(awk -F '=' '/^ONBOOT/ {print $NF}' /etc/sysconfig/network-scripts/ifcfg-eth0)" != "yes" ]; then
    sudo sed -e 's|^\(ONBOOT\)=.*|\1=yes|' -i /etc/sysconfig/network-scripts/ifcfg-eth0
    sudo ifup eth0
fi

sudo yum -y install acpid
sudo service acpid start

sudo yum -y install wget

# EPEL
[ $(rpm -qa | grep '^epel-release') ] || \
(
    PLATFORM=$(uname -i)
    RELEASE=$(grep -o '[0-9]\+' /etc/centos-release | head -n1)
    REPO_URL="http://dl.fedoraproject.org/pub/epel/${RELEASE}/${PLATFORM}"
    (("$RELEASE" >= 7)) && REPO_URL+="/e"
    EPEL_PKG=$(wget -qO- ${REPO_URL} | grep -oE 'epel-release[a-zA-Z0-9_\.\-]*\.rpm' | head -n1)
    wget ${REPO_URL}/${EPEL_PKG}
    sudo rpm -Uvh ${EPEL_PKG}
)

# install etckeeper and git
sudo yum -y install git
sudo yum -y install etckeeper
sudo sed -e 's|.*\(VCS="git"\)|\1|' -i /etc/etckeeper/etckeeper.conf
sudo sed -e 's|.*\(VCS="bzr"\)|#\1|' -i /etc/etckeeper/etckeeper.conf
sudo etckeeper init
sudo etckeeper commit "Initial: etckeeper and git"

sudo yum -y install screen 

#install and configure vim
sudo yum -y install vim-enhanced
if [ ! -f ${HOME}/.vimrc ]; then
    wget https://raw.githubusercontent.com/mrasskazov/dotfiles/master/vimrc-base -O ${HOME}/.vimrc
    sed -e 's|^\(set cc=.*\)|"\1|' -i ${HOME}/.vimrc
fi

# change hostname ($1)
sudo hostname $1
sudo sed -e 's|^\(HOSTNAME\)=.*|\1='$1'|' -i /etc/sysconfig/network
#sudo sed -e '/^127\.0\.0\.1.*/ d' -i /etc/hosts
#sudo sed -e '1 i 127.0.0.1 localhost' -i /etc/hosts
#sudo sed -e '1 a 127.0.0.1 '$1 -i /etc/hosts
sudo etckeeper commit "Hostname changed to $1"

#configure ssh
sudo sed -e 's|.*\(GSSAPIAuthentication\).*|\1 no|' -i /etc/ssh/sshd_config
grep 'UseDNS' /etc/ssh/sshd_config && sudo sed -e 's|.*\(UseDNS\).*|\1 no|' -i /etc/ssh/sshd_config || sudo sed -e '$ a UseDNS no' -i /etc/ssh/sshd_config
sudo etckeeper commit "sshd reconfigured"

set +x
