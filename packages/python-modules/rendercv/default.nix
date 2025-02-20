{
  lib,
  config,
  dream2nix,
  ...
}:

let
  pyproject = lib.importTOML (config.mkDerivation.src + /pyproject.toml);
in
{
  imports = [
    dream2nix.modules.dream2nix.pip
  ];

  config = {
    deps =
      { nixpkgs, ... }:
      {
        inherit (nixpkgs) fetchFromGitHub;
      };

    name = "rendercv";
    version = "2.2";

    mkDerivation = {
      src = config.deps.fetchFromGitHub {
        owner = "sinaatalay";
        repo = "rendercv";
        rev = "refs/tags/v${config.version}";
        hash = "sha256-bIEuzMGV/l8Cunc4W04ESFYTKhNH+ffkA6eXGbyu3A0=";
      };
    };

    buildPythonPackage = {
      pyproject = true;

      pythonImportsCheck = [
        "rendercv.cli"
      ];
    };

    pip = {
      requirementsList =
        pyproject.build-system.requires
        ++ pyproject.project.dependencies
        ++ pyproject.project.optional-dependencies.full;

      flattenDependencies = true;
    };

    public = {
      meta = with lib; {
        description = "A Typst-based cv/resume framework for academics and engineers";
        changelog = "https://github.com/sinaatalay/rendercv/releases/tag/v${config.version}";
        longDescription = ''
          RenderCV engine is a Typst-based Python package with a command-line interface (CLI) that allows you to version-control your CV/resume as source code. It reads a CV written in a YAML file with Markdown syntax, converts it into a Typst code, and generates a PDF.
        '';
        downloadPage = "https://github.com/sinaatalay/rendercv";
        homepage = "https://rendercv.com/";
        license = licenses.mit;
        maintainers = [ maintainers.polykernel ];
        platforms = platforms.unix;
        mainProgram = "rendercv";
      };
    };
  };
}
