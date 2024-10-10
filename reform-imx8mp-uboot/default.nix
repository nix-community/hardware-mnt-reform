# TODO: build the reform2 from here as well.

{
  buildUBoot,
  fetchFromGitHub,
  fetchgit,
}:

let
  mnt = fetchgit {
    url = "https://source.mnt.re/reform/reform-imx8mp-uboot";
    rev = "57b81c914c4e65a84159aa2d000f333f7623d126";
    hash = "sha256-PxN0wS9rL1U7+tOYzh70HhPXroL1TgGkLVOrhD/dbrY=";
  };
  defconfig = "imx8mp-mnt-pocket-reform_defconfig";
in
buildUBoot {
  version = "2022.04";
  inherit defconfig;
  src = fetchFromGitHub {
    owner = "boundarydevices";
    repo = "u-boot";
    rev = "b0e908b1ecbd5762e6cbab30c4c43debd273886e";
    hash = "sha256-qfTKLF0xeYowhgtTJ43ek7ATZC2b2EkQvHVoHaUZWKI=";
  };
  prePatch = ''
    cp ${mnt}/lpddr4*.bin ./
    cp "${mnt}/imx8mp-mnt-pocket-reform.dts" arch/arm/dts/imx8mp-nitrogen8mp.dts
    cp "${mnt}/${defconfig}" configs/
    echo 'dtb-$(CONFIG_ARCH_IMX8M) += imx8mp-mnt-pocket-reform.dtb' >> arch/arm/dts/Makefile
  '';
  patches = [ "${mnt}/nitrogen8mp.patch" ];
  extraMeta.platforms = [ "aarch64-linux" ];
  filesToInstall = [ "flash.bin" ];
}
