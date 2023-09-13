#! /bin/sh

TARGET_VOLUME="$(mount | grep ' /target ' | cut -d ' ' -f 1)"
DEB_SOURCE="deb http://deb.debian.org/debian"

mount "${TARGET_VOLUME}" /mnt
cd /mnt
btrfs subvolume create "@lmd"
btrfs subvolume create "@home"
mv /target/home/* "/mnt/@home"
cd
umount /mnt

cat << EOF > /target/etc/apt/sources.list
${DEB_SOURCE} testing main contrib non-free non-free-firmware
${DEB_SOURCE}-security testing-security main contrib non-free non-free-firmware
${DEB_SOURCE} testing-updates main contrib non-free non-free-firmware
EOF

cat << EOF > /target/etc/apt/sources.list.d/lmd.list
deb https://lmd-linux.github.io/ testing main
EOF

wget -O /target/etc/apt/trusted.gpg.d/lmd.gpg lmd-linux.github.io/lmd.gpg

cat << EOF > /target/tmp/post-install.sh
#! /bin/bash
apt-get update -y
apt-mark auto '*' > /dev/null
apt-mark manual '*firmware*' '*microcode*'
laptop-detect && apt-get install -y tlp
apt-get install -y lmd-xfce
apt-get purge -y ibus termit tilix xterm yelp zutty
apt autopurge -y
rm -rf /etc/network
sed 's/[ \t]\+/ /g' -i /etc/fstab
sed '/ \/ btrfs /{p;s/^\([^ ]*\) \/ \(.*\)rootfs/\1 \/home \2home/;}' -i /etc/fstab
EOF

chmod +x /target/tmp/post-install.sh
in-target --pass-stdout /tmp/post-install.sh > /target/var/log/lmd-install.log

cd /target/tmp
rm -rf -- ..?* .[!.]* *
cp /var/log/syslog /target/var/log/lmd-install.syslog
