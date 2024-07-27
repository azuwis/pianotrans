{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig.extra-substituters = [ "https://azuwis.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [
    "azuwis.cachix.org-1:194mFftt8RhaRjVyUrq8ttZCvYFwecVO+D5SC75d+9E="
  ];

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

        pianotrans = pkgs.callPackage ./nix/pianotrans { };
        pianotrans-bin = pianotrans.override { python3 = python3-bin; };
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
            pianotrans-mkl
            python3-bin
            ;
        };
        devShells = {
          default = shell;
          inherit shell shell-bin shell-mkl;
        };
      }
    );
}
