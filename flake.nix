{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [(self: super: rec {
          python3 = super.python3.override {
            packageOverrides = final: prev: {
              librosa = prev.librosa.overrideAttrs (o: rec {
                version = "0.8.1";
                src = prev.fetchPypi {
                  inherit (o) pname;
                  inherit version;
                  sha256 = "sha256-xT0F52iuSj5VOuIcLlAVKT5e+/1cEtSX8RBMtRnMprM=";
                };
              });
              mido = prev.mido.overrideAttrs (o:
                if super.stdenv.isDarwin
                then { propagatedBuildInputs = []; }
                else { }
              );
              soundfile = prev.soundfile.overrideAttrs (o:
                if (super.stdenv.system == "aarch64-darwin")
                then {
                  patches = [ ./soundfile.patch ];
                  prePatch = ''
                    rm tests/test_pysoundfile.py
                  '';
                }
                else { }
              );
              torchlibrosa = self.python3.pkgs.callPackage ./torchlibrosa.nix {};
              piano-transcription-inference = self.python3.pkgs.callPackage ./piano-transcription-inference.nix {};
              pianotrans = self.python3.pkgs.callPackage ./pianotrans.nix { pytorch = self.python3.pkgs.pytorch-bin; };
            };
          };
          python3Packages = python3.pkgs;
        })];
      };
    in rec {
      defaultPackage = with pkgs.python3Packages; toPythonApplication pianotrans;
      devShell = pkgs.mkShell {
        nativeBuildInputs = [ defaultPackage ];
      };
    });
}
