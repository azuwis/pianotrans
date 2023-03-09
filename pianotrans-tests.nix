let
  # github:azuwis/nixpkgs/62b4df51ee3c01968ac2ac30831b1f989ab917f9
  nixpkgs = builtins.getFlake github:azuwis/nixpkgs/torch;
  pkgs = import nixpkgs { system = "x86_64-darwin"; };
  mkPy = mklDnnSupport: pkgs.python3.override
    {
      packageOverrides = self: super: { torch = super.torch.override { inherit mklDnnSupport; }; };
    };
in
{
  mklDnnOn = (pkgs.pianotrans.override {
    python3 = mkPy true;
  });
  mklDnnOff = (pkgs.pianotrans.override {
    python3 = mkPy false;
  });
  torchBin = (pkgs.pianotrans.override {
    python3 = pkgs.python3.override
    {
      packageOverrides = self: super: { torch = super.torch-bin; };
    };
  });
}
