{
  lib,
  config,
  dream2nix,
  ...
}:

{
  imports = [
    dream2nix.modules.dream2nix.mkDerivation
  ];

  config = {
    deps =
      { nixpkgs, polypkgs, ... }:
      {
        inherit (nixpkgs)
          fetchFromGitHub
          pkg-config
          autoreconfHook
          gtest
          tbb
          ;

        inherit (polypkgs)
          mathic
          memtailor
          ;
      };

    name = "mathicgb";
    version = "0-unstable-2024-02-05";

    mkDerivation = {
      src = config.deps.fetchFromGitHub {
        owner = "Macaulay2";
        repo = "mathicgb";
        rev = "4cd2bd1357107cf0c83661fdda66c94987de4608";
        sha256 = "sha256-eWG4Zq+VynY9eHc8XlNekyFjB0WRl9nv1GudfVDkCyU=";
      };

      nativeBuildInputs = with config.deps; [
        gtest
        autoreconfHook
        pkg-config
      ];

      buildInputs = with config.deps; [
        mathic
        memtailor
        tbb
      ];

      configureFlags = [
        "--with-gtest=yes"
        "GTEST_PATH=${config.deps.gtest.src}/googletest"
      ];
    };

    public = {
      meta = with lib; {
        description = "Compute (signature) Groebner bases using the fast datastructures from mathic";
        longDescription = ''
          Mathicgb is a program for computing Groebner basis and signature Grobner bases. Mathicgb is based on the fast data structures from mathic.
        '';
        homepage = "https://github.com/Macaulay2/mathicgb";
        license = licensesSpdx."GPL-2.0-or-later";
        maintainers = [ maintainers.polykernel ];
        platforms = [
          "x86_64-linux"
          "aarch64-linux"
        ];
      };
    };
  };
}
