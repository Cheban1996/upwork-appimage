# upwork-appimage

Scripts to automate building an AppImage of the Upwork client on an Ubuntu VM, for running on other Linux distributions.  I chose Ruby because my shell-fu is weak.  While downloading a binary file may appeal to some, others might not want that option.  For them, there's this script.

# Prerequisites

- git, obviously
- Vagrant
- Ruby (installed when you build the Trusty VM)
- Bundler (gem install bundler)

# building

First, from within the git repo, install a Vagrant VM with Trusty with the following commands:

    vagrant init ubuntu/trusty64
    vagrant up

To get into the VM, just

    vagrant ssh

The Ruby script needs to be run inside the VM as root (sudo -s).

    cd /vagrant
    chmod +x upwork.rb
    gem install bundler
    bundle install
    ./upwork.rb

This does the following:

- Installs the Prerequisites
- Downloads and installs the Upwork deb
- Copies the binary and supporting libs
- Builds the AppImage

#TODO
- Get locales to work
- Clean up Ruby code
