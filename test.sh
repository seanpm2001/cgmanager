#!/bin/sh

# for expediency this test script assumes you're on recent ubuntu

if [ "$(id -u)" != "0" ]; then
	echo "Run as root"
	exit 0
fi

stop cgroup-lite || true

# mount memory cgroup and remove our test directories
mount -t cgroup -o memory cgroup /sys/fs/cgroup
rmdir /sys/fs/cgroup/b || true
rmdir /sys/fs/cgroup/xxx/b || true
mkdir /sys/fs/cgroup/xxx
chown -R 1000 /sys/fs/cgroup/xxx
umount /sys/fs/cgroup

dbus-send --print-reply --address=unix:path=/tmp/cgmanager --type=method_call /org/linuxcontainers/cgmanager org.linuxcontainers.cgmanager0_0.getValue string:'memory' string:'' string:'memory.usage_in_bytes'
if [ $? -ne 0 ]; then
	echo "Failed test 1"
	exit 1
fi

dbus-send --print-reply --address=unix:path=/tmp/cgmanager --type=method_call /org/linuxcontainers/cgmanager org.linuxcontainers.cgmanager0_0.getMyCgroup string:'memory'
if [ $? -ne 0 ]; then
	echo "Failed test 2"
	exit 1
fi

dbus-send --print-reply --address=unix:path=/tmp/cgmanager --type=method_call /org/linuxcontainers/cgmanager org.linuxcontainers.cgmanager0_0.Create string:'memory' string:"xxx/b"
if [ $? -ne 0 ]; then
	echo "Failed test 3"
	exit 1
fi

dbus-send --print-reply --address=unix:path=/tmp/cgmanager --type=method_call /org/linuxcontainers/cgmanager org.linuxcontainers.cgmanager0_0.getValue string:'memory' string:"xxx/b" string:'memory.usage_in_bytes'
if [ $? -ne 0 ]; then
	echo "Failed test 4"
	exit 1
fi

#This should fail:
dbus-send --print-reply --address=unix:path=/tmp/cgmanager --type=method_call /org/linuxcontainers/cgmanager org.linuxcontainers.cgmanager0_0.getValue string:'memory' string:"../xxx/b" string:'memory.usage_in_bytes'
if [ $? -eq 0 ]; then
	echo "Failed test 5: was able to read under \"../xxx\""
	exit 1
fi

dbus-send --print-reply --address=unix:path=/tmp/cgmanager --type=method_call /org/linuxcontainers/cgmanager org.linuxcontainers.cgmanager0_0.Create string:'memory' string:"b"
if [ $? -eq 0 ]; then
	echo "Failed test 6: was able to create without having the privilege"
	exit 1
fi

echo "All tests passed"