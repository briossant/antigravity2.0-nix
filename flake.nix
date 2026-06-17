{
  description = "Google Antigravity 2.0 desktop app + Antigravity CLI (agy) for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      # ------------------------------------------------------------------ #
      #  Per-system packages                                                 #
      # ------------------------------------------------------------------ #
      perSystem = flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          # -------------------------------------------------------------- #
          #  Antigravity CLI (agy) - v1.0.0                                 #
          #  Go binary, glibc only, x86_64 + aarch64                        #
          # -------------------------------------------------------------- #
          cliSrcs = {
            x86_64-linux = {
              url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.9-6003845613092864/linux-x64/cli_linux_x64.tar.gz";
              hash = "sha256-zYD4X0O1Kzide0mNZ4T4MW1Xqcxi6uI9hAxd42j5xNU=";
            };
            aarch64-linux = {
              url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.9-6003845613092864/linux-arm/cli_linux_arm64.tar.gz";
              hash = "sha256-lE1nBWt8xuRBHcqE2fB3seRgyM0qRDLSzfIZQh/3Plo=";
            };
          };

          antigravity-cli = pkgs.stdenv.mkDerivation {
            pname = "antigravity-cli";
            version = "1.0.9";

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

          # -------------------------------------------------------------- #
          #  Antigravity 2.0 Desktop App - v2.0.0                           #
          #  Electron app, x86_64-linux + aarch64-linux                     #
          # -------------------------------------------------------------- #
          desktopLibs = with pkgs; [
            alsa-lib
            at-spi2-atk
            at-spi2-core
            atk
            cairo
            cups
            dbus
            expat
            fontconfig
            freetype
            gdk-pixbuf
            glib
            gsettings-desktop-schemas
            gtk3
            libdrm
            libgbm
            libGL
            libglvnd
            libnotify
            libpulseaudio
            libsecret
            libuuid
            libxml2
            libxkbcommon
            mesa
            nspr
            nss
            pango
            stdenv.cc.cc
            systemd
            vulkan-loader
            wayland
            libx11
            libxcomposite
            libxcursor
            libxdamage
            libxext
            libxfixes
            libxi
            libxrandr
            libxrender
            libxt
            libxtst
            libxcb
            libxshmfence
          ];

          desktopSrcs = {
            x86_64-linux = {
              url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/100.0.0-5871373990625280/linux-x64/Antigravity.tar.gz";
              hash = "sha256-+88Vz9wR/IFuDK8EXqB6bNaUutI5vv0JSGBmHyjtLUY=";
              sourceRoot = "Antigravity-x64";
            };
            aarch64-linux = {
              url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/100.0.0-5871373990625280/linux-arm/Antigravity.tar.gz";
              hash = "sha256-xuDoPbJRFf1O0U8ETNzBCX8hE3yUl3NK30Y1gr5hXyw=";
              sourceRoot = "Antigravity-arm64";
            };
          };

          antigravity-desktop =
            pkgs.lib.makeOverridable ({ passwordStore ? "basic" }:
              pkgs.stdenv.mkDerivation {
                pname = "antigravity-desktop";
                version = "100.0.0";

                src = pkgs.fetchurl {
                  inherit (desktopSrcs.${system}) url hash;
                };

                sourceRoot = desktopSrcs.${system}.sourceRoot;

                nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];
                buildInputs = desktopLibs;

                installPhase = ''
                  runHook preInstall
                  mkdir -p $out/share/antigravity
                  cp -r . $out/share/antigravity/

                  mkdir -p $out/bin
                  makeWrapper $out/share/antigravity/antigravity $out/bin/antigravity \
                    --add-flags "--no-sandbox" \
                    ${pkgs.lib.optionalString (passwordStore != "") "--add-flags \"--password-store=${passwordStore}\""} \
                    --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.xdg-utils ]} \
                    --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath desktopLibs} \
                    --prefix XDG_DATA_DIRS : "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}" \
                    --prefix XDG_DATA_DIRS : "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"

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
                  platforms = [ "x86_64-linux" "aarch64-linux" ];
                  mainProgram = "antigravity";
                };
              }) {};

        in
        {
          packages = {
            inherit antigravity-cli antigravity-desktop;
            default = antigravity-cli;
          };
        }
      );

    in
    perSystem // {

      # ------------------------------------------------------------------ #
      #  Overlay — drop antigravity-cli / antigravity-desktop into pkgs     #
      # ------------------------------------------------------------------ #
      overlays.default = final: _prev: {
        antigravity-cli =
          self.packages.${final.system}.antigravity-cli;
        antigravity-desktop =
          self.packages.${final.system}.antigravity-desktop;
      };

      # ------------------------------------------------------------------ #
      #  Home Manager module                                                 #
      # ------------------------------------------------------------------ #
      homeManagerModules.default = { config, lib, pkgs, ... }:
        let cfg = config.programs.antigravity;
        in {
          options.programs.antigravity = {
            enable = lib.mkEnableOption "Google Antigravity 2.0";
            cli.enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Install the agy CLI tool.";
            };
            desktop.enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Install the Antigravity 2.0 desktop app (x86_64-linux and aarch64-linux).";
            };
            desktop.passwordStore = lib.mkOption {
              type = lib.types.enum [ "basic" "gnome-libsecret" "kwallet" "" ];
              default = "basic";
              description = ''
                Electron password store backend.
                - "basic": store credentials on disk (no keyring needed — recommended for non-GNOME setups and autologin).
                - "gnome-libsecret": use gnome-keyring (requires a running, unlocked keyring daemon).
                - "kwallet": use KDE Wallet.
                - "": let Electron decide (default upstream behaviour).
              '';
            };
          };

          config = lib.mkIf cfg.enable {
            home.packages =
              lib.optionals cfg.cli.enable [
                self.packages.${pkgs.stdenv.hostPlatform.system}.antigravity-cli
              ]
              ++ lib.optionals cfg.desktop.enable [
                (self.packages.${pkgs.stdenv.hostPlatform.system}.antigravity-desktop.override {
                  inherit (cfg.desktop) passwordStore;
                })
              ];
          };
        };

      # ------------------------------------------------------------------ #
      #  NixOS module — keyring setup for session persistence               #
      # ------------------------------------------------------------------ #
      nixosModules.default = { config, lib, ... }:
        let cfg = config.programs.antigravity;
        in {
          options.programs.antigravity = {
            enable = lib.mkEnableOption "Google Antigravity 2.0 keyring support";
            displayManager = lib.mkOption {
              type = lib.types.str;
              default = "lightdm";
              description = "PAM display manager service to enable gnome-keyring on (e.g. lightdm, gdm, sddm).";
            };
          };

          config = lib.mkIf cfg.enable {
            services.gnome.gnome-keyring.enable = true;
            security.pam.services.${cfg.displayManager}.enableGnomeKeyring = lib.mkDefault true;
            security.pam.services.login.enableGnomeKeyring = lib.mkDefault true;
          };
        };

    };
}
