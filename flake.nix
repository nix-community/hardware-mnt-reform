{
  description =
    "NixOS hardware configuration and bootable image for the MNT Reform";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/release-20.09";

  outputs = { self, nixpkgs }:
    let
      nixpkgs' = nixpkgs.legacyPackages.aarch64-linux;
      installer = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [ self.nixosModule ./nixos/installer.nix ];
      };
    in {

      overlay = final: prev:
        with final; {

          linux_5_7 = callPackage ./kernel/linux-5.7.nix {
            kernelPatches = [
              kernelPatches.bridge_stp_helper
              kernelPatches.request_key_helper
              kernelPatches.export_kernel_fpu_functions."5.3"
            ];
          };

          linux_reformNitrogen8m_latest =
            callPackage ./kernel { kernelPatches = [ ]; };

          linuxPackages_reformNitrogen8m_latest =
            linuxPackagesFor linux_reformNitrogen8m_latest;

          ubootReformImx8mq = callPackage ./uboot { };

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
