{ lib
, makeWrapper
, symlinkJoin
, microsoft-edge

, glibc
, glib
, nss
, nspr
, atk
, at-spi2-atk
, xorg
, cups
, dbus
, expat
, libdrm
, libxkbcommon
, pipewire
, gtk3
, pango
, cairo
, gdk-pixbuf
, mesa
, alsa-lib
, alsa-lib-with-plugins
, at-spi2-core
, systemd
, wayland

, bash
, coreutils
, system
, patchelf
, llvmPackages
, findutils
}:

# symlinkJoin {
#   name = "microsoft-edge-pipewire";
#   paths = [ microsoft-edge ];
#   nativeBuildInputs = [ makeWrapper ];
#   postBuild =
#     let
#       # libPath = "${pipewire}/lib/alsa-lib:" + (lib.makeLibraryPath [
#       libPath = (lib.makeLibraryPath [
#         glibc
#         glib
#         nss
#         nspr
#         atk
#         at-spi2-atk
#         xorg.libX11
#         xorg.libxcb
#         cups.lib
#         dbus.lib
#         expat
#         libdrm
#         xorg.libXcomposite
#         xorg.libXdamage
#         xorg.libXext
#         xorg.libXfixes
#         xorg.libXrandr
#         libxkbcommon
#         pipewire
#         gtk3
#         pango
#         cairo
#         gdk-pixbuf
#         mesa
#         alsa-lib-with-plugins
#         # alsa-lib
#         at-spi2-core
#         xorg.libxshmfence
#         systemd
#         wayland
#       ]);
#     in
#     ''
#       # echo $out/opt/microsoft/msedge/msedge
#       # ls -la $out/opt/microsoft/msedge/msedge
#       # ls -la `readlink -f $out/opt/microsoft/msedge/msedge`
#       # ORIGINAL=`readlink -f $out/opt/microsoft/msedge/msedge`
#       # rm "$out/opt/microsoft/msedge/msedge"
#       # # cp "$ORIGINAL" "$out/opt/microsoft/msedge/msedge"
#       # # ls -la $out/opt/microsoft/msedge/msedge
#       # # patchelf --set-rpath "${libPath}" "$out/opt/microsoft/msedge/msedge"
#       # # patchelf --set-rpath "${libPath}" `readlink -f $out/opt/microsoft/msedge/msedge`
#       # patchelf --set-rpath "${libPath}" "$ORIGINAL" --output "$out/opt/microsoft/msedge/msedge"
#       # ls -la $out/opt/microsoft/msedge/msedge
#       # rm -rf $out/bin
#       # cp -R ${microsoft-edge}/bin $out/bin

#       cp -R ${microsoft-edge}/* $out/
#       patchelf --set-rpath "${libPath}" "$ORIGINAL" --output "$out/opt/microsoft/msedge/msedge"
#     '';
#   meta.priority = 10;
# }


derivation {
  name = "microsoft-edge-pipewire";
  builder = "${bash}/bin/bash";
  # nativeBuildInputs = [ makeWrapper ];
  args =
    let
      libPath = (lib.makeLibraryPath [
        (derivation {
          name = "alsa-lib-with-pipewire";
          builder = "${bash}/bin/bash";
          args =
            let
              libPath2 = (lib.makeLibraryPath [ glibc ]);
            in
            [
              "-c"
              ''
                PATH="${coreutils}/bin:${patchelf}/bin:${llvmPackages.bintools}/bin:${findutils}/bin"
                mkdir -p "$TMP"
                cp -R ${alsa-lib}/* $TMP/
                find "${pipewire}/lib/alsa-lib/" -type f
                ls -la $TMP/lib
                chmod +w $TMP/lib/
                find "${pipewire}/lib/alsa-lib/" -type f -exec ln -s {} "$TMP/lib/" \;
                echo $TMP
                ls -la $TMP/lib
                mkdir -p "$out"
                cp -R $TMP $out
                rm -rf "$out/lib"
                mkdir -p "$out/lib"
                cd $TMP/lib
                for elf in *; do
                  patchelf --set-rpath "${libPath2}:$out/lib" "$elf" --output "$out/lib/$elf"
                done
                ls -la $out/lib
              ''
            ];
          inherit system;
        })
        glibc
        glib
        nss
        nspr
        atk
        at-spi2-atk
        xorg.libX11
        xorg.libxcb
        cups.lib
        dbus.lib
        expat
        libdrm
        xorg.libXcomposite
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXrandr
        libxkbcommon
        pipewire
        gtk3
        pango
        cairo
        gdk-pixbuf
        mesa
        # (symlinkJoin {
        #   name = "alsa-lib-with-pipewire";
        #   paths = [ alsa-lib ];
        #   postBuild =
        #   ''
        #     #  ln -s "${pipewire}/lib/alsa-lib/*" "$out/lib"
        #     find "${pipewire}/lib/alsa-lib/" -type f -exec ln -s {} "$out/lib/" \;
        #   '';
        # })
        # alsa-lib-with-plugins
        at-spi2-core
        xorg.libxshmfence
        systemd
        wayland
      ]);
    in
    [
      "-c"
      ''
        set -euo pipefail
        PATH="${coreutils}/bin:${patchelf}/bin:${llvmPackages.bintools}/bin"
        mkdir -p "$out"
        cp -R ${microsoft-edge}/* $out/
        ls -la "${microsoft-edge}/opt/microsoft/msedge/msedge"
        chmod -R +w "$out/opt/microsoft/msedge/"
        # patchelf --set-rpath "${libPath}" "${microsoft-edge}/opt/microsoft/msedge/msedge" --output "$out/opt/microsoft/msedge/msedge"
        for elf in msedge msedge-management-service msedge-sandbox msedge_crashpad_handler; do
          ls "${microsoft-edge}/opt/microsoft/msedge/$elf"
          ls "$out/opt/microsoft/msedge/$elf"
          patchelf --set-rpath "${libPath}" "${microsoft-edge}/opt/microsoft/msedge/$elf" --output "$out/opt/microsoft/msedge/$elf"
        done
        echo 1
        echo "$out/opt/microsoft/msedge/msedge"
        readelf -d "$out/opt/microsoft/msedge/msedge" | head -5 || true
        echo 2
      ''
    ];
  inherit system;
}
