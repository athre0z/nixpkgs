{ lib
, stdenv
, fetchzip
, fetchurl
, makeDesktopItem
, makeWrapper
, dbus
, fontconfig
, freetype
, libGL
, libxkbcommon
, xorg
, zlib
}:

stdenv.mkDerivation rec {
  pname = "binary-ninja";
  version = "8.1.0.221006";

  src =
    if stdenv.hostPlatform.system != "x86_64-linux" then throw "unsupported platform"
    else
      fetchzip {
        urls = [
          "https://cdn.binary.ninja/installers/BinaryNinja-demo.zip"
        ];
        hash = "sha256-Kor1pRAgGAwG1moz7tstEuDXhX8qHkX69mCE6jWyaxI=";
      };

  icon = fetchurl {
    urls = [
      "https://binary.ninja/icons/apple-touch-icon.png"
    ];
    hash = "sha256-ZTjevoKCIL6JsPqxiv50tslpxRRJIj+PabHxHzCEprI=";
  };

  desktopItem = makeDesktopItem {
    name = pname;
    exec = "binaryninja";
    icon = icon;
    comment = "Binary Ninja is an interactive disassembler, decompiler, and binary analysis platform";
    desktopName = "Binary Ninja Demo";
    genericName = "Interactive Disassembler";
    categories = [ "Development" ];
  };

  ldLibraryPath = lib.makeLibraryPath [
    dbus
    fontconfig
    freetype
    libGL
    libxkbcommon
    stdenv.cc.cc
    xorg.libX11
    xorg.libxcb
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil
    xorg.xcbutilwm
    zlib
  ];

  nativeBuildInputs = [ makeWrapper ];
  
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    BINJA=$out/opt/binary-ninja

    install -d $BINJA $out/{bin,share/applications}

    mv * $BINJA
    mv $BINJA/binaryninja{,-wrapped}

    # patch-elf doesn't like the executable, so we instead just create a wrapper.
    makeWrapper \
      $(cat $NIX_CC/nix-support/dynamic-linker) \
      $BINJA/binaryninja \
      --add-flags $BINJA/binaryninja-wrapped \
      --set LD_LIBRARY_PATH "$BINJA:${ldLibraryPath}" \
      --set QT_PLUGIN_PATH "$BINJA/qt" 

    cp $desktopItem/share/applications/* $out/share/applications
    ln -s $BINJA/binaryninja $out/bin/binaryninja

    runHook postInstall
  '';

  meta = {
    description = "Binary Ninja is an interactive disassembler, decompiler, and binary analysis platform";
    homepage = "https://binary.ninja/demo/";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    # license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ athre0z ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "binaryninja";
  };
}
