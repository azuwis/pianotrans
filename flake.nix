{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [(self: super: rec {
          python39 = super.python39.override {
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
                buildInputs = with super.darwin.apple_sdk.frameworks; [ CoreAudio CoreMIDI CoreServices ];
              });
              rtmidi-python = prev.rtmidi-python.overrideAttrs (o: {
                buildInputs = with super.darwin.apple_sdk.frameworks; [ CoreAudio CoreMIDI CoreServices ];
              });
              soundfile = prev.soundfile.overrideAttrs (o: {
                patches = [ ./soundfile.patch ];
                prePatch = ''
                  rm tests/test_pysoundfile.py
                '';
              });
              torchlibrosa = self.python39.pkgs.callPackage ./torchlibrosa.nix {};
              piano-transcription-inference = self.python39.pkgs.callPackage ./piano-transcription-inference.nix {};
              pianotrans = self.python39.pkgs.callPackage ./pianotrans.nix { pytorch = self.python39.pkgs.pytorch-bin; };
            };
          };
          python39Packages = python39.pkgs;
        })];
      };
    in {
      devShell = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          (python39.withPackages(ps: [
            ps.pianotrans
          ]))
          ffmpeg
        ];
      };
    });
}
