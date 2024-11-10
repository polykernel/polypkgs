{
  config,
  dream2nix,
  lib,
  ...
}:

let
  l = lib // builtins;
in
{
  imports = [
    ./interface.nix
    dream2nix.modules.dream2nix.mkDerivation
    dream2nix.modules.dream2nix.deps
  ];

  config = {
    package-func.func = config.deps.python.pkgs.buildPythonApplication;
    package-func.args = config.buildPythonApplication;

    deps =
      { nixpkgs, ... }:
      {
        python = l.mkOptionDefault nixpkgs.python3;
      };
  };
}
