{
  description =
    "NixOS hardware configuration and bootable image for the MNT Reform";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";

  outputs = { self, nixpkgs }:
    let
      nixpkgs' = nixpkgs.legacyPackages.aarch64-linux;
      installer = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [ self.nixosModule ./nixos/installer.nix ];
      };
    in {

      overlay = final: prev:
        {
          linux_6_1 = prev.callPackage ./kernel/linux-6.1.nix {
            kernelPatches = [
              final.kernelPatches.bridge_stp_helper
              final.kernelPatches.request_key_helper
            ];
          };

          linux_reformNitrogen8m_latest =
            prev.callPackage ./kernel { kernelPatches = [ ]; };

          linuxPackages_reformNitrogen8m_latest =
            final.linuxPackagesFor final.linux_reformNitrogen8m_latest;

          ubootReformImx8mq = prev.callPackage ./uboot { };

          reformFirmware = prev.callPackages ./firmware.nix {
            avrStdenv = prev.pkgsCross.avr.stdenv;
            armEmbeddedStdenv = prev.pkgsCross.arm-embedded.stdenv;
          };

        };

      legacyPackages.aarch64-linux = nixpkgs'.extend self.overlay;

      nixosModule = { config, lib, pkgs, ... }:

        {
          boot = {

            kernelPackages =
              lib.mkDefault pkgs.linuxPackages_reformNitrogen8m_latest;

            # Kernel params and modules are chosen to match the original System
            # image (v3).
            # See [gentoo wiki](https://wiki.gentoo.org/wiki/MNT_Reform#u-boot).
            kernelParams = [
              "console=ttymxc0,115200"
              "console=tty1"
              "pci=nomsi"
              "cma=512M"
              "no_console_suspend"
              "ro"
            ];

            # The module load order is significant, It is derived from this
            # custom script from the official system image:
            # https://source.mnt.re/reform/reform-tools/-/blob/c189f5ebb166d61c5f17c15a3c94fdb871cfb5c2/initramfs-tools/reform
            initrd.kernelModules = [
              "nwl-dsi"
              "imx-dcss"
              "reset_imx7"
              "mux_mmio"
              "fixed"
              "i2c-imx"
              "fan53555"
              "i2c_mux_pca954x"
              "pwm_imx27"
              "pwm_bl"
              "panel_edp"
              "ti_sn65dsi86"
              "phy-fsl-imx8-mipi-dphy"
              "mxsfb"
              "usbhid"
              "imx8mq-interconnect"
              "nvme"
            ];

            # hack to remove ATA modules
            initrd.availableKernelModules = lib.mkForce ([
              "cryptd"
              "dm_crypt"
              "dm_mod"
              "input_leds"
              "mmc_block"
              "nvme"
              "usbhid"
              "xhci_hcd"
            ] ++ config.boot.initrd.luks.cryptoModules);

            loader = {
              generic-extlinux-compatible.enable = lib.mkDefault true;
              grub.enable = lib.mkDefault false;
              timeout = lib.mkDefault 2;
            };
            supportedFilesystems = lib.mkForce [ "vfat" "f2fs" "ntfs" "cifs" ];
          };

          boot.kernel.sysctl."vm.swappiness" = lib.mkDefault 1;

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

          programs.sway.extraPackages = # unbloat
            lib.mkDefault (with pkgs; [ swaylock swayidle xwayland ]);

          services.fstrim.enable = lib.mkDefault true;

          system.activationScripts.asound = ''
            if [ ! -e "/var/lib/alsa/asound.state" ]; then
              mkdir -p /var/lib/alsa
              cp ${./initial-asound.state} /var/lib/alsa/asound.state
            fi
          '';
        };

      packages.aarch64-linux = {
        inherit (installer.config.system.build) kernel initialRamdisk sdImage;
      } // self.legacyPackages.aarch64-linux.reformFirmware;

      defaultPackage.aarch64-linux = self.packages.aarch64-linux.sdImage;

    };
}
