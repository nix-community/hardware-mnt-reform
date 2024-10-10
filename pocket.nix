let
  nixpkgs = import (
    builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/5633bcff0c6162b9e4b5f1264264611e950c8ec7.tar.gz"
  );
  overlay = import ./overlay.nix;
  pkgsFromX86 = nixpkgs {
    localSystem = "x86_64-linux";
    crossSystem = "aarch64-linux";
    overlays = [ overlay ];
  };
  pkgs = nixpkgs {
    localSystem = "aarch64-linux";
    crossSystem = "aarch64-linux";
    overlays = [
      (final: prev: { inherit pkgsFromX86; })
      overlay
    ];
  };
in
rec {
  inherit pkgs;

  pocketModule = import ./nixos/pocket.nix;

  installer = import "${<nixpkgs>}/nixos/lib/eval-config.nix" {
    inherit pkgs;
    system = "aarch64-linux";
    modules = [
      ./nixos/pocket-installer.nix
      pocketModule
    ];
  };

  inherit (installer.config.system.build) kernel initialRamdisk sdImage;
}
