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
bzcat ./result/sd-image/nixos-sd-image-20.09.20200831.4684bb9-aarch64-linux.img.bz2 > /dev/mmcblk1
```

## Boot

This image contains a mutable NixOS installation that will initialize itself on first boot.

To install NixOS to the NVMe device:
* format and mount the NVMe at /mnt
* mount /dev/mmcblk1p1 at /mnt/boot (the live image)
* run `nixos-generate-config --root /mnt`

* Add a flake file at `/mnt/etc/nixos/flake.nix` to import configuration from this repository:
```
{
  description = "Configuration for MNT Reform";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    reform.url = "github:nix-community/hardware-mnt-reform";
  };

  outputs = { self, nixpkgs, reform }: {

    nixosConfigurations.reform = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        reform.nixosModule
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
