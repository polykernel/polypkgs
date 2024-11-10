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
    version = "1.14";

    mkDerivation = {
      src = config.deps.fetchFromGitHub {
        owner = "sinaatalay";
        repo = "rendercv";
        rev = "refs/tags/v${config.version}";
        hash = "sha256-wTf4PN9akUsdJO39xuc8EB+EH4pLr1hCZfjlpG5gOik=";
        fetchSubmodules = true;
      };
    };

    buildPythonPackage = {
      format = "pyproject";
      build-system = [ config.deps.python.pkgs.hatchling ];

      pythonImportsCheck = [
        config.name
      ];
    };

    pip = {
      requirementsList = pyproject.build-system.requires or [ ] ++ pyproject.project.dependencies or [ ];

      flattenDependencies = true;
    };

    public = {
      meta = with lib; {
        description = "A LaTeX cv/resume framework for academics and engineers";
        changelog = "https://github.com/sinaatalay/rendercv/releases/tag/v${config.version}";
        longDescription = ''
          RenderCV is a framework for maintaining and version-controlling professional
          and customizable LaTeX CVs and resumes, built on top of the open-source
          rendering engine.
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
