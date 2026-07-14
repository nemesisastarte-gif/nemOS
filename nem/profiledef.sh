#!/usr/bin/env bash
# shellcheck disable=SC2034
# nemOS - Distribution Linux 32-bit légère avec interface macOS
# Profil de construction de l'ISO (basé sur archiso)

iso_name="nemOS"
iso_label="nemOS_$(date +%Y%m)"
iso_publisher="nemOS Project <https://github.com/nemesisastarte-gif/nemOS>"
iso_application="nemOS Session Live - La puissance de Linux, l'élégance de macOS"
iso_version="$(date +%Y.%m)"
install_dir="arch"
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito')
arch="i686"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '22' '-b' '1M' '-Xthreads' '4')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
  ["/usr/local/bin/nemos-cleanup"]="0:0:755"
  ["/usr/local/bin/nemos-firstboot"]="0:0:755"
  ["/usr/share/nemos-assets/"]="0:0:755"
  ["/usr/share/nemos-store/"]="0:0:755"
)