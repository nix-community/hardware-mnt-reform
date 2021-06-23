{
  description = "Bootable NixOS image for the MNT Reform";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/release-21.05";

  outputs = { self, nixpkgs, nixos-hardware }: {
    packages.aarch64-linux = let
      pkgs = nixpkgs.legacyPackages.aarch64-linux;
      installer = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          nixos-hardware.nixosModules.mnt-reform2-nitrogen8m
          ./installer.nix
        ];
      };
    in {
      inherit (installer.config.system.build) kernel initialRamdisk sdImage;
    } // (with pkgs;
      callPackages ./firmware.nix {
        avrGcc = pkgsCross.avr.buildPackages.gcc;
        avrBinutils = pkgsCross.avr.buildPackages.binutils;
      });

    defaultPackage.aarch64-linux = self.packages.aarch64-linux.sdImage;

  };
}
