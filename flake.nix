{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://azuwis.cachix.org"
      "https://cuda-maintainers.cachix.org"
    ];
    extra-trusted-public-keys = [
      "azuwis.cachix.org-1:194mFftt8RhaRjVyUrq8ttZCvYFwecVO+D5SC75d+9E="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };

  outputs =
    inputs@{ ... }:
    inputs.devshell.inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        blas = "${pkgs.mkl}/lib/libblas.so";
        python3-bin = pkgs.python3.override {
          packageOverrides = self: super: { torch = super.torch-bin; };
        };
        python3-cuda = pkgs.python3.override {
          packageOverrides = self: super: {
            torch = super.torch.override {
              openai-triton = super.openai-triton-cuda;
              cudaSupport = true;
            };
          };
        };

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
            python3-bin
            python3-cuda
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
