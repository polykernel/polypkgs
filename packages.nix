{
  lib,
  pkgs,
  dream2nix,
  ...
}:

let
  modulesDir = ./modules;
  packagesDir = ./packages;

  evalPackage =
    { packagePath, ... }@args:
    dream2nix.lib.evalModules {
      modules = args.modules or [ ] ++ [
        (packagesDir + "/${packagePath}")
        {
          paths.projectRoot = ./.;
          paths.projectRootFile = "flake.nix";
          paths.package = packagesDir + "/${packagePath}";
        }
      ];
      packageSets = {
        nixpkgs = pkgs;
      };
      specialArgs = {
        packagesRoot = packagesDir;
      };
    };

  packages = {
    canon-cups-ufr2 = evalPackage { packagePath = "canon-cups-ufr2"; };
    podlet = evalPackage { packagePath = "podlet"; };
    inherit (packages.python-modules) rendercv;

    python-modules = lib.recurseIntoAttrs {
      rendercv = evalPackage { packagePath = "python-modules/rendercv"; };
    };
  };
in
packages
