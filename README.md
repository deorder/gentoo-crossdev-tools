# Gentoo crossdev tools
Cross-compile tools to use with `crossdev`

## Still being worked on
Some packages may still not compile as it was tested on only a handful of packages. In combination with my [overlay](https://github.com/deorder/gentoo-overlay) I was able to cross-compile an entire stage3 for the following targets: `aarch64-rpi3hs-linux-musleabi`, `aarch64-rpi3s-linux-gnueabi`, `armv7a-rpi2hs-linux-musleabihf`, `armv7a-rpi2s-linux-gnueabih`, `armv6j-rpi1hs-linux-musleabihf`, `armv6j-rpi1s-linux-gnueabihf`, `m68k-unknown-linux-gnu`

## Example: Building a stage3 for the RPi 2 with glibc

First we create a crossdev environment for the `armv7a-rpi2s-linux-gnueabihf` target:
```
./crossdev-create --cd-target armv7a-rpi2s-linux-gnueabihf --cd-use-rpi
```
The `--cd-use-rpi` will make sure Raspberry Pi supported kernel headers are used, currently 4.19.

Copy one of the example portage configurations in `crossdev-example-profiles` to `/usr/armv7a-rpi2s-linux-gnueabihf/etc/portage/`:
```
cp -a ./crossdev-example-profiles/armv7a-rpi2s-linux-gnueabihf/* /usr/armv7a-rpi2s-linux-gnueabihf/etc/portage/
```
Modify the copied portage configuration as needed. You for example may want the versions of Python to be the same as on your host in `/etc/portage/make.conf` (it planned to add code to do this automatically):
```
PYTHON_TARGETS="python2_7 python3_7"
PYTHON_SINGLE_TARGET="python3_7"
USE_PYTHON="2.7 3.7"
```

Build the essential packages that will be used to build the rest of the system:
```
./crossdev-bootstrap --cd-target armv7a-rpi2s-linux-gnueabihf --cd-use-rpi
```

Build the system packages to complete the stage3:
```
./crossdev-system-install --cd-target armv7a-rpi2s-linux-gnueabihf
```

Install the Raspberry Pi kernel, firmware and overlay files:
```
./crossdev-linux-rpi-install --cd-target armv7a-rpi2s-linux-gnueabihf --cd-kernel-arch arm --cd-use-rpi 2
```

You can chroot into the environment (requires qemu and the user emulation binaries, see below):
```
./crossdev-qemu-binfmt-install --cd-target armv7a-rpi2s-linux-gnueabihf --cd-qemu-arch arm --cd-use-rpi 2
./crossdev-mount --cd-target armv7a-rpi2s-linux-gnueabihf
mount -o bind /usr/portage /usr/armv7a-rpi2s-linux-gnueabihf/usr/portage
chroot /usr/armv7a-rpi2s-linux-gnueabihf /bin/bash
```

## Example: Building a stage3 for the RPi 3 with musl

First we create a crossdev environment for the `aarch64-rpi3hs-linux-musleabi` target:
```
./crossdev-create --cd-target aarch64-rpi3hs-linux-musleabi --cd-use-rpi
```
The `--cd-use-rpi` will make sure Raspberry Pi supported kernel headers are used, currently 4.19.

Copy one of the example portage configurations in `crossdev-example-profiles` to `/usr/aarch64-rpi3hs-linux-musleabi/etc/portage/`:
```
cp -a ./crossdev-example-profiles/aarch64-rpi3hs-linux-musleabi/* /usr/aarch64-rpi3hs-linux-musleabi/etc/portage/
```
Modify the copied portage configuration as needed. You for example may want the versions of Python to be the same as on your host in `/etc/portage/make.conf` (it planned to add code to do this automatically):
```
PYTHON_TARGETS="python2_7 python3_7"
PYTHON_SINGLE_TARGET="python3_7"
USE_PYTHON="2.7 3.7"
```

Build the essential packages that will be used to build the rest of the system:
```
./crossdev-bootstrap --cd-target aarch64-rpi3hs-linux-musleabi --cd-use-rpi
```

Build the system packages to complete the stage3:
```
./crossdev-system-install --cd-target aarch64-rpi3hs-linux-musleabi
```

Install the Raspberry Pi kernel, firmware and overlay files:
```
./crossdev-linux-rpi-install --cd-target aarch64-rpi3hs-linux-musleabi --cd-kernel-arch arm64 --cd-use-rpi 3
```

You can chroot into the environment (requires qemu and the user emulation binaries, see below):
```
./crossdev-qemu-binfmt-install --cd-target aarch64-rpi3hs-linux-musleabi --cd-qemu-arch aarch64 --cd-use-rpi 3
./crossdev-mount --cd-target aarch64-rpi3hs-linux-musleabi
mount -o bind /usr/portage /usr/aarch64-rpi3hs-linux-musleabi/usr/portage
chroot /usr/aarch64-rpi3hs-linux-musleabi /bin/bash
```

## Example: Setting up automatic mounting / unmounting hooks

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

## Usage

### crossdev-emerge

Usage:
```
usage: crossdev-emerge ...
--cd-help (This help)
--cd-target "<target triplet>" (required)
--cd-prefix-dir "<prefix dir>" (empty)
--cd-config-dir "<config dir>" (/etc/crossdev)
--cd-target-dir "<target dir>" (/usr/<target>)
--cd-tmp-dir "<temp dir>" (/var/tmp)
```
Example:
```
./crossdev-emerge --cd-target armv7a-rpi2hs-linux-musleabihf --oneshot portage 
```

### crossdev-system-upgrade

Usage:
```
usage: crossdev-system-upgrade ...
--cd-help (This help)
--cd-target "<target triplet>" (required)
--cd-prefix-dir "<prefix dir>" (empty)
--cd-config-dir "<config dir>" (/etc/crossdev)
--cd-target-dir "<target dir>" (/usr/<target>)
--cd-tmp-dir "<temp dir>" (/var/tmp)
```
Example:
```
./crossdev-system-upgrade --cd-target armv7a-rpi2hs-linux-musleabihf --ask --tree
```

### crossdev-clean

Usage:
```
usage: crossdev-clean ...
--cd-help (This help)
--cd-target "<target triplet>" (required)
--cd-prefix-dir "<prefix dir>" (empty)
--cd-config-dir "<config dir>" (/etc/crossdev)
--cd-target-dir "<target dir>" (/usr/<target>)
--cd-tmp-dir "<temp dir>" (/var/tmp)
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
--cd-target "<target triplet>" (required)
--cd-prefix-dir "<prefix dir>" (empty)
--cd-config-dir "<config dir>" (/etc/crossdev)
--cd-target-dir "<target dir>" (/usr/<target>)
--cd-tmp-dir "<temp dir>" (/var/tmp)
--cd-use-rpi (Use RPi supported kernel)
--cd-use-musl (Use musl as the libc)
--cd-use-glibc (Use glibc as the libc)
--cd-gcc-ver (Override GCC version to use)
--cd-libc-ver (Override libc version to use)
--cd-kernel-ver (Override kernel version to use)
--cd-binutils-ver (Override binutils version to use)
```
Example:
```
./crossdev-create --cd-use-rpi --cd-target aarch64-rpi3s-linux-gnueabi
```

### crossdev-bootstrap

Usage:
```
usage: crossdev-bootstrap ...
--cd-help (This help)
--cd-target "<target triplet>" (required)
--cd-prefix-dir "<prefix dir>" (empty)
--cd-config-dir "<config dir>" (/etc/crossdev)
--cd-target-dir "<target dir>" (/usr/<target>)
--cd-tmp-dir "<temp dir>" (/var/tmp)
--cd-use-rpi (Use RPi supported kernel)
--cd-use-musl (Use musl as the libc)
--cd-use-glibc (Use glibc as the libc)
--cd-gcc-ver (Override GCC version to use)
--cd-libc-ver (Override libc version to use)
--cd-kernel-ver (Override kernel version to use)
--cd-binutils-ver (Override binutils version to use)
```
Example:
```
./crossdev-bootstrap --cd-use-rpi --cd-target aarch64-rpi3s-linux-gnueabi
```

### crossdev-linux-rpi-install

Usage:
```
usage: crossdev-linux-rpi-install ...
--cd-help (This help)
--cd-target "<target triplet>" (Target triplet) (required)
--cd-prefix-dir "<prefix dir>" (Prefix dir) (<empty>)
--cd-config-dir "<config dir>" (Config dir) (/etc/crossdev)
--cd-target-dir "<target dir>" (Target dir) (/usr/<target>)
--cd-tmp-dir "<temp dir>" (Temp dir) (/var/tmp)
--cd-kernel-menu (Show kernel menu)
--cd-kernel-clean (Clean kernel build)
--cd-kernel-config <path> (Kernel config)
--cd-kernel-branch <name> (Kernel branch)
--cd-kernel-arch <arch> (Architecture to build kernel for)
--cd-use-downstream-dtb (Install downstream / official dtb files)
--cd-use-upstream-dtb (Install upstream / linux dtb files)
--cd-firmware-branch <name> (Firmware branch)
--cd-use-rpi <name> (Which RPi to target)
```
Example:
```
./crossdev-linux-rpi-install --cd-target aarch64-rpi3hs-linux-musleabi --cd-kernel-arch arm64 --cd-use-rpi 3
```
  
### crossdev-qemu-binfmt-install

**Note:** This command requires `qemu` with `static-user` and the required `qemu_user_targets_` USE flags

Usage:
```
usage: crossdev-qemu-binfmt-install ...
--cd-help (This help)
--cd-target "<target triplet>" (required)
--cd-prefix-dir "<prefix dir>" (empty)
--cd-config-dir "<config dir>" (/etc/crossdev)
--cd-target-dir "<target dir>" (/usr/<target>)
--cd-tmp-dir "<temp dir>" (/var/tmp)
--cd-qemu-arch <arch> (Architecture part of user emulation binary)
--cd-use-rpi <name> (Use specified RPi equivalent CPU for wrapper)
```
Example:
```
./crossdev-qemu-binfmt-install --cd-target armv7a-rpi2hs-linux-musleabihf --cd-qemu-arch arm --cd-use-rpi 2
```
```
./crossdev-qemu-binfmt-install --cd-target aarch64-rpi3s-linux-gnueabi --cd-qemu-arch aarch64 --cd-use-rpi 3
```

### crossdev-cow-env-init

**Note:** This command requires `unionfs-fuse`

Usage:
```
usage: crossdev-cow-env-init ...
--cd-help (This help)
--cd-target "<target triplet>" (required)
--cd-prefix-dir "<prefix dir>" (empty)
--cd-config-dir "<config dir>" (/etc/crossdev)
--cd-target-dir "<target dir>" (/usr/<target>)
--cd-tmp-dir "<temp dir>" (/var/tmp)
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

### crossdev-cow-env-chroot

**Note:** This command requires `unionfs-fuse`

Usage:
```
usage: crossdev-cow-env-chroot ...
--cd-help (This help)
--cd-target "<target triplet>" (required)
--cd-prefix-dir "<prefix dir>" (empty)
--cd-config-dir "<config dir>" (/etc/crossdev)
--cd-target-dir "<target dir>" (/usr/<target>)
--cd-tmp-dir "<temp dir>" (/var/tmp)
```
Example:
```
./crossdev-cow-env-chroot --cd-target armv7a-rpi2hs-linux-musleabihf
```

### crossdev-cow-env-uninit

**Note:** This command requires `unionfs-fuse`

Usage:
```
usage: crossdev-cow-env-uninit ...
--cd-help (This help)
--cd-target "<target triplet>" (required)
--cd-prefix-dir "<prefix dir>" (empty)
--cd-config-dir "<config dir>" (/etc/crossdev)
--cd-target-dir "<target dir>" (/usr/<target>)
--cd-tmp-dir "<temp dir>" (/var/tmp)
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
