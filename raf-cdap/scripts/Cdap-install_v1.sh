#!/bin/bash


die() { echo "ERROR: ${*}"; exit 1; };

for i in `/etc/init.d/cdap-* | awk -F'/' '{print $NF}'`
do
  systemctl enable ${i} && systemctl start ${i} || die "Failed to start ${i}"
done
