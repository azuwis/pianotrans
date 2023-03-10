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
        config.allowUnfree = true;
        overlays = [ devshell.overlay (self: super: rec {
          pianotrans = super.callPackage ./nix/pianotrans { };
          blas = super.blas.override {
            blasProvider = self.mkl;
          };
        })];
      };
    in rec {
      defaultPackage = pkgs.pianotrans;
      devShell = pkgs.devshell.mkShell {
        packages = [
          (pkgs.python3.withPackages(ps: [
            ps.piano-transcription-inference
            ps.tkinter
          ]))
          pkgs.ffmpeg
        ];
      };
    });
}
