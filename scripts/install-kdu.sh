#! /usr/bin/env bash
wget http://kakadusoftware.com/wp-content/uploads/2014/06/KDU77_Demo_Apps_for_Linux-x86-64_150710.zip

unzip KDU77_Demo_Apps_for_Linux-x86-64_150710.zip

mkdir -p /opt/kdu
cp KDU77_Demo_Apps_for_Linux-x86-64_150710/* /opt/kdu/.

sh -c 'echo "/opt/kdu" > /etc/ld.so.conf.d/kdu.conf'
sh -c 'echo "PATH=\$PATH:/opt/kdu" > /etc/profile.d/kdu.sh'
sh -c 'echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/opt/kdu" > /etc/profile.d/kdu_ld_library.sh'
