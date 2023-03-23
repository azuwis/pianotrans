{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.devshell.url = "github:numtide/devshell";
  inputs.devshell.inputs.nixpkgs.follows = "nixpkgs";
  inputs.devshell.inputs.flake-utils.follows = "flake-utils";

  nixConfig.extra-substituters = [ "https://azuwis.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "azuwis.cachix.org-1:194mFftt8RhaRjVyUrq8ttZCvYFwecVO+D5SC75d+9E=" ];

  outputs = inputs@{ ... }:
    inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      devshell = import inputs.devshell { inherit system; nixpkgs = pkgs; };
      pianotrans = pkgs.callPackage ./nix/pianotrans { };
      python3 = pkgs.python3.override {
        packageOverrides = self: super: {
          torch = super.torch-bin;
        };
      };
      pianotrans-bin = pianotrans.override { inherit python3; };
    in {
      packages = {
        default = if pkgs.stdenv.isx86_64 then pianotrans-bin else pianotrans;
        inherit pianotrans pianotrans-bin;
      };
      devShells = {
        default = devshell.mkShell {
          packages = [
            (pkgs.python3.withPackages(ps: [
              ps.piano-transcription-inference
              ps.tkinter
            ]))
            pkgs.ffmpeg
          ];
        };
        bin = devshell.mkShell {
          packages = [
            (python3.withPackages(ps: [
              ps.piano-transcription-inference
              ps.tkinter
            ]))
            pkgs.ffmpeg
          ];
        };
      };
    });
}
