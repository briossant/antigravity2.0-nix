# antigravity2.0-nix

[![CI](https://github.com/briossant/antigravity2.0-nix/actions/workflows/ci.yml/badge.svg)](https://github.com/briossant/antigravity2.0-nix/actions/workflows/ci.yml)
[![Auto-update](https://github.com/briossant/antigravity2.0-nix/actions/workflows/update.yml/badge.svg)](https://github.com/briossant/antigravity2.0-nix/actions/workflows/update.yml)
![CLI version](https://img.shields.io/badge/agy-1.0.10-blue)
![Desktop version](https://img.shields.io/badge/antigravity-100.0.0-blue)
![License](https://img.shields.io/github/license/briossant/antigravity2.0-nix)

Nix flake for **Google Antigravity 2.0** — the agent-first development platform announced at Google I/O 2026.

Packages both the **desktop app** and the **CLI** (`agy`), which are not available in nixpkgs (the existing `antigravity` package in nixpkgs is the old v1.x IDE, which is a completely different product).

> The CLI auto-updates daily via GitHub Actions.

---

## Packages

| Attribute | Binary | Description | Architectures |
|---|---|---|---|
| `antigravity-cli` | `agy` | Terminal-first AI coding agent | `x86_64-linux` `aarch64-linux` |
| `antigravity-desktop` | `antigravity` | Antigravity 2.0 desktop app | `x86_64-linux` `aarch64-linux` |
| `default` | `agy` | Alias for `antigravity-cli` | `x86_64-linux` `aarch64-linux` |


---

## Usage

### Quick try (no install)

```bash
nix run github:briossant/antigravity2.0-nix#antigravity-cli
nix run github:briossant/antigravity2.0-nix#antigravity-desktop
```

### Flake input

```nix
# flake.nix
inputs = {
  antigravity2.url = "github:briossant/antigravity2.0-nix";
  antigravity2.inputs.nixpkgs.follows = "nixpkgs";
};
```

### Home Manager module

The easiest way to install both tools declaratively:

```nix
# flake.nix
inputs.antigravity2.url = "github:briossant/antigravity2.0-nix";

# home-manager config
{ inputs, ... }: {
  imports = [ inputs.antigravity2.homeManagerModules.default ];

  programs.antigravity = {
    enable = true;
    cli.enable = true;     # installs agy
    desktop.enable = true; # installs antigravity (x86_64 only)
  };
}
```

### NixOS module

Handles gnome-keyring setup so both tools remember your login across sessions:

```nix
# flake.nix
inputs.antigravity2.url = "github:briossant/antigravity2.0-nix";

# NixOS config
{ inputs, ... }: {
  imports = [ inputs.antigravity2.nixosModules.default ];

  programs.antigravity = {
    enable = true;
    displayManager = "lightdm"; # or "gdm", "sddm" — default: lightdm
  };
}
```

### Overlay

To get `pkgs.antigravity-cli` and `pkgs.antigravity-desktop` in your nixpkgs:

```nix
nixpkgs.overlays = [ inputs.antigravity2.overlays.default ];
```

### nix profile (imperative)

```bash
nix profile install github:briossant/antigravity2.0-nix#antigravity-cli
nix profile install github:briossant/antigravity2.0-nix#antigravity-desktop
```

---

## NixOS notes

- **Login persistence**: use the NixOS module above. Without it, both `agy` and `antigravity` will forget your login on every restart (gnome-keyring needs to be unlocked via PAM).
- **Sandbox**: `--no-sandbox` is applied automatically — Chrome's setuid sandbox requires root setup that NixOS doesn't do by default.
- **Unfree**: `allowUnfree` is set inside the flake; you don't need to set it globally.

---

## Versions

| Package | Version |
|---|---|
| Antigravity CLI (`agy`) | 1.0.0 |
| Antigravity Desktop | 2.0.0 |

CLI updates are automated (daily). Desktop updates are manual for now — PRs welcome.

---

## License

MIT — see [LICENSE](./LICENSE).

Not affiliated with or endorsed by Google. Google Antigravity is proprietary software owned by Google LLC.
