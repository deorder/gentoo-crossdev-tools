# Gentoo crossdev emerge wrapper 
Emerge wrapper with cross-compile work arounds to use on environments created with `crossdev`

## Still being worked on
The `sandbox` and `userpriv` emerge `FEATURES` are being disabled for now and the emerge `ROOT` is hardcoded to point to `/usr/<target>` as created using `crossdev`.
Some packages may still not compile as it was tested on only a handful of packages.
In combination with my overlay I was able to cross-compile an entire stage3.

## How to use
Usage:
```
./crossdev-emerge <target> <emerge arguments...>
```
Example:
```
./crossdev-emerge armv7a-rpi2hs-linux-musleabihf --oneshot portage 
```
