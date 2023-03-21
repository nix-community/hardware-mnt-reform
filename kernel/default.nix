{ stdenv, lib, buildLinux, fetchurl, fetchgit, linux_6_1, kernelPatches, ... }@args:

let
  linux = linux_6_1;
  reformKernel = fetchgit {
    url = "https://source.mnt.re/reform/reform-debian-packages.git";
    rev = "503590cbdd5d3a7aea90bf35c1601a6b598edb78";
    sha256 = "sha256-1e5ZeGQmUQyu8g+GGdG2jCRS9OJC7MAfnNectYrPJgg=";
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
  ]);

  allowImportFromDerivation = true;

} // (args.argsOverride or { }))) (attrs: {
  postPatch = attrs.postPatch + ''
    cp ${reformKernel}/*.dts arch/arm64/boot/dts/freescale/
    echo 'dtb-$(CONFIG_ARCH_MXC) += imx8mq-mnt-reform2.dtb imx8mq-mnt-reform2-hdmi.dtb' >> \
      arch/arm64/boot/dts/freescale/Makefile
  '';
  makeFlags = attrs.makeFlags ++ [ "LOADADDR=0x40480000" ];
})
