{
  inputs = {
    # https://hydra.nix-community.org/jobset/nixpkgs/cuda
    nixpkgs.url = "github:NixOS/nixpkgs/ac2df85f4d5c580786c7b4db031c199554152681";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
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
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        pkgsCuda = import inputs.nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
          };
        };

        blas = "${pkgs.mkl}/lib/libblas.so";
        python3-bin = pkgs.python3.override {
          packageOverrides = self: super: { torch = super.torch-bin; };
        };
        python3-cuda = pkgsCuda.python3;

        pianotrans = pkgs.callPackage ./nix/pianotrans { };
        pianotrans-bin = pianotrans.override { python3 = python3-bin; };
        pianotrans-cuda = pianotrans.override { python3 = python3-cuda; };
        pianotrans-mkl =
          let
            inherit (pkgs) runCommand makeWrapper;
          in
          runCommand "pianotrans" { buildInputs = [ makeWrapper ]; } ''
            makeWrapper ${pianotrans}/bin/pianotrans $out/bin/pianotrans \
              --set LD_PRELOAD "${blas}"
          '';

        devshell = import inputs.devshell {
          inherit system;
          nixpkgs = pkgs;
        };
        mkShellPkgs = python: [
          (python.withPackages (ps: [
            ps.piano-transcription-inference
            ps.resampy
            ps.tkinter
          ]))
          pkgs.ffmpeg
        ];

        shell = devshell.mkShell { packages = mkShellPkgs pkgs.python3; };
        shell-bin = devshell.mkShell { packages = mkShellPkgs python3-bin; };
        shell-cuda = devshell.mkShell { packages = mkShellPkgs python3-cuda; };
        shell-mkl = devshell.mkShell {
          packages = mkShellPkgs pkgs.python3;
          env = [
            {
              name = "LD_PRELOAD";
              value = blas;
            }
          ];
        };
      in
      {
        packages = {
          default = pianotrans;
          inherit
            pianotrans
            pianotrans-bin
            pianotrans-cuda
            pianotrans-mkl
            ;
        };
        devShells = {
          default = shell;
          inherit
            shell
            shell-bin
            shell-cuda
            shell-mkl
            ;
        };
      }
    );
}
