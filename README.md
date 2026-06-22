# tresorit-nix

A Nix flake packaging the [Tresorit](https://tresorit.com) end-to-end encrypted
file sync and sharing client for Linux.

Tresorit is distributed only as a proprietary self-extracting `.run` installer.
This flake unpacks it, patches the binaries for the Nix store, and wires up the
runtime dependencies (X11/XCB/GL, plus `libfuse` for Tresorit Drive).

> **Unfree:** the Tresorit client is proprietary. You must allow unfree packages
> (`nixpkgs.config.allowUnfree = true`, or `NIXPKGS_ALLOW_UNFREE=1`).

## What you get

The package ships all three executables behind a single launcher:

- `tresorit` — the desktop GUI / tray app
- `tresorit-cli` — headless command-line client
- `tresorit-daemon` — the background engine (sync, crypto, Tresorit Drive)

Because Tresorit derives its working directory from `/proc/self/exe` and insists
on writing `running.pid`, logs and self-updates next to its binary, the launcher
mirrors the app into a writable per-user directory (`$XDG_DATA_HOME/tresorit`,
defaulting to `~/.local/share/tresorit`) and execs it from there — matching the
behaviour of the official installer.

## Try it

```sh
NIXPKGS_ALLOW_UNFREE=1 nix run --impure github:mrtnvgh/tresorit-nix
```

## Use as a flake input

```nix
{
  inputs = {
    # ..
    tresorit-nix = {
      url = "github:mrtnvgh/tresorit-nix";
      inputs.nixpkgs.follows = "nixos-unstable";
    };
  };

  outputs = { nixpkgs, tresorit-nix, ... }:
    # ... e.g. in a NixOS/home-manager module:
    # environment.systemPackages = [ tresorit-nix.packages.x86_64-linux.tresorit ];
    # or via the overlay:
    # nixpkgs.overlays = [ tresorit-nix.overlays.default ];
    { };
}
```
