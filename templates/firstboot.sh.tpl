#!/bin/bash
for service in agetty-tty{1,2,3,4,5,6}; do
	printf -v srv "/etc/runit/runsvdir/default/%s" "$service"
	[[ -L "$srv" ]] && rm "$srv"
done
for service in dhcpcd-eth0 sshd; do
	printf -v srv "/etc/sv/%s" "$service"
	[[ -L "$srv" ]] || ln -s "$srv" /etc/runit/runsvdir/default
done
