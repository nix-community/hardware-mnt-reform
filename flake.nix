{
  description =
    "NixOS hardware configuration and bootable image for the MNT Reform";

  inputs.nixpkgs.url =
    "github:NixOS/nixpkgs/4684bb931179e6a1cf398491cc2df97c03aa963f";

  outputs = { self, nixpkgs }:
    let
      installer = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [ self.nixosModules.default ./installer.nix ];
      };
    in {

      nixosModules.default =
        import ./nixos-module.nix nixpkgs.legacyPackages.aarch64-linux;

      packages.aarch64-linux = {
        inherit (installer.config.system.build) kernel initialRamdisk sdImage;
      };

      defaultPackage.aarch64-linux = self.packages.aarch64-linux.sdImage;

    };
}
