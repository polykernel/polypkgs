{
  description = "Polypkgs flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";

    dream2nix.url = "github:nix-community/dream2nix";
    dream2nix.inputs.nixpkgs.follows = "nixpkgs";

    pre-commit-hooks.url = "github:cachix/git-hooks.nix";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      dream2nix,
      flake-utils,
      pre-commit-hooks,
      nixpkgs,
      ...
    }@inputs:
    let
      supportedSystems = [
        "aarch64-linux"
        "x86_64-linux"
      ];

      lib = nixpkgs.lib // builtins;

      perSystem =
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = { };
            overlays = [ ];
          };
        in
        lib.fix (_self: {
          apps = lib.mapAttrs (_: drv: flake-utils.lib.mkApp { inherit drv; }) _self.packages;

          packages = flake-utils.lib.flattenTree (
            import ./packages.nix {
              inherit lib dream2nix pkgs;
            }
          );

          checks = {
            pre-commit-check = pre-commit-hooks.lib.${system}.run {
              src = ./.;
              hooks = {
                treefmt.enable = true;
                treefmt.settings = {
                  formatters = [
                    pkgs.nixfmt-rfc-style
                    pkgs.typos
                    pkgs.toml-sort
                  ];
                };
              };
            };
          };

          devShells = {
            default = pkgs.mkShell {
              inherit (_self.checks.pre-commit-check) shellHook;

              nativeBuildInputs = _self.checks.pre-commit-check.enabledPackages;

            };
          };
        });

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
