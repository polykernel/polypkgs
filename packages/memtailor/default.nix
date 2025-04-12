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
      { nixpkgs, ... }:
      {
        inherit (nixpkgs)
          fetchFromGitHub
          pkg-config
          autoreconfHook
          gtest
          ;
      };

    name = "memtailor";
    version = "0-unstable-2023-09-16";

    mkDerivation = {
      src = config.deps.fetchFromGitHub {
        owner = "Macaulay2";
        repo = "memtailor";
        rev = "f785005b92a54463dbd5377ab80855a3d2a5f92d";
        sha256 = "sha256-fC7I7X97PUmmNG2MCRAw5HB+FoKO6RnMpz8vyRI1Cjk=";
      };

      nativeBuildInputs = with config.deps; [
        gtest
        autoreconfHook
        pkg-config
      ];

      configureFlags = [
        "--with-gtest=yes"
        "GTEST_PATH=${config.deps.gtest.src}/googletest"
      ];
    };

    public = {
      meta = with lib; {
        description = "C++ library of special purpose memory allocators";
        longDescription = ''
          Memtailor is a C++ library of special purpose memory allocators. It currently offers an arena allocator and a memory pool.
        '';
        homepage = "https://github.com/Macaulay2/memtailor";
        license = licensesSpdx."BSD-3-Clause";
        maintainers = [ maintainers.polykernel ];
        platforms = [
          "x86_64-linux"
          "aarch64-linux"
        ];
      };
    };
  };
}
