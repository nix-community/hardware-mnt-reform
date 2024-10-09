final: prev: with final; {

  linux_5_18 = callPackage ./kernel/linux-5.18.nix {
    kernelPatches = [
      kernelPatches.bridge_stp_helper
      kernelPatches.request_key_helper
      kernelPatches.export_kernel_fpu_functions."5.3"
    ];
  };

  linux_mnt-reform-aarch64-latest = callPackage ./linux/mnt-reform-arm64 { kernelPatches = [ ]; };
  linux_reformNitrogen8m_latest = callPackage ./kernel { kernelPatches = [ ]; };

  linuxPackages_mnt-reform-aarch64 = linuxPackagesFor linux_mnt-reform-aarch64-latest;
  linuxPackages_reformNitrogen8m_latest = linuxPackagesFor linux_reformNitrogen8m_latest;

  ubootReformImx8mq = callPackage ./uboot { };

  reformFirmware = callPackages ./firmware.nix {
    avrStdenv = pkgsCross.avr.stdenv;
    armEmbeddedStdenv = pkgsCross.arm-embedded.stdenv;
  };

}
