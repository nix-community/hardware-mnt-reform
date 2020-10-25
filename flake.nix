{
  description = "Bootable NixOS image for the MNT Reform";

  inputs = {
    nixpkgs.url =
      "github:NixOS/nixpkgs/4684bb931179e6a1cf398491cc2df97c03aa963f";
    nixos-hardware.url = "github:NixOS/nixos-hardware/reform";
  };

  outputs = { self, nixpkgs, nixos-hardware }:
    let
      installer = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules =
          [ nixos-hardware.nixosModules.mnt-reform-nitrogen8m ./installer.nix ];
      };
    in {

      packages.aarch64-linux = {
        inherit (installer.config.system.build) kernel initialRamdisk sdImage;
      };

      defaultPackage.aarch64-linux = self.packages.aarch64-linux.sdImage;

    };
}
