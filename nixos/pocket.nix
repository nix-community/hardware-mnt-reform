{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot = {
    blacklistedKernelModules = [
      "imx8m-ddrc"
      "raid456"
      "ath10k_sdio"
    ];
    initrd = {
      availableKernelModules = lib.mkForce [ ];
      kernelModules = [ "imx_bus" ];
    };
    kernelPackages = lib.mkDefault pkgs.linuxPackages_mnt-pocket-reform-arm64-latest;
    kernelParams = [
      "cma=256MB"
      "console=tty1"
      "console=ttymxc0,115200"
      "fbcon=rotate:3"
      "no_console_suspend"
      "nvme_core.default_ps_max_latency_us=0"
      "pci=pcie_bus_perf"
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
