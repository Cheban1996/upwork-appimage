#!/usr/bin/env ruby
# This app downloads and installs the 64-bit Upwork Ubuntu client inside a Vagrant VM.
# run as 'sudo ./upwork.rb'
# And yes, I know, system calls are a really bad idea.
require 'fileutils'
require 'net/http'
require 'uri'
require 'progressbar'
include FileUtils

class Upimage
  attr_reader :debname, :foldername, :bin, :lib, :filename
  def initialize(appname)
    @upurl="http://updates.team.odesk.com/binaries/v4_1_321_0_jyypcrocn10is1qc/upwork_amd64.deb"
    @appname=appname
    @lowcase=appname.downcase
    @foldername="#{appname}.AppDir"
    @desktop="#{@foldername}/#{@lowcase}.desktop"
    @filename="#{appname}.AppImage"
    @debname="upwork_amd64.deb"
    @deskfile="[Desktop Entry]\nName=Upwork\nExec=upwork\nIcon=upwork.png"
    @usr ="#{@foldername}/usr"
    @bin="#{@usr}/bin"
    @lib="#{@usr}/lib"
    @blacklist = []
  end

  def clean
    rm(@appname) if File.exists?(@appname)
    rm_rf(@foldername) if File.exists?(@foldername)
    rm(@debname) if File.exists?(@debname)
    rm(@filename) if File.exists?(@filename)
  end

  def makedir
    self.clean()  # destroy old instance First
    mkdir(@foldername)
    usr = @foldername + "/usr"
    mkdir(usr)
    %w{bin lib}.each {|f| mkdir "#{usr}/#{f}" }
  end

  def deskfile
    File.open(@desktop, "w") {|f| f.write(@deskfile)}
  end

  def read_blacklist
    raw_blacklist = File.readlines(Dir.pwd + "/AppImages/excludelist")
    @blacklist = raw_blacklist.grep(/\.so/)
    @blacklist.reject!{|f| f =~ /^#/ or f =~ /^\n/ or f =~ /nss/}
  end

  def get_libs
    self.read_blacklist
    raw_libs = `ldd /usr/share/upwork/upwork`
    split_libs = raw_libs.split("\n")
    split_libs.select! {|f| f =~ /x86_64/ }
    lib_list = []
    split_libs.each do |f|
      mysplit = f.split
      lib_list << mysplit[2]
    end
    @blacklist.each do |f|
      lib_list.delete_if {|g| g.include?(f.chomp)}
    end
    lib_list.each {|f| cp f, @lib}
    Dir.glob("/usr/share/upwork/*.so").each {|f| cp f, @lib}
    Dir.glob("/usr/lib/x86_64-linux-gnu/libnss*3*").each {|f| cp f, @lib}
    # Adding this explicitly for now.  Adding /usr/lib entries picks up things
    # that cause the app to hang.
    cp "/usr/lib/libgtkglext-x11-1.0.so.0", @lib
    cp "/usr/lib/libgdkglext-x11-1.0.so.0", @lib
    cp_r "/usr/lib/x86_64-linux-gnu/nss/", @lib
  end

  def download
    # i decided to do the download in Ruby rather than rely on wget or whatever
    url_base = @upurl.split('/')[2]
    url_path = '/'+@upurl.split('/')[3..-1].join('/')
    @counter = 0
    Net::HTTP.start(url_base) do |http|
      response = http.request_head(URI.escape(url_path))
      ProgressBar#format_arguments=[:title, :percentage, :bar, :stat_for_file_transfer]
      pbar = ProgressBar.new("file name:", response['content-length'].to_i)
      File.open(@debname, "w") {|f|
        http.get(URI.escape(url_path)) do |str|
          f.write str
        @counter += str.length
        pbar.set(@counter)
      end
      }
      pbar.finish
    end
  end
end

upwork = Upimage.new("Upwork")
upwork.clean # Remove old cruft if it's still around

# If you set up a fresystem, up-to-date vagrant vm, it should be up to date.
# But let's make sure.

system "apt-get update"
system "apt-get -y upgrade"

# Now, install the AppImage prerequisites
system "apt-get -y install libfuse-dev libglib2.0-dev cmake git libc6-dev binutils fuse"

puts upwork.debname

upwork.download # Snag a new copy of the .deb, unless it's marked false above

system "dpkg -i #{upwork.debname}"
system "apt-get -fy install"
system "apt-get -y --force-yes install libnss3=2:3.15.4-1ubuntu7 libnss3-nssdb=2:3.15.4-1ubuntu7"
system "apt-mark hold libnss3 libnss3-nssdb"

puts "Now building AppImageKit"

curdir = Dir.pwd
Dir.chdir("#{curdir}/AppImageKit")
['git reset --hard', 'git clean -f -d', 'cmake .', 'make'].each {|f| system f}
Dir.chdir(curdir)

upwork.makedir
upwork.deskfile

["AppImageKit/AppRun",
 "/usr/share/pixmaps/upwork.png"].each {|f| cp f, upwork.foldername}
cp "/usr/share/upwork/upwork", upwork.bin
["pak", "bin", "dat"].each do |f|
  Dir.glob("/usr/share/upwork/*.#{f}").each {|g| cp g, upwork.bin}
end
Dir.glob("/usr/share/upwork/locales/*.pak").each {|f| cp f, upwork.bin} # seems to be necessary
upwork.get_libs
system "#{Dir.pwd}/AppImageKit/AppImageAssistant #{upwork.foldername} #{upwork.filename}"
