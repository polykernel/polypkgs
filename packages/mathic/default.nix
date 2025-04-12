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
          autoreconfHook
          pkg-config
          ;

        inherit (polypkgs)
          memtailor
          ;
      };

    name = "mathic";
    version = "0-unstable-2023-09-16";

    mkDerivation = {
      src = config.deps.fetchFromGitHub {
        owner = "Macaulay2";
        repo = "mathic";
        rev = "07e8df4ded6b586c0ce9eec0f9096690379749cb";
        sha256 = "sha256-ZbfD+nn+d/htPVP3QprDua+R1oaPIZsmQln9YGImBto=";
      };

      nativeBuildInputs = with config.deps; [
        autoreconfHook
        pkg-config
      ];

      buildInputs = with config.deps; [ memtailor ];
    };

    public = {
      meta = with lib; {
        description = "C++ library of symbolic algebra data structures for use in Groebner basis computation";
        longDescription = ''
          Mathic is a C++ library of fast data structures designed for use in Groebner basis computation. This includes data structures for ordering S-pairs, performing divisor queries and ordering polynomial terms during polynomial reduction.
        '';
        homepage = "https://github.com/Macaulay2/mathic";
        license = licensesSpdx."LGPL-2.0-or-later";
        maintainers = [ maintainers.polykernel ];
        platforms = [
          "x86_64-linux"
          "aarch64-linux"
        ];
      };
    };
  };
}
