{
  inputs = {
    # nixos-24.11-small cuda https://hydra.nix-community.org/jobset/nixpkgs/cuda-stable
    nixpkgs.url = "github:NixOS/nixpkgs/a45fa362d887f4d4a7157d95c28ca9ce2899b70e";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://azuwis.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "azuwis.cachix.org-1:194mFftt8RhaRjVyUrq8ttZCvYFwecVO+D5SC75d+9E="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  outputs =
    inputs@{ ... }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      eachSystem =
        f:
        inputs.nixpkgs.lib.genAttrs systems (
          system:
          f rec {
            inherit system;
            devshell = import inputs.devshell { nixpkgs = pkgs; };
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
            python3-bin = pkgs.python3.override {
              packageOverrides = self: super: { torch = super.torch-bin; };
            };
            python3-cuda =
              (import inputs.nixpkgs {
                inherit system;
                config = {
                  allowUnfree = true;
                  cudaSupport = true;
                };
              }).python3;
          }
        );
    in
    {
      packages = eachSystem (
        {
          pkgs,
          python3-bin,
          python3-cuda,
          ...
        }:
        rec {
          default = pianotrans;
          pianotrans = pkgs.callPackage ./nix/pianotrans { };
          pianotrans-bin = pianotrans.override { python3 = python3-bin; };
          pianotrans-cuda = pianotrans.override { python3 = python3-cuda; };
          pianotrans-mkl =
            let
              inherit (pkgs) runCommand makeWrapper;
            in
            runCommand "pianotrans" { buildInputs = [ makeWrapper ]; } ''
              makeWrapper ${pianotrans}/bin/pianotrans $out/bin/pianotrans \
                --set LD_PRELOAD "${pkgs.mkl}/lib/libblas.so"
            '';
        }
      );

      devShells = eachSystem (
        {
          pkgs,
          devshell,
          python3-bin,
          python3-cuda,
          ...
        }:
        let
          mkShellPkgs = python: [
            (python.withPackages (ps: [
              ps.piano-transcription-inference
              ps.resampy
              ps.tkinter
            ]))
            pkgs.ffmpeg
          ];
        in
        rec {
          default = shell;
          shell = devshell.mkShell { packages = mkShellPkgs pkgs.python3; };
          shell-bin = devshell.mkShell { packages = mkShellPkgs python3-bin; };
          shell-cuda = devshell.mkShell { packages = mkShellPkgs python3-cuda; };
          shell-mkl = devshell.mkShell {
            packages = mkShellPkgs pkgs.python3;
            env = [
              {
                name = "LD_PRELOAD";
                value = "${pkgs.mkl}/lib/libblas.so";
              }
            ];
          };
        }
      );
    };
}
