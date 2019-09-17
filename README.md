# Gentoo crossdev tools
Cross-compile workarounds to use on environments created with `crossdev`

## Still being worked on
Some packages may still not compile as it was tested on only a handful of packages.

In combination with my overlay I was able to cross-compile an entire stage3 for the following targets: `aarch64-rpi3hs-linux-musleabi`, `aarch64-rpi3s-linux-gnueabi`, `armv7a-rpi2hs-linux-musleabihf`, `armv7a-rpi2s-linux-gnueabih`, `armv6j-rpi1hs-linux-musleabihf`, `armv6j-rpi1s-linux-gnueabihf`

Perl and Python sometimes, when not using multilib, still install in `/usr/<target>/*/lib64` where it should install in `/usr/<target>/*/lib`. I solved this by creating symbolic links from `/usr/<target>/*/lib64` to `/usr/<target>/*/lib`.

## How to use

Example of building a stage3 for `armv7a-rpi2s-linux-gnueabihf`:
```
./crossdev-create --cd-target armv7a-rpi2s-linux-gnueabihf
cp -a ./crossdev-example-profiles/armv7a-rpi2s-linux-gnueabihf/* /usr/armv7a-rpi2s-linux-gnueabihf/etc/portage/
./crossdev-bootstrap --cd-use-rpi --cd-target armv7a-rpi2s-linux-gnueabihf
./crossdev-emerge-install-system --cd-target armv7a-rpi2s-linux-gnueabihf
```

Example of chrooting into the `armv7a-rpi2s-linux-gnueabihf` environment:
```
./crossdev-install-qemu-wrapper --cd-target armv7a-rpi2s-linux-gnueabihf --cd-qemu-arch arm --cd-use-rpi2
./crossdev-mount --cd-target armv7a-rpi2s-linux-gnueabihf
mount -o bind /usr/portage /usr/armv7a-rpi2s-linux-gnueabihf/usr/portage
chroot /usr/armv7a-rpi2s-linux-gnueabihf /bin/bash
```

When done:
```
./crossdev-umount --cd-target armv7a-rpi2s-linux-gnueabihf
umount /usr/armv7a-rpi2s-linux-gnueabihf/usr/portage
```

To let it automatically mount/unmount `/usr/portage`, create the following files:

The file `/etc/crossdev/crossdev-emerge-pre` containing:
```bash
#!/bin/bash
${CD_SCRIPT_DIR}/crossdev-mount --cd-target ${CD_TARGET} --cd-target-dir "${CD_TARGET_DIR}"
```

The file `/etc/crossdev/crossdev-mount-post` containing:
```bash
#!/bin/bash

source "${CD_SCRIPT_DIR}/crossdev-functions.sh"

if [ -d "${CD_TARGET_DIR}" ]; then
  if ! cd_is_mount "${CD_TARGET_DIR}/usr/portage"; then
    ebegin "Mounting ${CD_TARGET_DIR}/usr/portage"
    mkdir -p "${CD_TARGET_DIR}/usr/portage" || cd_die
    mount -o bind "$(portageq get_repo_path / gentoo)" "${CD_TARGET_DIR}/usr/portage" || cd_die
    eend 0
  fi
fi
```

The file `/etc/crossdev/crossdev-umount-pre` containing:
```bash
#!/bin/bash

source "${CD_SCRIPT_DIR}/crossdev-functions.sh"

if [ -d "${CD_TARGET_DIR}" ]; then
  if cd_is_mount "${CD_TARGET_DIR}/usr/portage"; then
    ebegin "Unmounting ${CD_TARGET_DIR}/usr/portage"
    umount "${CD_TARGET_DIR}/usr/portage" || cd_die
    eend 0
  fi
fi
```

### crossdev-emerge

Usage:
```
usage: crossdev-emerge ...
--cd-help (This help)
--cd-tmp-dir "<temp dir>" (/var/tmp)
--cd-target "<target triplet>" (required)
--cd-target-dir "<target dir>" (/usr/<target>)
--cd-config-dir "<config dir>" (/etc/crossdev)
```
Example:
```
./crossdev-emerge --cd-target armv7a-rpi2hs-linux-musleabihf --oneshot portage 
```

### crossdev-emerge-upgrade-system

Usage:
```
usage: crossdev-emerge ...
--cd-help (This help)
--cd-tmp-dir "<temp dir>" (/var/tmp)
--cd-target "<target triplet>" (required)
--cd-target-dir "<target dir>" (/usr/<target>)
--cd-config-dir "<config dir>" (/etc/crossdev)
```
Example:
```
./crossdev-emerge-upgrade-system --cd-target armv7a-rpi2hs-linux-musleabihf --ask --tree
```

### crossdev-clean

Usage:
```
usage: crossdev-clean ...
--cd-help (This help)
--cd-tmp-dir "<temp dir>" (/var/tmp)
--cd-target "<target triplet>" (required)
--cd-target-dir "<target dir>" (/usr/<target>)
--cd-config-dir "<config dir>" (/etc/crossdev)
```
Example:
```
./crossdev-clean --cd-target armv7a-rpi2hs-linux-musleabihf
```
**Note:** You still have to confirm. Follow the instructions while running the above command

### crossdev-create

Usage:
```
usage: crossdev-create ...
--cd-help (This help)
--cd-tmp-dir "<temp dir>" (/var/tmp)
--cd-target "<target triplet>" (required)
--cd-target-dir "<target dir>" (/usr/<target>)
--cd-config-dir "<config dir>" (/etc/crossdev)
--cd-use-rpi (Use RPi supported kernel)
--cd-use-musl (Use musl as the libc)
--cd-use-glibc (Use glibc as the libc)
```
Example:
```
./crossdev-create --cd-use-rpi --cd-target aarch64-rpi3s-linux-gnueabi
```

### crossdev-install-rpi3-firmware

Usage:
```
usage: crossdev-install-rpi3-firmware ...
--cd-help (This help)
--cd-tmp-dir "<temp dir>" (/var/tmp)
--cd-target "<target triplet>" (required)
--cd-target-dir "<target dir>" (/usr/<target>)
--cd-config-dir "<config dir>" (/etc/crossdev)
```
Example:
```
./crossdev-install-rpi3-firmware --cd-target aarch64-rpi3s-linux-gnueabi
```
  
### crossdev-install-qemu-wrapper

**Note:** This command requires `qemu` with `static-user` and the required `qemu_user_targets_` USE flags

Usage:
```
usage: crossdev-install-qemu-wrapper ...
--cd-help (This help)
--cd-tmp-dir "<temp dir>" (/var/tmp)
--cd-target "<target triplet>" (required)
--cd-target-dir "<target dir>" (/usr/<target>)
--cd-config-dir "<config dir>" (/etc/crossdev)
--cd-use-rpi1 (Use RPi1 equivalent CPU for wrapper)
--cd-use-rpi2 (Use RPi2 equivalent CPU for wrapper)
--cd-use-rpi3 (Use RPi3 equivalent CPU for wrapper)
--cd-use-rpi4 (Use RPi4 equivalent CPU for wrapper)
--cd-qemu-arch (Architecture part of user emulation binary)
```
Example:
```
./crossdev-install-qemu-wrapper --cd-target armv7a-rpi2hs-linux-musleabihf --cd-qemu-arch arm --cd-use-rpi2
```
```
./crossdev-install-qemu-wrapper --cd-target aarch64-rpi3s-linux-gnueabi --cd-qemu-arch aarch64 --cd-use-rpi3
```

### crossdev-cow-env-init

**Note:** This command requires `unionfs-fuse`

Usage:
```
usage: crossdev-cow-env-init ...
--cd-help (This help)
--cd-tmp-dir "<temp dir>" (/var/tmp)
--cd-target "<target triplet>" (required)
--cd-target-dir "<target dir>" (/usr/<target>)
--cd-config-dir "<config dir>" (/etc/crossdev)
```
Example:
```
./crossdev-cow-env-init --cd-target armv7a-rpi2hs-linux-musleabihf
```
Before using this command you may want to create a `crossdev-cow-env-init-post` file containing:
```bash
#!/bin/bash
${CD_SCRIPT_DIR}/crossdev-mount --cd-target "${CD_TARGET}" --cd-target-dir "${CD_UNION_PREFIX_DIR}"
```

### crossdev-cow-env-enter

**Note:** This command requires `unionfs-fuse`

Usage:
```
usage: crossdev-cow-env-init ...
--cd-help (This help)
--cd-tmp-dir "<temp dir>" (/var/tmp)
--cd-target "<target triplet>" (required)
--cd-target-dir "<target dir>" (/usr/<target>)
--cd-config-dir "<config dir>" (/etc/crossdev)
```
Example:
```
./crossdev-cow-env-enter --cd-target armv7a-rpi2hs-linux-musleabihf
```

### crossdev-cow-env-uninit

**Note:** This command requires `unionfs-fuse`

Usage:
```
usage: crossdev-cow-env-uninit ...
--cd-help (This help)
--cd-tmp-dir "<temp dir>" (/var/tmp)
--cd-target "<target triplet>" (required)
--cd-target-dir "<target dir>" (/usr/<target>)
--cd-config-dir "<config dir>" (/etc/crossdev)
```
Example:
```
./crossdev-cow-env-uninit --cd-target armv7a-rpi2hs-linux-musleabihf
```
Before using this command you may want to create a `crossdev-cow-env-uninit-pre` file containing:
```bash
#!/bin/bash
${CD_SCRIPT_DIR}/crossdev-umount --cd-target ${CD_TARGET} --cd-target-dir "${CD_UNION_PREFIX_DIR}"
```
