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
      rust = false;
    };
    extraMakeFlags = [ "LOADADDR=0x40480000" ];
    structuredExtraConfig =
      with lib.kernel;
      builtins.mapAttrs (_: lib.mkForce) {
        ARCH_ACTIONS = no;
        ARCH_AIROHA = no;
        ARCH_ALPINE = no;
        ARCH_APPLE = no;
        ARCH_BCM = no;
        ARCH_BERLIN = no;
        ARCH_BITMAIN = no;
        ARCH_EXYNOS = no;
        ARCH_HISI = no;
        ARCH_INTEL_SOCFPGA = no;
        ARCH_K3 = no;
        ARCH_KEEMBAY = no;
        ARCH_LAYERSCAPE = no;
        ARCH_LG1K = no;
        ARCH_MA35 = no;
        ARCH_MEDIATEK = no;
        ARCH_MESON = yes;
        ARCH_MVEBU = no;
        ARCH_MXC = yes;
        ARCH_NPCM = no;
        ARCH_PENSANDO = no;
        ARCH_QCOM = no;
        ARCH_REALTEK = no;
        ARCH_RENESAS = no;
        ARCH_ROCKCHIP = yes;
        ARCH_S32 = no;
        ARCH_SEATTLE = no;
        ARCH_SPARX5 = no;
        ARCH_SPRD = no;
        ARCH_STM32 = no;
        ARCH_SUNXI = no;
        ARCH_SYNQUACER = no;
        ARCH_TEGRA = no;
        ARCH_THUNDER = no;
        ARCH_THUNDER2 = no;
        ARCH_UNIPHIER = no;
        ARCH_VEXPRESS = no;
        ARCH_VISCONTI = no;
        ARCH_XGENE = no;
        ARCH_ZYNQMP = no;
        CHROME_PLATFORMS = no;
        DRM_PANEL_JDI_LT070ME05000 = module;

        ATA = module;
        CC_OPTIMIZE_FOR_SIZE = yes;
        DEBUG_KERNEL = no;
        EFI = no;
        EFI_STUB = no;
        EXT3_FS_SECURITY = no;
        EXT4_FS_SECURITY = no;
        FONT_8x16 = no;
        FONT_TER16x32 = no;
        HYPERVISOR_GUEST = no;
        IKCONFIG = yes;
        INFINIBAND = no;
        KEXEC_FILE = no;
        KVM = no;
        LOGO = yes;
        PARAVIRT = no;
        SCSI = module;
        SCSI_SAS_ATA = no;
        VIRTIO = no;
        VIRTUALIZATION = no;
        VIRT_DRIVERS = no;
        XEN = no;

        # SND = no;

        CONFIG_FS_POSIX_ACL = no;
        CRYPTO_ZSTD = no;
        DECOMPRESS_ZSTD = no;
        F2FS_FS_ZSTD = no;
        FW_LOADER_COMPRESS_ZSTD = no;
        KERNEL_ZSTD = no;
        RD_ZSTD = no;
        SQUASHFS_ZSTD = no;
        UBIFS_FS_ZSTD = no;
        ZRAM_DEF_COMP_ZSTD = no;
        ZSTD_COMMON = no;
        ZSTD_COMPRESS = no;
        ZSTD_DECOMPRESS = no;
        ZSWAP_COMPRESSOR_DEFAULT_ZSTD = no;

        AFFS_FS = no;
        AFS_FS = no;
        BCACHEFS_FS = no;
        BEFS_FS = no;
        BFS_FS = no;
        BTRFS_FS = no;
        CODA_FS = no;
        DEBUG_FS = no;
        EFS_FS = no;
        GFS2_FS = no;
        HFSPLUS_FS = no;
        HFS_FS = no;
        JFS_FS = no;
        MINIX_FS = no;
        NFS_FS = no;
        NILFS2_FS = no;
        NR_CPUS = freeform "16";
        NTFS_FS = no;
        OCFS2_FS = no;
        REISERFS_FS = no;
        XFS_FS = no;

      };
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
in
b
