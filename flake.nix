{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.devshell.url = "github:numtide/devshell";
  inputs.devshell.inputs.nixpkgs.follows = "nixpkgs";
  inputs.devshell.inputs.flake-utils.follows = "flake-utils";

  outputs = inputs@{ ... }:
    inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      devshell = import inputs.devshell { inherit system; nixpkgs = pkgs; };
      pianotrans = pkgs.callPackage ./nix/pianotrans { };
      pianotrans-bin = pianotrans.override {
        python3 = pkgs.python3.override {
          packageOverrides = self: super: {
            torch = super.torch-bin;
          };
        };
      };
    in {
      packages = {
        default = pianotrans;
        inherit pianotrans pianotrans-bin;
      };
      devShell = devshell.mkShell {
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
