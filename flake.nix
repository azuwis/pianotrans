{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    systems.url = "github:nix-systems/default";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";
    devshell = {
      url = "github:numtide/devshell";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  nixConfig.extra-substituters = [ "https://azuwis.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [
    "azuwis.cachix.org-1:194mFftt8RhaRjVyUrq8ttZCvYFwecVO+D5SC75d+9E="
  ];

  outputs =
    inputs@{ self, ... }:
    let
      eachSystem = inputs.nixpkgs.lib.genAttrs (import inputs.systems);
    in
    {
      packages = eachSystem (
        system:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
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
                --set LD_PRELOAD "${pkgs.mkl}/lib/libblas.so"
            '';
        in
        {
          default = pianotrans;
          inherit
            pianotrans
            pianotrans-bin
            pianotrans-mkl
            python3-bin
            ;
        }
      );

      devShells = eachSystem (
        system:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          devshell = import inputs.devshell {
            inherit system;
            nixpkgs = pkgs;
          };
          packages = [
            (pkgs.python3.withPackages (ps: [
              ps.piano-transcription-inference
              ps.resampy
              ps.tkinter
            ]))
            pkgs.ffmpeg
          ];
          shell = devshell.mkShell { inherit packages; };
          shell-mkl = devshell.mkShell {
            inherit packages;
            env = [
              {
                name = "LD_PRELOAD";
                value = "${pkgs.mkl}/lib/libblas.so";
              }
            ];
          };
          shell-bin = devshell.mkShell {
            packages = [
              (self.packages.${system}.python3-bin.withPackages (ps: [
                ps.piano-transcription-inference
                ps.resampy
                ps.tkinter
              ]))
              pkgs.ffmpeg
            ];
          };
        in
        {
          default = shell;
          inherit shell shell-bin shell-mkl;
        }
      );
    };
}
