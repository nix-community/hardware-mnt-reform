{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot = {
    initrd = {
      kernelModules = [
        "nwl-dsi"
        "imx-dcss"
      ];
      availableKernelModules = # hack to remove ATA modules
        lib.mkForce (
          [
            "cryptd"
            "dm_crypt"
            "dm_mod"
            "input_leds"
            "mmc_block"
            "nvme"
            "usbhid"
            "xhci_hcd"
          ]
          ++ config.boot.initrd.luks.cryptoModules
        );
    };
    extraModprobeConfig = "options imx-dcss dcss_use_hdmi=0";
    kernelPackages = lib.mkDefault pkgs.pkgsFromX86.linuxPackages_mnt-pocket-reform-arm64-latest;
    kernelParams = [
      "console=ttymxc0,115200"
      "console=tty1"
      "pci=nomsi"
    ];
    loader = {
      generic-extlinux-compatible.enable = lib.mkDefault true;
      grub.enable = lib.mkDefault false;
      timeout = lib.mkDefault 1;
      # Cannot interact with U-Boot directly
    };
    supportedFilesystems = lib.mkForce [
      "vfat"
      "f2fs"
      "ntfs"
      "cifs"
    ];
  };

  hardware.deviceTree.name = lib.mkDefault "freescale/imx8mp-mnt-pocket-reform.dtb";

  nixpkgs = {
    system = "aarch64-linux";
    overlays = [ (import ../overlay.nix) ];
  };

  services.fstrim.enable = lib.mkDefault true;
}
