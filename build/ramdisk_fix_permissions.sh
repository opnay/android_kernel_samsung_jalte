#!/bin/bash
chmod 750 init*
chmod 644 *.rc

chmod 644 *contexts
chmod 644 sepolicy*
chmod 644 fstab*

chmod 644 default.prop

chmod -R 750 sbin
chmod -R 755 dev proc sys
