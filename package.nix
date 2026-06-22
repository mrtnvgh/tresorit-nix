{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeDesktopItem,
  copyDesktopItems,
  runtimeShell,
  coreutils,
  libGL,
  libxkbcommon,
  fuse,
  fuse3,
  libx11,
  libxext,
  libxcb,
  libxcb-image,
  libxcb-keysyms,
  libxcb-render-util,
  libxcb-wm,
  libxcb-cursor,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "tresorit";
  version = "3.5.1281.4700";

  src = fetchurl {
    url = "https://installer.tresorit.com/tresorit_installer.run";
    hash = "sha256-6PGp83mFSJSlBmycKyIYS+kU9lZpVWZ8FZccukdjyUM=";
  };

  # Qt is statically linked, so only the X11/XCB/GL stack is needed (via autoPatchelf)
  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
  ];

  buildInputs = [
    (lib.getLib stdenv.cc.cc)
    libGL
    libxkbcommon
    libx11
    libxext
    libxcb
    libxcb-image
    libxcb-keysyms
    libxcb-render-util
    libxcb-wm
  ];

  runtimeDependencies = [
    libxcb-cursor
    (lib.getLib fuse)
    (lib.getLib fuse3)
  ];

  unpackPhase = ''
    runHook preUnpack
    tail -n +93 "$src" | tar xz
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    libdir=$out/share/tresorit
    mkdir -p "$libdir"
    cp -r tresorit_x64/. "$libdir/"

    # Drop installer-only artifacts.
    rm -f "$libdir/uninstall.sh" "$libdir/tresorit.desktop"

    install -Dm644 "$libdir/tresorit.png" \
      "$out/share/icons/hicolor/256x256/apps/tresorit.png"

    # Tresorit derives its workdir from /proc/self/exe and writes running.pid,
    # logs and self-updates there, so it can't run from the read-only store.
    # The launcher mirrors the app into a writable per-user dir (as the official
    # installer does) and execs the binary matching $0 (one script, all three).
    mkdir -p "$out/bin"
    cat > "$out/bin/tresorit" <<'EOF'
#!${runtimeShell}
set -eu
data="''${XDG_DATA_HOME:-$HOME/.local/share}/tresorit"
# Re-sync on any store path change so rebuilds (e.g. RUNPATH fixes) take effect.
if [ "$(${coreutils}/bin/cat "$data/.nix-store" 2>/dev/null || true)" != "${placeholder "out"}" ]; then
  ${coreutils}/bin/mkdir -p "$data"
  ${coreutils}/bin/cp -rfL "${placeholder "out"}/share/tresorit/." "$data/"
  ${coreutils}/bin/chmod -R u+w "$data"
  ${coreutils}/bin/printf %s "${placeholder "out"}" > "$data/.nix-store"
fi
exec "$data/$(${coreutils}/bin/basename "$0")" "$@"
EOF
    chmod +x "$out/bin/tresorit"
    ln -s tresorit "$out/bin/tresorit-cli"
    ln -s tresorit "$out/bin/tresorit-daemon"

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "tresorit";
      desktopName = "Tresorit";
      genericName = "Tresorit";
      comment = "Secure file synchronization and sharing";
      exec = "tresorit %u";
      icon = "tresorit";
      categories = [
        "Utility"
        "Network"
      ];
      mimeTypes = [ "x-scheme-handler/tresorit" ];
      terminal = false;
    })
  ];

  meta = {
    description = "End-to-end encrypted file sync and sharing client";
    homepage = "https://tresorit.com";
    license = lib.licenses.unfree;
    mainProgram = "tresorit";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
