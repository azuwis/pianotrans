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
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          pkgsUnfree = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          python3-bin = pkgsUnfree.python3.override {
            packageOverrides = self: super: { torch = super.torch-bin; };
          };
          pianotrans = pkgs.callPackage ./nix/pianotrans { };
          pianotrans-bin = pianotrans.override { python3 = python3-bin; };
        in
        {
          default = if pkgs.stdenv.isx86_64 then pianotrans-bin else pianotrans;
          inherit pianotrans pianotrans-bin python3-bin;
        }
      );

      devShells = eachSystem (
        system:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          devshell = import inputs.devshell {
            inherit system;
            nixpkgs = pkgs;
          };
          shell = devshell.mkShell {
            packages = [
              (pkgs.python3.withPackages (ps: [
                ps.piano-transcription-inference
                ps.resampy
                ps.tkinter
              ]))
              pkgs.ffmpeg
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
          default = if pkgs.stdenv.isx86_64 then shell-bin else shell;
          inherit shell shell-bin;
        }
      );
    };
}
