{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      perSystem =
        { pkgs, lib, ... }:
        let
          libusb_zig = pkgs.stdenv.mkDerivation {
            name = "libusb_zig";
            src = lib.cleanSource ./.;
            doCheck = true;

            nativeBuildInputs = [
              pkgs.zig_0_15.hook
            ];

            # postPatch = ''
            #   ln -s ${pkgs.callPackage ./.deps.nix { }} $ZIG_GLOBAL_CACHE_DIR/p
            #
            #   # # Remove NIX_CFLAGS_COMPILE because zig cannot understand it
            #   # unset NIX_CFLAGS_COMPILE
            # '';
          };
        in
        {
          treefmt = {
            projectRootFile = ".git/config";

            # Nix
            programs.nixfmt.enable = true;

            # Zig
            programs.zig.enable = true;
            settings.formatter.zig.command = lib.getExe pkgs.zig_0_15;

            # GitHub Actions
            programs.actionlint.enable = true;

            # Markdown
            programs.mdformat.enable = true;
            settings.formatter.mdformat.excludes = [ "CODE_OF_CONDUCT.md" ];
          };

          packages = {
            inherit libusb_zig;
            default = libusb_zig;
          };

          checks = {
            inherit libusb_zig;
          };

          devShells.default = pkgs.mkShell {
            nativeBuildInputs = [
              # Compiler
              pkgs.zig_0_15
              pkgs.pkg-config

              # LSP
              pkgs.nil
              pkgs.zls

              # zon2nix
              pkgs.zon2nix
            ];

            buildInputs = [
              pkgs.libusb1
            ];

            # shellHook = ''
            #   # Remove NIX_CFLAGS_COMPILE because zig cannot understand it
            #   unset NIX_CFLAGS_COMPILE
            # '';
          };
        };
    };
}
