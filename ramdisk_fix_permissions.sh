#!/bin/bash
chmod 755 init*
chmod 644 *.rc

chmod 644 *contexts
chmod 644 sepolicy*
chmod 644 fstab*
chmod 644 default.prop

chmod 755 dev
chmod 755 proc
chmod 777 res
chmod 755 res/*
chmod 750 sbin
chmod 755 sbin/*
chmod 755 sys

chmod 755 *.sh