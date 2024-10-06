{
  description = "Polypkgs flake";

  inputs = {
    dream2nix.url = "github:nix-community/dream2nix";
    nixpkgs.follows = "dream2nix/nixpkgs";
  };

  outputs = {
    self,
    dream2nix,
    nixpkgs,
  }: let
    supportedSystems = [ "aarch64-linux" "x86_64-linux" ];

    eachSystem = nixpkgs.lib.genAttrs supportedSystems;
  in {
    packages = eachSystem (system:
      dream2nix.lib.importPackages {
        projectRoot = ./.;
        projectRootFile = "flake.nix";
        packagesDir = ./packages;
        packageSets.nixpkgs = nixpkgs.legacyPackages.${system};
      });
  };
}
