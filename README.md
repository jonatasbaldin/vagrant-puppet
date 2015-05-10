# Vagrant + bash = Puppet!

A Vagrant environment orchestrated with bash to create a Puppet Lab.

Just `vagrant ssh puppet` and start playing!

# What do we have here?

  * Vagrant env with three boxes
  * One simple bash script to orchestrate (almost idempotent)
    * /etc/resolv.conf and /etc/hosts configured

  * Puppet Master (192.168.51.10)
    * CentOS 7
    * Environments working (production and testing)
    * Autosign to testing purposes

  * Puppet Agents
    * CentOS 7 (192.168.51.11) and Ubuntu 14.04 (1921.68.51.12)
    * First in production, second in testing

Enjoy!
