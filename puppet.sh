#!/usr/bin/env bash

set -e

confdir="/etc/puppet"

sethosts() {
    echo "127.0.0.1 localhost" > /etc/hosts
    echo "127.0.0.1 $(hostname) $(hostname).lab" >> /etc/hosts
    echo "192.168.51.10 puppet puppet.lab" >> /etc/hosts
    echo "192.168.51.11 node1 node1.lab" >> /etc/hosts
    echo "192.168.51.12 node2 node2.lab" >> /etc/hosts
}

setresolv() {
    echo "domain lab" > /etc/resolv.conf
    echo "search lab" >> /etc/resolv.conf
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
    # fix the nonpersistent resolv.conf
    if [[ ! -e /etc/dhcp/dhclient-enter-hooks ]] ; then
        cp /vagrant/dhclient-enter-hooks /etc/dhcp/ && chmod +x /etc/dhcp/dhclient-enter-hooks
    fi
}

if [[ $(hostname) = "puppet" ]] ; then

    # /etc/hosts && /etc/resolv.conf
    sethosts
    setresolv

    # Install packages
    if ! rpm -qa | grep puppet-3* > /dev/null; then
        rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
        yum install puppet-server -y
    fi 

    # Config environments
    if [[ -d $confdir/manifests ]] && [[ -d $confdir/modules ]] ; then
        rm -fr $confdir/manifests
        rm -fr $confdir/modules
    fi
    if [[ ! -d $confidir/environments/production ]] && [[ ! -d $confdir/environments/testing ]] ; then
        mkdir -p $confdir/environments/production/{manifests,modules}
        mkdir -p $confdir/environments/testing/{manifests,modules}
    fi
    yes | cp -rf /vagrant/master-puppet.conf $confdir/puppet.conf

    # Autosign
    echo "*" > $confdir/autosign.conf

    # Services
    systemctl disable NetworkManager
    systemctl start puppetmaster
    systemctl enable puppetmaster

elif [[ $(hostname) = "node1" ]] ; then

    # /etc/hosts && /etc/resolv.conf
    sethosts
    setresolv

    # Packages
    if ! rpm -qa | grep puppet-3* > /dev/null ; then
        rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
        yum install puppet -y
    fi
    
    # Puppet conf
    puppet agent --test --waitforcert 15

    # Services
    systemctl disable NetworkManager
    systemctl start puppet
    systemctl enable puppet

elif [[ $(hostname) = "node2" ]] ; then

    # Fix nonpersistent resolv.conf
    # ALL this because the package resolvconf shows a splash screen while being removed
    # That splash breaks the orchestration, exists with error and cause CHAOS 
    # http://jim.rees.org/computers/resolv.html
    if [[ -h /etc/resolv.conf ]] ; then
        rm -rf /etc/resolv.conf
        touch /etc/resolv.conf
    fi
    if [[ -e /sbin/resolvconf ]] ; then
        mv /sbin/resolvconf /sbin/resolvconf- && cp -p /bin/true /sbin/resolvconf
    fi
    sed -i '/^  *mv/s/^/#/' /sbin/dhclient-script
    # populate /etc/resolv.conf
    chattr -i /etc/resolv.conf
    setresolv
    chattr +i /etc/resolv.conf

    # /etc/hosts
    sethosts

    # Packages
    if ! dpkg -l | grep puppetlabs > /dev/null ; then
        wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb -P /usr/src/
        dpkg -i /usr/src/puppetlabs-release-trusty.deb
        apt-get update
        apt-get install puppet -y
    fi
    
    # Puppet conf
    sed -i 's/START=no/START=yes/' /etc/default/puppet
    sed -i '/templatedir/d' $confdir/puppet.conf 
    puppet agent --enable
    puppet agent --test --waitforcert 15

    # node2 on testing env
    if ! grep environment $confdir/puppet.conf > /dev/null ; then
        echo "environment = testing" >> $confdir/puppet.conf 
    fi

    # Service
    if ! service puppet status > /dev/null ; then
        service puppet start
    fi
    update-rc.d puppet defaults

fi
