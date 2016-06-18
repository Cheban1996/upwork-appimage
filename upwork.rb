#!/usr/bin/env ruby
# This app downloads and installs the 64-bit Upwork Ubuntu client inside a Vagrant VM.
# run as 'sudo ./upwork.rb'
# And yes, I know, system calls are a really bad ida.
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

# Now, the Upwork prerequisites

system %q{apt-get -y install acl at-spi2-core colord dbus dbus-x11 \
  dconf-gsettings-backend dconf-service \
  fontconfig fontconfig-config fonts-dejavu-core gconf-service \
  gconf-service-backend gconf2 gconf2-common gcr gksu gnome-keyring \
  hicolor-icon-theme krb5-locales libapparmor1 libasn1-8-heimdal libasound2 \
  libasound2-data libatk-bridge2.0-0 libatk1.0-0 libatk1.0-data libatspi2.0-0 \
  libavahi-client3 libavahi-common-data libavahi-common3 libcairo-gobject2 \
  libcairo2 libcap-ng0 libcolord1 libcolorhug1 libcups2 libdatrie1 \
    libdbus-glib-1-2 libdconf1 libdrm-intel1 libdrm-nouveau2 libdrm-radeon1 \
  libelf1 libexif12 libfontconfig1 libfreetype6 libgck-1-0 libgconf-2-4 \
  libgcr-3-common libgcr-base-3-1 libgcr-ui-3-1 libgd3 libgdk-pixbuf2.0-0 \
  libgdk-pixbuf2.0-common libgksu2-0 libgl1-mesa-dri libgl1-mesa-glx \
  libglapi-mesa libglib2.0-0 libglib2.0-data libglu1-mesa \
  libgnome-keyring-common libgnome-keyring0 libgphoto2-6 libgphoto2-l10n \
  libgphoto2-port10 libgraphite2-3 libgssapi-krb5-2 libgssapi3-heimdal \
  libgtk-3-0 libgtk-3-bin libgtk-3-common libgtk2.0-0 libgtk2.0-bin \
  libgtk2.0-common libgtkglext1 libgtop2-7 libgtop2-common libgudev-1.0-0 \
  libgusb2 libharfbuzz0b libhcrypto4-heimdal libheimbase1-heimdal \
  libheimntlm0-heimdal libhx509-5-heimdal libice6 libieee1284-3 libjasper1 \
  libjbig0 libjpeg-turbo8 libjpeg8 libk5crypto3 libkeyutils1 \
  libkrb5-26-heimdal libkrb5-3 libkrb5support0 liblcms2-2 libldap-2.4-2 \
  libllvm3.4 libltdl7 libnspr4 libnss3 libnss3-nssdb libp11-kit-gnome-keyring \
  libpam-gnome-keyring libpam-systemd libpango-1.0-0 libpango1.0-0 \
  libpangocairo-1.0-0 libpangoft2-1.0-0 libpangox-1.0-0 libpangoxft-1.0-0 \
  libpciaccess0 libpixman-1-0 libpolkit-agent-1-0 libpolkit-backend-1-0 \
  libpolkit-gobject-1-0 libpython-stdlib libpython2.7-minimal \
  libpython2.7-stdlib libroken18-heimdal libsane libsane-common libsasl2-2 \
  libsasl2-modules libsasl2-modules-db libsm6 libstartup-notification0 \
  libsystemd-daemon0 libsystemd-login0 libthai-data libthai0 libtiff5 \
  libtxc-dxtn-s2tc0 libusb-1.0-0 libv4l-0 libv4lconvert0 libvpx1 \
  libwayland-client0 libwayland-cursor0 libwind0-heimdal libx11-6 libx11-data \
  libx11-xcb1 libxau6 libxcb-dri2-0 libxcb-dri3-0 libxcb-glx0 libxcb-present0 \
  libxcb-render0 libxcb-shm0 libxcb-sync1 libxcb-util0 libxcb1 libxcomposite1 \
  libxcursor1 libxdamage1 libxdmcp6 libxext6 libxfixes3 libxft2 libxi6 \
  libxinerama1 libxkbcommon0 libxml2 libxmu6 libxmuu1 libxpm4 libxrandr2 \
  libxrender1 libxshmfence1 libxss1 libxt6 libxtst6 libxxf86vm1 p11-kit \
  p11-kit-modules policykit-1 psmisc python python-minimal python2.7 \
  python2.7-minimal sgml-base shared-mime-info systemd-services systemd-shim \
  x11-common xauth xml-core xdg-utils}

# Now install downgraded libnss.  This is necessary for the current Upwork client to run.

system "apt-get -y --force-yes install libnss3=2:3.15.4-1ubuntu7 libnss3-nssdb=2:3.15.4-1ubuntu7"
system "apt-mark hold libnss3 libnss3-nssdb"

puts upwork.debname

upwork.download # Snag a new copy of the .deb, unless it's marked false above

system "dpkg -i #{upwork.debname}"

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
