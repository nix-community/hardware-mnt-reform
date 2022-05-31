{ stdenv, lib, buildLinux, fetchurl, fetchgit, linux_5_17, kernelPatches, ... }@args:

let
  linux = linux_5_17;
  reformKernel = fetchgit {
    url = "https://source.mnt.re/reform/reform-debian-packages.git";
    rev = "982efa907e7134b29bbb6b85f7eb121de770135d";
    sha256 = "sha256-4I7k24OztJjhsAkAJ/7LCZ7dCKKNgVYqe/l0PL2qUO4=";
  } + "/linux";
  kernelConfig = stdenv.mkDerivation {
    name = "kernel-config";
    src = reformKernel;
    buildPhase = ''
      cp $src/config kernel-config
      sed -i 's/CONFIG_//' kernel-config
      sed -i 's/=/ /' kernel-config
    '';
    installPhase = ''
      mkdir -p $out
      cp kernel-config $out/kernel-config
    '';
  };
in lib.overrideDerivation (buildLinux (args // {
  inherit (linux) src version;

  features = {
    efiBootStub = false;
    iwlwifi = false;
  } // (args.features or { });

  kernelPatches = let
    patches = lib.filesystem.listFilesRecursive "${reformKernel}/patches";
    reformPatches = map (patch: { inherit patch; }) patches;
  in lib.lists.unique (kernelPatches ++ reformPatches ++ [
    {
      name = "MNT-Reform-imx8mq-config-upstream";
      patch = null;
      extraConfig = builtins.readFile "${kernelConfig}/kernel-config";
    }
    {
      name = "MNT-Reform-imx8mq-config-local";
      patch = null;
      extraConfig = builtins.readFile ./kernel-config;
    }
  ]);

  allowImportFromDerivation = true;

} // (args.argsOverride or { }))) (attrs: {
  prePatch = attrs.prePatch + ''
    cp ${reformKernel}/*.dts arch/arm64/boot/dts/freescale/
    echo 'dtb-$(CONFIG_ARCH_MXC) += imx8mq-mnt-reform2.dtb imx8mq-mnt-reform2-hdmi.dtb' >> \
      arch/arm64/boot/dts/freescale/Makefile
  '';
  makeFlags = attrs.makeFlags ++ [ "LOADADDR=0x40480000" ];
})
