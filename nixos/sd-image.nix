# The derivation for the SD image will be placed in
# config.system.build.sdImage

{ config, lib, pkgs, modulesPath, ... }:

with lib;

let
  rootfsImage = pkgs.callPackage (modulesPath + "/../lib/make-ext4-fs.nix") ({
    inherit (config.sdImage) storePaths;
    compressImage = false;
    populateImageCommands = config.sdImage.populateRootCommands;
    volumeLabel = "NIXOS_SD";
  } // optionalAttrs (config.sdImage.rootPartitionUUID != null) {
    uuid = config.sdImage.rootPartitionUUID;
  });
in {
  options.sdImage = {
    imageName = mkOption {
      default =
        "${config.sdImage.imageBaseName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.img";
      description = ''
        Name of the generated image file.
      '';
    };

    imageBaseName = mkOption {
      default = "nixos-sd-image";
      description = ''
        Prefix of the name of the generated image file.
      '';
    };

    storePaths = mkOption {
      type = with types; listOf package;
      example = literalExample "[ pkgs.stdenv ]";
      description = ''
        Derivations to be included in the Nix store in the generated SD image.
      '';
    };

    firmwarePartitionName = mkOption {
      type = types.str;
      default = "FIRMWARE";
      description = ''
        Name of the filesystem which holds the boot firmware.
      '';
    };

    rootPartitionUUID = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "14e19a7b-0ae0-484d-9d54-43bd6fdc20c7";
      description = ''
        UUID for the filesystem on the main NixOS partition on the SD card.
      '';
    };

    populateRootCommands = mkOption {
      example = literalExample
        "''\${config.boot.loader.generic-extlinux-compatible.populateCmd} -c \${config.system.build.toplevel} -d ./files/boot''";
      description = ''
        Shell commands to populate the ./files directory.
        All files in that directory are copied to the
        root (/) partition on the SD image. Use this to
        populate the ./files/boot (/boot) directory.
      '';
    };

    compressCommand = mkOption {
      type = types.nullOr types.str;
      example = literalExample "$${pkgs.lz4}/bin/lz4 --rm";
      default = "${pkgs.bzip2}/bin/bzip2";
      description = ''
        Command used to compress the SD image.
      '';
    };

  };

  config = {
    fileSystems = {
      "/boot/firmware" = {
        device = "/dev/disk/by-label/${config.sdImage.firmwarePartitionName}";
        fsType = "vfat";
        # Alternatively, this could be removed from the configuration.
        # The filesystem is not needed at runtime, it could be treated
        # as an opaque blob instead of a discrete FAT32 filesystem.
        options = [ "nofail" "noauto" ];
      };
      "/" = {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
      };
    };

    sdImage.storePaths = [ config.system.build.toplevel ];

    system.build.uboot = pkgs.ubootReformImx8mq;

    system.build.sdImage = pkgs.callPackage
      ({ runCommand, dosfstools, e2fsprogs, mtools, libfaketime, utillinux }:
        runCommand config.sdImage.imageName {
          nativeBuildInputs =
            [ dosfstools e2fsprogs mtools libfaketime utillinux ];
          inherit (config.sdImage) compressCommand;
          inherit rootfsImage;
        } ''
          mkdir -p $out/nix-support $out/sd-image
          export img=$out/sd-image/${config.sdImage.imageName}

          cp -v "$rootfsImage" ./root-fs.img

          # Create the image file sized to fit a 4 MiB gap and /, plus slack.
          rootSizeBlocks=$(du -B 512 --apparent-size ./root-fs.img | awk '{ print $1 }')
          imageSize=$(((rootSizeBlocks + 8192) * 512))
          truncate -s $imageSize $img

          # Use a unique but deterministic partition identifier
          nonce=$(b2sum -l 32 <<< $out)

          # information (dtbs, extlinux.conf file).
          sfdisk $img << END_SFDISK
            label: dos
            label-id: 0x''${nonce::8}
            start=8192, type=L, bootable
          END_SFDISK

          # Copy the rootfs into the SD image
          eval $(partx $img -o START,SECTORS --nr 1 --pairs)
          dd conv=notrunc if=./root-fs.img of=$img seek=$START count=$SECTORS

          # install u-boot for i.MX8M
          dd conv=notrunc if=${pkgs.ubootReformImx8mq}/flash.bin of=$img bs=1k seek=33

          test -n "$compressCommand" && $compressCommand $img

          echo "${pkgs.stdenv.buildPlatform.system}" > $out/nix-support/system
          echo -n "file sd-image " >> $out/nix-support/hydra-build-products
          echo $img* >> $out/nix-support/hydra-build-products
        '') { };

    boot.postBootCommands = ''
      # On the first boot do some maintenance tasks
      if [ -f /nix-path-registration ]; then
        set -euo pipefail
        set -x
        # Figure out device names for the boot device and root filesystem.
        rootPart=$(${pkgs.utillinux}/bin/findmnt -n -o SOURCE /)
        bootDevice=$(lsblk -npo PKNAME $rootPart)

        # Resize the root partition and the filesystem to fit the disk
        echo ",+," | sfdisk -N1 --no-reread $bootDevice
        ${pkgs.parted}/bin/partprobe
        ${pkgs.e2fsprogs}/bin/resize2fs $rootPart

        # Register the contents of the initial Nix store
        ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration

        # nixos-rebuild also requires a "system" profile and an /etc/NIXOS tag.
        touch /etc/NIXOS
        ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system

        # Prevents this from running on later boots.
        rm -f /nix-path-registration
      fi
    '';
  };
}
