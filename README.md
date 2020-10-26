# Bootable NixOS SD image

Requires an aarch64 host and Nix with [flake support](https://www.tweag.io/blog/2020-05-25-flakes/).

## Describe
```
nix flake show "git+https://source.mntmn.com/ehmry/nixos-installer-mnt-reform.git"
nix flake list-inputs "git+https://source.mntmn.com/ehmry/nixos-installer-mnt-reform.git"
```

## Build
```
nix build "git+https://source.mntmn.com/ehmry/nixos-installer-mnt-reform.git" -L
```

## Verify

The generation of this image should be deterministic and match the following sha256 digest:
```
0ba80fbf466bcbbeffaea78af036b34abead25f06128979d864bae687b8a928a  result/sd-image/nixos-sd-image-20.09.20200831.4684bb9-aarch64-linux.img.bz2
```
If it does not, please contact me and we can diffoscope images.

## Flash
```
bzcat ./result/sd-image/nixos-sd-image-20.09.20200831.4684bb9-aarch64-linux.img.bz2 > /dev/mmcblk1
```

## Boot

This image contains a mutable NixOS installation that will initialize itself on first boot.

To install NixOS to the NVMe device:
* format and mount the NVMe at /mnt
* mount /dev/mmcblk1p1 at /mnt/boot (the live image)
* run `nixos-generate-config --root /mnt`

* Edit the file at `/mnt/etc/nixos/configuration.nix` to import configuration from the nixos-hardware repository:
```
{ config, pkgs, ... }:

{

  imports = let
    nixosHardware = fetchGit {
      url = "https://github.com/NixOS/nixos-hardware.git";
      ref = "reform";
    };
  in [
    ./hardware-configuration.nix
    "${nixosHardware}/mnt/reform2-nitrogen8m"
  ];

}
```

* Finish customizing /mnt/etc/nixos/configuration.nix and run `nixos-install`
* Move /mnt/boot to /mnt/boot.bak. Uboot will now boot from /mnt/extlinux.

* Reboot?

For more information see the  [NixOS manual](https://nixos.org/manual/nixos/stable/#sec-installation)
