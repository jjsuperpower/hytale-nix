{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      json = builtins.fromJSON (builtins.readFile ./launcher.json);

      version = json.version;
      hytale-launcher-zip = pkgs.fetchurl {
        url = "https://launcher.hytale.com/builds/release/linux/amd64/hytale-launcher-${version}.zip";
        sha256 = json.download_url.linux.amd64.sha256;
      };

      hytale-launcher-bin = pkgs.runCommand "hytale-launcher-bin" {
        buildInputs = [ pkgs.unzip ];
      } ''
        mkdir -p $out
        unzip ${hytale-launcher-zip} -d $out
      '';
    in
    {
      packages.x86_64-linux.default = self.packages.x86_64-linux.hytale-launcher;

      packages.x86_64-linux.hytale-launcher = pkgs.buildFHSEnv {
        pname = "hytale-launcher";
        inherit version;

        targetPkgs =
          p: with p; [
            # Launcher
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

        runScript = "${hytale-launcher-bin}/hytale-launcher";
      };
    };
}
