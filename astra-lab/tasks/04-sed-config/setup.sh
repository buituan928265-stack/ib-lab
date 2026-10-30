#!/bin/bash
. /opt/astra/tasks/lib.sh
C=/etc/uchet/uchet.conf
if [ "$1" = "--reset" ] || [ ! -f $C ]; then
  mkdir -p /etc/uchet
  cp /opt/astra/tasks/04-sed-config/orig.conf $C
  chmod 644 $C; rm -f $C.bak $C.orig /etc/uchet/*~ 
fi
true
