{ buildUBoot, fetchgit }:

buildUBoot rec {
  pname = "uboot-reform2-imx8mq";
  version = "2023-01-25";
  src = fetchgit {
    url = "https://source.mnt.re/reform/reform-boundary-uboot.git";
    rev = version;
    sha256 = "sha256-oRZOhXwfjwaq+i+FqJ+QOuQZyoRgLNC30oN7wh2Lxak=";
  };
  defconfig = "nitrogen8m_som_4g_defconfig";
  extraMeta.platforms = [ "aarch64-linux" ];
  filesToInstall = [ "flash.bin" ];
  patches = [ ];
  configurePhase = "cp mntreform-config .config";
  makeFlags = filesToInstall;
}
