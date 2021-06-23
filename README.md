# Bootable NixOS SD image

Requires an aarch64 host and Nix with [flake support](https://www.tweag.io/blog/2020-05-25-flakes/).

## Describe
```
nix flake show "github:nix-community/hardware-mnt-reform"
nix flake list-inputs "github:nix-community/hardware-mnt-reform"
```

## Build
```
nix build "github:nix-community/hardware-mnt-reform" -L
readlink result
```

## Flash
```
bzcat ./result/sd-image/nixos-sd-image-*-aarch64-linux.img.bz2 > /dev/mmcblk1
```

## Boot

This image contains a mutable NixOS installation that will initialize itself on first boot.

To install NixOS to the NVMe device:
* format and mount the NVMe at /mnt
* mount /dev/mmcblk1p1 at /mnt/boot (the live image)
* run `nixos-generate-config --root /mnt`

* Add a flake file at `/mnt/etc/nixos/flake.nix` to import configuration from the NixOS-hardware repository:
```
{
  description = "Configuration for MNT Reform";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, nixos-hardware }: {

    nixosConfigurations.reform = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        nixos-hardware.nixosModules.mnt-reform-nitrogen8m
        ./configuration.nix
        ({ pkgs, ... }: {
          nix.package = pkgs.nixFlakes;
          programs.sway.enable = true;
        })
      ];
    };

  };
}
```

* Finish customizing /mnt/etc/nixos/configuration.nix and run `nixos-install`
* Move /mnt/boot to /mnt/boot.bak. Uboot will now boot from /mnt/extlinux.

* Reboot?

For more information see the  [NixOS manual](https://nixos.org/manual/nixos/stable/#sec-installation)


# Firmware

## Keyboard

Flash the stock keyboard firmware (assuming the keyboard is in programming mode):
```
doas nix run "github:nix-community/hardware-mnt-reform#reform2-keyboard-fw" -L
```

Override the keyboard layout:
```
let
  hardware-mnt-reform =
    builtins.getFlake "github:nix-community/hardware-mnt-reform";
in {
  reform2-keyboard-fw =
    hardware-mnt-reform.packages.aarch64-linux.reform2-keyboard-fw.overrideAttrs
    (_: { patches = [ ./custom-firmware.patch ]; });
}
```

## Motherboard

Build and flash:
```
nix build  "github:nix-community/hardware-mnt-reform#reform2-lpc-fw-«your-board-rev»" -L
mount «board-rom» /mnt
dd if=result/firmware.bin of="/mnt/firmware.bin" conv=nocreat,notrunc
umount /mnt
```
