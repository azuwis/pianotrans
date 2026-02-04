{
  inputs = {
    # https://hydra.nixos-cuda.org/jobset/nixos-cuda/cuda-packages-stable
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://azuwis.cachix.org"
      "https://cache.nixos-cuda.org"
    ];
    extra-trusted-public-keys = [
      "azuwis.cachix.org-1:194mFftt8RhaRjVyUrq8ttZCvYFwecVO+D5SC75d+9E="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
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
            python3-rocm =
              (import inputs.nixpkgs {
                inherit system;
                config = {
                  allowUnfree = true;
                  rocmSupport = true;
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
          python3-rocm,
          ...
        }:
        let
          # pianotrans = pkgs.callPackage ./nix/pianotrans { };
          pianotrans = pkgs.pianotrans;
          wrapBlas =
            blas:
            pkgs.runCommand "pianotrans" { buildInputs = [ pkgs.makeWrapper ]; } ''
              makeWrapper ${pianotrans}/bin/pianotrans $out/bin/pianotrans \
                --set LD_PRELOAD "${blas}/lib/libblas.so"
            '';
        in
        {
          inherit pianotrans;
          default = pianotrans;
          pianotrans-bin = pianotrans.override { python3 = python3-bin; };
          pianotrans-blis = wrapBlas pkgs.blis;
          pianotrans-amd-blis = wrapBlas pkgs.amd-blis;
          pianotrans-cuda = pianotrans.override { python3 = python3-cuda; };
          pianotrans-mkl = wrapBlas pkgs.mkl;
          pianotrans-rocm = pianotrans.override { python3 = python3-rocm; };
        }
      );

      devShells = eachSystem (
        {
          pkgs,
          devshell,
          python3-bin,
          python3-cuda,
          python3-rocm,
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
          shell = devshell.mkShell { packages = mkShellPkgs pkgs.python3; };
          wrapBlas =
            blas:
            devshell.mkShell {
              packages = mkShellPkgs pkgs.python3;
              env = [
                {
                  name = "LD_PRELOAD";
                  value = "${blas}/lib/libblas.so";
                }
              ];
            };
        in
        {
          inherit shell;
          default = shell;
          shell-amd-blis = wrapBlas pkgs.amd-blis;
          shell-bin = devshell.mkShell { packages = mkShellPkgs python3-bin; };
          shell-blis = wrapBlas pkgs.blis;
          shell-cuda = devshell.mkShell { packages = mkShellPkgs python3-cuda; };
          shell-mkl = wrapBlas pkgs.mkl;
          shell-rocm = devshell.mkShell { packages = mkShellPkgs python3-rocm; };
        }
      );
    };
}
