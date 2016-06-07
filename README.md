# upwork-appimage

Scripts to automate building an AppImage of the Upwork client on an Ubuntu VM, for running on other Linux distributions.

# Prerequisites

- Vagrant
- git, obviously


# building

First, from within the git repo, install a Vagrant VM with Trusty with the following commands:

    vagrant init ubuntu/trusty64
    vagrant up

To get into the VM, just

    vagrant ssh
