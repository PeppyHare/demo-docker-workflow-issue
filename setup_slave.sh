#! /bin/bash

#Change Directory permissions to jenkins
chown -R jenkins:jenkins /home/jenkins
ls -al /home

# start the docker daemon
/usr/local/bin/wrapdocker &

# start the ssh daemon
if [ -n "$MAXIMUM_LIFETIME" ]; then
    exec timeout --preserve-status --foreground $MAXIMUM_LIFETIME /usr/sbin/sshd -D
else
    exec /usr/sbin/sshd -D
fi
