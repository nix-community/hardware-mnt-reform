final: prev: with final; {

  linux_5_18 = callPackage ./kernel/linux-5.18.nix {
    kernelPatches = [
      kernelPatches.bridge_stp_helper
      kernelPatches.request_key_helper
      kernelPatches.export_kernel_fpu_functions."5.3"
    ];
  };

  linux_mnt-pocket-reform-arm64-latest = callPackage ./linux/mnt-reform-arm64 { };
  linux_reformNitrogen8m_latest = callPackage ./kernel { kernelPatches = [ ]; };

  linuxPackages_mnt-pocket-reform-arm64-latest = linuxPackagesFor linux_mnt-pocket-reform-arm64-latest;
  linuxPackages_reformNitrogen8m_latest = linuxPackagesFor linux_reformNitrogen8m_latest;

  ubootReformImx8mq = callPackage ./uboot { };
  ubootReformImx8mp = callPackage ./reform-imx8mp-uboot { };

  reformFirmware = callPackages ./firmware.nix {
    avrStdenv = pkgsCross.avr.stdenv;
    armEmbeddedStdenv = pkgsCross.arm-embedded.stdenv;
  };

}
