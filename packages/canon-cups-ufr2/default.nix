/*
  Port of the canon-cups-ufr2 package from nixpkgs for personal use.

  Changelog:
    * Sat Nov 2 19:32:00 UTC 2024 polykernel - 0-1
    - Initial port from upstream
    * Sun Feb 23 21:44:00 UTC 2025 polykernel - 0-2
    - Port fix for build failure due to dangling symlinks[^1]
    from upstream PR[^2] which is in turn based on the
    cnrdrvcups-lb AUR package

    [^1]: https://github.com/NixOS/nixpkgs/issues/380572#issuecomment-2646162619
    [^2]: https://github.com/NixOS/nixpkgs/pull/381315
*/

{
  dream2nix,
  config,
  lib,
  ...
}:

let
  inherit (config.deps) stdenv;

  l = lib // builtins;

  system =
    if stdenv.hostPlatform.system == "x86_64-linux" then
      "intel"
    else if stdenv.hostPlatform.system == "aarch64-linux" then
      "arm"
    else
      throw "Unsupported platform for Canon UFRII Drivers: ${stdenv.hostPlatform.system}";

  version = "6.00";
  dl = "6/0100009236/20";
  region = "us";
  suffix = "02";

  ld64 = "${stdenv.cc}/nix-support/dynamic-linker";
  libs = l.makeLibraryPath config.mkDerivation.buildInputs;

  versionNoDots = l.replaceStrings [ "." ] [ "" ] version;

  src_canon = config.deps.fetchurl {
    url = "https://gdlp01.c-wss.com/gds/${dl}/linux-UFRII-drv-v${versionNoDots}-${region}-${suffix}.tar.gz";
    hash = "sha256-lktesKcGsHOUMgmeq04KYck6qai/tS/ZN2ptB8F/n4s=";
  };

  convertSpec = config.deps.writeTextFile {
    name = "convert-spec.awk";
    checkPhase = "awk -f $target < /dev/null";
    text = ''
      $1 == "%" phase { inPhase = 1; next }
      inPhase && /^%/ { exit }
      inPhase {
        gsub("[$]{RPM_BUILD_DIR}", "$srcRoot");
        gsub("[$]{RPM_BUILD_ROOT}", "");
        gsub("%{nobuild}", "0");
        gsub("%{_builddir}", "$srcRoot");
        gsub("%{_prefix}", "$out");
        gsub("%{_libsarch}", "libs64/${system}");
        gsub("%{_libdir}", "$out/lib");
        gsub("%{locallibs}", "$out/lib");
        gsub("%{_bindir}", "$out/bin");
        gsub("%{_includedir}", "$out/include");
        gsub("%{_cflags}", "");
        gsub("%{_machine_type}", "MACHINETYPE=${stdenv.hostPlatform.parsed.cpu.name}");
        gsub("%{common_dir}", "cnrdrvcups-common-${version}");
        gsub("%{driver_dir}", "cnrdrvcups-lb-${version}");
        gsub("%{utility_dir}", "cnrdrvcups-utility-${version}");
        gsub("%{b_lib_dir}", "$srcRoot/lib");
        gsub("%{b_include_dir}", "$srcRoot/include");
        gsub("-m 4755", "-m 755"); # no setuid
        if (/%/) {
          print "error: variable not replaced:", $0 > "/dev/stderr"
          print "exit 1"
          exit 1
        }
        print
      }
    '';
  };

  configureScript = config.deps.writeScript "canon-cups-ufr2-configure" ''
    set -eu
    # Update old automake files
    for dir in \
      cnrdrvcups-common-${version}/{backend,buftool,cngplp,cnjbig,rasterfilter} \
      cnrdrvcups-lb-${version}/{cngplp/files,cngplp,cpca,pdftocpca}
    do
      echo autoreconf $dir
      pushd "$dir"
      # For some reason, autoreconf fails to create ltmain.sh on first run.
      autoreconf --force --install --warnings=none || autoreconf --force --install --warnings=none
      popd
    done
    awk -f ${convertSpec} -v phase=setup cnrdrvcups-lb.spec | bash -eux
  '';
in
{
  imports = [
    dream2nix.modules.dream2nix.mkDerivation
  ];

  config = {
    name = "canon-cups-ufr2";
    inherit version;

    deps =
      { nixpkgs, ... }:
      {
        inherit (nixpkgs)
          stdenv
          fetchurl
          pkg-config
          makeWrapper
          writeTextFile
          writeScript
          unzip
          autoconf
          automake
          libtool_1_5
          cups
          zlib
          jbigkit
          glib
          gtk3
          libxml2
          gdk-pixbuf
          pango
          cairo
          atk
          libredirect
          ghostscript
          ;
      };

    mkDerivation = {
      src = src_canon;

      # we can't let patchelf remove unnecessary RPATHs because the driver uses dlopen to load libjpeg and libgcrypt
      dontPatchELF = true;

      nativeBuildInputs = with config.deps; [
        makeWrapper
        unzip
        autoconf
        automake
        libtool_1_5
        pkg-config
      ];

      buildInputs = with config.deps; [
        cups
        zlib
        jbigkit
        glib
        gtk3
        libxml2
        gdk-pixbuf
        pango
        cairo
        atk
      ];

      postUnpack = ''
        # make a new variable instead of shadowing `sourceRoot`
        export srcRoot=$PWD/$sourceRoot

        (
          cd $sourceRoot
          tar -xf Sources/cnrdrvcups-lb-${version}-1.${suffix}.tar.xz
        )
      '';

      patches = [
        ./0001-replace-incorrect-int-with-char.patch
      ];

      postPatch = ''
        substituteInPlace $(find cnrdrvcups-lb-${version}/cngplp -name Makefile.am) \
          --replace-quiet /usr/include/libxml2/ ${config.deps.libxml2.dev}/include/libxml2/
        substituteInPlace \
          cnrdrvcups-common-${version}/{{backend,cngplp/src,rasterfilter}/Makefile.am,rasterfilter/cnrasterproc.h} \
          cnrdrvcups-lb-${version}/{cngplp/files,pdftocpca}/Makefile.am \
          --replace-fail /usr "$out"
        substituteInPlace cnrdrvcups-common-${version}/cngplp/Makefile.am \
          --replace-fail /etc/cngplp "$out/etc/cngplp"
        patchShebangs cnrdrvcups-common-${version}
        patchShebangs cnrdrvcups-lb-${version}
      '';

      configureScript = configureScript.outPath;

      buildPhase = ''
        runHook preBuild

        awk -f ${convertSpec} -v phase=build cnrdrvcups-lb.spec | bash -eux

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        awk -f ${convertSpec} -v phase=install cnrdrvcups-lb.spec | bash -eux

        (
          cd $out/lib

          patchelf --set-rpath "$(cat $NIX_CC/nix-support/orig-cc)/lib:${libs}:${l.getLib stdenv.cc.cc}/lib64:${stdenv.cc.libc}/lib64:$out/lib" libcanonufr2r.so.1.0.0
          patchelf --set-rpath "$(cat $NIX_CC/nix-support/orig-cc)/lib:${libs}:${l.getLib stdenv.cc.cc}/lib64:${stdenv.cc.libc}/lib64" libcaepcmufr2.so.1.0
          patchelf --set-rpath "$(cat $NIX_CC/nix-support/orig-cc)/lib:${libs}:${l.getLib stdenv.cc.cc}/lib64:${stdenv.cc.libc}/lib64" libColorGearCufr2.so.2.0.0
        )

        (
          cd $out/bin
          patchelf --set-interpreter "$(cat ${ld64})" --set-rpath "${l.makeLibraryPath config.mkDerivation.buildInputs}:${l.getLib stdenv.cc.cc}/lib64:${stdenv.cc.libc}/lib64" cnsetuputil2 cnpdfdrv
          patchelf --set-interpreter "$(cat ${ld64})" --set-rpath "${l.makeLibraryPath config.mkDerivation.buildInputs}:${l.getLib stdenv.cc.cc}/lib64:${stdenv.cc.libc}/lib64:$out/lib" cnpkbidir cnrsdrvufr2 cnpkmoduleufr2r cnjbigufr2

          wrapProgram $out/bin/cnrsdrvufr2 \
            --prefix LD_LIBRARY_PATH ":" "$out/lib" \
            --set LD_PRELOAD "${config.deps.libredirect}/lib/libredirect.so" \
            --set NIX_REDIRECTS /usr/bin/cnpkmoduleufr2r=$out/bin/cnpkmoduleufr2r:/usr/bin/cnjbigufr2=$out/bin/cnjbigufr2

          wrapProgram $out/bin/cnsetuputil2 \
            --set LD_PRELOAD "${config.deps.libredirect}/lib/libredirect.so" \
            --set NIX_REDIRECTS /usr/share/cnsetuputil2=$out/usr/share/cnsetuputil2
        )

        makeWrapper "${config.deps.ghostscript}/bin/gs" "$out/bin/gs" \
          --prefix LD_LIBRARY_PATH ":" "$out/lib" \
          --prefix PATH ":" "$out/bin"

        runHook postInstall
      '';
    };

    public = {
      meta = with lib; {
        description = "Canon UFR II/UFRII LT Linux printer drivers for CUPS";
        homepage = "https://www.canon.com/";
        sourceProvenance = [ sourceTypes.binaryNativeCode ];
        license = licenses.unfree;
        maintainers = [ maintainers.polykernel ];
        platforms = [
          "x86_64-linux"
          "aarch64-linux"
        ];
      };
    };
  };
}
