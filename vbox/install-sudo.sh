#!/bin/sh


exposrt ASSUME_ALWAYS_YES=yes 

pkg update
pkg install -y sudo
echo \"%wheel ALL=(ALL) NOPASSWD: ALL\" > /usr/local/etc/sudoers.d/000-wheel-nopasswd

