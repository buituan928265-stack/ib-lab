#!/bin/bash
. /opt/astra/tasks/lib.sh
[ "$1" = "--reset" ] && rm -f /usr/local/bin/cleanlogs
true
