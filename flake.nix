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
              python-rtmidi = prev.python-rtmidi.overrideAttrs (o: {
                buildInputs = if super.stdenv.isDarwin
                  then with super.darwin.apple_sdk.frameworks; [ CoreAudio CoreMIDI CoreServices ]
                  else o.buildInputs;
              });
              rtmidi-python = prev.rtmidi-python.overrideAttrs (o: {
                buildInputs = if super.stdenv.isDarwin
                  then with super.darwin.apple_sdk.frameworks; [ CoreAudio CoreMIDI CoreServices ]
                  else o.buildInputs;
              });
              soundfile = prev.soundfile.overrideAttrs (o: {
                patches = if (super.stdenv.system == "aarch64-darwin") then [ ./soundfile.patch ] else o.patches;
                prePatch = if (super.stdenv.system == "aarch64-darwin") then ''
                  rm tests/test_pysoundfile.py
                '' else o.prePatch;
              });
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
