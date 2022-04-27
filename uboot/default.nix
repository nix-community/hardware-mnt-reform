{ buildUBoot, fetchgit }:

buildUBoot rec {
  pname = "uboot-reform2-imx8mq";
  version = "v3";
  src = fetchgit {
    url = "https://source.mnt.re/reform/reform-boundary-uboot.git";
    rev = version;
    sha256 = "sha256-C2JjEz/uv6N08kmzyjhVS8TZKNNtfpRatjGhewEclOM=";
  };
  defconfig = "nitrogen8m_som_4g_defconfig";
  extraMeta.platforms = [ "aarch64-linux" ];
  filesToInstall = [ "flash.bin" ];
  patches = [ ./env_vars.patch ];
  makeFlags = filesToInstall;
}
