{
  description = "Tresorit end-to-end encrypted file sync client, packaged for Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      # Tresorit only ships an x86_64-linux build.
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      # `tresorit` is unfree, so consumers must allow unfree packages. The
      # `packages` output below builds against a nixpkgs with unfree enabled;
      # via the overlay, that is the consumer's responsibility.
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        rec {
          tresorit = pkgs.callPackage ./package.nix { };
          default = tresorit;
        }
      );

      overlays.default = _final: prev: {
        tresorit = prev.callPackage ./package.nix { };
      };

      formatter = forAllSystems (system: (import nixpkgs { inherit system; }).nixfmt-rfc-style);
    };
}
