#!/bin/bash

HOSTLINE=$(echo $(ip -f inet addr show eth0 | grep 'inet' | awk '{ print $2 }' | cut -d/ -f1) $(hostname) $(hostname -s))
echo $HOSTLINE >> /etc/hosts

echo 127.0.0.1     `uname -n` >> /etc/hosts

JAVA_OPTS="-Djava.awt.headless=true -Xms256m -Xmx1024m -XX:+UseConcMarkSweepGC -Dlinshare.config.path=file:/etc/linshare -Dlog4j.configuration
=file:/etc/linshare/log4j.properties"

service tomcat6 restart
