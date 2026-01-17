{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      hytale_json_url = "https://launcher.hytale.com/version/release/launcher.json";

      download-hytale = pkgs.writeScriptBin "download-hytale" ''
        #!/usr/bin/env bash
        set -euo pipefail

        HYTALE_VERSION=$(${pkgs.curl}/bin/curl -s ${hytale_json_url} | ${pkgs.jq}/bin/jq -r '.version')
        HYTALE_URL=$(${pkgs.curl}/bin/curl -s ${hytale_json_url} | ${pkgs.jq}/bin/jq -r '.download_url.linux.amd64.url')
        HYTALE_SHA256=$(${pkgs.curl}/bin/curl -s ${hytale_json_url} | ${pkgs.jq}/bin/jq -r '.download_url.linux.amd64.sha256')
        TEMP_DIR=$(mktemp -d)

        echo "Downloading Hytale $HYTALE_VERSION launcher..."
        ${pkgs.curl}/bin/curl -L -o "$TEMP_DIR/hytale-game.zip" "$HYTALE_URL"

        echo "Verifying checksum..."
        echo "$HYTALE_SHA256  $TEMP_DIR/hytale-game.zip" | ${pkgs.coreutils}/bin/sha256sum -c -

        echo "Extracting game files..."
        ${pkgs.unzip}/bin/unzip "$TEMP_DIR/hytale-game.zip" -d "$HOME/.hytale"
      '';

      hytale-fhs = pkgs.buildFHSEnv {
        name = "hytale-launcher";
        targetPkgs = pkgs: with pkgs; [
          # launcher
          libsoup_3
          gdk-pixbuf
          glib
          gtk3
          webkitgtk_4_1

          # Game
          alsa-lib
          icu
          libGL
          openssl
          udev
          xorg.libX11
          xorg.libXcursor
          xorg.libXrandr
          xorg.libXi
        ];

        runScript = pkgs.writeScript "launch-hytale" ''
          #!/usr/bin/env bash
          set -euo pipefail

          LAUNCHER_DIR="$HOME/.hytale"
          if [ ! -d "$LAUNCHER_DIR" ]; then
            echo "Hytale launcher not found locally"
            ${download-hytale}/bin/download-hytale
          fi

          echo "Launching Hytale..."
          "$LAUNCHER_DIR/hytale-launcher"
        '';
      };
    in
    {
      packages.x86_64-linux.default = self.packages.x86_64-linux.hytale-launcher;
      packages.x86_64-linux.hytale-launcher = hytale-fhs;
    };
}
