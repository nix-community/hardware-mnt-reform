{
  lib,
  stdenv,
  fetchgit,
  linux_6_10,
  kernelPatches,
  runCommandLocal,
  ...
}@args:

let
  reformDebianPackages = fetchgit {
    url = "https://source.mnt.re/reform/reform-debian-packages";
    rev = "0897ab8a1a0d3034d5b7d6a9e77c4ae1f28651eb";
    sha256 = "sha256-vh47lqoEqN6cjHzddFHFrA1A5BWW1eIrt5fzUf/oNko=";
  };
  a = linux_6_10.override {
    features = {
      efiBootStub = false;
      iwlwifi = false;
    };
    # extraMakeFlags = [ "LOADADDR=0x40480000" ];
    kernelPatches = (
      map (patch: { inherit patch; }) (
        lib.filesystem.listFilesRecursive "${reformDebianPackages}/linux/patches6.10/imx8mp-mnt-pocket-reform"
      )
    );
    extraConfig = builtins.readFile (
      runCommandLocal "mnt-kernel-config" { src = reformDebianPackages; } ''
        sed \
          -e '/DRM_PANEL_JDI_LT070ME05000/d' \
          -e '/DWMAC_MESON/d' \
          -e 's/CONFIG_//' \
          -e 's/=/ /' \
          <$src/linux/config >$out
      ''
    );
    extraStructuredConfig = import ./config { inherit lib; };
  };
  b = a.overrideAttrs (
    {
      postPatch ? "",
      ...
    }:
    {
      postPatch =
        postPatch
        + ''
          cp \
            ${reformDebianPackages}/linux/imx8mp-mnt-pocket-reform.dts \
            arch/arm64/boot/dts/freescale/
        '';
    }
  );
in
b
