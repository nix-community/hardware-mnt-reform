{
  description =
    "NixOS hardware configuration and bootable image for the MNT Reform";

  inputs.nixpkgs.url = # The last version of Nixpkgs with linux_5_7
    "github:NixOS/nixpkgs/4684bb931179e6a1cf398491cc2df97c03aa963f";

  outputs = { self, nixpkgs }:
    let
      nixpkgs' = nixpkgs.legacyPackages.aarch64-linux;
      installer = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [ self.nixosModule ./nixos/installer.nix ];
      };
    in {

      overlay = final: prev: {

        inherit (nixpkgs') linux_5_7;

        linux_reformNitrogen8m_latest =
          final.callPackage ./kernel { kernelPatches = [ ]; };

        linuxPackages_reformNitrogen8m_latest =
          final.linuxPackagesFor final.linux_reformNitrogen8m_latest;

        ubootReformImx8mq = final.callPackage ./uboot { };

      };

      legacyPackages.aarch64-linux = nixpkgs'.extend self.overlay;

      nixosModule = { config, lib, pkgs, ... }:

        {
          boot = {
            initrd = {
              availableKernelModules = [ "nvme" "usbhid" ];
              kernelModules = [ "nwl-dsi" "imx-dcss" ];
            };
            extraModprobeConfig = "options imx-dcss dcss_use_hdmi=0";
            kernelPackages =
              lib.mkDefault pkgs.linuxPackages_reformNitrogen8m_latest;
            kernelParams =
              [ "console=ttymxc0,115200" "console=tty1" "pci=nomsi" ];
            loader = {
              generic-extlinux-compatible.enable = lib.mkDefault true;
              grub.enable = lib.mkDefault false;
              timeout = lib.mkDefault 1;
              # Cannot interact with U-Boot directly
            };
          };

          environment.etc."systemd/system.conf".text =
            "DefaultTimeoutStopSec=15s";

          environment.systemPackages = with pkgs; [ brightnessctl usbutils ];

          hardware.deviceTree.name =
            lib.mkDefault "freescale/imx8mq-mnt-reform2.dtb";

          hardware.pulseaudio.daemon.config.default-sample-rate =
            lib.mkDefault "48000";

          nixpkgs = {
            system = "aarch64-linux";
            overlays = [ self.overlay ];
          };

          system.activationScripts.asound = ''
            if [ ! -e "/var/lib/alsa/asound.state" ]; then
              mkdir -p /var/lib/alsa
              cp ${./initial-asound.state} /var/lib/alsa/asound.state
            fi
          '';
        };

      packages.aarch64-linux = {
        inherit (installer.config.system.build) kernel initialRamdisk sdImage;
      };

      defaultPackage.aarch64-linux = self.packages.aarch64-linux.sdImage;

    };
}
