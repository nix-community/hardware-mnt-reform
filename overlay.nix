final: prev: {

  linux_5_18 = callPackage ./kernel/linux-5.18.nix {
    kernelPatches = [
      kernelPatches.bridge_stp_helper
      kernelPatches.request_key_helper
      kernelPatches.export_kernel_fpu_functions."5.3"
    ];
  };

  linux_reformNitrogen8m_latest = callPackage ./kernel { kernelPatches = [ ]; };

  linuxPackages_reformNitrogen8m_latest = linuxPackagesFor linux_reformNitrogen8m_latest;

  ubootReformImx8mq = callPackage ./uboot { };

  reformFirmware = callPackages ./firmware.nix {
    avrStdenv = pkgsCross.avr.stdenv;
    armEmbeddedStdenv = pkgsCross.arm-embedded.stdenv;
  };

}
