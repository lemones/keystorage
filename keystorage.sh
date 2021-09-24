#!/bin/env bash

dir="/home/lemones/crypt/"
file="keys"
destination="/mnt/extOne/Uploads/"
mountpoint="/mnt/keystorage/"
server=pipub
port="2280"


check_backup() {
	echo "[*] Checking server status..."
	server_check=$(ssh -o ConnectTimeout=5 -q $server -p $port exit; echo $?)
	if [ "${server_check}" == "0" ]
	then
	    echo "[*] Uploading to $server:$destination$file"
		scp -P $port $file $server:$destination
	    echo -e "[*] Gather checksums...\n"
	    md5sum $dir$file
		ssh $server -p $port "md5sum $destination$file"
	else
	    echo "[-] Server is dead..."
	    exit
	fi
}

check_umount() {
	echo "- Unmounting /mnt/keystorage and closing mapper..."
	sudo umount $mountpoint
	sudo cryptsetup close keystorage
}

check_mount() {
	if grep -qs '/mnt/keystorage' /proc/mounts; then
	    echo "[*] $file is already mounted to: $mountpoint"
	    exit
	else
		echo "[*] Mounting keystorage to /mnt/keystorage..."
		sudo cryptsetup -v luksOpen keys keystorage
		sudo mount /dev/mapper/keystorage /mnt/keystorage
	fi
}

check_file() {
	if [ -f "$dir$file" ]; then
		check_mount
	else
		echo "[*] Could not find $dir$file"
		exit
	fi
}

start_mount() {
	check_file
}

start_umount() {
	check_umount
}

start_backup() {
	check_backup
}

if [ $# -lt 1 ]; then
	echo -e "Usage:\n $0 -m <- Mount\n $0 -u <- Unmount"
	echo -e " $0 -b <- Backup"
	exit
fi

case "$1" in

-m) start_mount
    ;;
-u) start_umount
    ;;
-b) start_backup
    ;;
*) echo "Invalid option"
   ;;
esac
