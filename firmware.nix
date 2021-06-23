{ lib, stdenv, fetchgit, dfu-programmer, runtimeShell, gcc

, armEmbeddedStdenv, avrStdenv }:

let
  version = "2021-06-10";
  src = fetchgit {
    url = "https://source.mnt.re/reform/reform.git";
    rev = "00035d71d17d34d5580539e7bf4164ddf0257643";
    sha256 = "05kzzsc9m39ma3w5ygglcdz9pyhj2kjgvcg5w4iqb4dcnd66jiki";
  };

  mkLpcFirmware = board:
    armEmbeddedStdenv.mkDerivation rec {
      pname = "reform2-lpc-fw-${board}";
      inherit version src;
      nativeBuildInputs = [ gcc ];
      hardeningDisable = [ "format" ];
      preConfigure = ''
        cd reform2-lpc-fw
        substituteInPlace src/boards/reform2/board_reform2.c \
          --replace \
            "define REFORM_MOTHERBOARD_REV REFORM_MBREV_R2" \
            "define REFORM_MOTHERBOARD_REV REFORM_MBREV_${board}"
      '';
      preBuild = # probably better than recursive make
        ''
          pushd tools/lpcrc
          make
          popd
        '';
      installPhase = ''
        runHook preInstall
        install -Dt $out bin/firmware.bin
        runHook postInstall
      '';
    };

  boardRevs = [ "D2" "D3" "D4" "R1" "R2" "R3" ];

  boardBuilds = builtins.listToAttrs (map (rev:
    let value = mkLpcFirmware rev;
    in {
      name = value.pname;
      inherit value;
    }) boardRevs);

in boardBuilds // {

  reform2-keyboard-fw = avrStdenv.mkDerivation rec {
    pname = "reform2-keyboard-fw";
    inherit version src;
    preConfigure = "cd $pname";
    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin

      cp Keyboard.hex $out/

      cat << EOF >> $out/bin/$pname
      #! ${runtimeShell}
      DFUP=${dfu-programmer}/bin/dfu-programmer
      \$DFUP atmega32u4 erase --suppress-bootloader-mem
      \$DFUP atmega32u4 flash $out/Keyboard.hex --suppress-bootloader-mem
      \$DFUP atmega32u4 start
      EOF
      chmod +x $out/bin/$pname

      runHook postInstall
    '';
  };

}
