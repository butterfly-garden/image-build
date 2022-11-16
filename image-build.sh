#!/usr/bin/env bash

if [ -z "${SUDO_USER}" ]; then
    echo "ERROR! You must use sudo to run this script: sudo ./$(basename "${0}")"
    exit 1
fi

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# The brand name of the distribution
TARGET_DISTRO_NAME="Ubuntu Butterfly"

# The version of Ubuntu to generate.
# - Successfully tested: kinetic
# - See https://wiki.ubuntu.com/DevelopmentCodeNames for details
TARGET_UBUNTU_VERSION="22.10"
TARGET_ARCH="amd64"

# The packaged version of the Linux kernel to install on target image.
# See https://wiki.ubuntu.com/Kernel/LTSEnablementStack for details
TARGET_KERNEL_PACKAGE="linux-generic"

# The file (no extension) of the ISO containing the generated disk image,
# the volume id, and the hostname of the live environment are set from this name.
TARGET_NAME="${TARGET_DISTRO_NAME// /-}"
TARGET_NAME="${TARGET_NAME,,}"

# Shorthand for where the root filesystem is located
MACHINE="/var/lib/machines/${TARGET_NAME}"

# The text label shown in GRUB for booting into the live environment
GRUB_LIVEBOOT_LABEL="Try ${TARGET_DISTRO_NAME}"

# The text label shown in GRUB for starting installation
GRUB_INSTALL_LABEL="Install ${TARGET_DISTRO_NAME}"

# Packages to be removed from the target system after installation completes succesfully
TARGET_PACKAGE_REMOVE="
    ubiquity \
    casper \
    discover \
    laptop-detect \
    os-prober \
"

function host_setup() {
    # Host tools
    apt-get -y install \
        binutils dosfstools grub-pc-bin grub-efi-amd64-bin mtools \
        squashfs-tools wget unzip  xorriso

    # Download machinespawn
    if ! command -v machinespawn >/dev/null 2>&1; then
        if ! wget --quiet --show-progress --progress=bar:force:noscroll "https://raw.githubusercontent.com/wimpysworld/machinespawn/main/machinespawn" -O /usr/local/bin/machinespawn; then
            echo "Failed to download machinespawn. Deleting /usr/local/bin/machinespawn..."
            rm "/usr/local/bin/${FILE}" 2>/dev/null
            exit 1
        else
            chmod +x /usr/local/bin/machinespawn
        fi
    fi
}

function bootstrap_container() {
    if [ -d "${MACHINE}" ]; then
        machinespawn remove "${TARGET_NAME}"
    fi
    machinespawn bootstrap ubuntu-${TARGET_UBUNTU_VERSION} "${TARGET_NAME}" "${TARGET_ARCH}"
}

function install_os() {
    # Install ubuntu-standard
    machinespawn run "${TARGET_NAME}" apt-get -y update
    machinespawn run "${TARGET_NAME}" apt-get -y install ubuntu-standard snapd

    # Install Live image packages
    machinespawn run "${TARGET_NAME}" apt-get -y install \
        casper discover laptop-detect memtest86+ os-prober grub-common \
        grub-gfxpayload-lists grub-pc grub-pc-bin grub2-common locales

    # Install kernel
    machinespawn run "${TARGET_NAME}" apt-get -y --no-install-recommends install "${TARGET_KERNEL_PACKAGE}"

    # Install Ubiquity - the legacy installer
    machinespawn run "${TARGET_NAME}" apt-get -y install \
        ubiquity ubiquity-casper ubiquity-frontend-gtk ubiquity-slideshow-ubuntu \
        ubiquity-ubuntu-artwork

    # Repository management
    machinespawn run "${TARGET_NAME}" apt-get -y install software-properties-common

    # Display manager
    machinespawn run "${TARGET_NAME}" apt-get -y --no-install-recommends install \
        lightdm lightdm-gtk-greeter yaru-theme-gtk yaru-theme-icon yaru-theme-sound \
        yaru-theme-unity

    mkdir -p "${MACHINE}/usr/share/lightdm/lightdm-gtk-greeter.conf.d/"
    cat <<EOM > "${MACHINE}/usr/share/lightdm/lightdm-gtk-greeter.conf.d/30-ubuntu-butterfly.conf"
# LightDM GTK+ Configuration
# Available configuration options listed below.
#
# Appearance:
#  theme-name = GTK+ theme to use
#  icon-theme-name = Icon theme to use
#  cursor-theme-name = Cursor theme to use
#  cursor-theme-size = Cursor size to use
#  background = Background file to use, either an image path or a color (e.g. #772953)
#  user-background = false|true ("true" by default)  Display user background (if available)
#  transition-duration = Length of time (in milliseconds) to transition between background images ("500" by default)
#  transition-type = ease-in-out|linear|none  ("ease-in-out" by default)
#
# Fonts:
#  font-name = Font to use
#  xft-antialias = false|true  Whether to antialias Xft fonts
#  xft-dpi = Resolution for Xft in dots per inch (e.g. 96)
#  xft-hintstyle = none|slight|medium|hintfull  What degree of hinting to use
#  xft-rgba = none|rgb|bgr|vrgb|vbgr  Type of subpixel antialiasing
#
# Login window:
#  active-monitor = Monitor to display greeter window (name or number). Use #cursor value to display greeter at monitor with cursor. Can be a semicolon separated list
#  position = x y ("50% 50%" by default)  Login window position
#  default-user-image = Image used as default user icon, path or #icon-name
#  hide-user-image = false|true ("false" by default)
#
# Panel:
#  panel-position = top|bottom ("top" by default)
#  clock-format = strftime-format string, e.g. %H:%M
#  indicators = semi-colon ";" separated list of allowed indicator modules. Built-in indicators include "~a11y", "~language", "~session", "~power", "~clock", "~host", "~spacer". Unity indicators can be represented by short name (e.g. "sound", "power"), service file name, or absolute path
#
# Accessibility:
#  a11y-states = states of accessibility features: "name" - save state on exit, "-name" - disabled at start (default value for unlisted), "+name" - enabled at start. Allowed names: contrast, font, keyboard, reader.
#  keyboard = command to launch on-screen keyboard (e.g. "onboard")
#  keyboard-position = x y[;width height] ("50%,center -0;50% 25%" by default)  Works only for "onboard"
#  reader = command to launch screen reader (e.g. "orca")
#  at-spi-enabled = false|true ("true" by default) Enables accessibility at-spi-command if the greeter is built with it enabled
#
# Security:
#  allow-debugging = false|true ("false" by default)
#  screensaver-timeout = Timeout (in seconds) until the screen blanks when the greeter is called as lockscreen
#
# Template for per-monitor configuration:
#  [monitor: name]
#  background = overrides default value
#  user-background = overrides default value
#  laptop = false|true ("false" by default) Marks monitor as laptop display
#  transition-duration = overrides default value
#

[greeter]
background=/usr/share/backgrounds/ubuntu-butterfly.png
theme-name=Yaru-red-dark
icon-theme-name=Yaru-red
cursor-theme-name=Yaru
font-name=Ubuntu 11
xft-antialias=true
xft-dpi=96
xft-hintstyle=slight
xft-rgba=rgb
indicators=~host;~spacer;~clock;~spacer;~session;~language;~a11y;~power;
clock-format=%d %b, %H:%M
active-monitor=#cursor
position = 15%,start 50%,center
user-background = false
EOM

    # Pipewire
    machinespawn run "${TARGET_NAME}" apt-get -y install \
        pipewire-audio-client-libraries pulsemixer wireplumber libfdk-aac2 \
        libopenaptx0 libspa-0.2-bluetooth libspa-0.2-jack

    # Language support
    machinespawn run "${TARGET_NAME}" apt-get -y --no-install-recommends install \
        language-pack-gnome-en

    # Desktop
    machinespawn run "${TARGET_NAME}" apt-get -y --no-install-recommends install \
        gnome-bluetooth gnome-control-center gnome-control-center-faces \
        gnome-session-flashback gnome-startup-applications \
        libcanberra-pulse librsvg2-2 librsvg2-bin librsvg2-common \
        network-manager-gnome tilix yaru-theme-gtk yaru-theme-icon yaru-theme-sound \
        yaru-theme-unity

    # Instruct netplan to hand all network management to NetworkManager
    cat <<EOM > "${MACHINE}/etc/netplan/01-network-manager-all.yaml"
# Let NetworkManager manage all devices on this system
network:
  version: 2
  renderer: NetworkManager
EOM

    # Install gschemas that prevent gnome-control-center from crashing
    machinespawn run "${TARGET_NAME}" apt-get -y --no-install-recommends install \
        gnome-shell-common mutter-common

    # Indicators
    machinespawn run "${TARGET_NAME}" apt-get -y --no-install-recommends install \
        gkbd-capplet gucharmap indicator-applet indicator-application \
        indicator-bluetooth indicator-datetime indicator-keyboard indicator-session \
        indicator-sound

    # Display servers and compositors
    machinespawn run "${TARGET_NAME}" apt-get -y install \
        wayfire weston xwayland xorg

    # Firefox ESR
    machinespawn run "${TARGET_NAME}" apt-add-repository -y ppa:mozillateam/ppa
    machinespawn run "${TARGET_NAME}" apt-get -y install firefox-esr

    # Wallpaper
    mkdir -p "${MACHINE}/usr/share/backgrounds"
    cp ubuntu-butterfly.png "${MACHINE}/usr/share/backgrounds/ubuntu-butterfly.png"

    # Create custom panel layout
    mkdir -p "${MACHINE}/usr/share/gnome-panel/layouts"
    cat <<EOM > "${MACHINE}/usr/share/gnome-panel/layouts/ubuntu-butterfly.layout"
[Toplevel top-panel]
expand=true
orientation=top
size=26

[Object menu-bar]
object-iid=org.gnome.gnome-panel.menu::menu-bar
toplevel-id=top-panel
pack-index=0

[Object window-list]
object-iid=org.gnome.gnome-panel.wncklet::window-list
toplevel-id=top-panel
pack-index=1

[Object indicators]
object-iid=IndicatorAppletCompleteFactory::IndicatorAppletComplete
toplevel-id=top-panel
pack-type=end
pack-index=0
EOM

    # Create gschema override
    cat <<EOM > "${MACHINE}/usr/share/glib-2.0/schemas/90_ubuntu-butterfly.gschema.override"
[org.gnome.desktop.background:GNOME-Flashback]
color-shading-type='vertical'
picture-uri='file:///usr/share/backgrounds/ubuntu-butterfly.png'
primary-color='#FF135B'
secondary-color='#F096AE'

[org.gnome.desktop.datetime:GNOME-Flashback]
automatic-timezone=true

[org.gnome.desktop.interface:GNOME-Flashback]
color-scheme='prefer-dark'
cursor-theme='Yaru'
document-font-name='Ubuntu 11'
enable-hot-corners=false
font-name='Ubuntu 11'
gtk-theme='Yaru-red-dark'
icon-theme='Yaru-red-dark'
monospace-font-name='Ubuntu Mono 13'

[org.gnome.desktop.lockdown:GNOME-Flashback]
disable-printing=true
disable-print-setup=true
disable-user-switching=true

[org.gnome.desktop.media-handling:GNOME-Flashback]
automount-open=false

[org.gnome.desktop.privacy:GNOME-Flashback]
remember-app-usage=false
remember-recent-files=false
report-technical-problems=false
send-software-usage-stats=false

[org.gnome.desktop.screensaver:GNOME-Flashback]
color-shading-type='vertical'
lock-enabled=false
picture-uri='file:///usr/share/backgrounds/ubuntu-butterfly.png'
primary-color='#FF135B'
secondary-color='#F096AE'
user-switch-enabled=false

[org.gnome.desktop.session:GNOME-Flashback]
idle-delay=0

[org.gnome.desktop.sound:GNOME-Flashback]
theme-name='Yaru'

[org.gnome.desktop.wm.preferences:GNOME-Flashback]
button-layout=':minimize,maximize,close'
theme='Yaru'
titlebar-font='Ubuntu Bold 11'
titlebar-uses-system-font=false

[org.gnome.gedit.preferences.editor]
scheme='Yaru-dark'
editor-font='Ubuntu Mono 13'

[org.gnome.gnome-flashback.desktop.background:GNOME-Flashback]
fade=true

[org.gnome.gnome-flashback.desktop.icons:GNOME-Flashback]
show-home=false
show-trash=false

[org.gnome.metacity:GNOME-Flashback]
alt-tab-thumbnails=true

[org.gnome.metacity.theme:GNOME-Flashback]
name='Yaru'

[org.gnome.gnome-panel.general:GNOME-Flashback]
default-layout='ubuntu-butterfly'
EOM
    machinespawn run "${TARGET_NAME}" glib-compile-schemas /usr/share/glib-2.0/schemas/

    # Plymouth
    machinespawn run "${TARGET_NAME}" apt-get -y install plymouth-theme-spinner
}

function clean_up() {
    machinespawn run "${TARGET_NAME}" apt-get -y upgrade
    machinespawn run "${TARGET_NAME}" apt-get -y autoremove
    machinespawn run "${TARGET_NAME}" apt-get -y autoclean
    machinespawn run "${TARGET_NAME}" apt-get -y clean

    rm -f "${B}"/{*.bak,*.old}
    rm -f "${MACHINE}"/wget-log
    rm -f "${MACHINE}"/boot/{*.bak,*.old}
    rm -f "${MACHINE}"/etc/ssh/ssh_host_*_key*
    rm -f "${MACHINE}"/etc/apt/*.save
    rm -f "${MACHINE}"/etc/apt/apt.conf.d/90cache
    rm -f "${MACHINE}"/etc/apt/sources.list.d/*.save
    rm -f "${MACHINE}"/root/.wget-hsts
    rm -rf "${MACHINE}"/tmp/*
    rm -f "${MACHINE}"/var/log/apt/*
    rm -f "${MACHINE}"/var/log/alternatives.log
    rm -f "${MACHINE}"/var/log/bootstrap.log
    rm -f "${MACHINE}"/var/log/dpkg.log
    rm -f "${MACHINE}"/var/log/fontconfig.log
    rm -f "${MACHINE}"/var/cache/debconf/*-old
    rm -f "${MACHINE}"/var/cache/deb-get/*.json
    rm -f "${MACHINE}"/var/cache/fontconfig/CACHEDIR.TAG
    rm -f "${MACHINE}"/var/crash/*
    rm -rf "${MACHINE}"/var/lib/apt/lists/*
    rm -f "${MACHINE}"/var/lib/dpkg/*-old
    [ -L "${MACHINE}"/var/lib/dbus/machine-id ] || rm -f "${MACHINE}"/var/lib/dbus/machine-id
    echo '' > "${MACHINE}"/etc/machine-id
}

function build_image() {
    rm -rf image
    mkdir -p image/{casper,isolinux,install}

    # copy kernel files
    cp -v ${MACHINE}/boot/vmlinuz-**-**-generic image/casper/vmlinuz
    cp -v ${MACHINE}/boot/initrd.img-**-**-generic image/casper/initrd

    # memtest86
    cp -v ${MACHINE}/boot/memtest86+.bin image/install/memtest86+
    wget --quiet --show-progress --progress=bar:force:noscroll "https://www.memtest86.com/downloads/memtest86-usb.zip" -O image/install/memtest86-usb.zip
    unzip -p image/install/memtest86-usb.zip memtest86-usb.img > image/install/memtest86
    rm -f image/install/memtest86-usb.zip

    # grub
    touch image/ubuntu
    cat <<EOF > image/isolinux/grub.cfg

search --set=root --file /ubuntu

insmod all_video

set default="0"
set timeout=30

menuentry "${GRUB_LIVEBOOT_LABEL}" {
   linux /casper/vmlinuz boot=casper nopersistent toram quiet splash ---
   initrd /casper/initrd
}

menuentry "${GRUB_INSTALL_LABEL}" {
   linux /casper/vmlinuz boot=casper only-ubiquity quiet splash ---
   initrd /casper/initrd
}

menuentry "Check disc for defects" {
   linux /casper/vmlinuz boot=casper integrity-check quiet splash ---
   initrd /casper/initrd
}

menuentry "Test memory Memtest86+ (BIOS)" {
   linux16 /install/memtest86+
}

menuentry "Test memory Memtest86 (UEFI, long load time)" {
   insmod part_gpt
   insmod search_fs_uuid
   insmod chain
   loopback loop /install/memtest86
   chainloader (loop,gpt1)/efi/boot/BOOTX64.efi
}
EOF

    # generate manifest
    machinespawn run "${TARGET_NAME}" dpkg-query -W --showformat='${Package} ${Version}\n' | tee image/casper/filesystem.manifest
    cp -v image/casper/filesystem.manifest image/casper/filesystem.manifest-desktop
    for pkg in ${TARGET_PACKAGE_REMOVE}; do
        sed -i "/$pkg/d" image/casper/filesystem.manifest-desktop
    done

    clean_up

    # compress rootfs
    mksquashfs ${MACHINE} image/casper/filesystem.squashfs \
        -noappend -no-duplicates -no-recovery \
        -wildcards \
        -e "var/cache/apt/archives/*" \
        -e "root/*" \
        -e "root/.*" \
        -e "tmp/*" \
        -e "tmp/.*" \
        -e "swapfile"
    printf $(du -sx --block-size=1 ${MACHINE} | cut -f1) > image/casper/filesystem.size

    # create diskdefines
    cat <<EOF > image/README.diskdefines
#define DISKNAME  ${TARGET_DISTRO_NAME} ${TARGET_UBUNTU_VERSION}
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  amd64
#define ARCHamd64  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1
EOF

    # create iso image
    pushd $SCRIPT_DIR/image
    grub-mkstandalone \
        --format=x86_64-efi \
        --output=isolinux/bootx64.efi \
        --locales="" \
        --fonts="" \
        "boot/grub/grub.cfg=isolinux/grub.cfg"

    (
        cd isolinux && \
        dd if=/dev/zero of=efiboot.img bs=1M count=10 && \
        mkfs.vfat efiboot.img && \
        LC_CTYPE=C mmd -i efiboot.img efi efi/boot && \
        LC_CTYPE=C mcopy -i efiboot.img ./bootx64.efi ::efi/boot/
    )

    grub-mkstandalone \
        --format=i386-pc \
        --output=isolinux/core.img \
        --install-modules="linux16 linux normal iso9660 biosdisk memdisk search tar ls" \
        --modules="linux16 linux normal iso9660 biosdisk search" \
        --locales="" \
        --fonts="" \
        "boot/grub/grub.cfg=isolinux/grub.cfg"

    cat /usr/lib/grub/i386-pc/cdboot.img isolinux/core.img > isolinux/bios.img

    /bin/bash -c "(find . -type f -print0 | xargs -0 md5sum | grep -v -e 'md5sum.txt' -e 'bios.img' -e 'efiboot.img' > md5sum.txt)"

    xorriso \
        -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "${TARGET_NAME}" \
        -eltorito-boot boot/grub/bios.img \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --eltorito-catalog boot/grub/boot.cat \
        --grub2-boot-info \
        --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
        -eltorito-alt-boot \
        -e EFI/efiboot.img \
        -no-emul-boot \
        -append_partition 2 0xef isolinux/efiboot.img \
        -output "${SCRIPT_DIR}/${TARGET_NAME}.iso" \
        -m "isolinux/efiboot.img" \
        -m "isolinux/bios.img" \
        -graft-points \
           "/EFI/efiboot.img=isolinux/efiboot.img" \
           "/boot/grub/bios.img=isolinux/bios.img" \
           "."
    popd
}

host_setup
bootstrap_container
install_os
build_image
