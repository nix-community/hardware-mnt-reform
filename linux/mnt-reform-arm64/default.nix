{
  stdenv,
  lib,
  buildLinux,
  fetchurl,
  fetchgit,
  linux_6_10,
  kernelPatches,
  runCommandLocal,
  ...
}@args:

let
  linux = linux_6_10;
  reformDebianPackages = fetchgit {
    url = "https://source.mnt.re/reform/reform-debian-packages";
    rev = "0897ab8a1a0d3034d5b7d6a9e77c4ae1f28651eb";
    sha256 = "sha256-vh47lqoEqN6cjHzddFHFrA1A5BWW1eIrt5fzUf/oNko=";
  };
  mntConfig = runCommandLocal "mnt-kernel-config" { src = reformDebianPackages; } ''
    sed \
      -e 's/CONFIG_//' \
      -e 's/=/ /' \
      <$src/linux/config >$out
  '';
in
lib.overrideDerivation
  (buildLinux (
    args
    // {
      inherit (linux) src version;

      features = {
        efiBootStub = false;
        iwlwifi = false;
      } // (args.features or { });

      kernelPatches =
        let
          patches = lib.filesystem.listFilesRecursive "${reformDebianPackages}/linux/patches6.10";
          reformPatches = map (patch: { inherit patch; }) patches;
        in
        lib.lists.unique (
          kernelPatches
          ++ reformPatches
          ++ [
            {
              name = "mnt-reform-arm64-config";
              patch = null;
              extraConfig = builtins.readFile mntConfig;
            }
            {
              name = "mnt-reform-arm64-config-local";
              patch = null;
              extraConfig = builtins.readFile ./kernel-config;
            }
          ]
        );

      allowImportFromDerivation = true;

    }
    // (args.argsOverride or { })
  ))
  (
    {
      prePatch ? "",
      makeFlags ? [ ],
      ...
    }:
    {
      prePatch =
        prePatch
        + ''
          cp ${reformDebianPackages}/linux/*.dts arch/arm64/boot/dts/freescale/
          echo 'dtb-$(CONFIG_ARCH_MXC) += imx8mq-mnt-reform2.dtb imx8mq-mnt-reform2-hdmi.dtb' >> \
            arch/arm64/boot/dts/freescale/Makefile
        '';
      makeFlags = makeFlags ++ [ "LOADADDR=0x40480000" ];
    }
  )
