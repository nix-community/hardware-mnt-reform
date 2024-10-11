{
  nixpkgs ? builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/5633bcff0c6162b9e4b5f1264264611e950c8ec7.tar.gz",
  localSystem ? builtins.currentSystem,
}:

rec {
  overlay = import ./overlay.nix;

  pkgsCross = import nixpkgs {
    localSystem = builtins.currentSystem;
    crossSystem = "aarch64-linux";
    overlays = [ overlay ];
  };

  pkgs = import nixpkgs {
    inherit localSystem;
    crossSystem = "aarch64-linux";
    overlays = [ overlay ];
  };

  pocketModule = import ./nixos/pocket.nix;

  installer = import "${nixpkgs}/nixos/lib/eval-config.nix" {
    inherit pkgs;
    system = "aarch64-linux";
    modules = [
      ./nixos/pocket-installer.nix
      pocketModule
      {
        boot.kernelPackages = pkgsCross.linuxPackages_mnt-pocket-reform-arm64-latest;
        sdImage.compressCommand = null;
      }
    ];
  };

  inherit (installer.config.system.build) kernel initialRamdisk sdImage;
}
