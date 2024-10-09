{
  pkgs ? import <nixpkgs> {
    crossSystem = "aarch64-linux";
    overlays = [ (import ./overlay.nix) ];
  },
}:

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
