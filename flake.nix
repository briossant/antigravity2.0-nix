{
  description = "Google Antigravity 2.0 desktop app + Antigravity CLI (agy) for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # ------------------------------------------------------------------ #
        #  Antigravity CLI (agy) - v1.0.0                                     #
        #  Go binary, glibc only, x86_64 + aarch64                            #
        # ------------------------------------------------------------------ #
        cliSrcs = {
          x86_64-linux = {
            url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.0-5288553236791296/linux-x64/cli_linux_x64.tar.gz";
            hash = "sha256-cAljQFdPr8SgbE08gFcxTiLUdc4cgg0K1R/wf7fpnrY=";
          };
          aarch64-linux = {
            url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.0-5288553236791296/linux-arm/cli_linux_arm64.tar.gz";
            hash = "sha256-9Nx8lsGDawB2jYpuxurMeFHzQkvW9Ovk2LhIplIHKoU=";
          };
        };

        antigravity-cli = pkgs.stdenv.mkDerivation {
          pname = "antigravity-cli";
          version = "1.0.0";

          src = pkgs.fetchurl cliSrcs.${system};

          nativeBuildInputs = [ pkgs.autoPatchelfHook ];
          buildInputs = [ pkgs.glibc ];

          dontUnpack = true;

          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin
            tar -xzf $src
            install -Dm755 antigravity $out/bin/agy
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Google Antigravity CLI - terminal-first AI coding agent";
            homepage = "https://antigravity.google";
            license = licenses.unfree;
            platforms = [ "x86_64-linux" "aarch64-linux" ];
            mainProgram = "agy";
          };
        };

        # ------------------------------------------------------------------ #
        #  Antigravity 2.0 Desktop App - v2.0.0                               #
        #  Electron app, x86_64 only for now (arm64 not yet released)         #
        # ------------------------------------------------------------------ #
        antigravity-desktop =
          if system != "x86_64-linux"
          then throw "antigravity-desktop is only available for x86_64-linux (arm64 not yet released by Google)"
          else
            let
              libs = with pkgs; [
                alsa-lib
                at-spi2-atk
                at-spi2-core
                atk
                cairo
                cups
                dbus
                expat
                gdk-pixbuf
                glib
                gtk3
                libdrm
                libgbm
                libGL
                libglvnd
                libxkbcommon
                mesa
                nss
                nspr
                pango
                systemd
                libx11
                libxcomposite
                libxdamage
                libxext
                libxfixes
                libxrandr
                libxcb
                libxshmfence
              ];
            in
            pkgs.stdenv.mkDerivation {
              pname = "antigravity-desktop";
              version = "2.0.0";

              src = pkgs.fetchurl {
                url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/2.0.0-6324554176528384/linux-x64/Antigravity.tar.gz";
                hash = "sha256-FLyctIClvo+zt9w+Kwzr+mbTcK1YzB4PoBFA0SBNQpc=";
              };

              sourceRoot = "Antigravity-x64";

              nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];
              buildInputs = libs;

              installPhase = ''
                runHook preInstall
                mkdir -p $out/share/antigravity
                cp -r . $out/share/antigravity/

                mkdir -p $out/bin
                makeWrapper $out/share/antigravity/antigravity $out/bin/antigravity \
                  --add-flags "--no-sandbox" \
                  --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath libs}

                mkdir -p $out/share/applications
                cat > $out/share/applications/antigravity.desktop << EOF
                [Desktop Entry]
                Name=Antigravity
                Comment=Google Antigravity 2.0 - Agent-first development platform
                Exec=$out/bin/antigravity %U
                Terminal=false
                Type=Application
                Categories=Development;
                StartupWMClass=Antigravity
                EOF
                runHook postInstall
              '';

              meta = with pkgs.lib; {
                description = "Google Antigravity 2.0 - agent-first development platform";
                homepage = "https://antigravity.google";
                license = licenses.unfree;
                platforms = [ "x86_64-linux" ];
                mainProgram = "antigravity";
              };
            };

      in
      {
        packages = {
          inherit antigravity-cli;
          antigravity-desktop =
            if system == "x86_64-linux" then antigravity-desktop
            else pkgs.lib.warn "antigravity-desktop not available for ${system}" null;
          default = antigravity-cli;
        };
      }
    );
}
