{
  description = "Polypkgs flake";

  inputs = {
    dream2nix.url = "github:nix-community/dream2nix";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.follows = "dream2nix/nixpkgs";
  };

  outputs =
    {
      self,
      dream2nix,
      flake-utils,
      nixpkgs,
      ...
    }@inputs:
    let
      supportedSystems = [
        "aarch64-linux"
        "x86_64-linux"
      ];

      lib = nixpkgs.lib // builtins;

      perSystem = system: {
        packages = flake-utils.lib.flattenTree (
          import ./packages.nix {
            inherit lib dream2nix;
            pkgs = nixpkgs.legacyPackages.${system};
          }
        );
      };

      modulesDir = ./modules;

      modules = lib.mapAttrs (module: modulesDir + "/${module}") (
        lib.filterAttrs (_: type: type == "directory") (lib.readDir modulesDir)
      );
    in
    flake-utils.lib.eachSystem supportedSystems perSystem
    // {
      polypkgs = modules;
    };
}
