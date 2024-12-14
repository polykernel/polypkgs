{
  lib,
  config,
  dream2nix,
  ...
}:

{
  imports = [
    dream2nix.modules.dream2nix.rust-cargo-lock
    dream2nix.modules.dream2nix.rust-cargo-vendor
    dream2nix.modules.dream2nix.buildRustPackage
  ];

  config = {
    deps =
      { nixpkgs, ... }:
      {
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

    public = {
      meta = with lib; {
        description = "Generate Podman Quadlet files from a Podman command, compose file, or existing object";
        homepage = "https://github.com/containers/podlet";
        changelog = "https://github.com/containers/podlet/blob/v${config.version}/CHANGELOG.md";
        license = licenses.mpl20;
        maintainers = [ maintainers.polykernel ];
        platforms = [
          "x86_64-linux"
          "aarch64-linux"
        ];
      };
    };
  };
}
