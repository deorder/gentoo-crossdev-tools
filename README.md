# Gentoo crossdev tools
Cross-compile workarounds to use on environments created with `crossdev`

## Still being worked on
Some packages may still not compile as it was tested on only a handful of packages.

In combination with my overlay I was able to cross-compile an entire stage3 for the following targets: `aarch64-rpi3hs-linux-musleabi`, `aarch64-rpi3s-linux-gnueabi`, `armv7a-rpi2hs-linux-musleabihf`, `armv7a-rpi2s-linux-gnueabih`, `armv6j-rpi1hs-linux-musleabihf`, `armv6j-rpi1s-linux-gnueabihf`

Perl and Python sometimes, when not using multilib, still install in `/usr/<target>/*/lib64` where it should install in `/usr/<target>/*/lib`. I solved this by creating symbolic links from `/usr/<target>/*/lib64` to `/usr/<target>/*/lib`.

## How to use

Example of how to build a stage3 for `armv7a-rpi2s-linux-gnueabihf`:
```
./crossdev-create-rpi-glibc armv7a-rpi2s-linux-gnueabihf /usr/armv7a-rpi2s-linux-gnueabihf
cp -a ./crossdev-example-profiles/armv7a-rpi2s-linux-gnueabihf/* /usr/armv7a-rpi2s-linux-gnueabihf/etc/portage/
./crossdev-emerge-bootstrap-glibc armv7a-rpi2s-linux-gnueabihf /usr/armv7a-rpi2s-linux-gnueabihf
./crossdev-emerge-install-system armv7a-rpi2s-linux-gnueabihf /usr/armv7a-rpi2s-linux-gnueabihf
```

Example of how to chroot into the `armv7a-rpi2s-linux-gnueabihf` environment:
```
./crossdev-install-qemu-wrapper armv7a-rpi2s-linux-gnueabihf /usr/armv7a-rpi2s-linux-gnueabihf
./crossdev-mount armv7a-rpi2s-linux-gnueabihf /usr/armv7a-rpi2s-linux-gnueabihf
mount -o bind /usr/portage /usr/armv7a-rpi2s-linux-gnueabihf/usr/portage
chroot /usr/armv7a-rpi2s-linux-gnueabihf /bin/bash
```

When done:
```
./crossdev-umount armv7a-rpi2s-linux-gnueabihf /usr/armv7a-rpi2s-linux-gnueabihf
umount /usr/armv7a-rpi2s-linux-gnueabihf/usr/portage
```

### crossdev-emerge

Usage:
```
./crossdev-emerge <target> <target dir> <emerge arguments...>
```
Example:
```
./crossdev-emerge armv7a-rpi2hs-linux-musleabihf /usr/armv7a-rpi2hs-linux-musleabihf --oneshot portage 
```

### crossdev-emerge-upgrade-system

Usage:
```
./crossdev-emerge-upgrade-system <target> <target dir> <extra emerge arguments...>
```
Example:
```
./crossdev-emerge-upgrade-system armv7a-rpi2hs-linux-musleabihf /usr/armv7a-rpi2hs-linux-musleabihf --ask --tree
```

### crossdev-emerge-bootstrap-glibc

Usage:
```
./crossdev-emerge-bootstrap-glibc <target> <target dir> <extra emerge arguments...>
```
Example:
```
./crossdev-emerge-bootstrap-glibc aarch64-rpi3s-linux-gnueabi /usr/aarch64-rpi3s-linux-gnueabi --ask --tree
```

### crossdev-emerge-bootstrap-musl

Usage:
```
./crossdev-emerge-bootstrap-musl <target> <target dir> <extra emerge arguments...>
```
Example:
```
./crossdev-emerge-bootstrap-musl armv7a-rpi2hs-linux-musleabihf /usr/armv7a-rpi2hs-linux-musleabihf --ask --tree
```

### crossdev-clean

Usage:
```
./crossdev-clean <target> <target dir> <confirm>
```
Example:
```
./crossdev-clean armv7a-rpi2hs-linux-musleabihf /usr/armv7a-rpi2hs-linux-musleabihf ICONFIRM
```

### crossdev-create-rpi-glibc

Usage:
```
./crossdev-create-rpi-glibc <target> <target dir> <confirm>
```
Example:
```
./crossdev-create-rpi-glibc aarch64-rpi3s-linux-gnueabi /usr/aarch64-rpi3s-linux-gnueabi
```

### crossdev-create-rpi-musl

Usage:
```
./crossdev-create-rpi-musl <target> <target dir> <confirm>
```
Example:
```
./crossdev-create-rpi-musl armv7a-rpi2hs-linux-musleabihf /usr/armv7a-rpi2hs-linux-musleabihf
```

### crossdev-install-rpi3-firmware

Usage:
```
./crossdev-install-rpi3-firmware <target> <target dir>
```
Example:
```
./crossdev-install-rpi3-firmware aarch64-rpi3s-linux-gnueabi /usr/aarch64-rpi3s-linux-gnueabi
```
  
### crossdev-install-qemu-wrapper

**Note:** This command requires `qemu` with `static-user` and the required `qemu_user_targets_` USE flags

Usage:
```
./crossdev-install-qemu-wrapper <target> <target dir> <architecture>
```
Example:
```
./crossdev-install-qemu-wrapper aarch64-rpi3s-linux-gnueabi /usr/aarch64-rpi3s-linux-gnueabi aarch64
```
```
./crossdev-install-qemu-wrapper armv7a-rpi2hs-linux-musleabihf /usr/armv7a-rpi2hs-linux-musleabihf arm
```

If there is no wrapper for your target just copy an existing C file in `crossdev-qemu-wrapper`, then modify and rename it as needed

### crossdev-cow-env-init

**Note:** This command requires `unionfs-fuse`

Usage:
```
./crossdev-cow-env-init <target> <target dir>
```
Example:
```
./crossdev-cow-env-init armv7a-rpi2hs-linux-musleabihf /usr/armv7a-rpi2hs-linux-musleabihf
```
Before using this command you may want to create a `crossdev-cow-env-init-post` file containing:
```
#!/bin/bash
${SCRIPT_DIR}/crossdev-mount ${TARGET} ${UNION_PREFIX_DIR}
```

### crossdev-cow-env-enter

**Note:** This command requires `unionfs-fuse`

Usage:
```
./crossdev-cow-env-enter <target> <target dir>
```
Example:
```
./crossdev-cow-env-enter armv7a-rpi2hs-linux-musleabihf /usr/armv7a-rpi2hs-linux-musleabihf
```

### crossdev-cow-env-uninit

**Note:** This command requires `unionfs-fuse`

Usage:
```
./crossdev-cow-env-uninit <target> <target dir>
```
Example:
```
./crossdev-cow-env-uninit armv7a-rpi2hs-linux-musleabihf /usr/armv7a-rpi2hs-linux-musleabihf
```
Before using this command you may want to create a `crossdev-cow-env-uninit-pre` file containing:
```
#!/bin/bash
${SCRIPT_DIR}/crossdev-umount ${TARGET} ${UNION_PREFIX_DIR}
```
