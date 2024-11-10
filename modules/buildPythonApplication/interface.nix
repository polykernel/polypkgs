{
  config,
  dream2nix,
  lib,
  ...
}:

let
  l = lib // builtins;
  t = l.types;

  # buildPythonApplication takes exactly the same arguments as buildPythonPackage
  buildPythonApplicationOptions = import (
    dream2nix.modules.dream2nix.buildPythonPackage + "/options.nix"
  ) { inherit config lib; };
in
{
  options = {
    buildPythonApplication = buildPythonApplicationOptions;
    deps.python = l.mkOption {
      type = t.package;
      description = "The python interpreter package to use";
    };
  };
  config = {
    buildPythonApplication.format = lib.mkOptionDefault (
      if config.buildPythonApplication.pyproject == null then "setuptools" else null
    );
  };
}
