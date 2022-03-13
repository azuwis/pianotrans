{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.devshell.url = "github:numtide/devshell";
  inputs.devshell.inputs.nixpkgs.follows = "nixpkgs";
  inputs.devshell.inputs.flake-utils.follows = "flake-utils";

  outputs = { self, nixpkgs, flake-utils, devshell }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ devshell.overlay (self: super: rec {
          python3 = super.python3.override {
            packageOverrides = final: prev: {
              torchlibrosa = python3Packages.callPackage ./nix/torchlibrosa { };
              piano-transcription-inference = python3Packages.callPackage ./nix/piano-transcription-inference { };
              pianotrans = python3Packages.callPackage ./nix/pianotrans { };
            } // super.lib.optionalAttrs super.stdenv.isDarwin {
              pytorch = prev.pytorch-bin;
            };
          };
          python3Packages = python3.pkgs;
        })];
      };
    in rec {
      defaultPackage = with pkgs.python3Packages; toPythonApplication pianotrans;
      devShell = pkgs.devshell.mkShell {
        packages = [
          (pkgs.python3.withPackages(ps: [ ps.pianotrans ]))
        ];
      };
    });
}
