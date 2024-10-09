{
  description =
    "NixOS hardware configuration and bootable image for the MNT Reform";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";

  outputs = { self, nixpkgs }:
    let
      nixpkgs' = nixpkgs.legacyPackages.aarch64-linux;
      installer = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [ self.nixosModule ./nixos/installer.nix ];
      };
    in {

      overlay = import ./overlay.nix;

      legacyPackages.aarch64-linux = nixpkgs'.extend self.overlay;

      nixosModule = { config, lib, pkgs, ... }:

        {
          boot = {
            initrd = {
              kernelModules = [ "nwl-dsi" "imx-dcss" ];
              availableKernelModules = # hack to remove ATA modules
                lib.mkForce ([
                  "cryptd"
                  "dm_crypt"
                  "dm_mod"
                  "input_leds"
                  "mmc_block"
                  "nvme"
                  "usbhid"
                  "xhci_hcd"
                ] ++ config.boot.initrd.luks.cryptoModules);
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
