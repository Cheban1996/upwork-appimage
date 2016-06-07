#!/usr/bin/env ruby
# This app downloads and installs the 64-bit Upwork Ubuntu client inside a Vagrant VM.

require 'fileutils'
require 'open-uri'
include FileUtils

class Upimage

  def initialize(appname)
    @upurl="http://updates.team.odesk.com/binaries/v4_1_314_0_0bo6g5kfbj07y2x4/upwork_amd64.deb"
    @appname=appname
    @lowcase=appname.downcase
    @foldername="#{appname}.AppDir"
    @desktop="#{@foldername}/#{@lowcase}.desktop"
    @filename="#{appname}.AppImage"
  end

  def clean
    rm(self.appname) if File.exists?(self.appname)
    rm_rf(self.foldername) if File.exists?(self.appname)
  end

  def makedir
    self.clean()  # destroy old instance First
    mkdir(@foldername)
  end

  def download
    File.write("upwork_amd64.deb", Net::HTTP.get(URI.parse(self.upurl)))
  end
end

upwork = new Upimage("Upwork")
upwork.download
