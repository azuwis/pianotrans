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
              mido = prev.mido.overrideAttrs (o:
                if super.stdenv.isDarwin
                then { propagatedBuildInputs = []; }
                else { }
              );
              soundfile = prev.soundfile.overrideAttrs (o:
                if (super.stdenv.system == "aarch64-darwin")
                then {
                  patches = [ ./nix/soundfile/aarch64-darwin.patch ];
                  prePatch = ''
                    rm tests/test_pysoundfile.py
                  '';
                }
                else { }
              );
              torchlibrosa = self.python3.pkgs.callPackage ./nix/torchlibrosa { };
              piano-transcription-inference = self.python3.pkgs.callPackage ./nix/piano-transcription-inference { };
              pianotrans = self.python3.pkgs.callPackage ./pianotrans.nix (
                if super.stdenv.isDarwin
                then { pytorch = self.python3.pkgs.pytorch-bin; }
                else { }
              );
            };
          };
          python3Packages = python3.pkgs;
        })];
      };
    in rec {
      defaultPackage = with pkgs.python3Packages; toPythonApplication pianotrans;
      devShell = pkgs.devshell.mkShell {
        packages = [ defaultPackage ];
      };
    });
}
