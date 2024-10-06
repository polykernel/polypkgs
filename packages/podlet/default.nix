{
  lib,
  config,
  dream2nix,
  ...
}:

{
  imports = [
    dream2nix.modules.dream2nix.rust-cargo-lock
    dream2nix.modules.dream2nix.buildRustPackage
  ];

  deps = { nixpkgs, ... }: {
    inherit (nixpkgs) fetchFromGitHub;
  };

  name = lib.mkForce "podlet";
  version = lib.mkForce "0.3.0";

  mkDerivation = {
    src = config.deps.fetchFromGitHub {
      owner = "containers";
      repo = "podlet";
      rev = "v${config.version}";
      sha256 = "sha256-STkYCaXBoQSmFKpMdsKzqFGXHh9s0jeGi5K2itj8jmc=";
    };
  };
}
