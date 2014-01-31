#!/bin/bash

# Create a new directory and chown it to calling user;  then try to have
# calling user movepid to the new directory

echo "Test 9 (Chown)"
if [ -n "$SUDO_USER" ]; then
	gid=$SUDO_GID
	uid=$SUDO_UID
else
	gid=1000
	uid=1000
fi

mnt=`mktemp -d`

cleanup() {
	umount $mnt || true
	rmdir $mnt
}

trap cleanup EXIT

# We can't readily verify if we can't mount cgroups
cantmount=0
mount -t cgroup -o memory cgroup $mnt || cantmount=1
if [ $cantmount -eq 0 ]; then
	myc=`cat /proc/$$/cgroup | grep memory | awk -F: '{ print $3 }'`
	rmdir "${mnt}/${myc}/zzz/b" || true
	rmdir "${mnt}/${myc}/zzz" || true
fi

dbus-send --print-reply --address=unix:path=/sys/fs/cgroup/cgmanager/sock --type=method_call /org/linuxcontainers/cgmanager org.linuxcontainers.cgmanager0_0.Create string:'memory' string:"zzz" > /dev/null 2>&1
dbus-send --print-reply --address=unix:path=/sys/fs/cgroup/cgmanager/sock --type=method_call /org/linuxcontainers/cgmanager org.linuxcontainers.cgmanager0_0.Chown string:'memory' string:"zzz" int32:$uid int32:$gid > /dev/null 2>&1
if [ $cantmount -eq 1 ]; then
	echo "Chowned zzz, but cannot verify the result"
	exit 0
fi
o1=`stat --format="%u:%g" ${mnt}/${myc}/zzz`
o2=`stat --format="%u:%g" ${mnt}/${myc}/zzz/tasks`
o3=`stat --format="%u:%g" ${mnt}/${myc}/zzz/cgroup.procs`
o4=`stat --format="%u:%g" ${mnt}/${myc}/zzz/memory.limit_in_bytes`

if [ "$o1" != "$uid:$gid" ]; then
	exit 1
fi
if [ "$o2" != "$uid:$gid" ]; then
	exit 1
fi
if [ "$o3" != "$uid:$gid" ]; then
	exit 1
fi
if [ "$o4" = "$uid:$gid" ]; then
	exit 1
fi

exit 0
