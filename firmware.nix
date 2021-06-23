{ lib, stdenv, fetchgit, dfu-programmer, avrGcc, avrBinutils, runtimeShell }:

let
  version = "2021-06-10";
  src = fetchgit {
    url = "https://source.mnt.re/reform/reform.git";
    rev = "00035d71d17d34d5580539e7bf4164ddf0257643";
    sha256 = "05kzzsc9m39ma3w5ygglcdz9pyhj2kjgvcg5w4iqb4dcnd66jiki";
  };
in {

  reform2-keyboard-fw = stdenv.mkDerivation rec {
    pname = "reform2-keyboard-fw";
    inherit version src;
    preConfigure = "cd $pname";
    buildInputs = [ avrGcc avrBinutils ];
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
