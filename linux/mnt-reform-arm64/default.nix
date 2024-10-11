{
  lib,
  stdenv,
  fetchgit,
  fetchurl,
  linux_6_10,
  runCommandLocal,
  linuxManualConfig,
  ...
}@args:

let
  reformDebianPackages = fetchgit {
    url = "https://source.mnt.re/reform/reform-debian-packages";
    rev = "0897ab8a1a0d3034d5b7d6a9e77c4ae1f28651eb";
    sha256 = "sha256-vh47lqoEqN6cjHzddFHFrA1A5BWW1eIrt5fzUf/oNko=";
  };
  a = linux_6_10.override {
    autoModules = false;
    preferBuiltin = false;
    features = {
      efiBootStub = false;
      iwlwifi = false;
    };
    extraMakeFlags = [ "LOADADDR=0x40480000" ];
    kernelPatches = (
      map
        (patch: {
          name = builtins.baseNameOf patch;
          inherit patch;
        })
        (
          lib.filesystem.listFilesRecursive "${reformDebianPackages}/linux/patches6.10/imx8mp-mnt-pocket-reform"
        )
    );
    extraConfig =
      (builtins.readFile (
        runCommandLocal "mnt-kernel-config" { src = reformDebianPackages; } ''
          sed \
            -e '/DRM_PANEL_JDI_LT070ME05000/d' \
            -e '/DWMAC_MESON/d' \
            -e 's/CONFIG_//' \
            -e 's/=/ /' \
            <$src/linux/config >$out
        ''
      ))
      + (builtins.readFile ./kernel-config);
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
            ${reformDebianPackages}/linux/imx8m*.dts \
            arch/arm64/boot/dts/freescale/
          cat << EOF >> arch/arm64/boot/dts/freescale/Makefile
          dtb-\$(CONFIG_ARCH_MXC) += imx8mp-mnt-reform2.dtb
          dtb-\$(CONFIG_ARCH_MXC) += imx8mq-mnt-reform2-hdmi.dtb
          dtb-\$(CONFIG_ARCH_MXC) += imx8mp-mnt-pocket-reform.dtb

          EOF
        '';
    }
  );
  c = linuxManualConfig rec {
    pname = "linux-reform-debian";
    version = "6.11.2";
    src = fetchurl {
      url = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${version}.tar.xz";
      hash = "sha256-7J73oLnOu1WUDh74eh+eEASxBFahGdw4a7PlZbDTnEI=";
    };
    configfile = ../../config-6.11.2-mnt-reform-arm64;
    kernelPatches =
      let
        reformDebianPackages = fetchgit {
          url = "https://source.mnt.re/reform/reform-debian-packages";
          rev = "0897ab8a1a0d3034d5b7d6a9e77c4ae1f28651eb";
          hash = "sha256-vh47lqoEqN6cjHzddFHFrA1A5BWW1eIrt5fzUf/oNko=";
        };
      in
      (map
        (patch: {
          name = builtins.baseNameOf patch;
          inherit patch;
        })
        (
          lib.filesystem.listFilesRecursive "${reformDebianPackages}/linux/patches6.11/imx8mp-mnt-pocket-reform"
        )
      );
  };
in
b
