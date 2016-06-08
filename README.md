# Releases

[Binary releases](https://github.com/regeya/upwork-appimage/releases).

# upwork-appimage

Scripts to automate building an AppImage of the Upwork client on an Ubuntu VM, for running on other Linux distributions.  I chose Ruby because my shell-fu is weak.  While downloading a binary file may appeal to some, others might not want that option.  For them, there's this script.  

# Why

Ubuntu and Fedora are the most popular Linux distributions, and for good reason.  However, some of us prefer to use other Linux distributions, and for open source and Free software, it's not a big issue; distributions repackage software.  Proprietary software, though, tends to be more troublesome, both because it's pre-compiled against certain libraries, and just the troublesome nature of proprietary softare on a Free Software operating system.  If you're trying to use Upwork as part of your side hustle, though, you might run into a situation where you need to run their client software.

Upwork is in Arch's User Repository, and the developer does a great job of packaging the software.  The way Upwork has chosen to distribute their software, though, is for the client software to download the newest packages rather than creating repositories for those distributions.  This means that for those of us not running Ubuntu or Fedora, new releases sneak up on us.  And sometimes, it means that fixing problems for distributions like Arch can raise a whole new set of problems.

Enter AppImage, which can create ISO filesystems with a binary header.  This allows us to package all the necessary binaries and libraries into a single compressed package which, if all goes well, Just Works.

This repository contains a quick and dirty Ruby script for building an Upwork AppImage from a clean Ubuntu installation.

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
- Error handling
