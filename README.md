# Bootable NixOS SD image

|[Download latest image](https://nightly.link/nix-community/hardware-mnt-reform/workflows/image/master/nixos-mnt-reform.zip)|

Requires an aarch64 host and Nix with [flake support](https://www.tweag.io/blog/2020-05-25-flakes/).

<details>
  <summary>Use flakes (required)</summary>

  ```
    mkdir -p ~/.config/nix
    echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
    nix-shell -p nixUnstable
  ```
</details>

<details>
  <summary>Use nix-community binary cache (recommended)</summary>

  Configure for the current user:
  ```
    nix run nixpkgs#cachix -- use nix-community -m user-nixconf -v
  ```

  Generate a configuration for system-wide installation:
  ```
    sudo nix run nixpkgs#cachix -- use nix-community -m nixos -v
  ```
</details>

## Describe
```
nix flake show "github:nix-community/hardware-mnt-reform"
nix flake list-inputs "github:nix-community/hardware-mnt-reform"
```

## Build
```
nix build "github:nix-community/hardware-mnt-reform" -L
readlink result
```

## Flash
```
bzcat ./result/sd-image/nixos-sd-image-*-aarch64-linux.img.bz2 > /dev/mmcblk1
```

## Boot

This image contains a mutable NixOS installation that will initialize itself on the first boot.

## Install NixOS on the NVMe

<details>
  <summary>Setup wireless connection</summary>

  ```
    sudo -i
    wpa_supplicant -B -i wlp1s0 -c <(wpa_passphrase ${SSID} ${PASSWORD})
  ```
</details>

<details>
  <summary>Use flakes (required)</summary>

  ```
    mkdir -p ~/.config/nix
    echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
    nix-shell -p nixUnstable
  ```
</details>

<details>
  <summary>Enable binary cache (strongly recommended)</summary>

  ```
    nix run nixpkgs#cachix -- use nix-community -m user-nixconf -v
  ```
</details>

Prepare partitions:
* <details>
    <summary>Encrypted (recommended)</summary>

    ```
      parted /dev/nvme0n1 mklabel gpt
      parted /dev/nvme0n1 mkpart NIX ext4 0% 100%
      cryptsetup luksFormat /dev/nvme0n1p1
      cryptsetup open /dev/nvme0n1p1 nix
      mkfs.ext4 /dev/mapper/nix
      mount /dev/mapper/nix /mnt/

      parted /dev/mmcblk0 mklabel gpt
      parted /dev/mmcblk0 mkpart BOOT ext4 0% 100%
      mkfs.ext4 /dev/mmcblk0p1
      mount /dev/mmcblk0p1 /mnt/boot
    ```
  </details>

* <details>
    <summary>Plain text</summary>

    ```
      parted /dev/nvme0n1 mklabel gpt
      parted /dev/nvme0n1 mkpart NIX ext4 0% 100%
      mkfs.ext4 /dev/nvme0n1
      mount /dev/nvme0n1 /mnt

      parted /dev/mmcblk0 mklabel gpt
      parted /dev/mmcblk0 mkpart BOOT ext4 0% 100%
      mkfs.ext4 /dev/mmcblk0p1
      mount /dev/mmcblk0p1 /mnt/boot
    ```
  </details>

Flash bootloader:
```
  nix build "github:nix-community/hardware-mnt-reform#ubootReformImx8mq
  echo 0 > /sys/class/block/mmcblk0boot0/force_ro
  dd if=result/flash.bin of=/dev/mmcblk0boot0 bs=1024 seek=33
```

Generate basic configuration:
```
nixos-generate-config --root /mnt
```

<details>
  <summary>Configuration (required)</summary>

  Add a flake file at `/mnt/etc/nixos/flake.nix` to import configuration from this repository:
  ```
    {
      description = "Configuration for MNT Reform";

      inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
        reform.url = "github:nix-community/hardware-mnt-reform";
      };

      outputs = { self, nixpkgs, reform }: {

        nixosConfigurations.reform = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            reform.nixosModule
            ./configuration.nix
            ({ pkgs, ... }: {
              nix.package = pkgs.nixFlakes;
              programs.sway.enable = true;
            })
          ];
        };

      };
    }
  ```
</details>

Start installation:
```
nixos-install --verbose --impure --flake /mnt/etc/nixos#reform
```

Shutdown the machine, and flip the DIP switch on the Nitrogen8M_SOM module (under the heatsink). After this step, MNT Reform will boot from NVMe without an SD card. Don't forget to enable binary cache to avoid compiling kernels on the device itself.

For more information see the  [NixOS manual](https://nixos.org/manual/nixos/stable/#sec-installation)

<details>
  <summary>How to upgrade</summary>

  ```
    nixos-rebuild switch --recreate-lock-file --verbose --impure --flake /etc/nixos#reform

    # in case there is new u-boot
    nix build "github:nix-community/hardware-mnt-reform#ubootReformImx8mq"
    echo 0 > /sys/class/block/mmcblk0boot0/force_ro
    dd if=result/flash.bin of=/dev/mmcblk0boot0 bs=1024 seek=33
  ```
</details>

<details>
  <summary>Important notes</summary>

  * There may be an issue with the early console with some kernel versions (e.g. I haven't managed to make it work on Linux v5.17.6 at the time of writing this). Just type the password blindly.
  * You can choose the NixOS generation at the boot process with UART.
</details>

# Firmware

## Keyboard

Flash the stock keyboard firmware (assuming the keyboard is in programming mode):
```
doas nix run "github:nix-community/hardware-mnt-reform#reform2-keyboard-fw" -L
```

Override the keyboard layout:
```
let
  hardware-mnt-reform =
    builtins.getFlake "github:nix-community/hardware-mnt-reform";
in {
  reform2-keyboard-fw =
    hardware-mnt-reform.packages.aarch64-linux.reform2-keyboard-fw.overrideAttrs
    (_: { patches = [ ./custom-firmware.patch ]; });
}
```

## Motherboard

Build and flash:
```
nix build  "github:nix-community/hardware-mnt-reform#reform2-lpc-fw-«your-board-rev»" -L
mount «board-rom» /mnt
dd if=result/firmware.bin of="/mnt/firmware.bin" conv=nocreat,notrunc
umount /mnt
```
