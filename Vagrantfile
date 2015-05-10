# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.define "puppet" do |puppet|
    puppet.vm.box = "chef/centos-7.0"
    puppet.vm.network "private_network", ip: "192.168.51.10", virtualbox__intnet: "puppet"
    puppet.vm.hostname = "puppet"
    puppet.vm.provision "shell", path: "puppet.sh"
  end

  config.vm.define "node1" do |node1|
    node1.vm.box = "chef/centos-7.0"
    node1.vm.network "private_network", ip: "192.168.51.11", virtualbox__intnet: "puppet"
    node1.vm.hostname = "node1"
    node1.vm.provision "shell", path: "puppet.sh"
  end

  config.vm.define "node2" do |node2|
    node2.vm.box = "ubuntu/trusty64"
    node2.vm.network "private_network", ip: "192.168.51.12", virtualbox__intnet: "puppet"
    node2.vm.hostname = "node2"
    node2.vm.provision "shell", path: "puppet.sh"
  end
end
